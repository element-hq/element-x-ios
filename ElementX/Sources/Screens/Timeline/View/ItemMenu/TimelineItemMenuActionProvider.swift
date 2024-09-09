//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    let isPinnedEventsTimeline: Bool
    
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

        if item.isEditable {
            actions.append(.edit)
        }
        
        if canCurrentUserPin, let eventID = item.id.eventID {
            actions.append(pinnedEventIDs.contains(eventID) ? .unpin : .pin)
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
        
        if isPinnedEventsTimeline {
            actions.insert(.viewInRoomTimeline, at: 0)
            actions = actions.filter(\.canAppearInPinnedEventsTimeline)
        }

        return .init(isReactable: isPinnedEventsTimeline ? false : item.isReactable, actions: actions, debugActions: debugActions)
    }
    
    private func canRedactItem(_ item: EventBasedTimelineItemProtocol) -> Bool {
        item.isOutgoing ? canCurrentUserRedactSelf : canCurrentUserRedactOthers && !isDM
    }
}
