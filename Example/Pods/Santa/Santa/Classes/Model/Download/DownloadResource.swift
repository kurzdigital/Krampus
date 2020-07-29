//
//  DownloadResource.swift
//  Santa
//
//  Created by Christian Braun on 17.06.20.
//

import Foundation

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
