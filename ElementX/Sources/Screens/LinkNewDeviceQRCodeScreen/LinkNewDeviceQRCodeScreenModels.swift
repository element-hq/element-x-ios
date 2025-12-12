//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import SwiftUI

enum LinkNewDeviceQRCodeScreenViewModelAction {
    case cancel
    case done
    case requestOIDCAuthorisation(URL)
}

enum LinkNewDeviceQRCodeScreenMode {
    case scanQRCode
    case generateQRCode(LinkNewDeviceService.GenerateProgressPublisher)
}

struct LinkNewDeviceQRCodeScreenViewState: BindableState {
    var state: LinkNewDeviceQRCodeState
    
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
    
    private static let showQRCodeListItem2AttributedText = {
        let boldPlaceholder = "{bold}"
        var finalString = AttributedString(L10n.screenLinkNewDeviceMobileStep2(boldPlaceholder))
        var boldString = AttributedString(L10n.screenLinkNewDeviceMobileStep2Action)
        boldString.bold()
        finalString.replace(boldPlaceholder, with: boldString)
        return finalString
    }()
    
    let showQRCodeListItems = [
        AttributedString(L10n.screenLinkNewDeviceMobileStep1(InfoPlistReader.main.productionAppName)),
        showQRCodeListItem2AttributedText,
        AttributedString(L10n.screenLinkNewDeviceMobileStep3)
    ]
    
    var bindings = LinkNewDeviceQRCodeScreenViewStateBindings(checkCodeInput: "")
}

struct LinkNewDeviceQRCodeScreenViewStateBindings {
    var qrResult: Data?
    var checkCodeInput: String
}

enum LinkNewDeviceQRCodeScreenViewAction {
    case cancel
    case startScan
    case startOver
    case checkCodeInput
    case openSettings
}

enum LinkNewDeviceQRCodeState {
    /// Instructions where the user is informed how to perform the scan
    case scanInstructions
    /// The camera is scanning
    case scan(QRCodeLoginState.ScanningState)
    /// The QR code is being shown
    case displayQR(UIImage)
    /// The user needs to enter the two digit code to confirm the channel is secure
    case checkCode(CheckCodeSenderProtocol)
    /// The user needs to enter the two digit code to confirm the channel is secure
    case checkCodeInvalid(CheckCodeSenderProtocol)
    /// Codes are being shown
    case displayCode(LinkNewDeviceQRCodeDisplayCodeState)
    /// Any full screen error state
    case error(QRCodeLoginState.ErrorState)
    
    enum LinkNewDeviceQRCodeDisplayCodeState: Equatable {
        case deviceCode(String)
        case verificationCode(String)
        
        var code: String {
            switch self {
            case .deviceCode(let code): code
            case .verificationCode(let code): code
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
        case .displayCode, .checkCode, .checkCodeInvalid, .scan, .error(.noCameraPermission): true
        case .displayQR, .scanInstructions, .error: false
        }
    }
    
    var shouldDisplayBackButton: Bool {
        switch self {
        case .displayQR, .scanInstructions: true
        case .displayCode, .checkCode, .checkCodeInvalid, .scan, .error: false
        }
    }
    
    var checkCodeSender: CheckCodeSenderProtocol? {
        switch self {
        case .checkCode(let sender): return sender
        case .checkCodeInvalid(let sender): return sender
        default: return nil
        }
    }
}
