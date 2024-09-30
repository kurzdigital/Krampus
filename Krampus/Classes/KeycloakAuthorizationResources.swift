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

    /// Creates a `DataResource` object for the given username, password, and custom-defined fields.
    /// All custom fields are combined into a URL-encoded form string (e.g., "foo=bar").
    /// - Note: If the scope is set inside the custom fields and `useOfflineToken` is true, the custom scope value will be ignored.
    /// - Parameters:
    ///   - username: The login username.
    ///   - password: The login password.
    ///   - customValues: A dictionary of custom fields to attach to the body data.
    /// - Returns: A credentials `DataResource` object.
    func create(witherUsername username: String, password: String, customValues: [[String: String]]? = nil) -> DataResource<Credentials> {
        guard let username = username.encodeAsQueryParam(),
            let password = password.encodeAsQueryParam(),
            let clientId = clientId.encodeAsQueryParam() else {
                fatalError("Redirect URI and clientId must be url encodable")
        }

        // Parse and format custom values
        var customValuesString = ""
        if let customValues {
            customValuesString = customValues.map({
                $0.compactMap({
                    guard let key = $0.key.encodeAsQueryParam(), let value = $0.value.encodeAsQueryParam() else {
                        return nil
                    }

                    return "\(key)=\(value)"
                })
                .joined()
            })
            .joined(separator: "&")
        }

        // Build body data and send request
        var bodyString = "username=\(username)&password=\(password)&client_id=\(clientId)&grant_type=password"

        if !customValuesString.isEmpty {
            bodyString += "&\(customValuesString)"
        }

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
