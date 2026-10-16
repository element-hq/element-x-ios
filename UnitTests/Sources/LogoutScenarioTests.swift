//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct LogoutScenarioTests {
    @Test(arguments: [SecureBackupRecoveryState.enabled, .incomplete, .disabled, .unknown, .settingUp])
    func otherVerifiedDeviceWinsRegardlessOfRecovery(recoveryState: SecureBackupRecoveryState) {
        #expect(LogoutScenario(hasOtherDevice: true, recoveryState: recoveryState) == .hasOtherVerifiedDevice)
    }
    
    @Test
    func recoveryKeyOnlyWhenRecoveryIsEnabled() {
        #expect(LogoutScenario(hasOtherDevice: false, recoveryState: .enabled) == .hasRecoveryKeyOnly)
    }
    
    @Test(arguments: [SecureBackupRecoveryState.incomplete, .disabled, .unknown, .settingUp])
    func noRecoveryUnlessRecoveryIsEnabled(recoveryState: SecureBackupRecoveryState) {
        #expect(LogoutScenario(hasOtherDevice: false, recoveryState: recoveryState) == .hasNoRecovery)
    }
}
