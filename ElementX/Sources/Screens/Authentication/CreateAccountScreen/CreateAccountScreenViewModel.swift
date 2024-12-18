//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import ReownAppKit
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
        
        AppKit.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                switch response.result {
                case let .response(value):
                    self?.createUserAccountWithWallet(token: value.stringRepresentation.replacingOccurrences(of: "\"", with: ""))
                case let .error(error):
                    MXLog.error("Session error: \(error)")
                    self?.state.bindings.alertInfo = AlertInfo(id: .unknown)
                }
            }
            .store(in: &cancellables)
    }
    
    override func process(viewAction: CreateAccountScreenViewAction) {
        switch viewAction {
        case .openLoginScreen:
            actionsSubject.send(.openLoginScreen)
        case .createAccount:
            createUserAccount()
        case .openWalletConnectModal:
            presentWalletConnectModal()
        }
    }
    
    private func createUserAccount() {
        startLoading()
        Task {
            switch await authenticationService.createUserAccount(email: state.bindings.emailAddress,
                                                                 password: state.bindings.password,
                                                                 inviteCode: state.inviteCode) {
            case .success(let userSession):
                stopLoading()
                actionsSubject.send(.accountCreated(userSession: userSession))
            case .failure(let error):
                stopLoading()
                handleError(error: error)
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
    
    private func handleError(error: AuthenticationServiceError) {
        state.bindings.alertInfo = AlertInfo(id: .unknown)
    }
    
    private func presentWalletConnectModal() {
        WalletConnectService.shared.presentWalletConnectModal()
    }
    
    private func createUserAccountWithWallet(token: String) {
        startLoading()
        Task {
            switch await authenticationService.createUserAccountWithWeb3(web3Token: token, inviteCode: state.inviteCode) {
            case .success(let userSession):
                stopLoading()
                actionsSubject.send(.accountCreated(userSession: userSession))
            case .failure(let error):
                stopLoading()
                handleError(error: error)
            }
        }
    }
}
