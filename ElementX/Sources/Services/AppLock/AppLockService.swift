//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import LocalAuthentication

/// The service responsible for locking and unlocking the app.
class AppLockService: AppLockServiceProtocol {
    private let keychainController: KeychainControllerProtocol
    private let appSettings: AppSettings
    private let context: LAContext
    
    private let timer: AppLockTimer
    private let unlockPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
    
    var isMandatory: Bool { appSettings.appLockIsMandatory }
    
    var isEnabled: Bool {
        do {
            return try keychainController.containsPINCode()
        } catch {
            MXLog.error("Keychain access error: \(error)")
            MXLog.error("Locking the app.")
            return true
        }
    }
    
    private var isEnabledSubject: PassthroughSubject<Bool, Never> = .init()
    var isEnabledPublisher: AnyPublisher<Bool, Never> { isEnabledSubject.eraseToAnyPublisher() }
    
    var biometryType: LABiometryType {
        updateBiometrics()
        guard context.evaluatedPolicyDomainState != nil else { return .none }
        return context.biometryType
    }
    
    var biometricUnlockEnabled: Bool {
        keychainController.containsPINCodeBiometricState()
    }
    
    var biometricUnlockTrusted: Bool {
        guard let state = keychainController.pinCodeBiometricState() else { return false }
        updateBiometrics()
        return state == context.evaluatedPolicyDomainState
    }
    
    var numberOfPINAttempts: AnyPublisher<Int, Never> { appSettings.$appLockNumberOfPINAttempts }
    
    init(keychainController: KeychainControllerProtocol, appSettings: AppSettings, context: LAContext = .init()) {
        self.keychainController = keychainController
        self.appSettings = appSettings
        self.context = context
        timer = AppLockTimer(gracePeriod: appSettings.appLockGracePeriod)
        
        updateBiometrics()
    }
    
    func setupPINCode(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        let result = validate(pinCode)
        guard case .success = result else { return result }
        
        do {
            try keychainController.setPINCode(pinCode)
            isEnabledSubject.send(true)
            return .success(())
        } catch {
            MXLog.error("Keychain access error: \(error)")
            return .failure(.keychainError)
        }
    }
    
    func validate(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        guard pinCode.count == 4, pinCode.allSatisfy(\.isNumber) else { return .failure(.invalidPIN) }
        guard !appSettings.appLockPINCodeBlockList.contains(pinCode) else { return .failure(.weakPIN) }
        return .success(())
    }
    
    func enableBiometricUnlock() -> Result<Void, AppLockServiceError> {
        guard isEnabled else { return .failure(.pinNotSet) }
        guard let state = context.evaluatedPolicyDomainState else { return .failure(.biometricUnlockNotSupported) }
        
        do {
            try keychainController.setPINCodeBiometricState(state)
            return .success(())
        } catch {
            MXLog.error("Keychain access error: \(error)")
            return .failure(.keychainError)
        }
    }
    
    func disableBiometricUnlock() {
        keychainController.removePINCodeBiometricState()
    }
    
    func disable() {
        keychainController.removePINCode()
        keychainController.removePINCodeBiometricState()
        appSettings.appLockNumberOfPINAttempts = 0
        isEnabledSubject.send(false)
    }
    
    func applicationDidEnterBackground() {
        timer.applicationDidEnterBackground()
    }
    
    func computeNeedsUnlock(didBecomeActiveAt date: Date) -> Bool {
        timer.computeLockState(didBecomeActiveAt: date)
    }
    
    func unlock(with pinCode: String) -> Bool {
        guard pinCode == keychainController.pinCode() else {
            MXLog.warning("Wrong PIN entered.")
            appSettings.appLockNumberOfPINAttempts += 1
            return false
        }
        
        if biometricUnlockEnabled, !biometricUnlockTrusted {
            MXLog.info("Fixing trust for biometric unlock.")
            updateBiometrics()
            _ = enableBiometricUnlock()
        }
        
        completeUnlock()
        return true
    }
    
    func unlockWithBiometrics() async -> AppLockServiceBiometricResult {
        guard biometryType != .none, biometricUnlockEnabled else {
            MXLog.error("Biometric unlock not setup.")
            return .failed
        }
        
        guard biometricUnlockTrusted else {
            MXLog.error("Biometrics have changed. PIN should be shown.")
            return .failed
        }
        
        do {
            let context = unlockContext()
            guard try await context.evaluatePolicy(unlockPolicy, localizedReason: L10n.screenAppLockBiometricUnlockReasonIos) else {
                MXLog.warning("\(context.biometryType) failed without error.")
                return .failed
            }
            completeUnlock()
            return .unlocked
        } catch LAError.systemCancel {
            MXLog.error("\(context.biometryType) failed: The system cancelled.")
            return .interrupted
        } catch {
            MXLog.error("\(context.biometryType) failed: \(error)")
            return .failed
        }
    }
    
    // MARK: - Private
    
    /// Queries the context for supported biometrics and enrolment state.
    private func updateBiometrics() {
        var error: NSError?
        context.canEvaluatePolicy(unlockPolicy, error: &error)
        
        if let error {
            MXLog.error("Biometrics error: \(error)")
        }
    }
    
    /// Creates a context specifically for unlocking the app. The titles are customised,
    /// and the fresh context ensures that the user is promoted to unlock based on
    /// `timer.gracePeriod` rather than any system to defined grace period.
    private func unlockContext() -> LAContext {
        // Keep using the injected context for tests etc.
        guard type(of: context) == LAContext.self else { return context }
        
        let context = LAContext()
        context.localizedFallbackTitle = L10n.actionEnterPin
        return context
    }
    
    /// Shared logic for completing an unlock via a PIN or biometrics.
    private func completeUnlock() {
        timer.registerUnlock()
        appSettings.appLockNumberOfPINAttempts = 0
    }
}
