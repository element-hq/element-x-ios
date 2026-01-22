//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

struct TimelinePaginationState: Equatable {
    /// An initial state that is used to prevent pagination whilst loading the timeline.
    /// Once the initial items are loaded the TimelineProxy will publish the correct value.
    static var initial = TimelinePaginationState(backward: .endReached, forward: .endReached)
    let backward: PaginationState
    let forward: PaginationState
}

/// Entities implementing this protocol are responsible for processings diffs coming from the rust timeline
/// and converting them into an array of Element X specific ``TimelineItemProxy``s that will be
/// published as an array together with the pagination state through the ``updatePublisher``.
@MainActor
protocol TimelineItemProviderProtocol {
    /// A publisher that signals when ``itemProxies`` or ``paginationState`` are changed.
    var updatePublisher: AnyPublisher<([TimelineItemProxy], TimelinePaginationState), Never> { get }
    /// The current set of items in the timeline.
    var itemProxies: [TimelineItemProxy] { get }
    /// Whether the timeline is back/forward paginating or not (or has reached the start/end of the room).
    var paginationState: TimelinePaginationState { get }
    /// The kind of the timeline
    var kind: TimelineKind { get }
    /// A publisher that signals when changes to the room's membership have occurred through `/sync`.
    ///
    /// This is temporary and will be replace by a subscription on the room itself.
    var membershipChangePublisher: AnyPublisher<Void, Never> { get }
}

// sourcery: AutoMockable
extension TimelineItemProviderProtocol { }
