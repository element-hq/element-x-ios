//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@MainActor
struct TimelineItemMenuActionProvider {
    let timelineItem: RoomTimelineItemProtocol
    let canCurrentUserRedactSelf: Bool
    let canCurrentUserRedactOthers: Bool
    let canCurrentUserPin: Bool
    let pinnedEventIDs: Set<String>
    let isDM: Bool
    let isViewSourceEnabled: Bool
    let timelineKind: TimelineKind
    let emojiProvider: EmojiProviderProtocol
    
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

        if let encryptedItem = timelineItem as? EncryptedRoomTimelineItem {
            return makeEncryptedItemActions(encryptedItem)
        }
        
        var actions: [TimelineItemMenuAction] = []
        var secondaryActions: [TimelineItemMenuAction] = []
        
        if timelineKind == .pinned || timelineKind == .media(.mediaFilesScreen) {
            actions.append(.viewInRoomTimeline)
        }
        
        if canRedactItem(item), let poll = item.pollIfAvailable, !poll.hasEnded, let eventID = item.id.eventID {
            actions.append(.endPoll(pollStartID: eventID))
        }

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
            if item.supportsMediaCaption {
                if item.hasMediaCaption {
                    actions.append(.editCaption)
                } else {
                    actions.append(.addCaption)
                }
            } else if item is PollRoomTimelineItem {
                actions.append(.editPoll)
            } else if !(item is VoiceMessageRoomTimelineItem) {
                actions.append(.edit)
            }
        }
        
        if item.isRemoteMessage {
            actions.append(.copyPermalink)
        }
        
        if canCurrentUserPin, let eventID = item.id.eventID {
            actions.append(pinnedEventIDs.contains(eventID) ? .unpin : .pin)
        }

        if item.isCopyable {
            actions.append(.copy)
        } else if item.hasMediaCaption {
            actions.append(.copyCaption)
        }
        
        if item.isEditable, item.hasMediaCaption {
            actions.append(.removeCaption)
        }
        
        if isViewSourceEnabled {
            actions.append(.viewSource)
        }
        
        if !item.isOutgoing {
            secondaryActions.append(.report)
        }
        
        if canRedactItem(item) {
            secondaryActions.append(.redact)
        }
        
        switch timelineKind {
        case .pinned:
            actions = actions.filter(\.canAppearInPinnedEventsTimeline)
            secondaryActions = secondaryActions.filter(\.canAppearInPinnedEventsTimeline)
        case .media:
            actions = actions.filter(\.canAppearInMediaDetails)
            secondaryActions = secondaryActions.filter(\.canAppearInMediaDetails)
        case .live, .detached:
            break // viewInRoomTimeline is the only non-room item and was added conditionally.
        }
        
        if item.hasFailedToSend {
            actions = actions.filter(\.canAppearInFailedEcho)
            secondaryActions = secondaryActions.filter(\.canAppearInFailedEcho)
        }
        
        if item.isRedacted {
            actions = actions.filter(\.canAppearInRedacted)
            secondaryActions = secondaryActions.filter(\.canAppearInRedacted)
        }
        
        let isReactable = timelineKind == .live || timelineKind == .detached ? item.isReactable : false

        return .init(isReactable: isReactable, actions: actions, secondaryActions: secondaryActions, emojiProvider: emojiProvider)
    }
    
    private func makeEncryptedItemActions(_ encryptedItem: EncryptedRoomTimelineItem) -> TimelineItemMenuActions? {
        var actions: [TimelineItemMenuAction] = [.copyPermalink]

        if isViewSourceEnabled {
            actions.append(.viewSource)
        }
                
        return .init(isReactable: false,
                     actions: actions,
                     secondaryActions: [],
                     emojiProvider: emojiProvider)
    }
    
    private func canRedactItem(_ item: EventBasedTimelineItemProtocol) -> Bool {
        item.isOutgoing ? canCurrentUserRedactSelf : canCurrentUserRedactOthers && !isDM
    }
}
