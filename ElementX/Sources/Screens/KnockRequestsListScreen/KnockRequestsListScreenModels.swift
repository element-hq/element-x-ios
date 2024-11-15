//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum KnockRequestsListScreenViewModelAction {
    case done
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}

struct KnockRequestsListScreenViewState: BindableState {
    var title: String
    var placeholder: String
    var bindings: KnockRequestsListScreenViewStateBindings
}

struct KnockRequestsListScreenViewStateBindings {
    var composerText: String
}

enum KnockRequestsListScreenViewAction {
    case done
    case textChanged
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}
