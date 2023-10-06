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
    private let cache: VoiceMessageCache
    
    private let backgroundTaskService: BackgroundTaskServiceProtocol?
    private let processingQueue: DispatchQueue
    private var ongoingRequests = [MediaSourceProxy: VoiceMessageConversionRequest]()
    
    private let supportedVoiceMessageMimeType = "audio/ogg"
    
    init(mediaProvider: MediaProviderProtocol,
         processingQueue: DispatchQueue = .global(),
         backgroundTaskService: BackgroundTaskServiceProtocol?) {
        self.mediaProvider = mediaProvider
        cache = VoiceMessageCache()
        self.processingQueue = processingQueue
        self.backgroundTaskService = backgroundTaskService
    }

    deinit {
        cache.clearCache()
    }
    
    func loadVoiceMessageFromSource(_ source: MediaSourceProxy, body: String?) async throws -> URL {
        guard let mimeType = source.mimeType, mimeType == supportedVoiceMessageMimeType else {
            throw VoiceMessageMediaManagerError.unsupportedMimeTye
        }
        
        // Do we already have a converted version?
        if let fileURL = cache.fileURL(for: source) {
            return fileURL
        }
        
        // Otherwise, load the file from source
        guard case .success(let fileHandle) = await mediaProvider.loadFileFromSource(source, body: body) else {
            throw MediaProviderError.failedRetrievingFile
        }
        
        let url = try await enqueueVoiceMessageConversionRequest(forSource: source) { [cache] in
            // Convert from ogg
            let convertedFileURL = try AudioConverter.convertToMPEG4AAC(sourceURL: fileHandle.url)

            // Cache the file and return the url
            return try cache.cache(mediaSource: source, using: convertedFileURL, move: true)
        }
        
        return url
    }
    
    // MARK: - Private
    
    private func enqueueVoiceMessageConversionRequest(forSource source: MediaSourceProxy, operation: @escaping () throws -> URL) async throws -> URL {
        if let ongoingRequest = ongoingRequests[source] {
            return try await withCheckedThrowingContinuation { continuation in
                ongoingRequest.continuations.append(continuation)
            }
        }
        
        let ongoingRequest = VoiceMessageConversionRequest()
        ongoingRequests[source] = ongoingRequest
        
        defer {
            ongoingRequests[source] = nil
        }
        
        do {
            let result = try await Task.dispatch(on: processingQueue) {
                try operation()
            }
            
            ongoingRequest.continuations.forEach { $0.resume(returning: result) }
            
            return result
            
        } catch {
            ongoingRequest.continuations.forEach { $0.resume(throwing: error) }
            throw error
        }
    }
}
