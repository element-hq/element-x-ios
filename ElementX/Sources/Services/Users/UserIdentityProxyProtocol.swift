//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

enum UserIdentityVerificationState {
    case notVerified
    case verified
    case verificationViolation
}

// sourcery: AutoMockable
protocol UserIdentityProxyProtocol {
    var verificationState: UserIdentityVerificationState { get }
}
