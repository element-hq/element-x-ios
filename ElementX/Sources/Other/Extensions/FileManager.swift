//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    func writeDataToTemporaryDirectory(data: Data, fileName: String) throws -> URL {
        let newURL = URL.temporaryDirectory.appendingPathComponent(fileName)
        
        try data.write(to: newURL)
        
        return newURL
    }
    
    /// Retrieve a file's disk size
    /// - Parameter url: the file URL
    /// - Returns: the size in bytes
    func sizeForItem(at url: URL) throws -> Double {
        let attributes = try attributesOfItem(atPath: url.path())
        
        guard let size = attributes[FileAttributeKey.size] as? Double else {
            throw FileManagerError.invalidFileSize
        }
        
        return size
    }
    
    func numberOfItems(at url: URL) throws -> Int {
        try contentsOfDirectory(at: url, includingPropertiesForKeys: nil).count
    }
}
