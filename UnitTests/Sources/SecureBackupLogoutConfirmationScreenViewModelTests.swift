//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
@Suite
struct SecureBackupLogoutConfirmationScreenViewModelTests {
    private var viewModel: SecureBackupLogoutConfirmationScreenViewModel
    private var context: SecureBackupLogoutConfirmationScreenViewModel.Context {
        viewModel.context
    }
    
    private var secureBackupController: SecureBackupControllerMock
    private var reachabilitySubject: CurrentValueSubject<NetworkMonitorReachability, Never>
    
    init() {
        secureBackupController = SecureBackupControllerMock()
        secureBackupController.underlyingKeyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(.enabled).asCurrentValuePublisher()
        
        reachabilitySubject = CurrentValueSubject<NetworkMonitorReachability, Never>(.reachable)
        
        viewModel = SecureBackupLogoutConfirmationScreenViewModel(secureBackupController: secureBackupController,
                                                                  homeserverReachabilityPublisher: reachabilitySubject.asCurrentValuePublisher())
    }
    
    @Test
    func initialState() {
        #expect(context.viewState.mode == .saveRecoveryKey)
    }
    
    @Test
    func ongoingState() async {
        var testSetup = self
        #expect(testSetup.context.viewState.mode == .saveRecoveryKey)
        
        await confirmation { confirmation in
            testSetup.secureBackupController.waitForKeyBackupUploadUploadStateSubjectClosure = { stateSubject in
                try? await Task.sleep(for: .seconds(4))
                stateSubject.send(.uploading(uploadedKeyCount: 50, totalKeyCount: 100))
                confirmation()
                return .success(())
            }
            
            let deferredWaiting = deferFulfillment(testSetup.context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: false) }
            testSetup.context.send(viewAction: .logout)
            try? await deferredWaiting.fulfill()
            
            // Wait for the 2-second timeout.
            let deferredHasStalled = deferFulfillment(testSetup.context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: true) }
            try? await deferredHasStalled.fulfill()
        }
        
        #expect(testSetup.context.viewState.mode == .backupOngoing(progress: 0.5))
    }
    
    @Test
    func offlineState() async throws {
        var testSetup = self
        #expect(testSetup.context.viewState.mode == .saveRecoveryKey)
        
        await confirmation { confirmation in
            testSetup.secureBackupController.waitForKeyBackupUploadUploadStateSubjectClosure = { stateSubject in
                try? await Task.sleep(for: .seconds(4))
                stateSubject.send(.uploading(uploadedKeyCount: 50, totalKeyCount: 100))
                confirmation()
                return .success(())
            }
            
            let deferredWaiting = deferFulfillment(testSetup.context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: false) }
            testSetup.context.send(viewAction: .logout)
            try? await deferredWaiting.fulfill()
            
            // Wait for the 2-second timeout.
            let deferredHasStalled = deferFulfillment(testSetup.context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: true) }
            try? await deferredHasStalled.fulfill()
        }
        
        let deferred = deferFulfillment(testSetup.context.observe(\.viewState.mode)) { $0 == .offline }
        testSetup.reachabilitySubject.send(.unreachable)
        try await deferred.fulfill()
    }
}
