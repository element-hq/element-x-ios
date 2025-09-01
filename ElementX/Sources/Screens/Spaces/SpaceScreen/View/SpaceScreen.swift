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
        .navigationTitle(context.viewState.space.name ?? L10n.commonSpace)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
    }
    
    @ViewBuilder
    var rooms: some View {
        ForEach(context.viewState.rooms, id: \.id) { spaceRoomProxy in
            SpaceRoomCell(spaceRoomProxy: spaceRoomProxy,
                          isSelected: false,
                          mediaProvider: context.mediaProvider) { action in
                context.send(viewAction: .spaceAction(action))
            }
        }
        
        if context.viewState.isPaginating {
            ProgressView()
                .padding()
        }
    }
}

// MARK: - Previews

struct SpaceScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        NavigationStack {
            SpaceScreen(context: viewModel.context)
        }
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
                                             mediaProvider: MediaProviderMock(configuration: .init()),
                                             userIndicatorController: UserIndicatorControllerMock())
        return viewModel
    }
}
