//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SpaceServiceProxyError: Error {
    case sdkError(Error)
    case missingSpace
}

// sourcery: AutoMockable
protocol SpaceServiceProxyProtocol {
    var joinedSpacesPublisher: CurrentValuePublisher<[SpaceRoomProxyProtocol], Never> { get }
    
    func spaceRoomList(spaceID: String) async -> Result<SpaceRoomListProxyProtocol, SpaceServiceProxyError>
    func leaveSpace(spaceID: String) async -> Result<LeaveSpaceHandleProxy, SpaceServiceProxyError>
}
