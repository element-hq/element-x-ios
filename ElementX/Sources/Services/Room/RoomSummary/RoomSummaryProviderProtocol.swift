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

enum RoomSummaryProviderState {
    case notLoaded
    case loaded(totalNumberOfRooms: UInt)
    
    var isLoaded: Bool {
        switch self {
        case .loaded:
            return true
        default:
            return false
        }
    }
    
    var totalNumberOfRooms: UInt? {
        switch self {
        case .loaded(let totalNumberOfRooms):
            return totalNumberOfRooms
        default:
            return nil
        }
    }
}

enum RoomSummaryProviderFilter: Equatable {
    /// Filters out everything
    case excludeAll
    /// Includes only the items that satisfy the predicate logic
    case search(query: String)
    /// Includes only what satisfies the filters used
    case all(filters: Set<RoomListFilter>)
}

// sourcery: AutoMockable
protocol RoomSummaryProviderProtocol {
    /// Publishes the currently available room summaries
    var roomListPublisher: CurrentValuePublisher<[RoomSummary], Never> { get }
    
    /// Publishes the current state the summary provider is finding itself in
    var statePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never> { get }
    
    func setRoomList(_ roomList: RoomList)
    
    func updateVisibleRange(_ range: Range<Int>)
    
    func setFilter(_ filter: RoomSummaryProviderFilter)
}
