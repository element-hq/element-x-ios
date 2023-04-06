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
import MatrixRustSDK

/// A light wrapper around timeline items returned from Rust.
enum TimelineItemProxy {
    case event(EventTimelineItemProxy)
    case virtual(MatrixRustSDK.VirtualTimelineItem)
    case unknown(MatrixRustSDK.TimelineItem)
    
    init(item: MatrixRustSDK.TimelineItem) {
        if let eventItem = item.asEvent() {
            self = .event(EventTimelineItemProxy(item: eventItem))
        } else if let virtualItem = item.asVirtual() {
            self = .virtual(virtualItem)
        } else {
            self = .unknown(item)
        }
    }
}

/// The delivery status for the item.
enum TimelineItemDeliveryStatus: Hashable {
    case sending
    case sent(elapsedTime: TimeInterval)
    case sendingFailed
}

/// A light wrapper around event timeline items returned from Rust.
struct EventTimelineItemProxy: CustomDebugStringConvertible {
    let item: MatrixRustSDK.EventTimelineItem
    
    init(item: MatrixRustSDK.EventTimelineItem) {
        self.item = item
    }
    
    var id: String {
        item.uniqueIdentifier()
    }
    
    var deliveryStatus: TimelineItemDeliveryStatus? {
        guard let localSendState = item.localSendState() else { return nil }
        
        switch localSendState {
        case .notSendYet:
            return .sending
        case .sendingFailed:
            return .sendingFailed
        case .sent:
            return .sent(elapsedTime: Date().timeIntervalSince1970 - timestamp.timeIntervalSince1970)
        }
    }
    
    var body: String? {
        content.asMessage()?.body()
    }
    
    var isMessage: Bool {
        content.asMessage() != nil
    }
    
    var isRoomState: Bool {
        content.kind().isRoomState
    }
    
    var content: TimelineItemContent {
        item.content()
    }

    var isOwn: Bool {
        item.isOwn()
    }

    var isEditable: Bool {
        item.isEditable()
    }
    
    var sender: TimelineItemSender {
        let profile = item.senderProfile()
        
        switch profile {
        case let .ready(displayName, _, avatarUrl):
            return .init(id: item.sender(),
                         displayName: displayName,
                         avatarURL: avatarUrl.flatMap(URL.init(string:)))
        default:
            return .init(id: item.sender(),
                         displayName: nil,
                         avatarURL: nil)
        }
    }

    var reactions: [Reaction] {
        item.reactions() ?? []
    }
    
    var timestamp: Date {
        Date(timeIntervalSince1970: TimeInterval(item.timestamp() / 1000))
    }
    
    // MARK: - CustomDebugStringConvertible
    
    var debugDescription: String {
        let debugInfo = item.debugInfo()
        
        var debugDescription = debugInfo.model
        
        if let originalJson = debugInfo.originalJson {
            debugDescription += "\n\n\(originalJson)"
        }
        
        if let latestEditJson = debugInfo.latestEditJson {
            debugDescription += "\n\n\(latestEditJson)"
        }
        
        return debugDescription
    }
}

extension TimelineItemContentKind {
    var isRoomState: Bool {
        switch self {
        case .state, .roomMembership:
            return true
        default:
            return false
        }
    }
}
