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

@Suite(.serialized)
@MainActor
final class AppLockServiceTests {
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
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
    // MARK: - PIN Code
    
    @Test
    func validPINCode() {
        // Given a service that hasn't been enabled.
        #expect(!service.isEnabled, "The service shouldn't be enabled to begin with.")
        
        // When setting a PIN code.
        let pinCode = "2023" // Highly secure PIN that is rotated every 12 months.
        guard case .success = service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        
        // Then service should be enabled and only the provided PIN should work to unlock the app.
        #expect(service.isEnabled, "The service should become enabled when setting a PIN.")
        #expect(service.unlock(with: pinCode), "The provided PIN code should work.")
        #expect(!service.unlock(with: "2024"), "No other PIN code should work.")
        #expect(!service.unlock(with: "1234"), "No other PIN code should work.")
        #expect(!service.unlock(with: "9999"), "No other PIN code should work.")
    }
    
    @Test
    func weakPINCode() {
        // Given a service that hasn't been enabled.
        #expect(!service.isEnabled, "The service shouldn't be enabled to begin with.")
        
        // When setting a PIN code that is in the block list.
        let pinCode = appSettings.appLockPINCodeBlockList[0]
        let result = service.setupPINCode(pinCode)
        
        // Then the setup should fail and the service be left as disabled.
        guard case let .failure(error) = result else {
            Issue.record("The call should have failed.")
            return
        }
        #expect(error == .weakPIN, "The PIN should be rejected as weak.")
        #expect(!service.isEnabled, "The service should remain disabled.")
    }
    
    @Test
    func shortPINCode() {
        // Given a service that hasn't been enabled.
        #expect(!service.isEnabled, "The service shouldn't be enabled to begin with.")
        
        // When setting a PIN code that is too short
        let pinCode = "123"
        let result = service.setupPINCode(pinCode)
        
        // Then the setup should fail and the service be left as disabled.
        guard case let .failure(error) = result else {
            Issue.record("The call should have failed.")
            return
        }
        #expect(error == .invalidPIN, "The PIN should be rejected as invalid.")
        #expect(!service.isEnabled, "The service should remain disabled.")
    }
    
    @Test
    func nonNumericPINCode() {
        // Given a service that hasn't been enabled.
        #expect(!service.isEnabled, "The service shouldn't be enabled to begin with.")
        
        // When setting a PIN code that is too short
        let pinCode = "abcd"
        let result = service.setupPINCode(pinCode)
        
        // Then the setup should fail and the service be left as disabled.
        guard case let .failure(error) = result else {
            Issue.record("The call should have failed.")
            return
        }
        #expect(error == .invalidPIN, "The PIN should be rejected as invalid.")
        #expect(!service.isEnabled, "The service should remain disabled.")
    }
    
    @Test
    func changePINCode() {
        // Given a service that is already enabled with a PIN.
        let pinCode = "2023"
        let newPINCode = "2024"
        guard case .success = service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        #expect(service.isEnabled, "The service should be enabled.")
        #expect(service.unlock(with: pinCode), "The initial PIN should work.")
        #expect(!service.unlock(with: newPINCode), "The PIN we're about to set should not work.")
        
        // When updating the PIN code.
        guard case .success = service.setupPINCode(newPINCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        
        // Then the old code should not be accepted.
        #expect(service.isEnabled, "The service should remain enabled.")
        #expect(service.unlock(with: newPINCode), "The new PIN should work.")
        #expect(!service.unlock(with: pinCode), "The original PIN should be rejected.")
    }
    
    @Test
    func invalidChangePINCode() {
        // Given a service that is already enabled with a PIN.
        let pinCode = "2023"
        let invalidPIN = appSettings.appLockPINCodeBlockList[0]
        guard case .success = service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        #expect(service.isEnabled, "The service should be enabled.")
        #expect(service.unlock(with: pinCode), "The initial PIN should work.")
        #expect(!service.unlock(with: invalidPIN), "The PIN we're about to set should not work.")
        
        // When updating the PIN code that is in the block list.
        let result = service.setupPINCode(invalidPIN)
        
        // Then it should fail and nothing should change.
        guard case let .failure(error) = result else {
            Issue.record("The call should have failed.")
            return
        }
        #expect(error == .weakPIN, "The PIN should be rejected as weak.")
        #expect(service.isEnabled, "The service should remain enabled.")
        #expect(!service.unlock(with: invalidPIN), "The rejected PIN shouldn't work.")
        #expect(service.unlock(with: pinCode), "The original PIN should continue to work.")
    }
    
    @Test
    func disablePINCode() {
        // Given a service that is already enabled with a PIN.
        let pinCode = "2023"
        guard case .success = service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        #expect(service.isEnabled, "The service should be enabled.")
        #expect(service.unlock(with: pinCode), "The initial PIN should work.")
        
        // When disabling the PIN code.
        service.disable()
        
        // Then the PIN code should be removed.
        #expect(!service.isEnabled, "The service should no longer be enabled.")
        #expect(!service.unlock(with: pinCode), "The initial PIN shouldn't work any more.")
    }
    
    // MARK: - Biometric Unlock
    
    @Test
    func enableBiometricUnlock() async {
        // Given a service with the PIN code already set.
        let context = LAContextMock()
        context.biometryTypeValue = .touchID
        context.evaluatedPolicyDomainStateValue = Data("👆".utf8)
        service = AppLockService(keychainController: keychainController, appSettings: appSettings, context: context)
        guard case .success = service.setupPINCode("2023") else {
            Issue.record("The PIN should be valid.")
            return
        }
        #expect(service.isEnabled, "The service should be enabled.")
        #expect(service.biometryType == .touchID, "The biometry type should be in sync with the mock.")
        #expect(!service.biometricUnlockEnabled, "Biometric unlock should not be enabled.")
        #expect(!service.biometricUnlockTrusted, "Biometric unlock should not be trusted.")
        
        // When enabling biometric unlock.
        guard case .success = service.enableBiometricUnlock() else {
            Issue.record("The biometric lock should enable.")
            return
        }
        context.evaluatePolicyReturnValue = true
        
        // Then the service should be unlockable with biometrics.
        #expect(service.biometryType == .touchID, "The biometry type should not change.")
        #expect(service.biometricUnlockEnabled, "Biometric unlock should now be enabled.")
        #expect(service.biometricUnlockTrusted, "Biometric unlock should now be trusted.")
        guard await service.unlockWithBiometrics() == .unlocked else {
            Issue.record("The biometric unlock should work.")
            return
        }
    }
    
    @Test
    func biometricUnlockTrust() {
        // Given a service with the PIN code already set.
        let context = LAContextMock()
        context.biometryTypeValue = .touchID
        context.evaluatedPolicyDomainStateValue = Data("👆".utf8)
        service = AppLockService(keychainController: keychainController, appSettings: appSettings, context: context)
        let pinCode = "2023"
        guard case .success = service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        guard case .success = service.enableBiometricUnlock() else {
            Issue.record("The biometric lock should enable.")
            return
        }
        #expect(service.isEnabled, "The service should be enabled.")
        #expect(service.biometryType == .touchID, "The biometry type should be in sync with the mock.")
        #expect(service.biometricUnlockEnabled, "Biometric unlock should be enabled.")
        #expect(service.biometricUnlockTrusted, "Biometric unlock should be trusted.")
        
        // When the user changes biometric data.
        context.evaluatedPolicyDomainStateValue = Data("👈".utf8)
        
        // Then biometric lock should remain enabled but untrusted.
        #expect(service.isEnabled, "The service should remain enabled.")
        #expect(service.biometryType == .touchID, "The biometry type should not change.")
        #expect(service.biometricUnlockEnabled, "Biometric unlock should remain enabled.")
        #expect(!service.biometricUnlockTrusted, "Biometric unlock should no longer be trusted.")
        
        // When the user confirms their PIN code.
        #expect(service.unlock(with: pinCode), "The PIN code should be accepted")
        
        // Then the biometric lock should once again be trusted.
        #expect(service.isEnabled, "The service should remain enabled.")
        #expect(service.biometryType == .touchID, "The biometry type should not change.")
        #expect(service.biometricUnlockEnabled, "Biometric unlock should remain enabled.")
        #expect(service.biometricUnlockTrusted, "Biometric unlock should once again be trusted.")
    }
    
    @Test
    func disableBiometricUnlock() {
        // Given a service with the PIN code already set.
        let context = LAContextMock()
        context.biometryTypeValue = .touchID
        context.evaluatedPolicyDomainStateValue = Data("👆".utf8)
        service = AppLockService(keychainController: keychainController, appSettings: appSettings, context: context)
        guard case .success = service.setupPINCode("2023") else {
            Issue.record("The PIN should be valid.")
            return
        }
        guard case .success = service.enableBiometricUnlock() else {
            Issue.record("The biometric lock should enable.")
            return
        }
        #expect(service.isEnabled, "The service should be enabled.")
        #expect(service.biometryType == .touchID, "The biometry type should be in sync with the mock.")
        #expect(service.biometricUnlockEnabled, "Biometric unlock should be enabled.")
        #expect(service.biometricUnlockTrusted, "Biometric unlock should be trusted.")
        
        // When disabling biometric unlock.
        service.disableBiometricUnlock()
        
        // Then only PIN unlock should remain enabled.
        #expect(service.isEnabled, "The service should remain enabled.")
        #expect(service.biometryType == .touchID, "The biometry type should not change.")
        #expect(!service.biometricUnlockEnabled, "Biometric unlock should become disabled.")
        #expect(!service.biometricUnlockTrusted, "Biometric unlock should no longer be trusted.")
    }
    
    @Test
    func disablePINWithBiometricUnlock() {
        // Given a service with the PIN code already set.
        let context = LAContextMock()
        context.biometryTypeValue = .touchID
        context.evaluatedPolicyDomainStateValue = Data("👆".utf8)
        service = AppLockService(keychainController: keychainController, appSettings: appSettings, context: context)
        guard case .success = service.setupPINCode("2023") else {
            Issue.record("The PIN should be valid.")
            return
        }
        guard case .success = service.enableBiometricUnlock() else {
            Issue.record("The biometric lock should enable.")
            return
        }
        #expect(service.isEnabled, "The service should be enabled.")
        #expect(service.biometricUnlockEnabled, "Biometric unlock should be enabled.")
        #expect(service.biometricUnlockTrusted, "Biometric unlock should be trusted.")
        
        // When disabling the PIN lock.
        service.disable()
        
        // Then both PIN and biometric unlock should be disabled.
        #expect(!service.isEnabled, "The service should remain enabled.")
        #expect(!service.biometricUnlockEnabled, "Biometric unlock should become disabled.")
        #expect(!service.biometricUnlockTrusted, "Biometric unlock should no longer be trusted.")
    }
    
    // MARK: - Attempt failures
    
    @Test
    func resetAttemptsOnUnlock() {
        // Given a service that is enabled and has failed unlock attempts.
        let pinCode = "2023"
        guard case .success = service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        appSettings.appLockNumberOfPINAttempts = 2
        #expect(appSettings.appLockNumberOfPINAttempts == 2, "The initial conditions should be stored.")
        #expect(service.isEnabled, "The service should be enabled.")
        
        // When unlocking the service
        #expect(service.unlock(with: pinCode), "The PIN should work.")
        
        // Then the attempts counts should both be reset.
        #expect(appSettings.appLockNumberOfPINAttempts == 0, "The PIN attempts should be reset.")
    }
    
    @Test
    func resetAttemptsOnDisable() {
        // Given a service that is enabled and has failed unlock attempts.
        let pinCode = "2023"
        guard case .success = service.setupPINCode(pinCode) else {
            Issue.record("The PIN should be valid.")
            return
        }
        appSettings.appLockNumberOfPINAttempts = 2
        #expect(appSettings.appLockNumberOfPINAttempts == 2, "The initial conditions should be stored.")
        #expect(service.isEnabled, "The service should be enabled.")
        
        // When disabling the service
        service.disable()
        #expect(!service.isEnabled, "The service should be disabled.")
        
        // Then the attempts counts should both be reset.
        #expect(appSettings.appLockNumberOfPINAttempts == 0, "The PIN attempts should be reset.")
    }
}
