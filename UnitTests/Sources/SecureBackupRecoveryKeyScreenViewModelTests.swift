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
    
    // MARK: - Helpers
    
    private func confirmKeyIsSaved(on viewModel: SecureBackupRecoveryKeyScreenViewModel) async throws {
        viewModel.context.send(viewAction: .keySaved)
        viewModel.context.send(viewAction: .confirmKeySaved)
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.isCompleted)) { $0 }
        viewModel.context.alertInfo?.primaryButton.action?()
        try await deferred.fulfill()
    }
    
    private func makeViewModel(recoveryState: SecureBackupRecoveryState = .enabled,
                               presentationContext: SecureBackupRecoveryKeyScreenPresentationContext = .standard) -> (SecureBackupRecoveryKeyScreenViewModel, SecureBackupControllerMock) {
        let secureBackupController = SecureBackupControllerMock()
        secureBackupController.recoveryState = CurrentValueSubject<SecureBackupRecoveryState, Never>(recoveryState).asCurrentValuePublisher()
        secureBackupController.generateRecoveryKeyReturnValue = recoveryKey
        secureBackupController.activateRecoveryKeyReturnValue = .success(())
        
        let viewModel = SecureBackupRecoveryKeyScreenViewModel(secureBackupController: secureBackupController,
                                                               userIndicatorController: UserIndicatorControllerMock(),
                                                               isModallyPresented: false,
                                                               presentationContext: presentationContext)
        
        return (viewModel, secureBackupController)
    }
}
