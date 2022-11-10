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

enum TimelineItemInGroupState {
    case single
    case beginning
    case middle
    case end

    var roundedCorners: UIRectCorner {
        switch self {
        case .single:
            return .allCorners
        case .beginning:
            return [.topLeft, .topRight]
        case .middle:
            return []
        case .end:
            return [.bottomLeft, .bottomRight]
        }
    }

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
    var inGroupState: TimelineItemInGroupState { get }
    var isOutgoing: Bool { get }
    var isEditable: Bool { get }
    
    var senderId: String { get }
    var senderDisplayName: String? { get set }
    var senderAvatar: UIImage? { get set }
    
    var properties: RoomTimelineItemProperties { get }
}

extension EventBasedTimelineItemProtocol {
    var shouldShowSenderDetails: Bool {
        inGroupState.shouldShowSenderDetails
    }
}
