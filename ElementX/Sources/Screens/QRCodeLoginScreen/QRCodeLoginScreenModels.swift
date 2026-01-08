//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum QRCodeLoginScreenViewModelAction: CustomStringConvertible {
    case dismiss
    case signInManually
    case signedIn(userSession: UserSessionProtocol)
    case requestOIDCAuthorisation(URL, OIDCAccountSettingsPresenter.Continuation)
    case linkedDevice
    
    var description: String {
        switch self {
        case .dismiss: "dismiss"
        case .signInManually: "signInManually"
        case .signedIn: "signedIn"
        case .requestOIDCAuthorisation: "requestOIDCAuthorisation"
        case .linkedDevice: "linkedDevice"
        }
    }
}

enum QRCodeLoginScreenMode {
    /// Configures the screen to login this device by scanning a QR code.
    case login(QRCodeLoginServiceProtocol)
    /// Configures the screen to link another device by scanning a QR code.
    case linkDesktop(LinkNewDeviceServiceProtocol)
    /// Configures the screen to link another device by showing it a QR code.
    case linkMobile(LinkNewDeviceService.LinkMobileProgressPublisher)
}

struct QRCodeLoginScreenViewState: BindableState {
    var state: QRCodeLoginState
    /// Whether or not it is possible for the screen to start the manual sign in flow. This was added to avoid
    /// having to handle server configuration when ``AppSettings.allowOtherAccountProviders`` is false.
    let canSignInManually: Bool
    let isPresentedModally: Bool
    
    let instructions = QRCodeLoginScreenInstructions()
    var bindings = QRCodeLoginScreenViewStateBindings()
    
    var shouldDisplayCancelButton: Bool {
        // TODO: Simplify/validate these assumptions.
        if isPresentedModally {
            switch state {
            case .loginInstructions, .scan, .error(.noCameraPermission): true
            default: false
            }
        } else {
            switch state {
            case .displayCode, .confirmCode, .scan, .error(.noCameraPermission): true
            case .loginInstructions, .linkDesktopInstructions, .displayQR, .error: false
            }
        }
    }

    var shouldDisplayBackButton: Bool {
        if isPresentedModally {
            false
        } else {
            switch state {
            case .loginInstructions, .linkDesktopInstructions, .displayQR: true
            case .displayCode, .confirmCode, .scan, .error: false
            }
        }
    }
}

struct QRCodeLoginScreenViewStateBindings {
    var qrResult: Data?
    var checkCodeInput = ""
}

enum QRCodeLoginScreenViewAction {
    case dismiss
    case startScan
    case sendCheckCode
    case errorAction(QRCodeErrorView.Action)
}

enum QRCodeLoginState: Equatable {
    /// Initial state where the user is informed how to login this device by scanning a QR code.
    case loginInstructions
    /// Initial state where the user is informed how to link another device by scanning it's QR code.
    case linkDesktopInstructions
    
    /// The camera is scanning a QR code.
    case scan(ScanningState)
    /// Codes are being shown.
    case displayCode(DisplayCodeState)
    
    /// Initial state where the user can link another device using the shown QR code.
    case displayQR(UIImage)
    /// The user needs to enter the two digit code to confirm the channel is secure
    case confirmCode(CheckCodeState)
    
    /// Any full screen error state
    case error(ErrorState)
    
    enum ErrorState: Equatable, CaseIterable {
        case noCameraPermission
        case connectionNotSecure
        case cancelled
        case declined
        case expired
        case linkingNotSupported
        case deviceNotSupported
        /// Expected a QR code for a new device, however the processed code belongs to a device that is already signed in.
        case deviceAlreadySignedIn
        case unknown
    }
    
    enum ScanningState: Equatable {
        /// The QR code is scanning.
        case scanning
        /// The QR code has been detected and is being processed.
        case connecting
        /// The QR code was scanned, but an error occurred.
        case scanFailed(Error)
        
        enum Error: Equatable {
            /// The QR code has been processed and is invalid.
            case invalid
            /// The QR code has been processed but it is for an account provider that isn't allowed.
            case notAllowed(scannedProvider: String, allowedProviders: [String])
            /// The QR code has been processed but it belongs to a device not signed in.
            case deviceNotSignedIn
            
            var title: String {
                switch self {
                case .invalid:
                    L10n.screenQrCodeLoginInvalidScanStateSubtitle
                case .notAllowed(let scannedProvider, _):
                    L10n.screenChangeServerErrorUnauthorizedHomeserverTitle(scannedProvider)
                case .deviceNotSignedIn:
                    L10n.screenQrCodeLoginDeviceNotSignedInScanStateSubtitle
                }
            }
            
            var description: String {
                switch self {
                case .invalid:
                    L10n.screenQrCodeLoginInvalidScanStateDescription
                case .notAllowed(_, let allowedProviders):
                    L10n.screenChangeServerErrorUnauthorizedHomeserverContent(allowedProviders.formatted(.list(type: .and)))
                case .deviceNotSignedIn:
                    L10n.screenQrCodeLoginDeviceNotSignedInScanStateDescription
                }
            }
        }
    }
    
    enum DisplayCodeState: Equatable {
        case deviceCode(String)
        case verificationCode(String)
        
        var code: String {
            switch self {
            case .deviceCode(let code): code
            case .verificationCode(let code): code
            }
        }
    }
    
    enum CheckCodeState: Equatable {
        /// The user needs to input the confirmation code.
        case inputCode(CheckCodeSenderProxy)
        /// The code supplied by the user didn't pass local validation.
        case invalidCode
        /// The code is being sent.
        case sendingCode
        
        var isSending: Bool {
            switch self {
            case .sendingCode: true
            default: false
            }
        }
    }
    
    var isScanning: Bool {
        switch self {
        case .scan(.scanning): true
        default: false
        }
    }
    
    var isDisplayQR: Bool {
        switch self {
        case .displayQR: true
        default: false
        }
    }
    
    var isError: Bool {
        switch self {
        case .error, .scan(.scanFailed): true
        default: false
        }
    }
}

struct QRCodeLoginScreenInstructions {
    private static let loginItem3 = {
        let boldPlaceholder = "{bold}"
        var finalString = AttributedString(L10n.screenQrCodeLoginInitialStateItem3(boldPlaceholder))
        var boldString = AttributedString(L10n.screenQrCodeLoginInitialStateItem3Action)
        boldString.bold()
        finalString.replace(boldPlaceholder, with: boldString)
        return finalString
    }()
    
    let loginItems = [
        AttributedString(L10n.screenQrCodeLoginInitialStateItem1(InfoPlistReader.main.productionAppName)), // "Open Element on another device"
        AttributedString(L10n.screenQrCodeLoginInitialStateItem2), // "Click or tap on your avatar"
        loginItem3,
        AttributedString(L10n.screenQrCodeLoginInitialStateItem4)
    ]
    
    private static let linkDesktopItem2 = {
        let boldPlaceholder = "{bold}"
        var finalString = AttributedString(L10n.screenLinkNewDeviceMobileStep2(boldPlaceholder))
        var boldString = AttributedString(L10n.screenLinkNewDeviceMobileStep2Action)
        boldString.bold()
        finalString.replace(boldPlaceholder, with: boldString)
        return finalString
    }()
    
    let linkDesktopItems = [
        AttributedString(L10n.screenLinkNewDeviceDesktopStep1(InfoPlistReader.main.productionAppName)),
        linkDesktopItem2,
        AttributedString(L10n.screenLinkNewDeviceDesktopStep3)
    ]
    
    private static let linkMobile = {
        let boldPlaceholder = "{bold}"
        var finalString = AttributedString(L10n.screenLinkNewDeviceMobileStep2(boldPlaceholder))
        var boldString = AttributedString(L10n.screenLinkNewDeviceMobileStep2Action)
        boldString.bold()
        finalString.replace(boldPlaceholder, with: boldString)
        return finalString
    }()
    
    let linkMobileItems = [
        AttributedString(L10n.screenLinkNewDeviceMobileStep1(InfoPlistReader.main.productionAppName)),
        linkMobile,
        AttributedString(L10n.screenLinkNewDeviceMobileStep3)
    ]
}
