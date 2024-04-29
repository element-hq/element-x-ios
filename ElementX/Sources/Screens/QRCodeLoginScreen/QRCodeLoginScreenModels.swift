//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

enum QRCodeLoginScreenViewModelAction {
    case cancel
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
        case unknown
    }
    
    enum QRCodeLoginScanningState: Equatable {
        /// the qr code is scanning
        case scanning
        /// the qr code has been detected and is being processed
        case connecting
        /// the qr code has been processed and is invalid
        case invalid
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
    
    var isDisplayingCode: Bool {
        switch self {
        case .displayCode:
            return true
        default:
            return false
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
}
