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

import Compound
import SwiftUI

struct MessageForwardingScreen: View {
    @ObservedObject var context: MessageForwardingScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                ForEach(context.viewState.rooms) { room in
                    MessageForwardingListRow(room: room,
                                             isSelected: context.viewState.selectedRoomID == room.id,
                                             context: context)
                }
                // Replace these with ScrollView's `scrollPosition` when dropping iOS 16.
            } header: {
                emptyRectangle
                    .onAppear {
                        context.send(viewAction: .reachedTop)
                    }
            } footer: {
                emptyRectangle
                    .onAppear {
                        context.send(viewAction: .reachedBottom)
                    }
            }
        }
        .compoundList()
        .navigationTitle(L10n.commonForwardMessage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.actionSend) {
                    context.send(viewAction: .send)
                }
                .disabled(context.viewState.selectedRoomID == nil)
            }
        }
        .searchController(query: $context.searchQuery, showsCancelButton: false)
        .compoundSearchField()
        .disableAutocorrection(true)
    }
    
    /// The greedy size of Rectangle can create an issue with the navigation bar when the search is highlighted, so is best to use a fixed frame instead of hidden() or EmptyView()
    private var emptyRectangle: some View {
        Rectangle()
            .frame(width: 0, height: 0)
    }
}

private struct MessageForwardingListRow: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let room: MessageForwardingRoom
    let isSelected: Bool
    let context: MessageForwardingScreenViewModel.Context
    
    var body: some View {
        ListRow(label: .avatar(title: room.name,
                               description: room.alias ?? room.id,
                               icon: avatar),
                kind: .selection(isSelected: isSelected) {
                    context.send(viewAction: .selectRoom(roomID: room.id))
                })
    }
    
    @ViewBuilder @MainActor
    var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            LoadableAvatarImage(url: room.avatarURL,
                                name: room.name,
                                contentID: room.id,
                                avatarSize: .room(on: .messageForwarding),
                                imageProvider: context.imageProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

struct MessageForwardingScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let summaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let viewModel = MessageForwardingScreenViewModel(forwardingItem: .init(id: .init(timelineID: ""),
                                                                               roomID: "",
                                                                               content: .init(noPointer: .init())),
                                                         clientProxy: ClientProxyMock(),
                                                         roomSummaryProvider: summaryProvider,
                                                         userIndicatorController: UserIndicatorControllerMock(),
                                                         mediaProvider: MockMediaProvider())
        
        NavigationStack {
            MessageForwardingScreen(context: viewModel.context)
        }
    }
}
