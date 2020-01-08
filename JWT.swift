//
//  JWT.swift
//  Krampus
//
//  Created by Christian Braun on 07.01.20.
//

import Foundation

public struct JWT {
    public let payload: [String: Any]

    init?(with accessToken: String) {
        let webTokenElements = accessToken.split(separator: ".")
        guard webTokenElements.count == 3,
            let payloadData = Data.resilientBase64Decoded(from: String(webTokenElements[1])),
            let payload = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else {
                return nil
        }
        self.payload = payload
    }
}

public extension Data {
    var hexDescription: String {
        return reduce("") { $0 + String(format: "%02x", $1) }
    }

    static func resilientBase64Decoded(from encoded: String) -> Data? {
        var mutableEncoded = encoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Works only when decoding strictly byte based data.
        // Base64 can encode 6 bytes in a single char. Every char in a string consumes 8 bytes
        // this means if the number of encoded bytes in the base64 data is not a multiple of 8
        // there are fill bytes (=) missing.
        let remainder = encoded.count % 4
        if remainder > 0 {
            mutableEncoded = mutableEncoded.padding(toLength: encoded.count + 4 - remainder, withPad: "=", startingAt: 0)
        }

        return Data(base64Encoded: mutableEncoded)
    }
}
