//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum ClassicAppAccountConfirmationScreenViewModelAction {
    case loginDirectlyWithOIDC(data: OIDCAuthorizationDataProxy, window: UIWindow)
    case loginDirectlyWithPassword(loginHint: String)
}

struct ClassicAppAccountConfirmationScreenViewState: BindableState {
    let classicAppAccount: ClassicAppAccount
    var window: UIWindow?
    
    var bindings = ClassicAppAccountConfirmationScreenViewStateBindings()
    
    var title: String {
        classicAppAccount.displayName ?? classicAppAccount.userID
    }
    
    var subtitle: String? {
        classicAppAccount.displayName != nil ? classicAppAccount.userID : nil
    }
}

struct ClassicAppAccountConfirmationScreenViewStateBindings {
    var alertInfo: AlertInfo<ClassicAppAccountConfirmationScreenAlertType>?
}

enum ClassicAppAccountConfirmationScreenAlertType {
    case genericError
}

enum ClassicAppAccountConfirmationScreenViewAction {
    case `continue`
    case updateWindow(UIWindow)
}
