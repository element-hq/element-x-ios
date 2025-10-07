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
        .sheet(item: $context.leaveHandle) { leaveHandle in
            LeaveSpaceView(context: context, leaveHandle: leaveHandle)
        }
    }
    
    @ViewBuilder
    var rooms: some View {
        ForEach(context.viewState.rooms, id: \.id) { spaceRoomProxy in
            SpaceRoomCell(spaceRoomProxy: spaceRoomProxy,
                          isSelected: spaceRoomProxy.id == context.viewState.selectedSpaceRoomID,
                          isJoining: context.viewState.joiningRoomIDs.contains(spaceRoomProxy.id),
                          mediaProvider: context.mediaProvider) { action in
                context.send(viewAction: .spaceAction(action))
            }
        }
        
        if context.viewState.isPaginating {
            ProgressView()
                .padding()
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        // Use the same trick as the RoomScreen for a leading title view that
        // also hides the navigation title.
        ToolbarItem(placement: .principal) {
            RoomHeaderView(roomName: context.viewState.spaceName,
                           roomAvatar: context.viewState.space.avatar,
                           mediaProvider: context.mediaProvider)
        }
        
        ToolbarItemGroup(placement: .secondaryAction) {
            // FIXME: The ShareLink crashes on iOS 26 due to the share sheet failing to morph out of the button 🤦‍♂️
            if let permalink = context.viewState.permalink, #unavailable(iOS 26.0) {
                Section {
                    ShareLink(item: permalink) {
                        Label(L10n.actionShare, icon: \.shareIos)
                    }
                }
            }
            
            Section {
                Button(role: .destructive) { context.send(viewAction: .leaveSpace) } label: {
                    Label(L10n.actionLeaveSpace, icon: \.leave)
                }
            }
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
                                             selectedSpaceRoomPublisher: .init(nil),
                                             userSession: UserSessionMock(.init()),
                                             userIndicatorController: UserIndicatorControllerMock())
        return viewModel
    }
}
