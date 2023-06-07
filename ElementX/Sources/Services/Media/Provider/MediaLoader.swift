//
// Copyright 2022 New Vector Ltd
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
import Foundation
import MatrixRustSDK
import UIKit

private final class MediaRequest {
    var continuations: [CheckedContinuation<Data, Error>] = []
}

actor MediaLoader: MediaLoaderProtocol {
    private let client: ClientProtocol
    private let clientQueue: DispatchQueue
    private var ongoingRequests = [MediaSourceProxy: MediaRequest]()

    init(client: ClientProtocol,
         clientQueue: DispatchQueue = .global()) {
        self.client = client
        self.clientQueue = clientQueue
    }
    
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await enqueueLoadMediaRequest(forSource: source) {
            try self.client.getMediaContent(mediaSource: source.underlyingSource)
        }
    }
    
    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await enqueueLoadMediaRequest(forSource: source) {
            try self.client.getMediaThumbnail(mediaSource: source.underlyingSource, width: UInt64(width), height: UInt64(height))
        }
    }
    
    func loadMediaFileForSource(_ source: MediaSourceProxy, body: String?) async throws -> MediaFileHandleProxy {
        let result = try await Task.dispatch(on: clientQueue) {
            try self.client.getMediaFile(mediaSource: source.underlyingSource, body: body, mimeType: source.mimeType ?? "application/octet-stream", tempDir: nil)
        }
        
        return MediaFileHandleProxy(handle: result)
    }
    
    // MARK: - Private
    
    private func enqueueLoadMediaRequest(forSource source: MediaSourceProxy, operation: @escaping () throws -> [UInt8]) async throws -> Data {
        if let ongoingRequest = ongoingRequests[source] {
            return try await withCheckedThrowingContinuation { continuation in
                ongoingRequest.continuations.append(continuation)
            }
        }
        
        let ongoingRequest = MediaRequest()
        ongoingRequests[source] = ongoingRequest
        
        defer {
            ongoingRequests[source] = nil
        }
        
        do {
            let result = try await Task.dispatch(on: clientQueue) {
                let bytes = try operation()
                return Data(bytes: bytes, count: bytes.count)
            }
            
            ongoingRequest.continuations.forEach { $0.resume(returning: result) }
            
            return result
            
        } catch {
            ongoingRequest.continuations.forEach { $0.resume(throwing: error) }
            throw error
        }
    }
}
