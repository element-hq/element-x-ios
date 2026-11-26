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
    private let mediaProvider: MediaProviderProtocol?
    
    @ScaledMetric private var cellWidth: CGFloat = 80
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
        self.init(items: items, mediaProvider: mediaProvider)
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
        self.init(items: items, mediaProvider: mediaProvider)
    }
    
    init(rooms: [SpaceAddRoomsScreenRoom],
         mediaProvider: MediaProviderProtocol?,
         removeAction: @escaping (SpaceAddRoomsScreenRoom) -> Void) {
        let items = rooms.map { room in
            Item(id: room.id, title: room.title, avatar: .room(room.avatar)) {
                removeAction(room)
            }
        }
        self.init(items: items, mediaProvider: mediaProvider)
    }
    
    private init(items: [Item], mediaProvider: MediaProviderProtocol?) {
        self.items = items
        self.mediaProvider = mediaProvider
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items) { item in
                    SelectedItemsCarouselCell(item: item, mediaProvider: mediaProvider)
                        .frame(width: cellWidth)
                }
            }
            .padding(.horizontal, 16)
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollPosition, anchor: .trailing)
        .onChange(of: items.map(\.id)) { oldIDs, newIDs in
            scrollToAddedItem(oldIDs: oldIDs, newIDs: newIDs)
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

/// A picked item in the carousel: its avatar with a remove button, above its title.
private struct SelectedItemsCarouselCell: View {
    let item: SelectedItemsCarousel.Item
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        VStack(spacing: 10) {
            avatar
                .accessibilityHidden(true)
            
            Text(item.title)
                .font(.compound.bodySM)
                .foregroundStyle(.compound.textSecondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            if let removeAction = item.removeAction {
                Button(L10n.actionRemove, action: removeAction)
            }
        }
    }
    
    @ViewBuilder
    private var avatar: some View {
        if let removeAction = item.removeAction {
            avatarImage
                .overlayRemoveItemButton(action: removeAction)
        } else {
            avatarImage
        }
    }
    
    @ViewBuilder
    private var avatarImage: some View {
        switch item.avatar {
        case .user(let url, let name, let contentID):
            LoadableAvatarImage(url: url,
                                name: name,
                                contentID: contentID,
                                avatarSize: .user(on: .selectedItemsCarousel),
                                mediaProvider: mediaProvider)
        case .room(let roomAvatar):
            RoomAvatarImage(avatar: roomAvatar,
                            avatarSize: .room(on: .selectedItemsCarousel),
                            mediaProvider: mediaProvider)
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
