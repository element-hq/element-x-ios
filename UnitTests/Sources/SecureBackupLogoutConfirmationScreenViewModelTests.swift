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
struct SecureBackupLogoutConfirmationScreenViewModelTests {
    private var viewModel: SecureBackupLogoutConfirmationScreenViewModel
    private var context: SecureBackupLogoutConfirmationScreenViewModel.Context {
        viewModel.context
    }
    
    private var secureBackupController: SecureBackupControllerMock
    private var reachabilitySubject: CurrentValueSubject<HomeserverReachability, Never>
    
    init() {
        secureBackupController = SecureBackupControllerMock()
        secureBackupController.keyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(.enabled).asCurrentValuePublisher()
        
        reachabilitySubject = CurrentValueSubject<HomeserverReachability, Never>(.reachable)
        
        viewModel = SecureBackupLogoutConfirmationScreenViewModel(secureBackupController: secureBackupController,
                                                                  homeserverReachabilityPublisher: reachabilitySubject.asCurrentValuePublisher(),
                                                                  learnMoreURL: "https://example.org/encryption",
                                                                  mode: .saveRecoveryKey)
    }
    
    @Test
    func initialState() {
        #expect(context.viewState.mode == .saveRecoveryKey)
    }
    
    @Test
    func ongoingState() async throws {
        #expect(context.viewState.mode == .saveRecoveryKey)
        
        try await confirmation { confirmation in
            secureBackupController.waitForKeyBackupUploadUploadStateSubjectClosure = { stateSubject in
                try? await Task.sleep(for: .seconds(4))
                stateSubject.send(.uploading(uploadedKeyCount: 50, totalKeyCount: 100))
                confirmation()
                return .success(())
            }
            
            let deferredWaiting = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: false) }
            context.send(viewAction: .logout)
            _ = try await deferredWaiting.fulfill()
            
            // Wait for the 2-second timeout.
            let deferredHasStalled = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: true) }
            _ = try await deferredHasStalled.fulfill()
            
            try await deferFulfillment(context.observe(\.viewState.mode)) { $0 == .backupOngoing(progress: 0.5) }.fulfill()
        }
    }
    
    @Test
    func offlineState() async throws {
        #expect(context.viewState.mode == .saveRecoveryKey)
        
        try await confirmation { confirmation in
            secureBackupController.waitForKeyBackupUploadUploadStateSubjectClosure = { stateSubject in
                try? await Task.sleep(for: .seconds(4))
                stateSubject.send(.uploading(uploadedKeyCount: 50, totalKeyCount: 100))
                confirmation()
                return .success(())
            }
            
            let deferredWaiting = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: false) }
            context.send(viewAction: .logout)
            try await deferredWaiting.fulfill()
            
            // Wait for the 2-second timeout.
            let deferredHasStalled = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: true) }
            try await deferredHasStalled.fulfill()
            
            try await deferFulfillment(context.observe(\.viewState.mode)) { $0 == .backupOngoing(progress: 0.5) }.fulfill()
        }
        
        let deferred = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .offline }
        reachabilitySubject.send(.unreachable)
        try await deferred.fulfill()
    }
    
    @Test
    func titleSubtitleAndIconFollowTheMode() {
        func state(_ mode: SecureBackupLogoutConfirmationScreenViewMode) -> SecureBackupLogoutConfirmationScreenViewState {
            .init(learnMoreURL: "https://example.org/encryption", mode: mode)
        }
        
        #expect(state(.saveRecoveryKey).title == L10n.screenSignoutSaveRecoveryKeyTitle)
        #expect(state(.saveRecoveryKey).subtitle == L10n.screenSignoutSaveRecoveryKeySubtitle)
        #expect(state(.saveRecoveryKey).icon.keyPath == \.info)
        
        #expect(state(.noRecovery).title == L10n.screenSignoutRecoveryDisabledTitle)
        #expect(state(.noRecovery).subtitle == L10n.screenSignoutRecoveryDisabledSubtitle)
        #expect(state(.noRecovery).icon.keyPath == \.errorSolid)
        
        #expect(state(.waitingToStart(hasStalled: false)).title == L10n.screenSignoutKeyBackupOngoingTitle)
        #expect(state(.backupOngoing(progress: 0.5)).subtitle == L10n.screenSignoutKeyBackupOngoingSubtitle)
        #expect(state(.offline).title == L10n.screenSignoutKeyBackupOfflineTitle)
        #expect(state(.offline).subtitle == L10n.screenSignoutKeyBackupOfflineSubtitle)
        #expect(state(.offline).icon.keyPath == \.keyOffSolid)
    }
    
    @Test
    func noRecoveryLogsOutStraightAway() async throws {
        let viewModel = SecureBackupLogoutConfirmationScreenViewModel(secureBackupController: secureBackupController,
                                                                      homeserverReachabilityPublisher: reachabilitySubject.asCurrentValuePublisher(),
                                                                      learnMoreURL: "https://example.org/encryption",
                                                                      mode: .noRecovery)
        #expect(viewModel.context.viewState.mode == .noRecovery)
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            if case .logout = action {
                true
            } else {
                false
            }
        }
        viewModel.context.send(viewAction: .logout)
        try await deferred.fulfill()
        
        // There are no keys to wait for without a recovery key, and the question stays as it is.
        #expect(viewModel.context.viewState.mode == .noRecovery)
        #expect(secureBackupController.waitForKeyBackupUploadUploadStateSubjectCallsCount == 0)
    }
    
    @Test
    func cancelIsForwarded() async throws {
        let deferred = deferFulfillment(viewModel.actions) { action in
            if case .cancel = action {
                true
            } else {
                false
            }
        }
        context.send(viewAction: .cancel)
        try await deferred.fulfill()
    }
    
    @Test
    func generatingARecoveryKeyIsForwarded() async throws {
        let deferred = deferFulfillment(viewModel.actions) { action in
            if case .generateRecoveryKey = action {
                true
            } else {
                false
            }
        }
        context.send(viewAction: .generateRecoveryKey)
        try await deferred.fulfill()
    }
    
    @Test
    func continuingWithANewRecoveryKeyWaitsForTheBackupFirst() async throws {
        let viewModel = SecureBackupLogoutConfirmationScreenViewModel(secureBackupController: secureBackupController,
                                                                      homeserverReachabilityPublisher: reachabilitySubject.asCurrentValuePublisher(),
                                                                      learnMoreURL: "https://example.org/encryption",
                                                                      mode: .noRecovery)
        secureBackupController.waitForKeyBackupUploadUploadStateSubjectClosure = { _ in .success(()) }
        
        let deferredLogout = deferFulfillment(viewModel.actions) { action in
            if case .logout = action {
                true
            } else {
                false
            }
        }
        let deferredContinuation = deferFulfillment(viewModel.actions) { action in
            if case let .generateRecoveryKey(continuation) = action {
                continuation.yield()
                return true
            }
            return false
        }
        viewModel.context.send(viewAction: .generateRecoveryKey)
        try await deferredContinuation.fulfill()
        try await deferredLogout.fulfill()
        
        // Unlike removing the device without a recovery key, the new keys have to be uploaded.
        #expect(secureBackupController.waitForKeyBackupUploadUploadStateSubjectCallsCount == 1)
    }
}
