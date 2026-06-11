//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Combine
import SwiftUI

struct ProfileSetupScreenCoordinatorParameters {
    let phoneNumber: String
    let suggestedUsername: String
    let suggestedDisplayName: String

    init(phoneNumber: String, suggestedUsername: String = "", suggestedDisplayName: String = "") {
        self.phoneNumber = phoneNumber
        self.suggestedUsername = suggestedUsername
        self.suggestedDisplayName = suggestedDisplayName
    }
}

enum ProfileSetupScreenCoordinatorAction {
    case complete(username: String, displayName: String)
    case cancel
}

final class ProfileSetupScreenCoordinator: CoordinatorProtocol {
    private let parameters: ProfileSetupScreenCoordinatorParameters
    private let viewModel: ProfileSetupScreenViewModel

    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject: PassthroughSubject<ProfileSetupScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ProfileSetupScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: ProfileSetupScreenCoordinatorParameters) {
        self.parameters = parameters

        viewModel = ProfileSetupScreenViewModel(phoneNumber: parameters.phoneNumber,
                                                suggestedUsername: parameters.suggestedUsername,
                                                suggestedDisplayName: parameters.suggestedDisplayName)
    }

    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete(let username, let displayName):
                actionsSubject.send(.complete(username: username, displayName: displayName))
            case .cancel:
                actionsSubject.send(.cancel)
            }
        }
        .store(in: &cancellables)
    }

    func setSubmitting(_ isSubmitting: Bool) {
        viewModel.setSubmitting(isSubmitting)
    }

    func displayError(_ message: String) {
        viewModel.displayError(message)
    }

    func markUsernameTaken() {
        viewModel.markUsernameTaken()
    }

    func setUsernameAvailabilityChecker(_ checker: @escaping @MainActor (String) async throws -> UsernameAvailability) {
        viewModel.usernameAvailabilityChecker = checker
    }

    func toPresentable() -> AnyView {
        AnyView(ProfileSetupScreen(context: viewModel.context))
    }
}
