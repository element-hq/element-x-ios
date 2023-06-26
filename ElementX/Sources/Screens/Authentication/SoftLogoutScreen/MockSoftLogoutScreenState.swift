//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
