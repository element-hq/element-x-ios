//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The push notification provider used for delivering remote notifications.
enum PushProvider: Codable {
    /// Use APNs directly (default Element X behavior).
    case apns
    /// Use Firebase Cloud Messaging as a wrapper around APNs.
    case firebase
}
