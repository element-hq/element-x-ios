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

import SwiftUI

struct TimelineItemContextMenuActions {
    static var empty: TimelineItemContextMenuActions { .init(actions: [], debugActions: []) }
    
    let actions: [TimelineItemContextMenuAction]
    let debugActions: [TimelineItemContextMenuAction]
    var isEmpty: Bool { actions.isEmpty && debugActions.isEmpty }
}

enum TimelineItemContextMenuAction: Identifiable, Hashable {
    case react
    case copy
    case edit
    case quote
    case copyPermalink
    case redact
    case reply
    case viewSource
    case retryDecryption(sessionId: String)
    
    var id: Self { self }

    var switchToDefaultComposer: Bool {
        switch self {
        case .reply, .edit:
            return false
        default:
            return true
        }
    }
}

public struct TimelineItemContextMenu: View {
    let contextMenuActions: TimelineItemContextMenuActions
    let callback: (TimelineItemContextMenuAction) -> Void
    
    public var body: some View {
        if contextMenuActions.isEmpty {
            // When there are no actions make sure then menu isn't shown.
            EmptyView()
        } else {
            viewsForActions(contextMenuActions.actions)
            Menu {
                viewsForActions(contextMenuActions.debugActions)
            } label: {
                Label("Developer", systemImage: "hammer")
            }
        }
    }
    
    private func viewsForActions(_ actions: [TimelineItemContextMenuAction]) -> some View {
        ForEach(actions, id: \.self) { item in
            switch item {
            case .react:
                Button { callback(item) } label: {
                    Label(ElementL10n.reactions, systemImage: "face.smiling")
                }
            case .copy:
                Button { callback(item) } label: {
                    Label(ElementL10n.actionCopy, systemImage: "doc.on.doc")
                }
            case .edit:
                Button { callback(item) } label: {
                    Label(ElementL10n.edit, systemImage: "pencil")
                }
            case .quote:
                Button { callback(item) } label: {
                    Label(ElementL10n.actionQuote, systemImage: "quote.bubble")
                }
            case .copyPermalink:
                Button { callback(item) } label: {
                    Label(ElementL10n.permalink, systemImage: "link")
                }
            case .reply:
                Button { callback(item) } label: {
                    Label(ElementL10n.reply, systemImage: "arrow.uturn.left")
                }
            case .redact:
                Button(role: .destructive) { callback(item) } label: {
                    Label(ElementL10n.messageActionItemRedact, systemImage: "trash")
                }
            case .viewSource:
                Button { callback(item) } label: {
                    Label(ElementL10n.viewSource, systemImage: "doc.text.below.ecg")
                }
            case .retryDecryption:
                Button { callback(item) } label: {
                    Label(ElementL10n.roomTimelineContextMenuRetryDecryption, systemImage: "arrow.down.message")
                }
            }
        }
    }
}
