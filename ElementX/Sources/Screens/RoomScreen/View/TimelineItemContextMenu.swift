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
    let actions: [TimelineItemContextMenuAction]
    let debugActions: [TimelineItemContextMenuAction]
    
    init?(actions: [TimelineItemContextMenuAction], debugActions: [TimelineItemContextMenuAction]) {
        if actions.isEmpty, debugActions.isEmpty {
            return nil
        }
        
        self.actions = actions
        self.debugActions = debugActions
    }
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
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    
    let itemID: String
    let contextMenuActions: TimelineItemContextMenuActions
    
    public var body: some View {
        viewsForActions(contextMenuActions.actions)
        Menu {
            viewsForActions(contextMenuActions.debugActions)
        } label: {
            Label("Developer", systemImage: "hammer")
        }
    }
    
    private func viewsForActions(_ actions: [TimelineItemContextMenuAction]) -> some View {
        ForEach(actions, id: \.self) { action in
            switch action {
            case .react:
                Button { send(action) } label: {
                    Label(ElementL10n.reactions, systemImage: "face.smiling")
                }
            case .copy:
                Button { send(action) } label: {
                    Label(ElementL10n.actionCopy, systemImage: "doc.on.doc")
                }
            case .edit:
                Button { send(action) } label: {
                    Label(ElementL10n.edit, systemImage: "pencil.line")
                }
            case .quote:
                Button { send(action) } label: {
                    Label(ElementL10n.actionQuote, systemImage: "quote.bubble")
                }
            case .copyPermalink:
                Button { send(action) } label: {
                    Label(ElementL10n.permalink, systemImage: "link")
                }
            case .reply:
                Button { send(action) } label: {
                    Label(ElementL10n.reply, systemImage: "arrowshape.turn.up.left")
                }
            case .redact:
                Button(role: .destructive) { send(action) } label: {
                    Label(ElementL10n.actionRemove, systemImage: "trash")
                }
            case .viewSource:
                Button { send(action) } label: {
                    Label(ElementL10n.viewSource, systemImage: "doc.text.below.ecg")
                }
            }
        }
    }
    
    private func send(_ action: TimelineItemContextMenuAction) {
        context.send(viewAction: .contextMenuAction(itemID: itemID, action: action))
    }
}
