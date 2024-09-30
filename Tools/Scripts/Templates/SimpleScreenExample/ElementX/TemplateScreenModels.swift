//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum TemplateScreenViewModelAction {
    case done
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}

struct TemplateScreenViewState: BindableState {
    var title: String
    var placeholder: String
    var bindings: TemplateScreenViewStateBindings
}

struct TemplateScreenViewStateBindings {
    var composerText: String
}

enum TemplateScreenViewAction {
    case done
    case textChanged
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}
