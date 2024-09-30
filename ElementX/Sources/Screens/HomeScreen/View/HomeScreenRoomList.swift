//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct HomeScreenRoomList: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    
    var body: some View {
        // Hide the room list when the search bar is focused but the query is empty
        // This works hand in hand with the room list service layer filtering and
        // avoids glitches when focusing the search bar
        if !context.viewState.shouldHideRoomList {
            content
        } else if context.viewState.isRoomDirectorySearchEnabled {
            RoomDirectorySearchView {
                context.send(viewAction: .selectRoomDirectorySearch)
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        ForEach(context.viewState.visibleRooms) { room in
            switch room.type {
            case .placeholder:
                HomeScreenRoomCell(room: room, context: context, isSelected: false)
                    .redacted(reason: .placeholder)
            case .invite:
                HomeScreenInviteCell(room: room, context: context)
            case .room:
                let isSelected = context.viewState.selectedRoomID == room.id
                
                HomeScreenRoomCell(room: room, context: context, isSelected: isSelected)
                    .contextMenu {
                        if room.badges.isDotShown {
                            Button {
                                context.send(viewAction: .markRoomAsRead(roomIdentifier: room.id))
                            } label: {
                                Label(L10n.screenRoomlistMarkAsRead, icon: \.markAsRead)
                            }
                        } else {
                            Button {
                                context.send(viewAction: .markRoomAsUnread(roomIdentifier: room.id))
                            } label: {
                                Label(L10n.screenRoomlistMarkAsUnread, icon: \.markAsUnread)
                            }
                        }
                        
                        if room.isFavourite {
                            Button {
                                context.send(viewAction: .markRoomAsFavourite(roomIdentifier: room.id, isFavourite: false))
                            } label: {
                                Label(L10n.commonFavourited, icon: \.favouriteSolid)
                            }
                        } else {
                            Button {
                                context.send(viewAction: .markRoomAsFavourite(roomIdentifier: room.id, isFavourite: true))
                            } label: {
                                Label(L10n.commonFavourite, icon: \.favourite)
                            }
                        }
                        
                        Button {
                            context.send(viewAction: .showRoomDetails(roomIdentifier: room.id))
                        } label: {
                            Label(L10n.commonSettings, icon: \.settings)
                        }
                        
                        Button(role: .destructive) {
                            context.send(viewAction: .leaveRoom(roomIdentifier: room.id))
                        } label: {
                            Label(L10n.actionLeaveRoom, icon: \.leave)
                        }
                    }
            }
        }
    }
}
