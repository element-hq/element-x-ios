//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import OrderedCollections
import SFSafeSymbols
import SwiftUI

@MainActor
struct TimelineItemMenuActions {
    let reactions: [TimelineItemMenuReaction]
    let actions: [TimelineItemMenuAction]
    let secondaryActions: [TimelineItemMenuAction]
    
    init?(isReactable: Bool,
          actions: [TimelineItemMenuAction],
          secondaryActions: [TimelineItemMenuAction],
          emojiProvider: EmojiProviderProtocol) {
        if !isReactable, actions.isEmpty, secondaryActions.isEmpty {
            return nil
        }
        
        self.actions = actions
        self.secondaryActions = secondaryActions
        
        var frequentlyUsed: OrderedSet<TimelineItemMenuReaction> = [
            .init(key: "👍️", symbol: .handThumbsup),
            .init(key: "👎️", symbol: .handThumbsdown),
            .init(key: "🎉", symbol: .partyPopper),
            .init(key: "❤️", symbol: .heart)
        ]
        
        frequentlyUsed.append(contentsOf: emojiProvider.frequentlyUsedSystemEmojis().map { TimelineItemMenuReaction(key: $0, symbol: .heart) })
        
        reactions = if isReactable {
            Array(frequentlyUsed.elements.prefix(10))
        } else {
            []
        }
    }
}

struct TimelineItemMenuReaction: Hashable {
    let key: String
    let symbol: SFSymbol
    
    // Frequently used emojis on the all use the same .heart SFSymbol.
    // Override equatable so we can remove duplicates.
    static func == (lhs: TimelineItemMenuReaction, rhs: TimelineItemMenuReaction) -> Bool {
        lhs.key == rhs.key
    }
}

enum TimelineItemMenuAction: Identifiable, Hashable {
    case copy
    case translate
    case copyCaption
    case edit
    case addCaption
    case editCaption
    case removeCaption
    case editPoll
    case copyPermalink
    case redact
    case reply(isThread: Bool)
    case replyInThread
    case forward(itemID: TimelineItemIdentifier)
    case viewSource
    case report
    case react
    case toggleReaction(key: String)
    case endPoll(pollStartID: String)
    case pin
    case unpin
    case viewInRoomTimeline
    case share
    case save
    
    var id: Self { self }
    
    /// Whether the item should cancel a reply/edit occurring in the composer.
    var switchToDefaultComposer: Bool {
        switch self {
        case .reply, .edit, .addCaption, .editCaption, .editPoll:
            false
        default:
            true
        }
    }
    
    /// Whether the action should be shown for an item that failed to send.
    var canAppearInFailedEcho: Bool {
        switch self {
        case .copy, .edit, .redact, .viewSource, .editPoll:
            true
        default:
            false
        }
    }
    
    /// Whether the action should be shown for a redacted item.
    var canAppearInRedacted: Bool {
        switch self {
        case .viewSource, .unpin, .viewInRoomTimeline:
            true
        default:
            false
        }
    }
    
    /// Whether or not the action is destructive.
    var isDestructive: Bool {
        switch self {
        case .redact, .report, .removeCaption:
            true
        default:
            false
        }
    }
    
    var canAppearInPinnedEventsTimeline: Bool {
        switch self {
        case .viewInRoomTimeline, .pin, .unpin, .forward:
            true
        default:
            false
        }
    }
    
    var canAppearInMediaDetails: Bool {
        switch self {
        case .viewInRoomTimeline, .share, .save, .redact, .forward:
            true
        default:
            false
        }
    }
    
    /// The action's label.
    @ViewBuilder
    var label: some View {
        switch self {
        case .copy:
            Label(L10n.actionCopyText, icon: \.copy)
        case .translate:
            Label(L10n.actionTranslate, icon: \.translate)
        case .copyCaption:
            Label(L10n.actionCopyCaption, icon: \.copy)
        case .edit:
            Label(L10n.actionEdit, icon: \.edit)
        case .addCaption:
            Label(L10n.actionAddCaption, icon: \.edit)
        case .editCaption:
            Label(L10n.actionEditCaption, icon: \.edit)
        case .removeCaption:
            Label(L10n.actionRemoveCaption, icon: \.close)
        case .editPoll:
            Label(L10n.actionEditPoll, icon: \.edit)
        case .copyPermalink:
            Label(L10n.actionCopyLinkToMessage, icon: \.link)
        case .reply(let isThread):
            Label(isThread ? L10n.actionReplyInThread : L10n.actionReply, icon: \.reply)
        case .replyInThread:
            Label(L10n.actionReplyInThread, icon: \.threads)
        case .forward:
            Label(L10n.actionForward, icon: \.forward)
        case .redact:
            Label(L10n.actionRemoveMessage, icon: \.delete)
        case .viewSource:
            Label(L10n.actionViewSource, icon: \.code)
        case .report:
            Label(L10n.actionReportContent, icon: \.chatProblem)
        case .react:
            Label(L10n.actionReact, icon: \.reactionAdd)
        case .toggleReaction:
            // Unused label - manually created in TimelineItemMacContextMenu.
            Label(L10n.actionReact, icon: \.reactionAdd)
        case .endPoll:
            Label(L10n.actionEndPoll, icon: \.pollsEnd)
        case .pin:
            Label(L10n.actionPin, icon: \.pin)
        case .unpin:
            Label(L10n.actionUnpin, icon: \.unpin)
        case .viewInRoomTimeline:
            Label(L10n.actionViewInTimeline, icon: \.visibilityOn)
        case .share:
            Label(L10n.actionShare, icon: \.shareIos)
        case .save:
            Label(L10n.actionSave, icon: \.downloadIos)
        }
    }
}
