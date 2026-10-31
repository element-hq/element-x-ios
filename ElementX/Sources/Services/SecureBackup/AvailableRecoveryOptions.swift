//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

/// What the user has to get their encrypted chats back if they remove this device, which decides how the removal is presented.
enum AvailableRecoveryOptions: Equatable {
    /// The user has another verified device, so the removal only needs a light warning.
    case otherVerifiedDevice
    /// This is the only verified device but the user has a recovery key.
    case recoveryKeyOnly
    /// This is the only verified device and the user doesn't have a recovery key.
    case noOptions
    
    init(hasOtherVerifiedDevice: Bool, recoveryState: SecureBackupRecoveryState) {
        self = if hasOtherVerifiedDevice {
            .otherVerifiedDevice
        } else if recoveryState == .enabled {
            .recoveryKeyOnly
        } else {
            .noOptions
        }
    }
}
