//
//  DownloadedFilesManager.swift
//  Santa
//
//  Created by Christian Braun on 05.12.19.
//

import Foundation

public struct DownloadedFilesManager {
    public static func moveItemToDocuments(at location: URL, fileName: String) throws -> URL {
        let destinationUrl = try fileUrl(for: fileName)
        // Always override existing files
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            try FileManager.default.removeItem(at: destinationUrl)
        }
        try FileManager.default.moveItem(at: location, to: destinationUrl)
        return destinationUrl
    }

    public static func removeItem(fileName: String) throws {
        let destinationUrl = try fileUrl(for: fileName)
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            try FileManager.default.removeItem(at: destinationUrl)
        }
    }

    public static func exists(fileName: String) -> Bool {
        do {
            let destinationUrl = try fileUrl(for: fileName)
            return FileManager.default.fileExists(atPath: destinationUrl.path)
        } catch {
            return false
        }
    }

    public static func fileUrl(for fileName: String) throws -> URL {
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
