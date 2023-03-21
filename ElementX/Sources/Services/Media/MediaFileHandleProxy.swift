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
    var url: URL {
        URL(filePath: handle.path())
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
private struct UnmanagedMediaFileHandle: MediaFileHandleProtocol {
    let url: URL
    
    func path() -> String {
        url.path()
    }
}
