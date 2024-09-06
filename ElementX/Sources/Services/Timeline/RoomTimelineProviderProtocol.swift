//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

enum PaginationDirection: String {
    case backwards, forwards
}

enum PaginationStatus {
    case idle
    case timelineEndReached
    case paginating
}

struct PaginationState: Equatable {
    /// An initial state that is used to prevent pagination whilst loading the timeline.
    /// Once the initial items are loaded the TimelineProxy will publish the correct value.
    static var initial = PaginationState(backward: .timelineEndReached, forward: .timelineEndReached)
    let backward: PaginationStatus
    let forward: PaginationStatus
}

@MainActor
// sourcery: AutoMockable
protocol RoomTimelineProviderProtocol {
    /// A publisher that signals when ``itemProxies`` or ``paginationState`` are changed.
    var updatePublisher: AnyPublisher<([TimelineItemProxy], PaginationState), Never> { get }
    /// The current set of items in the timeline.
    var itemProxies: [TimelineItemProxy] { get }
    /// Whether the timeline is back/forward paginating or not (or has reached the start/end of the room).
    var paginationState: PaginationState { get }
    /// The kind of the timeline
    var kind: TimelineKind { get }
    /// A publisher that signals when changes to the room's membership have occurred through `/sync`.
    ///
    /// This is temporary and will be replace by a subscription on the room itself.
    var membershipChangePublisher: AnyPublisher<Void, Never> { get }
}
