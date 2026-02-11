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
    private let clientProxy: ClientProxyProtocol
    
    private let actionsSubject: PassthroughSubject<LinkNewDeviceScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<LinkNewDeviceScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(clientProxy: ClientProxyProtocol) {
        self.clientProxy = clientProxy
        
        let isQRCodeScanningSupported = !ProcessInfo.processInfo.isiOSAppOnMac
        
        super.init(initialViewState: LinkNewDeviceScreenViewState(showLinkDesktopComputerButton: isQRCodeScanningSupported))
        
        Task { await checkQRCodeLoginSupport() }
    }
    
    // MARK: - Public
    
    override func process(viewAction: LinkNewDeviceScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .linkMobileDevice:
            Task { await linkMobileDevice() }
        case .linkDesktopComputer:
            actionsSubject.send(.linkDesktopComputer)
        case .errorAction(let action):
            handleErrorAction(action)
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }
    
    // MARK: - Private
    
    private func checkQRCodeLoginSupport() async {
        if await clientProxy.isLoginWithQRCodeSupported {
            state.mode = .readyToLink(isGeneratingCode: false)
        } else {
            state.mode = .error(.notSupported)
        }
    }
    
    private func linkMobileDevice() async {
        state.mode = .readyToLink(isGeneratingCode: true)
        
        let linkNewDeviceService = clientProxy.linkNewDeviceService()
        
        let progressPublisher = linkNewDeviceService.linkMobileDevice()
        
        do {
            _ = try await progressPublisher.values
                .first { progress in
                    switch progress {
                    case .qrReady: true
                    default: false
                    }
                }
            
            actionsSubject.send(.linkMobileDevice(progressPublisher))
            state.mode = .readyToLink(isGeneratingCode: false)
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
            state.mode = .readyToLink(isGeneratingCode: false)
        case .openSettings, .signInManually:
            MXLog.error("Unexpected error action: \(action)")
            actionsSubject.send(.dismiss)
        case .cancel:
            actionsSubject.send(.dismiss)
        }
    }
}
