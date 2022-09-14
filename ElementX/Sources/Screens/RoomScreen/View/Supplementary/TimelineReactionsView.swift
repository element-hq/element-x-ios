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
    let alignment: HorizontalAlignment
    let action: (String) -> Void
    
    var body: some View {
        AlignedScrollView(alignment: alignment, showsIndicators: false) {
            HStack {
                ForEach(reactions, id: \.self) { reaction in
                    TimelineReactionButton(reaction: reaction, action: action)
                }
            }
        }
    }
}

struct TimelineReactionButton: View {
    let reaction: AggregatedReaction
    let action: (String) -> Void
    
    var body: some View {
        Button { action(reaction.key) } label: { label }
    }
    
    var label: some View {
        HStack(spacing: 4) {
            Text(reaction.key)
                .font(.element.caption1)
            Text(String(reaction.count))
                .font(.element.caption1)
                .foregroundColor(.element.secondaryContent)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .background(
            Capsule()
                .strokeBorder(reaction.isHighlighted ? Color.element.accent : .element.background, lineWidth: 2)
                .background(reaction.isHighlighted ? Color.element.accent.opacity(0.1) : .element.system, in: Capsule())
        )
        .accessibilityElement(children: .combine)
    }
}

struct TimelineReactionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TimelineReactionButton(reaction: AggregatedReaction(key: "👍", count: 5, isHighlighted: true)) { _ in }
            TimelineReactionButton(reaction: AggregatedReaction(key: "👏", count: 1, isHighlighted: false)) { _ in }
            TimelineReactionButton(reaction: AggregatedReaction(key: "🎉", count: 20, isHighlighted: false)) { _ in }
            
            TimelineReactionsView(reactions: [
                AggregatedReaction(key: "😅", count: 1, isHighlighted: true),
                AggregatedReaction(key: "🤷‍♂️", count: 1, isHighlighted: false),
                AggregatedReaction(key: "🎨", count: 6, isHighlighted: true),
                AggregatedReaction(key: "🎉", count: 8, isHighlighted: false),
                AggregatedReaction(key: "🤯", count: 15, isHighlighted: true),
                AggregatedReaction(key: "🫣", count: 1, isHighlighted: false),
                AggregatedReaction(key: "🚀", count: 3, isHighlighted: true),
                AggregatedReaction(key: "😇", count: 2, isHighlighted: false),
                AggregatedReaction(key: "🤭", count: 9, isHighlighted: true),
                AggregatedReaction(key: "🫤", count: 10, isHighlighted: false)
            ], alignment: .leading) { _ in }
        }
    }
}
