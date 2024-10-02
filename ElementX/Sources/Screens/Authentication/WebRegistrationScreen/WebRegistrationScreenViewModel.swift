//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias WebRegistrationScreenViewModelType = StateStoreViewModel<WebRegistrationScreenViewState, WebRegistrationScreenViewAction>

class WebRegistrationScreenViewModel: WebRegistrationScreenViewModelType, WebRegistrationScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<WebRegistrationScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<WebRegistrationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(registrationHelperURL: URL) {
        super.init(initialViewState: WebRegistrationScreenViewState(url: registrationHelperURL))
    }
    
    override func process(viewAction: WebRegistrationScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .cancel:
            actionsSubject.send(.cancel)
        case .signedIn(let credentials):
            actionsSubject.send(.signedIn(credentials))
        }
    }
}
