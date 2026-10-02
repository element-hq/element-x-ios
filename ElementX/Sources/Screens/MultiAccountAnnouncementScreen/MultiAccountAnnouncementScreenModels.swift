//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum MultiAccountAnnouncementScreenViewModelAction {
    case addAccount
    case dismiss
}

struct MultiAccountAnnouncementScreenViewState: BindableState {
    let description: AttributedString
    
    init() {
        let boldPlaceholder = "{bold}"
        var description = AttributedString(UntranslatedL10n.screenRoomlistAddAccountSheetDescription(boldPlaceholder))
        var boldString = AttributedString("\(L10n.commonSettings) > \(L10n.screenSettingsAddAccount)")
        boldString.bold()
        description.replace(boldPlaceholder, with: boldString)
        self.description = description
    }
}

enum MultiAccountAnnouncementScreenViewAction {
    case addAccount
    case close
}
