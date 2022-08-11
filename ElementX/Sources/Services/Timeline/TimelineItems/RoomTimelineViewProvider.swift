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

enum RoomTimelineViewProvider: Identifiable, Equatable {
    case text(TextRoomTimelineItem)
    case separator(SeparatorRoomTimelineItem)
    case image(ImageRoomTimelineItem)
    case emote(EmoteRoomTimelineItem)
    case notice(NoticeRoomTimelineItem)
    
    var id: String {
        switch self {
        case .text(let item):
            return item.id
        case .separator(let item):
            return item.id
        case .image(let item):
            return item.id
        case .emote(let item):
            return item.id
        case .notice(let item):
            return item.id
        }
    }
}

extension RoomTimelineViewProvider: View {
    @ViewBuilder var body: some View {
        switch self {
        case .text(let item):
            TextRoomTimelineView(timelineItem: item)
        case .separator(let item):
            SeparatorRoomTimelineView(timelineItem: item)
        case .image(let item):
            ImageRoomTimelineView(timelineItem: item)
        case .emote(let item):
            EmoteRoomTimelineView(timelineItem: item)
        case .notice(let item):
            NoticeRoomTimelineView(timelineItem: item)
        }
    }
}
