//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A preview object for the Room. useful to get all the possible info for rooms to which the user is not invited to
protocol RoomPreviewProxyProtocol {
    var info: RoomPreviewInfoProxy { get }
    var ownMembershipDetails: RoomMembershipDetailsProxyProtocol? { get async }
}

// sourcery: AutoMockable
extension RoomPreviewProxyProtocol { }
