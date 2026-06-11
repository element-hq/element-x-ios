//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Combine
import SwiftUI

typealias ProfileSetupScreenViewModelType = StateStoreViewModelV2<ProfileSetupScreenViewState, ProfileSetupScreenViewAction>

class ProfileSetupScreenViewModel: ProfileSetupScreenViewModelType, ProfileSetupScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<ProfileSetupScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ProfileSetupScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    /// Async closure that checks whether a normalized username is available. Injected so the
    /// view model can stay independent of the network layer (and easy to test).
    var usernameAvailabilityChecker: (@MainActor (String) async throws -> UsernameAvailability)?
    private var currentAvailabilityTask: Task<Void, Never>?

    init(phoneNumber: String, suggestedUsername: String = "", suggestedDisplayName: String = "") {
        super.init(initialViewState: ProfileSetupScreenViewState(phoneNumber: phoneNumber,
                                                                 bindings: .init(username: suggestedUsername, displayName: suggestedDisplayName)))
    }

    // MARK: - Public

    func setSubmitting(_ isSubmitting: Bool) {
        state.isSubmitting = isSubmitting
        if isSubmitting { state.errorMessage = nil }
    }

    func displayError(_ message: String) {
        state.isSubmitting = false
        state.errorMessage = message
    }

    /// Forces the status to `.taken` from outside (e.g. when the backend rejects the username
    /// during `completeSignup` despite our pre-check having raced).
    func markUsernameTaken() {
        state.usernameStatus = .taken
    }

    override func process(viewAction: ProfileSetupScreenViewAction) {
        switch viewAction {
        case .usernameChanged:
            // Normalize username: lowercase, strip disallowed characters, clamp length.
            let cleaned = state.bindings.username
                .lowercased()
                .filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "_" || $0 == "-" }
            let clamped = String(cleaned.prefix(ProfileSetupScreenViewState.usernameMaxLength))
            if clamped != state.bindings.username {
                state.bindings.username = clamped
            }
            scheduleAvailabilityCheck(for: clamped)
        case .submitTapped:
            guard state.canSubmit else { return }
            state.isSubmitting = true
            let username = state.bindings.username.trimmingCharacters(in: .whitespaces)
            let displayName = state.bindings.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            actionsSubject.send(.complete(username: username, displayName: displayName))
        case .cancelTapped:
            actionsSubject.send(.cancel)
        }
    }

    // MARK: - Private

    /// Debounce keystrokes by ~400ms and only hit the backend when the format is plausibly valid.
    /// Each new keystroke cancels the prior in-flight check so we never display stale results.
    private func scheduleAvailabilityCheck(for username: String) {
        currentAvailabilityTask?.cancel()

        guard !username.isEmpty else {
            state.usernameStatus = .idle
            return
        }
        guard ProfileSetupScreenViewState.isValid(username: username) else {
            state.usernameStatus = .invalid(reason: nil)
            return
        }
        guard let checker = usernameAvailabilityChecker else {
            state.usernameStatus = .idle
            return
        }

        state.usernameStatus = .checking
        currentAvailabilityTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return }
            do {
                let result = try await checker(username)
                if Task.isCancelled { return }
                guard let self else { return }
                // Discard stale results if the user typed more in the meantime.
                guard self.state.bindings.username == username else { return }
                self.state.usernameStatus = self.statusFromResult(result)
            } catch {
                guard let self, !Task.isCancelled else { return }
                guard self.state.bindings.username == username else { return }
                self.state.usernameStatus = .idle
            }
        }
    }

    private func statusFromResult(_ result: UsernameAvailability) -> ProfileSetupUsernameStatus {
        switch result {
        case .available: .available
        case .taken: .taken
        case let .invalid(reason): .invalid(reason: reason)
        }
    }
}
