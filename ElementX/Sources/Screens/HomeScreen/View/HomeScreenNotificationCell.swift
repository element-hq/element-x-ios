//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeScreenNotificationCell: View {
    let room: HomeScreenRoom
    let context: HomeScreenViewModel.Context
    
    var notificationText: AttributedString {
        let isRoomDM = room.isDirect
        let baseText: String

        switch room.type {
        case .invite:
            baseText = isRoomDM ? "\(room.name) invited you to chat" : "You are invited to join \(room.name)"
        case .room:
            baseText = room.unreadNotificationsCount > 1 ?
            "\(room.unreadNotificationsCount) messages in \(room.name)" :
            "\(room.unreadNotificationsCount) message in \(room.name)"
        default:
            baseText = "You may have new messages in \(room.name)"
        }
        
        var attributedText = AttributedString(baseText)
        if let roomNameRange = attributedText.range(of: room.name) {
            attributedText[roomNameRange].foregroundColor = .compound.textPrimary
        }
        if room.unreadNotificationsCount >= 1, let unreadCountRange = attributedText.range(of: String(room.unreadNotificationsCount)) {
            attributedText[unreadCountRange].foregroundColor = .compound.textPrimary
        }
        return attributedText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                RoomAvatarImage(avatar: room.avatar,
                                avatarSize: .room(on: .notificationSettings),
                                mediaProvider: context.mediaProvider)
                    .accessibilityHidden(true)
                
                Text(notificationText)
                    .font(.zero.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .lineSpacing(2)
                
                Spacer()
            }
            .padding()
            
            // Divider()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            context.send(viewAction: .selectRoom(roomIdentifier: room.id))
        }
    }
}
