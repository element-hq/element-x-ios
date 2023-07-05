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
    /// We use a coordinate space for measuring the reactions within their container.
    /// For some reason when using .local the origin of reactions always shown as (0, 0)
    private static let flowCoordinateSpace = "flowCoordinateSpace"
    private static let hSpacing: CGFloat = 4
    private static let vSpacing: CGFloat = 4
    
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection

    let itemID: String
    let reactions: [AggregatedReaction]
    @Binding var collapsed: Bool
        
    var body: some View {
        CollapsibleFlowLayout(itemSpacing: 4, lineSpacing: 4, collapsed: collapsed, linesBeforeCollapsible: 2) {
            ForEach(reactions, id: \.self) { reaction in
                TimelineReactionButton(itemID: itemID, reaction: reaction)
            }
            Button {
                collapsed.toggle()
            } label: {
                TimelineCollapseButton(collapsed: collapsed)
            }
        }
        .coordinateSpace(name: Self.flowCoordinateSpace)
    }
}

/// The pill shape for the label that surrounds both the reaction and collapse buttons.
struct TimelineReactionButtonLabel<Content: View>: View {
    var isHighlighted = false
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        HStack(spacing: 4) {
            content()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(backgroundShape.inset(by: 1).fill(overlayBackgroundColor))
        .overlay(backgroundShape.inset(by: 2.0).strokeBorder(overlayBorderColor))
        .overlay(backgroundShape.strokeBorder(Color.compound.bgCanvasDefault, lineWidth: 2))
        .accessibilityElement(children: .combine)
    }
    
    var backgroundShape: some InsettableShape {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
    }
    
    var overlayBackgroundColor: Color {
        isHighlighted ? Color.compound.bgSubtlePrimary : .compound.bgSubtleSecondary
    }
    
    var overlayBorderColor: Color {
        isHighlighted ? Color.compound.borderInteractivePrimary : .clear
    }
}

struct TimelineCollapseButton: View {
    var collapsed: Bool
    
    var body: some View {
        TimelineReactionButtonLabel {
            Text(collapsed ? L10n.screenRoomReactionsShowMore : L10n.screenRoomReactionsShowLess)
                .layoutPriority(1)
                .drawingGroup()
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
        }
    }
}

struct TimelineReactionButton: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    let itemID: String
    let reaction: AggregatedReaction
    
    var body: some View {
        label
            .onTapGesture {
                context.send(viewAction: .toggleReaction(key: reaction.key, eventID: itemID))
            }
            .longPressWithFeedback {
                context.send(viewAction: .reactionSummary(itemID: itemID, key: reaction.key))
            }
    }
    
    var label: some View {
        TimelineReactionButtonLabel(isHighlighted: reaction.isHighlighted) {
            Text(reaction.key)
                .font(.compound.bodyMD)
            if reaction.count > 1 {
                Text(String(reaction.count))
                    .font(.compound.bodyMD)
                    .foregroundColor(textColor)
            }
        }
    }
    
    var textColor: Color {
        reaction.isHighlighted ? Color.compound.textPrimary : .compound.textSecondary
    }
}

struct TimelineReactionViewPreviewsContainer: View {
    @State private var collapseState1 = false
    @State private var collapseState2 = true

    var body: some View {
        VStack {
            TimelineReactionsView(itemID: "1", reactions: Array(AggregatedReaction.mockReactions.prefix(3)), collapsed: .constant(true))
            Divider()
            TimelineReactionsView(itemID: "2", reactions: AggregatedReaction.mockReactions, collapsed: $collapseState1)
            Divider()
            TimelineReactionsView(itemID: "3", reactions: AggregatedReaction.mockReactions, collapsed: $collapseState2)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .background(Color.red)
        .frame(maxWidth: 250, alignment: .leading)
    }
}

struct TimelineReactionView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineReactionViewPreviewsContainer()
    }
}
