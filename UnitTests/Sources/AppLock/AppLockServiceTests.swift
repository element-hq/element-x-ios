//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@MainActor
@Suite(.serialized)
struct AppLockServiceTests {
    private var keychainController: KeychainController
    private var appSettings: AppSettings
    private var service: AppLockService
    
    init() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        
        keychainController = KeychainController(service: .tests, accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
        keychainController.resetSecrets()
        
        service = AppLockService(keychainController: keychainController, appSettings: appSettings)
        service.disable()
    }
    
    // MARK: - PIN Code
    
    @Test
    func validPINCode() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service that hasn't been enabled.
        #expect(!testSetup.service.isEnabled, "The service shouldn't be enabled to begin with.")
        
        // When setting a PIN code.
        let pinCode = "2023" // Highly secure PIN that is rotated every 12 months.
        guard case .success = testSetup.service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        
        // Then service should be enabled and only the provided PIN should work to unlock the app.
        #expect(testSetup.service.isEnabled, "The service should become enabled when setting a PIN.")
        #expect(testSetup.service.unlock(with: pinCode), "The provided PIN code should work.")
        #expect(!testSetup.service.unlock(with: "2024"), "No other PIN code should work.")
        #expect(!testSetup.service.unlock(with: "1234"), "No other PIN code should work.")
        #expect(!testSetup.service.unlock(with: "9999"), "No other PIN code should work.")
    }
    
    @Test
    func weakPINCode() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service that hasn't been enabled.
        #expect(!testSetup.service.isEnabled, "The service shouldn't be enabled to begin with.")
        
        // When setting a PIN code that is in the block list.
        let pinCode = testSetup.appSettings.appLockPINCodeBlockList[0]
        let result = testSetup.service.setupPINCode(pinCode)
        
        // Then the setup should fail and the service be left as disabled.
        guard case let .failure(error) = result else {
            Issue.record("The call should have failed.")
            return
        }
        #expect(error == .weakPIN, "The PIN should be rejected as weak.")
        #expect(!testSetup.service.isEnabled, "The service should remain disabled.")
    }
    
    @Test
    func shortPINCode() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service that hasn't been enabled.
        #expect(!testSetup.service.isEnabled, "The service shouldn't be enabled to begin with.")
        
        // When setting a PIN code that is too short
        let pinCode = "123"
        let result = testSetup.service.setupPINCode(pinCode)
        
        // Then the setup should fail and the service be left as disabled.
        guard case let .failure(error) = result else {
            Issue.record("The call should have failed.")
            return
        }
        #expect(error == .invalidPIN, "The PIN should be rejected as invalid.")
        #expect(!testSetup.service.isEnabled, "The service should remain disabled.")
    }
    
    @Test
    func nonNumericPINCode() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service that hasn't been enabled.
        #expect(!testSetup.service.isEnabled, "The service shouldn't be enabled to begin with.")
        
        // When setting a PIN code that is too short
        let pinCode = "abcd"
        let result = testSetup.service.setupPINCode(pinCode)
        
        // Then the setup should fail and the service be left as disabled.
        guard case let .failure(error) = result else {
            Issue.record("The call should have failed.")
            return
        }
        #expect(error == .invalidPIN, "The PIN should be rejected as invalid.")
        #expect(!testSetup.service.isEnabled, "The service should remain disabled.")
    }
    
    @Test
    func changePINCode() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service that is already enabled with a PIN.
        let pinCode = "2023"
        let newPINCode = "2024"
        guard case .success = testSetup.service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        #expect(testSetup.service.isEnabled, "The service should be enabled.")
        #expect(testSetup.service.unlock(with: pinCode), "The initial PIN should work.")
        #expect(!testSetup.service.unlock(with: newPINCode), "The PIN we're about to set should not work.")
        
        // When updating the PIN code.
        guard case .success = testSetup.service.setupPINCode(newPINCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        
        // Then the old code should not be accepted.
        #expect(testSetup.service.isEnabled, "The service should remain enabled.")
        #expect(testSetup.service.unlock(with: newPINCode), "The new PIN should work.")
        #expect(!testSetup.service.unlock(with: pinCode), "The original PIN should be rejected.")
    }
    
    @Test
    func invalidChangePINCode() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service that is already enabled with a PIN.
        let pinCode = "2023"
        let invalidPIN = testSetup.appSettings.appLockPINCodeBlockList[0]
        guard case .success = testSetup.service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        #expect(testSetup.service.isEnabled, "The service should be enabled.")
        #expect(testSetup.service.unlock(with: pinCode), "The initial PIN should work.")
        #expect(!testSetup.service.unlock(with: invalidPIN), "The PIN we're about to set should not work.")
        
        // When updating the PIN code that is in the block list.
        let result = testSetup.service.setupPINCode(invalidPIN)
        
        // Then it should fail and nothing should change.
        guard case let .failure(error) = result else {
            Issue.record("The call should have failed.")
            return
        }
        #expect(error == .weakPIN, "The PIN should be rejected as weak.")
        #expect(testSetup.service.isEnabled, "The service should remain enabled.")
        #expect(!testSetup.service.unlock(with: invalidPIN), "The rejected PIN shouldn't work.")
        #expect(testSetup.service.unlock(with: pinCode), "The original PIN should continue to work.")
    }
    
    @Test
    func disablePINCode() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service that is already enabled with a PIN.
        let pinCode = "2023"
        guard case .success = testSetup.service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        #expect(testSetup.service.isEnabled, "The service should be enabled.")
        #expect(testSetup.service.unlock(with: pinCode), "The initial PIN should work.")
        
        // When disabling the PIN code.
        testSetup.service.disable()
        
        // Then the PIN code should be removed.
        #expect(!testSetup.service.isEnabled, "The service should no longer be enabled.")
        #expect(!testSetup.service.unlock(with: pinCode), "The initial PIN shouldn't work any more.")
    }
    
    // MARK: - Biometric Unlock
    
    @Test
    func enableBiometricUnlock() async {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service with the PIN code already set.
        let context = LAContextMock()
        context.biometryTypeValue = .touchID
        context.evaluatedPolicyDomainStateValue = Data("👆".utf8)
        testSetup.service = AppLockService(keychainController: testSetup.keychainController, appSettings: testSetup.appSettings, context: context)
        guard case .success = testSetup.service.setupPINCode("2023") else {
            Issue.record("The PIN should be valid.")
            return
        }
        #expect(testSetup.service.isEnabled, "The service should be enabled.")
        #expect(testSetup.service.biometryType == .touchID, "The biometry type should be in sync with the mock.")
        #expect(!testSetup.service.biometricUnlockEnabled, "Biometric unlock should not be enabled.")
        #expect(!testSetup.service.biometricUnlockTrusted, "Biometric unlock should not be trusted.")
        
        // When enabling biometric unlock.
        guard case .success = testSetup.service.enableBiometricUnlock() else {
            Issue.record("The biometric lock should enable.")
            return
        }
        context.evaluatePolicyReturnValue = true
        
        // Then the service should be unlockable with biometrics.
        #expect(testSetup.service.biometryType == .touchID, "The biometry type should not change.")
        #expect(testSetup.service.biometricUnlockEnabled, "Biometric unlock should now be enabled.")
        #expect(testSetup.service.biometricUnlockTrusted, "Biometric unlock should now be trusted.")
        guard await testSetup.service.unlockWithBiometrics() == .unlocked else {
            Issue.record("The biometric unlock should work.")
            return
        }
    }
    
    @Test
    func biometricUnlockTrust() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service with the PIN code already set.
        let context = LAContextMock()
        context.biometryTypeValue = .touchID
        context.evaluatedPolicyDomainStateValue = Data("👆".utf8)
        testSetup.service = AppLockService(keychainController: testSetup.keychainController, appSettings: testSetup.appSettings, context: context)
        let pinCode = "2023"
        guard case .success = testSetup.service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        guard case .success = testSetup.service.enableBiometricUnlock() else {
            Issue.record("The biometric lock should enable.")
            return
        }
        #expect(testSetup.service.isEnabled, "The service should be enabled.")
        #expect(testSetup.service.biometryType == .touchID, "The biometry type should be in sync with the mock.")
        #expect(testSetup.service.biometricUnlockEnabled, "Biometric unlock should be enabled.")
        #expect(testSetup.service.biometricUnlockTrusted, "Biometric unlock should be trusted.")
        
        // When the user changes biometric data.
        context.evaluatedPolicyDomainStateValue = Data("👈".utf8)
        
        // Then biometric lock should remain enabled but untrusted.
        #expect(testSetup.service.isEnabled, "The service should remain enabled.")
        #expect(testSetup.service.biometryType == .touchID, "The biometry type should not change.")
        #expect(testSetup.service.biometricUnlockEnabled, "Biometric unlock should remain enabled.")
        #expect(!testSetup.service.biometricUnlockTrusted, "Biometric unlock should no longer be trusted.")
        
        // When the user confirms their PIN code.
        #expect(testSetup.service.unlock(with: pinCode), "The PIN code should be accepted")
        
        // Then the biometric lock should once again be trusted.
        #expect(testSetup.service.isEnabled, "The service should remain enabled.")
        #expect(testSetup.service.biometryType == .touchID, "The biometry type should not change.")
        #expect(testSetup.service.biometricUnlockEnabled, "Biometric unlock should remain enabled.")
        #expect(testSetup.service.biometricUnlockTrusted, "Biometric unlock should once again be trusted.")
    }
    
    @Test
    func disableBiometricUnlock() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service with the PIN code already set.
        let context = LAContextMock()
        context.biometryTypeValue = .touchID
        context.evaluatedPolicyDomainStateValue = Data("👆".utf8)
        testSetup.service = AppLockService(keychainController: testSetup.keychainController, appSettings: testSetup.appSettings, context: context)
        guard case .success = testSetup.service.setupPINCode("2023") else {
            Issue.record("The PIN should be valid.")
            return
        }
        guard case .success = testSetup.service.enableBiometricUnlock() else {
            Issue.record("The biometric lock should enable.")
            return
        }
        #expect(testSetup.service.isEnabled, "The service should be enabled.")
        #expect(testSetup.service.biometryType == .touchID, "The biometry type should be in sync with the mock.")
        #expect(testSetup.service.biometricUnlockEnabled, "Biometric unlock should be enabled.")
        #expect(testSetup.service.biometricUnlockTrusted, "Biometric unlock should be trusted.")
        
        // When disabling biometric unlock.
        testSetup.service.disableBiometricUnlock()
        
        // Then only PIN unlock should remain enabled.
        #expect(testSetup.service.isEnabled, "The service should remain enabled.")
        #expect(testSetup.service.biometryType == .touchID, "The biometry type should not change.")
        #expect(!testSetup.service.biometricUnlockEnabled, "Biometric unlock should become disabled.")
        #expect(!testSetup.service.biometricUnlockTrusted, "Biometric unlock should no longer be trusted.")
    }
    
    @Test
    func disablePINWithBiometricUnlock() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service with the PIN code already set.
        let context = LAContextMock()
        context.biometryTypeValue = .touchID
        context.evaluatedPolicyDomainStateValue = Data("👆".utf8)
        testSetup.service = AppLockService(keychainController: testSetup.keychainController, appSettings: testSetup.appSettings, context: context)
        guard case .success = testSetup.service.setupPINCode("2023") else {
            Issue.record("The PIN should be valid.")
            return
        }
        guard case .success = testSetup.service.enableBiometricUnlock() else {
            Issue.record("The biometric lock should enable.")
            return
        }
        #expect(testSetup.service.isEnabled, "The service should be enabled.")
        #expect(testSetup.service.biometricUnlockEnabled, "Biometric unlock should be enabled.")
        #expect(testSetup.service.biometricUnlockTrusted, "Biometric unlock should be trusted.")
        
        // When disabling the PIN lock.
        testSetup.service.disable()
        
        // Then both PIN and biometric unlock should be disabled.
        #expect(!testSetup.service.isEnabled, "The service should remain enabled.")
        #expect(!testSetup.service.biometricUnlockEnabled, "Biometric unlock should become disabled.")
        #expect(!testSetup.service.biometricUnlockTrusted, "Biometric unlock should no longer be trusted.")
    }
    
    // MARK: - Attempt failures
    
    @Test
    func resetAttemptsOnUnlock() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service that is enabled and has failed unlock attempts.
        let pinCode = "2023"
        guard case .success = testSetup.service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        testSetup.appSettings.appLockNumberOfPINAttempts = 2
        #expect(testSetup.appSettings.appLockNumberOfPINAttempts == 2, "The initial conditions should be stored.")
        #expect(testSetup.service.isEnabled, "The service should be enabled.")
        
        // When unlocking the service
        #expect(testSetup.service.unlock(with: pinCode), "The PIN should work.")
        
        // Then the attempts counts should both be reset.
        #expect(testSetup.appSettings.appLockNumberOfPINAttempts == 0, "The PIN attempts should be reset.")
    }
    
    @Test
    func resetAttemptsOnDisable() {
        var testSetup = self
        defer { AppSettings.resetAllSettings() }
        
        // Given a service that is enabled and has failed unlock attempts.
        let pinCode = "2023"
        guard case .success = testSetup.service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        testSetup.appSettings.appLockNumberOfPINAttempts = 2
        #expect(testSetup.appSettings.appLockNumberOfPINAttempts == 2, "The initial conditions should be stored.")
        #expect(testSetup.service.isEnabled, "The service should be enabled.")
        
        // When disabling the service
        testSetup.service.disable()
        #expect(!testSetup.service.isEnabled, "The service should be disabled.")
        
        // Then the attempts counts should both be reset.
        #expect(testSetup.appSettings.appLockNumberOfPINAttempts == 0, "The PIN attempts should be reset.")
    }
}
