//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum QRCodeLoginScreenViewModelAction {
    case cancel
    case signInManually
    case done(userSession: UserSessionProtocol)
}

struct QRCodeLoginScreenViewState: BindableState {
    var state: QRCodeLoginState = .initial
    
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
        /// the qr code is scanning
        case scanning
        /// the qr code has been detected and is being processed
        case connecting
        /// the qr code has been processed and is invalid
        case invalid
        /// the qr code has been processed but it belongs to a device not signed in,
        case deviceNotSignedIn
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
        case .scan(let state):
            return state == .scanning
        default:
            return false
        }
    }
    
    var isError: Bool {
        switch self {
        case .error:
            return true
        case let .scan(state):
            switch state {
            case .invalid, .deviceNotSignedIn:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
    
    var shouldDisplayCancelButton: Bool {
        switch self {
        case .initial:
            return true
        case .scan:
            return true
        case .error(let error):
            return error == .noCameraPermission
        default:
            return false
        }
    }
}
