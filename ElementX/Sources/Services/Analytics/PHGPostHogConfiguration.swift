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
        let postHogConfiguration = PostHogConfig(projectToken: analyticsConfiguration.apiKey, host: analyticsConfiguration.host)
        // We capture screens manually
        postHogConfiguration.captureScreenViews = false
        postHogConfiguration.surveys = false
        
        // Should be disabled by the swizzling config below, but also seriously, wtf PostHog?!
        postHogConfiguration.capturePushNotificationSubscriptions = false
        postHogConfiguration.capturePushNotificationOpened = false
        
        // We only want to track the events provided by the AnalyticsEvents package
        postHogConfiguration.enableSwizzling = false
        postHogConfiguration.captureApplicationLifecycleEvents = false
        
        // We don't use PostHog feature flags, don't fetch them
        postHogConfiguration.preloadFeatureFlags = false
        
        // Off by default but spelled out so a PostHog default flip doesn't silently enable them
        postHogConfiguration.sessionReplay = false
        postHogConfiguration.captureElementInteractions = false
        postHogConfiguration.errorTrackingConfig.autoCapture = false
        
        return postHogConfiguration
    }
}
