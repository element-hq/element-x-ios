//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LeaveSpaceView: View {
    let context: SpaceScreenViewModel.Context
    
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
                Text(L10n.screenLeaveSpaceTitle(context.viewState.spaceName))
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                switch context.leaveHandle?.mode {
                case .manyRooms:
                    Text(L10n.screenLeaveSpaceSubtitle)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                case .onlyAdminRooms:
                    Text(L10n.screenLeaveSpaceSubtitleOnlyLastAdmin)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                case .noRooms, nil:
                    EmptyView()
                }
            }
        }
        .padding(24)
    }
    
    @ViewBuilder
    var rooms: some View {
        if let leaveRooms = context.leaveHandle?.rooms, !leaveRooms.isEmpty {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    ForEach(leaveRooms, id: \.spaceRoomProxy.id) { room in
                        LeaveSpaceRoomDetailsCell(room: room, mediaProvider: context.mediaProvider) {
                            context.send(viewAction: .toggleLeaveSpaceRoomDetails(id: room.spaceRoomProxy.id))
                        }
                        .disabled(room.isLastAdmin)
                    }
                } header: {
                    Button(L10n.commonDeselectAll) {
                        context.send(viewAction: .deselectAllLeaveRoomDetails)
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
    
    var buttons: some View {
        VStack(spacing: 16) {
            Button(role: .destructive) {
                context.send(viewAction: .confirmLeaveSpace)
            } label: {
                Label(context.leaveHandle?.confirmationTitle ?? L10n.actionLeaveSpace, icon: \.leave)
            }
            .buttonStyle(.compound(.primary))
            
            Button(L10n.actionCancel) {
                context.leaveHandle = nil
            }
            .buttonStyle(.compound(.tertiary))
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct LeaveSpaceRoomDetailsCell: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    let room: LeaveSpaceRoomDetails
    let mediaProvider: MediaProviderProtocol?
    
    let action: () -> Void
    
    private var subtitle: String? {
        guard !room.spaceRoomProxy.isSpace else { return nil }
        let memberCount = L10n.commonMemberCount(room.spaceRoomProxy.joinedMembersCount)
        return room.isLastAdmin ? L10n.screenLeaveSpaceLastAdminInfo(memberCount) : memberCount
    }
    
    var visibilityIcon: KeyPath<CompoundIcons, Image>? {
        switch room.spaceRoomProxy.visibility {
        case .public: \.public
        case .private: \.lockSolid
        case .restricted: nil
        case .none: \.lockSolid
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if dynamicTypeSize < .accessibility3 {
                    RoomAvatarImage(avatar: room.spaceRoomProxy.avatar,
                                    avatarSize: .room(on: .leaveSpace),
                                    mediaProvider: mediaProvider)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(room.spaceRoomProxy.computedName)
                        .font(.compound.bodyLGSemibold)
                        .foregroundStyle(.compound.textPrimary)
                        .lineLimit(1)
                        .padding(.vertical, 1)
                        .padding(.vertical, subtitle == nil ? 10 : 0)
                    
                    subtitleLabel
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                
                ListRowAccessory.multiSelection(room.isSelected)
            }
            .padding(.horizontal, 16)
        }
        .buttonStyle(SpaceRoomCellButtonStyle(isSelected: false))
    }
    
    @ViewBuilder
    private var subtitleLabel: some View {
        if let subtitle {
            Label {
                Text(subtitle)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .lineLimit(1)
                    .padding(.vertical, 1)
            } icon: {
                if let visibilityIcon {
                    CompoundIcon(visibilityIcon,
                                 size: .xSmall,
                                 relativeTo: .compound.bodyMD)
                        .foregroundStyle(.compound.iconTertiary)
                }
            }
            .labelStyle(.custom(spacing: 4))
        }
    }
}

// MARK: - Previews

import MatrixRustSDK

struct LeaveSpaceView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel(mode: .manyRooms)
    static let onlyAdminRoomsViewModel = makeViewModel(mode: .onlyAdminRooms)
    static let noRoomsViewModel = makeViewModel(mode: .noRooms)
    
    static var previews: some View {
        LeaveSpaceView(context: viewModel.context)
            .previewDisplayName("Many Rooms")
            .snapshotPreferences(expect: viewModel.context.observe(\.leaveHandle).map { $0 != nil }.eraseToStream())
        LeaveSpaceView(context: onlyAdminRoomsViewModel.context)
            .previewDisplayName("Only Admin Rooms")
            .snapshotPreferences(expect: viewModel.context.observe(\.leaveHandle).map { $0 != nil }.eraseToStream())
        LeaveSpaceView(context: noRoomsViewModel.context)
            .previewDisplayName("No Rooms")
            .snapshotPreferences(expect: viewModel.context.observe(\.leaveHandle).map { $0 != nil }.eraseToStream())
    }
    
    static func makeViewModel(mode: LeaveSpaceHandleProxy.Mode) -> SpaceScreenViewModel {
        let spaceRoomProxy = SpaceRoomProxyMock(.init(id: "!eng-space:matrix.org",
                                                      name: "Engineering Team",
                                                      isSpace: true,
                                                      parent: SpaceRoomProxyMock(.init(name: "MegaGroup", isSpace: true)),
                                                      childrenCount: 30,
                                                      joinedMembersCount: 76,
                                                      heroes: [.mockDan, .mockBob, .mockCharlie, .mockVerbose],
                                                      topic: "Description of the space goes right here. Lorem ipsum dolor sit amet consectetur. Leo viverra morbi habitant in.",
                                                      joinRule: .knockRestricted(rules: [.roomMembership(roomId: "")])))
        let spaceRoomListProxy = SpaceRoomListProxyMock(.init(spaceRoomProxy: spaceRoomProxy,
                                                              initialSpaceRooms: .mockSpaceList))
        
        let rooms: [LeaveSpaceRoom] = switch mode {
        case .manyRooms: .mockRooms
        case .onlyAdminRooms: .mockAdminRooms
        case .noRooms: []
        }
        let spaceServiceProxy = SpaceServiceProxyMock(.init(leaveSpaceRooms: rooms))
        
        let viewModel = SpaceScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                             spaceServiceProxy: spaceServiceProxy,
                                             selectedSpaceRoomPublisher: .init(nil),
                                             userSession: UserSessionMock(.init()),
                                             userIndicatorController: UserIndicatorControllerMock())
        viewModel.context.send(viewAction: .leaveSpace)
        return viewModel
    }
}
