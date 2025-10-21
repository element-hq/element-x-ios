//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK

enum SpaceRoomListProxyError: Error {
    case missingSpace
}

// sourcery: AutoMockable
protocol SpaceRoomListProxyProtocol {
    var id: String { get }
    
    var spaceRoomProxyPublisher: CurrentValuePublisher<SpaceRoomProxyProtocol, Never> { get }
    var spaceRoomsPublisher: CurrentValuePublisher<[SpaceRoomProxyProtocol], Never> { get }
    var paginationStatePublisher: CurrentValuePublisher<SpaceRoomListPaginationState, Never> { get }
    
    func paginate() async
}
