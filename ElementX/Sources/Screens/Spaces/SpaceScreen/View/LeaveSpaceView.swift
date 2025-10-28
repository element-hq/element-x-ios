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
    
    let context: SpaceScreenViewModel.Context
    let leaveHandle: LeaveSpaceHandleProxy
    
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
                Text(leaveHandle.title(spaceName: context.viewState.space.name))
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                if let subtitle = leaveHandle.subtitle {
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
        if !leaveHandle.rooms.isEmpty, leaveHandle.canLeave {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    ForEach(leaveHandle.rooms, id: \.spaceRoomProxy.id) { room in
                        LeaveSpaceRoomDetailsCell(room: room,
                                                  hideSelection: leaveHandle.mode == .onlyAdminRooms,
                                                  mediaProvider: context.mediaProvider) {
                            context.send(viewAction: .toggleLeaveSpaceRoomDetails(id: room.spaceRoomProxy.id))
                        }
                        .disabled(room.isLastAdmin)
                    }
                } header: {
                    if leaveHandle.mode == .manyRooms {
                        Button(leaveHandle.selectedCount > 0 ? L10n.actionDeselectAll : L10n.actionSelectAll) {
                            context.send(viewAction: leaveHandle.selectedCount > 0 ? .deselectAllLeaveRoomDetails : .selectAllLeaveRoomDetails)
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
            if leaveHandle.canLeave {
                Button(role: .destructive) {
                    context.send(viewAction: .confirmLeaveSpace)
                } label: {
                    Label(leaveHandle.confirmationTitle, icon: \.leave)
                }
                .buttonStyle(.compound(.primary))
            } else if context.viewState.isSpaceManagementEnabled {
                Button {
                    context.send(viewAction: .spaceSettings)
                } label: {
                    Label(L10n.actionGoToSettings, icon: \.settings)
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

private extension LeaveSpaceHandleProxy {
    func title(spaceName: String) -> String {
        switch mode {
        case .lastSpaceAdmin: L10n.screenLeaveSpaceTitleLastAdmin(spaceName)
        default: L10n.screenLeaveSpaceTitle(spaceName)
        }
    }
    
    var subtitle: String? {
        switch mode {
        case .manyRooms: L10n.screenLeaveSpaceSubtitle
        case .onlyAdminRooms: L10n.screenLeaveSpaceSubtitleOnlyLastAdmin
        case .noRooms: nil
        case .lastSpaceAdmin: L10n.screenLeaveSpaceSubtitleLastAdmin
        }
    }
    
    var confirmationTitle: String {
        let selectedCount = selectedCount
        return selectedCount > 0 ? L10n.screenLeaveSpaceSubmit(selectedCount) : L10n.actionLeaveSpace
    }
}

// MARK: - Previews

import MatrixRustSDK

struct LeaveSpaceView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        LeaveSpaceView(context: viewModel.context, leaveHandle: makeLeaveHandle(mode: .manyRooms))
            .previewDisplayName("Many Rooms")
        LeaveSpaceView(context: viewModel.context, leaveHandle: makeLeaveHandle(mode: .onlyAdminRooms))
            .previewDisplayName("Only Admin Rooms")
        LeaveSpaceView(context: viewModel.context, leaveHandle: makeLeaveHandle(mode: .noRooms))
            .previewDisplayName("No Rooms")
        LeaveSpaceView(context: viewModel.context, leaveHandle: makeLeaveHandle(mode: .lastSpaceAdmin))
            .previewDisplayName("Last Space Admin")
    }
    
    static let spaceRoomProxy = SpaceRoomProxyMock(.init(id: "!eng-space:matrix.org",
                                                         name: "Engineering Team",
                                                         isSpace: true,
                                                         childrenCount: 30,
                                                         joinedMembersCount: 76,
                                                         heroes: [.mockDan, .mockBob, .mockCharlie, .mockVerbose],
                                                         topic: "Description of the space goes right here. Lorem ipsum dolor sit amet consectetur. Leo viverra morbi habitant in.",
                                                         joinRule: .knockRestricted(rules: [.roomMembership(roomId: "")])))
    
    static func makeViewModel() -> SpaceScreenViewModel {
        let spaceRoomListProxy = SpaceRoomListProxyMock(.init(spaceRoomProxy: spaceRoomProxy,
                                                              initialSpaceRooms: .mockSpaceList))
        let spaceServiceProxy = SpaceServiceProxyMock(.init())
        
        let viewModel = SpaceScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                             spaceServiceProxy: spaceServiceProxy,
                                             selectedSpaceRoomPublisher: .init(nil),
                                             userSession: UserSessionMock(.init()),
                                             appSettings: AppSettings(),
                                             userIndicatorController: UserIndicatorControllerMock())
        return viewModel
    }
    
    static func makeLeaveHandle(mode: LeaveSpaceHandleProxy.Mode) -> LeaveSpaceHandleProxy {
        let rooms: [LeaveSpaceRoom] = switch mode {
        case .manyRooms: .mockRooms
        case .onlyAdminRooms: .mockAdminRooms
        case .noRooms: []
        case .lastSpaceAdmin: .mockLastSpaceAdmin(spaceRoomProxy: spaceRoomProxy)
        }
        
        return LeaveSpaceHandleProxy(spaceID: spaceRoomProxy.id,
                                     leaveHandle: LeaveSpaceHandleSDKMock(.init(rooms: rooms)))
    }
}
