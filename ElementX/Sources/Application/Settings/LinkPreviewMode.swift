//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

/// Where link previews are fetched from, if at all.
nonisolated enum LinkPreviewMode: Codable {
    case off
    /// Asks the homeserver, which sees every previewed link, including ones from encrypted rooms.
    case homeserver
    /// Fetches on device with `LinkPresentation`, which exposes the device IP address to the linked site.
    case apple
    
    /// The mode for a room, unencrypted rooms only ever use the homeserver.
    /// - Parameter isRoomEncrypted: `nil` while the room's encryption state is unknown, which turns previews off.
    init(isRoomEncrypted: Bool?, userSettings: UserSettings) {
        switch isRoomEncrypted {
        case true:
            self = userSettings.app.encryptedRoomsLinkPreviewsMode
        case false:
            self = userSettings.app.unencryptedRoomsLinkPreviewsEnabled ? .homeserver : .off
        case nil:
            self = .off
        }
    }
}
