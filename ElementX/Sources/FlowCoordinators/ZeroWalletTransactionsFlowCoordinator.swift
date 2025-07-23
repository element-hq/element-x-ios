//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum ZeroWalletTransactionsFlowCoordinatorAction {
    case transactionCompleted
    case finished
}

class ZeroWalletTransactionsFlowCoordinator: FlowCoordinatorProtocol {
    private let rootStackCoordinator: NavigationStackCoordinator
    private let userSession: UserSessionProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    private let startWithTransactionType: WalletTransactionType
    private let meowPrice: ZeroCurrency?
    
    private let actionsSubject: PassthroughSubject<ZeroWalletTransactionsFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ZeroWalletTransactionsFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(rootStackCoordinator: NavigationStackCoordinator,
         userSession: UserSessionProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol,
         transactionType: WalletTransactionType,
         meowPrice: ZeroCurrency?) {
        self.rootStackCoordinator = rootStackCoordinator
        self.userSession = userSession
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        self.startWithTransactionType = transactionType
        self.meowPrice = meowPrice
    }
    
    func start() {
        presentView()
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        fatalError()
    }
    
    private func presentView() {
        switch startWithTransactionType {
        case .sendToken:
            presentWalletTokenTransferSheet()
        case .receiveTransaction:
            presentReceiveWalletTransactionSheet()
        }
    }
    
    private func presentWalletTokenTransferSheet() {
        let stackCoordinator = NavigationStackCoordinator()
        let transferTokenCoordinator = TransferTokenCoordinator(parameters: .init(meowPrice: meowPrice,
                                                                                  clientProxy: userSession.clientProxy,
                                                                                  mediaProvider: userSession.mediaProvider,
                                                                                  userIndicatorController: userIndicatorController))
        transferTokenCoordinator.actions
            .sink { [weak self] action in
                switch action {
                case .transactionCompleted:
                    self?.actionsSubject.send(.transactionCompleted)
                case .finished:
                    self?.actionsSubject.send(.finished)
                }
            }
            .store(in: &cancellables)
        stackCoordinator.setRootCoordinator(transferTokenCoordinator)
        rootStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.actionsSubject.send(.finished)
        }
    }
    
    private func presentReceiveWalletTransactionSheet() {
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = ReceiveTransactionCoordinator(parameters: .init(clientProxy: userSession.clientProxy))
        coordinator.actions
            .sink { [weak self] action in
                switch action {
                case .finish:
                    self?.actionsSubject.send(.transactionCompleted)
                    self?.actionsSubject.send(.finished)
                }
            }
            .store(in: &cancellables)
        stackCoordinator.setRootCoordinator(coordinator)
        rootStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.actionsSubject.send(.transactionCompleted)
            self?.actionsSubject.send(.finished)
        }
    }
}
