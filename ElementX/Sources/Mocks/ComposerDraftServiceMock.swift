//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
