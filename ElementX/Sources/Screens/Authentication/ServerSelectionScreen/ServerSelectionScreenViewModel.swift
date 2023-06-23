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

typealias ServerSelectionScreenViewModelType = StateStoreViewModel<ServerSelectionScreenViewState, ServerSelectionScreenViewAction>

class ServerSelectionScreenViewModel: ServerSelectionScreenViewModelType, ServerSelectionScreenViewModelProtocol {
    private let slidingSyncLearnMoreURL: URL
    
    var callback: (@MainActor (ServerSelectionScreenViewModelAction) -> Void)?

    init(homeserverAddress: String, slidingSyncLearnMoreURL: URL, isModallyPresented: Bool) {
        self.slidingSyncLearnMoreURL = slidingSyncLearnMoreURL
        let bindings = ServerSelectionScreenBindings(homeserverAddress: homeserverAddress)
        
        super.init(initialViewState: ServerSelectionScreenViewState(slidingSyncLearnMoreURL: slidingSyncLearnMoreURL,
                                                                    bindings: bindings,
                                                                    isModallyPresented: isModallyPresented))
    }
    
    override func process(viewAction: ServerSelectionScreenViewAction) {
        switch viewAction {
        case .confirm:
            callback?(.confirm(homeserverAddress: state.bindings.homeserverAddress))
        case .dismiss:
            callback?(.dismiss)
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
        case .slidingSyncAlert:
            let openURL = { UIApplication.shared.open(self.slidingSyncLearnMoreURL) }
            state.bindings.alertInfo = AlertInfo(id: .slidingSyncAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorNoSlidingSyncMessage,
                                                 primaryButton: .init(title: L10n.actionLearnMore, role: .cancel, action: openURL),
                                                 secondaryButton: .init(title: L10n.actionCancel, action: nil))
        }
    }
    
    // MARK: - Private
    
    /// Clear any errors shown in the text field footer.
    private func clearFooterError() {
        guard state.footerErrorMessage != nil else { return }
        withElementAnimation { state.footerErrorMessage = nil }
    }
}
