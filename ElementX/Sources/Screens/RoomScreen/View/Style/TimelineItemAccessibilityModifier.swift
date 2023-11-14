//
// Copyright 2023 New Vector Ltd
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

private struct TimelineItemAccessibilityModifier: ViewModifier {
    let timelineItem: RoomTimelineItemProtocol
    let action: () -> Void
    
    @ViewBuilder
    func body(content: Content) -> some View {
        switch timelineItem {
        case is PollRoomTimelineItem, is VoiceMessageRoomTimelineItem:
            content
                .accessibilityActions {
                    Button(L10n.commonMessageActions) {
                        action()
                    }
                }
        case let timelineItem as EventBasedTimelineItemProtocol:
            content
                .accessibilityRepresentation {
                    VStack(spacing: 8) {
                        Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                        content
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityActions {
                    Button(L10n.commonMessageActions) {
                        action()
                    }
                }
        default:
            content
                .accessibilityElement(children: .combine)
        }
    }
}

extension View {
    func timelineItemAccessibility(_ timelineItem: RoomTimelineItemProtocol, action: @escaping () -> Void) -> some View {
        modifier(TimelineItemAccessibilityModifier(timelineItem: timelineItem, action: action))
    }
}
