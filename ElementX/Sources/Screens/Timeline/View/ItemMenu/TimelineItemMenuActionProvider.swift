//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

@MainActor
struct TimelineItemMenuActionProvider {
    enum PresentationContext { case room, pinnedEvents, mediaDetailsOnBrowser, mediaDetailsOnRoom }
    
    let timelineItem: RoomTimelineItemProtocol
    let canCurrentUserRedactSelf: Bool
    let canCurrentUserRedactOthers: Bool
    let canCurrentUserPin: Bool
    let pinnedEventIDs: Set<String>
    let isDM: Bool
    let isViewSourceEnabled: Bool
    let isCreateMediaCaptionsEnabled: Bool
    let presentationContext: PresentationContext
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
        
        if presentationContext == .pinnedEvents || presentationContext == .mediaDetailsOnBrowser {
            actions.append(.viewInRoomTimeline)
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
        
        if canCurrentUserPin, let eventID = item.id.eventID {
            actions.append(pinnedEventIDs.contains(eventID) ? .unpin : .pin)
        }
        
        if item.isRemoteMessage {
            actions.append(.copyPermalink)
        }
        
        if item.isEditable {
            if item.supportsMediaCaption {
                if item.hasMediaCaption {
                    actions.append(.editCaption)
                } else if isCreateMediaCaptionsEnabled {
                    actions.append(.addCaption)
                }
            } else if item is PollRoomTimelineItem {
                actions.append(.editPoll)
            } else if !(item is VoiceMessageRoomTimelineItem) {
                actions.append(.edit)
            }
        }

        if item.isCopyable {
            actions.append(.copy)
        } else if item.hasMediaCaption {
            actions.append(.copyCaption)
        }
        
        if item.hasMediaCaption {
            actions.append(.removeCaption)
        }
        
        if canRedactItem(item), let poll = item.pollIfAvailable, !poll.hasEnded, let eventID = item.id.eventID {
            actions.append(.endPoll(pollStartID: eventID))
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
        
        switch presentationContext {
        case .room:
            break // viewInRoomTimeline is added conditionally so we don't need to filter.
        case .pinnedEvents:
            actions = actions.filter(\.canAppearInPinnedEventsTimeline)
            secondaryActions = secondaryActions.filter(\.canAppearInPinnedEventsTimeline)
        case .mediaDetailsOnBrowser, .mediaDetailsOnRoom:
            actions = actions.filter(\.canAppearInMediaDetails)
            secondaryActions = secondaryActions.filter(\.canAppearInMediaDetails)
        }
        
        if item.hasFailedToSend {
            actions = actions.filter(\.canAppearInFailedEcho)
            secondaryActions = secondaryActions.filter(\.canAppearInFailedEcho)
        }
        
        if item.isRedacted {
            actions = actions.filter(\.canAppearInRedacted)
            secondaryActions = secondaryActions.filter(\.canAppearInRedacted)
        }

        return .init(isReactable: presentationContext == .room ? item.isReactable : false,
                     actions: actions,
                     secondaryActions: secondaryActions,
                     emojiProvider: emojiProvider)
    }
    
    private func makeEncryptedItemActions(_ encryptedItem: EncryptedRoomTimelineItem) -> TimelineItemMenuActions? {
        var actions: [TimelineItemMenuAction] = [.copyPermalink]
        var secondaryActions: [TimelineItemMenuAction] = []
        
        if isViewSourceEnabled {
            actions.append(.viewSource)
        }
        
        switch encryptedItem.encryptionType {
        case .megolmV1AesSha2(let sessionID, _):
            secondaryActions.append(.retryDecryption(sessionID: sessionID))
        default:
            break
        }
        
        return .init(isReactable: false,
                     actions: actions,
                     secondaryActions: secondaryActions,
                     emojiProvider: emojiProvider)
    }
    
    private func canRedactItem(_ item: EventBasedTimelineItemProtocol) -> Bool {
        item.isOutgoing ? canCurrentUserRedactSelf : canCurrentUserRedactOthers && !isDM
    }
}
