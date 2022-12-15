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
import UIKit

enum SettingsViewModelAction {
    case close
    case toggleAnalytics
    case reportBug
    case crash
    case logout
}

struct SettingsViewState: BindableState {
    var bindings: SettingsViewStateBindings
    var userID: String
    var userAvatar: UIImage?
    var userDisplayName: String?
}

struct SettingsViewStateBindings {
    var enableAnalytics = ServiceLocator.shared.settings.enableAnalytics
}

enum SettingsViewAction {
    case close
    case toggleAnalytics
    case reportBug
    case crash
    case logout
}
