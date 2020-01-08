//
//  KeychainKeycloakCredentials.swift
//  Krampus
//
//  Created by Christian Braun on 06.12.19.
//

import Foundation

public struct KeychainKeycloakCredentials: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let accessTokenExpiresAt: Date

    #if DEBUG
    public static var mocked: KeychainKeycloakCredentials {
        return KeychainKeycloakCredentials(
            accessToken: "MockedToken",
            refreshToken: "MockedRefreshToken",
            accessTokenExpiresAt: Date.distantFuture)
    }
    #endif
}

public struct KeycloakCredentials: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let accessTokenExpiresIn: Int64

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case accessTokenExpiresIn = "expires_in"
    }
}

