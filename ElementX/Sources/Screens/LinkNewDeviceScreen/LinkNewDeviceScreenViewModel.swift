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
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }
    
    // MARK: - Private
    
    private func checkQRCodeLoginSupport() async {
        if await clientProxy.isLoginWithQRCodeSupported {
            state.mode = .readyToLink(isGeneratingCode: false)
        } else {
            state.mode = .notSupported
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
            #warning("Needs some form of re-usable error handling, will handle with the next screen.")
            state.mode = .notSupported
        }
    }
}
