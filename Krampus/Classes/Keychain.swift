//
//  Keychain.swift
//  Krampus
//
//  Created by Christian Braun on 06.12.19.
//

import Foundation

/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 A struct for accessing generic password keychain items.
 */

/// Taken from the GenericKeychain example from apple (Version 4.0)
public struct Keychain {
    // MARK: Types

    enum KeychainError: Error {
        case unhandledError(status: OSStatus)
    }

    // MARK: Convenience

    public static func query(_ serviceName: String) -> [String: AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = serviceName as AnyObject?
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        return query
    }

    // MARK: - Helper

    public static func delete(serviceName: String) throws {
        // Delete the existing item from the keychain.
        let query = Keychain.query(serviceName)
        let status = SecItemDelete(query as CFDictionary)

        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }

    public static func save<T: Codable>(object: T, serviceName: String) throws {
        let data: Data = {
            do {
                let data = try JSONEncoder().encode(object)
                return data
            } catch {
                preconditionFailure("Unable to encode")
            }
        }()
        let query = Keychain.query(serviceName)
        // This is needed as readQuery is a generic functions and needs to infer the type before the
        // value can be evaluated
        let authData: T? = readQuery(query)
        if authData != nil {
            // Update the existing item with the new credentials.
            var attributesToUpdate = [String: AnyObject]()
            attributesToUpdate[kSecValueData as String] = data as AnyObject?

            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        } else {
            /*
             No credentials was found in the keychain. Create a dictionary to save
             as a new keychain item.
             */
            var newItem = Keychain.query(serviceName)
            newItem[kSecValueData as String] = data as AnyObject?

            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)

            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
    }

    public static func readQuery<T: Codable>(_ query: [String: AnyObject]) -> T? {
        var query = query
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue

        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        // Check the return status
        guard status != errSecItemNotFound,
            status == noErr  else {
                return nil
        }

        // Parse the credentials string from the query result.
        guard let existingItem = queryResult as? [String: AnyObject],
            let credentialsData = existingItem[kSecValueData as String] as? Data,
            let credentials = try? JSONDecoder().decode(T.self, from: credentialsData)
            else {
                return nil
        }

        return credentials
    }
}
