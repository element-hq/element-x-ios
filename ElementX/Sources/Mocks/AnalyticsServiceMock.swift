//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

extension AnalyticsServiceMock {
    static func `default`() -> AnalyticsServiceMock {
        let mock = AnalyticsServiceMock()
        mock.isEnabled = false
        mock.shouldShowAnalyticsPrompt = false
        mock.signpost = Signposter()
        return mock
    }
}
