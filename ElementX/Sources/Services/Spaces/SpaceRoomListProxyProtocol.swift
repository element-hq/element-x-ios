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
    
    var spaceServiceRoomPublisher: CurrentValuePublisher<SpaceServiceRoom, Never> { get }
    var spaceRoomsPublisher: CurrentValuePublisher<[SpaceServiceRoom], Never> { get }
    var paginationStatePublisher: CurrentValuePublisher<SpaceRoomListPaginationState, Never> { get }
    
    func paginate() async
    func reset() async
}

extension SpaceRoomListProxyProtocol {
    /// Resets the list and then waits everything to be paginated back in again before returning.
    ///
    /// **Note:** It's the caller's responsibility to handle the calls to ``paginate``. This method
    /// purely acts as a helper to wait until the list has reloaded.
    func resetAndWaitForFullReload(timeout: Duration) async {
        await reset()
        
        let runner = ExpiringTaskRunner { [paginationStatePublisher] in
            await _ = paginationStatePublisher.values.first { $0 == .idle(endReached: true) }
        }
        try? await runner.run(timeout: timeout)
    }
}
