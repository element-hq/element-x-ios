//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import SwiftUI
import Testing

@MainActor
class LinkNewDeviceScreenViewModelTests {
    var linkNewDeviceService: LinkNewDeviceServiceMock!
    var appLockService: AppLockServiceMock!
    
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
    func linkingMobileDeviceVerifiesThenGeneratesQRCode() async throws {
        // Given a ready screen whose QR code isn't immediately available.
        let progressSubject = CurrentValueSubject<LinkNewDeviceService.LinkMobileProgress, QRCodeLoginError>(.starting)
        setupViewModel(linkMobileProgressPublisher: progressSubject.asCurrentValuePublisher(),
                       mode: .loading)
        
        // When linking a mobile device.
        let deferredGenerating = deferFulfillment(context.observe(\.viewState.mode),
                                                  transitionValues: [.readyToLink(.verifyingDeviceOwner),
                                                                     .readyToLink(.generatingCode)])
        context.send(viewAction: .linkMobileDevice)
        
        // Then it should verify the device owner and start generating the QR code.
        try await deferredGenerating.fulfill()
        #expect(appLockService.verifyDeviceOwnerReasonCalled)
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
    func linkingDesktopComputerVerifiesThenEmitsAction() async throws {
        // Given a ready screen.
        setupViewModel(mode: .loading)
        
        // When linking a desktop computer.
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { $0.isLinkDesktopComputer }
        let deferredMode = deferFulfillment(context.observe(\.viewState.mode),
                                            transitionValues: [.readyToLink(.verifyingDeviceOwner), .readyToLink(.idle)])
        context.send(viewAction: .linkDesktopComputer)
        
        // Then it should verify the device owner, and continue the flow to link a desktop.
        try await deferredAction.fulfill()
        try await deferredMode.fulfill()
        #expect(appLockService.verifyDeviceOwnerReasonCalled)
        #expect(!linkNewDeviceService.linkMobileDeviceCalled)
    }
    
    @Test
    func linkingProceedsWhenVerificationUnavailable() async throws {
        // Given a device with no passcode set, so device owner verification is unavailable.
        let progressSubject = CurrentValueSubject<LinkNewDeviceService.LinkMobileProgress, QRCodeLoginError>(.starting)
        setupViewModel(linkMobileProgressPublisher: progressSubject.asCurrentValuePublisher(),
                       deviceOwnerResult: .unavailable,
                       mode: .loading)
        
        // When linking a mobile device.
        let deferredGenerating = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .readyToLink(.generatingCode) }
        context.send(viewAction: .linkMobileDevice)
        
        // Then it should proceed by generating a QR code.
        try await deferredGenerating.fulfill()
        #expect(appLockService.verifyDeviceOwnerReasonCalled)
        #expect(linkNewDeviceService.linkMobileDeviceCalled)
    }
    
    @Test
    func appLockPINRequiredDoesNotLink() async throws {
        // Given a device with no passcode but an App Lock PIN set, so PIN verification is required.
        setupViewModel(deviceOwnerResult: .appLockPINRequired,
                       mode: .loading)
        
        // When linking a mobile device, it should not proceed to generate a QR code.
        // TODO: assert the App Lock PIN screen is presented once it's wired up.
        let deferred = deferFailure(context.observe(\.viewState.mode), timeout: .seconds(1)) { $0 == .readyToLink(.generatingCode) }
        context.send(viewAction: .linkMobileDevice)
        try await deferred.fulfill()
        
        // Then verification should have been attempted but linking should not have started.
        #expect(appLockService.verifyDeviceOwnerReasonCalled)
        #expect(!linkNewDeviceService.linkMobileDeviceCalled)
    }
    
    // MARK: - Verification failures
    
    @Test
    func cancellingVerificationReturnsToIdle() async throws {
        // Given a screen where the user will cancel the device owner verification.
        setupViewModel(deviceOwnerResult: .cancelled,
                       mode: .loading)
        
        // When linking a mobile device.
        let deferred = deferFulfillment(context.observe(\.viewState.mode),
                                        transitionValues: [.readyToLink(.verifyingDeviceOwner), .readyToLink(.idle)])
        context.send(viewAction: .linkMobileDevice)
        
        // Then the cancellation should silently return to idle without generating a QR code.
        try await deferred.fulfill()
        #expect(!linkNewDeviceService.linkMobileDeviceCalled)
    }
    
    @Test
    func unverifiedReturnsToIdle() async throws {
        // Given a screen where the device owner verification completes without success.
        setupViewModel(deviceOwnerResult: .unverified,
                       mode: .loading)
        
        // When linking a mobile device.
        let deferred = deferFulfillment(context.observe(\.viewState.mode),
                                        transitionValues: [.readyToLink(.verifyingDeviceOwner), .readyToLink(.idle)])
        context.send(viewAction: .linkMobileDevice)
        
        // Then the unverified result should silently return to idle without generating a QR code.
        try await deferred.fulfill()
        #expect(!linkNewDeviceService.linkMobileDeviceCalled)
    }
    
    @Test
    func verificationErrorShowsError() async throws {
        // Given a screen where the device owner verification errors.
        setupViewModel(deviceOwnerResult: .error,
                       mode: .loading)
        
        // When linking a mobile device.
        let deferred = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .error(.unknown) }
        context.send(viewAction: .linkMobileDevice)
        
        // Then the error should surface without generating a QR code.
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
                                deviceOwnerResult: AppLockDeviceOwnerResult = .verified,
                                mode: LinkNewDeviceScreenViewState.Mode? = nil) {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.underlyingIsLoginWithQRCodeSupported = isLoginWithQRCodeSupported
        
        linkNewDeviceService = LinkNewDeviceServiceMock(.init(linkMobileProgressPublisher: linkMobileProgressPublisher))
        clientProxy.linkNewDeviceServiceReturnValue = linkNewDeviceService
        
        appLockService = AppLockServiceMock.mock()
        appLockService.verifyDeviceOwnerReasonReturnValue = deviceOwnerResult
        
        let initialState = mode.map { LinkNewDeviceScreenViewState(mode: $0, showLinkDesktopComputerButton: true) }
        
        viewModel = LinkNewDeviceScreenViewModel(clientProxy: clientProxy,
                                                 appLockService: appLockService,
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
