//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

/// Information about a room avatar such as it's URL or the heroes to use as a fallback.
enum RoomAvatar: Equatable {
    /// An avatar generated from the room's details.
    case room(id: String, name: String?, avatarURL: URL?)
    /// An avatar generated from the room's heroes.
    case heroes([UserProfileProxy])
}

/// A view that shows the avatar for a room, or a cluster of heroes if provided.
///
/// This should be preferred over `LoadableAvatarImage` when displaying a
/// room avatar so that DMs have a consistent appearance throughout the app.
struct RoomAvatarImage: View {
    let avatar: RoomAvatar
    
    let avatarSize: AvatarSize
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        switch avatar {
        case .room(let id, let name, let avatarURL):
            LoadableAvatarImage(url: avatarURL,
                                name: name,
                                contentID: id,
                                avatarSize: avatarSize,
                                mediaProvider: mediaProvider)
        case .heroes(let users):
            // We will expand upon this with more stack sizes in the future.
            if users.count == 0 {
                let _ = assertionFailure("We should never pass empty heroes here.")
                PlaceholderAvatarImage(name: nil, contentID: nil)
            } else if users.count == 2 {
                let clusterSize = avatarSize.value * 1.6
                ZStack {
                    LoadableAvatarImage(url: users[0].avatarURL,
                                        name: users[0].displayName,
                                        contentID: users[0].userID,
                                        avatarSize: avatarSize,
                                        mediaProvider: mediaProvider)
                        .scaledFrame(size: clusterSize, alignment: .topTrailing)
                    
                    LoadableAvatarImage(url: users[1].avatarURL,
                                        name: users[1].displayName,
                                        contentID: users[1].userID,
                                        avatarSize: avatarSize,
                                        mediaProvider: mediaProvider)
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
                                    mediaProvider: mediaProvider)
            }
        }
    }
}

struct RoomAvatarImage_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        HStack(spacing: 8) {
            RoomAvatarImage(avatar: .room(id: "!1:server.com",
                                          name: "Room",
                                          avatarURL: nil),
                            avatarSize: .room(on: .home),
                            mediaProvider: MockMediaProvider())
            
            RoomAvatarImage(avatar: .room(id: "!2:server.com",
                                          name: "Room",
                                          avatarURL: .picturesDirectory),
                            avatarSize: .room(on: .home),
                            mediaProvider: MockMediaProvider())
            
            RoomAvatarImage(avatar: .heroes([.init(userID: "@user:server.com",
                                                   displayName: "User",
                                                   avatarURL: nil)]),
            avatarSize: .room(on: .home),
            mediaProvider: MockMediaProvider())
            
            RoomAvatarImage(avatar: .heroes([.init(userID: "@user:server.com",
                                                   displayName: "User",
                                                   avatarURL: .picturesDirectory)]),
            avatarSize: .room(on: .home),
            mediaProvider: MockMediaProvider())
            
            RoomAvatarImage(avatar: .heroes([.init(userID: "@alice:server.com", displayName: "Alice", avatarURL: nil),
                                             .init(userID: "@bob:server.net", displayName: "Bob", avatarURL: nil)]),
                            avatarSize: .room(on: .home),
                            mediaProvider: MockMediaProvider())
        }
    }
}
