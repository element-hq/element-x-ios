//
// Copyright 2026 Element Creations Ltd.
// Copyright 2026 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

/// The content scanning state of an event's media.
nonisolated enum ContentValidation: Hashable {
    /// The media hasn't been scanned yet.
    case unknown
    /// A scan is in flight - the media should be presented as loading.
    case scanning
    /// The media is clean and safe to present.
    case safe
    /// The media is unsafe (a virus or a forbidden mime type) and must not be presented.
    case notSafe
}

// sourcery: AutoMockable
/// Holds the observable ``ContentValidation`` state for events, keyed by event ID. This is the state
/// the timeline reads to decide how to present media - it is written to by ``ContentScannerServiceProtocol``.
nonisolated protocol EventContentValidationCacheProtocol: Sendable {
    /// A publisher of the current validation state for the given event (starts at ``ContentValidation/unknown``).
    func validationPublisher(for eventID: String) -> CurrentValuePublisher<ContentValidation, Never>
    
    /// The current validation state for the given event.
    func validation(for eventID: String) -> ContentValidation
    
    /// Updates the validation state for the given event.
    func update(_ validation: ContentValidation, for eventID: String)
}
