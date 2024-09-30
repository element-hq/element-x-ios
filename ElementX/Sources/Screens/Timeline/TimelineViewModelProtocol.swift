//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import SwiftUI

@MainActor
protocol TimelineViewModelProtocol {
    var actions: AnyPublisher<TimelineViewModelAction, Never> { get }
    var context: TimelineViewModel.Context { get }
    func process(composerAction: ComposerToolbarViewModelAction)
    /// Updates the timeline to show and highlight the item with the corresponding event ID.
    func focusOnEvent(eventID: String) async
    func stop()
}
