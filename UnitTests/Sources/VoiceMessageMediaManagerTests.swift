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
class VoiceMessageMediaManagerTests: XCTestCase {
    private var voiceMessageMediaManager: VoiceMessageMediaManager!
    private var voiceMessageCache: VoiceMessageCacheMock!
    private var mediaProvider: MockMediaProvider!
    
    private let someURL = URL("/some/url")
    private let audioOGGMimeType = "audio/ogg"
    
    override func setUp() async throws {
        voiceMessageCache = VoiceMessageCacheMock()
        mediaProvider = MockMediaProvider()
        voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: mediaProvider,
                                                            voiceMessageCache: voiceMessageCache)
    }
    
    func testLoadVoiceMessageFromSourceUnsupportedMedia() async throws {
        // Only "audio/ogg" file are supported
        let unsupportedMediaSource = MediaSourceProxy(url: someURL, mimeType: "audio/wav")
        do {
            _ = try await voiceMessageMediaManager.loadVoiceMessageFromSource(unsupportedMediaSource, body: nil)
            XCTFail("A `VoiceMessageMediaManagerError.unsupportedMimeTye` error is expected")
        } catch {
            switch error as? VoiceMessageMediaManagerError {
            case .unsupportedMimeTye:
                break
            default:
                XCTFail("A `VoiceMessageMediaManagerError.unsupportedMimeTye` error is expected")
            }
        }
    }
    
    func testLoadVoiceMessageFromSourceMimeTypeWithParameters() async throws {
        // URL representing the file loaded by the media provider
        let loadedFile = URL("/some/url/loaded_file.ogg")
        // URL representing the final cached file
        let cachedConvertedFileURL = URL("/some/url/cached_converted_file.m4a")
        
        voiceMessageCache.fileURLForReturnValue = nil
        let mediaSource = MediaSourceProxy(url: someURL, mimeType: "audio/ogg; codecs=opus")
        mediaProvider.loadFileFromSourceReturnValue = MediaFileHandleProxy.unmanaged(url: loadedFile)
        voiceMessageCache.cacheMediaSourceUsingMoveReturnValue = .success(cachedConvertedFileURL)
        
        voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: mediaProvider,
                                                            voiceMessageCache: voiceMessageCache,
                                                            audioConverter: AudioConverterMock())
        
        do {
            _ = try await voiceMessageMediaManager.loadVoiceMessageFromSource(mediaSource, body: nil)
        } catch {
            XCTFail("An unexpected error has occured: \(error)")
        }
    }
    
    func testLoadVoiceMessageFromSourceAlreadyCached() async throws {
        // Check if the file is already present in cache
        voiceMessageCache.fileURLForReturnValue = URL("/converted_file/url")
        let mediaSource = MediaSourceProxy(url: someURL, mimeType: audioOGGMimeType)
        let url = try await voiceMessageMediaManager.loadVoiceMessageFromSource(mediaSource, body: nil)
        XCTAssertEqual(url, URL("/converted_file/url"))
        // The file must have be search in the cache
        XCTAssertTrue(voiceMessageCache.fileURLForCalled)
        XCTAssertEqual(voiceMessageCache.fileURLForReceivedMediaSource, mediaSource)
        // The file must not have been cached again
        XCTAssertFalse(voiceMessageCache.cacheMediaSourceUsingMoveCalled)
    }
    
    func testLoadVoiceMessageFromSourceMediaProviderError() async throws {
        // An error must be reported if the file cannot be retrieved
        do {
            voiceMessageCache.fileURLForReturnValue = nil
            let mediaSource = MediaSourceProxy(url: someURL, mimeType: audioOGGMimeType)
            _ = try await voiceMessageMediaManager.loadVoiceMessageFromSource(mediaSource, body: nil)
            XCTFail("A `MediaProviderError.failedRetrievingFile` error is expected")
        } catch {
            switch error as? MediaProviderError {
            case .failedRetrievingFile:
                break
            default:
                XCTFail("A `MediaProviderError.failedRetrievingFile` error is expected")
            }
        }
    }
    
    func testLoadVoiceMessageFromSourceSingleCall() async throws {
        // URL representing the file loaded by the media provider
        let loadedFile = URL("/some/url/loaded_file")
        // URL representing the final cached file
        let cachedConvertedFileURL = URL("/some/url/cached_converted_file")

        // Check if the file is not already present in cache
        voiceMessageCache.fileURLForReturnValue = nil
        let mediaSource = MediaSourceProxy(url: someURL, mimeType: audioOGGMimeType)
        mediaProvider.loadFileFromSourceReturnValue = MediaFileHandleProxy.unmanaged(url: loadedFile)
        let audioConverter = AudioConverterMock()
        voiceMessageCache.cacheMediaSourceUsingMoveReturnValue = .success(cachedConvertedFileURL)
        voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: mediaProvider,
                                                            voiceMessageCache: voiceMessageCache,
                                                            audioConverter: audioConverter)
        let url = try await voiceMessageMediaManager.loadVoiceMessageFromSource(mediaSource, body: nil)
        
        // The file must have been converted
        XCTAssertTrue(audioConverter.convertToMPEG4AACSourceURLDestinationURLCalled)
        // The converted file must have been cached
        XCTAssert(voiceMessageCache.cacheMediaSourceUsingMoveCalled)
        XCTAssertEqual(voiceMessageCache.cacheMediaSourceUsingMoveReceivedArguments?.mediaSource, mediaSource)
        XCTAssertEqual(voiceMessageCache.cacheMediaSourceUsingMoveReceivedArguments?.fileURL.pathExtension, "m4a")
        XCTAssertTrue(voiceMessageCache.cacheMediaSourceUsingMoveReceivedArguments?.move ?? false)
        // The returned URL must point to the cached converted file
        XCTAssertEqual(url, cachedConvertedFileURL)
    }
     
    func testLoadVoiceMessageFromSourceMultipleCalls() async throws {
        // URL representing the file loaded by the media provider
        let loadedFile = URL("/some/url/loaded_file")
        // URL representing the final cached file
        let cachedConvertedFileURL = URL("/some/url/cached_converted_file")
        
        // Multiple calls
        var cachedURL: URL?
        voiceMessageCache.fileURLForClosure = { _ in
            cachedURL
        }
        voiceMessageCache.cacheMediaSourceUsingMoveClosure = { _, _, _ in
            cachedURL = cachedConvertedFileURL
            return .success(cachedConvertedFileURL)
        }
        
        let audioConverter = AudioConverterMock()
        mediaProvider.loadFileFromSourceReturnValue = MediaFileHandleProxy.unmanaged(url: loadedFile)

        voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: mediaProvider,
                                                            voiceMessageCache: voiceMessageCache,
                                                            audioConverter: audioConverter)
        
        let mediaSource = MediaSourceProxy(url: someURL, mimeType: audioOGGMimeType)
        for _ in 0..<10 {
            let url = try await voiceMessageMediaManager.loadVoiceMessageFromSource(mediaSource, body: nil)
            XCTAssertEqual(url, cachedConvertedFileURL)
        }
     
        // The file must have been converted only once
        XCTAssertEqual(audioConverter.convertToMPEG4AACSourceURLDestinationURLCallsCount, 1)

        // The converted file must have been cached only once
        XCTAssertEqual(voiceMessageCache.cacheMediaSourceUsingMoveCallsCount, 1)
    }
}
