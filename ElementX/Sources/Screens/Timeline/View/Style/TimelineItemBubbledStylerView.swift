//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineItemBubbledStylerView<Content: View>: View {
    @EnvironmentObject private var context: TimelineViewModel.Context
    @Environment(\.timelineGroupStyle) private var timelineGroupStyle
    @Environment(\.focussedEventID) private var focussedEventID
    
    let timelineItem: EventBasedTimelineItemProtocol
    let adjustedDeliveryStatus: TimelineItemDeliveryStatus?
    @ViewBuilder let content: () -> Content

    private var isEncryptedOneToOneRoom: Bool { context.viewState.isEncryptedOneToOneRoom }
    private var isFocussed: Bool { focussedEventID != nil && timelineItem.id.eventID == focussedEventID }
    private var isPinned: Bool {
        guard !context.viewState.isPinnedEventsTimeline,
              let eventID = timelineItem.id.eventID else {
            return false
        }
        return context.viewState.pinnedEventIDs.contains(eventID)
    }
    
    /// The base padding applied to bubbles on either side.
    ///
    /// **Note:** This is on top of the insets applied to the cells by the table view.
    private let bubbleHorizontalPadding: CGFloat = 8
    /// Additional padding applied to outgoing bubbles when the avatar is shown
    private var bubbleAvatarPadding: CGFloat {
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
                    HStack(spacing: 0) {
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
                        TimelineItemStatusView(timelineItem: timelineItem, adjustedDeliveryStatus: adjustedDeliveryStatus)
                            .environmentObject(context)
                            .padding(.top, 8)
                            .padding(.bottom, 3)
                    }
                }
                .padding(.horizontal, bubbleHorizontalPadding)
                .padding(.leading, bubbleAvatarPadding)
            }
        }
        .padding(EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8))
        .highlightedTimelineItem(isFocussed)
    }
    
    @ViewBuilder
    private var header: some View {
        if shouldShowSenderDetails {
            HStack(alignment: .top, spacing: 4) {
                TimelineSenderAvatarView(timelineItem: timelineItem)
                HStack(alignment: .center, spacing: 4) {
                    Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                        .font(.compound.bodySMSemibold)
                        .foregroundColor(.compound.decorativeColor(for: timelineItem.sender.id).text)
                    
                    if timelineItem.sender.displayName != nil, timelineItem.sender.isDisplayNameAmbiguous {
                        Text(timelineItem.sender.id)
                            .font(.compound.bodyXS)
                            .foregroundColor(.compound.textSecondary)
                    }
                }
                .lineLimit(1)
                .scaledPadding(.vertical, 3)
            }
            // sender info are read inside the `TimelineAccessibilityModifier`
            .accessibilityHidden(true)
            .onTapGesture {
                context.send(viewAction: .tappedOnSenderDetails(userID: timelineItem.sender.id))
            }
            .padding(.top, 8)
        }
    }
    
    private var messageBubbleWithReactions: some View {
        // Figma overlaps reactions by 3
        VStack(alignment: alignment, spacing: -3) {
            messageBubbleWithActions
                .timelineItemAccessibility(timelineItem) {
                    context.send(viewAction: .displayTimelineItemMenu(itemID: timelineItem.id))
                }
            
            // Do not display reactions in the pinned events timeline
            if !context.viewState.isPinnedEventsTimeline,
               !timelineItem.properties.reactions.isEmpty {
                TimelineReactionsView(context: context,
                                      itemID: timelineItem.id,
                                      reactions: timelineItem.properties.reactions,
                                      isLayoutRTL: timelineItem.isOutgoing)
                    // Workaround to stop the message long press stealing the touch from the reaction buttons
                    .onTapGesture { }
            }
        }
    }
    
    var messageBubbleWithActions: some View {
        messageBubble
            .onTapGesture {
                context.send(viewAction: .itemTapped(itemID: timelineItem.id))
            }
            // We need a tap gesture before this long one so that it doesn't
            // steal away the gestures from the scroll view
            .longPressWithFeedback {
                context.send(viewAction: .displayTimelineItemMenu(itemID: timelineItem.id))
            }
            .swipeRightAction {
                SwipeToReplyView(timelineItem: timelineItem)
            } shouldStartAction: {
                timelineItem.canBeRepliedTo
            } action: {
                let isThread = (timelineItem as? EventBasedMessageTimelineItemProtocol)?.isThreaded ?? false
                context.send(viewAction: .handleTimelineItemMenuAction(itemID: timelineItem.id, action: .reply(isThread: isThread)))
            }
            .contextMenu {
                let provider = TimelineItemMenuActionProvider(timelineItem: timelineItem,
                                                              canCurrentUserRedactSelf: context.viewState.canCurrentUserRedactSelf,
                                                              canCurrentUserRedactOthers: context.viewState.canCurrentUserRedactOthers,
                                                              canCurrentUserPin: context.viewState.canCurrentUserPin,
                                                              pinnedEventIDs: context.viewState.pinnedEventIDs,
                                                              isDM: context.viewState.isEncryptedOneToOneRoom,
                                                              isViewSourceEnabled: context.viewState.isViewSourceEnabled,
                                                              isPinnedEventsTimeline: context.viewState.isPinnedEventsTimeline)
                TimelineItemMacContextMenu(item: timelineItem, actionProvider: provider) { action in
                    context.send(viewAction: .handleTimelineItemMenuAction(itemID: timelineItem.id, action: action))
                }
            }
            .pinnedIndicator(isPinned: isPinned, isOutgoing: timelineItem.isOutgoing)
            .padding(.top, messageBubbleTopPadding)
    }
    
    var messageBubble: some View {
        contentWithReply
            .timelineItemSendInfo(timelineItem: timelineItem, adjustedDeliveryStatus: adjustedDeliveryStatus, context: context)
            .bubbleStyle(insets: timelineItem.bubbleInsets,
                         color: timelineItem.bubbleBackgroundColor,
                         corners: roundedCorners)
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
                        .onTapGesture {
                            context.send(viewAction: .focusOnEventID(replyDetails.eventID))
                        }
                    
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

    /// The insets for the full bubble content.
    /// Padding affecting just the "send info" should be added inside `TimelineItemSendInfoView`
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

private extension EdgeInsets {
    init(around: CGFloat) {
        self.init(top: around, leading: around, bottom: around, trailing: around)
    }

    static var zero: Self = .init(around: 0)
}

private struct PinnedIndicatorViewModifier: ViewModifier {
    let isPinned: Bool
    let isOutgoing: Bool
    
    func body(content: Content) -> some View {
        if isPinned {
            HStack(alignment: .top, spacing: 8) {
                if isOutgoing {
                    pinnedIndicator
                }
                content
                    .layoutPriority(1)
                if !isOutgoing {
                    pinnedIndicator
                }
            }
        } else {
            content
        }
    }
    
    private var pinnedIndicator: some View {
        CompoundIcon(\.pinSolid, size: .xSmall, relativeTo: .compound.bodyMD)
            .foregroundStyle(Color.compound.iconTertiary)
    }
}

private extension View {
    func pinnedIndicator(isPinned: Bool, isOutgoing: Bool) -> some View {
        modifier(PinnedIndicatorViewModifier(isPinned: isPinned, isOutgoing: isOutgoing))
    }
}

// MARK: - Previews

struct TimelineItemBubbledStylerView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    static let viewModelWithPins: TimelineViewModel = {
        var settings = AppSettings()
        settings.pinningEnabled = true
        let roomProxy = JoinedRoomProxyMock(.init(name: "Preview Room", pinnedEventIDs: [""]))
        return TimelineViewModel(roomProxy: roomProxy,
                                 focussedEventID: nil,
                                 timelineController: MockRoomTimelineController(),
                                 mediaProvider: MockMediaProvider(),
                                 mediaPlayerProvider: MediaPlayerProviderMock(),
                                 voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                 userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                 appMediator: AppMediatorMock.default,
                                 appSettings: settings,
                                 analyticsService: ServiceLocator.shared.analytics)
    }()

    static var previews: some View {
        mockTimeline
            .previewDisplayName("Mock Timeline")
        mockTimeline
            .environment(\.layoutDirection, .rightToLeft)
            .previewDisplayName("Mock Timeline RTL")
        replies
            .previewDisplayName("Replies")
        threads
            .previewDisplayName("Thread decorator")
        encryptionAuthenticity
            .previewDisplayName("Encryption Indicators")
        pinned
            .previewDisplayName("Pinned messages")
            .snapshotPreferences(delay: 1.0)
    }
    
    // These always include a reply
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
                                                                                                   eventID: "123",
                                                                                                   eventContent: .message(.text(.init(body: "Short"))))),
                                                  groupStyle: .single))

            AudioRoomTimelineView(timelineItem: .init(id: .init(timelineID: ""),
                                                      timestamp: "10:42",
                                                      isOutgoing: true,
                                                      isEditable: false,
                                                      canBeRepliedTo: true,
                                                      isThreaded: true,
                                                      sender: .init(id: ""),
                                                      content: .init(body: "audio.ogg",
                                                                     duration: 100,
                                                                     waveform: EstimatedWaveform.mockWaveform,
                                                                     source: nil,
                                                                     contentType: nil),
                                                      replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                            eventID: "123",
                                                                            eventContent: .message(.text(.init(body: "Short"))))))
            
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
                                                                           eventID: "123",
                                                                           eventContent: .message(.text(.init(body: "Short"))))))
            ImageRoomTimelineView(timelineItem: .init(id: .init(timelineID: ""),
                                                      timestamp: "10:42",
                                                      isOutgoing: true,
                                                      isEditable: true,
                                                      canBeRepliedTo: true,
                                                      isThreaded: true,
                                                      sender: .init(id: ""),
                                                      content: .init(body: "Some image", source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/png"), thumbnailSource: nil),
                                                      replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                            eventID: "123",
                                                                            eventContent: .message(.text(.init(body: "Short"))))))
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
                                                                               eventID: "123",
                                                                               eventContent: .message(.text(.init(body: "Short"))))))
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
                                                                               eventID: "123",
                                                                               eventContent: .message(.text(.init(body: "Short"))))))
            
            VoiceMessageRoomTimelineView(timelineItem: .init(id: .init(timelineID: ""),
                                                             timestamp: "10:42",
                                                             isOutgoing: true,
                                                             isEditable: false,
                                                             canBeRepliedTo: true,
                                                             isThreaded: true,
                                                             sender: .init(id: ""),
                                                             content: .init(body: "audio.ogg",
                                                                            duration: 100,
                                                                            waveform: EstimatedWaveform.mockWaveform,
                                                                            source: nil,
                                                                            contentType: nil),
                                                             replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                                   eventID: "123",
                                                                                   eventContent: .message(.text(.init(body: "Short"))))),
                                         playerState: AudioPlayerState(id: .timelineItemIdentifier(.random),
                                                                       title: L10n.commonVoiceMessage,
                                                                       duration: 10,
                                                                       waveform: EstimatedWaveform.mockWaveform))
        }
        .environmentObject(viewModel.context)
    }

    static var mockTimeline: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.state.timelineViewState.itemViewStates) { viewState in
                    RoomTimelineItemView(viewState: viewState)
                }
            }
        }
        .environmentObject(viewModel.context)
    }

    static var replies: some View {
        VStack(spacing: 0) {
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .init(timelineID: ""),
                                                                             timestamp: "10:42",
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             isThreaded: false,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "A long message that should be on multiple lines."),
                                                                             replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                                                   eventID: "123",
                                                                                                   eventContent: .message(.text(.init(body: "Short"))))),
                                                  groupStyle: .single))

            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .init(timelineID: ""),
                                                                             timestamp: "10:42",
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             isThreaded: false,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "Short message"),
                                                                             replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                                                   eventID: "123",
                                                                                                   eventContent: .message(.text(.init(body: "A long message that should be on more than 2 lines and so will be clipped by the layout."))))),
                                                  groupStyle: .single))
        }
        .environmentObject(viewModel.context)
    }

    static var encryptionAuthenticity: some View {
        VStack(spacing: 0) {
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .init(timelineID: ""),
                                                                             timestamp: "10:42",
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             isThreaded: false,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "A long message that should be on multiple lines."),
                                                                             properties: RoomTimelineItemProperties(encryptionAuthenticity: .unsignedDevice(color: .red))),
                                                  groupStyle: .single))
            
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .init(timelineID: ""),
                                                                             timestamp: "10:42",
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             isThreaded: false,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "A long message that should be on multiple lines."),
                                                                             properties: RoomTimelineItemProperties(isEdited: true,
                                                                                                                    encryptionAuthenticity: .unsignedDevice(color: .red))),
                                                  groupStyle: .single))
            
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .init(timelineID: ""),
                                                                             timestamp: "10:42",
                                                                             isOutgoing: false,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             isThreaded: false,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "Short message"),
                                                                             properties: RoomTimelineItemProperties(encryptionAuthenticity: .unknownDevice(color: .red))),
                                                  groupStyle: .first))
            
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .init(timelineID: ""),
                                                                             timestamp: "10:42",
                                                                             isOutgoing: false,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             isThreaded: false,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "Message goes Here"),
                                                                             properties: RoomTimelineItemProperties(encryptionAuthenticity: .notGuaranteed(color: .gray))),
                                                  groupStyle: .last))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .random,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(body: "Some other image", source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/png"), thumbnailSource: nil),
                                                                      
                                                                      properties: RoomTimelineItemProperties(encryptionAuthenticity: .notGuaranteed(color: .gray))))
            
            VoiceMessageRoomTimelineView(timelineItem: .init(id: .init(timelineID: ""),
                                                             timestamp: "10:42",
                                                             isOutgoing: true,
                                                             isEditable: false,
                                                             canBeRepliedTo: true,
                                                             isThreaded: true,
                                                             sender: .init(id: ""),
                                                             content: .init(body: "audio.ogg",
                                                                            duration: 100,
                                                                            waveform: EstimatedWaveform.mockWaveform,
                                                                            source: nil,
                                                                            contentType: nil),
                                                             properties: RoomTimelineItemProperties(encryptionAuthenticity: .notGuaranteed(color: .gray))),
                                         playerState: AudioPlayerState(id: .timelineItemIdentifier(.random),
                                                                       title: L10n.commonVoiceMessage,
                                                                       duration: 10,
                                                                       waveform: EstimatedWaveform.mockWaveform))
        }
        .environmentObject(viewModel.context)
    }
        
    static var pinned: some View {
        ScrollView {
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .init(timelineID: "", eventID: ""),
                                                                             timestamp: "10:42",
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             isThreaded: false,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "A long message that should be on multiple lines."),
                                                                             replyDetails: nil),
                                                  groupStyle: .single))

            AudioRoomTimelineView(timelineItem: .init(id: .init(timelineID: "", eventID: ""),
                                                      timestamp: "10:42",
                                                      isOutgoing: true,
                                                      isEditable: false,
                                                      canBeRepliedTo: true,
                                                      isThreaded: false,
                                                      sender: .init(id: ""),
                                                      content: .init(body: "audio.ogg",
                                                                     duration: 100,
                                                                     waveform: EstimatedWaveform.mockWaveform,
                                                                     source: nil,
                                                                     contentType: nil),
                                                      replyDetails: nil))
            
            FileRoomTimelineView(timelineItem: .init(id: .init(timelineID: "", eventID: ""),
                                                     timestamp: "10:42",
                                                     isOutgoing: false,
                                                     isEditable: false,
                                                     canBeRepliedTo: true,
                                                     isThreaded: false,
                                                     sender: .init(id: ""),
                                                     content: .init(body: "File",
                                                                    source: nil,
                                                                    thumbnailSource: nil,
                                                                    contentType: nil),
                                                     replyDetails: nil))
            ImageRoomTimelineView(timelineItem: .init(id: .init(timelineID: "", eventID: ""),
                                                      timestamp: "10:42",
                                                      isOutgoing: true,
                                                      isEditable: true,
                                                      canBeRepliedTo: true,
                                                      isThreaded: false,
                                                      sender: .init(id: ""),
                                                      content: .init(body: "Some image", source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/png"), thumbnailSource: nil),
                                                      replyDetails: nil))
            LocationRoomTimelineView(timelineItem: .init(id: .init(timelineID: "", eventID: ""),
                                                         timestamp: "Now",
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         isThreaded: false,
                                                         sender: .init(id: "Bob"),
                                                         content: .init(body: "Fallback geo uri description",
                                                                        geoURI: .init(latitude: 41.902782,
                                                                                      longitude: 12.496366),
                                                                        description: "Location description description description description description description description description"),
                                                         replyDetails: nil))
            LocationRoomTimelineView(timelineItem: .init(id: .init(timelineID: "", eventID: ""),
                                                         timestamp: "Now",
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         isThreaded: false,
                                                         sender: .init(id: "Bob"),
                                                         content: .init(body: "Fallback geo uri description",
                                                                        geoURI: .init(latitude: 41.902782, longitude: 12.496366), description: nil),
                                                         replyDetails: nil))
            
            VoiceMessageRoomTimelineView(timelineItem: .init(id: .init(timelineID: "", eventID: ""),
                                                             timestamp: "10:42",
                                                             isOutgoing: true,
                                                             isEditable: false,
                                                             canBeRepliedTo: true,
                                                             isThreaded: false,
                                                             sender: .init(id: ""),
                                                             content: .init(body: "audio.ogg",
                                                                            duration: 100,
                                                                            waveform: EstimatedWaveform.mockWaveform,
                                                                            source: nil,
                                                                            contentType: nil),
                                                             replyDetails: nil),
                                         playerState: AudioPlayerState(id: .timelineItemIdentifier(.random),
                                                                       title: L10n.commonVoiceMessage,
                                                                       duration: 10,
                                                                       waveform: EstimatedWaveform.mockWaveform))
        }
        .environmentObject(viewModelWithPins.context)
    }
}
