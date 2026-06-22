//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import LocalAuthentication
import MatrixRustSDK
import SwiftUI

typealias LinkNewDeviceScreenViewModelType = StateStoreViewModelV2<LinkNewDeviceScreenViewState, LinkNewDeviceScreenViewAction>

class LinkNewDeviceScreenViewModel: LinkNewDeviceScreenViewModelType, LinkNewDeviceScreenViewModelProtocol {
    private enum Device { case mobileDevice, desktopComputer }
    
    private let clientProxy: ClientProxyProtocol
    private let authenticationContext: LAContext
    
    private let actionsSubject: PassthroughSubject<LinkNewDeviceScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<LinkNewDeviceScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(clientProxy: ClientProxyProtocol, authenticationContext: LAContext = LAContext(), initialState: LinkNewDeviceScreenViewState? = nil) {
        self.clientProxy = clientProxy
        self.authenticationContext = authenticationContext
        
        if let initialState {
            super.init(initialViewState: initialState)
            return
        }
        
        let isQRCodeScanningSupported = !ProcessInfo.processInfo.isiOSAppOnMac
        
        super.init(initialViewState: LinkNewDeviceScreenViewState(showLinkDesktopComputerButton: isQRCodeScanningSupported))
        
        Task { await checkQRCodeLoginSupport() }
    }
    
    // MARK: - Public
    
    override func process(viewAction: LinkNewDeviceScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .linkMobileDevice:
            Task { await authenticateAndLink(.mobileDevice) }
        case .linkDesktopComputer:
            Task { await authenticateAndLink(.desktopComputer) }
        case .errorAction(let action):
            handleErrorAction(action)
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }
    
    // MARK: - Private
    
    private func checkQRCodeLoginSupport() async {
        if await clientProxy.isLoginWithQRCodeSupported {
            state.mode = .readyToLink(.idle)
        } else {
            state.mode = .error(.notSupported)
        }
    }
    
    private func authenticateAndLink(_ device: Device) async {
        state.mode = .readyToLink(.authenticatingDeviceOwner)
        
        do {
            guard try await authenticateDeviceOwner() else {
                state.mode = .readyToLink(.idle)
                return
            }
        } catch {
            // TODO: Failure UX is pending product confirmation; using the generic error state for now.
            state.mode = .error(.unknown)
            return
        }
        
        switch device {
        case .mobileDevice:
            await linkMobileDevice() // Automatically sets the state.
        case .desktopComputer:
            actionsSubject.send(.linkDesktopComputer)
            state.mode = .readyToLink(.idle)
        }
    }
    
    private func linkMobileDevice() async {
        state.mode = .readyToLink(.generatingCode)
        
        let linkNewDeviceService = clientProxy.linkNewDeviceService()
        
        let progressPublisher = linkNewDeviceService.linkMobileDevice()
        
        do {
            var iterator = progressPublisher.values.makeAsyncIterator()
            while let progress = try await iterator.next(isolation: #isolation) {
                if case .qrReady = progress {
                    break
                }
            }
            
            actionsSubject.send(.linkMobileDevice(progressPublisher))
            state.mode = .readyToLink(.idle)
        } catch {
            // This is hard to share a mapping from the QRCodeLoginError with the
            // QRCodeLoginScreen given that some of those are scan errors…
            state.mode = .error(.unknown)
        }
    }
    
    private func handleErrorAction(_ action: QRCodeErrorView.Action) {
        switch action {
        case .startOver:
            // Reset to ready state to allow trying again.
            state.mode = .readyToLink(.idle)
        case .openSettings, .signInManually:
            MXLog.error("Unexpected error action: \(action)")
            actionsSubject.send(.dismiss)
        case .cancel:
            actionsSubject.send(.dismiss)
        }
    }
    
    // MARK: - Authentication
    
    private func authenticateDeviceOwner() async throws -> Bool {
        let context = makeAuthenticationContext()
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            MXLog.warning("Device owner authentication unavailable, proceeding without: \(String(describing: error))")
            return true
        }
        
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication,
                                                    localizedReason: UntranslatedL10n.screenLinkNewDeviceAuthenticationReasonIos)
        } catch LAError.userCancel, LAError.systemCancel {
            MXLog.info("Device owner authentication was cancelled.")
            return false
        } catch {
            MXLog.warning("Device owner authentication failed: \(error)")
            throw error
        }
    }
    
    /// Creates a fresh context for each authentication so the user is always prompted.
    private func makeAuthenticationContext() -> LAContext {
        // Keep using the injected context for tests etc.
        guard type(of: authenticationContext) == LAContext.self else { return authenticationContext }
        
        return LAContext()
    }
}
