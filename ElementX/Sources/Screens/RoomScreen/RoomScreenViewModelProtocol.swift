//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

protocol RoomScreenViewModelProtocol {
    var actions: AnyPublisher<RoomScreenViewModelAction, Never> { get }
    var context: RoomScreenViewModel.Context { get }
    
    func timelineHasScrolled(direction: ScrollDirection)
    func setSelectedPinnedEventID(_ eventID: String)
}
