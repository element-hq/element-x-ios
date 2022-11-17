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
    
    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric private var senderNameVerticalPadding = 3

    var body: some View {
        VStack(alignment: alignment, spacing: -12) {
            if !timelineItem.isOutgoing {
                header
                    .zIndex(1)
            }
            VStack(alignment: alignment) {
                if timelineItem.isOutgoing {
                    HStack {
                        Spacer()
                        styledContentWithReactions
                        if timelineItem.isOutgoing {
                            TimelineDeliveryStatusView(deliveryStatus: timelineItem.properties.deliveryStatus)
                                .padding(.top, 6)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.leading, 16)
                } else {
                    styledContentWithReactions
                        .padding(.leading, 24)
                        .padding(.trailing, 24)
                }
            }
        }
    }
    
    @ViewBuilder
    private var header: some View {
        if timelineItem.shouldShowSenderDetails {
            VStack {
                Spacer()
                    .frame(height: 8)
                HStack(alignment: .top, spacing: 4) {
                    TimelineSenderAvatarView(timelineItem: timelineItem)
                        .accessibilityHidden(true)
                    Text(timelineItem.senderDisplayName ?? timelineItem.senderId)
                        .font(.element.footnoteBold)
                        .foregroundColor(.element.primaryContent)
                        .lineLimit(1)
                        .padding(.vertical, senderNameVerticalPadding)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
    
    private var styledContentWithReactions: some View {
        // Figma has a spacing of -4 but it doesn't take into account
        // the centre aligned stroke width so we use -5 here
        VStack(alignment: alignment, spacing: -5) {
            styledContent
                .accessibilityElement(children: .combine)
            
            if !timelineItem.properties.reactions.isEmpty {
                TimelineReactionsView(reactions: timelineItem.properties.reactions,
                                      alignment: .leading) { key in
                    context.send(viewAction: .sendReaction(key: key, eventID: timelineItem.id))
                }
                .padding(.horizontal, 12)
            }
        }
    }

    @ViewBuilder
    var styledContent: some View {
        if timelineItem.isOutgoing {
            styledContentOutgoing
        } else {
            styledContentIncoming
        }
    }

    @ViewBuilder
    var styledContentOutgoing: some View {
        let topPadding: CGFloat? = timelineItem.inGroupState == .single || timelineItem.inGroupState == .beginning ? 8 : 0
        
        if shouldAvoidBubbling {
            content()
                .cornerRadius(12, corners: timelineItem.roundedCorners)
                .padding(.top, topPadding)
        } else {
            VStack(alignment: .trailing, spacing: 4) {
                content()

                if timelineItem.properties.isEdited {
                    Text(ElementL10n.editedSuffix)
                        .font(.element.caption2)
                        .foregroundColor(.element.tertiaryContent)
                }
            }
            .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            .background(Color.element.systemGray5)
            .cornerRadius(12, corners: timelineItem.roundedCorners)
            .padding(.top, topPadding)
        }
    }

    @ViewBuilder
    var styledContentIncoming: some View {
        if shouldAvoidBubbling {
            content()
                .cornerRadius(12, corners: timelineItem.roundedCorners)
        } else {
            VStack(alignment: .trailing, spacing: 4) {
                content()

                if timelineItem.properties.isEdited {
                    Text(ElementL10n.editedSuffix)
                        .font(.element.caption2)
                        .foregroundColor(.element.tertiaryContent)
                }
            }
            .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            .background(Color.element.systemGray6)
            .cornerRadius(12, corners: timelineItem.roundedCorners)
        }
    }

    private var shouldAvoidBubbling: Bool {
        timelineItem is ImageRoomTimelineItem || timelineItem is VideoRoomTimelineItem
    }
    
    private var alignment: HorizontalAlignment {
        timelineItem.isOutgoing ? .trailing : .leading
    }
}

struct TimelineItemBubbledStylerView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }

    @ViewBuilder
    static var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(1..<MockRoomTimelineController().timelineItems.count, id: \.self) { index in
                let item = MockRoomTimelineController().timelineItems[index]
                RoomTimelineViewFactory().buildTimelineViewFor(timelineItem: item)
            }
        }
        .timelineStyle(.bubbles)
        .padding(.horizontal, 8)
        .previewLayout(.sizeThatFits)
    }
}
