//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum LinkNewDeviceScreenViewModelAction {
    case linkMobileDevice(LinkNewDeviceService.LinkMobileProgressPublisher)
    case linkDesktopComputer
    case verifyWithAppLockPIN(CheckedContinuation<Bool, Never>)
    case dismiss
}

struct LinkNewDeviceScreenViewState: BindableState {
    nonisolated enum Mode: Equatable {
        enum ReadyState: Equatable {
            case idle
            case verifyingDeviceOwner
            case generatingCode
        }
        
        case loading
        case readyToLink(ReadyState)
        case error(QRCodeLoginState.ErrorState)
    }
    
    var mode: Mode = .loading
    
    let showLinkDesktopComputerButton: Bool
}

enum LinkNewDeviceScreenViewAction {
    case linkMobileDevice
    case linkDesktopComputer
    case errorAction(QRCodeErrorView.Action)
    case dismiss
}
