//
//  KeycloakAuthorization.swift
//  Krampus
//
//  Created by Christian Braun on 06.12.19.
//

import Foundation
import Santa

extension KeycloakAuthorization {
    public enum AuthError: LocalizedError {
        case loginErrorMissingCredentials
        case loginNeeded
        case alreadyLoggedOut

        public var errorDescription: String? {
            switch self {
            case .loginErrorMissingCredentials:
                return "No credentials given"
            case .loginNeeded:
                return "Login required"
            case .alreadyLoggedOut:
                return "Try to logout while already logged out"
            }
        }
    }
}

public struct KeycloakAuthorization: Authorization {
    static var expirationTolerance: TimeInterval = 60

    public let baseUrl: String
    public let clientId: String
    public let realm: String
    public let redirectUrl: String
    public let keychain: KeycloakKeychain
    public let webservice: Webservice

    public var url: String {
        guard let url = URL(string: baseUrl) else {
            fatalError("Malformed base url")
        }
        return url
            .appendingPathComponent("auth/realms/\(realm)/protocol/openid-connect")
            .absoluteString
    }

    var tokenUrl: String {"\(url)/token"}
    var logoutUrl: String {"\(url)/logout"}

    #if DEBUG
    public var mockedCredentials: KeychainKeycloakCredentials?
    #endif

    var keychainKeycloakCredentials: KeychainKeycloakCredentials? {
        #if DEBUG
        if let mockedCredentials = mockedCredentials {
            return mockedCredentials
        }
        #endif
        return keychain.readCredentials()
    }

    public var loggedIn: Bool {
        guard let keychainKeycloakCredentials = keychainKeycloakCredentials else {
            return false
        }

        return keychainKeycloakCredentials.refreshTokenExpiresAt > Date() + KeycloakAuthorization.expirationTolerance
    }

    public func authorize(_ request: URLRequest, for resource: Resource, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var mutableRequest = request
        renewOrGetCredentials(for: resource) { result in
            switch result {
            case .success(let credentials):
                mutableRequest.addValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
                completion(Result.success(request))
            case .failure(let error):
                completion(Result.failure(error))
            }
        }
    }

    public func login(withUsername username: String, password: String, completion:  @escaping (Result<KeychainKeycloakCredentials, Error>) -> Void) {
        let resource = create(witherUsername: username, password: password)
        loadCredentials(resource: resource, completion: completion)
    }

    public func login(withAuthCode code: String, completion:  @escaping (Result<KeychainKeycloakCredentials, Error>) -> Void) {
        let resource = create(withAuthCode: code)
        loadCredentials(resource: resource, completion: completion)
    }

    public func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let refreshToken = keychainKeycloakCredentials?.refreshToken else {
            completion(Result.failure(AuthError.alreadyLoggedOut))
            return
        }
        // First delete the keychain entry then call logout endpoint
        do {
            try keychain.deleteCredentials()
            webservice.reset()
            webservice.load(resource: delete(refreshToken: refreshToken)) { _, error in
                if let error = error {
                    completion(Result.failure(error))
                } else {
                    completion(Result.success(Void()))
                }
            }
        } catch {
            completion(Result.failure(error))
        }
    }
}

extension KeycloakAuthorization {
    fileprivate func renewOrGetCredentials(for resource: Resource, completion: @escaping (Result<KeychainKeycloakCredentials, Error>) -> Void) {
        guard let credentials = keychainKeycloakCredentials else {
            completion(Result.failure(AuthError.loginErrorMissingCredentials))
            return
        }
        let now = Date()
        if credentials.accessTokenExpiresAt > now + KeycloakAuthorization.expirationTolerance {
            completion(Result.success(credentials))
        } else if credentials.refreshTokenExpiresAt > now + KeycloakAuthorization.expirationTolerance {
            let resource = refresh(refreshToken: credentials.refreshToken).update(uuid: resource.uuid)
            loadCredentials(resource: resource, completion: completion)
        } else {
            completion(Result.failure(AuthError.loginNeeded))
        }
    }

    fileprivate func loadCredentials(resource: DataResource<KeycloakCredentials>, completion: @escaping (Result<KeychainKeycloakCredentials, Error>) -> Void) {
        webservice.load(resource: resource) { credentials, error in
            if let error = error {
                if let error = error as? NetworkError {
                    switch error {
                    case .failedAuthorization,
                         .noInternetConnectivity:
                        // pass through to parent-errorhandler
                        completion(Result.failure(error))
                        return
                    case .badResponseCode,
                         .parseUrl,
                         .parseData,
                         .notFound:
                        // fallthrough do default-errorhandling
                        break
                    }
                }

                let error = error as NSError
                if error.domain == NSURLErrorDomain &&
                    error.code == NSURLErrorNotConnectedToInternet {
                    completion(Result.failure(NetworkError.noInternetConnectivity))
                } else {
                    completion(Result.failure(AuthError.loginNeeded))
                }
            } else if let credentials = credentials {
                do {
                    let keychainCredentials = try self.keychain.saveCredentials(credentials)
                    completion(Result.success(keychainCredentials))
                } catch {
                    completion(Result.failure(error))
                }
            } else {
                completion(Result.failure(AuthError.loginErrorMissingCredentials))
            }
        }
    }
}

