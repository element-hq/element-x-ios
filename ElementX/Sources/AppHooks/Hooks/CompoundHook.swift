//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound

nonisolated protocol CompoundHookProtocol: Sendable {
    // periphery:ignore:parameters colors,uiColors - part of the hook signature
    @MainActor func override(colors: CompoundColors, uiColors: CompoundUIColors)
}

struct DefaultCompoundHook: CompoundHookProtocol {
    // periphery:ignore:parameters colors,uiColors - part of the hook signature
    func override(colors: CompoundColors, uiColors: CompoundUIColors) { }
}
