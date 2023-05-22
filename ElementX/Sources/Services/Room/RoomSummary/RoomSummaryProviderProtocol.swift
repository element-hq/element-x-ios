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
    case preloaded
    case partiallyLoaded
    case fullyLoaded
}

enum RoomSummary: CustomStringConvertible {
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
    
    var name: String? {
        switch self {
        case .empty:
            return nil
        case .invalidated(let details), .filled(let details):
            return details.name
        }
    }
    
    var description: String {
        switch self {
        case .empty:
            return "\(String(describing: Self.self)): Empty"
        case .invalidated(let details):
            return "\(String(describing: Self.self)): Invalidated(\(details.id))"
        case .filled(let details):
            return "\(String(describing: Self.self)): Filled(\(details.id))"
        }
    }
}

protocol RoomSummaryProviderProtocol {
    /// Publishes the currently available room summaries
    var roomListPublisher: CurrentValuePublisher<[RoomSummary], Never> { get }
    
    /// Publishes the current state the summary provider is finding itself in
    var statePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never> { get }
    
    /// Publishes the total number of rooms
    var countPublisher: CurrentValuePublisher<UInt, Never> { get }
        
    func updateVisibleRange(_ range: Range<Int>, timelineLimit: UInt)
}
