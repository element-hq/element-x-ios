//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum QRCodeLoginScreenViewModelAction {
    case cancel
    case signInManually
    case done(userSession: UserSessionProtocol)
}

struct QRCodeLoginScreenViewState: BindableState {
    var state: QRCodeLoginState = .initial
    /// Whether or not it is possible for the screen to start the manual sign in flow. This was added to avoid
    /// having to handle server configuration when ``AppSettings.allowOtherAccountProviders`` is false.
    let canSignInManually: Bool
    
    private static let initialStateListItem3AttributedText = {
        let boldPlaceholder = "{bold}"
        var finalString = AttributedString(L10n.screenQrCodeLoginInitialStateItem3(boldPlaceholder))
        var boldString = AttributedString(L10n.screenQrCodeLoginInitialStateItem3Action)
        boldString.bold()
        finalString.replace(boldPlaceholder, with: boldString)
        return finalString
    }()
    
    let initialStateListItems = [
        AttributedString(L10n.screenQrCodeLoginInitialStateItem1(InfoPlistReader.main.productionAppName)),
        AttributedString(L10n.screenQrCodeLoginInitialStateItem2),
        initialStateListItem3AttributedText,
        AttributedString(L10n.screenQrCodeLoginInitialStateItem4)
    ]
    
    let connectionNotSecureListItems = [
        AttributedString(L10n.screenQrCodeLoginConnectionNoteSecureStateListItem1),
        AttributedString(L10n.screenQrCodeLoginConnectionNoteSecureStateListItem2),
        AttributedString(L10n.screenQrCodeLoginConnectionNoteSecureStateListItem3)
    ]
    
    var bindings = QRCodeLoginScreenViewStateBindings()
}

struct QRCodeLoginScreenViewStateBindings {
    var qrResult: Data?
}

enum QRCodeLoginScreenViewAction {
    case cancel
    case startScan
    case signInManually
    case openSettings
}

enum QRCodeLoginState: Equatable {
    /// Initial state where the user is informed how to perform the scan
    case initial
    /// The camera is scanning
    case scan(QRCodeLoginScanningState)
    /// Codes are being shown
    case displayCode(QRCodeLoginDisplayCodeState)
    /// Any full screen error state
    case error(QRCodeLoginErrorState)
    
    enum QRCodeLoginErrorState: Equatable {
        case noCameraPermission
        case connectionNotSecure
        case cancelled
        case declined
        case expired
        case linkingNotSupported
        case deviceNotSupported
        case unknown
    }
    
    enum QRCodeLoginScanningState: Equatable {
        /// the QR code is scanning
        case scanning
        /// the QR code has been detected and is being processed
        case connecting
        /// the QR code was scanned, but an error occurred.
        case scanFailed(Error)
        
        enum Error: Equatable {
            /// the QR code has been processed and is invalid
            case invalid
            /// the QR code has been processed but it is for an account provider that isn't allowed.
            case notAllowed(scannedProvider: String, allowedProviders: [String])
            /// the QR code has been processed but it belongs to a device not signed in
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
    
    enum QRCodeLoginDisplayCodeState: Equatable {
        case deviceCode(String)
        case verificationCode(String)
        
        var code: String {
            switch self {
            case .deviceCode(let code):
                return code
            case .verificationCode(let code):
                return code
            }
        }
    }
    
    var isScanning: Bool {
        switch self {
        case .scan(.scanning): true
        default: false
        }
    }
    
    var isError: Bool {
        switch self {
        case .error, .scan(.scanFailed): true
        default: false
        }
    }
    
    var shouldDisplayCancelButton: Bool {
        switch self {
        case .initial, .scan, .error(.noCameraPermission): true
        default: false
        }
    }
}
