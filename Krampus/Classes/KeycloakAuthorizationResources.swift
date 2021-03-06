//
//  KeycloakAuthorizationResources.swift
//  Krampus
//
//  Created by Christian Braun on 06.12.19.
//

import Foundation
import Santa

extension KeycloakAuthorization {
    func create(withAuthCode code: String) -> DataResource<Credentials> {
        guard let redirectUrl = redirectUrl.encodeAsQueryParam(),
            let clientId = clientId.encodeAsQueryParam() else {
                fatalError("Redirect URI and clientId must be url encodable")
        }
        var bodyString = "code=\(code)&client_id=\(clientId)&redirect_uri=\(redirectUrl)&grant_type=authorization_code"
        if useOfflineToken {
            bodyString.append("&scope=offline_access")
        }
        return resourceForPost(bodyString, url: tokenUrl)
    }

    func create(witherUsername username: String, password: String) -> DataResource<Credentials> {
        guard let username = username.encodeAsQueryParam(),
            let password = password.encodeAsQueryParam(),
            let clientId = clientId.encodeAsQueryParam() else {
                fatalError("Redirect URI and clientId must be url encodable")
        }
        var bodyString = "username=\(username)&password=\(password)&client_id=\(clientId)&grant_type=password"
        if useOfflineToken {
            bodyString.append("&scope=offline_access")
        }
        return resourceForPost(bodyString, url: tokenUrl)
    }

    func refresh(refreshToken: String) -> DataResource<Credentials> {
        guard let refreshToken = refreshToken.encodeAsQueryParam(),
            let clientId = clientId.encodeAsQueryParam() else {
                fatalError("RefreshToken and clientId must be url encodable")
        }
        let bodyString = "client_id=\(clientId)&refresh_token=\(refreshToken)&grant_type=refresh_token"
        return resourceForPost(bodyString, url: tokenUrl)
    }

    func delete(refreshToken: String) -> DataResource<Credentials> {
        guard let refreshToken = refreshToken.encodeAsQueryParam(),
            let clientId = clientId.encodeAsQueryParam() else {
                fatalError("RefreshToken and clientId must be url encodable")
        }
        let bodyString = "client_id=\(clientId)&refresh_token=\(refreshToken)"
        return resourceForPost(bodyString, url: logoutUrl)
    }

    // MARK: - Helper
    fileprivate func resourceForPost(_ bodyString: String, url: String) -> DataResource<Credentials> {
        let resource = DataResource(url: url, method: .post, body: bodyString.data(using: .utf8)) { data in
            try? JSONDecoder().decode(Credentials.self, from: data)
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
