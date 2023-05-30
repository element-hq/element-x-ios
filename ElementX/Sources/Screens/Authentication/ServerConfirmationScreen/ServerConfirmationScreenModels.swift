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

import SwiftUI

enum ServerConfirmationScreenViewModelAction {
    /// The user would like to continue with the current homeserver.
    case confirm
    /// The user would like to change to a different homeserver.
    case changeServer
}

struct ServerConfirmationScreenViewState: BindableState {
    /// The homeserver address input by the user.
    var homeserverAddress: String
    /// The flow being attempted on the selected homeserver.
    let authenticationFlow: AuthenticationFlow
    /// The presentation anchor used for OIDC authentication.
    var window: UIWindow?
    
    /// The screen's title.
    var title: String {
        switch authenticationFlow {
        case .login:
            return L10n.screenServerConfirmationTitleLogin(homeserverAddress)
        case .register:
            return L10n.screenServerConfirmationTitleRegister(homeserverAddress)
        }
    }
    
    /// The message shown beneath the title.
    var message: String {
        switch authenticationFlow {
        case .login:
            if homeserverAddress == "matrix.org" {
                return L10n.screenServerConfirmationMessageLoginMatrixDotOrg
            } else if homeserverAddress == "element.io" {
                return L10n.screenServerConfirmationMessageLoginElementDotIo
            } else {
                return ""
            }
        case .register:
            return L10n.screenServerConfirmationMessageRegister
        }
    }
}

enum ServerConfirmationScreenViewAction {
    /// Updates the window used as the OIDC presentation anchor.
    case updateWindow(UIWindow)
    /// The user would like to continue with the current homeserver.
    case confirm
    /// The user would like to change to a different homeserver.
    case changeServer
}
