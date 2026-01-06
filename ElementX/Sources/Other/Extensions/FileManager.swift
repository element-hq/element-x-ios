//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum FileManagerError: Error {
    case invalidFileSize
}

extension FileManager {
    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) else {
            return false
        }
        return isDirectory.boolValue
    }

    func createDirectoryIfNeeded(at url: URL, withIntermediateDirectories: Bool = true) throws {
        guard !directoryExists(at: url) else {
            return
        }
        try createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }
    
    func copyFileToTemporaryDirectory(file url: URL, with filename: String? = nil) throws -> URL {
        let newURL = URL.temporaryDirectory.appendingPathComponent(filename ?? url.lastPathComponent)
        
        try? removeItem(at: newURL)
        try copyItem(at: url, to: newURL)
        
        return newURL
    }

    @discardableResult
    func writeDataToTemporaryDirectory(data: Data, fileName: String, withinAppGroupContainer: Bool = false) throws -> URL {
        let baseURL: URL = withinAppGroupContainer ? .appGroupTemporaryDirectory : .temporaryDirectory
        let newURL = baseURL.appendingPathComponent(fileName)
        
        try data.write(to: newURL)
        
        return newURL
    }
    
    /// Retrieve a file's disk size
    /// - Parameter url: the file URL
    /// - Returns: the size in bytes
    func sizeForItem(at url: URL) throws -> UInt {
        let attributes = try attributesOfItem(atPath: url.path(percentEncoded: false))
        
        guard let size = attributes[FileAttributeKey.size] as? UInt else {
            throw FileManagerError.invalidFileSize
        }
        
        return size
    }

    func sizeForDirectory(at url: URL) throws -> UInt {
        guard let enumerator = enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) else {
            throw FileManagerError.invalidFileSize
        }
        
        return try enumerator
            .compactMap {
                guard let fileURL = $0 as? URL else { return nil }
                return try UInt(fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)
            }
            .reduce(0, +)
    }
    
    func numberOfItems(at url: URL) throws -> Int {
        try contentsOfDirectory(at: url, includingPropertiesForKeys: nil).count
    }
}
