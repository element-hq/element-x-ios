//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

class SpaceServiceProxy: SpaceServiceProxyProtocol {
    private let spaceService: SpaceServiceProtocol
    
    init(spaceService: SpaceServiceProtocol) {
        self.spaceService = spaceService
    }
    
    func joinedSpaces() -> [SpaceRoomProxyProtocol] {
        spaceService.joinedSpaces().map(SpaceRoomProxy.init)
    }
    
    func spaceRoomList(for spaceID: String) async -> Result<SpaceRoomListProxyProtocol, SpaceServiceProxyError> {
        do {
            return try await .success(SpaceRoomListProxy(spaceService.spaceRoomList(spaceId: spaceID)))
        } catch {
            MXLog.error("Failed creating space room list for \(spaceID): \(error)")
            return .failure(.sdkError(error))
        }
    }
}
