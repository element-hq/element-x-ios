//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ComposerDraftServiceMockConfiguration {
    var draft: ComposerDraftProxy?
}

extension ComposerDraftServiceMock {
    convenience init(_ config: ComposerDraftServiceMockConfiguration) {
        self.init()
        loadDraftReturnValue = .success(config.draft)
        saveDraftReturnValue = .success(())
    }
}
