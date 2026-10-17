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
    func newKeyIsNotActiveUntilTheUserHasConfirmedSavingIt() {
        let (viewModel, secureBackupController) = makeViewModel()
        #expect(viewModel.context.alertInfo == nil)
        #expect(!viewModel.context.viewState.isCompleted)
        
        viewModel.context.send(viewAction: .keySaved)
        viewModel.context.send(viewAction: .confirmKeySaved)
        
        #expect(viewModel.context.alertInfo != nil)
        #expect(!viewModel.context.viewState.isCompleted)
        #expect(!secureBackupController.activateRecoveryKeyCalled)
    }
    
    @Test
    func confirmingTheKeyIsSavedActivatesItAndShowsThatItIsActive() async throws {
        let (viewModel, secureBackupController) = makeViewModel()
        #expect(!viewModel.context.viewState.isCompleted)
        #expect(viewModel.context.viewState.title != L10n.screenRecoveryKeySuccessTitle)
        
        try await confirmKeyIsSaved(on: viewModel)
        
        #expect(secureBackupController.activateRecoveryKeyCallsCount == 1)
        #expect(viewModel.context.viewState.isCompleted)
        #expect(viewModel.context.viewState.title == L10n.screenRecoveryKeySuccessTitle)
    }
    
    @Test
    func failingToActivateTheKeyKeepsTheUserOnTheScreen() async throws {
        let (viewModel, secureBackupController) = makeViewModel()
        secureBackupController.activateRecoveryKeyClosure = { .failure(.failedActivatingRecoveryKey) }
        
        viewModel.context.send(viewAction: .keySaved)
        viewModel.context.send(viewAction: .confirmKeySaved)
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.bindings.alertInfo)) { $0?.title == L10n.commonError }
        viewModel.context.alertInfo?.primaryButton.action?()
        try await deferred.fulfill()
        
        #expect(!viewModel.context.viewState.isCompleted)
    }
    
    @Test
    func completingTheScreenIsReported() async throws {
        let (viewModel, _) = makeViewModel()
        try await confirmKeyIsSaved(on: viewModel)
        
        let deferred = deferFulfillment(viewModel.actions) { _ in true }
        viewModel.context.send(viewAction: .complete)
        try await deferred.fulfill()
    }
    
    @Test
    func completionButtonTitleDependsOnThePresentationContext() {
        let (standard, _) = makeViewModel(presentationContext: .standard)
        let (deviceRemoval, _) = makeViewModel(presentationContext: .deviceRemoval)
        
        #expect(standard.context.viewState.completionButtonTitle == L10n.actionDone)
        #expect(deviceRemoval.context.viewState.completionButtonTitle == L10n.screenSignoutSaveRecoveryKeyActionContinue)
    }
    
    @Test(arguments: [SecureBackupRecoveryState.disabled, .enabled])
    func keyIsGeneratedStraightAway(recoveryState: SecureBackupRecoveryState) {
        let (viewModel, secureBackupController) = makeViewModel(recoveryState: recoveryState)
        
        #expect(viewModel.context.viewState.recoveryKey == recoveryKey)
        #expect(secureBackupController.generateRecoveryKeyCallsCount == 1)
        #expect(!secureBackupController.activateRecoveryKeyCalled)
    }
    
    @Test
    func keyIsNotGeneratedWhenConfirmingAnExistingOne() {
        let (viewModel, secureBackupController) = makeViewModel(recoveryState: .incomplete)
        
        #expect(viewModel.context.viewState.recoveryKey == nil)
        #expect(!secureBackupController.generateRecoveryKeyCalled)
    }
    
    // MARK: - Checking the key
    
    @Test
    func checkingStartsWithoutAnyVerdict() async throws {
        let viewModel = try await makeViewModel(mode: .checkRecovery)
        
        #expect(viewModel.context.viewState.mode == .checkRecovery)
        #expect(viewModel.context.viewState.keyValidity == .unchecked)
    }
    
    @Test
    func correctKeyEnablesContinuingToTheSuccessScreen() async throws {
        let viewModel = try await makeViewModel(mode: .checkRecovery, checkResult: .success(()))
        #expect(!viewModel.context.viewState.isCompleted)
        
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
        let viewModel = try await makeViewModel(mode: .checkRecovery, checkResult: .failure(.failedConfirmingRecoveryKey))
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.keyValidity)) { $0 == .invalid }
        viewModel.context.confirmationRecoveryKey = "Not the key"
        viewModel.context.send(viewAction: .submitCheckedKey)
        try await deferred.fulfill()
        
        viewModel.context.send(viewAction: .completeCheck)
        #expect(!viewModel.context.viewState.isCompleted)
    }
    
    @Test
    func clearingTheKeyRemovesTheVerdict() async throws {
        let viewModel = try await makeViewModel(mode: .checkRecovery, checkResult: .failure(.failedConfirmingRecoveryKey))
        
        let invalid = deferFulfillment(viewModel.context.observe(\.viewState.keyValidity)) { $0 == .invalid }
        viewModel.context.confirmationRecoveryKey = "Not the key"
        viewModel.context.send(viewAction: .submitCheckedKey)
        try await invalid.fulfill()
        
        viewModel.context.confirmationRecoveryKey = ""
        viewModel.context.send(viewAction: .checkedKeyChanged)
        
        #expect(viewModel.context.viewState.keyValidity == .unchecked)
    }
    
    // MARK: - Helpers
    
    private func confirmKeyIsSaved(on viewModel: SecureBackupRecoveryKeyScreenViewModel) async throws {
        viewModel.context.send(viewAction: .keySaved)
        viewModel.context.send(viewAction: .confirmKeySaved)
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.isCompleted)) { $0 }
        viewModel.context.alertInfo?.primaryButton.action?()
        try await deferred.fulfill()
    }
    
    private func makeViewModel(recoveryState: SecureBackupRecoveryState = .enabled,
                               mode: SecureBackupRecoveryKeyScreenViewMode? = nil,
                               presentationContext: SecureBackupRecoveryKeyScreenPresentationContext = .standard,
                               checkResult: Result<Void, SecureBackupControllerError> = .success(()),
                               waitingForKey: Bool = false) async throws -> SecureBackupRecoveryKeyScreenViewModel {
        let secureBackupController = SecureBackupControllerMock()
        secureBackupController.recoveryState = CurrentValueSubject<SecureBackupRecoveryState, Never>(recoveryState).asCurrentValuePublisher()
        secureBackupController.generateRecoveryKeyWithPassphraseReturnValue = .success(recoveryKey)
        secureBackupController.checkRecoveryKeyReturnValue = checkResult
        
        let viewModel = SecureBackupRecoveryKeyScreenViewModel(secureBackupController: secureBackupController,
                                                               userIndicatorController: UserIndicatorControllerMock(),
                                                               isModallyPresented: false,
                                                               mode: mode,
                                                               presentationContext: presentationContext)
        
        return (viewModel, secureBackupController)
    }
}
