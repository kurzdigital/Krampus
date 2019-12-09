//
//  KeycloakAuthorizationResources.swift
//  Krampus
//
//  Created by Christian Braun on 06.12.19.
//

import Foundation
import Santa

extension KeycloakAuthorization {
    func create(withAuthCode code: String) -> DataResource<KeycloakCredentials> {
        guard let redirectUrl = redirectUrl.encodeAsQueryParam(),
            let clientId = clientId.encodeAsQueryParam() else {
                fatalError("Redirect URI and clientId must be url encodable")
        }
        let bodyString = "code=\(code)&client_id=\(clientId)&redirect_uri=\(redirectUrl)&grant_type=authorization_code"
        return resourceForPost(bodyString, url: tokenUrl)
    }

    func create(witherUsername username: String, password: String) -> DataResource<KeycloakCredentials> {
        guard let username = username.encodeAsQueryParam(),
            let password = password.encodeAsQueryParam(),
            let clientId = clientId.encodeAsQueryParam() else {
                fatalError("Redirect URI and clientId must be url encodable")
        }
        let bodyString = "username=\(username)&password=\(password)&client_id=\(clientId)&grant_type=password"
        return resourceForPost(bodyString, url: tokenUrl)
    }

    func refresh(refreshToken: String) -> DataResource<KeycloakCredentials> {
        guard let refreshToken = refreshToken.encodeAsQueryParam(),
            let clientId = clientId.encodeAsQueryParam() else {
                fatalError("RefreshToken and clientId must be url encodable")
        }
        let bodyString = "client_id=\(clientId)&refresh_token=\(refreshToken)&grant_type=refresh_token"
        return resourceForPost(bodyString, url: tokenUrl)
    }

    func delete(refreshToken: String) -> DataResource<KeycloakCredentials> {
        guard let refreshToken = refreshToken.encodeAsQueryParam(),
            let clientId = clientId.encodeAsQueryParam() else {
                fatalError("RefreshToken and clientId must be url encodable")
        }
        let bodyString = "client_id=\(clientId)&refresh_token=\(refreshToken)"
        return resourceForPost(bodyString, url: logoutUrl)
    }

    // MARK: - Helper
    fileprivate func resourceForPost(_ bodyString: String, url: String) -> DataResource<KeycloakCredentials> {
        let resource = DataResource(url: url, method: .post, body: bodyString.data(using: .utf8)) { data in
            try? JSONDecoder().decode(KeycloakCredentials.self, from: data)
        }
        resource.headers.contentType = HTTPHeader.contentTypeUrlEncoded
        // must be false or it will end in an endless-authorization-loop
        resource.authorizationNeeded = false
        return resource
    }
}

extension String {
    func encodeAsQueryParam() -> String? {
        var modifiedURLQueryAllowedCharacterSet = CharacterSet.urlQueryAllowed
        modifiedURLQueryAllowedCharacterSet.remove(charactersIn: "&+=?")

        return addingPercentEncoding(withAllowedCharacters: modifiedURLQueryAllowedCharacterSet)
    }
}
