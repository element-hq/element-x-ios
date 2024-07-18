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

import Compound
import SwiftUI

struct TimelineItemMenu: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    @Environment(\.dismiss) private var dismiss
    
    @State private var reactionsFrame = CGRect.zero
    
    let item: EventBasedTimelineItemProtocol
    let actions: TimelineItemMenuActions
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        VStack(spacing: 8) {
            header
                .frame(idealWidth: 300.0)
            
            Divider()
                .background(Color.compound.bgSubtlePrimary)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0.0) {
                    if !actions.reactions.isEmpty {
                        reactionsSection
                            .padding(.top, 4.0)
                            .padding(.bottom, 8.0)

                        Divider()
                            .background(Color.compound.bgSubtlePrimary)
                    }

                    if !actions.actions.isEmpty {
                        viewsForActions(actions.actions)

                        Divider()
                            .background(Color.compound.bgSubtlePrimary)
                    }
                    
                    viewsForActions(actions.debugActions)
                }
            }
        }
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.timelineItemActionMenu)
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.compound.bgCanvasDefault)
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
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.sender.displayName ?? item.sender.id)
                    .font(.compound.bodySMSemibold)
                    .foregroundColor(.compound.textPrimary)
                    .textSelection(.enabled)
                
                Text(item.timelineMenuDescription)
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
        ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: 8) {
                ForEach(actions.reactions, id: \.key) {
                    reactionButton(for: $0.key)
                }
                
                Button {
                    dismiss()
                    // Otherwise we get errors that a sheet is already presented
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        context.send(viewAction: .displayEmojiPicker(itemID: item.id))
                    }
                } label: {
                    CompoundIcon(\.reactionAdd, size: .medium, relativeTo: .compound.headingLG)
                        .foregroundColor(.compound.iconSecondary)
                        .padding(10)
                }
                .accessibilityLabel(L10n.actionReact)
            }
            .padding(.horizontal)
            .frame(minWidth: reactionsFrame.width, maxWidth: .infinity, alignment: .center)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .readFrame($reactionsFrame)
    }
    
    private func reactionButton(for emoji: String) -> some View {
        Button {
            feedbackGenerator.impactOccurred()
            dismiss()
            context.send(viewAction: .toggleReaction(key: emoji, itemID: item.id))
        } label: {
            Text(emoji)
                .font(.compound.headingLG)
                .padding(8)
                .background(Circle()
                    .foregroundColor(reactionBackgroundColor(for: emoji)))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func reactionBackgroundColor(for emoji: String) -> Color {
        if let reaction = item.properties.reactions.first(where: { $0.key == emoji }),
           reaction.isHighlighted {
            return .compound.bgActionPrimaryRest
        } else {
            return .clear
        }
    }
    
    private func viewsForActions(_ actions: [TimelineItemMenuAction]) -> some View {
        ForEach(actions, id: \.self) { action in
            Button(role: action.isDestructive ? .destructive : nil) {
                send(action)
            } label: {
                action.label
                    .labelStyle(.menuSheet)
            }
        }
    }
    
    private func send(_ action: TimelineItemMenuAction) {
        dismiss()
        // Otherwise we might get errors that a sheet is already presented
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            context.send(viewAction: .handleTimelineItemMenuAction(itemID: item.id, action: action))
        }
    }
}

struct TimelineItemMenu_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomScreenViewModel.mock

    static var previews: some View {
        testView
            .previewDisplayName("With button shapes off")
        testView
            .environment(\._accessibilityShowButtonShapes, true)
            .previewDisplayName("With button shapes on")
    }
    
    @ViewBuilder
    static var testView: some View {
        if let item = RoomTimelineItemFixtures.singleMessageChunk.first as? EventBasedTimelineItemProtocol,
           let actions = TimelineItemMenuActions(isReactable: true, actions: [.copy, .edit, .reply(isThread: false), .redact], debugActions: [.viewSource]) {
            TimelineItemMenu(item: item, actions: actions)
                .environmentObject(viewModel.context)
        }
    }
}
