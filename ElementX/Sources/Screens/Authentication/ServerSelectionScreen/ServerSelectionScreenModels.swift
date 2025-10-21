//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ServerSelectionScreenViewModelAction {
    /// The homeserver selection has been updated.
    case updated
    /// Dismiss the view without using the entered address.
    case dismiss
}

struct ServerSelectionScreenViewState: BindableState {
    /// The message to be shown in the text field footer when no error has occurred.
    private let regularFooterMessage = L10n.screenChangeServerFormNotice
    
    /// View state that can be bound to from SwiftUI.
    var bindings: ServerSelectionScreenBindings
    /// An error message to be shown in the text field footer.
    var footerErrorMessage: String?
    
    /// The message to show in the text field footer.
    var footerMessage: String {
        footerErrorMessage ?? regularFooterMessage
    }
    
    /// The text field is showing an error.
    var isShowingFooterError: Bool {
        footerErrorMessage != nil
    }
    
    /// Whether it is possible to continue when tapping the confirmation button.
    var hasValidationError: Bool {
        bindings.homeserverAddress.isEmpty || isShowingFooterError
    }
}

struct ServerSelectionScreenBindings {
    /// The homeserver address input by the user.
    var homeserverAddress: String
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<ServerSelectionScreenErrorType>?
}

enum ServerSelectionScreenViewAction {
    /// The user would like to use the homeserver at the input address.
    case confirm
    /// Dismiss the view without using the entered address.
    case dismiss
    /// Clear any errors shown in the text field footer.
    case clearFooterError
}

enum ServerSelectionScreenErrorType: Hashable {
    /// An error message to be shown in the text field footer.
    case footerMessage(String)
    /// An alert that informs the user about a bad well-known file.
    case invalidWellKnownAlert(String)
    /// An alert that allows the user to learn about sliding sync.
    case slidingSyncAlert
    /// An alert that informs the user that login isn't supported.
    case loginAlert
    /// An alert that informs the user that registration isn't supported.
    case registrationAlert
    /// An alert that informs the user that Element Pro should be used for a particular server.
    case elementProAlert
}
