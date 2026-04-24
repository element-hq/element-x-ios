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
struct IdentityConfirmationScreenViewModelTests {
    var securityStateSubject: CurrentValueSubject<SessionSecurityState, Never>!
    
    var viewModel: IdentityConfirmationScreenViewModel!
    var context: IdentityConfirmationScreenViewModel.Context {
        viewModel.context
    }
    
    @Test
    mutating func logoutShowsConfirmation() async throws {
        setupViewModel()
        
        #expect(context.alertInfo == nil)
        
        context.send(viewAction: .logout)
        
        let alertInfo = try #require(context.alertInfo)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .logoutConfirmed }
        alertInfo.primaryButton.action?()
        try await deferred.fulfill()
    }
    
    // MARK: - Available Actions
    
    @Test
    mutating func availableActionsWithDevicesAndRecovery() async throws {
        setupViewModel(hasDevicesToVerifyAgainst: true)
        #expect(context.viewState.availableActions == nil)
        
        let deferred = deferFulfillment(context.observe(\.viewState.availableActions)) { $0 != nil }
        securityStateSubject.send(.init(verificationState: .unverified, recoveryState: .enabled))
        try await deferred.fulfill()
        
        let availableActions = try #require(context.viewState.availableActions)
        #expect(availableActions == [.interactiveVerification, .recovery])
    }
    
    @Test
    mutating func availableActionsWithDevices() async throws {
        setupViewModel(hasDevicesToVerifyAgainst: true)
        #expect(context.viewState.availableActions == nil)
        
        let deferred = deferFulfillment(context.observe(\.viewState.availableActions)) { $0 != nil }
        securityStateSubject.send(.init(verificationState: .unverified, recoveryState: .disabled))
        try await deferred.fulfill()
        
        let availableActions = try #require(context.viewState.availableActions)
        #expect(availableActions == [.interactiveVerification])
    }
    
    @Test
    mutating func availableActionsWithRecovery() async throws {
        setupViewModel(hasDevicesToVerifyAgainst: false)
        #expect(context.viewState.availableActions == nil)
        
        let deferred = deferFulfillment(context.observe(\.viewState.availableActions)) { $0 != nil }
        securityStateSubject.send(.init(verificationState: .unverified, recoveryState: .enabled))
        try await deferred.fulfill()
        
        let availableActions = try #require(context.viewState.availableActions)
        #expect(availableActions == [.recovery])
    }
    
    @Test
    mutating func availableActionsWithoutDevicesOrRecovery() async throws {
        setupViewModel(hasDevicesToVerifyAgainst: false)
        #expect(context.viewState.availableActions == nil)
        
        let deferred = deferFulfillment(context.observe(\.viewState.availableActions)) { $0 != nil }
        securityStateSubject.send(.init(verificationState: .unverified, recoveryState: .disabled))
        try await deferred.fulfill()
        
        let availableActions = try #require(context.viewState.availableActions)
        #expect(availableActions.isEmpty)
    }
    
    @Test
    mutating func availableActionsWhileSecurityStateIsPending() async throws {
        setupViewModel(hasDevicesToVerifyAgainst: true)
        
        let deferred = deferFailure(context.observe(\.viewState.availableActions), timeout: .seconds(1)) { $0 != nil }
        try await deferred.fulfill()
        
        #expect(context.viewState.availableActions == nil)
    }
    
    // MARK: - Private
    
    mutating func setupViewModel(hasDevicesToVerifyAgainst: Bool = true) {
        let initialState = SessionSecurityState(verificationState: .unverified, recoveryState: .unknown)
        securityStateSubject = CurrentValueSubject<SessionSecurityState, Never>(initialState)
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.hasDevicesToVerifyAgainstReturnValue = .success(hasDevicesToVerifyAgainst)
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        userSession.sessionSecurityStatePublisher = securityStateSubject.asCurrentValuePublisher()
        
        viewModel = IdentityConfirmationScreenViewModel(userSession: userSession,
                                                        appSettings: AppSettings(),
                                                        userIndicatorController: UserIndicatorControllerMock())
    }
}
