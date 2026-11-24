//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias RemoteLogoutScreenViewModelType = StateStoreViewModelV2<RemoteLogoutScreenViewState, RemoteLogoutScreenViewAction>

class RemoteLogoutScreenViewModel: RemoteLogoutScreenViewModelType, RemoteLogoutScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<RemoteLogoutScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RemoteLogoutScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSessionDetails: UserSessionDetails) {
        super.init(initialViewState: RemoteLogoutScreenViewState(userProfile: userSessionDetails.userProfile),
                   mediaProvider: userSessionDetails.mediaProvider)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RemoteLogoutScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .done:
            actionsSubject.send(.done)
        }
    }
}
