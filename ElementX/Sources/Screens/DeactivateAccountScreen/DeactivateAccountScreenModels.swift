//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum DeactivateAccountScreenViewModelAction {
    case accountDeactivated
}

struct DeactivateAccountScreenViewState: BindableState {
    let info: AttributedString
    let infoPoint1: AttributedString
    let infoPoint2 = AttributedString(L10n.screenDeactivateAccountListItem2)
    let infoPoint3 = AttributedString(L10n.screenDeactivateAccountListItem3)
    let infoPoint4 = AttributedString(L10n.screenDeactivateAccountListItem4)
    
    var bindings = DeactivateAccountScreenViewStateBindings()
    
    init() {
        let boldPlaceholder = "{bold}"
        var attributedString = AttributedString(L10n.screenDeactivateAccountDescription(boldPlaceholder))
        var boldString = AttributedString(L10n.screenDeactivateAccountDescriptionBoldPart)
        boldString.bold()
        attributedString.replace(boldPlaceholder, with: boldString)
        info = attributedString
        
        attributedString = AttributedString(L10n.screenDeactivateAccountListItem1(boldPlaceholder))
        boldString = AttributedString(L10n.screenDeactivateAccountListItem1BoldPart)
        boldString.bold()
        attributedString.replace(boldPlaceholder, with: boldString)
        infoPoint1 = attributedString
    }
}

struct DeactivateAccountScreenViewStateBindings {
    var password = ""
    var eraseData = false
    var alertInfo: AlertInfo<DeactivateAccountScreenAlert>?
}

enum DeactivateAccountScreenAlert {
    case confirmation
    case deactivationFailed
}

enum DeactivateAccountScreenViewAction {
    case deactivate
}
