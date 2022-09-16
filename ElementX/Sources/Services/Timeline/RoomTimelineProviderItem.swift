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

import MatrixRustSDK

/// A light wrapper around timeline items returned from Rust for use in `RoomTimelineProvider`.
enum RoomTimelineProviderItem {
    case event(EventTimelineItem)
    case virtual(MatrixRustSDK.VirtualTimelineItem)
    case other(MatrixRustSDK.TimelineItem)
    
    init(item: MatrixRustSDK.TimelineItem) {
        if let eventItem = item.asEvent() {
            self = .event(EventTimelineItem(item: eventItem))
        } else if let virtualItem = item.asVirtual() {
            self = .virtual(virtualItem)
        } else {
            self = .other(item)
        }
    }

    func canBeGrouped(with prevItem: RoomTimelineProviderItem) -> Bool {
        guard case let .event(selfEventItem) = self, case let .event(prevEventItem) = prevItem else {
            return false
        }
        //  can be improved by adding a date threshold
        return prevEventItem.reactions.isEmpty && selfEventItem.sender == prevEventItem.sender
    }
}

/// A light wrapper around event timeline items returned from Rust, used in `RoomTimelineProviderItem`.
struct EventTimelineItem {
    let item: MatrixRustSDK.EventTimelineItem
    
    init(item: MatrixRustSDK.EventTimelineItem) {
        self.item = item
    }
    
    var id: String {
        #warning("Handle txid in a better way")
        switch item.key() {
        case .transactionId(let txnID):
            return txnID
        case .eventId(let eventID):
            return eventID
        }
    }
    
    var body: String? {
        item.content().asMessage()?.msgtype().body()
    }
    
    var isMessage: Bool {
        item.content().asMessage() != nil
    }
    
    var content: TimelineItemContent {
        item.content()
    }
    
    var sender: String {
        item.sender()
    }

    var reactions: [Reaction] {
        item.reactions()
    }
    
    var originServerTs: Date {
        if let timestamp = item.originServerTs() {
            return Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        } else {
            return .now
        }
    }
}
