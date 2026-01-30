//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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

    private var isDirectOneToOneRoom: Bool {
        context.viewState.isDirectOneToOneRoom
    }

    private var isFocussed: Bool {
        focussedEventID != nil && timelineItem.id.eventID == focussedEventID
    }

    private var isPinned: Bool {
        guard context.viewState.timelineKind != .pinned,
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
        guard !timelineItem.isOutgoing, !isDirectOneToOneRoom else { return 0 }
        return 8
    }
    
    var body: some View {
        ZStack(alignment: .trailingFirstTextBaseline) {
            VStack(alignment: alignment, spacing: -12) {
                if !timelineItem.isOutgoing, !isDirectOneToOneRoom {
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
                context.send(viewAction: .tappedOnSenderDetails(sender: timelineItem.sender))
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
            if context.viewState.timelineKind != .pinned,
               !timelineItem.properties.reactions.isEmpty {
                TimelineReactionsView(context: context,
                                      itemID: timelineItem.id,
                                      reactions: timelineItem.properties.reactions,
                                      isLayoutRTL: timelineItem.isOutgoing)
                    // Workaround to stop the message long press stealing the touch from the reaction buttons
                    .onTapGesture { }
            }
            
            if context.viewState.areThreadsEnabled,
               !context.viewState.timelineKind.isThread,
               let threadSummary = timelineItem.properties.threadSummary {
                TimelineThreadSummaryView(threadSummary: threadSummary) {
                    context.send(viewAction: .displayThread(itemID: timelineItem.id))
                }
                .padding(5)
            }
        }
    }
    
    var messageBubbleWithActions: some View {
        messageBubble
            .onTapGesture {
                // We need a tap gesture before the long press gesture below, otherwise something
                // on iOS 17 hijacks the long press and you can't bring up the context menu. This
                // is no longer an issue on iOS 18. Note: it's fine for this to be empty, we handle
                // specific taps within the timeline views themselves.
            }
            .longPressWithFeedback {
                context.send(viewAction: .displayTimelineItemMenu(itemID: timelineItem.id))
            }
            .swipeRightAction {
                SwipeToReplyView(timelineItem: timelineItem)
            } shouldStartAction: {
                timelineItem.canBeRepliedTo
            } action: {
                context.send(viewAction: .handleTimelineItemMenuAction(itemID: timelineItem.id,
                                                                       action: .reply(isThread: timelineItem.properties.isThreaded)))
            }
            .contextMenu {
                let provider = TimelineItemMenuActionProvider(timelineItem: timelineItem,
                                                              canCurrentUserSendMessage: context.viewState.canCurrentUserSendMessage,
                                                              canCurrentUserRedactSelf: context.viewState.canCurrentUserRedactSelf,
                                                              canCurrentUserRedactOthers: context.viewState.canCurrentUserRedactOthers,
                                                              canCurrentUserPin: context.viewState.canCurrentUserPin,
                                                              pinnedEventIDs: context.viewState.pinnedEventIDs,
                                                              isDM: context.viewState.isDirectOneToOneRoom,
                                                              isViewSourceEnabled: context.viewState.isViewSourceEnabled,
                                                              areThreadsEnabled: context.viewState.areThreadsEnabled,
                                                              timelineKind: context.viewState.timelineKind,
                                                              emojiProvider: context.viewState.emojiProvider)
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
            .bubbleBackground(isOutgoing: timelineItem.isOutgoing,
                              insets: timelineItem.bubbleInsets,
                              color: timelineItem.bubbleBackgroundColor)
    }
    
    var contentWithReply: some View {
        TimelineBubbleLayout(spacing: 8) {
            if !context.viewState.timelineKind.isThread, timelineItem.properties.isThreaded {
                ThreadDecorator()
                    .padding(.leading, 4)
                    .timelineBubbleLayoutSize(.natural)
            }
            
            if let replyDetails = timelineItem.properties.replyDetails {
                // The rendered reply bubble with a greedy width. The custom layout prevents
                // the infinite width from increasing the overall width of the view.
                
                TimelineReplyView(placement: .timeline, timelineItemReplyDetails: replyDetails)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(4.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.compound.bgCanvasDefault)
                    .cornerRadius(8)
                    .timelineBubbleLayoutSize(.bubbleWidth(mode: .rendering))
                    .onTapGesture {
                        if context.viewState.timelineKind != .pinned {
                            context.send(viewAction: .focusOnEventID(replyDetails.eventID))
                        }
                    }
                
                // Add a fixed width reply bubble that is used for layout calculations but won't be rendered.
                TimelineReplyView(placement: .timeline, timelineItemReplyDetails: replyDetails)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(4.0)
                    .timelineBubbleLayoutSize(.bubbleWidth(mode: .layout))
                    .hidden()
            }
            
            content()
                .timelineBubbleLayoutSize(.natural)
                .cornerRadius(timelineItem.contentCornerRadius)
        }
    }
    
    private var messageBubbleTopPadding: CGFloat {
        guard timelineItem.isOutgoing || isDirectOneToOneRoom else { return 0 }
        return timelineGroupStyle == .single || timelineGroupStyle == .first ? 8 : 0
    }
    
    private var alignment: HorizontalAlignment {
        timelineItem.isOutgoing ? .trailing : .leading
    }
    
    private var shouldShowSenderDetails: Bool {
        timelineGroupStyle.shouldShowSenderDetails
    }
}

private extension EventBasedTimelineItemProtocol {
    var bubbleBackgroundColor: Color? {
        let defaultColor: Color = isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming
        
        switch self {
        case is ImageRoomTimelineItem, is VideoRoomTimelineItem:
            // In case a reply detail or a thread decorator is present we render the color and the padding
            return properties.replyDetails != nil || properties.isThreaded || hasMediaCaption ? defaultColor : nil
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
        // In case a reply detail or a thread decorator is present we render the color and the padding
        case is ImageRoomTimelineItem, is VideoRoomTimelineItem:
            return properties.replyDetails != nil || properties.isThreaded || hasMediaCaption ? defaultInsets : .zero
        case let locationTimelineItem as LocationRoomTimelineItem:
            return locationTimelineItem.content.geoURI == nil ||
                properties.replyDetails != nil ||
                properties.isThreaded ? defaultInsets : .zero
        default:
            return defaultInsets
        }
    }
    
    var contentCornerRadius: CGFloat {
        switch self {
        case is ImageRoomTimelineItem, is VideoRoomTimelineItem, is LocationRoomTimelineItem:
            return properties.replyDetails != nil || properties.isThreaded ? 8 : .zero
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
            .accessibilityLabel(L10n.commonPinned)
    }
}

private extension View {
    func pinnedIndicator(isPinned: Bool, isOutgoing: Bool) -> some View {
        modifier(PinnedIndicatorViewModifier(isPinned: isPinned, isOutgoing: isOutgoing))
    }
}

private extension TimelineItemKeyForwarder {
    static var test: TimelineItemKeyForwarder {
        TimelineItemKeyForwarder(id: "@alice:matrix.org", displayName: "alice")
    }
}

// MARK: - Previews

struct TimelineItemBubbledStylerView_Previews: PreviewProvider, TestablePreview {
    static let viewModel: TimelineViewModel = {
        let appSettings = AppSettings()
        appSettings.enableKeyShareOnInvite = true
        appSettings.threadsEnabled = true
        
        let roomProxy = JoinedRoomProxyMock(.init())
        return TimelineViewModel(roomProxy: roomProxy,
                                 focussedEventID: nil,
                                 timelineController: MockTimelineController(),
                                 userSession: UserSessionMock(.init()),
                                 mediaPlayerProvider: MediaPlayerProviderMock(),
                                 userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                 appMediator: AppMediatorMock.default,
                                 appSettings: appSettings,
                                 analyticsService: ServiceLocator.shared.analytics,
                                 emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                 linkMetadataProvider: LinkMetadataProvider(),
                                 timelineControllerFactory: TimelineControllerFactoryMock(.init()))
    }()
    
    static let viewModelWithPins: TimelineViewModel = {
        let appSettings = AppSettings()
        appSettings.threadsEnabled = true
        
        let roomProxy = JoinedRoomProxyMock(.init(name: "Preview Room", pinnedEventIDs: ["pinned"]))
        return TimelineViewModel(roomProxy: roomProxy,
                                 focussedEventID: nil,
                                 timelineController: MockTimelineController(),
                                 userSession: UserSessionMock(.init()),
                                 mediaPlayerProvider: MediaPlayerProviderMock(),
                                 userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                 appMediator: AppMediatorMock.default,
                                 appSettings: appSettings,
                                 analyticsService: ServiceLocator.shared.analytics,
                                 emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                 linkMetadataProvider: LinkMetadataProvider(),
                                 timelineControllerFactory: TimelineControllerFactoryMock(.init()))
    }()

    static var previews: some View {
        mockTimeline
            .previewDisplayName("Mock Timeline")
            .previewLayout(.fixed(width: 390, height: 900))
            .padding(.bottom, 20)
        mockTimeline
            .environment(\.layoutDirection, .rightToLeft)
            .previewDisplayName("Mock Timeline RTL")
            .previewLayout(.fixed(width: 390, height: 900))
            .padding(.bottom, 20)
        replies
            .previewDisplayName("Replies")
        threadDecorator
            .previewDisplayName("Thread decorator")
            .previewLayout(.fixed(width: 390, height: 1700))
            .padding(.bottom, 20)
        threadSummary
            .previewDisplayName("Thread summary")
            .previewLayout(.fixed(width: 390, height: 1700))
            .padding(.bottom, 20)
        encryptionAuthenticity
            .previewDisplayName("Encryption Indicators")
        encryptionForwarder
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Encryption Forwarder Info")
        pinned
            .previewDisplayName("Pinned messages")
            .previewLayout(.fixed(width: 390, height: 1150))
            .padding(.bottom, 20)
    }
    
    static var mockTimeline: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.state.timelineState.itemViewStates) { viewState in
                    RoomTimelineItemView(viewState: viewState)
                }
            }
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
    }
    
    static var replies: some View {
        VStack(spacing: 0) {
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .randomEvent,
                                                                             timestamp: .mock,
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "A long message that should be on multiple lines."),
                                                                             properties: .init(replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                                                                     eventID: "123",
                                                                                                                     eventContent: .message(.text(.init(body: "Short")))))),
                                                  groupStyle: .single))
            
            let properties = RoomTimelineItemProperties(replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                              eventID: "123",
                                                                              eventContent: .message(.text(.init(body: "A long message that should be on more than 2 lines and so will be clipped by the layout.")))))
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .randomEvent,
                                                                             timestamp: .mock,
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "Short message"),
                                                                             properties: properties),
                                                  groupStyle: .single))
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
    }
    
    static var threadDecorator: some View {
        ScrollView {
            MockTimelineContent(isThreaded: true)
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
    }
    
    static var threadSummary: some View {
        ScrollView {
            let threadSummary = TimelineItemThreadSummary.loaded(senderID: "@alice:matrix.org",
                                                                 sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                                 latestEventContent: .message(.text(.init(body: "This is a very long, multi-lined, threaded message"))),
                                                                 numberOfReplies: 42)
            
            MockTimelineContent(threadSummary: threadSummary)
        }
        .environmentObject(viewModelWithPins.context)
        .environment(\.timelineContext, viewModel.context)
    }
      
    static var pinned: some View {
        ScrollView {
            MockTimelineContent(isPinned: true)
        }
        .environmentObject(viewModelWithPins.context)
        .environment(\.timelineContext, viewModel.context)
    }
    
    static var encryptionAuthenticity: some View {
        VStack(spacing: 0) {
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .randomEvent,
                                                                             timestamp: .mock,
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "A long message that should be on multiple lines."),
                                                                             properties: RoomTimelineItemProperties(encryptionAuthenticity: .unsignedDevice(color: .red))),
                                                  groupStyle: .single))
            
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .randomEvent,
                                                                             timestamp: .mock,
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "A long message that should be on multiple lines."),
                                                                             properties: RoomTimelineItemProperties(isEdited: true,
                                                                                                                    encryptionAuthenticity: .unsignedDevice(color: .red))),
                                                  groupStyle: .single))
            
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .randomEvent,
                                                                             timestamp: .mock,
                                                                             isOutgoing: false,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "Short message"),
                                                                             properties: RoomTimelineItemProperties(encryptionAuthenticity: .unknownDevice(color: .red))),
                                                  groupStyle: .first))
            
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .randomEvent,
                                                                             timestamp: .mock,
                                                                             isOutgoing: false,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "Message goes Here"),
                                                                             properties: RoomTimelineItemProperties(encryptionAuthenticity: .notGuaranteed(color: .gray))),
                                                  groupStyle: .last))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .randomEvent,
                                                                      timestamp: .mock,
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(filename: "other.png",
                                                                                     imageInfo: .mockImage,
                                                                                     thumbnailInfo: nil),
                                                                      
                                                                      properties: RoomTimelineItemProperties(encryptionAuthenticity: .notGuaranteed(color: .gray))))
            
            VoiceMessageRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                             timestamp: .mock,
                                                             isOutgoing: true,
                                                             isEditable: false,
                                                             canBeRepliedTo: true,
                                                             sender: .init(id: ""),
                                                             content: .init(filename: "audio.ogg",
                                                                            duration: 100,
                                                                            waveform: EstimatedWaveform.mockWaveform,
                                                                            source: nil,
                                                                            fileSize: nil,
                                                                            contentType: nil),
                                                             properties: RoomTimelineItemProperties(isThreaded: true,
                                                                                                    encryptionAuthenticity: .notGuaranteed(color: .gray))),
                                         playerState: AudioPlayerState(id: .timelineItemIdentifier(.randomEvent),
                                                                       title: L10n.commonVoiceMessage,
                                                                       duration: 10,
                                                                       waveform: EstimatedWaveform.mockWaveform))
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
    }
    
    static var encryptionForwarder: some View {
        VStack(spacing: 0) {
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .randomEvent,
                                                                             timestamp: .mock,
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "A long message that should be on multiple lines."),
                                                                             properties: RoomTimelineItemProperties(isEdited: true, encryptionForwarder: .test)),
                                                  groupStyle: .single))
            
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .randomEvent,
                                                                             timestamp: .mock,
                                                                             isOutgoing: true,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "A long message that should be on multiple lines."),
                                                                             properties: RoomTimelineItemProperties(encryptionForwarder: .test)),
                                                  groupStyle: .single))
            
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .randomEvent,
                                                                             timestamp: .mock,
                                                                             isOutgoing: false,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "Short message"),
                                                                             properties: RoomTimelineItemProperties(encryptionForwarder: .test)),
                                                  groupStyle: .first))
            
            RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: .randomEvent,
                                                                             timestamp: .mock,
                                                                             isOutgoing: false,
                                                                             isEditable: false,
                                                                             canBeRepliedTo: true,
                                                                             sender: .init(id: "whoever"),
                                                                             content: .init(body: "Message goes Here"),
                                                                             properties: RoomTimelineItemProperties(encryptionForwarder: .test)),
                                                  groupStyle: .last))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .randomEvent,
                                                                      timestamp: .mock,
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(filename: "other.png",
                                                                                     imageInfo: .mockImage,
                                                                                     thumbnailInfo: nil),
                                                                      properties: RoomTimelineItemProperties(encryptionForwarder: .test)))
            
            VoiceMessageRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                             timestamp: .mock,
                                                             isOutgoing: true,
                                                             isEditable: false,
                                                             canBeRepliedTo: true,
                                                             sender: .init(id: ""),
                                                             content: .init(filename: "audio.ogg",
                                                                            duration: 100,
                                                                            waveform: EstimatedWaveform.mockWaveform,
                                                                            source: nil,
                                                                            fileSize: nil,
                                                                            contentType: nil),
                                                             properties: RoomTimelineItemProperties(isThreaded: true,
                                                                                                    encryptionForwarder: .test)),
                                         playerState: AudioPlayerState(id: .timelineItemIdentifier(.randomEvent),
                                                                       title: L10n.commonVoiceMessage,
                                                                       duration: 10,
                                                                       waveform: EstimatedWaveform.mockWaveform))
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
    }
}

private struct MockTimelineContent: View {
    var isThreaded = false
    var isPinned = false
    var threadSummary: TimelineItemThreadSummary?
    
    var body: some View {
        RoomTimelineItemView(viewState: .init(item: TextRoomTimelineItem(id: makeItemIdentifier(),
                                                                         timestamp: .mock,
                                                                         isOutgoing: true,
                                                                         isEditable: false,
                                                                         canBeRepliedTo: true,
                                                                         sender: .init(id: "whoever"),
                                                                         content: .init(body: "A long message that should be on multiple lines."),
                                                                         properties: .init(replyDetails: replyDetails,
                                                                                           isThreaded: isThreaded,
                                                                                           threadSummary: threadSummary)),
                                              groupStyle: .single))

        AudioRoomTimelineView(timelineItem: .init(id: makeItemIdentifier(),
                                                  timestamp: .mock,
                                                  isOutgoing: true,
                                                  isEditable: false,
                                                  canBeRepliedTo: true,
                                                  sender: .init(id: ""),
                                                  content: .init(filename: "audio.ogg",
                                                                 duration: 100,
                                                                 waveform: EstimatedWaveform.mockWaveform,
                                                                 source: nil,
                                                                 fileSize: nil,
                                                                 contentType: nil),
                                                  properties: .init(replyDetails: replyDetails,
                                                                    isThreaded: isThreaded,
                                                                    threadSummary: threadSummary)))
        
        FileRoomTimelineView(timelineItem: .init(id: makeItemIdentifier(),
                                                 timestamp: .mock,
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 canBeRepliedTo: true,
                                                 sender: .init(id: ""),
                                                 content: .init(filename: "file.txt",
                                                                caption: "File",
                                                                source: nil,
                                                                fileSize: nil,
                                                                thumbnailSource: nil,
                                                                contentType: nil),
                                                 properties: .init(replyDetails: replyDetails,
                                                                   isThreaded: isThreaded,
                                                                   threadSummary: threadSummary)))
        
        ImageRoomTimelineView(timelineItem: .init(id: makeItemIdentifier(),
                                                  timestamp: .mock,
                                                  isOutgoing: true,
                                                  isEditable: true,
                                                  canBeRepliedTo: true,
                                                  sender: .init(id: ""),
                                                  content: .init(filename: "image.jpg",
                                                                 imageInfo: .mockImage,
                                                                 thumbnailInfo: nil),
                                                  properties: .init(replyDetails: replyDetails,
                                                                    isThreaded: isThreaded,
                                                                    threadSummary: threadSummary)))
        
        LocationRoomTimelineView(timelineItem: .init(id: makeItemIdentifier(),
                                                     timestamp: .mock,
                                                     isOutgoing: false,
                                                     isEditable: false,
                                                     canBeRepliedTo: true,
                                                     sender: .init(id: "Bob"),
                                                     content: .init(body: "Fallback geo uri description",
                                                                    geoURI: .init(latitude: 41.902782,
                                                                                  longitude: 12.496366),
                                                                    description: "Location description description description description description description description description"),
                                                     properties: .init(replyDetails: replyDetails,
                                                                       isThreaded: isThreaded,
                                                                       threadSummary: threadSummary)))
        
        LocationRoomTimelineView(timelineItem: .init(id: makeItemIdentifier(),
                                                     timestamp: .mock,
                                                     isOutgoing: false,
                                                     isEditable: false,
                                                     canBeRepliedTo: true,
                                                     sender: .init(id: "Bob"),
                                                     content: .init(body: "Fallback geo uri description",
                                                                    geoURI: .init(latitude: 41.902782, longitude: 12.496366), description: nil),
                                                     properties: .init(replyDetails: replyDetails,
                                                                       isThreaded: isThreaded,
                                                                       threadSummary: threadSummary)))
        
        VoiceMessageRoomTimelineView(timelineItem: .init(id: makeItemIdentifier(),
                                                         timestamp: .mock,
                                                         isOutgoing: true,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: ""),
                                                         content: .init(filename: "audio.ogg",
                                                                        duration: 100,
                                                                        waveform: EstimatedWaveform.mockWaveform,
                                                                        source: nil,
                                                                        fileSize: nil,
                                                                        contentType: nil),
                                                         properties: .init(replyDetails: replyDetails,
                                                                           isThreaded: isThreaded,
                                                                           threadSummary: threadSummary)),
                                     playerState: AudioPlayerState(id: .timelineItemIdentifier(.randomEvent),
                                                                   title: L10n.commonVoiceMessage,
                                                                   duration: 10,
                                                                   waveform: EstimatedWaveform.mockWaveform))
    }
    
    func makeItemIdentifier() -> TimelineItemIdentifier {
        isPinned ? .event(uniqueID: .init(""), eventOrTransactionID: .eventID("pinned")) : .randomEvent
    }
    
    var replyDetails: TimelineItemReplyDetails? {
        isThreaded ? .loaded(sender: .init(id: "", displayName: "Alice"),
                             eventID: "123",
                             eventContent: .message(.text(.init(body: "Short")))) : nil
    }
}
