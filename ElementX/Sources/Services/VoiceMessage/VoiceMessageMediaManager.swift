//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum VoiceMessageMediaManagerError: Error {
    case unsupportedMimeTye
    case missingURL
}

private final class VoiceMessageConversionRequest {
    var continuations: [CheckedContinuation<URL, Error>] = []
}

class VoiceMessageMediaManager: VoiceMessageMediaManagerProtocol {
    private let mediaProvider: MediaProviderProtocol
    private let voiceMessageCache: VoiceMessageCacheProtocol
    private let audioConverter: AudioConverterProtocol
    
    private let processingQueue: DispatchQueue
    private var conversionRequests = [MediaSourceProxy: VoiceMessageConversionRequest]()
    
    private let supportedVoiceMessageMimeType = "audio/ogg"
    
    init(mediaProvider: MediaProviderProtocol,
         voiceMessageCache: VoiceMessageCacheProtocol = VoiceMessageCache(),
         audioConverter: AudioConverterProtocol = AudioConverter(),
         processingQueue: DispatchQueue = .global()) {
        self.mediaProvider = mediaProvider
        self.voiceMessageCache = voiceMessageCache
        self.audioConverter = audioConverter
        self.processingQueue = processingQueue
    }

    deinit {
        voiceMessageCache.clearCache()
    }
    
    func loadVoiceMessageFromSource(_ source: MediaSourceProxy, body: String?) async throws -> URL {
        guard let mimeType = source.mimeType, mimeType.starts(with: supportedVoiceMessageMimeType) else {
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
            guard let url = fileHandle.url else {
                throw VoiceMessageMediaManagerError.missingURL
            }
            let convertedFileURL = URL.temporaryDirectory.appendingPathComponent(url.deletingPathExtension().lastPathComponent).appendingPathExtension(AudioConverterPreferredFileExtension.mpeg4aac.rawValue)
            try audioConverter.convertToMPEG4AAC(sourceURL: url, destinationURL: convertedFileURL)

            // Cache the file and return the url
            let result = voiceMessageCache.cache(mediaSource: source, using: convertedFileURL, move: true)
            switch result {
            case .success(let url):
                return url
            case .failure(let error):
                throw error
            }
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
