//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct LocationSharingSettingsScreenViewState: BindableState {
    init(bindings: LocationSharingSettingsScreenViewStateBindings) {
        self.bindings = bindings
        
        let linkPlaceholder = "{link}"
        var footerString = AttributedString(L10n.screenAdvancedSettingsLiveLocationSectionFooter(linkPlaceholder))
        var linkString = AttributedString(L10n.screenAdvancedSettingsLiveLocationSectionFooterLink)
        linkString.link = URL(string: UIApplication.openSettingsURLString)
        linkString.bold()
        footerString.replace(linkPlaceholder, with: linkString)
        liveLocationUpdateFooterAttributedString = footerString
    }
    
    let liveLocationUpdateFooterAttributedString: AttributedString
    var bindings: LocationSharingSettingsScreenViewStateBindings
}

struct LocationSharingSettingsScreenViewStateBindings {
    private let userSettings: UserSettings
    
    init(userSettings: UserSettings) {
        self.userSettings = userSettings
    }
    
    var liveLocationMinimumDistanceUpdate: Int {
        get { userSettings.app.liveLocationMinimumDistanceUpdate }
        set { userSettings.app.liveLocationMinimumDistanceUpdate = newValue }
    }
}

enum LocationSharingSettingsScreenViewAction { }
