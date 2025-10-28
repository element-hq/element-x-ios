//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
        .toolbarRole(RoomHeaderView.toolbarRole)
        .navigationTitle(context.viewState.space.name)
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
            RoomHeaderView(roomName: context.viewState.space.name,
                           roomAvatar: context.viewState.space.avatar,
                           mediaProvider: context.mediaProvider)
        }
        
        // This should really use a ToolbarItemGroup(placement: .secondaryAction), however it
        // was crashing on iOS 26.0 when tapping the ShareLink as the popover presentation
        // controller attempts to anchor itself to the button that is no longer visible.
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Section {
                    if let roomProxy = context.viewState.roomProxy {
                        Button { context.send(viewAction: .displayMembers(roomProxy: roomProxy)) } label: {
                            Label(L10n.screenSpaceMenuActionMembers, icon: \.user)
                        }
                    }
                    if let permalink = context.viewState.permalink {
                        ShareLink(item: permalink) {
                            Label(L10n.actionShare, icon: \.shareIos)
                        }
                    }
                    
                    if context.viewState.isSpaceManagementEnabled {
                        Button { context.send(viewAction: .spaceSettings) } label: {
                            Label(L10n.commonSettings, icon: \.settings)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) { context.send(viewAction: .leaveSpace) } label: {
                        Label(L10n.actionLeaveSpace, icon: \.leave)
                    }
                }
            } label: {
                // Use an SF Symbol to match what ToolbarItemGroup(placement: .secondaryAction) would give us.
                Image(systemSymbol: .ellipsis)
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
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.roomForIdentifierClosure = { _ in
            .joined(JoinedRoomProxyMock(.init()))
        }
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        
        let viewModel = SpaceScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                             spaceServiceProxy: SpaceServiceProxyMock(.init()),
                                             selectedSpaceRoomPublisher: .init(nil),
                                             userSession: userSession,
                                             appSettings: AppSettings(),
                                             userIndicatorController: UserIndicatorControllerMock())
        return viewModel
    }
}
