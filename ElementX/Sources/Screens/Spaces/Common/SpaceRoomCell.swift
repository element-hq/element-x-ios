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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.editMode) private var editMode
    
    let spaceServiceRoom: SpaceServiceRoom
    let isSelected: Bool
    var isJoining = false
    let mediaProvider: MediaProviderProtocol!
    
    enum Action { case select(SpaceServiceRoom), join(SpaceServiceRoom) }
    let action: (Action) -> Void
    
    private let verticalInsets = 12.0
    private let horizontalInsets = 16.0
    
    private var isEditModeActive: Bool {
        editMode?.wrappedValue ?? .inactive != .inactive
    }

    private var isHighlighted: Bool {
        isSelected && !isEditModeActive
    }
    
    private var visibilityTitle: String {
        switch spaceServiceRoom.visibility {
        case .public: L10n.commonPublic
        case .private: L10n.commonPrivate
        case .restricted: L10n.commonSpaceMembers
        case .none: L10n.commonPrivate
        }
    }
    
    var visibilityIcon: KeyPath<CompoundIcons, Image> {
        switch spaceServiceRoom.visibility {
        case .public: \.public
        case .private: \.lockSolid
        case .restricted: \.spaceSolid
        case .none: \.lockSolid
        }
    }
    
    var body: some View {
        Button {
            action(.select(spaceServiceRoom))
        } label: {
            HStack(spacing: 0) {
                if isEditModeActive,
                   !spaceServiceRoom.isSpace { // We only support selection of rooms (so don't show this while removing the cell).
                    ZStack {
                        ListRowAccessory.multiSelection(isSelected)
                    }
                    // Use padding rather than spacing to improve the animation.
                    .padding(.trailing, 16)
                    // Put the transition on a ZStack to prevent it from being applied during selection/deselection.
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                HStack(spacing: 16) {
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
            }
            .padding(.horizontal, horizontalInsets)
            // Ensure the EditMode transition stays inside this cell if there are other insertions/removals in the list.
            // Seems to slow down the animations a bit in Xcode previews but its fine in the simulator and on a device.
            .drawingGroup()
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(SpaceRoomCellButtonStyle(isHighlighted: isHighlighted))
        .accessibilityIdentifier(A11yIdentifiers.spacesScreen.spaceRoomName(spaceServiceRoom.name))
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
                
                visibilityLabel
                
                Text(L10n.commonMemberCount(spaceServiceRoom.joinedMembersCount))
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            accessory
        }
    }
    
    private var visibilityLabel: some View {
        Label {
            Text(visibilityTitle)
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textSecondary)
                .lineLimit(1)
        } icon: {
            CompoundIcon(visibilityIcon,
                         size: .xSmall,
                         relativeTo: .compound.bodyMD)
                .foregroundStyle(.compound.iconTertiary)
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
    let isHighlighted: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isHighlighted || configuration.isPressed ? Color.compound.bgSubtleSecondary : Color.compound.bgCanvasDefault)
            .contentShape(Rectangle())
            .animation(isHighlighted ? .none : .easeOut(duration: 0.1).disabledDuringTests(), value: isHighlighted)
    }
}

struct SpaceRoomCell_Previews: PreviewProvider, TestablePreview {
    static let mediaProvider = MediaProviderMock(configuration: .init())
    
    static let spaces = [SpaceServiceRoom].mockSpaceList
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(spaces, id: \.id) { space in
                    SpaceRoomCell(spaceServiceRoom: space,
                                  isSelected: false,
                                  mediaProvider: mediaProvider) { _ in }
                }
                
                SpaceRoomCell(spaceServiceRoom: SpaceServiceRoom.mock(id: "Space being joined", isSpace: true),
                              isSelected: false,
                              isJoining: true,
                              mediaProvider: mediaProvider) { _ in }
                SpaceRoomCell(spaceServiceRoom: SpaceServiceRoom.mock(id: "Room being joined", isSpace: false),
                              isSelected: false,
                              isJoining: true,
                              mediaProvider: mediaProvider) { _ in }
                
                SpaceRoomCell(spaceServiceRoom: SpaceServiceRoom.mock(id: "Selected", isSpace: false, state: .joined),
                              isSelected: true,
                              isJoining: false,
                              mediaProvider: mediaProvider) { _ in }
                    .environment(\.editMode, .constant(.active))
                SpaceRoomCell(spaceServiceRoom: SpaceServiceRoom.mock(id: "Unselected", isSpace: false, state: .joined),
                              isSelected: false,
                              isJoining: false,
                              mediaProvider: mediaProvider) { _ in }
                    .environment(\.editMode, .constant(.active))
            }
        }
        .previewLayout(.fixed(width: 390, height: 850))
    }
}
