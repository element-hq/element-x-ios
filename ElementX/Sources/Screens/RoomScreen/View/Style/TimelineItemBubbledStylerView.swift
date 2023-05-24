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

import Foundation
import SwiftUI

struct TimelineItemBubbledStylerView<Content: View>: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    @Environment(\.timelineGroupStyle) private var timelineGroupStyle
    
    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content

    @ScaledMetric private var senderNameVerticalPadding = 3
    private let cornerRadius: CGFloat = 12

    private var isTextItem: Bool {
        timelineItem is TextBasedRoomTimelineItem
    }

    var body: some View {
        ZStack(alignment: .trailingFirstTextBaseline) {
            VStack(alignment: alignment, spacing: -12) {
                if !timelineItem.isOutgoing {
                    header
                        .zIndex(1)
                }
                
                HStack {
                    if timelineItem.isOutgoing {
                        Spacer()
                    }
                    
                    messageBubbleWithReactions
                }
                .padding(.horizontal, 16.0)
                .padding(timelineItem.isOutgoing ? .leading : .trailing, 40) // Extra padding to differentiate alignment.
            }
        }
    }
    
    @ViewBuilder
    private var header: some View {
        if shouldShowSenderDetails {
            VStack {
                Spacer()
                    .frame(height: 8)
                HStack(alignment: .top, spacing: 4) {
                    TimelineSenderAvatarView(timelineItem: timelineItem)
                        .accessibilityHidden(true)
                    Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                        .font(.compound.bodySMSemibold)
                        .foregroundColor(.element.primaryContent)
                        .lineLimit(1)
                        .padding(.vertical, senderNameVerticalPadding)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
    
    private var messageBubbleWithReactions: some View {
        // Figma has a spacing of -4 but it doesn't take into account
        // the centre aligned stroke width so we use -5 here
        VStack(alignment: alignment, spacing: -5) {
            messageBubble
                .accessibilityElement(children: .combine)
            
            if !timelineItem.properties.reactions.isEmpty {
                TimelineReactionsView(reactions: timelineItem.properties.reactions,
                                      alignment: alignment) { key in
                    context.send(viewAction: .sendReaction(key: key, eventID: timelineItem.id))
                }
            }

            TimelineReceiptView(timelineItem: timelineItem)
                .environmentObject(context)
                .padding(.top, 10)
                .padding(.bottom, 3)
        }
    }
    
    var messageBubble: some View {
        styledContent
            .contentShape(.contextMenuPreview, RoundedCornerShape(radius: cornerRadius, corners: roundedCorners)) // Rounded corners for the context menu animation.
            .contextMenu {
                context.viewState.contextMenuActionProvider?(timelineItem.id).map { actions in
                    TimelineItemContextMenu(itemID: timelineItem.id, contextMenuActions: actions)
                }
            }
            .padding(.top, messageBubbleTopPadding)
    }
    
    @ViewBuilder
    var styledContent: some View {
        if shouldAvoidBubbling {
            contentWithReply
                .bubbleStyle(inset: false,
                             cornerRadius: cornerRadius,
                             corners: roundedCorners)
        } else {
            contentWithTimestamp
                .bubbleStyle(inset: true,
                             color: timelineItem.isOutgoing ? .element.bubblesYou : .element.bubblesNotYou,
                             cornerRadius: cornerRadius,
                             corners: roundedCorners)
        }
    }

    @ViewBuilder
    var contentWithTimestamp: some View {
        if isTextItem {
            ZStack(alignment: .topLeading) {
                contentWithReply
                    .layoutPriority(1)
                localisedSendInfo
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        } else {
            HStack(alignment: .bottom, spacing: 4) {
                contentWithReply
                localisedSendInfo
            }
        }
    }

    @ViewBuilder
    var localisedSendInfo: some View {
        HStack(spacing: 4) {
            Text(timelineItem.localisedSendInfo)
            if timelineItem.properties.deliveryStatus == .sendingFailed {
                Image(systemName: "exclamationmark.circle.fill")
            }
        }
        .font(.compound.bodyXS)
        .foregroundColor(timelineItem.properties.deliveryStatus == .sendingFailed ? .element.alert : .element.secondaryContent)
        .padding(.bottom, -4)
    }
    
    @ViewBuilder
    var contentWithReply: some View {
        TimelineBubbleLayout(spacing: 8) {
            if let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol,
               let replyDetails = messageTimelineItem.replyDetails {
                // The rendered reply bubble with a greedy width. The custom layout prevents
                // the infinite width from increasing the overall width of the view.
                TimelineReplyView(timelineItemReplyDetails: replyDetails)
                    .foregroundColor(.compound.textPlaceholder)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(4.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.element.background)
                    .cornerRadius(8)
                    .layoutPriority(TimelineBubbleLayout.Priority.visibleQuote)
                
                // Add a fixed width reply bubble that is used for layout calculations but won't be rendered.
                TimelineReplyView(timelineItemReplyDetails: replyDetails)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(4.0)
                    .layoutPriority(TimelineBubbleLayout.Priority.hiddenQuote)
                    .hidden()
            }
            
            content()
                .layoutPriority(TimelineBubbleLayout.Priority.regularText)
        }
    }
    
    private var messageBubbleTopPadding: CGFloat {
        guard timelineItem.isOutgoing else { return 0 }
        return timelineGroupStyle == .single || timelineGroupStyle == .first ? 8 : 0
    }

    private var shouldAvoidBubbling: Bool {
        timelineItem is ImageRoomTimelineItem || timelineItem is VideoRoomTimelineItem || timelineItem is StickerRoomTimelineItem
    }
    
    private var alignment: HorizontalAlignment {
        timelineItem.isOutgoing ? .trailing : .leading
    }
    
    private var roundedCorners: UIRectCorner {
        switch timelineGroupStyle {
        case .single:
            return .allCorners
        case .first:
            if timelineItem.isOutgoing {
                return [.topLeft, .topRight, .bottomLeft]
            } else {
                return [.topLeft, .topRight, .bottomRight]
            }
        case .middle:
            return timelineItem.isOutgoing ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight]
        case .last:
            if timelineItem.isOutgoing {
                return [.topLeft, .bottomLeft, .bottomRight]
            } else {
                return [.topRight, .bottomLeft, .bottomRight]
            }
        }
    }
    
    private var shouldShowSenderDetails: Bool {
        timelineGroupStyle.shouldShowSenderDetails
    }
}

private extension View {
    func bubbleStyle(inset: Bool, color: Color? = nil, cornerRadius: CGFloat, corners: UIRectCorner) -> some View {
        padding(inset ? 8 : 0)
            .background(inset ? color : nil)
            .cornerRadius(cornerRadius, corners: corners)
    }
}

struct TimelineItemBubbledStylerView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static var previews: some View {
        mockTimeline
            .previewDisplayName("Mock Timeline")
        mockTimeline
            .environment(\.layoutDirection, .rightToLeft)
            .previewDisplayName("Mock Timeline RTL")
        replies
            .previewDisplayName("Replies")
    }
    
    static var mockTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.state.items) { item in
                item.padding(TimelineStyle.bubbles.rowInsets) // Insets added in the table view cells
            }
        }
        .timelineStyle(.bubbles)
        .previewLayout(.sizeThatFits)
        .environmentObject(viewModel.context)
    }
    
    static var replies: some View {
        VStack {
            RoomTimelineViewProvider.text(TextRoomTimelineItem(id: "",
                                                               timestamp: "10:42",
                                                               isOutgoing: true,
                                                               isEditable: false,
                                                               sender: .init(id: "whoever"),
                                                               content: .init(body: "A long message that should be on multiple lines."),
                                                               replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                                     content: .text(.init(body: "Short")))),
                                          .single)
            
            RoomTimelineViewProvider.text(TextRoomTimelineItem(id: "",
                                                               timestamp: "10:42",
                                                               isOutgoing: true,
                                                               isEditable: false,
                                                               sender: .init(id: "whoever"),
                                                               content: .init(body: "Short message"),
                                                               replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                                     content: .text(.init(body: "A long message that should be on more than 2 lines and so will be clipped by the layout.")))),
                                          .single)
        }
        .environmentObject(viewModel.context)
    }
}
