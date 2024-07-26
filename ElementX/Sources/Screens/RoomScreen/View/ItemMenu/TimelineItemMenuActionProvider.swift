//
// Copyright 2024 New Vector Ltd
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

struct TimelineItemMenuActionProvider {
    let timelineItem: RoomTimelineItemProtocol
    let canCurrentUserRedactSelf: Bool
    let canCurrentUserRedactOthers: Bool
    let canCurrentUserPin: Bool
    let pinnedEventIDs: Set<String>
    let isDM: Bool
    let isViewSourceEnabled: Bool
    
    // swiftlint:disable:next cyclomatic_complexity
    func makeActions() -> TimelineItemMenuActions? {
        guard let item = timelineItem as? EventBasedTimelineItemProtocol else {
            // Don't show a context menu for non-event based items.
            return nil
        }

        if timelineItem is StateRoomTimelineItem {
            // Don't show a context menu for state events.
            return nil
        }

        var debugActions: [TimelineItemMenuAction] = []
        if isViewSourceEnabled {
            debugActions.append(.viewSource)
        }

        if let encryptedItem = timelineItem as? EncryptedRoomTimelineItem {
            switch encryptedItem.encryptionType {
            case .megolmV1AesSha2(let sessionID, _):
                debugActions.append(.retryDecryption(sessionID: sessionID))
            default:
                break
            }
            
            return .init(isReactable: false, actions: [.copyPermalink], debugActions: debugActions)
        }
        
        var actions: [TimelineItemMenuAction] = []

        if item.canBeRepliedTo {
            if let messageItem = item as? EventBasedMessageTimelineItemProtocol {
                actions.append(.reply(isThread: messageItem.isThreaded))
            } else {
                actions.append(.reply(isThread: false))
            }
        }
        
        if item.isForwardable {
            actions.append(.forward(itemID: item.id))
        }
        
        if canCurrentUserPin, let eventID = item.id.eventID {
            actions.append(pinnedEventIDs.contains(eventID) ? .unpin : .pin)
        }

        if item.isEditable {
            actions.append(.edit)
        }

        if item.isCopyable {
            actions.append(.copy)
        }
        
        if item.isRemoteMessage {
            actions.append(.copyPermalink)
        }

        if canRedactItem(item), let poll = item.pollIfAvailable, !poll.hasEnded, let eventID = item.id.eventID {
            actions.append(.endPoll(pollStartID: eventID))
        }
        
        if canRedactItem(item) {
            actions.append(.redact)
        }

        if !item.isOutgoing {
            actions.append(.report)
        }

        if item.hasFailedToSend {
            actions = actions.filter(\.canAppearInFailedEcho)
        }

        if item.isRedacted {
            actions = actions.filter(\.canAppearInRedacted)
        }

        return .init(isReactable: item.isReactable, actions: actions, debugActions: debugActions)
    }
    
    private func canRedactItem(_ item: EventBasedTimelineItemProtocol) -> Bool {
        item.isOutgoing ? canCurrentUserRedactSelf : canCurrentUserRedactOthers && !isDM
    }
}
