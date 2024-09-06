//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockSoftLogoutScreenState: String, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case emptyPassword
    case enteredPassword
    case oidc
    case unsupported
    case keyBackupNeeded

    /// Generate the view struct for the screen state.
    @MainActor var viewModel: SoftLogoutScreenViewModel {
        let credentials = SoftLogoutScreenCredentials(userID: "@mock:matrix.org",
                                                      homeserverName: "matrix.org",
                                                      userDisplayName: "mock",
                                                      deviceID: nil)
        switch self {
        case .emptyPassword:
            return SoftLogoutScreenViewModel(credentials: credentials,
                                             homeserver: .mockMatrixDotOrg,
                                             keyBackupNeeded: false)
        case .enteredPassword:
            return SoftLogoutScreenViewModel(credentials: credentials,
                                             homeserver: .mockMatrixDotOrg,
                                             keyBackupNeeded: false,
                                             password: "12345678")
        case .oidc:
            return SoftLogoutScreenViewModel(credentials: credentials,
                                             homeserver: .mockOIDC,
                                             keyBackupNeeded: false)
        case .unsupported:
            return SoftLogoutScreenViewModel(credentials: credentials,
                                             homeserver: .mockUnsupported,
                                             keyBackupNeeded: false)
        case .keyBackupNeeded:
            return SoftLogoutScreenViewModel(credentials: credentials,
                                             homeserver: .mockMatrixDotOrg,
                                             keyBackupNeeded: true)
        }
    }
}

extension MockSoftLogoutScreenState: Identifiable {
    var id: String {
        rawValue
    }
}
