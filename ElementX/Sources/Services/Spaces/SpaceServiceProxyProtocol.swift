//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SpaceServiceProxyError: Error {
    case sdkError(Error)
}

// sourcery: AutoMockable
protocol SpaceServiceProxyProtocol {
    func joinedSpaces() -> [SpaceRoomProxyProtocol]
    func spaceRoomList(for spaceID: String) async -> Result<SpaceRoomListProxyProtocol, SpaceServiceProxyError>
}
