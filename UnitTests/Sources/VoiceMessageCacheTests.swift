//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import XCTest

@MainActor
class VoiceMessageCacheTests: XCTestCase {
    private var voiceMessageCache: VoiceMessageCache!
    private var mediaSource: MediaSourceProxy!
    private var fileManager: FileManager!
    
    private let someURL = URL("/some/url")
    private let testFilename = "test-file"
    private let mpeg4aacFileExtension = "m4a"
    private let testTemporaryDirectory = URL.temporaryDirectory.appendingPathComponent("test-voice-messsage-cache")
    
    override func setUp() async throws {
        voiceMessageCache = VoiceMessageCache()
        voiceMessageCache.clearCache()
        
        fileManager = FileManager.default
        mediaSource = MediaSourceProxy(url: someURL, mimeType: "audio/ogg")
        
        // Create the temporary directory we will use
        try fileManager.createDirectory(at: testTemporaryDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        voiceMessageCache.clearCache()
        
        // clear the test temporary directory
        try fileManager.removeItem(at: testTemporaryDirectory)
    }
    
    func testFileURL() async throws {
        // If the file is not already in the cache, no URL is expected
        XCTAssertNil(voiceMessageCache.fileURL(for: mediaSource))
        
        // If the file is present in the cache, its URL must be returned
        let temporaryFileURL = try createTemporaryFile(named: testFilename, withExtension: mpeg4aacFileExtension)
        guard case .success(let cachedURL) = voiceMessageCache.cache(mediaSource: mediaSource, using: temporaryFileURL, move: true) else {
            XCTFail("A success is expected")
            return
        }
        
        XCTAssertEqual(cachedURL, voiceMessageCache.fileURL(for: mediaSource))
    }
    
    func testCacheInvalidFileExtension() async throws {
        // An error should be raised if the file extension is not "m4a"
        let mpegFileURL = try createTemporaryFile(named: testFilename, withExtension: "mpg")
        guard case .failure(let error) = voiceMessageCache.cache(mediaSource: mediaSource, using: mpegFileURL, move: true) else {
            XCTFail("An error is expected")
            return
        }
        
        XCTAssertEqual(error, .invalidFileExtension)
    }
    
    func testCacheCopy() async throws {
        let fileURL = try createTemporaryFile(named: testFilename, withExtension: mpeg4aacFileExtension)
        guard case .success(let cacheURL) = voiceMessageCache.cache(mediaSource: mediaSource, using: fileURL, move: false) else {
            XCTFail("A success is expected")
            return
        }
        
        // The source file must remain in its original location
        XCTAssertTrue(fileManager.fileExists(atPath: fileURL.path()))
        // A copy must be present in the cache
        XCTAssertTrue(fileManager.fileExists(atPath: cacheURL.path()))
    }
    
    func testCacheMove() async throws {
        let fileURL = try createTemporaryFile(named: testFilename, withExtension: mpeg4aacFileExtension)
        guard case .success(let cacheURL) = voiceMessageCache.cache(mediaSource: mediaSource, using: fileURL, move: true) else {
            XCTFail("A success is expected")
            return
        }
        
        // The file must have been moved
        XCTAssertFalse(fileManager.fileExists(atPath: fileURL.path()))
        XCTAssertTrue(fileManager.fileExists(atPath: cacheURL.path()))
    }
    
    private func createTemporaryFile(named filename: String, withExtension fileExtension: String) throws -> URL {
        let temporaryFileURL = testTemporaryDirectory.appendingPathComponent(filename).appendingPathExtension(fileExtension)
        try Data().write(to: temporaryFileURL)
        return temporaryFileURL
    }
}
