//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum TemplateScreenViewModelAction {
    case done
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}

struct TemplateScreenViewState: BindableState {
    var title: String
    var placeholder: String
    var counter = 0
    
    var bindings: TemplateScreenViewStateBindings
}

struct TemplateScreenViewStateBindings {
    var composerText: String
}

enum TemplateScreenViewAction {
    case done
    case textChanged
    
    case incrementCounter
    case decrementCounter
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}
