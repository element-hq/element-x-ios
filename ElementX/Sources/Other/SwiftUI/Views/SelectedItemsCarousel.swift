//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// A horizontally scrolling row of picked items, each shown as an avatar with a remove button above a label.
///
/// The row scrolls to show any item that gets added to it.
struct SelectedItemsCarousel: View {
    struct Item: Identifiable {
        enum Avatar {
            case user(url: URL?, name: String?, contentID: String)
            case room(RoomAvatar)
        }
        
        let id: String
        let title: String
        let avatar: Avatar
        /// Removes the item from the selection, or `nil` when the item can't be removed.
        let removeAction: (() -> Void)?
    }
    
    private let items: [Item]
    private let style: Style
    private let mediaProvider: MediaProviderProtocol?
    
    @ScaledMetric private var cellWidth: CGFloat
    @State private var scrollPosition: String?
    
    init(users: [UserProfile],
         mediaProvider: MediaProviderProtocol?,
         isRemovable: (UserProfile) -> Bool,
         removeAction: @escaping (UserProfile) -> Void) {
        let items = users.map { user in
            Item(id: user.id,
                 title: user.displayName ?? user.id,
                 avatar: .user(url: user.avatarURL, name: user.displayName, contentID: user.id),
                 removeAction: isRemovable(user) ? { removeAction(user) } : nil)
        }
        self.init(items: items, style: .users, mediaProvider: mediaProvider)
    }
    
    init(members: [RoomMemberDetails],
         mediaProvider: MediaProviderProtocol?,
         isRemovable: (RoomMemberDetails) -> Bool,
         removeAction: @escaping (RoomMemberDetails) -> Void) {
        let items = members.map { member in
            Item(id: member.id,
                 title: member.name ?? member.id,
                 avatar: .user(url: member.avatarURL, name: member.name, contentID: member.id),
                 removeAction: isRemovable(member) ? { removeAction(member) } : nil)
        }
        self.init(items: items, style: .members, mediaProvider: mediaProvider)
    }
    
    init(rooms: [SpaceAddRoomsScreenRoom],
         mediaProvider: MediaProviderProtocol?,
         removeAction: @escaping (SpaceAddRoomsScreenRoom) -> Void) {
        let items = rooms.map { room in
            Item(id: room.id, title: room.title, avatar: .room(room.avatar)) {
                removeAction(room)
            }
        }
        self.init(items: items, style: .rooms, mediaProvider: mediaProvider)
    }
    
    private init(items: [Item], style: Style, mediaProvider: MediaProviderProtocol?) {
        self.items = items
        self.style = style
        self.mediaProvider = mediaProvider
        _cellWidth = ScaledMetric(wrappedValue: style.cellWidth)
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: style.itemSpacing) {
                ForEach(items) { item in
                    cell(for: item)
                        .frame(width: cellWidth)
                }
            }
            .padding(.horizontal, style.horizontalPadding)
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollPosition, anchor: .trailing)
        .onChange(of: items.map(\.id)) { oldIDs, newIDs in
            scrollToAddedItem(oldIDs: oldIDs, newIDs: newIDs)
        }
    }
    
    private func cell(for item: Item) -> some View {
        VStack(spacing: style.labelSpacing) {
            avatar(for: item)
                .accessibilityHidden(true)
            
            Text(item.title)
                .font(style.labelFont)
                .foregroundStyle(style.labelColor)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            if let removeAction = item.removeAction {
                Button(style.removeActionTitle, action: removeAction)
            }
        }
    }
    
    @ViewBuilder
    private func avatar(for item: Item) -> some View {
        if let removeAction = item.removeAction {
            avatarImage(item.avatar)
                .overlayRemoveItemButton(action: removeAction)
        } else {
            avatarImage(item.avatar)
        }
    }
    
    @ViewBuilder
    private func avatarImage(_ avatar: Item.Avatar) -> some View {
        switch avatar {
        case .user(let url, let name, let contentID):
            LoadableAvatarImage(url: url,
                                name: name,
                                contentID: contentID,
                                avatarSize: style.avatarSize,
                                mediaProvider: mediaProvider)
        case .room(let roomAvatar):
            RoomAvatarImage(avatar: roomAvatar,
                            avatarSize: style.avatarSize,
                            mediaProvider: mediaProvider)
        }
    }
    
    private func scrollToAddedItem(oldIDs: [String], newIDs: [String]) {
        // A pick adds one item at a time, larger changes come from the list reloading.
        guard newIDs.count == oldIDs.count + 1,
              let addedID = newIDs.first(where: { !oldIDs.contains($0) }) else {
            return
        }
        withElementAnimation(.easeInOut) { scrollPosition = addedID }
    }
}

private extension SelectedItemsCarousel {
    /// The look of the carousel for each kind of item it shows.
    struct Style {
        let avatarSize: Avatars.Size
        let labelFont: Font
        let labelColor: Color
        let labelSpacing: CGFloat
        let cellWidth: CGFloat
        let itemSpacing: CGFloat
        let horizontalPadding: CGFloat
        let removeActionTitle: String
        
        static var users: Style {
            Style(avatarSize: .user(on: .inviteUsers),
                  labelFont: .compound.bodySM,
                  labelColor: .compound.textSecondary,
                  labelSpacing: 10,
                  cellWidth: 80,
                  itemSpacing: 8,
                  horizontalPadding: 16,
                  removeActionTitle: L10n.actionRemove)
        }
        
        static var members: Style {
            Style(avatarSize: .user(on: .roomChangeRoles),
                  labelFont: .compound.bodyMD,
                  labelColor: .compound.textPrimary,
                  labelSpacing: 4,
                  cellWidth: 72,
                  itemSpacing: 16,
                  horizontalPadding: 14,
                  removeActionTitle: L10n.actionDismiss)
        }
        
        static var rooms: Style {
            Style(avatarSize: .room(on: .spaceAddRoomsSelected),
                  labelFont: .compound.bodySM,
                  labelColor: .compound.textSecondary,
                  labelSpacing: 10,
                  cellWidth: 80,
                  itemSpacing: 8,
                  horizontalPadding: 16,
                  removeActionTitle: L10n.actionRemove)
        }
    }
}

// MARK: - Previews

struct SelectedItemsCarousel_Previews: PreviewProvider, TestablePreview {
    static let users: [UserProfile] = [.mockAlice, .mockVerbose, .mockBob]
    
    static let members: [RoomMemberDetails] = [
        RoomMemberProxyMock.mockAlice,
        RoomMemberProxyMock.mockDan,
        RoomMemberProxyMock.mockVerbose,
        RoomMemberProxyMock(with: .init(userID: "@someone:server.org", membership: .join)),
        RoomMemberProxyMock.mockAdmin
    ]
    .map { .init(withProxy: $0) }
    
    static let rooms: [SpaceAddRoomsScreenRoom] = [
        .init(id: "!selected:matrix.org",
              title: "Selected Room",
              description: "#selected:matrix.org",
              avatar: .room(id: "!selected:matrix.org", name: "Selected Room", avatarURL: .mockMXCAvatar)),
        .init(id: "!another:matrix.org",
              title: "Another room",
              description: "#another:matrix.org",
              avatar: .room(id: "!another:matrix.org", name: "Another room", avatarURL: nil))
    ]
    
    static var previews: some View {
        SelectedItemsCarousel(users: users,
                              mediaProvider: MediaProviderMock(.init()),
                              isRemovable: { $0.id != UserProfile.mockAlice.id },
                              removeAction: { _ in })
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Users")
        
        SelectedItemsCarousel(members: members,
                              mediaProvider: MediaProviderMock(.init()),
                              isRemovable: { $0.id != RoomMemberProxyMock.mockAdmin.userID },
                              removeAction: { _ in })
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Members")
        
        SelectedItemsCarousel(rooms: rooms,
                              mediaProvider: MediaProviderMock(.init())) { _ in }
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Rooms")
    }
}
