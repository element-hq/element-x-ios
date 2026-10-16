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
    
    // MARK: - Helpers
    
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
