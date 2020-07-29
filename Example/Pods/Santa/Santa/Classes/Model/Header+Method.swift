//
//  Header+Method.swift
//  Pods-kta-taxstamp-montenegro
//
//  Created by Christian Braun on 17.06.20.
//

import Foundation

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
    public static let acceptImageJpeg = "image/jpeg"
    public static let acceptImagePng = "image/png"

    public static func contentTypeMultipart(boundary: String) -> String {
        return "multipart/form-data; boundary=\(boundary)"
    }
}

public struct Headers {
    public var contentType = HTTPHeader.contentTypeNone
    public var accept = HTTPHeader.acceptNone
    public var other = [String: String]()
}
