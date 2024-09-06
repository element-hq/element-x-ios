//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct ReportContentScreenCoordinatorParameters {
    let eventID: String
    let senderID: String
    let roomProxy: JoinedRoomProxyProtocol
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum ReportContentScreenCoordinatorAction {
    case cancel
    case finish
}

final class ReportContentScreenCoordinator: CoordinatorProtocol {
    private let parameters: ReportContentScreenCoordinatorParameters
    private var viewModel: ReportContentScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<ReportContentScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<ReportContentScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ReportContentScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ReportContentScreenViewModel(eventID: parameters.eventID,
                                                 senderID: parameters.senderID,
                                                 roomProxy: parameters.roomProxy,
                                                 clientProxy: parameters.clientProxy)
    }

    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .submitStarted:
                    startLoading()
                case let .submitFailed(message):
                    stopLoading()
                    showError(description: message)
                case .submitFinished:
                    stopLoading()
                    actionsSubject.send(.finish)
                case .cancel:
                    actionsSubject.send(.cancel)
                }
            }
            .store(in: &cancellables)
    }

    func stop() {
        stopLoading()
    }
        
    func toPresentable() -> AnyView {
        AnyView(ReportContentScreen(context: viewModel.context))
    }

    // MARK: - Private

    private static let loadingIndicatorIdentifier = "\(ReportContentScreenCoordinator.self)-Loading"

    private func startLoading() {
        parameters.userIndicatorController.submitIndicator(
            UserIndicator(id: Self.loadingIndicatorIdentifier,
                          type: .modal,
                          title: L10n.commonSending,
                          persistent: true)
        )
    }

    private func stopLoading() {
        parameters.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    private func showError(description: String) {
        parameters.userIndicatorController.submitIndicator(UserIndicator(title: description))
    }
}
