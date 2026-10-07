//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum LabsScreenViewModelAction {
    case clearCache
}

struct LabsScreenViewState: BindableState {
    var bindings: LabsScreenViewStateBindings
}

struct LabsScreenViewStateBindings {
    private let userSettings: UserSettings
    
    init(userSettings: UserSettings) {
        self.userSettings = userSettings
    }
    
    var threadsEnabled: Bool {
        get { userSettings.threadsEnabled }
        set { userSettings.threadsEnabled = newValue }
    }
    
    var galleryEnabled: Bool {
        get { userSettings.galleryEnabled }
        set { userSettings.galleryEnabled = newValue }
    }
    
    var knockingEnabled: Bool {
        get { userSettings.knockingEnabled }
        set { userSettings.knockingEnabled = newValue }
    }
}

enum LabsScreenViewAction {
    case clearCache
}
