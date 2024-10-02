//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum PillConstants {
    static let atRoom = "@room"
    static var everyone: String {
        L10n.commonEveryone
    }

    /// Used by the WYSIWYG as the urlString value to identify @room mentions
    static let composerAtRoomURLString = "#"
    
    /// Used only to mock the max width in previews since the real max width is calculated by the line fragment width
    static let mockMaxWidth: CGFloat = 235
}
