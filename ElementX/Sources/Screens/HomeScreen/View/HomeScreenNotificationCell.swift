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
            if isRoomDM {
                baseText = room.unreadNotificationsCount > 1 ?
                    "\(room.name) sent you \(room.unreadNotificationsCount) new messages" :
                    "\(room.name) sent you a new message"
            } else {
                baseText = room.unreadNotificationsCount > 1 ?
                    "You have \(room.unreadNotificationsCount) new messages in \(room.name)" :
                    "You have a new message in \(room.name)"
            }
        default:
            baseText = "You may have new messages in \(room.name)"
        }
        
        var attributedText = AttributedString(baseText)
        let roomNameRange = attributedText.range(of: room.name)!
        attributedText[roomNameRange].font = .compound.bodyMDSemibold
        if room.unreadNotificationsCount > 1 {
            let unreadCountRange = attributedText.range(of: String(room.unreadNotificationsCount))!
            attributedText[unreadCountRange].font = .compound.bodyMDSemibold
        }
        return attributedText
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(notificationText)
                .font(.zero.bodyMD)
                .foregroundStyle(.compound.textPrimary)
                .padding()
            
            Divider()
        }
        .onTapGesture {
            context.send(viewAction: .selectRoom(roomIdentifier: room.id))
        }
    }
}
