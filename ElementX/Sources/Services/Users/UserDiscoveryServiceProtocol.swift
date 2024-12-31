//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum UserDiscoveryErrorType: Error {
    case failedSearchingUsers
}

// sourcery: AutoMockable
protocol UserDiscoveryServiceProtocol {
    func searchProfiles(with searchQuery: String) async -> Result<[UserProfileProxy], UserDiscoveryErrorType>
}
