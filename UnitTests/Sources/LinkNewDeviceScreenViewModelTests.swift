//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import LocalAuthentication
import SwiftUI
import Testing

@MainActor
class LinkNewDeviceScreenViewModelTests {
    var linkNewDeviceService: LinkNewDeviceServiceMock!
    var authenticationContext: LAContextMock!
    
    var viewModel: LinkNewDeviceScreenViewModel!
    var context: LinkNewDeviceScreenViewModel.Context {
        viewModel.context
    }
    
    // MARK: - QR code support
    
    @Test
    func readyWhenQRCodeLoginSupported() async throws {
        // Given a client that supports logging in with a QR code.
        setupViewModel(isLoginWithQRCodeSupported: true)
        
        // Then the screen should become ready to link.
        let deferred = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .readyToLink(.idle) }
        try await deferred.fulfill()
    }
    
    @Test
    func errorWhenQRCodeLoginNotSupported() async throws {
        // Given a client that doesn't support logging in with a QR code.
        setupViewModel(isLoginWithQRCodeSupported: false)
        
        // Then the screen should show the unsupported error.
        let deferred = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .error(.notSupported) }
        try await deferred.fulfill()
    }
    
    // MARK: - Linking
    
    @Test
    func linkingMobileDeviceAuthenticatesThenGeneratesQRCode() async throws {
        // Given a ready screen whose QR code isn't immediately available.
        let progressSubject = CurrentValueSubject<LinkNewDeviceService.LinkMobileProgress, QRCodeLoginError>(.starting)
        setupViewModel(linkMobileProgressPublisher: progressSubject.asCurrentValuePublisher(),
                       mode: .loading)
        
        // When linking a mobile device.
        let deferredGenerating = deferFulfillment(context.observe(\.viewState.mode),
                                                  transitionValues: [.readyToLink(.authenticatingDeviceOwner),
                                                                     .readyToLink(.generatingCode)])
        context.send(viewAction: .linkMobileDevice)
        
        // Then it should authenticate the device owner and start generating the QR code.
        try await deferredGenerating.fulfill()
        #expect(authenticationContext.evaluatePolicyCalled)
        #expect(linkNewDeviceService.linkMobileDeviceCalled)
        
        // When the QR code has been generated.
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { $0.isLinkMobileDevice }
        let deferredIdle = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .readyToLink(.idle) }
        progressSubject.send(.qrReady(LinkNewDeviceServiceMock.mockQRCodeImage))
        
        // Then the flow should continue with linking the mobile device.
        try await deferredAction.fulfill()
        try await deferredIdle.fulfill()
    }
    
    @Test
    func linkingDesktopComputerAuthenticatesThenEmitsAction() async throws {
        // Given a ready screen.
        setupViewModel(mode: .loading)
        
        // When linking a desktop computer.
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { $0.isLinkDesktopComputer }
        let deferredMode = deferFulfillment(context.observe(\.viewState.mode),
                                            transitionValues: [.readyToLink(.authenticatingDeviceOwner), .readyToLink(.idle)])
        context.send(viewAction: .linkDesktopComputer)
        
        // Then it should authenticate the device owner, and continue the flow to link a desktop.
        try await deferredAction.fulfill()
        try await deferredMode.fulfill()
        #expect(authenticationContext.evaluatePolicyCalled)
        #expect(!linkNewDeviceService.linkMobileDeviceCalled)
    }
    
    @Test
    func linkingProceedsWhenAuthenticationUnavailable() async throws {
        // Given a device that can't evaluate the device owner authentication policy.
        let progressSubject = CurrentValueSubject<LinkNewDeviceService.LinkMobileProgress, QRCodeLoginError>(.starting)
        setupViewModel(linkMobileProgressPublisher: progressSubject.asCurrentValuePublisher(),
                       canEvaluatePolicy: false,
                       mode: .loading)
        
        // When linking a mobile device.
        let deferredGenerating = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .readyToLink(.generatingCode) }
        context.send(viewAction: .linkMobileDevice)
        
        // Then it should skip authentication and continue by generating a QR code.
        try await deferredGenerating.fulfill()
        #expect(!authenticationContext.evaluatePolicyCalled)
        #expect(linkNewDeviceService.linkMobileDeviceCalled)
    }
    
    // MARK: - Authentication failures
    
    @Test
    func cancellingAuthenticationReturnsToIdle() async throws {
        // Given a screen where the user will cancel the device owner authentication.
        setupViewModel(evaluatePolicyThrowableError: LAError(.userCancel),
                       mode: .loading)
        
        // When linking a mobile device.
        let deferred = deferFulfillment(context.observe(\.viewState.mode),
                                        transitionValues: [.readyToLink(.authenticatingDeviceOwner), .readyToLink(.idle)])
        context.send(viewAction: .linkMobileDevice)
        
        // Then the cancellation should silently return to idle without generating a QR code.
        try await deferred.fulfill()
        #expect(!linkNewDeviceService.linkMobileDeviceCalled)
    }
    
    @Test
    func declinedAuthenticationReturnsToIdle() async throws {
        // Given a screen where the device owner authentication returns false.
        setupViewModel(evaluatePolicyReturnValue: false,
                       mode: .loading)
        
        // When linking a mobile device.
        let deferred = deferFulfillment(context.observe(\.viewState.mode),
                                        transitionValues: [.readyToLink(.authenticatingDeviceOwner), .readyToLink(.idle)])
        context.send(viewAction: .linkMobileDevice)
        
        // Then the declined authentication should silently return to idle without generating a QR code.
        try await deferred.fulfill()
        #expect(!linkNewDeviceService.linkMobileDeviceCalled)
    }
    
    @Test
    func failedAuthenticationShowsError() async throws {
        // Given a screen where the device owner authentication fails unexpectedly.
        setupViewModel(evaluatePolicyThrowableError: LAError(.authenticationFailed),
                       mode: .loading)
        
        // When linking a mobile device.
        let deferred = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .error(.unknown) }
        context.send(viewAction: .linkMobileDevice)
        
        // Then the failure should surface an error without generating a QR code.
        try await deferred.fulfill()
        #expect(!linkNewDeviceService.linkMobileDeviceCalled)
    }
    
    // MARK: - Error actions
    
    @Test
    func startingOverReturnsToIdle() async throws {
        // Given a screen in an error state.
        setupViewModel(mode: .error(.unknown))
        
        // When starting over.
        let deferred = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .readyToLink(.idle) }
        context.send(viewAction: .errorAction(.startOver))
        
        // Then it should return to idle.
        try await deferred.fulfill()
    }
    
    @Test
    func cancellingErrorEmitsDismiss() async throws {
        // Given a screen in an error state.
        setupViewModel(mode: .error(.unknown))
        
        // When cancelling.
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0.isDismiss }
        context.send(viewAction: .errorAction(.cancel))
        
        // Then it should dismiss the flow.
        try await deferred.fulfill()
    }
    
    @Test
    func dismissEmitsAction() async throws {
        // Given a ready screen.
        setupViewModel(mode: .readyToLink(.idle))
        
        // When dismissing.
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0.isDismiss }
        context.send(viewAction: .dismiss)
        
        // Then it should dismiss the flow.
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(isLoginWithQRCodeSupported: Bool = true,
                                linkMobileProgressPublisher: LinkNewDeviceService.LinkMobileProgressPublisher = .init(.qrReady(LinkNewDeviceServiceMock.mockQRCodeImage)),
                                canEvaluatePolicy: Bool = true,
                                evaluatePolicyReturnValue: Bool = true,
                                evaluatePolicyThrowableError: Error? = nil,
                                mode: LinkNewDeviceScreenViewState.Mode? = nil) {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.underlyingIsLoginWithQRCodeSupported = isLoginWithQRCodeSupported
        
        linkNewDeviceService = LinkNewDeviceServiceMock(.init(linkMobileProgressPublisher: linkMobileProgressPublisher))
        clientProxy.linkNewDeviceServiceReturnValue = linkNewDeviceService
        
        authenticationContext = LAContextMock()
        authenticationContext.canEvaluatePolicyReturnValue = canEvaluatePolicy
        authenticationContext.evaluatePolicyReturnValue = evaluatePolicyReturnValue
        authenticationContext.evaluatePolicyThrowableError = evaluatePolicyThrowableError
        
        let initialState = mode.map { LinkNewDeviceScreenViewState(mode: $0, showLinkDesktopComputerButton: true) }
        
        viewModel = LinkNewDeviceScreenViewModel(clientProxy: clientProxy,
                                                 authenticationContext: authenticationContext,
                                                 initialState: initialState)
    }
}

private extension LinkNewDeviceScreenViewModelAction {
    var isLinkMobileDevice: Bool {
        switch self {
        case .linkMobileDevice: true
        default: false
        }
    }
    
    var isLinkDesktopComputer: Bool {
        switch self {
        case .linkDesktopComputer: true
        default: false
        }
    }
    
    var isDismiss: Bool {
        switch self {
        case .dismiss: true
        default: false
        }
    }
}
