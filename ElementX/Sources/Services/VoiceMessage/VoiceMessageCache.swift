//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

class VoiceMessageCache: VoiceMessageCacheProtocol {
    private let preferredFileExtension = "m4a"
    private var temporaryFilesFolderURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("media/voice-message")
    }
    
    var urlForRecording: URL {
        // Make sure the directory exist
        setupTemporaryFilesFolder()
        return temporaryFilesFolderURL.appendingPathComponent("voice-message-recording").appendingPathExtension(preferredFileExtension)
    }
    
    func fileURL(for mediaSource: MediaSourceProxy) -> URL? {
        let url = cacheURL(for: mediaSource)
        return FileManager.default.fileExists(atPath: url.path()) ? url : nil
    }
    
    func cache(mediaSource: MediaSourceProxy, using fileURL: URL, move: Bool = false) -> Result<URL, VoiceMessageCacheError> {
        guard fileURL.pathExtension == preferredFileExtension else {
            return .failure(.invalidFileExtension)
        }
        let url = cacheURL(for: mediaSource)
        do {
            try cacheFile(source: fileURL, destination: url, move: move)
        } catch {
            MXLog.error("Failed storing file in cache. \(error)")
            return .failure(.failedStoringFileInCache)
        }
        return .success(url)
    }
        
    func clearCache() {
        if FileManager.default.fileExists(atPath: temporaryFilesFolderURL.path) {
            do {
                try FileManager.default.removeItem(at: temporaryFilesFolderURL)
            } catch {
                MXLog.error("Failed clearing cached disk files. \(error)")
            }
        }
    }
    
    // MARK: - Private
    
    private func setupTemporaryFilesFolder() {
        do {
            try FileManager.default.createDirectoryIfNeeded(at: temporaryFilesFolderURL, withIntermediateDirectories: true)
        } catch {
            MXLog.error("Failed to setup audio cache manager.")
        }
    }
    
    private func cacheFile(source: URL, destination: URL, move: Bool) throws {
        setupTemporaryFilesFolder()
        try? FileManager.default.removeItem(at: destination)
        if move {
            try FileManager.default.moveItem(at: source, to: destination)
        } else {
            try FileManager.default.copyItem(at: source, to: destination)
        }
        try (destination as NSURL).setResourceValue(URLFileProtection.complete, forKey: .fileProtectionKey)
    }
    
    private func cacheURL(for mediaSource: MediaSourceProxy) -> URL {
        temporaryFilesFolderURL.appendingPathComponent(mediaSource.url.lastPathComponent).appendingPathExtension(preferredFileExtension)
    }
}
