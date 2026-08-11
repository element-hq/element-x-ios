//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeScreenRoomList: View {
    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    
    @ObservedObject var context: HomeScreenViewModel.Context
    
    var body: some View {
        // Hide the room list when the search bar is focused but the query is empty
        // This works hand in hand with the room list service layer filtering and
        // avoids glitches when focusing the search bar
        if !context.viewState.shouldHideRoomList {
            content
        }
    }
    
    private var content: some View {
        ForEach(context.viewState.visibleRooms) { room in
            switch room.type {
            case .placeholder:
                HomeScreenRoomCell(room: room, isSelected: false, mediaProvider: context.mediaProvider, action: context.send)
                    .redacted(reason: .placeholder)
            case .invite:
                HomeScreenInviteCell(room: room, context: context, hideInviteAvatars: context.viewState.hideInviteAvatars)
            case .knock:
                HomeScreenKnockedCell(room: room, context: context)
            case .room:
                let isSelected = context.viewState.selectedRoomID == room.id
                
                HomeScreenRoomCell(room: room,
                                   roomListActivityVisibility: context.viewState.roomListActivityVisibility,
                                   isSelected: isSelected,
                                   mediaProvider: context.mediaProvider,
                                   action: context.send)
                    .overlay {
                        RoomPeekInteraction(room: room,
                                            supportsMultipleWindows: supportsMultipleWindows,
                                            reportRoomEnabled: context.viewState.reportRoomEnabled,
                                            viewModelBuilder: context.viewState.roomPeekViewModelBuilder,
                                            action: context.send)
                    }
            }
        }
    }
}
