//
// Copyright 2025 Element Creations Ltd.
// Copyright 2021-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import PostHog

extension PostHogConfig {
    static func standard(analyticsConfiguration: AnalyticsConfiguration) -> PostHogConfig? {
        let postHogConfiguration = PostHogConfig(apiKey: analyticsConfiguration.apiKey, host: analyticsConfiguration.host)
        // We capture screens manually
        postHogConfiguration.captureScreenViews = false
        postHogConfiguration.surveys = false
        
        return postHogConfiguration
    }
}
