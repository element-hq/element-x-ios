//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SpaceSettingsScreenViewModelAction { }

struct SpaceSettingsScreenViewState: BindableState {
    var title: String
    var placeholder: String
    var counter = 0
    
    var bindings: SpaceSettingsScreenViewStateBindings
}

struct SpaceSettingsScreenViewStateBindings {
    var composerText: String
}

enum SpaceSettingsScreenViewAction {
    case done
    case textChanged
    
    case incrementCounter
    case decrementCounter
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}
