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
struct SecureBackupRecoveryKeyScreenViewActionTests {
    private let secureBackupController = SecureBackupControllerMock()
    private let userIndicatorController = UserIndicatorControllerMock()
    
    @Test
    func copyingTheKeyEnablesDone() {
        let viewModel = makeViewModel(recoveryState: .disabled)
        #expect(!viewModel.context.viewState.doneButtonEnabled)
        
        viewModel.context.send(viewAction: .copyKey)
        
        #expect(viewModel.context.viewState.doneButtonEnabled)
        #expect(userIndicatorController.submitIndicatorDelayCalled)
    }
    
    @Test
    func savingTheKeyElsewhereEnablesDone() {
        let viewModel = makeViewModel(recoveryState: .disabled)
        #expect(!viewModel.context.viewState.doneButtonEnabled)
        
        viewModel.context.send(viewAction: .keySaved)
        
        #expect(viewModel.context.viewState.doneButtonEnabled)
    }
    
    @Test
    func confirmingAKeyThatIsRightCompletesTheScreen() async throws {
        let viewModel = makeViewModel(recoveryState: .incomplete)
        secureBackupController.confirmRecoveryKeyReturnValue = .success(())
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .complete }
        viewModel.context.confirmationRecoveryKey = "the key"
        viewModel.context.send(viewAction: .confirmKey)
        try await deferred.fulfill()
        
        #expect(secureBackupController.confirmRecoveryKeyReceivedKey == "the key")
        #expect(viewModel.context.alertInfo == nil)
    }
    
    @Test
    func confirmingAKeyThatIsWrongShowsAnError() async throws {
        let viewModel = makeViewModel(recoveryState: .incomplete)
        secureBackupController.confirmRecoveryKeyReturnValue = .failure(.failedConfirmingRecoveryKey)
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.bindings.alertInfo)) { $0 != nil }
        viewModel.context.confirmationRecoveryKey = "not the key"
        viewModel.context.send(viewAction: .confirmKey)
        try await deferred.fulfill()
        
        #expect(viewModel.context.alertInfo?.title == L10n.screenRecoveryKeyConfirmErrorTitle)
    }
    
    @Test
    func cancellingCompletesTheScreen() async throws {
        let viewModel = makeViewModel(recoveryState: .disabled)
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .complete }
        viewModel.context.send(viewAction: .cancel)
        try await deferred.fulfill()
    }
    
    @Test
    func theConfirmationAlertCanBeDismissedWithoutActivatingTheKey() {
        let viewModel = makeViewModel(recoveryState: .disabled)
        
        viewModel.context.send(viewAction: .confirmKeySaved)
        
        #expect(viewModel.context.alertInfo?.secondaryButton?.role == .cancel)
        #expect(!secureBackupController.activateRecoveryKeyCalled)
        #expect(!viewModel.context.viewState.isCompleted)
    }
    
    // MARK: - Helpers
    
    private func makeViewModel(recoveryState: SecureBackupRecoveryState) -> SecureBackupRecoveryKeyScreenViewModel {
        secureBackupController.recoveryState = CurrentValueSubject<SecureBackupRecoveryState, Never>(recoveryState).asCurrentValuePublisher()
        secureBackupController.generateRecoveryKeyReturnValue = "a key"
        
        return SecureBackupRecoveryKeyScreenViewModel(secureBackupController: secureBackupController,
                                                      userIndicatorController: userIndicatorController,
                                                      isModallyPresented: false)
    }
}
