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
}

struct QRCodeLoginScreenViewState: BindableState {
    var state: QRCodeLoginState = .initial
    
    private let listItem3AttributedText = {
        let boldPlaceholder = "{bold}"
        var finalString = AttributedString(L10n.screenQrCodeLoginInitialStateItem3(boldPlaceholder))
        var boldString = AttributedString(L10n.screenQrCodeLoginInitialStateItem3Action)
        boldString.bold()
        finalString.replace(boldPlaceholder, with: boldString)
        return finalString
    }()
    
    private let listItem4AttributedText = {
        let boldPlaceholder = "{bold}"
        var finalString = AttributedString(L10n.screenQrCodeLoginInitialStateItem4(boldPlaceholder))
        var boldString = AttributedString(L10n.screenQrCodeLoginInitialStateItem4Action)
        boldString.bold()
        finalString.replace(boldPlaceholder, with: boldString)
        return finalString
    }()
    
    var listItems: [AttributedString] {
        [
            AttributedString(L10n.screenQrCodeLoginInitialStateItem1),
            AttributedString(L10n.screenQrCodeLoginInitialStateItem2),
            listItem3AttributedText,
            listItem4AttributedText
        ]
    }
}

enum QRCodeLoginScreenViewAction {
    case cancel
    case startScan
}

enum QRCodeLoginState: Equatable {
    /// Initial state where the user is informed how to perform the scan
    case initial
    /// The camera is scanning
    case scan(QRCodeLoginScanningState)
    /// Any full screen error state
    case error(QRCodeLoginErrorState)
    
    enum QRCodeLoginErrorState: Equatable {
        case noCameraPermission
    }
    
    enum QRCodeLoginScanningState: Equatable {
        /// the qr code is scanning
        case scanning
        /// the qr code has been detected and is being processed
        case connecting
        /// the qr code has been processed and is invalid
        case invalid
    }
}
