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

import Foundation

final class RoomTimelineItemViewModel: Identifiable, Equatable, ObservableObject {
    static func == (lhs: RoomTimelineItemViewModel, rhs: RoomTimelineItemViewModel) -> Bool {
        lhs.type == rhs.type && lhs.groupStyle == rhs.groupStyle
    }

    @Published var type: RoomTimelineItemType
    @Published var groupStyle: TimelineGroupStyle

    var id: String {
        type.id.timelineID
    }

    convenience init(item: RoomTimelineItemProtocol, groupStyle: TimelineGroupStyle) {
        self.init(type: .init(item: item), groupStyle: groupStyle)
    }

    init(type: RoomTimelineItemType, groupStyle: TimelineGroupStyle) {
        self.type = type
        self.groupStyle = groupStyle
    }

    var isReactable: Bool {
        type.isReactable
    }
}

enum RoomTimelineItemType: Equatable {
    case text(TextRoomTimelineItem)
    case separator(SeparatorRoomTimelineItem)
    case image(ImageRoomTimelineItem)
    case video(VideoRoomTimelineItem)
    case audio(AudioRoomTimelineItem)
    case file(FileRoomTimelineItem)
    case emote(EmoteRoomTimelineItem)
    case notice(NoticeRoomTimelineItem)
    case redacted(RedactedRoomTimelineItem)
    case encrypted(EncryptedRoomTimelineItem)
    case readMarker(ReadMarkerRoomTimelineItem)
    case paginationIndicator(PaginationIndicatorRoomTimelineItem)
    case sticker(StickerRoomTimelineItem)
    case unsupported(UnsupportedRoomTimelineItem)
    case timelineStart(TimelineStartRoomTimelineItem)
    case encryptedHistory(EncryptedHistoryRoomTimelineItem)
    case state(StateRoomTimelineItem)
    case group(CollapsibleTimelineItem)
    case location(LocationRoomTimelineItem)

    // swiftlint:disable:next cyclomatic_complexity
    init(item: RoomTimelineItemProtocol) {
        switch item {
        case let item as TextRoomTimelineItem:
            self = .text(item)
        case let item as ImageRoomTimelineItem:
            self = .image(item)
        case let item as VideoRoomTimelineItem:
            self = .video(item)
        case let item as AudioRoomTimelineItem:
            self = .audio(item)
        case let item as FileRoomTimelineItem:
            self = .file(item)
        case let item as SeparatorRoomTimelineItem:
            self = .separator(item)
        case let item as NoticeRoomTimelineItem:
            self = .notice(item)
        case let item as EmoteRoomTimelineItem:
            self = .emote(item)
        case let item as RedactedRoomTimelineItem:
            self = .redacted(item)
        case let item as EncryptedRoomTimelineItem:
            self = .encrypted(item)
        case let item as ReadMarkerRoomTimelineItem:
            self = .readMarker(item)
        case let item as PaginationIndicatorRoomTimelineItem:
            self = .paginationIndicator(item)
        case let item as StickerRoomTimelineItem:
            self = .sticker(item)
        case let item as UnsupportedRoomTimelineItem:
            self = .unsupported(item)
        case let item as TimelineStartRoomTimelineItem:
            self = .timelineStart(item)
        case let item as EncryptedHistoryRoomTimelineItem:
            self = .encryptedHistory(item)
        case let item as StateRoomTimelineItem:
            self = .state(item)
        case let item as CollapsibleTimelineItem:
            self = .group(item)
        case let item as LocationRoomTimelineItem:
            self = .location(item)
        default:
            fatalError("Unknown timeline item")
        }
    }

    var id: TimelineItemIdentifier {
        switch self {
        case .text(let item as RoomTimelineItemProtocol),
             .separator(let item as RoomTimelineItemProtocol),
             .image(let item as RoomTimelineItemProtocol),
             .video(let item as RoomTimelineItemProtocol),
             .audio(let item as RoomTimelineItemProtocol),
             .file(let item as RoomTimelineItemProtocol),
             .emote(let item as RoomTimelineItemProtocol),
             .notice(let item as RoomTimelineItemProtocol),
             .redacted(let item as RoomTimelineItemProtocol),
             .encrypted(let item as RoomTimelineItemProtocol),
             .readMarker(let item as RoomTimelineItemProtocol),
             .paginationIndicator(let item as RoomTimelineItemProtocol),
             .sticker(let item as RoomTimelineItemProtocol),
             .unsupported(let item as RoomTimelineItemProtocol),
             .timelineStart(let item as RoomTimelineItemProtocol),
             .encryptedHistory(let item as RoomTimelineItemProtocol),
             .state(let item as RoomTimelineItemProtocol),
             .group(let item as RoomTimelineItemProtocol),
             .location(let item as RoomTimelineItemProtocol):
            return item.id
        }
    }

    /// Whether or not it is possible to send a reaction to this timeline item.
    var isReactable: Bool {
        switch self {
        case .text, .image, .video, .audio, .file, .emote, .notice, .sticker, .location:
            return true
        case .redacted, .encrypted, .unsupported, .state: // Event based items that aren't reactable
            return false
        case .timelineStart, .encryptedHistory, .separator, .readMarker, .paginationIndicator: // Virtual items are never reactable
            return false
        case .group:
            return false
        }
    }
}
