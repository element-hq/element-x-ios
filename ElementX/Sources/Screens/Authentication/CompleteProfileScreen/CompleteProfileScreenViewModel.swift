//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias CompleteProfileScreenViewModelType = StateStoreViewModel<CompleteProfileScreenViewState, CompleteProfileScreenViewAction>

class CompleteProfileScreenViewModel: CompleteProfileScreenViewModelType, CompleteProfileScreenViewModelProtocol {
    private let authenticationService: AuthenticationServiceProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<CompleteProfileScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<CompleteProfileScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(authenticationService: AuthenticationServiceProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         inviteCode: String) {
        self.authenticationService = authenticationService
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: CompleteProfileScreenViewState(inviteCode: inviteCode))
    }
    
    override func process(viewAction: CompleteProfileScreenViewAction) {
        
    }
    
    private static let loadingIndicatorIdentifier = "\(CompleteProfileScreenCoordinatorAction.self)-Loading"
    
    private func startLoading() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    private func handleError(error: AuthenticationServiceError) {
        userIndicatorController.alertInfo = AlertInfo(id: UUID())
    }
}
