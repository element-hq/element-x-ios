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

struct TimelineReactionsView: View {
    let reactions: [AggregatedReaction]
    let isOutgoing: Bool
    let toggleReaction: (String) -> Void
    let showReactionSummary: (String) -> Void
    
    var body: some View {
        FlowLayout(alignment: isOutgoing ? .trailing : .leading) {
            ForEach(reactions, id: \.self) { reaction in
                TimelineReactionButton(reaction: reaction,
                                       toggleReaction: toggleReaction,
                                       showReactionSummary: showReactionSummary).padding(4)
            }
        }
    }
}

struct TimelineReactionButton: View {
    let reaction: AggregatedReaction
    let toggleReaction: (String) -> Void
    let showReactionSummary: (String) -> Void
    
    var body: some View {
        Button {
            toggleReaction(reaction.key)
        } label: {
            label
        }
        .simultaneousGesture(LongPressGesture()
            .onEnded { _ in
                showReactionSummary(reaction.key)
            }
        )
    }
    
    var label: some View {
        HStack(spacing: 4) {
            Text(reaction.key)
                .font(.compound.bodyMD)
            Text(String(reaction.count))
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            backgroundShape
                .strokeBorder(reaction.isHighlighted ? Color.compound.textSecondary : .compound.bgCanvasDefault, lineWidth: 2)
                .background(reaction.isHighlighted ? Color.compound.textPrimary.opacity(0.1) : .compound._bgReactionButton, in: backgroundShape)
        )
        .accessibilityElement(children: .combine)
    }
    
    var backgroundShape: some InsettableShape {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }
}

struct TimelineReactionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TimelineReactionButton(reaction: AggregatedReaction.mockThumbsUpHighlighted) { _ in } showReactionSummary: { _ in }
            TimelineReactionButton(reaction: AggregatedReaction.mockClap) { _ in } showReactionSummary: { _ in }
            TimelineReactionButton(reaction: AggregatedReaction.mockParty) { _ in } showReactionSummary: { _ in }
            TimelineReactionsView(reactions: AggregatedReaction.mockReactions, isOutgoing: false) { _ in } showReactionSummary: { _ in }
            TimelineReactionsView(reactions: AggregatedReaction.mockReactions, isOutgoing: true) { _ in } showReactionSummary: { _ in }
        }
    }
}
