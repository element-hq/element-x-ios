//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//
import SwiftUI

struct RoomTimelineItemView: View {
    @Environment(\.timelineContext) var context
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
            VoiceMessageRoomTimelineView(timelineItem: item, playerState: context?.viewState.audioPlayerStateProvider?(item.id) ?? AudioPlayerState(id: .timelineItemIdentifier(item.id),
                                                                                                                                                    title: L10n.commonVoiceMessage,
                                                                                                                                                    duration: 0))
        case .callInvite(let item):
            CallInviteRoomTimelineView(timelineItem: item)
        case .callNotification(let item):
            CallNotificationRoomTimelineView(timelineItem: item)
        }
    }
}
