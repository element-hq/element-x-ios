//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ZeroProSubcriptionScreenViewModelType = StateStoreViewModel<ZeroProSubcriptionScreenViewState, ZeroProSubcriptionScreenViewAction>

class ZeroProSubcriptionScreenViewModel:
    ZeroProSubcriptionScreenViewModelType,
    ZeroProSubcriptionScreenViewModelProtocol {
    init(userSession: UserSessionProtocol) {
        
        super.init(
            initialViewState: .init(bindings: .init())
        )
        
        userSession.clientProxy.zeroCurrentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                self?.state.isZeroProSubscriber = currentUser.subscriptions.zeroPro
            }
            .store(in: &cancellables)
    }
    
    override func process(viewAction: ZeroProSubcriptionScreenViewAction) {
        
    }
}
