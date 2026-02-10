//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Information about a room avatar such as it's URL or the heroes to use as a fallback.
enum RoomAvatar: Equatable {
    /// An avatar generated from a Room's details.
    case room(id: String, name: String?, avatarURL: URL?)
    /// An avatar generated from a collection of room heroes.
    case heroes([UserProfileProxy])
    /// An avatar generated from a Space's details.
    case space(id: String, name: String?, avatarURL: URL?)
    /// A static avatar for a tombstoned room.
    case tombstoned
    
    var removingAvatar: RoomAvatar {
        switch self {
        case let .room(id, name, _):
            .room(id: id, name: name, avatarURL: nil)
        case let .heroes(users):
            .heroes(users.map { .init(userID: $0.userID, displayName: $0.displayName, avatarURL: nil) })
        case .space(let id, let name, _):
            .space(id: id, name: name, avatarURL: nil)
        case .tombstoned:
            .tombstoned
        }
    }
    
    var hasURL: Bool {
        switch self {
        case let .room(_, _, url),
             let .space(_, _, url):
            return url != nil
        case let .heroes(heroes):
            return heroes.first?.avatarURL != nil
        case .tombstoned:
            return false
        }
    }
}

/// A view that shows the avatar for a room, or a cluster of heroes if provided.
///
/// This should be preferred over `LoadableAvatarImage` when displaying a
/// room avatar so that DMs have a consistent appearance throughout the app.
struct RoomAvatarImage: View {
    let avatar: RoomAvatar
    
    let avatarSize: Avatars.Size
    let mediaProvider: MediaProviderProtocol?
    
    private(set) var onAvatarTap: ((URL) -> Void)?
    
    var body: some View {
        switch avatar {
        case .room(let id, let name, let avatarURL):
            LoadableAvatarImage(url: avatarURL,
                                name: name,
                                contentID: id,
                                avatarSize: avatarSize,
                                mediaProvider: mediaProvider,
                                onTap: onAvatarTap)
        case .heroes(let users):
            // We will expand upon this with more stack sizes in the future.
            if users.count == 0 {
                let _ = assertionFailure("We should never pass empty heroes here.")
                PlaceholderAvatarImage(name: nil, contentID: "")
            } else if users.count == 2 {
                let clusterSize = avatarSize.value * 1.6
                ZStack {
                    LoadableAvatarImage(url: users[0].avatarURL,
                                        name: users[0].displayName,
                                        contentID: users[0].userID,
                                        avatarSize: avatarSize,
                                        mediaProvider: mediaProvider,
                                        onTap: onAvatarTap)
                        .scaledFrame(size: clusterSize, alignment: .topTrailing)
                    
                    LoadableAvatarImage(url: users[1].avatarURL,
                                        name: users[1].displayName,
                                        contentID: users[1].userID,
                                        avatarSize: avatarSize,
                                        mediaProvider: mediaProvider,
                                        onTap: onAvatarTap)
                        .mask {
                            Rectangle()
                                .fill(Color.white)
                                .overlay {
                                    Circle()
                                        .inset(by: -4)
                                        .fill(Color.black)
                                        .scaledOffset(x: clusterSize - avatarSize.value,
                                                      y: -clusterSize + avatarSize.value)
                                }
                                .compositingGroup()
                                .luminanceToAlpha()
                        }
                        .scaledFrame(size: clusterSize, alignment: .bottomLeading)
                }
                .scaledFrame(size: clusterSize)
            } else {
                LoadableAvatarImage(url: users[0].avatarURL,
                                    name: users[0].displayName,
                                    contentID: users[0].userID,
                                    avatarSize: avatarSize,
                                    mediaProvider: mediaProvider,
                                    onTap: onAvatarTap)
            }
        case .space(let id, let name, let avatarURL):
            LoadableAvatarImage(url: avatarURL,
                                name: name,
                                contentID: id,
                                shape: .roundedRect,
                                avatarSize: avatarSize,
                                mediaProvider: mediaProvider,
                                onTap: onAvatarTap)
        case .tombstoned:
            TombstonedAvatarImage(avatarSize: avatarSize)
        }
    }
}

struct RoomAvatarImage_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                RoomAvatarImage(avatar: .room(id: "!1:server.com",
                                              name: "Room",
                                              avatarURL: nil),
                                avatarSize: .room(on: .chats),
                                mediaProvider: MediaProviderMock(configuration: .init()))
                
                RoomAvatarImage(avatar: .room(id: "!2:server.com",
                                              name: "Room",
                                              avatarURL: .mockMXCAvatar),
                                avatarSize: .room(on: .chats),
                                mediaProvider: MediaProviderMock(configuration: .init()))
                
                RoomAvatarImage(avatar: .space(id: "!space:server.com",
                                               name: "Room",
                                               avatarURL: nil),
                                avatarSize: .room(on: .chats),
                                mediaProvider: MediaProviderMock(configuration: .init()))
                
                RoomAvatarImage(avatar: .space(id: "!otherspace:server.com",
                                               name: "Room",
                                               avatarURL: .mockMXCAvatar),
                                avatarSize: .room(on: .chats),
                                mediaProvider: MediaProviderMock(configuration: .init()))
                
                RoomAvatarImage(avatar: .tombstoned, avatarSize: .room(on: .chats), mediaProvider: MediaProviderMock(configuration: .init()))
            }
            
            HStack(spacing: 12) {
                RoomAvatarImage(avatar: .heroes([.init(userID: "@user:server.com",
                                                       displayName: "User",
                                                       avatarURL: nil)]),
                avatarSize: .room(on: .chats),
                mediaProvider: MediaProviderMock(configuration: .init()))
                
                RoomAvatarImage(avatar: .heroes([.init(userID: "@user:server.com",
                                                       displayName: "User",
                                                       avatarURL: .mockMXCAvatar)]),
                avatarSize: .room(on: .chats),
                mediaProvider: MediaProviderMock(configuration: .init()))
                
                RoomAvatarImage(avatar: .heroes([.init(userID: "@alice:server.com", displayName: "Alice", avatarURL: nil),
                                                 .init(userID: "@bob:server.net", displayName: "Bob", avatarURL: nil)]),
                                avatarSize: .room(on: .chats),
                                mediaProvider: MediaProviderMock(configuration: .init()))
            }
        }
    }
}
