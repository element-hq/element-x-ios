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
@Suite(.serialized)
struct VoiceMessageCacheTests {
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
    
    @Test
    func fileURL() throws {
        var testSetup = self
        defer {
            testSetup.voiceMessageCache.clearCache()
            try? testSetup.fileManager.removeItem(at: testSetup.testTemporaryDirectory)
        }
        
        // If the file is not already in the cache, no URL is expected
        #expect(testSetup.voiceMessageCache.fileURL(for: testSetup.mediaSource) == nil)
        
        // If the file is present in the cache, its URL must be returned
        let temporaryFileURL = try testSetup.createTemporaryFile(named: testSetup.testFilename, withExtension: testSetup.mpeg4aacFileExtension)
        guard case .success(let cachedURL) = testSetup.voiceMessageCache.cache(mediaSource: testSetup.mediaSource, using: temporaryFileURL, move: true) else {
            Issue.record("A success is expected")
            return
        }
        
        #expect(cachedURL == testSetup.voiceMessageCache.fileURL(for: testSetup.mediaSource))
    }
    
    @Test
    func cacheInvalidFileExtension() throws {
        var testSetup = self
        defer {
            testSetup.voiceMessageCache.clearCache()
            try? testSetup.fileManager.removeItem(at: testSetup.testTemporaryDirectory)
        }
        
        // An error should be raised if the file extension is not "m4a"
        let mpegFileURL = try testSetup.createTemporaryFile(named: testSetup.testFilename, withExtension: "mpg")
        guard case .failure(let error) = testSetup.voiceMessageCache.cache(mediaSource: testSetup.mediaSource, using: mpegFileURL, move: true) else {
            Issue.record("An error is expected")
            return
        }
        
        #expect(error == .invalidFileExtension)
    }
    
    @Test
    func cacheCopy() throws {
        var testSetup = self
        defer {
            testSetup.voiceMessageCache.clearCache()
            try? testSetup.fileManager.removeItem(at: testSetup.testTemporaryDirectory)
        }
        
        let fileURL = try testSetup.createTemporaryFile(named: testSetup.testFilename, withExtension: testSetup.mpeg4aacFileExtension)
        guard case .success(let cacheURL) = testSetup.voiceMessageCache.cache(mediaSource: testSetup.mediaSource, using: fileURL, move: false) else {
            Issue.record("A success is expected")
            return
        }
        
        // The source file must remain in its original location
        #expect(testSetup.fileManager.fileExists(atPath: fileURL.path()))
        // A copy must be present in the cache
        #expect(testSetup.fileManager.fileExists(atPath: cacheURL.path()))
    }
    
    @Test
    func cacheMove() throws {
        var testSetup = self
        defer {
            testSetup.voiceMessageCache.clearCache()
            try? testSetup.fileManager.removeItem(at: testSetup.testTemporaryDirectory)
        }
        
        let fileURL = try testSetup.createTemporaryFile(named: testSetup.testFilename, withExtension: testSetup.mpeg4aacFileExtension)
        guard case .success(let cacheURL) = testSetup.voiceMessageCache.cache(mediaSource: testSetup.mediaSource, using: fileURL, move: true) else {
            Issue.record("A success is expected")
            return
        }
        
        // The file must have been moved
        #expect(!testSetup.fileManager.fileExists(atPath: fileURL.path()))
        #expect(testSetup.fileManager.fileExists(atPath: cacheURL.path()))
    }
    
    private func createTemporaryFile(named filename: String, withExtension fileExtension: String) throws -> URL {
        let temporaryFileURL = testTemporaryDirectory.appendingPathComponent(filename).appendingPathExtension(fileExtension)
        try Data().write(to: temporaryFileURL)
        return temporaryFileURL
    }
}
