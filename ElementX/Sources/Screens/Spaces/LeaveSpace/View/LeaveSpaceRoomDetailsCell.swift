//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LeaveSpaceRoomDetailsCell: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    let room: LeaveSpaceRoomDetails
    var hideSelection = false
    let mediaProvider: MediaProviderProtocol?
    
    let action: () -> Void
    
    private var subtitle: String? {
        guard !room.spaceServiceRoom.isSpace else { return nil }
        let memberCount = L10n.commonMemberCount(room.spaceServiceRoom.joinedMembersCount)
        return room.isLastAdmin ? L10n.screenLeaveSpaceLastAdminInfo(memberCount) : memberCount
    }
    
    var visibilityIcon: KeyPath<CompoundIcons, Image>? {
        switch room.spaceServiceRoom.visibility {
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
                    RoomAvatarImage(avatar: room.spaceServiceRoom.avatar,
                                    avatarSize: .room(on: .leaveSpace),
                                    mediaProvider: mediaProvider)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(room.spaceServiceRoom.name)
                        .font(.compound.bodyLGSemibold)
                        .foregroundStyle(.compound.textPrimary)
                        .lineLimit(1)
                        .padding(.vertical, 1)
                        .padding(.vertical, subtitle == nil ? 10 : 0)
                    
                    subtitleLabel
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                
                if !hideSelection {
                    ListRowAccessory.multiSelection(room.isSelected)
                }
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

struct LeaveSpaceRoomDetailsCell_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 0) {
            LeaveSpaceRoomDetailsCell(room: .init(spaceServiceRoom: SpaceServiceRoomMock(.init(id: "1",
                                                                                               name: "Space",
                                                                                               isSpace: true)),
                                                  isLastAdmin: false,
                                                  isSelected: true),
                                      mediaProvider: MediaProviderMock(configuration: .init())) { }
            LeaveSpaceRoomDetailsCell(room: .init(spaceServiceRoom: SpaceServiceRoomMock(.init(id: "2",
                                                                                               name: "My Space",
                                                                                               isSpace: true)),
                                                  isLastAdmin: true,
                                                  isSelected: false),
                                      mediaProvider: MediaProviderMock(configuration: .init())) { }
            LeaveSpaceRoomDetailsCell(room: .init(spaceServiceRoom: SpaceServiceRoomMock(.init(id: "2",
                                                                                               name: "My Space",
                                                                                               isSpace: true)),
                                                  isLastAdmin: true,
                                                  isSelected: false),
                                      hideSelection: true,
                                      mediaProvider: MediaProviderMock(configuration: .init())) { }
            LeaveSpaceRoomDetailsCell(room: .init(spaceServiceRoom: SpaceServiceRoomMock(.init(id: "3",
                                                                                               name: "Room",
                                                                                               isSpace: false)),
                                                  isLastAdmin: false,
                                                  isSelected: true),
                                      mediaProvider: MediaProviderMock(configuration: .init())) { }
            LeaveSpaceRoomDetailsCell(room: .init(spaceServiceRoom: SpaceServiceRoomMock(.init(id: "4",
                                                                                               name: "My Room",
                                                                                               isSpace: false)),
                                                  isLastAdmin: true,
                                                  isSelected: false),
                                      mediaProvider: MediaProviderMock(configuration: .init())) { }
            LeaveSpaceRoomDetailsCell(room: .init(spaceServiceRoom: SpaceServiceRoomMock(.init(id: "4",
                                                                                               name: "My Room",
                                                                                               isSpace: false)),
                                                  isLastAdmin: true,
                                                  isSelected: false),
                                      hideSelection: true,
                                      mediaProvider: MediaProviderMock(configuration: .init())) { }
        }
    }
}
