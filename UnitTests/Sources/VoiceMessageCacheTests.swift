//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@MainActor
@Suite
final class VoiceMessageCacheTests {
    private var voiceMessageCache: VoiceMessageCache
    private var mediaSource: MediaSourceProxy
    private let fileManager: FileManager
    
    private let someURL = URL.mockMXCAudio
    private let testFilename = "test-file"
    private let mpeg4aacFileExtension = "m4a"
    private let testTemporaryDirectory = URL.temporaryDirectory.appendingPathComponent("test-voice-messsage-cache")
    
    init() throws {
        voiceMessageCache = VoiceMessageCache()
        voiceMessageCache.clearCache()
        
        fileManager = FileManager.default
        mediaSource = try MediaSourceProxy(url: someURL, mimeType: "audio/ogg")
        
        // Create the temporary directory we will use
        try fileManager.createDirectory(at: testTemporaryDirectory, withIntermediateDirectories: true)
    }
    
    deinit {
        voiceMessageCache.clearCache()
        try? fileManager.removeItem(at: testTemporaryDirectory)
    }
    
    @Test
    func fileURL() throws {
        // If the file is not already in the cache, no URL is expected
        #expect(voiceMessageCache.fileURL(for: mediaSource) == nil)
        
        // If the file is present in the cache, its URL must be returned
        let temporaryFileURL = try createTemporaryFile(named: testFilename, withExtension: mpeg4aacFileExtension)
        guard case .success(let cachedURL) = voiceMessageCache.cache(mediaSource: mediaSource, using: temporaryFileURL, move: true) else {
            Issue.record("A success is expected")
            return
        }
        
        #expect(cachedURL == voiceMessageCache.fileURL(for: mediaSource))
    }
    
    @Test
    func cacheInvalidFileExtension() throws {
        // An error should be raised if the file extension is not "m4a"
        let mpegFileURL = try createTemporaryFile(named: testFilename, withExtension: "mpg")
        guard case .failure(let error) = voiceMessageCache.cache(mediaSource: mediaSource, using: mpegFileURL, move: true) else {
            Issue.record("An error is expected")
            return
        }
        
        #expect(error == .invalidFileExtension)
    }
    
    @Test
    func cacheCopy() throws {
        let fileURL = try createTemporaryFile(named: testFilename, withExtension: mpeg4aacFileExtension)
        guard case .success(let cacheURL) = voiceMessageCache.cache(mediaSource: mediaSource, using: fileURL, move: false) else {
            Issue.record("A success is expected")
            return
        }
        
        // The source file must remain in its original location
        #expect(fileManager.fileExists(atPath: fileURL.path()))
        // A copy must be present in the cache
        #expect(fileManager.fileExists(atPath: cacheURL.path()))
    }
    
    @Test
    func cacheMove() throws {
        let fileURL = try createTemporaryFile(named: testFilename, withExtension: mpeg4aacFileExtension)
        guard case .success(let cacheURL) = voiceMessageCache.cache(mediaSource: mediaSource, using: fileURL, move: true) else {
            Issue.record("A success is expected")
            return
        }
        
        // The file must have been moved
        #expect(!fileManager.fileExists(atPath: fileURL.path()))
        #expect(fileManager.fileExists(atPath: cacheURL.path()))
    }
    
    private func createTemporaryFile(named filename: String, withExtension fileExtension: String) throws -> URL {
        let temporaryFileURL = testTemporaryDirectory.appendingPathComponent(filename).appendingPathExtension(fileExtension)
        try Data().write(to: temporaryFileURL)
        return temporaryFileURL
    }
}
