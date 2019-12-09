//
//  Resource.swift
//  Santa
//
//  Created by Christian Braun on 05.12.19.
//
import Foundation

public typealias Boundary = String

public enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

public struct HTTPHeader {
    public static let contentTypeNone = ""
    public static let contentTypeTextPlain = "text/plain"
    public static let contentTypeJson = "application/json"
    public static let contentTypeUrlEncoded = "application/x-www-form-urlencoded"
    public static let contentTypeImageJpeg = "image/jpeg"
    public static let contentTypeImagePng = "image/png"
    public static let acceptNone = ""
    public static let acceptTextPlain = "text/plain"
    public static let acceptJson = "application/json"
    public static let acceptPdf = "application/pdf"

    public static func contentTypeMultipart(boundary: String) -> String {
        return "multipart/form-data; boundary=\(boundary)"
    }
}

public struct Headers {
    public var contentType = HTTPHeader.contentTypeNone
    public var accept = HTTPHeader.acceptNone
    public var other = [String: String]()
}

public protocol Resource {
    var url: String { get }
    var method: HTTPMethod { get }
    var body: Data? { get }
    var authorizationNeeded: Bool { get }
    var headers: Headers { get }
    var uuid: UUID { get }

    /// When we do authentication we want to give it the same uuid as the actual data request.
    /// The reason for this is, that canceling the actual data request must also cancel the current
    /// Auth request. As the auth and data request are strictly sequentiel we just pass the uuid for the
    /// data request to the auth request. When the auth request is done the uuid can be used for the
    /// data request.
    func update(uuid: UUID) -> Self
}

public final class DataResource<A>: Resource {
    public let url: String
    public let method: HTTPMethod
    public let body: Data?
    public let parseData: (Data) throws -> A?
    public var authorizationNeeded = true
    public var headers = Headers()
    public let uuid: UUID

    public init(
        url: String,
        method: HTTPMethod,
        body: Data?,
        uuid: UUID = UUID(),
        authorizationNeeded: Bool = true,
        parseData:@escaping (Data) throws -> A?) {
        self.url = url
        self.method = method
        self.body = body
        self.parseData = parseData
        self.uuid = uuid
        self.authorizationNeeded = authorizationNeeded
    }

    public func update(uuid: UUID) -> DataResource {
        return DataResource(
            url: url,
            method: method,
            body: body,
            uuid: uuid,
            authorizationNeeded: authorizationNeeded,
            parseData: parseData)
    }

    public static func randomBoundary() -> String {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return "XXX\(String(alphabet.shuffled()).dropFirst(alphabet.count - 10))XXX"
    }

    public static func multipartFormData(with data: Data, boundary: Boundary, mimeType: String) -> Data {
        var returnData = Data()

        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
            let contentType = "Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8),
            let contentDisposition = "Content-Disposition:form-data; name=\"file\"; filename=\"data.jpg\"\r\n".data(using: .utf8),
            let newLine = "\r\n".data(using: .utf8),
            let closingBoundary = "--\(boundary)--".data(using: .utf8) else {
                preconditionFailure("Unable to create multi part form data")
        }

        returnData.append(boundaryData)
        returnData.append(contentDisposition)
        returnData.append(contentType)
        returnData.append(data)
        returnData.append(newLine)
        returnData.append(closingBoundary)

        return returnData
    }
}

public final class DownloadResource: Resource {
    public let url: String
    public let method: HTTPMethod
    public let body: Data?
    public let fileName: String
    public var authorizationNeeded = true
    public var headers = Headers()
    public let uuid: UUID

    public init(
        url: String,
        method: HTTPMethod,
        body: Data?,
        fileName: String,
        uuid: UUID = UUID(),
        authorizationNeeded: Bool = true) {
        self.url = url
        self.method = method
        self.body = body
        self.fileName = fileName
        self.uuid = uuid
        self.authorizationNeeded = authorizationNeeded
    }

    public func update(uuid: UUID) -> DownloadResource {
        return DownloadResource(
            url: url,
            method: method,
            body: body,
            fileName: fileName,
            uuid: uuid,
            authorizationNeeded: authorizationNeeded)
    }
}
