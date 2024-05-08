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

enum AdvancedSettingsScreenViewAction { }

protocol AdvancedSettingsProtocol: AnyObject {
    var timelineStyle: TimelineStyle { get set }
    var viewSourceEnabled: Bool { get set }
    var appAppearance: AppAppearance { get set }
    var sharePresence: Bool { get set }
}

extension AppSettings: AdvancedSettingsProtocol { }
