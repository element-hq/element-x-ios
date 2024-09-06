//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

@MainActor
struct TimelineReactionsView: View {
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection

    let context: TimelineViewModel.Context
    let itemID: TimelineItemIdentifier
    let reactions: [AggregatedReaction]
    let isLayoutRTL: Bool
    
    private var collapsed: Binding<Bool>
    
    init(context: TimelineViewModel.Context,
         itemID: TimelineItemIdentifier,
         reactions: [AggregatedReaction],
         isLayoutRTL: Bool = false) {
        self.context = context
        self.itemID = itemID
        self.reactions = reactions
        self.isLayoutRTL = isLayoutRTL
        
        collapsed = Binding(get: {
            context.reactionsCollapsed[itemID] ?? true
        }, set: {
            context.reactionsCollapsed[itemID] = $0
        })
    }
    
    var reactionsLayoutDirection: LayoutDirection {
        guard isLayoutRTL else { return layoutDirection }
        return layoutDirection == .leftToRight ? .rightToLeft : .leftToRight
    }
    
    var body: some View {
        layout {
            ForEach(reactions) { reaction in
                TimelineReactionButton(reaction: reaction) { key in
                    feedbackGenerator.impactOccurred()
                    context.send(viewAction: .toggleReaction(key: key, itemID: itemID))
                } showReactionSummary: { key in
                    context.send(viewAction: .displayReactionSummary(itemID: itemID, key: key))
                }
                .reactionLayoutItem(.reaction)
                .environment(\.layoutDirection, layoutDirection)
            }
            
            if isCollapsible {
                Button {
                    collapsed.wrappedValue.toggle()
                } label: {
                    TimelineCollapseButtonLabel(collapsed: collapsed.wrappedValue)
                        .transaction { $0.animation = nil }
                }
                .reactionLayoutItem(.expandCollapse)
                .environment(\.layoutDirection, layoutDirection)
            }
            
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
    
    // MARK: - Private
    
    private var isCollapsible: Bool {
        reactions.count > 5
    }
    
    private var layout: AnyLayout {
        if isCollapsible {
            return AnyLayout(CollapsibleReactionLayout(itemSpacing: 4,
                                                       rowSpacing: 4,
                                                       collapsed: collapsed.wrappedValue,
                                                       rowsBeforeCollapsible: 2))
        }
        
        return AnyLayout(HStackLayout(spacing: 4.0))
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
            Text(collapsed ? L10n.screenRoomTimelineReactionsShowMore : L10n.screenRoomTimelineReactionsShowLess)
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
    var body: some View {
        TimelineReactionButtonLabel {
            CompoundIcon(\.reactionAdd, size: .xSmall, relativeTo: .compound.bodySM)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .foregroundColor(.compound.iconSecondary)
                .accessibilityLabel(L10n.actionReact)
        }
    }
}

struct TimelineReactionViewPreviewsContainer: View {
    var body: some View {
        VStack(spacing: 8) {
            TimelineReactionsView(context: TimelineViewModel.mock.context,
                                  itemID: .init(timelineID: "1"),
                                  reactions: [AggregatedReaction.mockReactionWithLongText,
                                              AggregatedReaction.mockReactionWithLongTextRTL])
            Divider()
            TimelineReactionsView(context: TimelineViewModel.mock.context,
                                  itemID: .init(timelineID: "2"),
                                  reactions: Array(AggregatedReaction.mockReactions.prefix(3)))
            Divider()
            TimelineReactionsView(context: TimelineViewModel.mock.context,
                                  itemID: .init(timelineID: "3"),
                                  reactions: AggregatedReaction.mockReactions)
            Divider()
            TimelineReactionsView(context: TimelineViewModel.mock.context,
                                  itemID: .init(timelineID: "4"),
                                  reactions: AggregatedReaction.mockReactions,
                                  isLayoutRTL: true)
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
