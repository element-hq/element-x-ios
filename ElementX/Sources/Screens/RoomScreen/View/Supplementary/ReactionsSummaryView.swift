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
    let imageProvider: ImageProviderProtocol?
    
    @State var selectedKey: String
    
    var selectedReactionIndex: Int {
        reactions.firstIndex(where: { $0.key == selectedKey }) ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(reactions, id: \.self) { reaction in
                        ReactionSummaryButton(reaction: reaction, highlighted: selectedKey == reaction.key) { _ in }
                    }
                }
            }
            TabView {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(reactions[selectedReactionIndex].senders, id: \.self) { sender in
                            ReactionSummarySenderView(sender: sender, imageProvider: imageProvider)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .padding(.leading)
    }
}

struct ReactionSummaryButton: View {
    let reaction: AggregatedReaction
    let highlighted: Bool
    let action: (String) -> Void
    
    var body: some View {
        Button { action(reaction.key) } label: { label }
    }
    
    var label: some View {
        HStack(spacing: 4) {
            Text(reaction.key)
                .font(.compound.headingSM)
            Text(String(reaction.count))
                .font(.compound.headingSM)
                .foregroundColor(highlighted ? Color.compound.textOnSolidPrimary : Color.compound.textSecondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(highlighted ? Color.compound.bgActionPrimaryRest : .clear, in: backgroundShape)
        .accessibilityElement(children: .combine)
    }
    
    var backgroundShape: some InsettableShape {
        Capsule()
    }
}

struct ReactionSummarySenderView: View {
    var sender: String
    let imageProvider: ImageProviderProtocol?
    
    var body: some View {
        HStack {
            LoadableAvatarImage(url: nil,
                                name: sender,
                                contentID: sender,
                                avatarSize: .user(on: .timeline),
                                imageProvider: imageProvider)
            VStack {
                Text(sender)
                    .font(.compound.bodyMD)
                Text(sender)
                    .font(.compound.bodyMD)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ReactionsSummaryView_Previews: PreviewProvider {
    static let me = RoomMemberProxyMock.mockMe.userID
    static let alice = RoomMemberProxyMock.mockAlice.userID
    static let bob = RoomMemberProxyMock.mockBob.userID
    static var previews: some View {
        ReactionsSummaryView(reactions: AggregatedReaction.mockReactions,
                             imageProvider: MockMediaProvider(),
                             selectedKey: AggregatedReaction.mockReactions[0].key)
    }
}
