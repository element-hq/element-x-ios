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
struct VoiceMessageMediaManagerTests {
    private var voiceMessageMediaManager: VoiceMessageMediaManager
    private var voiceMessageCache: VoiceMessageCacheMock
    private var mediaProvider: MediaProviderMock
    
    private let someURL = URL.mockMXCAudio
    private let audioOGGMimeType = "audio/ogg"
    
    init() {
        voiceMessageCache = VoiceMessageCacheMock()
        mediaProvider = MediaProviderMock(configuration: .init())
        mediaProvider.loadFileFromSourceFilenameClosure = nil
        mediaProvider.loadFileFromSourceFilenameReturnValue = .failure(.failedRetrievingFile)
        voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: mediaProvider,
                                                            voiceMessageCache: voiceMessageCache)
    }
    
    @Test
    func loadVoiceMessageFromSourceUnsupportedMedia() async throws {
        // Only "audio/ogg" file are supported
        let unsupportedMediaSource = try MediaSourceProxy(url: someURL, mimeType: "audio/wav")
        do {
            _ = try await voiceMessageMediaManager.loadVoiceMessageFromSource(unsupportedMediaSource, body: nil)
            Issue.record("A `VoiceMessageMediaManagerError.unsupportedMimeTye` error is expected")
        } catch {
            switch error as? VoiceMessageMediaManagerError {
            case .unsupportedMimeTye:
                break
            default:
                Issue.record("A `VoiceMessageMediaManagerError.unsupportedMimeTye` error is expected")
            }
        }
    }
    
    @Test
    func loadVoiceMessageFromSourceMimeTypeWithParameters() async throws {
        var testSetup = self
        // URL representing the file loaded by the media provider
        let loadedFile = URL("/some/url/loaded_file.ogg")
        // URL representing the final cached file
        let cachedConvertedFileURL = URL("/some/url/cached_converted_file.m4a")
        
        testSetup.voiceMessageCache.fileURLForReturnValue = nil
        let mediaSource = try MediaSourceProxy(url: testSetup.someURL, mimeType: "audio/ogg; codecs=opus")
        testSetup.mediaProvider.loadFileFromSourceFilenameReturnValue = .success(MediaFileHandleProxy.unmanaged(url: loadedFile))
        testSetup.voiceMessageCache.cacheMediaSourceUsingMoveReturnValue = .success(cachedConvertedFileURL)
        
        testSetup.voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: testSetup.mediaProvider,
                                                                      voiceMessageCache: testSetup.voiceMessageCache,
                                                                      audioConverter: AudioConverterMock())
        
        do {
            _ = try await testSetup.voiceMessageMediaManager.loadVoiceMessageFromSource(mediaSource, body: nil)
        } catch {
            Issue.record("An unexpected error has occured: \(error)")
        }
    }
    
    @Test
    func loadVoiceMessageFromSourceAlreadyCached() async throws {
        var testSetup = self
        // Check if the file is already present in cache
        testSetup.voiceMessageCache.fileURLForReturnValue = URL("/converted_file/url")
        let mediaSource = try MediaSourceProxy(url: testSetup.someURL, mimeType: testSetup.audioOGGMimeType)
        let url = try await testSetup.voiceMessageMediaManager.loadVoiceMessageFromSource(mediaSource, body: nil)
        #expect(url == URL("/converted_file/url"))
        // The file must have be search in the cache
        #expect(testSetup.voiceMessageCache.fileURLForCalled)
        #expect(testSetup.voiceMessageCache.fileURLForReceivedMediaSource == mediaSource)
        // The file must not have been cached again
        #expect(!testSetup.voiceMessageCache.cacheMediaSourceUsingMoveCalled)
    }
    
    @Test
    func loadVoiceMessageFromSourceMediaProviderError() async throws {
        var testSetup = self
        // An error must be reported if the file cannot be retrieved
        do {
            testSetup.voiceMessageCache.fileURLForReturnValue = nil
            let mediaSource = try MediaSourceProxy(url: testSetup.someURL, mimeType: testSetup.audioOGGMimeType)
            _ = try await testSetup.voiceMessageMediaManager.loadVoiceMessageFromSource(mediaSource, body: nil)
            Issue.record("A `MediaProviderError.failedRetrievingFile` error is expected")
        } catch {
            switch error as? MediaProviderError {
            case .failedRetrievingFile:
                break
            default:
                Issue.record("A `MediaProviderError.failedRetrievingFile` error is expected")
            }
        }
    }
    
    @Test
    func loadVoiceMessageFromSourceSingleCall() async throws {
        var testSetup = self
        // URL representing the file loaded by the media provider
        let loadedFile = URL("/some/url/loaded_file")
        // URL representing the final cached file
        let cachedConvertedFileURL = URL("/some/url/cached_converted_file")

        // Check if the file is not already present in cache
        testSetup.voiceMessageCache.fileURLForReturnValue = nil
        let mediaSource = try MediaSourceProxy(url: testSetup.someURL, mimeType: testSetup.audioOGGMimeType)
        testSetup.mediaProvider.loadFileFromSourceFilenameReturnValue = .success(MediaFileHandleProxy.unmanaged(url: loadedFile))
        let audioConverter = AudioConverterMock()
        testSetup.voiceMessageCache.cacheMediaSourceUsingMoveReturnValue = .success(cachedConvertedFileURL)
        testSetup.voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: testSetup.mediaProvider,
                                                                      voiceMessageCache: testSetup.voiceMessageCache,
                                                                      audioConverter: audioConverter)
        let url = try await testSetup.voiceMessageMediaManager.loadVoiceMessageFromSource(mediaSource, body: nil)
        
        // The file must have been converted
        #expect(audioConverter.convertToMPEG4AACSourceURLDestinationURLCalled)
        // The converted file must have been cached
        #expect(testSetup.voiceMessageCache.cacheMediaSourceUsingMoveCalled)
        #expect(testSetup.voiceMessageCache.cacheMediaSourceUsingMoveReceivedArguments?.mediaSource == mediaSource)
        #expect(testSetup.voiceMessageCache.cacheMediaSourceUsingMoveReceivedArguments?.fileURL.pathExtension == "m4a")
        #expect(testSetup.voiceMessageCache.cacheMediaSourceUsingMoveReceivedArguments?.move ?? false)
        // The returned URL must point to the cached converted file
        #expect(url == cachedConvertedFileURL)
    }
     
    @Test
    func loadVoiceMessageFromSourceMultipleCalls() async throws {
        var testSetup = self
        // URL representing the file loaded by the media provider
        let loadedFile = URL("/some/url/loaded_file")
        // URL representing the final cached file
        let cachedConvertedFileURL = URL("/some/url/cached_converted_file")
        
        // Multiple calls
        var cachedURL: URL?
        testSetup.voiceMessageCache.fileURLForClosure = { _ in
            cachedURL
        }
        testSetup.voiceMessageCache.cacheMediaSourceUsingMoveClosure = { _, _, _ in
            cachedURL = cachedConvertedFileURL
            return .success(cachedConvertedFileURL)
        }
        
        let audioConverter = AudioConverterMock()
        testSetup.mediaProvider.loadFileFromSourceFilenameReturnValue = .success(MediaFileHandleProxy.unmanaged(url: loadedFile))

        testSetup.voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: testSetup.mediaProvider,
                                                                      voiceMessageCache: testSetup.voiceMessageCache,
                                                                      audioConverter: audioConverter)
        
        let mediaSource = try MediaSourceProxy(url: testSetup.someURL, mimeType: testSetup.audioOGGMimeType)
        for _ in 0..<10 {
            let url = try await testSetup.voiceMessageMediaManager.loadVoiceMessageFromSource(mediaSource, body: nil)
            #expect(url == cachedConvertedFileURL)
        }
     
        // The file must have been converted only once
        #expect(audioConverter.convertToMPEG4AACSourceURLDestinationURLCallsCount == 1)

        // The converted file must have been cached only once
        #expect(testSetup.voiceMessageCache.cacheMediaSourceUsingMoveCallsCount == 1)
    }
}
