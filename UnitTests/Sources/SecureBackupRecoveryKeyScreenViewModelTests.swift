//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
struct SecureBackupRecoveryKeyScreenViewModelTests {
    private let recoveryKey = "EsTM njec uHYA yHmh dQdW Nj4o bNRU 9jMN XGMc KUNM UFr5 R8GY"
    
    @Test
    func newKeyIsNotActiveUntilTheUserHasConfirmedSavingIt() async throws {
        let viewModel = try await makeViewModelWithGeneratedKey()
        
        viewModel.context.send(viewAction: .keySaved)
        viewModel.context.send(viewAction: .done)
        
        #expect(viewModel.context.alertInfo != nil)
        #expect(!viewModel.context.viewState.isCompleted)
    }
    
    @Test
    func confirmingTheKeyIsSavedShowsThatItIsActive() async throws {
        let viewModel = try await makeViewModelWithGeneratedKey()
        
        viewModel.context.send(viewAction: .keySaved)
        viewModel.context.send(viewAction: .done)
        viewModel.context.alertInfo?.primaryButton.action?()
        
        #expect(viewModel.context.viewState.isCompleted)
        #expect(viewModel.context.viewState.title == UntranslatedL10n.screenRecoveryKeySuccessTitle)
    }
    
    @Test
    func finishingReportsTheModeThatWasCompleted() async throws {
        let viewModel = try await makeViewModelWithGeneratedKey()
        viewModel.context.send(viewAction: .keySaved)
        viewModel.context.send(viewAction: .done)
        viewModel.context.alertInfo?.primaryButton.action?()
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            if case .done(mode: .changeRecovery) = action {
                true
            } else {
                false
            }
        }
        viewModel.context.send(viewAction: .finish)
        try await deferred.fulfill()
    }
    
    @Test
    func completionButtonTitleIsConfigurable() {
        let viewModel = makeViewModel(completionButtonTitle: "Continue to remove this device")
        
        #expect(viewModel.context.viewState.completionButtonTitle == "Continue to remove this device")
    }
    
    @Test(arguments: [SecureBackupRecoveryState.disabled, .enabled])
    func keyIsGeneratedStraightAway(recoveryState: SecureBackupRecoveryState) async throws {
        let viewModel = makeViewModel(recoveryState: recoveryState)
        
        try await deferFulfillment(viewModel.context.observe(\.viewState.recoveryKey)) { $0 == recoveryKey }.fulfill()
    }
    
    @Test
    func keyIsNotGeneratedWhenConfirmingAnExistingOne() async throws {
        let viewModel = makeViewModel(recoveryState: .incomplete)
        
        let deferred = deferFailure(viewModel.context.observe(\.viewState.recoveryKey), timeout: .seconds(1)) { $0 != nil }
        try await deferred.fulfill()
        
        #expect(viewModel.context.viewState.recoveryKey == nil)
    }
    
    // MARK: - Checking the key
    
    @Test
    func checkingStartsWithoutAnyVerdict() {
        let viewModel = makeCheckViewModel()
        
        #expect(viewModel.context.viewState.mode == .checkRecovery)
        #expect(viewModel.context.viewState.keyValidity == .unchecked)
    }
    
    @Test
    func correctKeyEnablesContinuingToTheSuccessScreen() async throws {
        let viewModel = makeCheckViewModel(checkResult: .success(()))
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.keyValidity)) { $0 == .valid }
        viewModel.context.confirmationRecoveryKey = recoveryKey
        viewModel.context.send(viewAction: .submitCheckedKey)
        try await deferred.fulfill()
        
        viewModel.context.send(viewAction: .completeCheck)
        #expect(viewModel.context.viewState.isCompleted)
        #expect(viewModel.context.viewState.title == UntranslatedL10n.screenRecoveryKeyCheckSuccessTitle)
    }
    
    @Test
    func incorrectKeyIsFlaggedAndCannotBeContinuedFrom() async throws {
        let viewModel = makeCheckViewModel(checkResult: .failure(.failedConfirmingRecoveryKey))
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.keyValidity)) { $0 == .invalid }
        viewModel.context.confirmationRecoveryKey = "Not the key"
        viewModel.context.send(viewAction: .submitCheckedKey)
        try await deferred.fulfill()
        
        viewModel.context.send(viewAction: .completeCheck)
        #expect(!viewModel.context.viewState.isCompleted)
    }
    
    @Test
    func clearingTheKeyRemovesTheVerdict() async throws {
        let viewModel = makeCheckViewModel(checkResult: .failure(.failedConfirmingRecoveryKey))
        
        let invalid = deferFulfillment(viewModel.context.observe(\.viewState.keyValidity)) { $0 == .invalid }
        viewModel.context.confirmationRecoveryKey = "Not the key"
        viewModel.context.send(viewAction: .submitCheckedKey)
        try await invalid.fulfill()
        
        viewModel.context.confirmationRecoveryKey = ""
        viewModel.context.send(viewAction: .checkedKeyChanged)
        
        #expect(viewModel.context.viewState.keyValidity == .unchecked)
    }
    
    // MARK: - Helpers
    
    private func makeCheckViewModel(checkResult: Result<Void, SecureBackupControllerError> = .success(())) -> SecureBackupRecoveryKeyScreenViewModel {
        let secureBackupController = SecureBackupControllerMock()
        secureBackupController.recoveryState = CurrentValueSubject<SecureBackupRecoveryState, Never>(.enabled).asCurrentValuePublisher()
        secureBackupController.checkRecoveryKeyReturnValue = checkResult
        
        return SecureBackupRecoveryKeyScreenViewModel(secureBackupController: secureBackupController,
                                                      userIndicatorController: UserIndicatorControllerMock(),
                                                      isModallyPresented: false,
                                                      mode: .checkRecovery)
    }
    
    private func makeViewModelWithGeneratedKey() async throws -> SecureBackupRecoveryKeyScreenViewModel {
        let viewModel = makeViewModel()
        
        try await deferFulfillment(viewModel.context.observe(\.viewState.recoveryKey)) { $0 == recoveryKey }.fulfill()
        
        return viewModel
    }
    
    private func makeViewModel(recoveryState: SecureBackupRecoveryState = .enabled,
                               completionButtonTitle: String = L10n.actionDone) -> SecureBackupRecoveryKeyScreenViewModel {
        let secureBackupController = SecureBackupControllerMock()
        secureBackupController.recoveryState = CurrentValueSubject<SecureBackupRecoveryState, Never>(recoveryState).asCurrentValuePublisher()
        secureBackupController.generateRecoveryKeyWithPassphraseReturnValue = .success(recoveryKey)
        
        return SecureBackupRecoveryKeyScreenViewModel(secureBackupController: secureBackupController,
                                                      userIndicatorController: UserIndicatorControllerMock(),
                                                      isModallyPresented: false,
                                                      completionButtonTitle: completionButtonTitle)
    }
}
