//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import XCTest

@MainActor
class SecureBackupLogoutConfirmationScreenViewModelTests: XCTestCase {
    var viewModel: SecureBackupLogoutConfirmationScreenViewModel!
    var context: SecureBackupLogoutConfirmationScreenViewModel.Context {
        viewModel.context
    }
    
    var secureBackupController: SecureBackupControllerMock!
    var reachabilitySubject: CurrentValueSubject<NetworkMonitorReachability, Never>!
    
    override func setUp() {
        secureBackupController = SecureBackupControllerMock()
        secureBackupController.underlyingKeyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(.enabled).asCurrentValuePublisher()
        
        reachabilitySubject = CurrentValueSubject<NetworkMonitorReachability, Never>(.reachable)
        
        viewModel = SecureBackupLogoutConfirmationScreenViewModel(secureBackupController: secureBackupController,
                                                                  homeserverReachabilityPublisher: reachabilitySubject.asCurrentValuePublisher())
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.mode, .saveRecoveryKey)
    }
    
    func testOngoingState() async throws {
        testInitialState()
        
        let progressExpectation = expectation(description: "The upload progress callback should be called.")
        secureBackupController.waitForKeyBackupUploadUploadStateSubjectClosure = { stateSubject in
            try? await Task.sleep(for: .seconds(4))
            stateSubject.send(.uploading(uploadedKeyCount: 50, totalKeyCount: 100))
            progressExpectation.fulfill()
            return .success(())
        }
        
        let deferredWaiting = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: false) }
        context.send(viewAction: .logout)
        try await deferredWaiting.fulfill()
        
        // Wait for the 2-second timeout.
        let deferredHasStalled = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: true) }
        try await deferredHasStalled.fulfill()
        
        // Wait for the progress to be reported.
        await fulfillment(of: [progressExpectation])
        XCTAssertEqual(context.viewState.mode, .backupOngoing(progress: 0.5))
    }
    
    func testOfflineState() async throws {
        try await testOngoingState()
        
        let deferred = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .offline }
        reachabilitySubject.send(.unreachable)
        try await deferred.fulfill()
    }
}
