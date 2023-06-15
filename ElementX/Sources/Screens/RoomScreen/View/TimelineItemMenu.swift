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
    
    let item: EventBasedTimelineItemProtocol
    let actions: TimelineItemMenuActions
    
    public var body: some View {
        VStack {
            header
                .frame(idealWidth: 300.0)
            
            Divider()
                .background(Color.compound.bgSubtlePrimary)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0.0) {
                    reactionsSection
                        .padding(.top, 4.0)
                        .padding(.bottom, 8.0)
                    
                    Divider()
                        .background(Color.compound.bgSubtlePrimary)
                    
                    viewsForActions(actions.actions)
                    
                    Divider()
                        .background(Color.compound.bgSubtlePrimary)
                    
                    viewsForActions(actions.debugActions)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var header: some View {
        HStack(alignment: .top, spacing: 0.0) {
            LoadableAvatarImage(url: item.sender.avatarURL,
                                name: item.sender.displayName,
                                contentID: item.sender.id,
                                avatarSize: .user(on: .timeline),
                                imageProvider: context.imageProvider)
            
            Spacer(minLength: 8.0)
            
            VStack(alignment: .leading) {
                Text(item.sender.displayName ?? item.sender.id)
                    .font(.compound.bodySMSemibold)
                    .foregroundColor(.compound.textPrimary)
                
                Text(item.body.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 16.0)
            
            Text(item.timestamp)
                .font(.compound.bodyXS)
                .foregroundColor(.compound.textSecondary)
        }
        .padding(.horizontal)
        .padding(.top, 32.0)
        .padding(.bottom, 4.0)
    }
    
    private var reactionsSection: some View {
        HStack(alignment: .center) {
            reactionButton(for: "👍️")
            reactionButton(for: "👎️")
            reactionButton(for: "🔥")
            reactionButton(for: "❤️")
            reactionButton(for: "👏")
            
            Button {
                presentationMode.wrappedValue.dismiss()
                // Otherwise we get errors that a sheet is already presented
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    context.send(viewAction: .displayEmojiPicker(itemID: item.id))
                }
            } label: {
                Image(systemName: "plus.circle")
                    .font(.compound.headingLG)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private func reactionButton(for emoji: String) -> some View {
        Button {
            presentationMode.wrappedValue.dismiss()
            context.send(viewAction: .sendReaction(key: emoji, eventID: item.id))
        } label: {
            Text(emoji)
                .padding(8.0)
                .font(.compound.headingLG)
                .background(Circle()
                    .foregroundColor(reactionBackgroundColor(for: emoji)))
            
            Spacer()
        }
    }
    
    private func reactionBackgroundColor(for emoji: String) -> Color {
        if item.properties.reactions.first(where: { $0.key == emoji }) != nil {
            return .compound.tempBgReactionButton
        } else {
            return .clear
        }
    }
    
    private func viewsForActions(_ actions: [TimelineItemMenuAction]) -> some View {
        ForEach(actions, id: \.self) { action in
            switch action {
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
        // Otherwise we might get errors that a sheet is already presented
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            context.send(viewAction: .timelineItemMenuAction(itemID: item.id, action: action))
        }
    }
    
    private struct MenuLabel: View {
        let title: String
        let systemImageName: String
        
        var body: some View {
            Label(title, systemImage: systemImageName)
                .labelStyle(FixedIconSizeLabelStyle())
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

struct TimelineItemMenu_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static var previews: some View {
        VStack {
            if let item = RoomTimelineItemFixtures.singleMessageChunk.first as? EventBasedTimelineItemProtocol,
               let actions = TimelineItemMenuActions(actions: [.copy, .edit, .reply, .redact], debugActions: [.viewSource]) {
                TimelineItemMenu(item: item, actions: actions)
            }
        }
        .environmentObject(viewModel.context)
    }
}
