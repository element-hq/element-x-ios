//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct AvailableRecoveryOptionsTests {
    @Test(arguments: [SecureBackupRecoveryState.enabled, .incomplete, .disabled, .unknown, .settingUp])
    func otherVerifiedDeviceWinsRegardlessOfRecovery(recoveryState: SecureBackupRecoveryState) {
        #expect(AvailableRecoveryOptions(hasOtherVerifiedDevice: true, recoveryState: recoveryState) == .otherVerifiedDevice)
    }
    
    @Test
    func recoveryKeyOnlyWhenRecoveryIsEnabled() {
        #expect(AvailableRecoveryOptions(hasOtherVerifiedDevice: false, recoveryState: .enabled) == .recoveryKeyOnly)
    }
    
    @Test(arguments: [SecureBackupRecoveryState.incomplete, .disabled, .unknown, .settingUp])
    func noRecoveryUnlessRecoveryIsEnabled(recoveryState: SecureBackupRecoveryState) {
        #expect(AvailableRecoveryOptions(hasOtherVerifiedDevice: false, recoveryState: recoveryState) == .noOptions)
    }
}
