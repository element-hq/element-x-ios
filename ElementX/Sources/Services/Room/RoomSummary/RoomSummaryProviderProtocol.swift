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

enum RoomSummaryProviderState {
    case cold
    case preload
    case catchingUp
    case live
}

enum RoomSummary: Identifiable {
    case empty(id: String)
    case filled(details: RoomSummaryDetails)
    
    var id: String {
        switch self {
        case .empty(let id):
            return id
        case .filled(let summary):
            return summary.id
        }
    }
    
    var asFilled: RoomSummaryDetails? {
        guard case let .filled(details) = self else {
            return nil
        }
        
        return details
    }
}

protocol RoomSummaryProviderProtocol {
    /// Publishes the currently available room summaries
    var roomListPublisher: CurrentValueSubject<[RoomSummary], Never> { get }
    
    /// Publishes the current state the summary provider is finding itself in
    var statePublisher: CurrentValueSubject<RoomSummaryProviderState, Never> { get }
    
    /// Publishes the total number of rooms
    var countPublisher: CurrentValueSubject<UInt, Never> { get }
    
    /// Invoked by the sliding sync controller whenever certain rooms have updated
    /// without necessarily changing their position in the list
    /// - Parameter identifiers: the identifiers for the rooms that have changed
    func updateRoomsWithIdentifiers(_ identifiers: [String])
    
    func updateVisibleRange(_ range: ClosedRange<Int>)
}
