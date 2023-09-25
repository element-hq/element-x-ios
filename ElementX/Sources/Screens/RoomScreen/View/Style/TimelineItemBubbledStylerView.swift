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

import Compound

struct TimelineItemBubbledStylerView<Content: View>: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    @Environment(\.timelineGroupStyle) private var timelineGroupStyle
    
    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content

    @ScaledMetric private var senderNameVerticalPadding = 3
    
    @State private var showItemActionMenu = false

    private var isEncryptedOneToOneRoom: Bool { context.viewState.isEncryptedOneToOneRoom }
    
    /// The base padding applied to bubbles on either side.
    ///
    /// **Note:** This is on top of the insets applied to the cells by the table view.
    let bubbleHorizontalPadding: CGFloat = 8
    /// Additional padding applied to outgoing bubbles when the avatar is shown
    var bubbleAvatarPadding: CGFloat {
        guard !timelineItem.isOutgoing, !isEncryptedOneToOneRoom else { return 0 }
        return 8
    }
    
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
                    .padding(timelineItem.isOutgoing ? .leading : .trailing, 48) // Additional padding to differentiate alignment.

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
                .padding(.horizontal, bubbleHorizontalPadding)
                .padding(.leading, bubbleAvatarPadding)
            }
        }
    }
    
    @ViewBuilder
    private var header: some View {
        if shouldShowSenderDetails {
            HStack(alignment: .top, spacing: 4) {
                TimelineSenderAvatarView(timelineItem: timelineItem)
                Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                    .font(.compound.bodySMSemibold)
                    .foregroundColor(.compound.avatarColor(for: timelineItem.sender.id).foreground)
                    .lineLimit(1)
                    .padding(.vertical, senderNameVerticalPadding)
            }
            .accessibilityHidden(true)
            .onTapGesture {
                context.send(viewAction: .tappedOnUser(userID: timelineItem.sender.id))
            }
            .padding(.top, 8)
        }
    }
    
    private var messageBubbleWithReactions: some View {
        // Figma overlaps reactions by 3
        VStack(alignment: alignment, spacing: -3) {
            messageBubble
                .accessibilityRepresentation {
                    VStack {
                        Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                        messageBubble
                    }
                }
                .accessibilityElement(children: .combine)
            
            if !timelineItem.properties.reactions.isEmpty {
                TimelineReactionsView(itemID: timelineItem.id,
                                      reactions: timelineItem.properties.reactions,
                                      isLayoutRTL: timelineItem.isOutgoing,
                                      collapsed: context.reactionsCollapsedBinding(for: timelineItem.id))
                    // Workaround to stop the message long press stealing the touch from the reaction buttons
                    .onTapGesture { }
            }
        }
    }
    
    var messageBubble: some View {
        styledContent
            .onTapGesture(count: 2) {
                context.send(viewAction: .displayEmojiPicker(itemID: timelineItem.id))
            }
            .onTapGesture {
                context.send(viewAction: .itemTapped(itemID: timelineItem.id))
            }
            // We need a tap gesture before this long one so that it doesn't
            // steal away the gestures from the scroll view
            .longPressWithFeedback(disabled: context.viewState.longPressDisabledItemID == timelineItem.id) {
                context.send(viewAction: .timelineItemMenu(itemID: timelineItem.id))
            }
            .swipeRightAction {
                SwipeToReplyView(timelineItem: timelineItem)
            } shouldStartAction: {
                context.viewState.timelineItemMenuActionProvider?(timelineItem.id)?.canReply ?? false
            } action: {
                let isThread = (timelineItem as? EventBasedMessageTimelineItemProtocol)?.isThreaded ?? false
                context.send(viewAction: .timelineItemMenuAction(itemID: timelineItem.id, action: .reply(isThread: isThread)))
            }
            .contextMenu {
                TimelineItemMacContextMenu(item: timelineItem,
                                           actionProvider: context.viewState.timelineItemMenuActionProvider) { action in
                    context.send(viewAction: .timelineItemMenuAction(itemID: timelineItem.id, action: action))
                }
            }
            .padding(.top, messageBubbleTopPadding)
    }

    @ViewBuilder
    var styledContent: some View {
        contentWithTimestamp
            .bubbleStyle(insets: timelineItem.bubbleInsets,
                         color: timelineItem.bubbleBackgroundColor,
                         corners: roundedCorners)
    }

    @ViewBuilder
    var contentWithTimestamp: some View {
        timelineItem.bubbleSendInfoLayoutType
            .layout {
                contentWithReply
                interactiveLocalizedSendInfo
            }
    }

    @ViewBuilder
    var interactiveLocalizedSendInfo: some View {
        if timelineItem.hasFailedToSend {
            layoutedLocalizedSendInfo
                .onTapGesture {
                    context.sendFailedConfirmationDialogInfo = .init(itemID: timelineItem.id)
                }
        } else {
            layoutedLocalizedSendInfo
        }
    }

    @ViewBuilder
    var layoutedLocalizedSendInfo: some View {
        switch timelineItem.bubbleSendInfoLayoutType {
        case .overlay(capsuleStyle: true):
            localizedSendInfo
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.compound.bgSubtleSecondary)
                .cornerRadius(10)
                .padding(.trailing, 4)
                .padding(.bottom, 4)
        case .horizontal, .overlay(capsuleStyle: false):
            localizedSendInfo
                .padding(.bottom, -4)
        case .vertical:
            GridRow {
                localizedSendInfo
                    .gridColumnAlignment(.trailing)
            }
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

            if timelineItem.hasFailedToSend {
                CompoundIcon(\.error, size: .xSmall, relativeTo: .compound.bodyXS)
            }
        }
        .font(.compound.bodyXS)
        .foregroundColor(timelineItem.hasFailedToSend ? .compound.textCriticalPrimary : .compound.textSecondary)
    }
    
    @ViewBuilder
    var contentWithReply: some View {
        TimelineBubbleLayout(spacing: 8) {
            if let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol {
                if messageTimelineItem.isThreaded {
                    ThreadDecorator()
                        .padding(.leading, 4)
                        .layoutPriority(TimelineBubbleLayout.Priority.regularText)
                }
                if let replyDetails = messageTimelineItem.replyDetails {
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
            }
            
            content()
                .layoutPriority(TimelineBubbleLayout.Priority.regularText)
                .cornerRadius(timelineItem.contentCornerRadius)
        }
    }
    
    private var messageBubbleTopPadding: CGFloat {
        guard timelineItem.isOutgoing || isEncryptedOneToOneRoom else { return 0 }
        return timelineGroupStyle == .single || timelineGroupStyle == .first ? 8 : 0
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
    func bubbleStyle(insets: EdgeInsets, color: Color? = nil, cornerRadius: CGFloat = 12, corners: UIRectCorner) -> some View {
        padding(insets)
            .background(color)
            .cornerRadius(cornerRadius, corners: corners)
    }
}

// Describes how the content and the send info should be arranged inside a bubble
private enum BubbleSendInfoLayoutType {
    case horizontal(spacing: CGFloat = 4)
    case vertical(spacing: CGFloat = 4)
    case overlay(capsuleStyle: Bool)

    var layout: AnyLayout {
        let layout: any Layout

        switch self {
        case .horizontal(let spacing):
            layout = HStackLayout(alignment: .bottom, spacing: spacing)
        case .vertical(let spacing):
            layout = GridLayout(alignment: .leading, verticalSpacing: spacing)
        case .overlay:
            layout = ZStackLayout(alignment: .bottomTrailing)
        }

        return AnyLayout(layout)
    }
}

private extension EventBasedTimelineItemProtocol {
    var bubbleBackgroundColor: Color? {
        let defaultColor: Color = isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming

        switch self {
        case let self as EventBasedMessageTimelineItemProtocol:
            switch self {
            case is ImageRoomTimelineItem, is VideoRoomTimelineItem:
                // In case a reply detail or a thread decorator is present we render the color and the padding
                return self.replyDetails != nil || self.isThreaded ? defaultColor : nil
            default:
                return defaultColor
            }
        case is StickerRoomTimelineItem:
            return nil
        default:
            return defaultColor
        }
    }

    // The insets for the full bubble content.
    // Padding affecting just the "send info" should be added inside `layoutedLocalizedSendInfo`
    var bubbleInsets: EdgeInsets {
        let defaultInsets: EdgeInsets = .init(around: 8)

        switch self {
        case is StickerRoomTimelineItem:
            return .zero
        case is PollRoomTimelineItem:
            return .init(top: 12, leading: 12, bottom: 4, trailing: 12)
        case let self as EventBasedMessageTimelineItemProtocol:
            switch self {
            // In case a reply detail or a thread decorator is present we render the color and the padding
            case is ImageRoomTimelineItem,
                 is VideoRoomTimelineItem:
                return self.replyDetails != nil ||
                    self.isThreaded ? defaultInsets : .zero
            case let locationTimelineItem as LocationRoomTimelineItem:
                return locationTimelineItem.content.geoURI == nil ||
                    self.replyDetails != nil ||
                    self.isThreaded ? defaultInsets : .zero
            default:
                return defaultInsets
            }
        default:
            return defaultInsets
        }
    }

    var bubbleSendInfoLayoutType: BubbleSendInfoLayoutType {
        let defaultTimestampLayout: BubbleSendInfoLayoutType = .horizontal()

        switch self {
        case is TextBasedRoomTimelineItem:
            return .overlay(capsuleStyle: false)
        case is ImageRoomTimelineItem,
             is VideoRoomTimelineItem,
             is StickerRoomTimelineItem:
            return .overlay(capsuleStyle: true)
        case let locationTimelineItem as LocationRoomTimelineItem:
            return .overlay(capsuleStyle: locationTimelineItem.content.geoURI != nil)
        case is PollRoomTimelineItem:
            return .vertical(spacing: 16)
        default:
            return defaultTimestampLayout
        }
    }
    
    var contentCornerRadius: CGFloat {
        guard let message = self as? EventBasedMessageTimelineItemProtocol else { return .zero }
        
        switch message {
        case is ImageRoomTimelineItem, is VideoRoomTimelineItem, is LocationRoomTimelineItem:
            return message.replyDetails != nil || message.isThreaded ? 8 : .zero
        default:
            return .zero
        }
    }
}

struct TimelineItemBubbledStylerView_Previews: PreviewProvider, TestablePreview {
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
        threads
            .previewDisplayName("Thread decorator")
    }
    
    // These akwats include a reply
    static var threads: some View {
        ScrollView {
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .init(timelineID: ""),
                                                                             timestamp: "10:42",
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             isThreaded: true,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "A long message that should be on multiple lines."),
                                                                             replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                                                   contentType: .text(.init(body: "Short")))), groupStyle: .single))

            AudioRoomTimelineView(timelineItem: .init(id: .init(timelineID: ""),
                                                      timestamp: "10:42",
                                                      isOutgoing: true,
                                                      isEditable: false,
                                                      canBeRepliedTo: true,
                                                      isThreaded: true,
                                                      sender: .init(id: ""),
                                                      content: .init(body: "audio.ogg",
                                                                     duration: 100,
                                                                     waveform: Waveform.mockWaveform,
                                                                     source: nil,
                                                                     contentType: nil),
                                                      replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                            contentType: .text(.init(body: "Short")))))
            
            FileRoomTimelineView(timelineItem: .init(id: .init(timelineID: ""),
                                                     timestamp: "10:42",
                                                     isOutgoing: false,
                                                     isEditable: false,
                                                     canBeRepliedTo: true,
                                                     isThreaded: true,
                                                     sender: .init(id: ""),
                                                     content: .init(body: "File",
                                                                    source: nil,
                                                                    thumbnailSource: nil,
                                                                    contentType: nil),
                                                     replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                           contentType: .text(.init(body: "Short")))))
            ImageRoomTimelineView(timelineItem: .init(id: .init(timelineID: ""),
                                                      timestamp: "10:42",
                                                      isOutgoing: true,
                                                      isEditable: true,
                                                      canBeRepliedTo: true,
                                                      isThreaded: true,
                                                      sender: .init(id: ""),
                                                      content: .init(body: "Some image", source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/png"), thumbnailSource: nil),
                                                      replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                            contentType: .text(.init(body: "Short")))))
            LocationRoomTimelineView(timelineItem: .init(id: .random,
                                                         timestamp: "Now",
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         isThreaded: true,
                                                         sender: .init(id: "Bob"),
                                                         content: .init(body: "Fallback geo uri description",
                                                                        geoURI: .init(latitude: 41.902782,
                                                                                      longitude: 12.496366),
                                                                        description: "Location description description description description description description description description"),
                                                         replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                               contentType: .text(.init(body: "Short")))))
            LocationRoomTimelineView(timelineItem: .init(id: .random,
                                                         timestamp: "Now",
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         isThreaded: true,
                                                         sender: .init(id: "Bob"),
                                                         content: .init(body: "Fallback geo uri description",
                                                                        geoURI: .init(latitude: 41.902782, longitude: 12.496366), description: nil),
                                                         replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                               contentType: .text(.init(body: "Short")))))
            
            VoiceRoomTimelineView(timelineItem: .init(id: .init(timelineID: ""),
                                                      timestamp: "10:42",
                                                      isOutgoing: true,
                                                      isEditable: false,
                                                      canBeRepliedTo: true,
                                                      isThreaded: true,
                                                      sender: .init(id: ""),
                                                      content: .init(body: "audio.ogg",
                                                                     duration: 100,
                                                                     waveform: Waveform.mockWaveform,
                                                                     source: nil,
                                                                     contentType: nil),
                                                      replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                            contentType: .text(.init(body: "Short")))),
                                  playerState: AudioPlayerState(duration: 10, waveform: Waveform.mockWaveform))
        }
        .environmentObject(viewModel.context)
    }

    static var mockTimeline: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.state.timelineViewState.itemViewStates) { viewState in
                    RoomTimelineItemView(viewState: viewState)
                        .padding(TimelineStyle.bubbles.rowInsets)
                    // Insets added in the table view cells
                }
            }
        }
        .environment(\.timelineStyle, .bubbles)
        .environmentObject(viewModel.context)
    }

    static var replies: some View {
        VStack {
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .init(timelineID: ""),
                                                                             timestamp: "10:42",
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             isThreaded: false,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "A long message that should be on multiple lines."),
                                                                             replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                                                   contentType: .text(.init(body: "Short")))), groupStyle: .single))

            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .init(timelineID: ""),
                                                                             timestamp: "10:42",
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             isThreaded: false,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "Short message"),
                                                                             replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                                                   contentType: .text(.init(body: "A long message that should be on more than 2 lines and so will be clipped by the layout.")))), groupStyle: .single))
        }
        .environmentObject(viewModel.context)
    }
}

private extension EdgeInsets {
    init(around: CGFloat) {
        self.init(top: around, leading: around, bottom: around, trailing: around)
    }

    static var zero: Self = .init(around: 0)
}
