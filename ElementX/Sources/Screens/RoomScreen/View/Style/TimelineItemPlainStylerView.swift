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

struct TimelineItemPlainStylerView<Content: View>: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    @Environment(\.timelineGroupStyle) private var timelineGroupStyle
    
    let timelineItem: EventBasedTimelineItemProtocol
    let adjustedDeliveryStatus: TimelineItemDeliveryStatus?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                header

                VStack(alignment: .leading, spacing: 4) {
                    contentWithReply
                    supplementaryViews
                }
            }
            TimelineItemStatusView(timelineItem: timelineItem, adjustedDeliveryStatus: adjustedDeliveryStatus)
                .environmentObject(context)
        }
    }
    
    @ViewBuilder
    var contentWithReply: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol {
                if messageTimelineItem.isThreaded {
                    ThreadDecorator()
                }
                if let replyDetails = messageTimelineItem.replyDetails {
                    HStack(spacing: 4.0) {
                        Rectangle()
                            .foregroundColor(.compound.iconTertiary)
                            .frame(width: 4.0)
                        TimelineReplyView(placement: .timeline, timelineItemReplyDetails: replyDetails)
                    }
                }
            }
            
            content()
                .layoutPriority(1)
                .timelineItemAccessibility(timelineItem) {
                    context.send(viewAction: .timelineItemMenu(itemID: timelineItem.id))
                }
        }
        .onTapGesture(count: 2) {
            context.send(viewAction: .displayEmojiPicker(itemID: timelineItem.id))
        }
        .onTapGesture {
            context.send(viewAction: .itemTapped(itemID: timelineItem.id))
        }
        // We need a tap gesture before this long one so that it doesn't
        // steal away the gestures from the scroll view
        .longPressWithFeedback {
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
    }
    
    @ViewBuilder
    private var header: some View {
        if shouldShowSenderDetails {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    TimelineSenderAvatarView(timelineItem: timelineItem)
                    Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                        .font(.subheadline)
                        .foregroundColor(.compound.decorativeColor(for: timelineItem.sender.id).text)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                .onTapGesture {
                    context.send(viewAction: .tappedOnUser(userID: timelineItem.sender.id))
                }
                Spacer()
                Text(timelineItem.timestamp)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodyXS)
            }
            .padding(.top, 16)
            // sender info are read inside the `TimelineAccessibilityModifier`
            .accessibilityHidden(true)
        }
    }
    
    @ViewBuilder
    private var supplementaryViews: some View {
        VStack(spacing: 4) {
            if timelineItem.properties.isEdited {
                Text(L10n.commonEditedSuffix)
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
            }
            
            if !timelineItem.properties.reactions.isEmpty {
                TimelineReactionsView(context: context,
                                      itemID: timelineItem.id,
                                      reactions: timelineItem.properties.reactions)
                    // Workaround to stop the message long press stealing the touch from the reaction buttons
                    .onTapGesture { }
            }
        }
    }
    
    private var shouldShowSenderDetails: Bool {
        timelineGroupStyle.shouldShowSenderDetails
    }
}

struct TimelineItemPlainStylerView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomScreenViewModel.mock
    
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
                                                                     waveform: nil,
                                                                     source: nil,
                                                                     contentType: nil),
                                                      replyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
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
                                                                                   eventContent: .message(.text(.init(body: "Short"))))),
                                         playerState: AudioPlayerState(id: .timelineItemIdentifier(.init(timelineID: "")), duration: 10, waveform: EstimatedWaveform.mockWaveform))
        }
        .environmentObject(viewModel.context)
    }
    
    static var previews: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(1..<MockRoomTimelineController().timelineItems.count, id: \.self) { index in
                let item = MockRoomTimelineController().timelineItems[index]
                RoomTimelineItemView(viewState: .init(item: item, groupStyle: .single))
                    .padding(TimelineStyle.plain.rowInsets) // Insets added in the table view cells
            }
        }
        .environment(\.timelineStyle, .plain)
        .environmentObject(viewModel.context)
        .previewLayout(.sizeThatFits)
        
        threads
            .padding()
            .environment(\.timelineStyle, .plain)
            .previewDisplayName("Threads")
    }
}
