//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class EncryptionSettingsUITests: XCTestCase {
    var app: XCUIApplication!
    
    @MainActor enum Step {
        static let secureBackupScreenSetUp = 0
        static let keyBackupScreen = 1
        static let secureBackupScreenDisabled = 2
        static let setUpRecovery = 3
        static let changeRecovery = 4
        
        static let secureBackupScreenOutOfSync = 5
        static let confirmRecovery = 6
    }
    
    func testFlow() async throws {
        app = Application.launch(.encryptionSettings)
        
        // Starting with key storage and recovery enabled.
        try await app.assertScreenshot(step: Step.secureBackupScreenSetUp)
        
        // Toggle key storage off.
        // app.switches[A11yIdentifiers.secureBackupScreen.keyStorage].tap()
        // Broken by https://github.com/element-hq/compound-ios/pull/140
        app.switches[A11yIdentifiers.secureBackupScreen.keyStorage].switches.firstMatch.tap()
        
        // Has been failing often on CI, reasons unclear.
        try await app.assertScreenshot(step: Step.keyBackupScreen, delay: .seconds(1))
        
        // Confirm deletion of keys.
        app.buttons[A11yIdentifiers.secureBackupKeyBackupScreen.deleteKeyStorage].tap()
        app.buttons[A11yIdentifiers.alertInfo.primaryButton].firstMatch.tap()
        try await app.assertScreenshot(step: Step.secureBackupScreenDisabled)
        
        // Toggle key storage back on and set up recovery.
        // app.switches[A11yIdentifiers.secureBackupScreen.keyStorage].tap()
        // Broken by https://github.com/element-hq/compound-ios/pull/140
        app.switches[A11yIdentifiers.secureBackupScreen.keyStorage].switches.firstMatch.switches.firstMatch.tap()
        app.buttons[A11yIdentifiers.secureBackupScreen.recoveryKey].tap()
        
        try await app.assertScreenshot(step: Step.setUpRecovery)
        
        // Generate and copy a new recovery key.
        app.buttons[A11yIdentifiers.secureBackupRecoveryKeyScreen.generateRecoveryKey].tap()
        app.buttons[A11yIdentifiers.secureBackupRecoveryKeyScreen.copyRecoveryKey].tap()
        app.buttons[A11yIdentifiers.secureBackupRecoveryKeyScreen.done].tap()
        app.buttons[A11yIdentifiers.alertInfo.primaryButton].firstMatch.tap()
        try await app.assertScreenshot(step: Step.secureBackupScreenSetUp)
        
        // Change the recovery key.
        app.buttons[A11yIdentifiers.secureBackupScreen.recoveryKey].tap()
        try await app.assertScreenshot(step: Step.changeRecovery)
        
        // Generate and copy the updated recovery key.
        app.buttons[A11yIdentifiers.secureBackupRecoveryKeyScreen.generateRecoveryKey].tap()
        app.buttons[A11yIdentifiers.secureBackupRecoveryKeyScreen.copyRecoveryKey].tap()
        app.buttons[A11yIdentifiers.secureBackupRecoveryKeyScreen.done].tap()
        app.buttons[A11yIdentifiers.alertInfo.primaryButton].firstMatch.tap()
        try await app.assertScreenshot(step: Step.secureBackupScreenSetUp)
    }
    
    func testOutOfSyncFlow() async throws {
        app = Application.launch(.encryptionSettingsOutOfSync)
        
        // Starting with key storage and recovery enabled.
        try await app.assertScreenshot(step: Step.secureBackupScreenOutOfSync)
        
        // Confirm the recovery key.
        app.buttons[A11yIdentifiers.secureBackupScreen.recoveryKey].tap()
        try await app.assertScreenshot(step: Step.confirmRecovery)
        
        // Enter the recovery key and submit.
        let recoveryKeyField = app.secureTextFields[A11yIdentifiers.secureBackupRecoveryKeyScreen.recoveryKeyField]
        recoveryKeyField.clearAndTypeText("sUpe RSec rEtR Ecov ERYk Ey12", app: app)
        app.buttons[A11yIdentifiers.secureBackupRecoveryKeyScreen.confirm].tap()
        try await app.assertScreenshot(step: Step.secureBackupScreenSetUp)
    }
}
