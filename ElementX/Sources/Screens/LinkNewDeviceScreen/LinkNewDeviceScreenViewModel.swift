//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias LinkNewDeviceScreenViewModelType = StateStoreViewModelV2<LinkNewDeviceScreenViewState, LinkNewDeviceScreenViewAction>

class LinkNewDeviceScreenViewModel: LinkNewDeviceScreenViewModelType, LinkNewDeviceScreenViewModelProtocol {
    private enum Device { case mobileDevice, desktopComputer }
    
    private let clientProxy: ClientProxyProtocol
    private let appLockService: AppLockServiceProtocol
    
    private let actionsSubject: PassthroughSubject<LinkNewDeviceScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<LinkNewDeviceScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(clientProxy: ClientProxyProtocol, appLockService: AppLockServiceProtocol, initialState: LinkNewDeviceScreenViewState? = nil) {
        self.clientProxy = clientProxy
        self.appLockService = appLockService
        
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
            Task { await verifyAndLink(.mobileDevice) }
        case .linkDesktopComputer:
            Task { await verifyAndLink(.desktopComputer) }
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
    
    private func verifyAndLink(_ device: Device) async {
        state.mode = .readyToLink(.verifyingDeviceOwner)
        
        switch await appLockService.verifyDeviceOwner(reason: L10n.screenLinkNewDeviceAuthenticationReasonIos) {
        case .verified, .unavailable:
            break
        case .appLockPINRequired:
            // Follow-up PR: present the App Lock PIN screen to verify the device owner.
            return
        case .cancelled, .unverified:
            state.mode = .readyToLink(.idle)
            return
        case .error:
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
}
