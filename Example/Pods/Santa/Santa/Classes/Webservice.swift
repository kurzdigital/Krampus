//
//  Webservice.swift
//  Santa
//
//  Created by Christian Braun on 05.12.19.
//

import UIKit

public protocol Authorization {
    func authorize(
        _ request: URLRequest,
        for resource: Resource,
        completion: @escaping (Result<URLRequest, Error>) -> Void)
}

public enum NetworkError: LocalizedError, Equatable {
    case parseUrl
    case parseData(message: String)
    case failedAuthorization
    case badResponseCode(code: Int)
    case noInternetConnectivity
    case notFound

    public var errorDescription: String? {
        switch self {
        case .parseUrl:
            return "A problem with the server address occured"
        case .parseData:
            return "Can't parse data"
        case .failedAuthorization:
            return "Unable to authorize"
        case .badResponseCode(let code):
            return "Server responded with unexpected response code \(code)"
        case .noInternetConnectivity:
            return "No internet connection"
        case .notFound:
            return "The requested data does not exist"
        }
    }
}

public protocol WebserviceDownloadTaskDelegate: class {
    func webservice(_ sender: Webservice, didFinishDownload url: String, atLocation location: URL, fileName: String)
    func webservice(_ sender: Webservice, didErrorDownload url: String, with error: Error, forFileName fileName: String?)
}

public protocol WebserviceDelegate: class {
    func webservice(_ sender: Webservice, error: Error, for request: URLRequest, with data: Data?)
}

public protocol Webservice {
    var downloadDelegate: WebserviceDownloadTaskDelegate? { get set }
    var delegate: WebserviceDelegate? { get set }
    var authorization: Authorization? { get set }

    func load<A>(resource: DataResource<A>, completion: @escaping (A?, Error?) -> Void)
    func load(resource: DownloadResource, onPreparationError: @escaping (Error) -> Void)
    func reset()
    func cancelTask(for uuid: UUID)
    func isTaskActive(for uuid: UUID) -> Bool
    func isTaskActive(for url: URL) -> Bool
}

public final class ImplWebservice: NSObject, Webservice {
    public weak var downloadDelegate: WebserviceDownloadTaskDelegate?
    public weak var delegate: WebserviceDelegate?
    public var authorization: Authorization?

    public var imageCache = ImageCache()
    fileprivate var fileNameForDownloadTasks = [Int: String]()
    fileprivate var activeTasks = [UUID: URLSessionTask]()
    fileprivate lazy var urlSession: URLSession = {
        URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: self,
            delegateQueue: nil)
    }()

    /// @param completion: Both arguments (data and error) may be nil (for example, when a resource gets deleted)
    public func load<A>(resource: DataResource<A>, completion: @escaping (A?, Error?) -> Void) {
        guard let request = createRequest(fromResource: resource) else {
            completion(nil, NetworkError.parseUrl)
            return
        }

        if let completion = completion as? (UIImage?, Error?) -> Void,
            let image = imageCache.get(url: resource.url) {
            completion(image, nil)
            return
        }

        if resource.authorizationNeeded {
            guard let authorization = authorization else {
                assertionFailure("Authorization must be set if a resource requires authorization")
                return
            }
            authorization.authorize(request, for: resource) { result in
                switch result {
                case .success(let authedRequest):
                    self.doRequest(
                        resource: resource,
                        authedRequest,
                        completion: completion)
                case .failure(let error):
                    completion(nil, error)
                }
            }
        } else {
            doRequest(resource: resource, request, completion: completion)
        }
    }

    public func cancelTask(for uuid: UUID) {
        activeTasks[uuid]?.cancel()
        activeTasks.removeValue(forKey: uuid)
    }

    public func isTaskActive(for uuid: UUID) -> Bool {
        return activeTasks[uuid] != nil
    }

    public func isTaskActive(for url: URL) -> Bool {
        for urlTask in activeTasks.values {
            guard let requestUrl = urlTask.originalRequest?.url else {
                continue
            }

            if url == requestUrl {
                return true
            }
        }

        return false
    }

    public func reset() {
        resetUrlTasks()
        imageCache.invalidate()
        guard let cookieStorage = urlSession.configuration.httpCookieStorage, let cookies = cookieStorage.cookies else {
            return
        }
        for cookie in cookies {
            cookieStorage.deleteCookie(cookie)
        }
    }

    fileprivate func createRequest(fromResource resource: Resource) -> URLRequest? {
        guard let url = URL(string: resource.url) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = resource.method.rawValue
        if resource.headers.accept != HTTPHeader.acceptNone {
            request.addValue(resource.headers.accept, forHTTPHeaderField: "Accept")
        }
        if resource.headers.contentType != HTTPHeader.contentTypeNone {
            request.addValue(resource.headers.contentType, forHTTPHeaderField: "Content-Type")
        }
        for header in resource.headers.other {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        request.httpBody = resource.body

        return request
    }

    fileprivate func doRequest<A>(resource: DataResource<A>, _ request: URLRequest, completion: @escaping (A?, Error?) -> Void) {
        let dataTask = urlSession.dataTask(with: request) { data, response, error in
            self.activeTasks.removeValue(forKey: resource.uuid)
            if let error = self.errorForResponseAndError(response, error) {
                completion(nil, error)
                self.delegate?.webservice(self, error: error, for: request, with: data)
                return
            }
            guard let data = data else {
                completion(nil, nil)
                return
            }
            do {
                let result = try resource.parseData(data)
                if let image = result as? UIImage {
                    self.imageCache.add(url: resource.url, image: image)
                }
                completion(result, nil)
            } catch {
                completion(nil, NetworkError.parseData(message: error.localizedDescription))
            }
        }
        activeTasks[resource.uuid] = dataTask
        dataTask.resume()
    }

    fileprivate func errorForResponseAndError(_ response: URLResponse?, _ error: Error?) -> Error? {
        // explicitly handle the case "no internet connectivity"
        if let error = error as NSError?,
            error.domain == NSURLErrorDomain &&
                error.code == NSURLErrorNotConnectedToInternet {
            return NetworkError.noInternetConnectivity
        }

        guard error == nil  else {
            return error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return NetworkError.badResponseCode(code: 0)
        }

        // explicitly handle the case 'unauthorized'
        guard httpResponse.statusCode != 401 else {
            return NetworkError.failedAuthorization
        }

        guard httpResponse.statusCode != 404 else {
            return NetworkError.notFound
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            return NetworkError.badResponseCode(code: httpResponse.statusCode)
        }

        return nil
    }

    public func resetUrlTasks() {
       urlSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            // cancel all tasks
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
       }
    }
}

public extension ImplWebservice {
    func load(resource: DownloadResource, onPreparationError: @escaping (Error) -> Void) {
        guard let request = createRequest(fromResource: resource) else {
            onPreparationError(NetworkError.parseUrl)
            return
        }

        if resource.authorizationNeeded {
            guard let authorization = authorization else {
                assertionFailure("Authorization must be set if a resource requires authorization")
                return
            }
            authorization.authorize(request, for: resource) { result in
                switch result {
                case .success(let authedRequest):
                    self.doRequest(
                        resource: resource,
                        authedRequest)
                case .failure(let error):
                    onPreparationError(error)
                }
            }
        } else {
            doRequest(resource: resource, request)
        }
    }

    fileprivate func doRequest(
        resource: DownloadResource ,
        _ request: URLRequest) {
        let downloadTask = urlSession.downloadTask(with: request)
        fileNameForDownloadTasks[downloadTask.taskIdentifier] = resource.fileName
        activeTasks[resource.uuid] = downloadTask
        downloadTask.resume()
    }
}

extension ImplWebservice: URLSessionDownloadDelegate {
    // MARK: - URLSessionDownloadDelegate

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL) {
        guard let fileName = fileNameForDownloadTasks[downloadTask.taskIdentifier] else {
            assertionFailure("Unable to get filename for download task")
            return
        }
        guard let url = downloadTask.originalRequest?.url else {
            preconditionFailure("Download task must contain url")
        }
        do {
            let destination = try DownloadedFilesManager.moveItemToDocuments(
                at: location,
                fileName: fileName)
            downloadDelegate?.webservice(self, didFinishDownload: url.absoluteString, atLocation: destination, fileName: fileName)
        } catch {
            try? DownloadedFilesManager.removeItem(fileName: fileName)
            downloadDelegate?.webservice(self, didErrorDownload: url.absoluteString, with: error, forFileName: fileName)
        }
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?) {
        let fileName = fileNameForDownloadTasks.removeValue(forKey: task.taskIdentifier)
        for currentTaskPair in activeTasks
            where currentTaskPair.value.taskIdentifier == task.taskIdentifier {
                activeTasks.removeValue(forKey: currentTaskPair.key)
        }

        guard let url = task.originalRequest?.url else {
            preconditionFailure("Download task must contain url")
        }

        if let error = errorForResponseAndError(task.response, error) {
            if let fileName = fileName {
                try? DownloadedFilesManager.removeItem(fileName: fileName)
            }
            downloadDelegate?.webservice(self, didErrorDownload: url.absoluteString, with: error, forFileName: fileName)
        }
    }
}

public final class MockWebservice: Webservice {
    public weak var downloadDelegate: WebserviceDownloadTaskDelegate?
    public weak var delegate: WebserviceDelegate?
    /// Will not be used with the mocked webservice
    public var authorization: Authorization?
    public var mocksForUrl = [String: (data: Data?, error: Error?)]()

    public func load(resource: DownloadResource, onPreparationError: @escaping (Error) -> Void) {
    }

    public func load<A>(resource: DataResource<A>, completion: @escaping (A?, Error?) -> Void) {
        if let currentMock = mocksForUrl[resource.url] {
            if let data = currentMock.data {
                try? completion(resource.parseData(data), currentMock.error)
            } else {
                completion(nil, currentMock.error)
            }
        } else {
            completion(nil, nil)
        }
    }

    public func reset() {
    }

    public func cancelTask(for uuid: UUID) {
    }

    public func isTaskActive(for uuid: UUID) -> Bool {
        return true
    }

    public func isTaskActive(for url: URL) -> Bool {
        return true
    }
}
