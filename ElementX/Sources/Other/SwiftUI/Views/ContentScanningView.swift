//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The reason a media item can't be presented.
nonisolated enum ContentScanningFailure {
    /// The content scanner flagged the media as unsafe.
    case notSafe
    /// The media couldn't be scanned, e.g. it wasn't found or a network error occurred.
    case notFound
}

/// Reports a ``ContentScanningFailure`` up the view hierarchy so that ancestors (such as the
/// message bubble) can adopt the critical styling without having to track the scan state themselves.
nonisolated struct ContentScanningFailurePreferenceKey: PreferenceKey {
    static let defaultValue: ContentScanningFailure? = nil
    
    static func reduce(value: inout ContentScanningFailure?, nextValue: () -> ContentScanningFailure?) {
        value = value ?? nextValue()
    }
}

/// A wrapper that gates the presentation of a media item on its content scan state.
///
/// The content is rendered when the media is known to be safe or when there's no content scanner
/// configured, the loading content whilst a scan is in flight and the failed content when the
/// media is unsafe or couldn't be scanned. Any failure is also reported up the view hierarchy
/// through ``ContentScanningFailurePreferenceKey``.
///
/// - Important: Any interactions with the media (taps, playback etc.) must live inside the
/// content so that they're unavailable whilst the media is being scanned or is unsafe.
struct ContentScanningView<Content: View, LoadingContent: View, FailedContent: View>: View {
    private enum ScanState {
        case loaded
        case loading
        case failed(ContentScanningFailure)
    }
    
    private let contentScannerService: ContentScannerServiceProtocol?
    private let mediaSource: MediaSourceProxy?
    private let content: () -> Content
    private let loadingContent: () -> LoadingContent
    private let failedContent: (ContentScanningFailure) -> FailedContent
    
    @State private var scanState: ScanState?
    
    /// - Parameters:
    ///   - contentScannerService: The service used to scan the media. Passing `nil` disables
    ///     scanning and the content is always rendered.
    ///   - mediaSource: The media source to scan. Passing `nil` renders the content, this
    ///     makes it convenient to wrap items whose media source is optional.
    ///   - content: The regular presentation of the media, including any interactions with it.
    ///   - loading: The presentation of the media whilst it's being scanned.
    ///   - failed: The presentation of the media when it can't be shown.
    init(contentScannerService: ContentScannerServiceProtocol?,
         mediaSource: MediaSourceProxy?,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder loading: @escaping () -> LoadingContent,
         @ViewBuilder failed: @escaping (ContentScanningFailure) -> FailedContent) {
        self.contentScannerService = contentScannerService
        self.mediaSource = mediaSource
        self.content = content
        loadingContent = loading
        failedContent = failed
    }
    
    var body: some View {
        scanStateContent
            .preference(key: ContentScanningFailurePreferenceKey.self, value: scanFailure)
            .task(id: mediaSource?.url.absoluteString) {
                await scan()
            }
    }
    
    @ViewBuilder
    private var scanStateContent: some View {
        switch resolvedScanState {
        case .loaded:
            content()
        case .loading:
            loadingContent()
        case .failed(let failure):
            failedContent(failure)
        }
    }
    
    private var scanFailure: ContentScanningFailure? {
        guard case .failed(let failure) = resolvedScanState else {
            return nil
        }
        return failure
    }
    
    private var resolvedScanState: ScanState {
        guard let contentScannerService, let mediaSource else {
            return .loaded
        }
        
        if let scanState {
            return scanState
        }
        
        // Until the scan triggered by this view resolves, reflect any verdict already in the cache.
        switch contentScannerService.scanResultFromSource(mediaSource) {
        case true: return .loaded
        case false: return .failed(.notSafe)
        default: return .loading
        }
    }
    
    private func scan() async {
        guard let contentScannerService, let mediaSource else {
            return
        }
        
        switch await contentScannerService.loadScanResultFromSource(mediaSource) {
        case .success(true):
            scanState = .loaded
        case .success(false):
            scanState = .failed(.notSafe)
        case .failure:
            scanState = .failed(.notFound)
        }
    }
}
