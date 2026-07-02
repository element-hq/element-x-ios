//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ContentScannerProxyError: Error {
    case missingClient
    case sdkError(Error)
}

// sourcery: AutoMockable
/// A thin wrapper around the SDK's content scanner. Given a media source it asks the scanner server
/// whether the content is clean (safe). It holds no state and no product logic - see
/// ``ContentScannerServiceProtocol`` for caching, per-event tracking and validation state.
protocol ContentScannerProxyProtocol: Sendable {
    func scan(mediaSource: MediaSourceProxy) async -> Result<Bool, ContentScannerProxyError>
}
