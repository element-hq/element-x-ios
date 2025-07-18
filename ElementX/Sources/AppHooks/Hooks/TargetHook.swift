//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol TargetHookProtocol {
    func update(_ configuration: Target.Configuration, with appSettings: CommonSettingsProtocol)
}

struct DefaultTargetHook: TargetHookProtocol {
    func update(_ configuration: Target.Configuration, with appSettings: CommonSettingsProtocol) { }
}
