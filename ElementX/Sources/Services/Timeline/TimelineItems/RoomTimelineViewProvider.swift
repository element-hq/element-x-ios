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

enum RoomTimelineViewProvider: Identifiable, Hashable {
    case text(TextRoomTimelineItem, TimelineGroupStyle)
    case separator(SeparatorRoomTimelineItem, TimelineGroupStyle)
    case image(ImageRoomTimelineItem, TimelineGroupStyle)
    case video(VideoRoomTimelineItem, TimelineGroupStyle)
    case audio(AudioRoomTimelineItem, TimelineGroupStyle)
    case file(FileRoomTimelineItem, TimelineGroupStyle)
    case emote(EmoteRoomTimelineItem, TimelineGroupStyle)
    case notice(NoticeRoomTimelineItem, TimelineGroupStyle)
    case redacted(RedactedRoomTimelineItem, TimelineGroupStyle)
    case encrypted(EncryptedRoomTimelineItem, TimelineGroupStyle)
    case readMarker(ReadMarkerRoomTimelineItem, TimelineGroupStyle)
    case paginationIndicator(PaginationIndicatorRoomTimelineItem, TimelineGroupStyle)
    case sticker(StickerRoomTimelineItem, TimelineGroupStyle)
    case unsupported(UnsupportedRoomTimelineItem, TimelineGroupStyle)
    case timelineStart(TimelineStartRoomTimelineItem, TimelineGroupStyle)
    case state(StateRoomTimelineItem, TimelineGroupStyle)
    case group(CollapsibleTimelineItem, TimelineGroupStyle)
    
    // swiftlint:disable:next cyclomatic_complexity
    init(timelineItem: RoomTimelineItemProtocol, grouping: TimelineGroupStyle) {
        switch timelineItem {
        case let item as TextRoomTimelineItem:
            self = .text(item, grouping)
        case let item as ImageRoomTimelineItem:
            self = .image(item, grouping)
        case let item as VideoRoomTimelineItem:
            self = .video(item, grouping)
        case let item as AudioRoomTimelineItem:
            self = .audio(item, grouping)
        case let item as FileRoomTimelineItem:
            self = .file(item, grouping)
        case let item as SeparatorRoomTimelineItem:
            self = .separator(item, grouping)
        case let item as NoticeRoomTimelineItem:
            self = .notice(item, grouping)
        case let item as EmoteRoomTimelineItem:
            self = .emote(item, grouping)
        case let item as RedactedRoomTimelineItem:
            self = .redacted(item, grouping)
        case let item as EncryptedRoomTimelineItem:
            self = .encrypted(item, grouping)
        case let item as ReadMarkerRoomTimelineItem:
            self = .readMarker(item, grouping)
        case let item as PaginationIndicatorRoomTimelineItem:
            self = .paginationIndicator(item, grouping)
        case let item as StickerRoomTimelineItem:
            self = .sticker(item, grouping)
        case let item as UnsupportedRoomTimelineItem:
            self = .unsupported(item, grouping)
        case let item as TimelineStartRoomTimelineItem:
            self = .timelineStart(item, grouping)
        case let item as StateRoomTimelineItem:
            self = .state(item, grouping)
        case let item as CollapsibleTimelineItem:
            self = .group(item, grouping)
        default:
            fatalError("Unknown timeline item")
        }
    }
    
    var id: String {
        switch self {
        case .text(let item as RoomTimelineItemProtocol, _),
             .separator(let item as RoomTimelineItemProtocol, _),
             .image(let item as RoomTimelineItemProtocol, _),
             .video(let item as RoomTimelineItemProtocol, _),
             .audio(let item as RoomTimelineItemProtocol, _),
             .file(let item as RoomTimelineItemProtocol, _),
             .emote(let item as RoomTimelineItemProtocol, _),
             .notice(let item as RoomTimelineItemProtocol, _),
             .redacted(let item as RoomTimelineItemProtocol, _),
             .encrypted(let item as RoomTimelineItemProtocol, _),
             .readMarker(let item as RoomTimelineItemProtocol, _),
             .paginationIndicator(let item as RoomTimelineItemProtocol, _),
             .sticker(let item as RoomTimelineItemProtocol, _),
             .unsupported(let item as RoomTimelineItemProtocol, _),
             .timelineStart(let item as RoomTimelineItemProtocol, _),
             .state(let item as RoomTimelineItemProtocol, _),
             .group(let item as RoomTimelineItemProtocol, _):
            return item.id
        }
    }
    
    /// Whether or not it is possible to send a reaction to this timeline item.
    var isReactable: Bool {
        switch self {
        case .text, .image, .video, .audio, .file, .emote, .notice, .sticker:
            return true
        case .redacted, .encrypted, .unsupported, .state: // Event based items that aren't reactable
            return false
        case .timelineStart, .separator, .readMarker, .paginationIndicator: // Virtual items are never reactable
            return false
        case .group:
            return false
        }
    }
}

extension RoomTimelineViewProvider: View {
    var body: some View {
        timelineView
            .environment(\.timelineGroupStyle, timelineStyleGrouping)
    }
    
    @ViewBuilder private var timelineView: some View {
        switch self {
        case .text(let item, _):
            TextRoomTimelineView(timelineItem: item)
        case .separator(let item, _):
            SeparatorRoomTimelineView(timelineItem: item)
        case .image(let item, _):
            ImageRoomTimelineView(timelineItem: item)
        case .video(let item, _):
            VideoRoomTimelineView(timelineItem: item)
        case .audio(let item, _):
            AudioRoomTimelineView(timelineItem: item)
        case .file(let item, _):
            FileRoomTimelineView(timelineItem: item)
        case .emote(let item, _):
            EmoteRoomTimelineView(timelineItem: item)
        case .notice(let item, _):
            NoticeRoomTimelineView(timelineItem: item)
        case .redacted(let item, _):
            RedactedRoomTimelineView(timelineItem: item)
        case .encrypted(let item, _):
            EncryptedRoomTimelineView(timelineItem: item)
        case .readMarker(let item, _):
            ReadMarkerRoomTimelineView(timelineItem: item)
        case .paginationIndicator(let item, _):
            PaginationIndicatorRoomTimelineView(timelineItem: item)
        case .sticker(let item, _):
            StickerRoomTimelineView(timelineItem: item)
        case .unsupported(let item, _):
            UnsupportedRoomTimelineView(timelineItem: item)
        case .timelineStart(let item, _):
            TimelineStartRoomTimelineView(timelineItem: item)
        case .state(let item, _):
            StateRoomTimelineView(timelineItem: item)
        case .group(let item, _):
            CollapsibleRoomTimelineView(timelineItem: item)
        }
    }
    
    private var timelineStyleGrouping: TimelineGroupStyle {
        switch self {
        case .text(_, let grouping),
             .separator(_, let grouping),
             .image(_, let grouping),
             .video(_, let grouping),
             .audio(_, let grouping),
             .file(_, let grouping),
             .emote(_, let grouping),
             .notice(_, let grouping),
             .redacted(_, let grouping),
             .encrypted(_, let grouping),
             .readMarker(_, let grouping),
             .paginationIndicator(_, let grouping),
             .sticker(_, let grouping),
             .unsupported(_, let grouping),
             .timelineStart(_, let grouping),
             .state(_, let grouping),
             .group(_, let grouping):
            return grouping
        }
    }
}
