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
    var topLevelSpacesPublisher: CurrentValuePublisher<[SpaceServiceRoomProtocol], Never> { get }
    
    func spaceRoomList(spaceID: String) async -> Result<SpaceRoomListProxyProtocol, SpaceServiceProxyError>
    /// Returns a joined space given its identifier
    func spaceForIdentifier(spaceID: String) async -> Result<SpaceServiceRoomProtocol?, SpaceServiceProxyError>
    func leaveSpace(spaceID: String) async -> Result<LeaveSpaceHandleProxy, SpaceServiceProxyError>
    /// Returns all the parent spaces of a child that user has joined.
    func joinedParents(childID: String) async -> Result<[SpaceServiceRoomProtocol], SpaceServiceProxyError>
}
