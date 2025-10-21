//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum PillUtilities {
    static let atRoom = "@room"

    /// Used by the WYSIWYG as the urlString value to identify @room mentions
    static let composerAtRoomURLString = "#"
    
    /// Used only to mock the max width in previews since the real max width is calculated by the line fragment width
    static let mockMaxWidth: CGFloat = 235
    
    private static let roomDecoration = "#"
    static func roomPillDisplayText(roomName: String?, rawRoomText: String) -> String {
        guard let roomName else {
            return rawRoomText
        }
        return "\(roomDecoration)\(roomName)"
    }
    
    private static let eventDecoration = "💬 > "
    static func eventPillDisplayText(roomName: String?, rawRoomText: String) -> String {
        guard let roomName else {
            return "\(eventDecoration)\(rawRoomText)"
        }
        return "\(eventDecoration)\(roomDecoration)\(roomName)"
    }
    
    private static let userDecoration = "@"
    static func userPillDisplayText(username: String?, userID: String) -> String {
        guard let username else {
            return userID
        }
        return "\(userDecoration)\(username)"
    }
}
