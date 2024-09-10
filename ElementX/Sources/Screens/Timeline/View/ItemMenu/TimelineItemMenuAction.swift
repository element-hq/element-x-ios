//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SFSafeSymbols
import SwiftUI

struct TimelineItemMenuActions {
    let reactions: [TimelineItemMenuReaction]
    let actions: [TimelineItemMenuAction]
    let debugActions: [TimelineItemMenuAction]
    
    init?(isReactable: Bool, actions: [TimelineItemMenuAction], debugActions: [TimelineItemMenuAction]) {
        if !isReactable, actions.isEmpty, debugActions.isEmpty {
            return nil
        }
        
        self.actions = actions
        self.debugActions = debugActions
        reactions = if isReactable {
            [
                .init(key: "👍️", symbol: .handThumbsup),
                .init(key: "👎️", symbol: .handThumbsdown),
                .init(key: "🔥", symbol: .flame),
                .init(key: "❤️", symbol: .heart),
                .init(key: "👏", symbol: .handsClap)
            ]
        } else {
            []
        }
    }
}

struct TimelineItemMenuReaction {
    let key: String
    let symbol: SFSymbol
}

enum TimelineItemMenuAction: Identifiable, Hashable {
    case copy
    case edit
    case copyPermalink
    case redact
    case reply(isThread: Bool)
    case forward(itemID: TimelineItemIdentifier)
    case viewSource
    case retryDecryption(sessionID: String)
    case report
    case react
    case toggleReaction(key: String)
    case endPoll(pollStartID: String)
    case pin
    case unpin
    case viewInRoomTimeline
    
    var id: Self { self }
    
    /// Whether the item should cancel a reply/edit occurring in the composer.
    var switchToDefaultComposer: Bool {
        switch self {
        case .reply, .edit:
            return false
        default:
            return true
        }
    }
    
    /// Whether the action should be shown for an item that failed to send.
    var canAppearInFailedEcho: Bool {
        switch self {
        case .copy, .edit, .redact, .viewSource:
            return true
        default:
            return false
        }
    }
    
    /// Whether the action should be shown for a redacted item.
    var canAppearInRedacted: Bool {
        switch self {
        case .viewSource, .unpin, .viewInRoomTimeline:
            return true
        default:
            return false
        }
    }
    
    /// Whether or not the action is destructive.
    var isDestructive: Bool {
        switch self {
        case .redact, .report:
            return true
        default:
            return false
        }
    }
    
    var canAppearInPinnedEventsTimeline: Bool {
        switch self {
        case .viewInRoomTimeline, .pin, .unpin, .forward:
            return true
        default:
            return false
        }
    }
    
    /// The action's label.
    @ViewBuilder
    var label: some View {
        switch self {
        case .copy:
            Label(L10n.actionCopy, icon: \.copy)
        case .edit:
            Label(L10n.actionEdit, icon: \.edit)
        case .copyPermalink:
            Label(L10n.actionCopyLinkToMessage, icon: \.link)
        case .reply(let isThread):
            Label(isThread ? L10n.actionReplyInThread : L10n.actionReply, icon: \.reply)
        case .forward:
            Label(L10n.actionForward, icon: \.forward)
        case .redact:
            Label(L10n.actionRemove, icon: \.delete)
        case .viewSource:
            Label(L10n.actionViewSource, icon: \.code)
        case .retryDecryption:
            Label(L10n.actionRetryDecryption, systemImage: "arrow.down.message")
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
        }
    }
}
