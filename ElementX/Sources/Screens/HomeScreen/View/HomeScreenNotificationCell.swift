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
    
    var notificationText: String {
        let isRoomDM = room.isDirect

        switch room.type {
        case .invite:
            return isRoomDM ? "\(room.name) invited you to chat" : "You are invited to join \(room.name)"
        case .room:
            if isRoomDM {
                return room.unreadNotificationsCount > 1 ?
                    "\(room.name) sent you new messages" :
                    "\(room.name) sent you a new message"
            } else {
                return room.unreadNotificationsCount > 1 ?
                    "You have \(room.unreadNotificationsCount) new messages in \(room.name)" :
                    "You have a new message in \(room.name)"
            }
        default:
            return "You may have new messages in \(room.name)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(notificationText)
                .font(.zero.bodyMD)
                .foregroundStyle(.compound.textSecondary)
                .padding()
            
            Divider()
        }
        .onTapGesture {
            context.send(viewAction: .selectRoom(roomIdentifier: room.id))
        }
    }
}
