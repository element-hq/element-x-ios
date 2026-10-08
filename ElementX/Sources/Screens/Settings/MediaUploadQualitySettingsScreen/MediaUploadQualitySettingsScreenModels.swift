//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct MediaUploadQualitySettingsScreenViewState: BindableState {
    var bindings: MediaUploadQualitySettingsScreenViewStateBindings
}

struct MediaUploadQualitySettingsScreenViewStateBindings {
    private let userSettings: UserSettings
    
    init(userSettings: UserSettings) {
        self.userSettings = userSettings
    }
    
    var optimizeMediaUploads: Bool {
        get { userSettings.app.optimizeMediaUploads }
        set { userSettings.app.optimizeMediaUploads = newValue }
    }
}

enum MediaUploadQualitySettingsScreenViewAction {
    case optimizeMediaUploadsChanged
}
