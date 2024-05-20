//
// Copyright 2022 New Vector Ltd
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

import Combine
import Foundation
import MatrixRustSDK

enum PaginationStatus {
    case idle
    case timelineEndReached
    case paginating
}

struct PaginationState: Equatable {
    static var `default` = PaginationState(backward: .idle, forward: .timelineEndReached)
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
    /// Whether or not the provider is for a live timeline.
    var isLive: Bool { get }
    /// A publisher that signals when changes to the room's membership have occurred through `/sync`.
    ///
    /// This is temporary and will be replace by a subscription on the room itself.
    var membershipChangePublisher: AnyPublisher<Void, Never> { get }
}
