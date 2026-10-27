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
        let viewModel = try await makeViewModel(waitingForKey: true)
        #expect(viewModel.context.alertInfo == nil)
        #expect(!viewModel.context.viewState.isCompleted)
        
        viewModel.context.send(viewAction: .keySaved)
        viewModel.context.send(viewAction: .confirmKeySaved)
        
        #expect(viewModel.context.alertInfo != nil)
        #expect(!viewModel.context.viewState.isCompleted)
    }
    
    @Test
    func confirmingTheKeyIsSavedShowsThatItIsActive() async throws {
        let viewModel = try await makeViewModel(waitingForKey: true)
        #expect(!viewModel.context.viewState.isCompleted)
        #expect(viewModel.context.viewState.title != UntranslatedL10n.screenRecoveryKeySuccessTitle)
        
        viewModel.context.send(viewAction: .keySaved)
        viewModel.context.send(viewAction: .confirmKeySaved)
        viewModel.context.alertInfo?.primaryButton.action?()
        
        #expect(viewModel.context.viewState.isCompleted)
        #expect(viewModel.context.viewState.title == UntranslatedL10n.screenRecoveryKeySuccessTitle)
    }
    
    @Test
    func completingTheScreenIsReported() async throws {
        let viewModel = try await makeViewModel(waitingForKey: true)
        viewModel.context.send(viewAction: .keySaved)
        viewModel.context.send(viewAction: .confirmKeySaved)
        viewModel.context.alertInfo?.primaryButton.action?()
        
        let deferred = deferFulfillment(viewModel.actions) { _ in true }
        viewModel.context.send(viewAction: .complete)
        try await deferred.fulfill()
    }
    
    @Test
    func completionButtonTitleDependsOnThePresentationContext() async throws {
        let standard = try await makeViewModel(presentationContext: .standard)
        let deviceRemoval = try await makeViewModel(presentationContext: .deviceRemoval)
        
        #expect(standard.context.viewState.completionButtonTitle == L10n.actionDone)
        #expect(deviceRemoval.context.viewState.completionButtonTitle == L10n.screenSignoutSaveRecoveryKeyActionContinue)
    }
    
    @Test(arguments: [SecureBackupRecoveryState.disabled, .enabled])
    func keyIsGeneratedStraightAway(recoveryState: SecureBackupRecoveryState) async throws {
        let viewModel = try await makeViewModel(recoveryState: recoveryState, waitingForKey: true)
        
        #expect(viewModel.context.viewState.recoveryKey == recoveryKey)
    }
    
    @Test
    func keyIsNotGeneratedWhenConfirmingAnExistingOne() async throws {
        let viewModel = try await makeViewModel(recoveryState: .incomplete)
        
        let deferred = deferFailure(viewModel.context.observe(\.viewState.recoveryKey), timeout: .seconds(1)) { $0 != nil }
        try await deferred.fulfill()
        
        #expect(viewModel.context.viewState.recoveryKey == nil)
    }
    
    // MARK: - Helpers
    
    private func makeViewModel(recoveryState: SecureBackupRecoveryState = .enabled,
                               presentationContext: SecureBackupRecoveryKeyScreenPresentationContext = .standard,
                               waitingForKey: Bool = false) async throws -> SecureBackupRecoveryKeyScreenViewModel {
        let secureBackupController = SecureBackupControllerMock()
        secureBackupController.recoveryState = CurrentValueSubject<SecureBackupRecoveryState, Never>(recoveryState).asCurrentValuePublisher()
        secureBackupController.generateRecoveryKeyWithPassphraseReturnValue = .success(recoveryKey)
        
        let viewModel = SecureBackupRecoveryKeyScreenViewModel(secureBackupController: secureBackupController,
                                                               userIndicatorController: UserIndicatorControllerMock(),
                                                               isModallyPresented: false,
                                                               presentationContext: presentationContext)
        
        if waitingForKey {
            try await deferFulfillment(viewModel.context.observe(\.viewState.recoveryKey)) { $0 == recoveryKey }.fulfill()
        }
        
        return viewModel
    }
}
