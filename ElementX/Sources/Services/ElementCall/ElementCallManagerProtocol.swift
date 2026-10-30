//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

enum ElementCallManagerAction: Equatable {
    /// A VoIP push rang, which iOS delivers without starting the app's services.
    case incomingCallReported
    case callAnswered(userID: String, roomID: String, isVoiceCall: Bool)
}

// sourcery: AutoMockable
/// The app's single owner of VoIP pushes and CallKit: decides what rings, and tracks the ringing and ongoing calls.
protocol ElementCallManagerProtocol: AnyObject {
    var actionsPublisher: AnyPublisher<ElementCallManagerAction, Never> { get }
    
    /// Routes the account's calls through its service, replacing the one it had before.
    func add(_ service: ElementCallServiceProtocol)
    /// Stops routing the account's calls.
    func remove(userID: String)
    
    /// Forgets a call that was answered but never opened, which would otherwise count as a call in progress.
    func dropAnsweredCall(userID: String, roomID: String)
}
