//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A type that represents how to set up the analytics module in the app.
struct AnalyticsConfiguration {
    /// The host to use for PostHog analytics.
    let host: String
    /// The public key for submitting analytics.
    let apiKey: String
}
