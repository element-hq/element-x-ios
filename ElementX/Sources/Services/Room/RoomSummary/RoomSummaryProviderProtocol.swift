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

enum RoomSummaryProviderCallback {
    case updatedRoomSummaries
}

enum RoomSummaryProviderState {
    case cold
    case live
}

protocol RoomSummaryProviderProtocol {
    var callbacks: PassthroughSubject<RoomSummaryProviderCallback, Never> { get }
    
    /// Publishes the current state the summary provider is finding itself in
    var stateUpdatePublisher: CurrentValueSubject<RoomSummaryProviderState, Never> { get }
    
    /// Publishes the total number of rooms
    var countUpdatePublisher: CurrentValueSubject<UInt, Never> { get }
    
    /// The current list of rooms currently provided by the sliding sync view
    var roomSummaries: [RoomSummary] { get }
    
    /// Invoked by the sliding sync controller whenever certain rooms have updated
    /// without necessarily changing their position in the list
    /// - Parameter identifiers: the identifiers for the rooms that have changed
    func updateRoomsWithIdentifiers(_ identifiers: [String])
}
