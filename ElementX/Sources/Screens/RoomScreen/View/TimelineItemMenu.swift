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

struct TimelineItemMenuActions {
    let actions: [TimelineItemMenuAction]
    let debugActions: [TimelineItemMenuAction]
    
    init?(actions: [TimelineItemMenuAction], debugActions: [TimelineItemMenuAction]) {
        if actions.isEmpty, debugActions.isEmpty {
            return nil
        }
        
        self.actions = actions
        self.debugActions = debugActions
    }
}

enum TimelineItemMenuAction: Identifiable, Hashable {
    case react
    case copy
    case edit
    case quote
    case copyPermalink
    case redact
    case reply
    case viewSource
    case retryDecryption(sessionID: String)
    case report
    
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

public struct TimelineItemMenu: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var sheetContentHeight = CGFloat(0)
    
    let itemID: String
    let actions: TimelineItemMenuActions
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0.0) {
                viewsForActions(actions.actions)
                
                Divider()
                
                viewsForActions(actions.debugActions)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .tint(.element.accent)
        }
    }
    
    private func viewsForActions(_ actions: [TimelineItemMenuAction]) -> some View {
        ForEach(actions, id: \.self) { action in
            switch action {
            case .react:
                Button { send(action) } label: {
                    MenuLabel(title: L10n.commonReactions, systemImageName: "face.smiling")
                }
            case .copy:
                Button { send(action) } label: {
                    MenuLabel(title: L10n.actionCopy, systemImageName: "doc.on.doc")
                }
            case .edit:
                Button { send(action) } label: {
                    MenuLabel(title: L10n.actionEdit, systemImageName: "pencil.line")
                }
            case .quote:
                Button { send(action) } label: {
                    MenuLabel(title: L10n.actionQuote, systemImageName: "quote.bubble")
                }
            case .copyPermalink:
                Button { send(action) } label: {
                    MenuLabel(title: L10n.commonPermalink, systemImageName: "link")
                }
            case .reply:
                Button { send(action) } label: {
                    MenuLabel(title: L10n.actionReply, systemImageName: "arrowshape.turn.up.left")
                }
            case .redact:
                Button(role: .destructive) { send(action) } label: {
                    MenuLabel(title: L10n.actionRemove, systemImageName: "trash")
                }
            case .viewSource:
                Button { send(action) } label: {
                    MenuLabel(title: L10n.actionViewSource, systemImageName: "doc.text.below.ecg")
                }
            case .retryDecryption:
                Button { send(action) } label: {
                    MenuLabel(title: L10n.actionRetryDecryption, systemImageName: "arrow.down.message")
                }
            case .report:
                Button(role: .destructive) { send(action) } label: {
                    MenuLabel(title: L10n.actionReportContent, systemImageName: "exclamationmark.bubble")
                }
            }
        }
    }
    
    private func send(_ action: TimelineItemMenuAction) {
        presentationMode.wrappedValue.dismiss()
        context.send(viewAction: .timelineItemMenuAction(itemID: itemID, action: action))
    }
    
    private struct MenuLabel: View {
        let title: String
        let systemImageName: String
        
        var body: some View {
            Label(title, systemImage: systemImageName)
                .labelStyle(EqualIconWidthLabelStyle())
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}
