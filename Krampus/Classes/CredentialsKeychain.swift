//
//  KeycloakKeychain.swift
//  Krampus
//
//  Created by Christian Braun on 06.12.19.
//

import Foundation

public struct CredentialsKeychain: Codable {
    public let credentialsServiceName: String

    public init(credentialsServiceName: String) {
        self.credentialsServiceName = credentialsServiceName
    }

    public func readCredentials() -> KeychainCredentials? {
        let query = Keychain.query(credentialsServiceName)
        return Keychain.readQuery(query)
    }

    public func saveCredentials(_ credentials: Credentials) throws -> KeychainCredentials {
        let now = Date()
        let accessTokenExpiresAt = now.addingTimeInterval(TimeInterval(credentials.accessTokenExpiresIn))
        let keychainCredentials = KeychainCredentials(
            accessToken: credentials.accessToken,
            refreshToken: credentials.refreshToken,
            accessTokenExpiresAt: accessTokenExpiresAt)
        try Keychain.save(object: keychainCredentials, serviceName: credentialsServiceName)
        return keychainCredentials
    }

    public func deleteCredentials() throws {
        try Keychain.delete(serviceName: credentialsServiceName)
    }
}
