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
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content

    @ScaledMetric private var senderNameVerticalPadding = 3
    private let cornerRadius: CGFloat = 12
    
    @State private var showItemActionMenu = false

    private var isTextItem: Bool { timelineItem is TextBasedRoomTimelineItem }
    private var isEncryptedOneToOneRoom: Bool { context.viewState.isEncryptedOneToOneRoom }

    var body: some View {
        ZStack(alignment: .trailingFirstTextBaseline) {
            VStack(alignment: alignment, spacing: -12) {
                if !timelineItem.isOutgoing, !isEncryptedOneToOneRoom {
                    header
                        .zIndex(1)
                }

                VStack(alignment: alignment, spacing: 0) {
                    HStack {
                        if timelineItem.isOutgoing {
                            Spacer()
                        }

                        messageBubbleWithReactions
                    }
                    .padding(timelineItem.isOutgoing ? .leading : .trailing, 40) // Extra padding to differentiate alignment.
                    
                    HStack(spacing: 0) {
                        if !timelineItem.isOutgoing {
                            Spacer()
                        }
                        TimelineItemStatusView(timelineItem: timelineItem)
                            .environmentObject(context)
                            .padding(.top, 8)
                            .padding(.bottom, 3)
                    }
                }
                .padding(.horizontal, 16)
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
                        .foregroundColor(.compound.textPrimary)
                        .lineLimit(1)
                        .padding(.vertical, senderNameVerticalPadding)
                }
                .accessibilityElement(children: .combine)
                .onTapGesture {
                    context.send(viewAction: .tappedOnUser(userID: timelineItem.sender.id))
                }
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
        }
    }
    
    var messageBubble: some View {
        styledContent
            .onTapGesture(count: 2) {
                context.send(viewAction: .displayEmojiPicker(itemID: timelineItem.id))
            }
            .onTapGesture {
                context.send(viewAction: .itemTapped(id: timelineItem.id))
            }
            // We need a tap gesture before this long one so that it doesn't
            // steal away the gestures from the scroll view
            .onLongPressGesture(minimumDuration: 0.25) {
                context.send(viewAction: .timelineItemMenu(itemID: timelineItem.id))
                feedbackGenerator.impactOccurred()
            } onPressingChanged: { pressing in
                if pressing {
                    feedbackGenerator.prepare()
                }
            }
            .padding(.top, messageBubbleTopPadding)
    }

    @ViewBuilder
    var styledContent: some View {
        if isMediaType {
            contentWithTimestamp
                .bubbleStyle(inset: false,
                             cornerRadius: cornerRadius,
                             corners: roundedCorners)
        } else {
            contentWithTimestamp
                .bubbleStyle(inset: true,
                             color: timelineItem.isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming,
                             cornerRadius: cornerRadius,
                             corners: roundedCorners)
        }
    }

    @ViewBuilder
    var contentWithTimestamp: some View {
        if isTextItem || isMediaType {
            ZStack(alignment: .bottomTrailing) {
                contentWithReply
                interactiveLocalizedSendInfo
            }
        } else {
            HStack(alignment: .bottom, spacing: 4) {
                contentWithReply
                interactiveLocalizedSendInfo
            }
        }
    }

    @ViewBuilder
    var interactiveLocalizedSendInfo: some View {
        if timelineItem.properties.deliveryStatus == .sendingFailed {
            backgroundedLocalizedSendInfo
                .onTapGesture {
                    context.sendFailedConfirmationDialogInfo = .init(transactionID: timelineItem.properties.transactionID)
                }
        } else {
            backgroundedLocalizedSendInfo
        }
    }

    @ViewBuilder
    var backgroundedLocalizedSendInfo: some View {
        if isMediaType {
            localizedSendInfo
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.compound.bgSubtleSecondary)
                .cornerRadius(10)
                .padding(.trailing, 4)
                .padding(.bottom, 4)

        } else {
            localizedSendInfo
        }
    }

    @ViewBuilder
    var localizedSendInfo: some View {
        HStack(spacing: 4) {
            if let timelineItem = timelineItem as? TextBasedRoomTimelineItem {
                Text(timelineItem.localizedSendInfo)
            } else {
                Text(timelineItem.timestamp)
            }

            if timelineItem.properties.deliveryStatus == .sendingFailed {
                Image(systemName: "exclamationmark.circle.fill")
            }
        }
        .font(.compound.bodyXS)
        .foregroundColor(timelineItem.properties.deliveryStatus == .sendingFailed ? .compound.textCriticalPrimary : .compound.textSecondary)
        .padding(.bottom, isMediaType ? 0 : -4)
    }
    
    @ViewBuilder
    var contentWithReply: some View {
        TimelineBubbleLayout(spacing: 8) {
            if let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol,
               let replyDetails = messageTimelineItem.replyDetails {
                // The rendered reply bubble with a greedy width. The custom layout prevents
                // the infinite width from increasing the overall width of the view.
                TimelineReplyView(placement: .timeline, timelineItemReplyDetails: replyDetails)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(4.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.compound.bgCanvasDefault)
                    .cornerRadius(8)
                    .layoutPriority(TimelineBubbleLayout.Priority.visibleQuote)
                
                // Add a fixed width reply bubble that is used for layout calculations but won't be rendered.
                TimelineReplyView(placement: .timeline, timelineItemReplyDetails: replyDetails)
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
        guard timelineItem.isOutgoing || isEncryptedOneToOneRoom else { return 0 }
        return timelineGroupStyle == .single || timelineGroupStyle == .first ? 8 : 0
    }

    private var isMediaType: Bool {
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
            .environment(\.readReceiptsEnabled, true)
            .previewDisplayName("Mock Timeline with read receipts")
        mockTimeline
            .environment(\.layoutDirection, .rightToLeft)
            .previewDisplayName("Mock Timeline RTL")
        replies
            .previewDisplayName("Replies")
    }
    
    static var mockTimeline: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.state.items) { item in
                    item.padding(TimelineStyle.bubbles.rowInsets) // Insets added in the table view cells
                }
            }
        }
        .environment(\.timelineStyle, .bubbles)
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
                                                                                     contentType: .text(.init(body: "Short")))),
                                          .single)
            
            RoomTimelineViewProvider.text(TextRoomTimelineItem(id: "",
                                                               timestamp: "10:42",
                                                               isOutgoing: true,
                                                               isEditable: false,
                                                               sender: .init(id: "whoever"),
                                                               content: .init(body: "Short message"),
                                                               replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                                     contentType: .text(.init(body: "A long message that should be on more than 2 lines and so will be clipped by the layout.")))),
                                          .single)
        }
        .environmentObject(viewModel.context)
    }
}
