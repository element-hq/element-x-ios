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

struct RoomTimelineViewFactory: RoomTimelineViewFactoryProtocol {
    // swiftlint:disable:next cyclomatic_complexity
    func buildTimelineViewFor(timelineItem: RoomTimelineItemProtocol) -> RoomTimelineViewProvider {
        switch timelineItem {
        case let item as TextRoomTimelineItem:
            return .text(item)
        case let item as ImageRoomTimelineItem:
            return .image(item)
        case let item as VideoRoomTimelineItem:
            return .video(item)
        case let item as FileRoomTimelineItem:
            return .file(item)
        case let item as SeparatorRoomTimelineItem:
            return .separator(item)
        case let item as NoticeRoomTimelineItem:
            return .notice(item)
        case let item as EmoteRoomTimelineItem:
            return .emote(item)
        case let item as RedactedRoomTimelineItem:
            return .redacted(item)
        case let item as EncryptedRoomTimelineItem:
            return .encrypted(item)
        case let item as ReadMarkerRoomTimelineItem:
            return .readMarker(item)
        case let item as PaginationIndicatorRoomTimelineItem:
            return .paginationIndicator(item)
        case let item as StickerRoomTimelineItem:
            return .sticker(item)
        case let item as UnsupportedRoomTimelineItem:
            return .unsupported(item)
        case let item as TimelineStartRoomTimelineItem:
            return .timelineStart(item)
        case let item as StateRoomTimelineItem:
            return .state(item)
        default:
            fatalError("Unknown timeline item")
        }
    }
}
