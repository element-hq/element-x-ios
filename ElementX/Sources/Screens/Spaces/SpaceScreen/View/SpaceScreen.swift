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
    
    private var isEditModeActive: Bool {
        context.viewState.editMode != .inactive
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if !isEditModeActive {
                    SpaceHeaderView(spaceServiceRoom: context.viewState.space,
                                    mediaProvider: context.mediaProvider)
                }
                
                if context.viewState.shouldShowEmptyState {
                    emptyState
                } else {
                    rooms
                }
            }
        }
        .environment(\.editMode, .constant(context.viewState.editMode))
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .toolbarRole(RoomHeaderView.toolbarRole)
        .navigationTitle(context.viewState.space.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditModeActive)
        .toolbar { toolbar }
        .sheet(isPresented: $context.isPresentingRemoveChildrenConfirmation) {
            SpaceRemoveChildrenConfirmationView(spaceName: context.viewState.space.name) {
                context.send(viewAction: .confirmRemoveSelectedChildren)
            }
        }
        .sheet(item: $context.leaveSpaceViewModel) { leaveSpaceViewModel in
            LeaveSpaceView(context: leaveSpaceViewModel.context)
        }
    }
    
    @ViewBuilder
    var rooms: some View {
        ForEach(context.viewState.visibleRooms, id: \.id) { spaceServiceRoom in
            SpaceRoomCell(spaceServiceRoom: spaceServiceRoom,
                          isSelected: context.viewState.isSpaceIDSelected(spaceServiceRoom.id),
                          isJoining: context.viewState.joiningRoomIDs.contains(spaceServiceRoom.id),
                          mediaProvider: context.mediaProvider) { action in
                context.send(viewAction: .spaceAction(action))
            }
        }
        
        if context.viewState.paginationState == .paginating {
            ProgressView()
                .padding()
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 24) {
            TitleAndIcon(title: L10n.screenSpaceEmptyStateTitle,
                         icon: \.room,
                         iconStyle: .defaultSolid)
                .padding(.horizontal, 24)
            
            VStack(spacing: 16) {
                Button { context.send(viewAction: .addExistingRooms) } label: {
                    Label(L10n.actionAddExistingRooms, icon: \.plus)
                }
                .buttonStyle(.compound(.primary))
                
                if context.viewState.canCreateRoom {
                    Button(L10n.actionCreateRoom) {
                        context.send(viewAction: .createChildRoom)
                    }
                    .buttonStyle(.compound(.secondary))
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 40)
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        if isEditModeActive {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel, role: .cancel) {
                    context.send(viewAction: .finishManagingChildren)
                }
            }
        }
        
        // Use the same trick as the RoomScreen for a leading title view that
        // also hides the navigation title.
        ToolbarItem(placement: .principal) {
            RoomHeaderView(roomName: context.viewState.space.name,
                           roomAvatar: context.viewState.space.avatar,
                           mediaProvider: context.mediaProvider) {
                if context.viewState.isSpaceManagementEnabled,
                   let roomProxy = context.viewState.roomProxy {
                    context.send(viewAction: .spaceSettings(roomProxy: roomProxy))
                }
            }
        }
        
        if isEditModeActive {
            ToolbarItem(placement: .primaryAction) {
                ToolbarButton(role: .destructive(title: L10n.actionRemove)) {
                    context.send(viewAction: .removeSelectedChildren)
                }
                .disabled(context.viewState.editModeSelectedIDs.isEmpty)
            }
        } else {
            // This should really use a ToolbarItemGroup(placement: .secondaryAction), however it
            // was crashing on iOS 26.0 when tapping the ShareLink as the popover presentation
            // controller attempts to anchor itself to the button that is no longer visible.
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if context.viewState.canEditChildren {
                        Section {
                            if context.viewState.canCreateRoom {
                                Button { context.send(viewAction: .createChildRoom) } label: {
                                    Label(L10n.actionCreateRoom, icon: \.plus)
                                }
                            }
                            Button { context.send(viewAction: .addExistingRooms) } label: {
                                Label(L10n.actionAddExistingRooms, icon: \.room)
                            }
                            .accessibilityIdentifier(A11yIdentifiers.spaceScreen.addExistingRooms)
                            
                            Button { context.send(viewAction: .manageChildren) } label: {
                                Label(L10n.actionManageRooms, icon: \.edit)
                            }
                        }
                    }
                    
                    Section {
                        if let roomProxy = context.viewState.roomProxy {
                            Button { context.send(viewAction: .displayMembers(roomProxy: roomProxy)) } label: {
                                Label(L10n.screenSpaceMenuActionMembers, icon: \.user)
                            }
                            .accessibilityIdentifier(A11yIdentifiers.spaceScreen.viewMembers)
                        }
                        
                        if let permalink = context.viewState.permalink {
                            ShareLink(item: permalink) {
                                Label(L10n.actionShare, icon: \.shareIos)
                            }
                        }
                        
                        if context.viewState.isSpaceManagementEnabled,
                           let roomProxy = context.viewState.roomProxy {
                            Button { context.send(viewAction: .spaceSettings(roomProxy: roomProxy)) } label: {
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
                .accessibilityIdentifier(A11yIdentifiers.spaceScreen.moreMenu)
            }
        }
    }
}

// MARK: - Previews

struct SpaceScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let managingViewModel = makeViewModel(isManagingRooms: true)
    static let newSpaceViewModel = makeViewModel(isNewSpace: true)
    
    static var previews: some View {
        NavigationStack {
            SpaceScreen(context: viewModel.context)
        }
        
        NavigationStack {
            SpaceScreen(context: managingViewModel.context)
        }
        .previewDisplayName("Managing")
        
        NavigationStack {
            SpaceScreen(context: newSpaceViewModel.context)
        }
        .previewDisplayName("New Space")
        .snapshotPreferences(expect: newSpaceViewModel.context.observe(\.viewState).map {
            $0.canCreateRoom && $0.canEditChildren
        })
    }
    
    static func makeViewModel(isManagingRooms: Bool = false, isNewSpace: Bool = false) -> SpaceScreenViewModel {
        let appSettings = AppSettings()
        appSettings.spaceSettingsEnabled = true
        appSettings.createSpaceEnabled = true
        
        let spaceServiceRoom = SpaceServiceRoom.mock(id: "!eng-space:matrix.org",
                                                     name: "Engineering Team",
                                                     isSpace: true,
                                                     childrenCount: 30,
                                                     joinedMembersCount: 76,
                                                     heroes: [.mockDan, .mockBob, .mockCharlie, .mockVerbose],
                                                     topic: "Description of the space goes right here. Lorem ipsum dolor sit amet consectetur. Leo viverra morbi habitant in.",
                                                     canonicalAlias: "#engineering-team:element.io",
                                                     joinRule: .knockRestricted(rules: [.roomMembership(roomID: "")]))
        let spaceRoomListProxy = SpaceRoomListProxyMock(.init(spaceServiceRoom: spaceServiceRoom,
                                                              initialSpaceRooms: isNewSpace ? [] : .mockSpaceList))
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.roomForIdentifierClosure = { _ in
            .joined(JoinedRoomProxyMock(.init(members: .allMembersAsAdmin)))
        }
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        
        let viewModel = SpaceScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                             spaceServiceProxy: SpaceServiceProxyMock(.init()),
                                             selectedSpaceRoomPublisher: .init(nil),
                                             userSession: userSession,
                                             appSettings: appSettings,
                                             userIndicatorController: UserIndicatorControllerMock())
        
        if isManagingRooms {
            viewModel.state.editMode = .transient
            viewModel.state.editModeSelectedIDs = [viewModel.state.visibleRooms[0].id]
        }
        
        return viewModel
    }
}
