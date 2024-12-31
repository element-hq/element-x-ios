//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomSelectionScreen: View {
    @ObservedObject var context: RoomSelectionScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                ForEach(context.viewState.rooms) { room in
                    RoomSelectionListRow(room: room,
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
        .navigationTitle(L10n.screenRoomlistMainSpaceTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.actionShare) {
                    context.send(viewAction: .confirm)
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

private struct RoomSelectionListRow: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let room: RoomSelectionRoom
    let isSelected: Bool
    let context: RoomSelectionScreenViewModel.Context
    
    var body: some View {
        ListRow(label: .avatar(title: room.title,
                               description: room.description,
                               icon: avatar),
                kind: .selection(isSelected: isSelected) {
                    context.send(viewAction: .selectRoom(roomID: room.id))
                })
    }
    
    @ViewBuilder @MainActor
    var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: room.avatar,
                            avatarSize: .room(on: .roomSelection),
                            mediaProvider: context.mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

struct RoomSelectionScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let summaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let viewModel = RoomSelectionScreenViewModel(clientProxy: ClientProxyMock(.init()),
                                                     roomSummaryProvider: summaryProvider,
                                                     mediaProvider: MediaProviderMock(configuration: .init()))
        
        NavigationStack {
            RoomSelectionScreen(context: viewModel.context)
        }
    }
}
