//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// sourcery: AutoMockable
protocol MediaLoaderProtocol {
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data

    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data
    
    func loadMediaFileForSource(_ source: MediaSourceProxy, filename: String?) async throws -> MediaFileHandleProxy
}
