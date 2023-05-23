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

// MARK: - TimelineStyler

struct TimelineStyler<Content: View>: View {
    @Environment(\.timelineStyle) private var style

    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content

    var body: some View {
        switch style {
        case .plain:
            TimelineItemPlainStylerView(timelineItem: timelineItem, content: content)
        case .bubbles:
            TimelineItemBubbledStylerView(timelineItem: timelineItem, content: content)
        }
    }
}

struct TimelineItemStyler_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock

    static let base = TextRoomTimelineItem(id: UUID().uuidString, timestamp: "Now", isOutgoing: true, isEditable: false, sender: .init(id: UUID().uuidString), content: .init(body: "Test"))

    static let sent: TextRoomTimelineItem = {
        var result = base
        result.properties.deliveryStatus = .sent
        return result
    }()

    static let sending: TextRoomTimelineItem = {
        var result = base
        result.properties.deliveryStatus = .sending
        return result
    }()

    static let failed: TextRoomTimelineItem = {
        var result = base
        result.properties.deliveryStatus = .sendingFailed
        return result
    }()

    static let last: TextRoomTimelineItem = {
        let id = viewModel.state.items.last?.id ?? UUID().uuidString
        let result = TextRoomTimelineItem(id: id, timestamp: "Now", isOutgoing: true, isEditable: false, sender: .init(id: UUID().uuidString), content: .init(body: "Test"))
        return result
    }()

    static var testView: some View {
        VStack {
            TextRoomTimelineView(timelineItem: sent)
            TextRoomTimelineView(timelineItem: sending)
            TextRoomTimelineView(timelineItem: base)
            TextRoomTimelineView(timelineItem: last)
            TextRoomTimelineView(timelineItem: failed)
        }
    }

    static var previews: some View {
        testView
            .environmentObject(viewModel.context)
            .environment(\.timelineStyle, .bubbles)

        testView
            .environmentObject(viewModel.context)
            .environment(\.timelineStyle, .plain)
    }
}
