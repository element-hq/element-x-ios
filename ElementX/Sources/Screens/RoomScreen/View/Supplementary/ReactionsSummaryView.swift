//
// Copyright 2023 New Vector Ltd
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

struct ReactionsSummaryView: View {
    let reactions: [AggregatedReaction]
    let members: [String: RoomMemberState]
    let imageProvider: ImageProviderProtocol?
    
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
                            ReactionSummarySenderView(sender: sender, member: members[sender.id], imageProvider: imageProvider)
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
    let imageProvider: ImageProviderProtocol?
    
    var displayName: String {
        member?.displayName ?? sender.id
    }
    
    var body: some View {
        HStack(spacing: 8) {
            LoadableAvatarImage(url: member?.avatarURL,
                                name: displayName,
                                contentID: sender.id,
                                avatarSize: .user(on: .timeline),
                                imageProvider: imageProvider)
            
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
                             imageProvider: MockMediaProvider(),
                             selectedReactionKey: AggregatedReaction.mockReactions[0].key)
            .snapshot(perceptualPrecision: 0.7) // Date formatting breaks the snaphots on CI
    }
}
