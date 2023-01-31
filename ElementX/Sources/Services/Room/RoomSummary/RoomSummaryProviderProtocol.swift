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
    case cold
    case preload
    case catchingUp
    case live
}

enum RoomSummary {
    case empty
    case filled(details: RoomSummaryDetails)
    case invalidated(details: RoomSummaryDetails)
    
    var id: String? {
        switch self {
        case .empty:
            return nil
        case .invalidated(let details), .filled(let details):
            return details.id
        }
    }
}

protocol RoomSummaryProviderProtocol {
    /// Publishes the currently available room summaries
    var roomListPublisher: CurrentValueSubject<[RoomSummary], Never> { get }
    
    /// Publishes the current state the summary provider is finding itself in
    var statePublisher: CurrentValueSubject<RoomSummaryProviderState, Never> { get }
    
    /// Publishes the total number of rooms
    var countPublisher: CurrentValueSubject<UInt, Never> { get }
        
    func updateVisibleRange(_ range: Range<Int>, timelineLimit: UInt)
}
