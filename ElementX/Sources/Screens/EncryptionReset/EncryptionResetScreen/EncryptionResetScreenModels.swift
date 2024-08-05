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

enum EncryptionResetScreenViewModelAction {
    case requestPassword
    case requestOIDCAuthorisation(url: URL)
    case resetFinished
    case cancel
}

struct EncryptionResetScreenViewState: BindableState {
    private let listItem3AttributedText = {
        let boldPlaceholder = "{bold}"
        var finalString = AttributedString(L10n.screenCreateNewRecoveryKeyListItem3(boldPlaceholder))
        var boldString = AttributedString(L10n.screenCreateNewRecoveryKeyListItem3ResetAll)
        boldString.bold()
        finalString.replace(boldPlaceholder, with: boldString)
        return finalString
    }()
    
    var listItems: [AttributedString] {
        [
            AttributedString(L10n.screenCreateNewRecoveryKeyListItem1(InfoPlistReader.main.productionAppName)),
            AttributedString(L10n.screenCreateNewRecoveryKeyListItem2),
            listItem3AttributedText,
            AttributedString(L10n.screenCreateNewRecoveryKeyListItem4),
            AttributedString(L10n.screenCreateNewRecoveryKeyListItem5)
        ]
    }

    var bindings: EncryptionResetScreenViewStateBindings
}

struct EncryptionResetScreenViewStateBindings {
    var alertInfo: AlertInfo<UUID>?
}

enum EncryptionResetScreenViewAction {
    case reset
    case cancel
}
