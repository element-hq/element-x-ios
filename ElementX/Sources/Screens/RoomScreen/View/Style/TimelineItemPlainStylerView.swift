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
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content
    
    @State private var showItemActionMenu = false

    var body: some View {
        VStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 4) {
                header

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        contentWithReply

                        Spacer()
                    }
                    supplementaryViews
                }
            }
            TimelineItemStatusView(timelineItem: timelineItem)
                .environmentObject(context)
        }
    }
    
    @ViewBuilder
    var contentWithReply: some View {
        VStack(alignment: .leading) {
            if let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol,
               let replyDetails = messageTimelineItem.replyDetails {
                HStack(spacing: 4.0) {
                    Rectangle()
                        .foregroundColor(.global.melon)
                        .frame(width: 4.0)
                    TimelineReplyView(placement: .timeline,
                                      timelineItemReplyDetails: replyDetails)
                }
            }
            
            content()
        }
        .onTapGesture(count: 2) {
            context.send(viewAction: .displayEmojiPicker(itemID: timelineItem.id))
        }
        .onTapGesture {
            context.send(viewAction: .itemTapped(id: timelineItem.id))
        }
        // We need a tap gesture before this long one so that it doesn't
        // steal away the gestures from the scroll view
        .longPressWithFeedback {
            context.send(viewAction: .timelineItemMenu(itemID: timelineItem.id))
        }
        .swipeRightAction {
            Image(systemName: "arrowshape.turn.up.left")
        } shouldStartAction: {
            context.viewState.timelineItemMenuActionProvider?(timelineItem.id)?.canReply ?? false
        } action: {
            context.send(viewAction: .timelineItemMenuAction(itemID: timelineItem.id, action: .reply))
        }
    }
    
    @ViewBuilder
    private var header: some View {
        if shouldShowSenderDetails {
            HStack {
                HStack {
                    TimelineSenderAvatarView(timelineItem: timelineItem)
                    Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                        .font(.subheadline)
                        .foregroundColor(.compound.textPrimary)
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
        }
    }
    
    @ViewBuilder
    private var supplementaryViews: some View {
        VStack {
            if timelineItem.properties.isEdited {
                Text(L10n.commonEditedSuffix)
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
            }
            
            if !timelineItem.properties.reactions.isEmpty {
                TimelineReactionsView(itemID: timelineItem.id,
                                      reactions: timelineItem.properties.reactions,
                                      collapsed: context.reactionsCollapsedBinding(for: timelineItem.id))
                    // Workaround to stop the message long press stealing the touch from the reaction buttons
                    .onTapGesture { }
            }
        }
    }
    
    private var shouldShowSenderDetails: Bool {
        timelineGroupStyle.shouldShowSenderDetails
    }
}

struct TimelineItemPlainStylerView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock

    static var previews: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(1..<MockRoomTimelineController().timelineItems.count, id: \.self) { index in
                let item = MockRoomTimelineController().timelineItems[index]
                RoomTimelineItemView(viewModel: .init(item: item, groupStyle: .single))
                    .padding(TimelineStyle.plain.rowInsets) // Insets added in the table view cells
            }
        }
        .environment(\.timelineStyle, .plain)
        .previewLayout(.sizeThatFits)
        .environmentObject(viewModel.context)
    }
}
