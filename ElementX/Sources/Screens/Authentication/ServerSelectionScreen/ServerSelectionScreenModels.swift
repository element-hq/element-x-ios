//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum ServerSelectionScreenViewModelAction {
    /// The user would like to use the homeserver at the given address.
    case confirm(homeserverAddress: String)
    /// Dismiss the view without using the entered address.
    case dismiss
}

struct ServerSelectionScreenViewState: BindableState {
    /// The message to be shown in the text field footer when no error has occurred.
    private let regularFooterMessage: AttributedString
    
    /// View state that can be bound to from SwiftUI.
    var bindings: ServerSelectionScreenBindings
    /// An error message to be shown in the text field footer.
    var footerErrorMessage: String?
    /// Whether the screen is presented modally or within a navigation stack.
    var isModallyPresented: Bool
    
    /// The message to show in the text field footer.
    var footerMessage: AttributedString {
        footerErrorMessage.map(AttributedString.init) ?? regularFooterMessage
    }
    
    /// The title shown on the confirm button.
    var buttonTitle: String {
        isModallyPresented ? L10n.actionContinue : L10n.actionNext
    }
    
    /// The text field is showing an error.
    var isShowingFooterError: Bool {
        footerErrorMessage != nil
    }
    
    /// Whether it is possible to continue when tapping the confirmation button.
    var hasValidationError: Bool {
        bindings.homeserverAddress.isEmpty || isShowingFooterError
    }
    
    init(slidingSyncLearnMoreURL: URL, bindings: ServerSelectionScreenBindings, footerErrorMessage: String? = nil, isModallyPresented: Bool) {
        self.bindings = bindings
        self.footerErrorMessage = footerErrorMessage
        self.isModallyPresented = isModallyPresented
        
        let linkPlaceholder = "{link}"
        var message = AttributedString(L10n.screenChangeServerFormNotice(linkPlaceholder))
        message.replace(linkPlaceholder,
                        with: L10n.actionLearnMore,
                        asLinkTo: slidingSyncLearnMoreURL)
        regularFooterMessage = message
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
}
