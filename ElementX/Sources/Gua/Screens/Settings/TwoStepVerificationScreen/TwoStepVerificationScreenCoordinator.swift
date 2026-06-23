//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct TwoStepVerificationScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let identityServiceClient: IdentityServiceClientProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let windowManager: WindowManagerProtocol
    let appSettings: AppSettings
}

enum TwoStepVerificationScreenCoordinatorAction {
    case close
}

final class TwoStepVerificationScreenCoordinator: CoordinatorProtocol {
    private let parameters: TwoStepVerificationScreenCoordinatorParameters
    private let viewModel: TwoStepVerificationScreenViewModelProtocol

    private var cancellables = Set<AnyCancellable>()
    /// Retained for the lifetime of the web flow so the session isn't cancelled early.
    private var passkeyEnrollmentPresenter: PasskeyEnrollmentPresenter?

    private let passkeyIndicatorID = "TwoStepVerificationScreen-Passkey"

    private let actionsSubject: PassthroughSubject<TwoStepVerificationScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<TwoStepVerificationScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: TwoStepVerificationScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = TwoStepVerificationScreenViewModel(clientProxy: parameters.clientProxy,
                                                       identityServiceClient: parameters.identityServiceClient,
                                                       userIndicatorController: parameters.userIndicatorController)
    }

    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            guard let self else { return }
            switch action {
            case .close:
                actionsSubject.send(.close)
            case .setUpPasskey:
                Task { await self.startPasskeyEnrollment() }
            }
        }
        .store(in: &cancellables)
    }

    private func startPasskeyEnrollment() async {
        guard let accessToken = parameters.clientProxy.accessToken else {
            MXLog.warning("No access token available; cannot start passkey enrollment.")
            return
        }

        parameters.userIndicatorController.submitIndicator(UserIndicator(id: passkeyIndicatorID,
                                                                         type: .modal,
                                                                         title: L10n.commonLoading,
                                                                         persistent: true))
        let enrollURL: URL
        do {
            enrollURL = try await parameters.identityServiceClient.startPasskeyEnrollment(accessToken: accessToken)
        } catch {
            MXLog.error("Failed to start passkey enrollment: \(error)")
            parameters.userIndicatorController.retractIndicatorWithId(passkeyIndicatorID)
            parameters.userIndicatorController.submitIndicator(UserIndicator(title: (error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown,
                                                                             iconName: "xmark"))
            return
        }
        parameters.userIndicatorController.retractIndicatorWithId(passkeyIndicatorID)

        let presenter = PasskeyEnrollmentPresenter(enrollURL: enrollURL,
                                                   presentationAnchor: parameters.windowManager.mainWindow,
                                                   appSettings: parameters.appSettings)
        passkeyEnrollmentPresenter = presenter
        await presenter.start()
        passkeyEnrollmentPresenter = nil
    }

    func toPresentable() -> AnyView {
        AnyView(TwoStepVerificationScreen(context: viewModel.context))
    }
}
