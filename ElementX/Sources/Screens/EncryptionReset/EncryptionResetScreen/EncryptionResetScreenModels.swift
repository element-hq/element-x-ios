//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
