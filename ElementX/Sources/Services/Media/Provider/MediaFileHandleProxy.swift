//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// A wrapper around Rust's `MediaFileHandle` type that provides us with a
/// media file that is stored unencrypted in a temporary location for previewing.
class MediaFileHandleProxy {
    /// The underlying handle for the file.
    private let handle: MediaFileHandleProtocol
    
    /// Creates a new instance from the Rust type.
    init(handle: MediaFileHandleProtocol) {
        self.handle = handle
    }
    
    /// Creates an unmanaged instance (for mocking etc), using a raw `URL`
    ///
    /// A media file created from a URL won't have the automatic clean-up mechanism
    /// that is provided by the SDK's `MediaFileHandle`.
    static func unmanaged(url: URL) -> MediaFileHandleProxy {
        MediaFileHandleProxy(handle: UnmanagedMediaFileHandle(url: url))
    }
    
    /// The media file's location on disk.
    var url: URL? {
        do {
            let path = try handle.path()
            return URL(filePath: path)
        } catch {
            MXLog.error("URL is missing for media file handle: \(error)")
            return nil
        }
    }
}

// MARK: - Hashable

extension MediaFileHandleProxy: Hashable {
    static func == (lhs: MediaFileHandleProxy, rhs: MediaFileHandleProxy) -> Bool {
        lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

// MARK: -

/// An unmanaged file handle that can be created direct from a URL.
///
/// This type allows for mocking but doesn't provide the automatic clean-up mechanism provided by the SDK.
private class UnmanagedMediaFileHandle: MediaFileHandleProtocol {
    func persist(path: String) throws -> Bool {
        false
    }
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func path() -> String {
        url.path()
    }
}
