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
    @Environment(\.isSearching) var isSearchFieldFocused
    
    @ObservedObject var context: HomeScreenViewModel.Context
    @Binding var isSearching: Bool
    
    var body: some View {
        content
            .onChange(of: isSearchFieldFocused) { isSearching = $0 }
    }
    
    @ViewBuilder
    private var content: some View {
        if isSearchFieldFocused, context.searchQuery.count == 0 {
            EmptyView()
        } else {
            ForEach(context.viewState.visibleRooms) { room in
                if room.isPlaceholder {
                    HomeScreenRoomCell(room: room, context: context, isSelected: false)
                        .redacted(reason: .placeholder)
                } else {
                    let isSelected = context.viewState.selectedRoomID == room.id
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
