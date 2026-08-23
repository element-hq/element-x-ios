//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import UIKit

@preconcurrency import MatrixRustSDK

actor MediaLoader: MediaLoaderProtocol {
    // We noticed that the keyboard appears to hold onto a reference to the `Context` of the last
    // screen that had text input focus, resulting in its MediaProvider staying alive which in
    // turn keeps this loader alive: https://github.com/element-hq/element-x-ios/issues/4465
    // Therefore the client is `weak` so that the underlying `MatrixRustSDK.Client` is released
    // when e.g. clearing the cache, otherwise we have the potential for 2 `Client`s to be alive
    // at the same time causing havoc.
    //
    // Whilst a more correct fix would be to make `Context.mediaProvider` weak, this requires a
    // bunch of workarounds in our preview tests to keep the mock provider alive as some ViewModels
    // don't have an accompanying ClientMock to own it.
    private weak var client: ClientProtocol?
    private var ongoingRequests = [MediaSourceProxy: Task<Data, Error>]()
    private var ongoingFileRequests = [MediaSourceProxy: OngoingFileRequest]()
    
    init(client: ClientProtocol) {
        self.client = client
    }
    
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await enqueueLoadMediaRequest(forSource: source) { [weak client] in
            guard let client else { throw MediaLoaderError.missingClient }
            return try await client.getMediaContent(mediaSource: source.underlyingSource)
        }
    }
    
    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await enqueueLoadMediaRequest(forSource: source) { [weak client] in
            guard let client else { throw MediaLoaderError.missingClient }
            return try await client.getMediaThumbnail(mediaSource: source.underlyingSource, width: UInt64(width), height: UInt64(height))
        }
    }
    
    func loadMediaFileForSource(_ source: MediaSourceProxy, filename: String?, progress: MediaDownloadProgressHandler?) async throws -> MediaFileHandleProxy {
        // One download per source however many callers ask while it's in flight (the viewer asked
        // for a page again mid-download and fetched the video twice). A joiner's progress handler
        // isn't wired up: the first caller's is reporting the same transfer.
        let request: OngoingFileRequest
        if let ongoingRequest = ongoingFileRequests[source] {
            request = ongoingRequest
        } else {
            guard let client else { throw MediaLoaderError.missingClient }
            let download = client.downloadMediaFile(mediaSource: source.underlyingSource,
                                                    filename: filename,
                                                    mimeType: source.mimeType ?? "application/octet-stream",
                                                    useCache: true,
                                                    tempDir: nil,
                                                    progressWatcher: progress.map(MediaDownloadProgressWatcher.init))
            request = OngoingFileRequest(download: download)
            ongoingFileRequests[source] = request
            request.task = Task { [weak self] in
                do {
                    let handle = MediaFileHandleProxy(handle: try await download.join())
                    await self?.finishFileRequest(request, for: source)
                    return handle
                } catch {
                    await self?.finishFileRequest(request, for: source)
                    throw error
                }
            }
        }
        
        // Cancelling the caller's task doesn't reach the Rust download by itself (the SDK future
        // outlives the Swift one): once every caller has cancelled, stop it over the FFI.
        request.waiters += 1
        return try await withTaskCancellationHandler {
            try await request.task!.value
        } onCancel: {
            Task { await self.cancelFileRequestWaiter(request, for: source) }
        }
    }
    
    /// A file download in flight, shared by every caller asking for the same source.
    private final class OngoingFileRequest: Sendable {
        let download: MediaFileDownloadHandleProtocol
        nonisolated(unsafe) var task: Task<MediaFileHandleProxy, Error>?
        nonisolated(unsafe) var waiters = 0
        nonisolated(unsafe) var cancelledWaiters = 0
        init(download: MediaFileDownloadHandleProtocol) { self.download = download }
    }
    
    private func finishFileRequest(_ request: OngoingFileRequest, for source: MediaSourceProxy) {
        if ongoingFileRequests[source] === request {
            ongoingFileRequests[source] = nil
        }
    }
    
    private func cancelFileRequestWaiter(_ request: OngoingFileRequest, for source: MediaSourceProxy) {
        request.cancelledWaiters += 1
        guard request.cancelledWaiters >= request.waiters else { return }
        MXLog.info("Cancelling the download of \(String(describing: source.url)): nothing is waiting for it any more")
        request.download.cancel()
        finishFileRequest(request, for: source) // A later caller starts a fresh download.
    }
    
    // MARK: - Private
    
    /// Forwards the SDK's per-chunk download progress to the handler as a fraction, on the main
    /// actor, once per percent (a 10 MB file is hundreds of chunks).
    private final class MediaDownloadProgressWatcher: ProgressWatcher, @unchecked Sendable {
        private let handler: MediaDownloadProgressHandler
        private let lock = NSLock()
        private var lastReported = -1.0
        
        init(handler: @escaping MediaDownloadProgressHandler) {
            self.handler = handler
        }
        
        func transmissionProgress(progress: TransmissionProgress) {
            guard progress.total > 0 else { return } // No Content-Length: nothing meaningful to show.
            let fraction = min(Double(progress.current) / Double(progress.total), 1)
            let shouldReport = lock.withLock {
                guard fraction - lastReported >= 0.01 || fraction == 1 else { return false }
                lastReported = fraction
                return true
            }
            guard shouldReport else { return }
            Task { @MainActor [handler] in handler(fraction) }
        }
    }
    
    private func enqueueLoadMediaRequest(forSource source: MediaSourceProxy, operation: @escaping @Sendable () async throws -> Data) async throws -> Data {
        if let ongoingRequest = ongoingRequests[source] {
            return try await ongoingRequest.value
        }
        
        // Wrap the SDK call in a Task so `ongoingRequests` is only mutated when resuming from
        // `task.value` (a runtime-managed await that hops back onto the actor) rather than when
        // resuming directly from the SDK's continuation, which can fire on a Rust thread and
        // mutate the dictionary off-actor, corrupting its storage.
        let ongoingRequest = Task { try await operation() }
        ongoingRequests[source] = ongoingRequest
        
        defer {
            ongoingRequests[source] = nil
        }
        
        return try await ongoingRequest.value
    }
}
