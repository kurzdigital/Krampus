//
//  DownloadedFilesManager.swift
//  Santa
//
//  Created by Christian Braun on 05.12.19.
//

import Foundation

struct DownloadedFilesManager {
    static func moveItemToDocuments(at location: URL, fileName: String) throws -> URL {
        let destinationUrl = try fileUrl(for: fileName)
        // Always override existing files
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            try FileManager.default.removeItem(at: destinationUrl)
        }
        try FileManager.default.moveItem(at: location, to: destinationUrl)
        return destinationUrl
    }

    static func removeItem(fileName: String) throws {
        let destinationUrl = try fileUrl(for: fileName)
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            try FileManager.default.removeItem(at: destinationUrl)
        }
    }

    static func fileUrl(for fileName: String) throws -> URL {
        let destinationFolder = try documentsUrl()
        return destinationFolder.appendingPathComponent(fileName)
    }

    fileprivate static func documentsUrl() throws -> URL {
        return try FileManager.default.url(for: .documentDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: nil,
                                           create: true)
    }
}
