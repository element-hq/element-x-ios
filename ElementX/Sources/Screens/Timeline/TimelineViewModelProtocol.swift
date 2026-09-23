//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftUI

protocol TimelineViewModelProtocol {
    var actions: AnyPublisher<TimelineViewModelAction, Never> { get }
    var context: TimelineViewModel.Context { get }
    
    func process(composerAction: ComposerToolbarViewModelAction)
    /// Updates the timeline to show and highlight the item with the corresponding event ID.
    func focusOnEvent(eventID: String) async
    /// Stops the current live location sharing
    func stopLiveLocationSharing() async
    /// Handles getting the contents to forward the given items, keeping the order of the given IDs.
    func makeForwardingItem(for itemIDs: [TimelineItemIdentifier]) async -> MessageForwardingItem?
    /// Ends the message selection, e.g. once the selected messages have been forwarded.
    func clearSelection()
}
