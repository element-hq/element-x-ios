//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated protocol SecurityAndPrivacyScreenHookProtocol: Sendable {
    @MainActor func update(_ viewState: SecurityAndPrivacyScreenViewState, homeserver: String) -> SecurityAndPrivacyScreenViewState
}

struct DefaultSecurityAndPrivacyScreenHook: SecurityAndPrivacyScreenHookProtocol {
    func update(_ viewState: SecurityAndPrivacyScreenViewState, homeserver: String) -> SecurityAndPrivacyScreenViewState {
        viewState
    }
}
