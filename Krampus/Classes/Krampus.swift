//
//  Krampus.swift
//  Krampus
//
//  Created by Christian Braun on 06.12.19.
//

import Foundation
import Santa

public struct Krampus {
    public static func keycloakAuthorization(
        baseUrl: String,
        clientId: String,
        realm: String,
        redirectUrl: String,
        keychain: CredentialsKeychain,
        webservice: Webservice,
        useOfflineToken: Bool = false) -> KeycloakAuthorization {
        return KeycloakAuthorization(
            baseUrl: baseUrl,
            clientId: clientId,
            realm: realm,
            redirectUrl: redirectUrl,
            keychain: keychain,
            webservice: webservice,
            useOfflineToken: useOfflineToken
        )
    }
}
