//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

extension SpaceRoomListProxyMock {
    class Configuration {
        var spaceServiceRoom: SpaceServiceRoomProtocol
        var initialSpaceRooms: [SpaceServiceRoomProtocol]
        var paginationStateSubject: CurrentValueSubject<SpaceRoomListPaginationState, Never>
        var paginationResponses: [[SpaceServiceRoomProtocol]]
        
        init(spaceServiceRoom: SpaceServiceRoomProtocol,
             initialSpaceRooms: [SpaceServiceRoomProtocol] = [],
             paginationStateSubject: CurrentValueSubject<SpaceRoomListPaginationState, Never> = .init(.idle(endReached: true)),
             paginationResponses: [[SpaceServiceRoomProtocol]] = []) {
            self.spaceServiceRoom = spaceServiceRoom
            self.initialSpaceRooms = initialSpaceRooms
            self.paginationStateSubject = paginationStateSubject
            self.paginationResponses = paginationResponses
        }
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        let spaceRoomsSubject: CurrentValueSubject<[SpaceServiceRoomProtocol], Never> = .init(configuration.initialSpaceRooms)
        
        id = configuration.spaceServiceRoom.id
        spaceServiceRoomPublisher = .init(configuration.spaceServiceRoom)
        spaceRoomsPublisher = spaceRoomsSubject.asCurrentValuePublisher()
        paginationStatePublisher = configuration.paginationStateSubject.asCurrentValuePublisher()
        
        paginateClosure = {
            configuration.paginationStateSubject.send(.loading)
            try? await Task.sleep(for: .milliseconds(100))
            let newRooms = configuration.paginationResponses.removeFirst()
            spaceRoomsSubject.send(spaceRoomsSubject.value + newRooms)
            configuration.paginationStateSubject.send(.idle(endReached: configuration.paginationResponses.isEmpty))
        }
    }
}
