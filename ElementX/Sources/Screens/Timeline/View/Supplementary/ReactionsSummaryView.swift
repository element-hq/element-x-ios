//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct ReactionsSummaryView: View {
    let reactions: [AggregatedReaction]
    let members: [String: RoomMemberState]
    let mediaProvider: MediaProviderProtocol?
    
    @State var selectedReactionKey: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            reactionButtons
            sendersList
        }
        .presentationDetents([.medium])
        .presentationBackground(Color.compound.bgCanvasDefault)
        .presentationDragIndicator(.visible)
    }
    
    private var reactionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scrollView in
                HStack(spacing: 8) {
                    ForEach(reactions) { reaction in
                        ReactionSummaryButton(reaction: reaction, highlighted: selectedReactionKey == reaction.key) { key in
                            selectedReactionKey = key
                        }
                    }
                }
                .padding(.horizontal, 20)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        scrollView.scrollTo(selectedReactionKey)
                    }
                }
                .onChange(of: selectedReactionKey) { _ in
                    scrollView.scrollTo(selectedReactionKey)
                }
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 12)
    }
    
    private var sendersList: some View {
        TabView(selection: $selectedReactionKey) {
            ForEach(reactions) { reaction in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(reaction.senders) { sender in
                            ReactionSummarySenderView(sender: sender, member: members[sender.id], mediaProvider: mediaProvider)
                                .padding(.horizontal, 16)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .tag(reaction.key)
            }
        }
    }
}

private struct ReactionSummaryButton: View {
    let reaction: AggregatedReaction
    let highlighted: Bool
    let action: (String) -> Void
    
    var body: some View {
        Button { action(reaction.key) } label: { label }
    }
    
    var label: some View {
        HStack(spacing: 4) {
            Text(reaction.displayKey)
                .font(.compound.headingSM)
                .foregroundColor(textColor)
            if reaction.count > 1 {
                Text(String(reaction.count))
                    .font(.compound.headingSM)
                    .foregroundColor(textColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(highlighted ? Color.compound.bgActionPrimaryRest : .clear, in: Capsule())
        .accessibilityElement(children: .combine)
    }
    
    var textColor: Color {
        highlighted ? Color.compound.textOnSolidPrimary : Color.compound.textSecondary
    }
}

private struct ReactionSummarySenderView: View {
    var sender: ReactionSender
    var member: RoomMemberState?
    let mediaProvider: MediaProviderProtocol?
    
    var displayName: String {
        member?.displayName ?? sender.id
    }
    
    var body: some View {
        HStack(spacing: 8) {
            LoadableAvatarImage(url: member?.avatarURL,
                                name: displayName,
                                contentID: sender.id,
                                avatarSize: .user(on: .timeline),
                                mediaProvider: mediaProvider)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text(displayName)
                        .font(.compound.bodyMDSemibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(sender.timestamp.formattedMinimal())
                        .font(.compound.bodyXS)
                        .foregroundColor(.compound.textSecondary)
                }
                Text(sender.id)
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
            }
        }
        
        .padding(.vertical, 8)
    }
}

struct ReactionsSummaryView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        ReactionsSummaryView(reactions: AggregatedReaction.mockReactions,
                             members: [:],
                             mediaProvider: MockMediaProvider(),
                             selectedReactionKey: AggregatedReaction.mockReactions[0].key)
    }
}
