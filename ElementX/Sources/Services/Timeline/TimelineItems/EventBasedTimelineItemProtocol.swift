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

import Foundation
import UIKit

enum TimelineItemGroupState: Hashable {
    case single
    case beginning
    case middle
    case end

    var shouldShowSenderDetails: Bool {
        switch self {
        case .single, .beginning:
            return true
        default:
            return false
        }
    }
}

protocol EventBasedTimelineItemProtocol: RoomTimelineItemProtocol {
    var text: String { get }
    var timestamp: String { get }
    var shouldShowSenderDetails: Bool { get }
    var groupState: TimelineItemGroupState { get }
    var isOutgoing: Bool { get }
    var isEditable: Bool { get }
    
    var senderId: String { get }
    var senderDisplayName: String? { get set }
    var senderAvatar: UIImage? { get set }
    
    var properties: RoomTimelineItemProperties { get }
}

extension EventBasedTimelineItemProtocol {
    var shouldShowSenderDetails: Bool {
        groupState.shouldShowSenderDetails
    }
    
    var roundedCorners: UIRectCorner {
        switch groupState {
        case .single:
            return .allCorners
        case .beginning:
            if isOutgoing {
                return [.topLeft, .topRight, .bottomLeft]
            } else {
                return [.topLeft, .topRight, .bottomRight]
            }
        case .middle:
            return isOutgoing ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight]
        case .end:
            if isOutgoing {
                return [.topLeft, .bottomLeft, .bottomRight]
            } else {
                return [.topRight, .bottomLeft, .bottomRight]
            }
        }
    }
}
