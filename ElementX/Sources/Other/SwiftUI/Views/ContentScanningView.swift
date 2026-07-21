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
/// The safe content is rendered when the media is known to be safe or when there's no content
/// scanner configured, the scanning content whilst a scan is in flight and the unsafe content
/// when the media is unsafe or couldn't be scanned. Any failure is also reported up the view
/// hierarchy through ``ContentScanningFailurePreferenceKey``.
///
/// - Important: Any interactions with the media (taps, playback etc.) must live inside the safe
/// content so that they're unavailable whilst the media is being scanned or is unsafe.
struct ContentScanningView<SafeContent: View, ScanningContent: View, UnsafeContent: View>: View {
    private enum ScanState {
        case safe
        case scanning
        case unsafe(ContentScanningFailure)
    }
    
    private let contentScannerService: ContentScannerServiceProtocol?
    private let mediaSources: [MediaSourceProxy]
    private let containerShowsFailure: Bool
    private let safeContent: () -> SafeContent
    private let scanningContent: () -> ScanningContent
    private let unsafeContent: (ContentScanningFailure) -> UnsafeContent
    
    @State private var scanState: ScanState?
    
    /// - Parameters:
    ///   - contentScannerService: The service used to scan the media. Passing `nil` disables
    ///     scanning and the content is always rendered.
    ///   - mediaSource: The media source to scan. Passing `nil` renders the content, this
    ///     makes it convenient to wrap items whose media source is optional.
    ///   - thumbnailSource: The thumbnail source to scan alongside the media source when the item
    ///     also downloads a thumbnail. The content is flagged if either source is unsafe or fails.
    ///   - containerShowsFailure: Whether a failure is reported up the view hierarchy through
    ///     ``ContentScanningFailurePreferenceKey`` so that the surrounding container (such as the
    ///     message bubble) adopts the critical styling. Pass `false` when the failure should only
    ///     affect this view, e.g. inside a reply preview where the bubble must stay regular.
    ///   - safeContent: The regular presentation of the media, including any interactions with it.
    ///   - scanningContent: The presentation of the media whilst it's being scanned.
    ///   - unsafeContent: The presentation of the media when it can't be shown.
    init(contentScannerService: ContentScannerServiceProtocol?,
         mediaSource: MediaSourceProxy?,
         thumbnailSource: MediaSourceProxy? = nil,
         containerShowsFailure: Bool = true,
         @ViewBuilder safeContent: @escaping () -> SafeContent,
         @ViewBuilder scanningContent: @escaping () -> ScanningContent,
         @ViewBuilder unsafeContent: @escaping (ContentScanningFailure) -> UnsafeContent) {
        self.contentScannerService = contentScannerService
        mediaSources = [mediaSource, thumbnailSource].compactMap { $0 }
        self.containerShowsFailure = containerShowsFailure
        self.safeContent = safeContent
        self.scanningContent = scanningContent
        self.unsafeContent = unsafeContent
    }
    
    var body: some View {
        content
            .preference(key: ContentScanningFailurePreferenceKey.self, value: containerShowsFailure ? scanFailure : nil)
            .task(id: mediaSources.map(\.url.absoluteString).joined(separator: "|")) {
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
        case .unsafe(let failure):
            unsafeContent(failure)
        }
    }
    
    private var scanFailure: ContentScanningFailure? {
        guard case .unsafe(let failure) = resolvedScanState else {
            return nil
        }
        return failure
    }
    
    private var resolvedScanState: ScanState {
        guard let contentScannerService, !mediaSources.isEmpty else {
            return .safe
        }
        
        if let scanState {
            return scanState
        }
        
        // Until the scan triggered by this view resolves, reflect any verdict already in the cache.
        switch contentScannerService.scanResultFromSources(mediaSources) {
        case true: return .safe
        case false: return .unsafe(.notSafe)
        default: return .scanning
        }
    }
    
    private func scan() async {
        guard let contentScannerService, !mediaSources.isEmpty else {
            return
        }
        
        switch await contentScannerService.loadScanResultFromSources(mediaSources) {
        case .success(true):
            scanState = .safe
        case .success(false):
            scanState = .unsafe(.notSafe)
        case .failure:
            scanState = .unsafe(.notFound)
        }
    }
}
