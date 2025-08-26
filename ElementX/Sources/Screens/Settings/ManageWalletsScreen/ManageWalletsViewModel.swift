//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ManageWalletsViewModelType = StateStoreViewModel<ManageWalletsViewState, ManageWalletsViewAction>

class ManageWalletsViewModel: ManageWalletsViewModelType, ManageWalletsViewModelProtocol {
    
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol

    init(userSession: UserSessionProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        
        self.clientProxy = userSession.clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(bindings: .init()))
    }
    
    override func process(viewAction: ManageWalletsViewAction) {
        
    }
    
    // MARK: Loading indicator
    
    private static let loadingIndicatorIdentifier = "\(ManageWalletsViewModel.self)-Loading"
    
    private func showLoadingIndicator(delay: Duration? = nil) {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: delay)
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
