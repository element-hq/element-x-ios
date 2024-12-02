//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias CreateAccountScreenViewModelType = StateStoreViewModel<CreateAccountScreenViewState, CreateAccountScreenViewAction>

class CreateAccountScreenViewModel: CreateAccountScreenViewModelType, CreateAccountScreenViewModelProtocol {
    private let authenticationService: AuthenticationServiceProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<CreateAccountScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<CreateAccountScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(authenticationService: AuthenticationServiceProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         inviteCode: String) {
        self.authenticationService = authenticationService
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: CreateAccountScreenViewState(inviteCode: inviteCode))
    }
    
    override func process(viewAction: CreateAccountScreenViewAction) {
        switch viewAction {
        case .openLoginScreen:
            actionsSubject.send(.openLoginScreen)
        case .createAccount:
            createUserAccount()
        }
    }
    
    private func createUserAccount() {
        startLoading()
        Task {
            switch await authenticationService.createUserAccount(email: state.bindings.emailAddress,
                                                                 password: state.bindings.password,
                                                                 inviteCode: state.inviteCode) {
            case .success:
                stopLoading()
                //TODO: move to complete profile screen
            case .failure(let error):
                stopLoading()
            }
        }
    }
    
    private static let loadingIndicatorIdentifier = "\(CreateAccountScreenCoordinatorAction.self)-Loading"
    
    private func startLoading() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
