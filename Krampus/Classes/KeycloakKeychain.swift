//
//  KeycloakKeychain.swift
//  Krampus
//
//  Created by Christian Braun on 06.12.19.
//

import Foundation

public struct KeycloakKeychain: Codable {
    public let credentialsServiceName: String

    public init(credentialsServiceName: String) {
        self.credentialsServiceName = credentialsServiceName
    }

    public func readCredentials() -> KeychainKeycloakCredentials? {
        let query = Keychain.query(credentialsServiceName)
        return Keychain.readQuery(query)
    }

    public func saveCredentials(_ credentials: KeycloakCredentials) throws -> KeychainKeycloakCredentials {
        let now = Date()
        let accessTokenExpiresAt = now.addingTimeInterval(TimeInterval(credentials.accessTokenExpiresIn))
        let refreshTokenExpiresAt = now.addingTimeInterval(TimeInterval(credentials.refreshTokenExpiresIn))
        let keychainCredentials = KeychainKeycloakCredentials(accessToken: credentials.accessToken,
                                                              refreshToken: credentials.refreshToken,
                                                              accessTokenExpiresAt: accessTokenExpiresAt,
                                                              refreshTokenExpiresAt: refreshTokenExpiresAt)
        try Keychain.save(object: keychainCredentials, serviceName: credentialsServiceName)
        return keychainCredentials
    }

    public func deleteCredentials() throws {
        try Keychain.delete(serviceName: credentialsServiceName)
    }
}
