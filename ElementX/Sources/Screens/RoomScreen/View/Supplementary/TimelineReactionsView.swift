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
    private static let horizontalSpacing: CGFloat = 4
    private static let verticalSpacing: CGFloat = 4
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection

    let itemID: TimelineItemIdentifier
    let reactions: [AggregatedReaction]
    var isLayoutRTL = false
    @Binding var collapsed: Bool
    
    var reactionsLayoutDirection: LayoutDirection {
        guard isLayoutRTL else { return layoutDirection }
        return layoutDirection == .leftToRight ? .rightToLeft : .leftToRight
    }
        
    var body: some View {
        if reactions.count < 5 {
            nonCollapsibleBody
        } else {
            collapsibleBody
        }
    }
    
    // MARK: - Private
    
    private var nonCollapsibleBody: some View {
        HStack(spacing: 4) {
            ForEach(reactions, id: \.self) { reaction in
                TimelineReactionButton(reaction: reaction) { key in
                    feedbackGenerator.impactOccurred()
                    context.send(viewAction: .toggleReaction(key: key, itemID: itemID))
                } showReactionSummary: { key in
                    context.send(viewAction: .reactionSummary(itemID: itemID, key: key))
                }
                .reactionLayoutItem(.reaction)
                .environment(\.layoutDirection, layoutDirection)
            }
            
            Button {
                context.send(viewAction: .displayEmojiPicker(itemID: itemID))
            } label: {
                TimelineReactionAddMoreButtonLabel()
            }
        }
        .environment(\.layoutDirection, reactionsLayoutDirection)
        .animation(.easeInOut(duration: 0.1).disabledDuringTests(), value: reactions)
        .padding(.leading, 4)
    }
    
    private var collapsibleBody: some View {
        CollapsibleReactionLayout(itemSpacing: 4, rowSpacing: 4, collapsed: collapsed, rowsBeforeCollapsible: 2) {
            ForEach(reactions, id: \.self) { reaction in
                TimelineReactionButton(reaction: reaction) { key in
                    feedbackGenerator.impactOccurred()
                    context.send(viewAction: .toggleReaction(key: key, itemID: itemID))
                } showReactionSummary: { key in
                    context.send(viewAction: .reactionSummary(itemID: itemID, key: key))
                }
                .reactionLayoutItem(.reaction)
                .environment(\.layoutDirection, layoutDirection)
            }
            Button {
                collapsed.toggle()
            } label: {
                TimelineCollapseButtonLabel(collapsed: collapsed)
                    .transaction { $0.animation = nil }
            }
            .reactionLayoutItem(.expandCollapse)
            .environment(\.layoutDirection, layoutDirection)
            Button {
                context.send(viewAction: .displayEmojiPicker(itemID: itemID))
            } label: {
                TimelineReactionAddMoreButtonLabel()
            }
            .reactionLayoutItem(.addMore)
        }
        .environment(\.layoutDirection, reactionsLayoutDirection)
        .animation(.easeInOut(duration: 0.1).disabledDuringTests(), value: reactions)
        .padding(.leading, 4)
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
    @ScaledMetric(relativeTo: .subheadline) private var lineHeight = 20
    
    var body: some View {
        TimelineReactionButtonLabel {
            Text(collapsed ? L10n.screenRoomReactionsShowMore : L10n.screenRoomReactionsShowLess)
                .frame(height: lineHeight, alignment: .center)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
        }
    }
}

struct TimelineReactionButton: View {
    let reaction: AggregatedReaction
    let toggleReaction: (String) -> Void
    let showReactionSummary: (String) -> Void
    @ScaledMetric(relativeTo: .subheadline) private var lineHeight = 20
    
    var body: some View {
        label
            .onTapGesture {
                toggleReaction(reaction.key)
            }
            .longPressWithFeedback {
                showReactionSummary(reaction.key)
            }
            .accessibilityHint(L10n.commonReaction)
            .accessibilityAddTraits(reaction.isHighlighted ? .isSelected : [])
    }
    
    var label: some View {
        TimelineReactionButtonLabel(isHighlighted: reaction.isHighlighted) {
            HStack(spacing: 4) {
                // Designs have bodyMD for the key but practically this makes
                // emojis too big. bodySM gives a more appropriate size when compared
                // to the count text and the lineHeight/padding in the designs.
                Text(reaction.displayKey)
                    .font(.compound.bodySM)
                if reaction.count > 1 {
                    Text(String(reaction.count))
                        .font(.compound.bodyMD)
                        .foregroundColor(textColor)
                }
            }
            .frame(height: lineHeight, alignment: .center)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
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
            Image(asset: Asset.Images.addReaction)
                .resizable()
                .frame(width: addMoreButtonIconSize, height: addMoreButtonIconSize)
                // Vertical sizing is done by the layout so that the add more button
                // matches the height of the text based buttons.
                .padding(.horizontal, 10)
                .frame(maxHeight: .infinity, alignment: .center)
                .foregroundColor(.compound.iconSecondary)
        }
    }
}

struct TimelineReactionViewPreviewsContainer: View {
    @State private var collapseState1 = false
    @State private var collapseState2 = true

    var body: some View {
        VStack {
            TimelineReactionsView(itemID: .init(timelineID: "1"),
                                  reactions: [AggregatedReaction.mockReactionWithLongText,
                                              AggregatedReaction.mockReactionWithLongTextRTL],
                                  collapsed: .constant(true))
            Divider()
            TimelineReactionsView(itemID: .init(timelineID: "2"), reactions: Array(AggregatedReaction.mockReactions.prefix(3)), collapsed: .constant(true))
            Divider()
            TimelineReactionsView(itemID: .init(timelineID: "3"), reactions: AggregatedReaction.mockReactions, collapsed: $collapseState1)
            Divider()
            TimelineReactionsView(itemID: .init(timelineID: "4"), reactions: AggregatedReaction.mockReactions, isLayoutRTL: true, collapsed: $collapseState2)
        }
        .background(Color.red)
        .frame(maxWidth: 250, alignment: .leading)
    }
}

struct TimelineReactionView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        TimelineReactionViewPreviewsContainer()
    }
}
