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

import Foundation

enum VoiceMessageMediaManagerError: Error {
    case unsupportedMimeTye
}

private final class VoiceMessageConversionRequest {
    var continuations: [CheckedContinuation<URL, Error>] = []
}

class VoiceMessageMediaManager: VoiceMessageMediaManagerProtocol {
    private let mediaProvider: MediaProviderProtocol
    private let voiceMessageCache: VoiceMessageCacheProtocol
    private let audioConverter: AudioConverterProtocol
    
    private let backgroundTaskService: BackgroundTaskServiceProtocol?
    private let processingQueue: DispatchQueue
    private var conversionRequests = [MediaSourceProxy: VoiceMessageConversionRequest]()
    
    private let supportedVoiceMessageMimeType = "audio/ogg"
    
    init(mediaProvider: MediaProviderProtocol,
         voiceMessageCache: VoiceMessageCacheProtocol = VoiceMessageCache(),
         audioConverter: AudioConverterProtocol = AudioConverter(),
         processingQueue: DispatchQueue = .global(),
         backgroundTaskService: BackgroundTaskServiceProtocol?) {
        self.mediaProvider = mediaProvider
        self.voiceMessageCache = voiceMessageCache
        self.audioConverter = audioConverter
        self.processingQueue = processingQueue
        self.backgroundTaskService = backgroundTaskService
    }

    deinit {
        voiceMessageCache.clearCache()
    }
    
    func loadVoiceMessageFromSource(_ source: MediaSourceProxy, body: String?) async throws -> URL {
        let loadFileBgTask = await backgroundTaskService?.startBackgroundTask(withName: "LoadFile: \(source.url.hashValue)")
        defer { loadFileBgTask?.stop() }

        guard let mimeType = source.mimeType, mimeType == supportedVoiceMessageMimeType else {
            throw VoiceMessageMediaManagerError.unsupportedMimeTye
        }
        
        // Do we already have a converted version?
        if let fileURL = voiceMessageCache.fileURL(for: source) {
            return fileURL
        }
        
        // Otherwise, load the file from source
        guard case .success(let fileHandle) = await mediaProvider.loadFileFromSource(source, body: body) else {
            throw MediaProviderError.failedRetrievingFile
        }
        
        return try await enqueueVoiceMessageConversionRequest(forSource: source) { [audioConverter, voiceMessageCache] in
            // Do we already have a converted version?
            if let fileURL = voiceMessageCache.fileURL(for: source) {
                return fileURL
            }

            // Convert from ogg
            let convertedFileURL = try audioConverter.convertToMPEG4AAC(sourceURL: fileHandle.url)

            // Cache the file and return the url
            return try voiceMessageCache.cache(mediaSource: source, using: convertedFileURL, move: true)
        }
    }
    
    // MARK: - Private
    
    private func enqueueVoiceMessageConversionRequest(forSource source: MediaSourceProxy, operation: @escaping () throws -> URL) async throws -> URL {
        if let conversionRequests = conversionRequests[source] {
            return try await withCheckedThrowingContinuation { continuation in
                conversionRequests.continuations.append(continuation)
            }
        }
        
        let conversionRequest = VoiceMessageConversionRequest()
        conversionRequests[source] = conversionRequest
        
        defer {
            conversionRequests[source] = nil
        }
        
        do {
            let result = try await Task.dispatch(on: processingQueue) {
                try operation()
            }
            
            conversionRequest.continuations.forEach { $0.resume(returning: result) }
            
            return result
            
        } catch {
            conversionRequest.continuations.forEach { $0.resume(throwing: error) }
            throw error
        }
    }
}
