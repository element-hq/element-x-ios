//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SpaceScreen: View {
    @Bindable var context: SpaceScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                SpaceHeaderView(spaceRoomProxy: context.viewState.space,
                                mediaProvider: context.mediaProvider)
                rooms
            }
        }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .navigationTitle(context.viewState.spaceName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .sheet(isPresented: .constant(true)) {
            SpaceScreenDescriptionView()
                .presentationDetents([.height(199)])
                .presentationDragIndicator(.visible)
        }
    }
    
    @ViewBuilder
    var rooms: some View {
        ForEach(context.viewState.rooms, id: \.id) { spaceRoomProxy in
            SpaceRoomCell(spaceRoomProxy: spaceRoomProxy,
                          isSelected: spaceRoomProxy.id == context.viewState.selectedSpaceRoomID,
                          mediaProvider: context.mediaProvider) { action in
                context.send(viewAction: .spaceAction(action))
            }
        }
        
        if context.viewState.isPaginating {
            ProgressView()
                .padding()
        }
    }
    
    var toolbar: some ToolbarContent {
        // Use the same trick as the RoomScreen for a leading title view that
        // also hides the navigation title.
        ToolbarItem(placement: .principal) {
            RoomHeaderView(roomName: context.viewState.spaceName,
                           roomAvatar: context.viewState.space.avatar,
                           mediaProvider: context.mediaProvider)
        }
    }
}

struct SpaceScreenDescriptionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Text("Description")
                .font(.compound.bodySM)
                .foregroundStyle(.compound.textSecondary)
                .textCase(.uppercase)
            Text("Description of the space goes right here. Lorem ipsum dolor sit amet consectetur. Leo viverra morbi habitant in. Sem amet enim habitant nibh augue mauris. Interdum mauris ultrices tincidunt proin morbi erat aenean risus nibh. Diam amet sit fermentum vulputate faucibus.")
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textPrimary)
        }
        .padding(16.0)
    }
}


// MARK: - Previews

struct SpaceScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        NavigationStack {
            SpaceScreen(context: viewModel.context)
        }
        SpaceScreenDescriptionView()
    }
    
    static func makeViewModel() -> SpaceScreenViewModel {
        let spaceRoomProxy = SpaceRoomProxyMock(.init(id: "!eng-space:matrix.org",
                                                      name: "Engineering Team",
                                                      isSpace: true,
                                                      childrenCount: 30,
                                                      joinedMembersCount: 76,
                                                      heroes: [.mockDan, .mockBob, .mockCharlie, .mockVerbose],
                                                      topic: "Description of the space goes right here. Lorem ipsum dolor sit amet consectetur. Leo viverra morbi habitant in.",
                                                      joinRule: .knockRestricted(rules: [.roomMembership(roomId: "")])))
        let spaceRoomListProxy = SpaceRoomListProxyMock(.init(spaceRoomProxy: spaceRoomProxy,
                                                              initialSpaceRooms: .mockSpaceList))
        
        let viewModel = SpaceScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                             spaceServiceProxy: SpaceServiceProxyMock(.init()),
                                             selectedSpaceRoomPublisher: .init(nil),
                                             mediaProvider: .mock,
                                             userIndicatorController: UserIndicatorControllerMock())
        return viewModel
    }
}
