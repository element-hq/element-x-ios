//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// A type that represents how to set up the analytics module in the app.
struct AnalyticsConfiguration {
    /// Whether or not analytics should be enabled.
    let isEnabled: Bool
    /// The host to use for PostHog analytics.
    let host: String
    /// The public key for submitting analytics.
    let apiKey: String
    /// The URL to open with more information about analytics terms.
    let termsURL: URL
}
