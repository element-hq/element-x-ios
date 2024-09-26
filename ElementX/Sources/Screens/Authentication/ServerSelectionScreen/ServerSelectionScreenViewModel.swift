//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias ServerSelectionScreenViewModelType = StateStoreViewModel<ServerSelectionScreenViewState, ServerSelectionScreenViewAction>

class ServerSelectionScreenViewModel: ServerSelectionScreenViewModelType, ServerSelectionScreenViewModelProtocol {
    private let slidingSyncLearnMoreURL: URL
    
    private var actionsSubject: PassthroughSubject<ServerSelectionScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ServerSelectionScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(homeserverAddress: String, slidingSyncLearnMoreURL: URL) {
        self.slidingSyncLearnMoreURL = slidingSyncLearnMoreURL
        let bindings = ServerSelectionScreenBindings(homeserverAddress: homeserverAddress)
        
        super.init(initialViewState: ServerSelectionScreenViewState(slidingSyncLearnMoreURL: slidingSyncLearnMoreURL,
                                                                    bindings: bindings))
    }
    
    override func process(viewAction: ServerSelectionScreenViewAction) {
        switch viewAction {
        case .confirm:
            actionsSubject.send(.confirm(homeserverAddress: state.bindings.homeserverAddress))
        case .dismiss:
            actionsSubject.send(.dismiss)
        case .clearFooterError:
            clearFooterError()
        }
    }
    
    func displayError(_ type: ServerSelectionScreenErrorType) {
        switch type {
        case .footerMessage(let message):
            withElementAnimation {
                state.footerErrorMessage = message
            }
        case .invalidWellKnownAlert(let error):
            state.bindings.alertInfo = AlertInfo(id: .invalidWellKnownAlert(error),
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorInvalidWellKnown(error))
        case .slidingSyncAlert:
            let openURL = { UIApplication.shared.open(self.slidingSyncLearnMoreURL) }
            state.bindings.alertInfo = AlertInfo(id: .slidingSyncAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorNoSlidingSyncMessage,
                                                 primaryButton: .init(title: L10n.actionLearnMore, role: .cancel, action: openURL),
                                                 secondaryButton: .init(title: L10n.actionCancel, action: nil))
        case .registrationAlert:
            state.bindings.alertInfo = AlertInfo(id: .registrationAlert,
                                                 title: L10n.errorUnknown,
                                                 message: L10n.errorAccountCreationNotPossible)
        }
    }
    
    // MARK: - Private
    
    /// Clear any errors shown in the text field footer.
    private func clearFooterError() {
        guard state.footerErrorMessage != nil else { return }
        withElementAnimation { state.footerErrorMessage = nil }
    }
}
