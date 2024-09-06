//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum WaitlistScreenViewModelAction {
    case cancel
    case `continue`(UserSessionProtocol)
}

/// The user's credentials used to retry login and refresh the waiting list.
struct WaitlistScreenCredentials: CustomStringConvertible, CustomDebugStringConvertible {
    let username: String
    let password: String
    let initialDeviceName: String?
    let deviceID: String?
    
    let homeserver: LoginHomeserver
    
    var description: String { "Redacted" }
    var debugDescription: String { "Redacted" }
}

struct WaitlistScreenViewState: BindableState {
    /// The homeserver the user is waiting for.
    let homeserver: LoginHomeserver
    /// When refresh was successful, the user session that was returned by the login.
    var userSession: UserSessionProtocol?
    
    /// Whether or not the user is still waiting in the queue.
    var isWaiting: Bool { userSession == nil }
    
    var title: String {
        if isWaiting {
            return L10n.screenWaitlistTitle
        } else {
            return L10n.screenWaitlistTitleSuccess
        }
    }
    
    var message: String {
        if isWaiting {
            return L10n.screenWaitlistMessage(InfoPlistReader.main.bundleDisplayName, homeserver.address)
        } else {
            return L10n.screenWaitlistMessageSuccess(InfoPlistReader.main.bundleDisplayName)
        }
    }
}

enum WaitlistScreenViewAction {
    case cancel
    case `continue`(UserSessionProtocol)
}
