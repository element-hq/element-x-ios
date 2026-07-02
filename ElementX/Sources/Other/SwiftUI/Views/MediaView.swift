//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The reason a media item can't be presented.
nonisolated enum MediaScanFailure {
    /// The content scanner flagged the media as unsafe.
    case notSafe
    /// The media couldn't be scanned, e.g. it wasn't found or a network error occurred.
    case notFound
}

/// Reports a ``MediaScanFailure`` up the view hierarchy so that ancestors (such as the message
/// bubble) can adopt the critical styling without having to track the scan state themselves.
nonisolated struct MediaScanFailurePreferenceKey: PreferenceKey {
    static let defaultValue: MediaScanFailure? = nil
    
    static func reduce(value: inout MediaScanFailure?, nextValue: () -> MediaScanFailure?) {
        value = value ?? nextValue()
    }
}

/// A wrapper that gates the presentation of a media item on its content scan state.
///
/// The safe content is rendered when the media is known to be safe or when there's no content
/// scanner configured, the scanning content whilst a scan is in flight and the unsafe content
/// when the media is unsafe or couldn't be scanned. Any failure is also reported up the view
/// hierarchy through ``MediaScanFailurePreferenceKey``.
///
/// - Important: Any interactions with the media (taps, playback etc.) must live inside the safe
/// content so that they're unavailable whilst the media is being scanned or is unsafe.
struct MediaView<SafeContent: View, ScanningContent: View, UnsafeContent: View>: View {
    private enum ScanState {
        case safe
        case scanning
        case failed(MediaScanFailure)
    }
    
    private let contentScannerService: ContentScannerServiceProtocol?
    private let mediaSource: MediaSourceProxy?
    private let safeContent: () -> SafeContent
    private let scanningContent: () -> ScanningContent
    private let unsafeContent: (MediaScanFailure) -> UnsafeContent
    
    @State private var scanState: ScanState?
    
    /// - Parameters:
    ///   - contentScannerService: The service used to scan the media. Passing `nil` disables
    ///     scanning and the safe content is always rendered.
    ///   - mediaSource: The media source to scan. Passing `nil` renders the safe content, this
    ///     makes it convenient to wrap items whose media source is optional.
    ///   - safeContent: The regular presentation of the media, including any interactions with it.
    ///   - scanningContent: The presentation of the media whilst it's being scanned.
    ///   - unsafeContent: The presentation of the media when it can't be shown.
    init(contentScannerService: ContentScannerServiceProtocol?,
         mediaSource: MediaSourceProxy?,
         @ViewBuilder safeContent: @escaping () -> SafeContent,
         @ViewBuilder scanningContent: @escaping () -> ScanningContent,
         @ViewBuilder unsafeContent: @escaping (MediaScanFailure) -> UnsafeContent) {
        self.contentScannerService = contentScannerService
        self.mediaSource = mediaSource
        self.safeContent = safeContent
        self.scanningContent = scanningContent
        self.unsafeContent = unsafeContent
    }
    
    var body: some View {
        content
            .preference(key: MediaScanFailurePreferenceKey.self, value: scanFailure)
            .task(id: mediaSource?.url.absoluteString) {
                await scan()
            }
    }
    
    @ViewBuilder
    private var content: some View {
        switch resolvedScanState {
        case .safe:
            safeContent()
        case .scanning:
            scanningContent()
        case .failed(let failure):
            unsafeContent(failure)
        }
    }
    
    private var scanFailure: MediaScanFailure? {
        guard case .failed(let failure) = resolvedScanState else {
            return nil
        }
        return failure
    }
    
    private var resolvedScanState: ScanState {
        guard let contentScannerService, let mediaSource else {
            return .safe
        }
        
        if let scanState {
            return scanState
        }
        
        // Until the scan triggered by this view resolves, reflect any verdict already in the cache.
        switch contentScannerService.scanResultFromSource(mediaSource) {
        case true: return .safe
        case false: return .failed(.notSafe)
        default: return .scanning
        }
    }
    
    private func scan() async {
        guard let contentScannerService, let mediaSource else {
            return
        }
        
        switch await contentScannerService.loadScanResultFromSource(mediaSource) {
        case .success(true):
            scanState = .safe
        case .success(false):
            scanState = .failed(.notSafe)
        case .failure:
            scanState = .failed(.notFound)
        }
    }
}
