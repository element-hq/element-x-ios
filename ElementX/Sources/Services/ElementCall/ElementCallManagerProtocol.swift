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
    /// What the call screen has to do, whichever account's call it shows.
    case callScreen(CallScreenPresentation)
}

/// The call screen the manager wants on screen. Only one call shows at a time, so only presenting names the call.
enum CallScreenPresentation: Equatable {
    enum Kind: Equatable {
        /// The Element Call web view, which needs the room to load the call.
        case webView(ElementCallServiceAction.RoomCall)
        /// The account's native call stack, which already knows its call.
        case native
    }
    
    case present(userID: String, kind: Kind)
    case minimize
    case restore
    case dismiss
}

// sourcery: AutoMockable
/// The app's single owner of VoIP pushes, CallKit and the calls of every account: decides what rings,
/// what the call screen shows, and tracks the ringing and ongoing calls.
protocol ElementCallManagerProtocol: AnyObject {
    var actionsPublisher: AnyPublisher<ElementCallManagerAction, Never> { get }
    
    /// Routes the account's calls through its service, replacing the one it had before.
    func add(_ service: ElementCallServiceProtocol)
    /// Stops routing the account's calls.
    func remove(userID: String)
    /// Ends the account's calls and takes their screen down, still routing its calls.
    func endCalls(userID: String)
    
    /// Opens the room's call for the account, keeping the request pending until the account's service is added.
    func requestCall(userID: String, roomID: String, isVoiceCall: Bool, answeredFromCallKit: Bool)
    
    /// Forgets a call that was answered but never opened, which would otherwise count as a call in progress.
    func dropAnsweredCall(userID: String, roomID: String)
}
