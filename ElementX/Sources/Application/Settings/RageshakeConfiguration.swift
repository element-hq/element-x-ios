//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A type that represents how rageshakes are collected by the app.
enum RageshakeConfiguration: Equatable, Codable {
    /// Rageshakes should be sent to the provided URL
    case url(URL)
    /// Rageshakes are disabled.
    case disabled
}
