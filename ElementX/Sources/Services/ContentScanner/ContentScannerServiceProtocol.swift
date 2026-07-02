//
// Copyright 2026 Element Creations Ltd.
// Copyright 2026 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// sourcery: AutoMockable
/// Performs active content scanning of an event's media, writing the outcome into an
/// ``EventContentValidationCacheProtocol``. It caches which sources have been scanned to avoid
/// redundant work and short-circuits once an event is known to be unsafe.
///
/// A service only exists when a content scanner is configured for the server, so the absence of a
/// service means content scanning is disabled and media can be presented normally.
nonisolated protocol ContentScannerServiceProtocol: Sendable {
    /// Requests an active scan of the given event's media source. Does nothing if the source has
    /// already been scanned or the event is already known to be unsafe.
    func scan(eventID: String, mediaSource: MediaSourceProxy) async
}
