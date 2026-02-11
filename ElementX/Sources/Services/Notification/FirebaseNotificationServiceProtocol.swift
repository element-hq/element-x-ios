//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// sourcery: AutoMockable
protocol FirebaseNotificationServiceProtocol {
    func configure(onTokenUpdate: @escaping (String) -> Void)
    func currentToken() async -> String?
}
