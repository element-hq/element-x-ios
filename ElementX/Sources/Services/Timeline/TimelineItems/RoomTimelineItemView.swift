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
import SwiftUI

struct RoomTimelineItemView: View {
    @Environment(\.roomContext) var context
    @ObservedObject var viewState: RoomTimelineItemViewState
    
    var body: some View {
        timelineView
            .animation(.elementDefault, value: viewState.groupStyle)
            .animation(.elementDefault, value: viewState.type)
            .environment(\.timelineGroupStyle, viewState.groupStyle)
            .onAppear {
                context?.send(viewAction: .itemAppeared(itemID: viewState.identifier))
            }
            .onDisappear {
                context?.send(viewAction: .itemDisappeared(itemID: viewState.identifier))
            }
    }

    @ViewBuilder private var timelineView: some View {
        switch viewState.type {
        case .text(let item):
            TextRoomTimelineView(timelineItem: item)
        case .separator(let item):
            SeparatorRoomTimelineView(timelineItem: item)
        case .image(let item):
            ImageRoomTimelineView(timelineItem: item)
        case .video(let item):
            VideoRoomTimelineView(timelineItem: item)
        case .audio(let item):
            AudioRoomTimelineView(timelineItem: item)
        case .file(let item):
            FileRoomTimelineView(timelineItem: item)
        case .emote(let item):
            EmoteRoomTimelineView(timelineItem: item)
        case .notice(let item):
            NoticeRoomTimelineView(timelineItem: item)
        case .redacted(let item):
            RedactedRoomTimelineView(timelineItem: item)
        case .encrypted(let item):
            EncryptedRoomTimelineView(timelineItem: item)
        case .readMarker(let item):
            ReadMarkerRoomTimelineView(timelineItem: item)
        case .paginationIndicator(let item):
            PaginationIndicatorRoomTimelineView(timelineItem: item)
        case .sticker(let item):
            StickerRoomTimelineView(timelineItem: item)
        case .unsupported(let item):
            UnsupportedRoomTimelineView(timelineItem: item)
        case .timelineStart(let item):
            TimelineStartRoomTimelineView(timelineItem: item)
        case .state(let item):
            StateRoomTimelineView(timelineItem: item)
        case .group(let item):
            CollapsibleRoomTimelineView(timelineItem: item)
        case .location(let item):
            LocationRoomTimelineView(timelineItem: item)
        case .poll(let item):
            PollRoomTimelineView(timelineItem: item)
        case .voice(let item):
            VoiceMessageRoomTimelineView(timelineItem: item, playerState: context?.viewState.audioPlayerStateProvider?(item.id) ?? AudioPlayerState(id: .timelineItemIdentifier(item.id), duration: 0))
        case .callInvite(let item):
            CallInviteRoomTimelineView(timelineItem: item)
        }
    }
}
