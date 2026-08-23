//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

enum MediaProviderError: Error {
    case failedRetrievingImage
    case failedRetrievingFile
    case invalidImageData
    case failedRetrievingThumbnail
    case cancelled
}

/// Told how much of a file has been downloaded, as a fraction (0...1), at most every percent.
/// Only called when the server sent the file's size; a cached file arrives without any call.
typealias MediaDownloadProgressHandler = @MainActor @Sendable (Double) -> Void

// sourcery: AutoMockable
nonisolated protocol MediaProviderProtocol: Sendable {
    func imageFromSource(_ source: MediaSourceProxy?, size: CGSize?) -> UIImage?
    func loadImageDataFromSource(_ source: MediaSourceProxy) async -> Result<Data, MediaProviderError>
    func loadImageRetryingOnReconnection(_ source: MediaSourceProxy, size: CGSize?) -> Task<UIImage, Error>
    
    func loadThumbnailForSource(source: MediaSourceProxy, size: CGSize) async -> Result<Data, MediaProviderError>
    
    func loadFileFromSource(_ source: MediaSourceProxy, filename: String?, progress: MediaDownloadProgressHandler?) async -> Result<MediaFileHandleProxy, MediaProviderError>
}

extension MediaProviderProtocol {
    func imageFromSource(_ source: MediaSourceProxy?) -> UIImage? {
        imageFromSource(source, size: nil)
    }
    
    func loadImageRetryingOnReconnection(_ source: MediaSourceProxy) -> Task<UIImage, Error> {
        loadImageRetryingOnReconnection(source, size: nil)
    }
    
    func loadFileFromSource(_ source: MediaSourceProxy, filename: String? = nil) async -> Result<MediaFileHandleProxy, MediaProviderError> {
        await loadFileFromSource(source, filename: filename, progress: nil)
    }
}
