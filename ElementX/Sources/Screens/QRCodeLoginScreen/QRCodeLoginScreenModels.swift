//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
    case errorAction(QRCodeErrorView.Action)
}

enum QRCodeLoginState: Equatable {
    /// Initial state where the user is informed how to perform the scan
    case initial
    /// The camera is scanning
    case scan(ScanningState)
    /// Codes are being shown
    case displayCode(QRCodeLoginDisplayCodeState)
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
