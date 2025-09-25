//
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
    
    let spaceRoomProxy: SpaceRoomProxyProtocol
    let isSelected: Bool
    var isJoining = false
    let mediaProvider: MediaProviderProtocol!
    
    enum Action { case select(SpaceRoomProxyProtocol), join(SpaceRoomProxyProtocol) }
    let action: (Action) -> Void
    
    private let verticalInsets = 12.0
    private let horizontalInsets = 16.0
    
    private var subtitle: String {
        if spaceRoomProxy.isSpace {
            spaceRoomProxy.joinRule == .public ? L10n.commonPublicSpace : L10n.commonPrivateSpace
        } else {
            L10n.commonMemberCount(spaceRoomProxy.joinedMembersCount)
        }
    }
    
    private var details: String {
        if spaceRoomProxy.isSpace {
            L10n.screenSpaceListDetails(L10n.commonRooms(spaceRoomProxy.childrenCount),
                                        L10n.commonMemberCount(spaceRoomProxy.joinedMembersCount))
        } else {
            spaceRoomProxy.topic ?? " " // Use a single space to reserve a consistent amount of space.
        }
    }
    
    var body: some View {
        Button {
            action(.select(spaceRoomProxy))
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
        .accessibilityIdentifier(A11yIdentifiers.spaceListScreen.spaceRoomName(spaceRoomProxy.name ?? spaceRoomProxy.id))
    }
    
    @ViewBuilder @MainActor
    private var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: spaceRoomProxy.avatar,
                            avatarSize: .room(on: .spaces),
                            mediaProvider: mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
    
    private var content: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(spaceRoomProxy.computedName)
                    .font(.compound.bodyLGSemibold)
                    .foregroundColor(.compound.textPrimary)
                    .lineLimit(1)
                
                visibilityLabel
                
                Text(details)
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
            Text(subtitle)
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textSecondary)
                .lineLimit(1)
        } icon: {
            CompoundIcon(spaceRoomProxy.joinRule == .public ? \.public : \.lockSolid,
                         size: .xSmall,
                         relativeTo: .compound.bodyMD)
                .foregroundStyle(.compound.iconTertiary)
        }
        .labelStyle(.custom(spacing: 4))
    }
    
    @ViewBuilder
    private var accessory: some View {
        switch spaceRoomProxy.state {
        case .none, .left, .invited:
            Button(L10n.actionJoin) { action(.join(spaceRoomProxy)) }
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
    
    static let spaces = [SpaceRoomProxyProtocol].mockSpaceList
    
    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(spaces, id: \.id) { space in
                SpaceRoomCell(spaceRoomProxy: space,
                              isSelected: false,
                              mediaProvider: mediaProvider) { _ in }
            }
            
            SpaceRoomCell(spaceRoomProxy: SpaceRoomProxyMock(.init(id: "Space being joined", isSpace: true)),
                          isSelected: false,
                          isJoining: true,
                          mediaProvider: mediaProvider) { _ in }
            SpaceRoomCell(spaceRoomProxy: SpaceRoomProxyMock(.init(id: "Room being joined", isSpace: false)),
                          isSelected: false,
                          isJoining: true,
                          mediaProvider: mediaProvider) { _ in }
        }
    }
}
