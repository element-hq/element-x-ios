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
    case callAnswered(roomID: String, isVoiceCall: Bool)
}

// sourcery: AutoMockable
/// The app's single owner of VoIP pushes and CallKit: decides what rings, and tracks the ringing and ongoing calls.
protocol ElementCallManagerProtocol: AnyObject {
    var actionsPublisher: AnyPublisher<ElementCallManagerAction, Never> { get }
    
    /// Forgets a call that was answered but never opened, which would otherwise count as a call in progress.
    func dropAnsweredCall(roomID: String)
}
