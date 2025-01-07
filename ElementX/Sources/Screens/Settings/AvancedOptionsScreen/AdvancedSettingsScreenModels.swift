//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct AdvancedSettingsScreenViewState: BindableState {
    var bindings: AdvancedSettingsScreenViewStateBindings
}

// periphery:ignore - subscript are seen as false positives
@dynamicMemberLookup
struct AdvancedSettingsScreenViewStateBindings {
    private let advancedSettings: AdvancedSettingsProtocol

    init(advancedSettings: AdvancedSettingsProtocol) {
        self.advancedSettings = advancedSettings
    }

    subscript<Setting>(dynamicMember keyPath: ReferenceWritableKeyPath<AdvancedSettingsProtocol, Setting>) -> Setting {
        get { advancedSettings[keyPath: keyPath] }
        set { advancedSettings[keyPath: keyPath] = newValue }
    }
}

enum AdvancedSettingsScreenViewAction {
    case optimizeMediaUploadsChanged
}

protocol AdvancedSettingsProtocol: AnyObject {
    var viewSourceEnabled: Bool { get set }
    var appAppearance: AppAppearance { get set }
    var sharePresence: Bool { get set }
    
    var optimizeMediaUploads: Bool { get set }
}

extension AppSettings: AdvancedSettingsProtocol { }
