//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

enum ElementCallServiceAction {
    case startCall(roomID: String)
    case endCall(roomID: String)
    case setAudioEnabled(_ enabled: Bool, roomID: String)
}

// sourcery: AutoMockable
protocol ElementCallServiceProtocol {
    var actions: AnyPublisher<ElementCallServiceAction, Never> { get }
    
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> { get }
    
    func setClientProxy(_ clientProxy: ClientProxyProtocol)
    
    func setupCallSession(roomID: String, roomDisplayName: String) async
    
    func tearDownCallSession()
    
    func setAudioEnabled(_ enabled: Bool, roomID: String)
}
