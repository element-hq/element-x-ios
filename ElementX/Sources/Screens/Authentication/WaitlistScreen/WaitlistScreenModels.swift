//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
    
    var iconSymbolName: String {
        if isWaiting {
            return "stopwatch"
        } else {
            return "sparkles"
        }
    }
    
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
