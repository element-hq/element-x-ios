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

typealias ServerSelectionViewModelType = StateStoreViewModel<ServerSelectionViewState, ServerSelectionViewAction>

class ServerSelectionViewModel: ServerSelectionViewModelType, ServerSelectionViewModelProtocol {
    var callback: (@MainActor (ServerSelectionViewModelAction) -> Void)?

    init(homeserverAddress: String, isModallyPresented: Bool) {
        let bindings = ServerSelectionBindings(homeserverAddress: homeserverAddress)
        
        super.init(initialViewState: ServerSelectionViewState(bindings: bindings,
                                                              isModallyPresented: isModallyPresented))
    }

    override func process(viewAction: ServerSelectionViewAction) async {
        switch viewAction {
        case .confirm:
            callback?(.confirm(homeserverAddress: state.bindings.homeserverAddress))
        case .dismiss:
            callback?(.dismiss)
        case .clearFooterError:
            clearFooterError()
        }
    }
    
    func displayError(_ type: ServerSelectionErrorType) {
        switch type {
        case .footerMessage(let message):
            withElementAnimation {
                state.footerErrorMessage = message
            }
        case .slidingSyncAlert:
            let openURL = { UIApplication.shared.open(ServiceLocator.shared.settings.slidingSyncLearnMoreURL) }
            state.bindings.alertInfo = AlertInfo(id: .slidingSyncAlert,
                                                 title: ElementL10n.serverSelectionSlidingSyncAlertTitle,
                                                 message: ElementL10n.serverSelectionSlidingSyncAlertMessage,
                                                 primaryButton: .init(title: ElementL10n.actionLearnMore, role: .cancel, action: openURL),
                                                 secondaryButton: .init(title: ElementL10n.actionCancel, action: nil))
        }
    }
    
    // MARK: - Private
    
    /// Clear any errors shown in the text field footer.
    private func clearFooterError() {
        guard state.footerErrorMessage != nil else { return }
        withElementAnimation { state.footerErrorMessage = nil }
    }
}
