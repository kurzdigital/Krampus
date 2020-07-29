//
//  DataResource.swift
//  Pods-kta-taxstamp-montenegro
//
//  Created by Christian Braun on 17.06.20.
//

import Foundation

public typealias Boundary = String

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
        body: Data? = nil,
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
}

extension DataResource where A: Decodable {
    public convenience init(url: String, method: HTTPMethod, body: Data? = nil, uuid: UUID = UUID(), authorizationNeeded: Bool = true) {
        self.init(url: url, method: method, body: body, uuid: uuid, authorizationNeeded: authorizationNeeded) { data -> A in
            try JSONDecoder().decode(A.self, from: data)
        }
        self.headers.contentType = HTTPHeader.contentTypeJson
    }
}
