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
    private static let horizontalSpacing: CGFloat = 4
    private static let verticalSpacing: CGFloat = 4
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @Namespace private var animation

    let itemID: TimelineItemIdentifier
    let reactions: [AggregatedReaction]
    @Binding var collapsed: Bool
        
    var body: some View {
        CollapsibleReactionLayout(itemSpacing: 4, rowSpacing: 4, collapsed: collapsed, rowsBeforeCollapsible: 2) {
            ForEach(reactions, id: \.self) { reaction in
                TimelineReactionButton(reaction: reaction) { key in
                    context.send(viewAction: .toggleReaction(key: key, itemID: itemID))
                } showReactionSummary: { key in
                    context.send(viewAction: .reactionSummary(itemID: itemID, key: key))
                }
                .reactionLayoutItem(.reaction)
            }
            Button {
                collapsed.toggle()
            } label: {
                TimelineCollapseButtonLabel(collapsed: collapsed)
            }
            .reactionLayoutItem(.expandCollapse)
            .animation(.easeOut, value: collapsed)
            Button {
                context.send(viewAction: .displayEmojiPicker(itemID: itemID))
            } label: {
                TimelineReactionAddMoreButtonLabel()
            }
            .animation(.easeOut, value: collapsed)
            .reactionLayoutItem(.addMore)
        }
        .coordinateSpace(name: Self.flowCoordinateSpace)
    }
}

/// The pill shape for the label that surrounds both the reaction and collapse buttons.
struct TimelineReactionButtonLabel<Content: View>: View {
    var isHighlighted = false
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
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

struct TimelineCollapseButtonLabel: View {
    var collapsed: Bool
    
    var body: some View {
        TimelineReactionButtonLabel {
            Text(collapsed ? L10n.screenRoomReactionsShowMore : L10n.screenRoomReactionsShowLess)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .layoutPriority(1)
                .drawingGroup()
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
        }
    }
}

struct TimelineReactionButton: View {
    let reaction: AggregatedReaction
    let toggleReaction: (String) -> Void
    let showReactionSummary: (String) -> Void
    
    var body: some View {
        label
            .onTapGesture {
                toggleReaction(reaction.key)
            }
            .longPressWithFeedback {
                showReactionSummary(reaction.key)
            }
    }
    
    var label: some View {
        TimelineReactionButtonLabel(isHighlighted: reaction.isHighlighted) {
            HStack(spacing: 4) {
                Text(reaction.key)
                    .font(.compound.bodyMD)
                if reaction.count > 1 {
                    Text(String(reaction.count))
                        .font(.compound.bodyMD)
                        .foregroundColor(textColor)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
        }
    }
    
    var textColor: Color {
        reaction.isHighlighted ? Color.compound.textPrimary : .compound.textSecondary
    }
}

struct TimelineReactionAddMoreButtonLabel: View {
    @ScaledMetric private var addMoreButtonIconSize = 16
    
    var body: some View {
        TimelineReactionButtonLabel {
            Image(asset: Asset.Images.timelineReactionAddMore)
                .resizable()
                .frame(width: addMoreButtonIconSize, height: addMoreButtonIconSize)
                // Vertical sizing is done by the layout so that the add more button
                // matches the height of the text based buttons.
                .padding(.horizontal, 8)
                .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}

struct TimelineReactionViewPreviewsContainer: View {
    @State private var collapseState1 = false
    @State private var collapseState2 = true

    var body: some View {
        VStack {
            TimelineReactionsView(itemID: .init(timelineID: "1"), reactions: Array(AggregatedReaction.mockReactions.prefix(3)), collapsed: .constant(true))
            Divider()
            TimelineReactionsView(itemID: .init(timelineID: "2"), reactions: AggregatedReaction.mockReactions, collapsed: $collapseState1)
            Divider()
            TimelineReactionsView(itemID: .init(timelineID: "3"), reactions: AggregatedReaction.mockReactions, collapsed: $collapseState2)
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
