//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

extension AnalyticsServiceMock {
    struct Configuration {
        var isEnabled = false
        var shouldShowAnalyticsPrompt = false
        var signpost = Signposter()
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        isEnabled = configuration.isEnabled
        shouldShowAnalyticsPrompt = configuration.shouldShowAnalyticsPrompt
        signpost = configuration.signpost
    }
}
