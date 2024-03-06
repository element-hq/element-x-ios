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

struct HomeScreenRoomList: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    
    var body: some View {
        // Hide the room list when the search bar is focused but the query is empty
        // This works hand in hand with the room list service layer filtering and
        // avoids glitches when focusing the search bar
        if !context.viewState.shouldHideRoomList {
            content
        }
    }
    
    @ViewBuilder
    private var content: some View {
        ForEach(context.viewState.visibleRooms) { room in
            if room.isPlaceholder {
                HomeScreenRoomCell(room: room, context: context, isSelected: false)
                    .redacted(reason: .placeholder)
            } else {
                let isSelected = context.viewState.selectedRoomID == room.id
                
                HomeScreenRoomCell(room: room, context: context, isSelected: isSelected)
                    .contextMenu {
                        if context.viewState.markAsUnreadEnabled {
                            if room.badges.isDotShown {
                                Button {
                                    context.send(viewAction: .markRoomAsRead(roomIdentifier: room.id))
                                } label: {
                                    Text(L10n.screenRoomlistMarkAsRead)
                                }
                            } else {
                                Button {
                                    context.send(viewAction: .markRoomAsUnread(roomIdentifier: room.id))
                                } label: {
                                    Text(L10n.screenRoomlistMarkAsUnread)
                                }
                            }
                        }
                        
                        if context.viewState.markAsFavouriteEnabled {
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
