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
    case sent
    case sendingFailed
}

/// A light wrapper around event timeline items returned from Rust.
struct EventTimelineItemProxy {
    let item: MatrixRustSDK.EventTimelineItem
    
    init(item: MatrixRustSDK.EventTimelineItem) {
        self.item = item
    }
    
    var id: String {
        item.uniqueIdentifier()
    }
    
    var deliveryStatus: TimelineItemDeliveryStatus? {
        guard let localSendState = item.localSendState() else {
            return nil
        }
        
        switch localSendState {
        case .notSentYet:
            return .sending
        case .sendingFailed:
            return .sendingFailed
        case .sent:
            return .sent
        }
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
        item.reactions()
    }
    
    var timestamp: Date {
        Date(timeIntervalSince1970: TimeInterval(item.timestamp() / 1000))
    }
    
    var debugInfo: TimelineItemDebugInfo {
        let debugInfo = item.debugInfo()
        return TimelineItemDebugInfo(model: debugInfo.model, originalJSON: debugInfo.originalJson, latestEditJSON: debugInfo.latestEditJson)
    }

    var readReceipts: [String: Receipt] {
        item.readReceipts()
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

struct TimelineItemDebugInfo: Identifiable, CustomStringConvertible {
    let id = UUID()
    let model: String
    let originalJSON: String?
    let latestEditJSON: String?
    
    init(model: String, originalJSON: String?, latestEditJSON: String?) {
        self.model = model
        
        self.originalJSON = Self.prettyJsonFormattedString(from: originalJSON)
        self.latestEditJSON = Self.prettyJsonFormattedString(from: latestEditJSON)
    }
    
    var description: String {
        var description = model
        
        if let originalJSON {
            description += "\n\n\(originalJSON)"
        }
        
        if let latestEditJSON {
            description += "\n\n\(latestEditJSON)"
        }
        
        return description
    }
    
    // MARK: - Private
    
    private static func prettyJsonFormattedString(from string: String?) -> String? {
        guard let string,
              let data = string.data(using: .utf8),
              let jsonDictionary = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
              let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: [.prettyPrinted]) else {
            return nil
        }
        
        return String(data: jsonData, encoding: .utf8)
    }
}

extension Receipt {
    var dateTimestamp: Date? {
        guard let timestamp else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
    }
}
