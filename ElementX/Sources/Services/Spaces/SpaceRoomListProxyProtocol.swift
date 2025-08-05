//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK

// sourcery: AutoMockable
protocol SpaceRoomListProxyProtocol {
    var spaceRoom: SpaceRoomProxyProtocol { get }
    
    var spaceRoomsPublisher: CurrentValuePublisher<[SpaceRoomProxyProtocol], Never> { get }
    var paginationStatePublisher: CurrentValuePublisher<SpaceRoomListPaginationState, Never> { get }
    
    func paginate() async
}
