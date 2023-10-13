//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
    private let cachedFileURL = URL("/cache/file/url")
    private let audioOGGMimeType = "audio/ogg"
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
        let cachedURL = try voiceMessageCache.cache(mediaSource: mediaSource, using: temporaryFileURL, move: true)
        
        XCTAssertEqual(cachedURL, voiceMessageCache.fileURL(for: mediaSource))
    }
    
    func testCacheInvalidFileExtension() async throws {
        // An error should be raised if the file extension is not "m4a"
        let mpegFileURL = try createTemporaryFile(named: testFilename, withExtension: "mpg")
        do {
            _ = try voiceMessageCache.cache(mediaSource: mediaSource, using: mpegFileURL, move: true)
            XCTFail("An error is expected")
        } catch {
            switch error as? VoiceMessageCacheError {
            case .invalidFileExtension:
                break
            default:
                XCTFail("A VoiceMessageCacheError.invalidFileExtension is expected")
            }
        }
    }
    
    func testCacheCopy() async throws {
        let fileURL = try createTemporaryFile(named: testFilename, withExtension: mpeg4aacFileExtension)
        let cacheURL = try voiceMessageCache.cache(mediaSource: mediaSource, using: fileURL, move: false)
        
        // The source file must remain in its original location
        XCTAssertTrue(fileManager.fileExists(atPath: fileURL.path()))
        // A copy must be present in the cache
        XCTAssertTrue(fileManager.fileExists(atPath: cacheURL.path()))
    }
    
    func testCacheMove() async throws {
        let fileURL = try createTemporaryFile(named: testFilename, withExtension: mpeg4aacFileExtension)
        let cacheURL = try voiceMessageCache.cache(mediaSource: mediaSource, using: fileURL, move: true)
        
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
