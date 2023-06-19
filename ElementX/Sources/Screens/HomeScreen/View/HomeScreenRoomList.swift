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
    @Environment(\.isSearching) var isSearching
    
    @ObservedObject var context: HomeScreenViewModel.Context
    
    var body: some View {
        if isSearching, context.searchQuery.count == 0 {
            EmptyView()
        } else {
            ForEach(context.viewState.visibleRooms) { room in
                Group {
                    if room.isPlaceholder {
                        HomeScreenRoomCell(room: room, context: context, isSelected: false)
                            .redacted(reason: .placeholder)
                    } else {
                        let isSelected = context.viewState.highlightedRoomID == room.id
                        HomeScreenRoomCell(room: room, context: context, isSelected: isSelected)
                            .contextMenu {
                                Button {
                                    context.send(viewAction: .showRoomDetails(roomIdentifier: room.id))
                                } label: {
                                    Label(L10n.commonSettings, systemImage: "gearshape")
                                }
                                
                                Button(role: .destructive) {
                                    context.send(viewAction: .leaveRoom(roomIdentifier: room.id))
                                } label: {
                                    Label(L10n.actionLeaveRoom, systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            }
                    }
                }
            }
        }
    }
}
