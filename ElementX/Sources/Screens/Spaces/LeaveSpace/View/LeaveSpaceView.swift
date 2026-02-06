//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LeaveSpaceView: View {
    @Environment(\.dismiss) private var dismiss
    
    let context: LeaveSpaceViewModel.Context
    
    @State private var scrollViewHeight: CGFloat = .zero
    @State private var buttonsHeight: CGFloat = .zero
    private let topPadding = 19.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                rooms
            }
            .readHeight($scrollViewHeight)
        }
        .backportSafeAreaBar(edge: .bottom, spacing: 0) {
            buttons
                .readHeight($buttonsHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding(.top, topPadding) // For the drag indicator
        .presentationDetents([.height(scrollViewHeight + buttonsHeight + topPadding)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.compound.bgCanvasDefault)
    }
    
    var header: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.errorSolid, style: .alertSolid)
            
            VStack(spacing: 8) {
                Text(context.viewState.title)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                if let subtitle = context.viewState.subtitle {
                    Text(subtitle)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(24)
    }
    
    @ViewBuilder
    var rooms: some View {
        if !context.viewState.leaveHandle.rooms.isEmpty,
           context.viewState.leaveHandle.canLeave {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    ForEach(context.viewState.leaveHandle.rooms, id: \.spaceServiceRoom.id) { room in
                        LeaveSpaceRoomDetailsCell(room: room,
                                                  hideSelection: !room.canLeave,
                                                  mediaProvider: context.mediaProvider) {
                            context.send(viewAction: .toggleRoom(roomID: room.spaceServiceRoom.id))
                        }
                        .disabled(!room.canLeave)
                    }
                } header: {
                    if context.viewState.leaveHandle.mode == .manyRooms {
                        Button(context.viewState.leaveHandle.selectedCount > 0 ? L10n.actionDeselectAll : L10n.actionSelectAll) {
                            context.send(viewAction: context.viewState.leaveHandle.selectedCount > 0 ? .deselectAll : .selectAll)
                        }
                        .buttonStyle(.compound(.textLink, size: .small))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
                    }
                }
            }
        }
    }
    
    var buttons: some View {
        VStack(spacing: 16) {
            switch context.viewState.leaveHandle.mode {
            case .spaceNeedsNewOwner(let useTransferOwnershipFlow):
                if context.viewState.canEditRolesAndPermissions {
                    if useTransferOwnershipFlow {
                        Button(L10n.leaveRoomAlertSelectNewOwnerAction, role: .destructive) {
                            context.send(viewAction: .transferOwnership)
                        }
                        .buttonStyle(.compound(.primary))
                    } else {
                        Button {
                            context.send(viewAction: .rolesAndPermissions)
                        } label: {
                            Label(L10n.actionGoToRolesAndPermissions, icon: \.settings)
                        }
                        .buttonStyle(.compound(.primary))
                    }
                }
            default:
                Button(role: .destructive) {
                    context.send(viewAction: .confirmLeaveSpace)
                } label: {
                    Label(context.viewState.confirmationTitle, icon: \.leave)
                }
                .buttonStyle(.compound(.primary))
            }
            
            Button(L10n.actionCancel, action: dismiss.callAsFunction)
                .buttonStyle(.compound(.tertiary))
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Previews

import MatrixRustSDK
import MatrixRustSDKMocks

struct LeaveSpaceView_Previews: PreviewProvider, TestablePreview {
    static let manyViewModel = makeViewModel(mode: .manyRooms)
    static let onlyAdminViewModel = makeViewModel(mode: .roomsNeedNewOwner)
    static let noRoomsViewModel = makeViewModel(mode: .noRooms)
    static let lastAdminViewModel = makeViewModel(mode: .spaceNeedsNewOwner(useTransferOwnershipFlow: false))
    static let lastOwnerViewModel = makeViewModel(mode: .spaceNeedsNewOwner(useTransferOwnershipFlow: true))
    
    static var previews: some View {
        LeaveSpaceView(context: manyViewModel.context)
            .previewDisplayName("Many Rooms")
        LeaveSpaceView(context: onlyAdminViewModel.context)
            .previewDisplayName("Only Admin Rooms")
        LeaveSpaceView(context: noRoomsViewModel.context)
            .previewDisplayName("No Rooms")
        LeaveSpaceView(context: lastAdminViewModel.context)
            .previewDisplayName("Last Space Admin")
        LeaveSpaceView(context: lastOwnerViewModel.context)
            .previewDisplayName("Last Space Owner")
    }
    
    static let spaceServiceRoom = SpaceServiceRoom.mock(id: "!eng-space:matrix.org",
                                                        name: "Engineering Team",
                                                        isSpace: true,
                                                        childrenCount: 30,
                                                        joinedMembersCount: 76,
                                                        heroes: [.mockDan, .mockBob, .mockCharlie, .mockVerbose],
                                                        topic: "Description of the space goes right here. Lorem ipsum dolor sit amet consectetur. Leo viverra morbi habitant in.",
                                                        joinRule: .knockRestricted(rules: [.roomMembership(roomID: "")]))
    
    static func makeViewModel(mode: LeaveSpaceHandleProxy.Mode) -> LeaveSpaceViewModel {
        let rooms: [LeaveSpaceRoom] = switch mode {
        case .manyRooms: .mockRooms
        case .roomsNeedNewOwner: .mockNeedNewOwnerRooms
        case .noRooms: .mockSingleSpace(spaceServiceRoom: spaceServiceRoom,
                                        isLastOwner: false,
                                        areCreatorsPrivileged: false)
        case .spaceNeedsNewOwner(let useTransferOwnershipFlow): .mockRoomsWithSpace(spaceServiceRoom: spaceServiceRoom,
                                                                                    isLastOwner: true,
                                                                                    areCreatorsPrivileged: useTransferOwnershipFlow)
        }
        
        let leaveHandle = LeaveSpaceHandleProxy(spaceID: spaceServiceRoom.id,
                                                leaveHandle: LeaveSpaceHandleSDKMock(.init(rooms: rooms)))
        
        return LeaveSpaceViewModel(spaceName: spaceServiceRoom.name,
                                   canEditRolesAndPermissions: true,
                                   leaveHandle: leaveHandle,
                                   userIndicatorController: UserIndicatorControllerMock(),
                                   mediaProvider: MediaProviderMock(configuration: .init()))
    }
}
