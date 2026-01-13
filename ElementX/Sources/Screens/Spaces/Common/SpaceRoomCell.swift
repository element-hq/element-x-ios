//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct SpaceRoomCell: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let spaceServiceRoom: SpaceServiceRoomProtocol
    let isSelected: Bool
    var isJoining = false
    let mediaProvider: MediaProviderProtocol!
    
    enum Action { case select(SpaceServiceRoomProtocol), join(SpaceServiceRoomProtocol) }
    let action: (Action) -> Void
    
    private let verticalInsets = 12.0
    private let horizontalInsets = 16.0
    
    private var subtitle: String {
        if spaceServiceRoom.isSpace {
            switch spaceServiceRoom.visibility {
            case .public: L10n.commonPublicSpace
            case .private: L10n.commonPrivateSpace
            case .restricted: L10n.commonSharedSpace
            case .none: L10n.commonPrivateSpace
            }
        } else {
            L10n.commonMemberCount(spaceServiceRoom.joinedMembersCount)
        }
    }
    
    var visibilityIcon: KeyPath<CompoundIcons, Image>? {
        switch spaceServiceRoom.visibility {
        case .public: \.public
        case .private: \.lockSolid
        case .restricted: nil
        case .none: \.lockSolid
        }
    }
    
    private var details: String {
        if spaceServiceRoom.isSpace {
            L10n.commonMemberCount(spaceServiceRoom.joinedMembersCount)
        } else {
            spaceServiceRoom.topic ?? " " // Use a single space to reserve a consistent amount of space.
        }
    }
    
    var body: some View {
        Button {
            action(.select(spaceServiceRoom))
        } label: {
            HStack(spacing: 16.0) {
                avatar
                
                content
                    .padding(.vertical, verticalInsets)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.compound.borderDisabled)
                            .frame(height: 1 / UIScreen.main.scale)
                            .padding(.trailing, -horizontalInsets)
                    }
            }
            .padding(.horizontal, horizontalInsets)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(SpaceRoomCellButtonStyle(isSelected: isSelected))
        .accessibilityIdentifier(A11yIdentifiers.spaceListScreen.spaceRoomName(spaceServiceRoom.name))
    }
    
    @ViewBuilder @MainActor
    private var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: spaceServiceRoom.avatar,
                            avatarSize: .room(on: .spaces),
                            mediaProvider: mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
    
    private var content: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(spaceServiceRoom.name)
                    .font(.compound.bodyLGSemibold)
                    .foregroundColor(.compound.textPrimary)
                    .lineLimit(1)
                
                subtitleLabel
                
                Text(details)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            accessory
        }
    }
    
    private var subtitleLabel: some View {
        Label {
            Text(subtitle)
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textSecondary)
                .lineLimit(1)
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
    
    @ViewBuilder
    private var accessory: some View {
        switch spaceServiceRoom.state {
        case .none, .left, .invited:
            Button(L10n.actionJoin) { action(.join(spaceServiceRoom)) }
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textActionAccent)
                .opacity(isJoining ? 0 : 1)
                .overlay {
                    if isJoining {
                        ProgressView()
                    }
                }
        case .joined, .knocked, .banned:
            EmptyView()
        }
    }
}

struct SpaceRoomCellButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isSelected || configuration.isPressed ? Color.compound.bgSubtleSecondary : Color.compound.bgCanvasDefault)
            .contentShape(Rectangle())
            .animation(isSelected ? .none : .easeOut(duration: 0.1).disabledDuringTests(), value: isSelected)
    }
}

struct SpaceRoomCell_Previews: PreviewProvider, TestablePreview {
    static let mediaProvider = MediaProviderMock(configuration: .init())
    
    static let spaces = [SpaceServiceRoomProtocol].mockSpaceList
    
    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(spaces, id: \.id) { space in
                SpaceRoomCell(spaceServiceRoom: space,
                              isSelected: false,
                              mediaProvider: mediaProvider) { _ in }
            }
            
            SpaceRoomCell(spaceServiceRoom: SpaceServiceRoomMock(.init(id: "Space being joined", isSpace: true)),
                          isSelected: false,
                          isJoining: true,
                          mediaProvider: mediaProvider) { _ in }
            SpaceRoomCell(spaceServiceRoom: SpaceServiceRoomMock(.init(id: "Room being joined", isSpace: false)),
                          isSelected: false,
                          isJoining: true,
                          mediaProvider: mediaProvider) { _ in }
        }
    }
}
