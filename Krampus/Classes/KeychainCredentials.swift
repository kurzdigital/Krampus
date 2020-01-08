//
//  KeychainKeycloakCredentials.swift
//  Krampus
//
//  Created by Christian Braun on 06.12.19.
//

import Foundation

public struct KeychainCredentials: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let accessTokenExpiresAt: Date

    #if DEBUG
    public static var mocked: KeychainCredentials {
        return KeychainCredentials(
            accessToken: "MockedToken",
            refreshToken: "MockedRefreshToken",
            accessTokenExpiresAt: Date.distantFuture)
    }
    #endif
}

public struct Credentials: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let accessTokenExpiresIn: Int64

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case accessTokenExpiresIn = "expires_in"
    }
}

