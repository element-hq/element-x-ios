// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
import AnalyticsEvents
import AVFoundation
import Combine
import Foundation
import LocalAuthentication
import MatrixRustSDK
import SwiftUI
class AnalyticsClientMock: AnalyticsClientProtocol {
    var isRunning: Bool {
        get { return underlyingIsRunning }
        set(value) { underlyingIsRunning = value }
    }
    var underlyingIsRunning: Bool!

    //MARK: - start

    var startAnalyticsConfigurationUnderlyingCallsCount = 0
    var startAnalyticsConfigurationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return startAnalyticsConfigurationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = startAnalyticsConfigurationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startAnalyticsConfigurationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    startAnalyticsConfigurationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var startAnalyticsConfigurationCalled: Bool {
        return startAnalyticsConfigurationCallsCount > 0
    }
    var startAnalyticsConfigurationReceivedAnalyticsConfiguration: AnalyticsConfiguration?
    var startAnalyticsConfigurationReceivedInvocations: [AnalyticsConfiguration] = []
    var startAnalyticsConfigurationClosure: ((AnalyticsConfiguration) -> Void)?

    func start(analyticsConfiguration: AnalyticsConfiguration) {
        startAnalyticsConfigurationCallsCount += 1
        startAnalyticsConfigurationReceivedAnalyticsConfiguration = analyticsConfiguration
        DispatchQueue.main.async {
            self.startAnalyticsConfigurationReceivedInvocations.append(analyticsConfiguration)
        }
        startAnalyticsConfigurationClosure?(analyticsConfiguration)
    }
    //MARK: - reset

    var resetUnderlyingCallsCount = 0
    var resetCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resetUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resetUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resetUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCount += 1
        resetClosure?()
    }
    //MARK: - stop

    var stopUnderlyingCallsCount = 0
    var stopCallsCount: Int {
        get {
            if Thread.isMainThread {
                return stopUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = stopUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stopUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    stopUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCount += 1
        stopClosure?()
    }
    //MARK: - capture

    var captureUnderlyingCallsCount = 0
    var captureCallsCount: Int {
        get {
            if Thread.isMainThread {
                return captureUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = captureUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                captureUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    captureUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var captureCalled: Bool {
        return captureCallsCount > 0
    }
    var captureReceivedEvent: AnalyticsEventProtocol?
    var captureReceivedInvocations: [AnalyticsEventProtocol] = []
    var captureClosure: ((AnalyticsEventProtocol) -> Void)?

    func capture(_ event: AnalyticsEventProtocol) {
        captureCallsCount += 1
        captureReceivedEvent = event
        DispatchQueue.main.async {
            self.captureReceivedInvocations.append(event)
        }
        captureClosure?(event)
    }
    //MARK: - screen

    var screenUnderlyingCallsCount = 0
    var screenCallsCount: Int {
        get {
            if Thread.isMainThread {
                return screenUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = screenUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                screenUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    screenUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var screenCalled: Bool {
        return screenCallsCount > 0
    }
    var screenReceivedEvent: AnalyticsScreenProtocol?
    var screenReceivedInvocations: [AnalyticsScreenProtocol] = []
    var screenClosure: ((AnalyticsScreenProtocol) -> Void)?

    func screen(_ event: AnalyticsScreenProtocol) {
        screenCallsCount += 1
        screenReceivedEvent = event
        DispatchQueue.main.async {
            self.screenReceivedInvocations.append(event)
        }
        screenClosure?(event)
    }
    //MARK: - updateUserProperties

    var updateUserPropertiesUnderlyingCallsCount = 0
    var updateUserPropertiesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return updateUserPropertiesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = updateUserPropertiesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                updateUserPropertiesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    updateUserPropertiesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var updateUserPropertiesCalled: Bool {
        return updateUserPropertiesCallsCount > 0
    }
    var updateUserPropertiesReceivedEvent: AnalyticsEvent.UserProperties?
    var updateUserPropertiesReceivedInvocations: [AnalyticsEvent.UserProperties] = []
    var updateUserPropertiesClosure: ((AnalyticsEvent.UserProperties) -> Void)?

    func updateUserProperties(_ event: AnalyticsEvent.UserProperties) {
        updateUserPropertiesCallsCount += 1
        updateUserPropertiesReceivedEvent = event
        DispatchQueue.main.async {
            self.updateUserPropertiesReceivedInvocations.append(event)
        }
        updateUserPropertiesClosure?(event)
    }
}
class AppLockServiceMock: AppLockServiceProtocol {
    var isMandatory: Bool {
        get { return underlyingIsMandatory }
        set(value) { underlyingIsMandatory = value }
    }
    var underlyingIsMandatory: Bool!
    var isEnabled: Bool {
        get { return underlyingIsEnabled }
        set(value) { underlyingIsEnabled = value }
    }
    var underlyingIsEnabled: Bool!
    var isEnabledPublisher: AnyPublisher<Bool, Never> {
        get { return underlyingIsEnabledPublisher }
        set(value) { underlyingIsEnabledPublisher = value }
    }
    var underlyingIsEnabledPublisher: AnyPublisher<Bool, Never>!
    var biometryType: LABiometryType {
        get { return underlyingBiometryType }
        set(value) { underlyingBiometryType = value }
    }
    var underlyingBiometryType: LABiometryType!
    var biometricUnlockEnabled: Bool {
        get { return underlyingBiometricUnlockEnabled }
        set(value) { underlyingBiometricUnlockEnabled = value }
    }
    var underlyingBiometricUnlockEnabled: Bool!
    var biometricUnlockTrusted: Bool {
        get { return underlyingBiometricUnlockTrusted }
        set(value) { underlyingBiometricUnlockTrusted = value }
    }
    var underlyingBiometricUnlockTrusted: Bool!
    var numberOfPINAttempts: AnyPublisher<Int, Never> {
        get { return underlyingNumberOfPINAttempts }
        set(value) { underlyingNumberOfPINAttempts = value }
    }
    var underlyingNumberOfPINAttempts: AnyPublisher<Int, Never>!

    //MARK: - setupPINCode

    var setupPINCodeUnderlyingCallsCount = 0
    var setupPINCodeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setupPINCodeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setupPINCodeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setupPINCodeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setupPINCodeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setupPINCodeCalled: Bool {
        return setupPINCodeCallsCount > 0
    }
    var setupPINCodeReceivedPinCode: String?
    var setupPINCodeReceivedInvocations: [String] = []

    var setupPINCodeUnderlyingReturnValue: Result<Void, AppLockServiceError>!
    var setupPINCodeReturnValue: Result<Void, AppLockServiceError>! {
        get {
            if Thread.isMainThread {
                return setupPINCodeUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, AppLockServiceError>? = nil
                DispatchQueue.main.sync {
                    returnValue = setupPINCodeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setupPINCodeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    setupPINCodeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var setupPINCodeClosure: ((String) -> Result<Void, AppLockServiceError>)?

    func setupPINCode(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        setupPINCodeCallsCount += 1
        setupPINCodeReceivedPinCode = pinCode
        DispatchQueue.main.async {
            self.setupPINCodeReceivedInvocations.append(pinCode)
        }
        if let setupPINCodeClosure = setupPINCodeClosure {
            return setupPINCodeClosure(pinCode)
        } else {
            return setupPINCodeReturnValue
        }
    }
    //MARK: - validate

    var validateUnderlyingCallsCount = 0
    var validateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return validateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = validateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                validateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    validateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var validateCalled: Bool {
        return validateCallsCount > 0
    }
    var validateReceivedPinCode: String?
    var validateReceivedInvocations: [String] = []

    var validateUnderlyingReturnValue: Result<Void, AppLockServiceError>!
    var validateReturnValue: Result<Void, AppLockServiceError>! {
        get {
            if Thread.isMainThread {
                return validateUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, AppLockServiceError>? = nil
                DispatchQueue.main.sync {
                    returnValue = validateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                validateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    validateUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var validateClosure: ((String) -> Result<Void, AppLockServiceError>)?

    func validate(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        validateCallsCount += 1
        validateReceivedPinCode = pinCode
        DispatchQueue.main.async {
            self.validateReceivedInvocations.append(pinCode)
        }
        if let validateClosure = validateClosure {
            return validateClosure(pinCode)
        } else {
            return validateReturnValue
        }
    }
    //MARK: - enableBiometricUnlock

    var enableBiometricUnlockUnderlyingCallsCount = 0
    var enableBiometricUnlockCallsCount: Int {
        get {
            if Thread.isMainThread {
                return enableBiometricUnlockUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = enableBiometricUnlockUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enableBiometricUnlockUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    enableBiometricUnlockUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var enableBiometricUnlockCalled: Bool {
        return enableBiometricUnlockCallsCount > 0
    }

    var enableBiometricUnlockUnderlyingReturnValue: Result<Void, AppLockServiceError>!
    var enableBiometricUnlockReturnValue: Result<Void, AppLockServiceError>! {
        get {
            if Thread.isMainThread {
                return enableBiometricUnlockUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, AppLockServiceError>? = nil
                DispatchQueue.main.sync {
                    returnValue = enableBiometricUnlockUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enableBiometricUnlockUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    enableBiometricUnlockUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var enableBiometricUnlockClosure: (() -> Result<Void, AppLockServiceError>)?

    func enableBiometricUnlock() -> Result<Void, AppLockServiceError> {
        enableBiometricUnlockCallsCount += 1
        if let enableBiometricUnlockClosure = enableBiometricUnlockClosure {
            return enableBiometricUnlockClosure()
        } else {
            return enableBiometricUnlockReturnValue
        }
    }
    //MARK: - disableBiometricUnlock

    var disableBiometricUnlockUnderlyingCallsCount = 0
    var disableBiometricUnlockCallsCount: Int {
        get {
            if Thread.isMainThread {
                return disableBiometricUnlockUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = disableBiometricUnlockUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                disableBiometricUnlockUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    disableBiometricUnlockUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var disableBiometricUnlockCalled: Bool {
        return disableBiometricUnlockCallsCount > 0
    }
    var disableBiometricUnlockClosure: (() -> Void)?

    func disableBiometricUnlock() {
        disableBiometricUnlockCallsCount += 1
        disableBiometricUnlockClosure?()
    }
    //MARK: - disable

    var disableUnderlyingCallsCount = 0
    var disableCallsCount: Int {
        get {
            if Thread.isMainThread {
                return disableUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = disableUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                disableUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    disableUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var disableCalled: Bool {
        return disableCallsCount > 0
    }
    var disableClosure: (() -> Void)?

    func disable() {
        disableCallsCount += 1
        disableClosure?()
    }
    //MARK: - applicationDidEnterBackground

    var applicationDidEnterBackgroundUnderlyingCallsCount = 0
    var applicationDidEnterBackgroundCallsCount: Int {
        get {
            if Thread.isMainThread {
                return applicationDidEnterBackgroundUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = applicationDidEnterBackgroundUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                applicationDidEnterBackgroundUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    applicationDidEnterBackgroundUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var applicationDidEnterBackgroundCalled: Bool {
        return applicationDidEnterBackgroundCallsCount > 0
    }
    var applicationDidEnterBackgroundClosure: (() -> Void)?

    func applicationDidEnterBackground() {
        applicationDidEnterBackgroundCallsCount += 1
        applicationDidEnterBackgroundClosure?()
    }
    //MARK: - computeNeedsUnlock

    var computeNeedsUnlockDidBecomeActiveAtUnderlyingCallsCount = 0
    var computeNeedsUnlockDidBecomeActiveAtCallsCount: Int {
        get {
            if Thread.isMainThread {
                return computeNeedsUnlockDidBecomeActiveAtUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = computeNeedsUnlockDidBecomeActiveAtUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                computeNeedsUnlockDidBecomeActiveAtUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    computeNeedsUnlockDidBecomeActiveAtUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var computeNeedsUnlockDidBecomeActiveAtCalled: Bool {
        return computeNeedsUnlockDidBecomeActiveAtCallsCount > 0
    }
    var computeNeedsUnlockDidBecomeActiveAtReceivedDate: Date?
    var computeNeedsUnlockDidBecomeActiveAtReceivedInvocations: [Date] = []

    var computeNeedsUnlockDidBecomeActiveAtUnderlyingReturnValue: Bool!
    var computeNeedsUnlockDidBecomeActiveAtReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return computeNeedsUnlockDidBecomeActiveAtUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = computeNeedsUnlockDidBecomeActiveAtUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                computeNeedsUnlockDidBecomeActiveAtUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    computeNeedsUnlockDidBecomeActiveAtUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var computeNeedsUnlockDidBecomeActiveAtClosure: ((Date) -> Bool)?

    func computeNeedsUnlock(didBecomeActiveAt date: Date) -> Bool {
        computeNeedsUnlockDidBecomeActiveAtCallsCount += 1
        computeNeedsUnlockDidBecomeActiveAtReceivedDate = date
        DispatchQueue.main.async {
            self.computeNeedsUnlockDidBecomeActiveAtReceivedInvocations.append(date)
        }
        if let computeNeedsUnlockDidBecomeActiveAtClosure = computeNeedsUnlockDidBecomeActiveAtClosure {
            return computeNeedsUnlockDidBecomeActiveAtClosure(date)
        } else {
            return computeNeedsUnlockDidBecomeActiveAtReturnValue
        }
    }
    //MARK: - unlock

    var unlockWithUnderlyingCallsCount = 0
    var unlockWithCallsCount: Int {
        get {
            if Thread.isMainThread {
                return unlockWithUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = unlockWithUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unlockWithUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    unlockWithUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var unlockWithCalled: Bool {
        return unlockWithCallsCount > 0
    }
    var unlockWithReceivedPinCode: String?
    var unlockWithReceivedInvocations: [String] = []

    var unlockWithUnderlyingReturnValue: Bool!
    var unlockWithReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return unlockWithUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = unlockWithUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unlockWithUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    unlockWithUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var unlockWithClosure: ((String) -> Bool)?

    func unlock(with pinCode: String) -> Bool {
        unlockWithCallsCount += 1
        unlockWithReceivedPinCode = pinCode
        DispatchQueue.main.async {
            self.unlockWithReceivedInvocations.append(pinCode)
        }
        if let unlockWithClosure = unlockWithClosure {
            return unlockWithClosure(pinCode)
        } else {
            return unlockWithReturnValue
        }
    }
    //MARK: - unlockWithBiometrics

    var unlockWithBiometricsUnderlyingCallsCount = 0
    var unlockWithBiometricsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return unlockWithBiometricsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = unlockWithBiometricsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unlockWithBiometricsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    unlockWithBiometricsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var unlockWithBiometricsCalled: Bool {
        return unlockWithBiometricsCallsCount > 0
    }

    var unlockWithBiometricsUnderlyingReturnValue: AppLockServiceBiometricResult!
    var unlockWithBiometricsReturnValue: AppLockServiceBiometricResult! {
        get {
            if Thread.isMainThread {
                return unlockWithBiometricsUnderlyingReturnValue
            } else {
                var returnValue: AppLockServiceBiometricResult? = nil
                DispatchQueue.main.sync {
                    returnValue = unlockWithBiometricsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unlockWithBiometricsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    unlockWithBiometricsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var unlockWithBiometricsClosure: (() async -> AppLockServiceBiometricResult)?

    func unlockWithBiometrics() async -> AppLockServiceBiometricResult {
        unlockWithBiometricsCallsCount += 1
        if let unlockWithBiometricsClosure = unlockWithBiometricsClosure {
            return await unlockWithBiometricsClosure()
        } else {
            return unlockWithBiometricsReturnValue
        }
    }
}
class AppMediatorMock: AppMediatorProtocol {
    var windowManager: WindowManagerProtocol {
        get { return underlyingWindowManager }
        set(value) { underlyingWindowManager = value }
    }
    var underlyingWindowManager: WindowManagerProtocol!
    var networkMonitor: NetworkMonitorProtocol {
        get { return underlyingNetworkMonitor }
        set(value) { underlyingNetworkMonitor = value }
    }
    var underlyingNetworkMonitor: NetworkMonitorProtocol!
    var appState: UIApplication.State {
        get { return underlyingAppState }
        set(value) { underlyingAppState = value }
    }
    var underlyingAppState: UIApplication.State!

    //MARK: - beginBackgroundTask

    var beginBackgroundTaskExpirationHandlerUnderlyingCallsCount = 0
    var beginBackgroundTaskExpirationHandlerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return beginBackgroundTaskExpirationHandlerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = beginBackgroundTaskExpirationHandlerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                beginBackgroundTaskExpirationHandlerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    beginBackgroundTaskExpirationHandlerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var beginBackgroundTaskExpirationHandlerCalled: Bool {
        return beginBackgroundTaskExpirationHandlerCallsCount > 0
    }

    var beginBackgroundTaskExpirationHandlerUnderlyingReturnValue: UIBackgroundTaskIdentifier!
    var beginBackgroundTaskExpirationHandlerReturnValue: UIBackgroundTaskIdentifier! {
        get {
            if Thread.isMainThread {
                return beginBackgroundTaskExpirationHandlerUnderlyingReturnValue
            } else {
                var returnValue: UIBackgroundTaskIdentifier? = nil
                DispatchQueue.main.sync {
                    returnValue = beginBackgroundTaskExpirationHandlerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                beginBackgroundTaskExpirationHandlerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    beginBackgroundTaskExpirationHandlerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var beginBackgroundTaskExpirationHandlerClosure: (((() -> Void)?) -> UIBackgroundTaskIdentifier)?

    func beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        beginBackgroundTaskExpirationHandlerCallsCount += 1
        if let beginBackgroundTaskExpirationHandlerClosure = beginBackgroundTaskExpirationHandlerClosure {
            return beginBackgroundTaskExpirationHandlerClosure(handler)
        } else {
            return beginBackgroundTaskExpirationHandlerReturnValue
        }
    }
    //MARK: - endBackgroundTask

    var endBackgroundTaskUnderlyingCallsCount = 0
    var endBackgroundTaskCallsCount: Int {
        get {
            if Thread.isMainThread {
                return endBackgroundTaskUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = endBackgroundTaskUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                endBackgroundTaskUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    endBackgroundTaskUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var endBackgroundTaskCalled: Bool {
        return endBackgroundTaskCallsCount > 0
    }
    var endBackgroundTaskReceivedIdentifier: UIBackgroundTaskIdentifier?
    var endBackgroundTaskReceivedInvocations: [UIBackgroundTaskIdentifier] = []
    var endBackgroundTaskClosure: ((UIBackgroundTaskIdentifier) -> Void)?

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        endBackgroundTaskCallsCount += 1
        endBackgroundTaskReceivedIdentifier = identifier
        DispatchQueue.main.async {
            self.endBackgroundTaskReceivedInvocations.append(identifier)
        }
        endBackgroundTaskClosure?(identifier)
    }
    //MARK: - open

    var openUnderlyingCallsCount = 0
    var openCallsCount: Int {
        get {
            if Thread.isMainThread {
                return openUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = openUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                openUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    openUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var openCalled: Bool {
        return openCallsCount > 0
    }
    var openReceivedUrl: URL?
    var openReceivedInvocations: [URL] = []
    var openClosure: ((URL) -> Void)?

    func open(_ url: URL) {
        openCallsCount += 1
        openReceivedUrl = url
        DispatchQueue.main.async {
            self.openReceivedInvocations.append(url)
        }
        openClosure?(url)
    }
    //MARK: - openAppSettings

    var openAppSettingsUnderlyingCallsCount = 0
    var openAppSettingsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return openAppSettingsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = openAppSettingsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                openAppSettingsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    openAppSettingsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var openAppSettingsCalled: Bool {
        return openAppSettingsCallsCount > 0
    }
    var openAppSettingsClosure: (() -> Void)?

    func openAppSettings() {
        openAppSettingsCallsCount += 1
        openAppSettingsClosure?()
    }
    //MARK: - setIdleTimerDisabled

    var setIdleTimerDisabledUnderlyingCallsCount = 0
    var setIdleTimerDisabledCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setIdleTimerDisabledUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setIdleTimerDisabledUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setIdleTimerDisabledUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setIdleTimerDisabledUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setIdleTimerDisabledCalled: Bool {
        return setIdleTimerDisabledCallsCount > 0
    }
    var setIdleTimerDisabledReceivedDisabled: Bool?
    var setIdleTimerDisabledReceivedInvocations: [Bool] = []
    var setIdleTimerDisabledClosure: ((Bool) -> Void)?

    func setIdleTimerDisabled(_ disabled: Bool) {
        setIdleTimerDisabledCallsCount += 1
        setIdleTimerDisabledReceivedDisabled = disabled
        DispatchQueue.main.async {
            self.setIdleTimerDisabledReceivedInvocations.append(disabled)
        }
        setIdleTimerDisabledClosure?(disabled)
    }
    //MARK: - requestAuthorizationIfNeeded

    var requestAuthorizationIfNeededUnderlyingCallsCount = 0
    var requestAuthorizationIfNeededCallsCount: Int {
        get {
            if Thread.isMainThread {
                return requestAuthorizationIfNeededUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = requestAuthorizationIfNeededUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                requestAuthorizationIfNeededUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    requestAuthorizationIfNeededUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var requestAuthorizationIfNeededCalled: Bool {
        return requestAuthorizationIfNeededCallsCount > 0
    }

    var requestAuthorizationIfNeededUnderlyingReturnValue: Bool!
    var requestAuthorizationIfNeededReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return requestAuthorizationIfNeededUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = requestAuthorizationIfNeededUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                requestAuthorizationIfNeededUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    requestAuthorizationIfNeededUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var requestAuthorizationIfNeededClosure: (() async -> Bool)?

    func requestAuthorizationIfNeeded() async -> Bool {
        requestAuthorizationIfNeededCallsCount += 1
        if let requestAuthorizationIfNeededClosure = requestAuthorizationIfNeededClosure {
            return await requestAuthorizationIfNeededClosure()
        } else {
            return requestAuthorizationIfNeededReturnValue
        }
    }
}
class AudioConverterMock: AudioConverterProtocol {

    //MARK: - convertToOpusOgg

    var convertToOpusOggSourceURLDestinationURLThrowableError: Error?
    var convertToOpusOggSourceURLDestinationURLUnderlyingCallsCount = 0
    var convertToOpusOggSourceURLDestinationURLCallsCount: Int {
        get {
            if Thread.isMainThread {
                return convertToOpusOggSourceURLDestinationURLUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = convertToOpusOggSourceURLDestinationURLUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                convertToOpusOggSourceURLDestinationURLUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    convertToOpusOggSourceURLDestinationURLUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var convertToOpusOggSourceURLDestinationURLCalled: Bool {
        return convertToOpusOggSourceURLDestinationURLCallsCount > 0
    }
    var convertToOpusOggSourceURLDestinationURLReceivedArguments: (sourceURL: URL, destinationURL: URL)?
    var convertToOpusOggSourceURLDestinationURLReceivedInvocations: [(sourceURL: URL, destinationURL: URL)] = []
    var convertToOpusOggSourceURLDestinationURLClosure: ((URL, URL) throws -> Void)?

    func convertToOpusOgg(sourceURL: URL, destinationURL: URL) throws {
        if let error = convertToOpusOggSourceURLDestinationURLThrowableError {
            throw error
        }
        convertToOpusOggSourceURLDestinationURLCallsCount += 1
        convertToOpusOggSourceURLDestinationURLReceivedArguments = (sourceURL: sourceURL, destinationURL: destinationURL)
        DispatchQueue.main.async {
            self.convertToOpusOggSourceURLDestinationURLReceivedInvocations.append((sourceURL: sourceURL, destinationURL: destinationURL))
        }
        try convertToOpusOggSourceURLDestinationURLClosure?(sourceURL, destinationURL)
    }
    //MARK: - convertToMPEG4AAC

    var convertToMPEG4AACSourceURLDestinationURLThrowableError: Error?
    var convertToMPEG4AACSourceURLDestinationURLUnderlyingCallsCount = 0
    var convertToMPEG4AACSourceURLDestinationURLCallsCount: Int {
        get {
            if Thread.isMainThread {
                return convertToMPEG4AACSourceURLDestinationURLUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = convertToMPEG4AACSourceURLDestinationURLUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                convertToMPEG4AACSourceURLDestinationURLUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    convertToMPEG4AACSourceURLDestinationURLUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var convertToMPEG4AACSourceURLDestinationURLCalled: Bool {
        return convertToMPEG4AACSourceURLDestinationURLCallsCount > 0
    }
    var convertToMPEG4AACSourceURLDestinationURLReceivedArguments: (sourceURL: URL, destinationURL: URL)?
    var convertToMPEG4AACSourceURLDestinationURLReceivedInvocations: [(sourceURL: URL, destinationURL: URL)] = []
    var convertToMPEG4AACSourceURLDestinationURLClosure: ((URL, URL) throws -> Void)?

    func convertToMPEG4AAC(sourceURL: URL, destinationURL: URL) throws {
        if let error = convertToMPEG4AACSourceURLDestinationURLThrowableError {
            throw error
        }
        convertToMPEG4AACSourceURLDestinationURLCallsCount += 1
        convertToMPEG4AACSourceURLDestinationURLReceivedArguments = (sourceURL: sourceURL, destinationURL: destinationURL)
        DispatchQueue.main.async {
            self.convertToMPEG4AACSourceURLDestinationURLReceivedInvocations.append((sourceURL: sourceURL, destinationURL: destinationURL))
        }
        try convertToMPEG4AACSourceURLDestinationURLClosure?(sourceURL, destinationURL)
    }
}
class AudioPlayerMock: AudioPlayerProtocol {
    var actions: AnyPublisher<AudioPlayerAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<AudioPlayerAction, Never>!
    var mediaSource: MediaSourceProxy?
    var duration: TimeInterval {
        get { return underlyingDuration }
        set(value) { underlyingDuration = value }
    }
    var underlyingDuration: TimeInterval!
    var currentTime: TimeInterval {
        get { return underlyingCurrentTime }
        set(value) { underlyingCurrentTime = value }
    }
    var underlyingCurrentTime: TimeInterval!
    var url: URL?
    var state: MediaPlayerState {
        get { return underlyingState }
        set(value) { underlyingState = value }
    }
    var underlyingState: MediaPlayerState!

    //MARK: - load

    var loadMediaSourceUsingAutoplayUnderlyingCallsCount = 0
    var loadMediaSourceUsingAutoplayCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadMediaSourceUsingAutoplayUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaSourceUsingAutoplayUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaSourceUsingAutoplayUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaSourceUsingAutoplayUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadMediaSourceUsingAutoplayCalled: Bool {
        return loadMediaSourceUsingAutoplayCallsCount > 0
    }
    var loadMediaSourceUsingAutoplayReceivedArguments: (mediaSource: MediaSourceProxy, url: URL, autoplay: Bool)?
    var loadMediaSourceUsingAutoplayReceivedInvocations: [(mediaSource: MediaSourceProxy, url: URL, autoplay: Bool)] = []
    var loadMediaSourceUsingAutoplayClosure: ((MediaSourceProxy, URL, Bool) -> Void)?

    func load(mediaSource: MediaSourceProxy, using url: URL, autoplay: Bool) {
        loadMediaSourceUsingAutoplayCallsCount += 1
        loadMediaSourceUsingAutoplayReceivedArguments = (mediaSource: mediaSource, url: url, autoplay: autoplay)
        DispatchQueue.main.async {
            self.loadMediaSourceUsingAutoplayReceivedInvocations.append((mediaSource: mediaSource, url: url, autoplay: autoplay))
        }
        loadMediaSourceUsingAutoplayClosure?(mediaSource, url, autoplay)
    }
    //MARK: - reset

    var resetUnderlyingCallsCount = 0
    var resetCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resetUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resetUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resetUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCount += 1
        resetClosure?()
    }
    //MARK: - play

    var playUnderlyingCallsCount = 0
    var playCallsCount: Int {
        get {
            if Thread.isMainThread {
                return playUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = playUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                playUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    playUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var playCalled: Bool {
        return playCallsCount > 0
    }
    var playClosure: (() -> Void)?

    func play() {
        playCallsCount += 1
        playClosure?()
    }
    //MARK: - pause

    var pauseUnderlyingCallsCount = 0
    var pauseCallsCount: Int {
        get {
            if Thread.isMainThread {
                return pauseUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = pauseUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pauseUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    pauseUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var pauseCalled: Bool {
        return pauseCallsCount > 0
    }
    var pauseClosure: (() -> Void)?

    func pause() {
        pauseCallsCount += 1
        pauseClosure?()
    }
    //MARK: - stop

    var stopUnderlyingCallsCount = 0
    var stopCallsCount: Int {
        get {
            if Thread.isMainThread {
                return stopUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = stopUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stopUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    stopUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCount += 1
        stopClosure?()
    }
    //MARK: - seek

    var seekToUnderlyingCallsCount = 0
    var seekToCallsCount: Int {
        get {
            if Thread.isMainThread {
                return seekToUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = seekToUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                seekToUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    seekToUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var seekToCalled: Bool {
        return seekToCallsCount > 0
    }
    var seekToReceivedProgress: Double?
    var seekToReceivedInvocations: [Double] = []
    var seekToClosure: ((Double) async -> Void)?

    func seek(to progress: Double) async {
        seekToCallsCount += 1
        seekToReceivedProgress = progress
        DispatchQueue.main.async {
            self.seekToReceivedInvocations.append(progress)
        }
        await seekToClosure?(progress)
    }
}
class AudioRecorderMock: AudioRecorderProtocol {
    var actions: AnyPublisher<AudioRecorderAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<AudioRecorderAction, Never>!
    var currentTime: TimeInterval {
        get { return underlyingCurrentTime }
        set(value) { underlyingCurrentTime = value }
    }
    var underlyingCurrentTime: TimeInterval!
    var isRecording: Bool {
        get { return underlyingIsRecording }
        set(value) { underlyingIsRecording = value }
    }
    var underlyingIsRecording: Bool!
    var audioFileURL: URL?

    //MARK: - record

    var recordAudioFileURLUnderlyingCallsCount = 0
    var recordAudioFileURLCallsCount: Int {
        get {
            if Thread.isMainThread {
                return recordAudioFileURLUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = recordAudioFileURLUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recordAudioFileURLUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    recordAudioFileURLUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var recordAudioFileURLCalled: Bool {
        return recordAudioFileURLCallsCount > 0
    }
    var recordAudioFileURLReceivedAudioFileURL: URL?
    var recordAudioFileURLReceivedInvocations: [URL] = []
    var recordAudioFileURLClosure: ((URL) async -> Void)?

    func record(audioFileURL: URL) async {
        recordAudioFileURLCallsCount += 1
        recordAudioFileURLReceivedAudioFileURL = audioFileURL
        DispatchQueue.main.async {
            self.recordAudioFileURLReceivedInvocations.append(audioFileURL)
        }
        await recordAudioFileURLClosure?(audioFileURL)
    }
    //MARK: - stopRecording

    var stopRecordingUnderlyingCallsCount = 0
    var stopRecordingCallsCount: Int {
        get {
            if Thread.isMainThread {
                return stopRecordingUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = stopRecordingUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stopRecordingUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    stopRecordingUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var stopRecordingCalled: Bool {
        return stopRecordingCallsCount > 0
    }
    var stopRecordingClosure: (() async -> Void)?

    func stopRecording() async {
        stopRecordingCallsCount += 1
        await stopRecordingClosure?()
    }
    //MARK: - deleteRecording

    var deleteRecordingUnderlyingCallsCount = 0
    var deleteRecordingCallsCount: Int {
        get {
            if Thread.isMainThread {
                return deleteRecordingUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = deleteRecordingUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                deleteRecordingUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    deleteRecordingUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var deleteRecordingCalled: Bool {
        return deleteRecordingCallsCount > 0
    }
    var deleteRecordingClosure: (() async -> Void)?

    func deleteRecording() async {
        deleteRecordingCallsCount += 1
        await deleteRecordingClosure?()
    }
    //MARK: - averagePower

    var averagePowerUnderlyingCallsCount = 0
    var averagePowerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return averagePowerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = averagePowerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                averagePowerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    averagePowerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var averagePowerCalled: Bool {
        return averagePowerCallsCount > 0
    }

    var averagePowerUnderlyingReturnValue: Float!
    var averagePowerReturnValue: Float! {
        get {
            if Thread.isMainThread {
                return averagePowerUnderlyingReturnValue
            } else {
                var returnValue: Float? = nil
                DispatchQueue.main.sync {
                    returnValue = averagePowerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                averagePowerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    averagePowerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var averagePowerClosure: (() -> Float)?

    func averagePower() -> Float {
        averagePowerCallsCount += 1
        if let averagePowerClosure = averagePowerClosure {
            return averagePowerClosure()
        } else {
            return averagePowerReturnValue
        }
    }
}
class AudioSessionMock: AudioSessionProtocol {

    //MARK: - requestRecordPermission

    var requestRecordPermissionUnderlyingCallsCount = 0
    var requestRecordPermissionCallsCount: Int {
        get {
            if Thread.isMainThread {
                return requestRecordPermissionUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = requestRecordPermissionUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                requestRecordPermissionUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    requestRecordPermissionUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var requestRecordPermissionCalled: Bool {
        return requestRecordPermissionCallsCount > 0
    }
    var requestRecordPermissionReceivedResponse: ((Bool) -> Void)?
    var requestRecordPermissionReceivedInvocations: [((Bool) -> Void)] = []
    var requestRecordPermissionClosure: ((@escaping (Bool) -> Void) -> Void)?

    func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        requestRecordPermissionCallsCount += 1
        requestRecordPermissionReceivedResponse = response
        DispatchQueue.main.async {
            self.requestRecordPermissionReceivedInvocations.append(response)
        }
        requestRecordPermissionClosure?(response)
    }
    //MARK: - setAllowHapticsAndSystemSoundsDuringRecording

    var setAllowHapticsAndSystemSoundsDuringRecordingThrowableError: Error?
    var setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingCallsCount = 0
    var setAllowHapticsAndSystemSoundsDuringRecordingCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setAllowHapticsAndSystemSoundsDuringRecordingCalled: Bool {
        return setAllowHapticsAndSystemSoundsDuringRecordingCallsCount > 0
    }
    var setAllowHapticsAndSystemSoundsDuringRecordingReceivedInValue: Bool?
    var setAllowHapticsAndSystemSoundsDuringRecordingReceivedInvocations: [Bool] = []
    var setAllowHapticsAndSystemSoundsDuringRecordingClosure: ((Bool) throws -> Void)?

    func setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool) throws {
        if let error = setAllowHapticsAndSystemSoundsDuringRecordingThrowableError {
            throw error
        }
        setAllowHapticsAndSystemSoundsDuringRecordingCallsCount += 1
        setAllowHapticsAndSystemSoundsDuringRecordingReceivedInValue = inValue
        DispatchQueue.main.async {
            self.setAllowHapticsAndSystemSoundsDuringRecordingReceivedInvocations.append(inValue)
        }
        try setAllowHapticsAndSystemSoundsDuringRecordingClosure?(inValue)
    }
    //MARK: - setCategory

    var setCategoryModeOptionsThrowableError: Error?
    var setCategoryModeOptionsUnderlyingCallsCount = 0
    var setCategoryModeOptionsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setCategoryModeOptionsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setCategoryModeOptionsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setCategoryModeOptionsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setCategoryModeOptionsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setCategoryModeOptionsCalled: Bool {
        return setCategoryModeOptionsCallsCount > 0
    }
    var setCategoryModeOptionsReceivedArguments: (category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)?
    var setCategoryModeOptionsReceivedInvocations: [(category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)] = []
    var setCategoryModeOptionsClosure: ((AVAudioSession.Category, AVAudioSession.Mode, AVAudioSession.CategoryOptions) throws -> Void)?

    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
        if let error = setCategoryModeOptionsThrowableError {
            throw error
        }
        setCategoryModeOptionsCallsCount += 1
        setCategoryModeOptionsReceivedArguments = (category: category, mode: mode, options: options)
        DispatchQueue.main.async {
            self.setCategoryModeOptionsReceivedInvocations.append((category: category, mode: mode, options: options))
        }
        try setCategoryModeOptionsClosure?(category, mode, options)
    }
    //MARK: - setActive

    var setActiveOptionsThrowableError: Error?
    var setActiveOptionsUnderlyingCallsCount = 0
    var setActiveOptionsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setActiveOptionsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setActiveOptionsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setActiveOptionsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setActiveOptionsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setActiveOptionsCalled: Bool {
        return setActiveOptionsCallsCount > 0
    }
    var setActiveOptionsReceivedArguments: (active: Bool, options: AVAudioSession.SetActiveOptions)?
    var setActiveOptionsReceivedInvocations: [(active: Bool, options: AVAudioSession.SetActiveOptions)] = []
    var setActiveOptionsClosure: ((Bool, AVAudioSession.SetActiveOptions) throws -> Void)?

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        if let error = setActiveOptionsThrowableError {
            throw error
        }
        setActiveOptionsCallsCount += 1
        setActiveOptionsReceivedArguments = (active: active, options: options)
        DispatchQueue.main.async {
            self.setActiveOptionsReceivedInvocations.append((active: active, options: options))
        }
        try setActiveOptionsClosure?(active, options)
    }
}
class BugReportServiceMock: BugReportServiceProtocol {
    var crashedLastRun: Bool {
        get { return underlyingCrashedLastRun }
        set(value) { underlyingCrashedLastRun = value }
    }
    var underlyingCrashedLastRun: Bool!
    var lastCrashEventID: String?

    //MARK: - submitBugReport

    var submitBugReportProgressListenerUnderlyingCallsCount = 0
    var submitBugReportProgressListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return submitBugReportProgressListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = submitBugReportProgressListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                submitBugReportProgressListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    submitBugReportProgressListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var submitBugReportProgressListenerCalled: Bool {
        return submitBugReportProgressListenerCallsCount > 0
    }
    var submitBugReportProgressListenerReceivedArguments: (bugReport: BugReport, progressListener: CurrentValueSubject<Double, Never>)?
    var submitBugReportProgressListenerReceivedInvocations: [(bugReport: BugReport, progressListener: CurrentValueSubject<Double, Never>)] = []

    var submitBugReportProgressListenerUnderlyingReturnValue: Result<SubmitBugReportResponse, BugReportServiceError>!
    var submitBugReportProgressListenerReturnValue: Result<SubmitBugReportResponse, BugReportServiceError>! {
        get {
            if Thread.isMainThread {
                return submitBugReportProgressListenerUnderlyingReturnValue
            } else {
                var returnValue: Result<SubmitBugReportResponse, BugReportServiceError>? = nil
                DispatchQueue.main.sync {
                    returnValue = submitBugReportProgressListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                submitBugReportProgressListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    submitBugReportProgressListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var submitBugReportProgressListenerClosure: ((BugReport, CurrentValueSubject<Double, Never>) async -> Result<SubmitBugReportResponse, BugReportServiceError>)?

    func submitBugReport(_ bugReport: BugReport, progressListener: CurrentValueSubject<Double, Never>) async -> Result<SubmitBugReportResponse, BugReportServiceError> {
        submitBugReportProgressListenerCallsCount += 1
        submitBugReportProgressListenerReceivedArguments = (bugReport: bugReport, progressListener: progressListener)
        DispatchQueue.main.async {
            self.submitBugReportProgressListenerReceivedInvocations.append((bugReport: bugReport, progressListener: progressListener))
        }
        if let submitBugReportProgressListenerClosure = submitBugReportProgressListenerClosure {
            return await submitBugReportProgressListenerClosure(bugReport, progressListener)
        } else {
            return submitBugReportProgressListenerReturnValue
        }
    }
}
class ClientProxyMock: ClientProxyProtocol {
    var actionsPublisher: AnyPublisher<ClientProxyAction, Never> {
        get { return underlyingActionsPublisher }
        set(value) { underlyingActionsPublisher = value }
    }
    var underlyingActionsPublisher: AnyPublisher<ClientProxyAction, Never>!
    var loadingStatePublisher: CurrentValuePublisher<ClientProxyLoadingState, Never> {
        get { return underlyingLoadingStatePublisher }
        set(value) { underlyingLoadingStatePublisher = value }
    }
    var underlyingLoadingStatePublisher: CurrentValuePublisher<ClientProxyLoadingState, Never>!
    var verificationStatePublisher: CurrentValuePublisher<SessionVerificationState, Never> {
        get { return underlyingVerificationStatePublisher }
        set(value) { underlyingVerificationStatePublisher = value }
    }
    var underlyingVerificationStatePublisher: CurrentValuePublisher<SessionVerificationState, Never>!
    var userID: String {
        get { return underlyingUserID }
        set(value) { underlyingUserID = value }
    }
    var underlyingUserID: String!
    var deviceID: String?
    var homeserver: String {
        get { return underlyingHomeserver }
        set(value) { underlyingHomeserver = value }
    }
    var underlyingHomeserver: String!
    var slidingSyncVersion: SlidingSyncVersion {
        get { return underlyingSlidingSyncVersion }
        set(value) { underlyingSlidingSyncVersion = value }
    }
    var underlyingSlidingSyncVersion: SlidingSyncVersion!
    var availableSlidingSyncVersionsCallsCount = 0
    var availableSlidingSyncVersionsCalled: Bool {
        return availableSlidingSyncVersionsCallsCount > 0
    }

    var availableSlidingSyncVersions: [SlidingSyncVersion] {
        get async {
            availableSlidingSyncVersionsCallsCount += 1
            if let availableSlidingSyncVersionsClosure = availableSlidingSyncVersionsClosure {
                return await availableSlidingSyncVersionsClosure()
            } else {
                return underlyingAvailableSlidingSyncVersions
            }
        }
    }
    var underlyingAvailableSlidingSyncVersions: [SlidingSyncVersion]!
    var availableSlidingSyncVersionsClosure: (() async -> [SlidingSyncVersion])?
    var canDeactivateAccount: Bool {
        get { return underlyingCanDeactivateAccount }
        set(value) { underlyingCanDeactivateAccount = value }
    }
    var underlyingCanDeactivateAccount: Bool!
    var userIDServerName: String?
    var userDisplayNamePublisher: CurrentValuePublisher<String?, Never> {
        get { return underlyingUserDisplayNamePublisher }
        set(value) { underlyingUserDisplayNamePublisher = value }
    }
    var underlyingUserDisplayNamePublisher: CurrentValuePublisher<String?, Never>!
    var userAvatarURLPublisher: CurrentValuePublisher<URL?, Never> {
        get { return underlyingUserAvatarURLPublisher }
        set(value) { underlyingUserAvatarURLPublisher = value }
    }
    var underlyingUserAvatarURLPublisher: CurrentValuePublisher<URL?, Never>!
    var ignoredUsersPublisher: CurrentValuePublisher<[String]?, Never> {
        get { return underlyingIgnoredUsersPublisher }
        set(value) { underlyingIgnoredUsersPublisher = value }
    }
    var underlyingIgnoredUsersPublisher: CurrentValuePublisher<[String]?, Never>!
    var pusherNotificationClientIdentifier: String?
    var roomSummaryProvider: RoomSummaryProviderProtocol?
    var roomsToAwait: Set<String> {
        get { return underlyingRoomsToAwait }
        set(value) { underlyingRoomsToAwait = value }
    }
    var underlyingRoomsToAwait: Set<String>!
    var alternateRoomSummaryProvider: RoomSummaryProviderProtocol?
    var notificationSettings: NotificationSettingsProxyProtocol {
        get { return underlyingNotificationSettings }
        set(value) { underlyingNotificationSettings = value }
    }
    var underlyingNotificationSettings: NotificationSettingsProxyProtocol!
    var secureBackupController: SecureBackupControllerProtocol {
        get { return underlyingSecureBackupController }
        set(value) { underlyingSecureBackupController = value }
    }
    var underlyingSecureBackupController: SecureBackupControllerProtocol!

    //MARK: - isOnlyDeviceLeft

    var isOnlyDeviceLeftUnderlyingCallsCount = 0
    var isOnlyDeviceLeftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isOnlyDeviceLeftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isOnlyDeviceLeftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isOnlyDeviceLeftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isOnlyDeviceLeftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var isOnlyDeviceLeftCalled: Bool {
        return isOnlyDeviceLeftCallsCount > 0
    }

    var isOnlyDeviceLeftUnderlyingReturnValue: Result<Bool, ClientProxyError>!
    var isOnlyDeviceLeftReturnValue: Result<Bool, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return isOnlyDeviceLeftUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = isOnlyDeviceLeftUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isOnlyDeviceLeftUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isOnlyDeviceLeftUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var isOnlyDeviceLeftClosure: (() async -> Result<Bool, ClientProxyError>)?

    func isOnlyDeviceLeft() async -> Result<Bool, ClientProxyError> {
        isOnlyDeviceLeftCallsCount += 1
        if let isOnlyDeviceLeftClosure = isOnlyDeviceLeftClosure {
            return await isOnlyDeviceLeftClosure()
        } else {
            return isOnlyDeviceLeftReturnValue
        }
    }
    //MARK: - startSync

    var startSyncUnderlyingCallsCount = 0
    var startSyncCallsCount: Int {
        get {
            if Thread.isMainThread {
                return startSyncUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = startSyncUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startSyncUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    startSyncUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var startSyncCalled: Bool {
        return startSyncCallsCount > 0
    }
    var startSyncClosure: (() -> Void)?

    func startSync() {
        startSyncCallsCount += 1
        startSyncClosure?()
    }
    //MARK: - stopSync

    var stopSyncUnderlyingCallsCount = 0
    var stopSyncCallsCount: Int {
        get {
            if Thread.isMainThread {
                return stopSyncUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = stopSyncUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stopSyncUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    stopSyncUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var stopSyncCalled: Bool {
        return stopSyncCallsCount > 0
    }
    var stopSyncClosure: (() -> Void)?

    func stopSync() {
        stopSyncCallsCount += 1
        stopSyncClosure?()
    }
    //MARK: - accountURL

    var accountURLActionUnderlyingCallsCount = 0
    var accountURLActionCallsCount: Int {
        get {
            if Thread.isMainThread {
                return accountURLActionUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = accountURLActionUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                accountURLActionUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    accountURLActionUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var accountURLActionCalled: Bool {
        return accountURLActionCallsCount > 0
    }
    var accountURLActionReceivedAction: AccountManagementAction?
    var accountURLActionReceivedInvocations: [AccountManagementAction] = []

    var accountURLActionUnderlyingReturnValue: URL?
    var accountURLActionReturnValue: URL? {
        get {
            if Thread.isMainThread {
                return accountURLActionUnderlyingReturnValue
            } else {
                var returnValue: URL?? = nil
                DispatchQueue.main.sync {
                    returnValue = accountURLActionUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                accountURLActionUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    accountURLActionUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var accountURLActionClosure: ((AccountManagementAction) async -> URL?)?

    func accountURL(action: AccountManagementAction) async -> URL? {
        accountURLActionCallsCount += 1
        accountURLActionReceivedAction = action
        DispatchQueue.main.async {
            self.accountURLActionReceivedInvocations.append(action)
        }
        if let accountURLActionClosure = accountURLActionClosure {
            return await accountURLActionClosure(action)
        } else {
            return accountURLActionReturnValue
        }
    }
    //MARK: - createDirectRoomIfNeeded

    var createDirectRoomIfNeededWithExpectedRoomNameUnderlyingCallsCount = 0
    var createDirectRoomIfNeededWithExpectedRoomNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return createDirectRoomIfNeededWithExpectedRoomNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = createDirectRoomIfNeededWithExpectedRoomNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                createDirectRoomIfNeededWithExpectedRoomNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    createDirectRoomIfNeededWithExpectedRoomNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var createDirectRoomIfNeededWithExpectedRoomNameCalled: Bool {
        return createDirectRoomIfNeededWithExpectedRoomNameCallsCount > 0
    }
    var createDirectRoomIfNeededWithExpectedRoomNameReceivedArguments: (userID: String, expectedRoomName: String?)?
    var createDirectRoomIfNeededWithExpectedRoomNameReceivedInvocations: [(userID: String, expectedRoomName: String?)] = []

    var createDirectRoomIfNeededWithExpectedRoomNameUnderlyingReturnValue: Result<(roomID: String, isNewRoom: Bool), ClientProxyError>!
    var createDirectRoomIfNeededWithExpectedRoomNameReturnValue: Result<(roomID: String, isNewRoom: Bool), ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return createDirectRoomIfNeededWithExpectedRoomNameUnderlyingReturnValue
            } else {
                var returnValue: Result<(roomID: String, isNewRoom: Bool), ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = createDirectRoomIfNeededWithExpectedRoomNameUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                createDirectRoomIfNeededWithExpectedRoomNameUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    createDirectRoomIfNeededWithExpectedRoomNameUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var createDirectRoomIfNeededWithExpectedRoomNameClosure: ((String, String?) async -> Result<(roomID: String, isNewRoom: Bool), ClientProxyError>)?

    func createDirectRoomIfNeeded(with userID: String, expectedRoomName: String?) async -> Result<(roomID: String, isNewRoom: Bool), ClientProxyError> {
        createDirectRoomIfNeededWithExpectedRoomNameCallsCount += 1
        createDirectRoomIfNeededWithExpectedRoomNameReceivedArguments = (userID: userID, expectedRoomName: expectedRoomName)
        DispatchQueue.main.async {
            self.createDirectRoomIfNeededWithExpectedRoomNameReceivedInvocations.append((userID: userID, expectedRoomName: expectedRoomName))
        }
        if let createDirectRoomIfNeededWithExpectedRoomNameClosure = createDirectRoomIfNeededWithExpectedRoomNameClosure {
            return await createDirectRoomIfNeededWithExpectedRoomNameClosure(userID, expectedRoomName)
        } else {
            return createDirectRoomIfNeededWithExpectedRoomNameReturnValue
        }
    }
    //MARK: - directRoomForUserID

    var directRoomForUserIDUnderlyingCallsCount = 0
    var directRoomForUserIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return directRoomForUserIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = directRoomForUserIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                directRoomForUserIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    directRoomForUserIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var directRoomForUserIDCalled: Bool {
        return directRoomForUserIDCallsCount > 0
    }
    var directRoomForUserIDReceivedUserID: String?
    var directRoomForUserIDReceivedInvocations: [String] = []

    var directRoomForUserIDUnderlyingReturnValue: Result<String?, ClientProxyError>!
    var directRoomForUserIDReturnValue: Result<String?, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return directRoomForUserIDUnderlyingReturnValue
            } else {
                var returnValue: Result<String?, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = directRoomForUserIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                directRoomForUserIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    directRoomForUserIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var directRoomForUserIDClosure: ((String) async -> Result<String?, ClientProxyError>)?

    func directRoomForUserID(_ userID: String) async -> Result<String?, ClientProxyError> {
        directRoomForUserIDCallsCount += 1
        directRoomForUserIDReceivedUserID = userID
        DispatchQueue.main.async {
            self.directRoomForUserIDReceivedInvocations.append(userID)
        }
        if let directRoomForUserIDClosure = directRoomForUserIDClosure {
            return await directRoomForUserIDClosure(userID)
        } else {
            return directRoomForUserIDReturnValue
        }
    }
    //MARK: - createDirectRoom

    var createDirectRoomWithExpectedRoomNameUnderlyingCallsCount = 0
    var createDirectRoomWithExpectedRoomNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return createDirectRoomWithExpectedRoomNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = createDirectRoomWithExpectedRoomNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                createDirectRoomWithExpectedRoomNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    createDirectRoomWithExpectedRoomNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var createDirectRoomWithExpectedRoomNameCalled: Bool {
        return createDirectRoomWithExpectedRoomNameCallsCount > 0
    }
    var createDirectRoomWithExpectedRoomNameReceivedArguments: (userID: String, expectedRoomName: String?)?
    var createDirectRoomWithExpectedRoomNameReceivedInvocations: [(userID: String, expectedRoomName: String?)] = []

    var createDirectRoomWithExpectedRoomNameUnderlyingReturnValue: Result<String, ClientProxyError>!
    var createDirectRoomWithExpectedRoomNameReturnValue: Result<String, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return createDirectRoomWithExpectedRoomNameUnderlyingReturnValue
            } else {
                var returnValue: Result<String, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = createDirectRoomWithExpectedRoomNameUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                createDirectRoomWithExpectedRoomNameUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    createDirectRoomWithExpectedRoomNameUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var createDirectRoomWithExpectedRoomNameClosure: ((String, String?) async -> Result<String, ClientProxyError>)?

    func createDirectRoom(with userID: String, expectedRoomName: String?) async -> Result<String, ClientProxyError> {
        createDirectRoomWithExpectedRoomNameCallsCount += 1
        createDirectRoomWithExpectedRoomNameReceivedArguments = (userID: userID, expectedRoomName: expectedRoomName)
        DispatchQueue.main.async {
            self.createDirectRoomWithExpectedRoomNameReceivedInvocations.append((userID: userID, expectedRoomName: expectedRoomName))
        }
        if let createDirectRoomWithExpectedRoomNameClosure = createDirectRoomWithExpectedRoomNameClosure {
            return await createDirectRoomWithExpectedRoomNameClosure(userID, expectedRoomName)
        } else {
            return createDirectRoomWithExpectedRoomNameReturnValue
        }
    }
    //MARK: - createRoom

    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLUnderlyingCallsCount = 0
    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLCallsCount: Int {
        get {
            if Thread.isMainThread {
                return createRoomNameTopicIsRoomPrivateUserIDsAvatarURLUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = createRoomNameTopicIsRoomPrivateUserIDsAvatarURLUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                createRoomNameTopicIsRoomPrivateUserIDsAvatarURLUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    createRoomNameTopicIsRoomPrivateUserIDsAvatarURLUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLCalled: Bool {
        return createRoomNameTopicIsRoomPrivateUserIDsAvatarURLCallsCount > 0
    }
    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReceivedArguments: (name: String, topic: String?, isRoomPrivate: Bool, userIDs: [String], avatarURL: URL?)?
    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReceivedInvocations: [(name: String, topic: String?, isRoomPrivate: Bool, userIDs: [String], avatarURL: URL?)] = []

    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLUnderlyingReturnValue: Result<String, ClientProxyError>!
    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReturnValue: Result<String, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return createRoomNameTopicIsRoomPrivateUserIDsAvatarURLUnderlyingReturnValue
            } else {
                var returnValue: Result<String, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = createRoomNameTopicIsRoomPrivateUserIDsAvatarURLUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                createRoomNameTopicIsRoomPrivateUserIDsAvatarURLUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    createRoomNameTopicIsRoomPrivateUserIDsAvatarURLUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLClosure: ((String, String?, Bool, [String], URL?) async -> Result<String, ClientProxyError>)?

    func createRoom(name: String, topic: String?, isRoomPrivate: Bool, userIDs: [String], avatarURL: URL?) async -> Result<String, ClientProxyError> {
        createRoomNameTopicIsRoomPrivateUserIDsAvatarURLCallsCount += 1
        createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReceivedArguments = (name: name, topic: topic, isRoomPrivate: isRoomPrivate, userIDs: userIDs, avatarURL: avatarURL)
        DispatchQueue.main.async {
            self.createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReceivedInvocations.append((name: name, topic: topic, isRoomPrivate: isRoomPrivate, userIDs: userIDs, avatarURL: avatarURL))
        }
        if let createRoomNameTopicIsRoomPrivateUserIDsAvatarURLClosure = createRoomNameTopicIsRoomPrivateUserIDsAvatarURLClosure {
            return await createRoomNameTopicIsRoomPrivateUserIDsAvatarURLClosure(name, topic, isRoomPrivate, userIDs, avatarURL)
        } else {
            return createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReturnValue
        }
    }
    //MARK: - joinRoom

    var joinRoomViaUnderlyingCallsCount = 0
    var joinRoomViaCallsCount: Int {
        get {
            if Thread.isMainThread {
                return joinRoomViaUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = joinRoomViaUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinRoomViaUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    joinRoomViaUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var joinRoomViaCalled: Bool {
        return joinRoomViaCallsCount > 0
    }
    var joinRoomViaReceivedArguments: (roomID: String, via: [String])?
    var joinRoomViaReceivedInvocations: [(roomID: String, via: [String])] = []

    var joinRoomViaUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var joinRoomViaReturnValue: Result<Void, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return joinRoomViaUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = joinRoomViaUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinRoomViaUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    joinRoomViaUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var joinRoomViaClosure: ((String, [String]) async -> Result<Void, ClientProxyError>)?

    func joinRoom(_ roomID: String, via: [String]) async -> Result<Void, ClientProxyError> {
        joinRoomViaCallsCount += 1
        joinRoomViaReceivedArguments = (roomID: roomID, via: via)
        DispatchQueue.main.async {
            self.joinRoomViaReceivedInvocations.append((roomID: roomID, via: via))
        }
        if let joinRoomViaClosure = joinRoomViaClosure {
            return await joinRoomViaClosure(roomID, via)
        } else {
            return joinRoomViaReturnValue
        }
    }
    //MARK: - joinRoomAlias

    var joinRoomAliasUnderlyingCallsCount = 0
    var joinRoomAliasCallsCount: Int {
        get {
            if Thread.isMainThread {
                return joinRoomAliasUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = joinRoomAliasUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinRoomAliasUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    joinRoomAliasUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var joinRoomAliasCalled: Bool {
        return joinRoomAliasCallsCount > 0
    }
    var joinRoomAliasReceivedRoomAlias: String?
    var joinRoomAliasReceivedInvocations: [String] = []

    var joinRoomAliasUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var joinRoomAliasReturnValue: Result<Void, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return joinRoomAliasUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = joinRoomAliasUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinRoomAliasUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    joinRoomAliasUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var joinRoomAliasClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func joinRoomAlias(_ roomAlias: String) async -> Result<Void, ClientProxyError> {
        joinRoomAliasCallsCount += 1
        joinRoomAliasReceivedRoomAlias = roomAlias
        DispatchQueue.main.async {
            self.joinRoomAliasReceivedInvocations.append(roomAlias)
        }
        if let joinRoomAliasClosure = joinRoomAliasClosure {
            return await joinRoomAliasClosure(roomAlias)
        } else {
            return joinRoomAliasReturnValue
        }
    }
    //MARK: - uploadMedia

    var uploadMediaUnderlyingCallsCount = 0
    var uploadMediaCallsCount: Int {
        get {
            if Thread.isMainThread {
                return uploadMediaUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = uploadMediaUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                uploadMediaUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    uploadMediaUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var uploadMediaCalled: Bool {
        return uploadMediaCallsCount > 0
    }
    var uploadMediaReceivedMedia: MediaInfo?
    var uploadMediaReceivedInvocations: [MediaInfo] = []

    var uploadMediaUnderlyingReturnValue: Result<String, ClientProxyError>!
    var uploadMediaReturnValue: Result<String, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return uploadMediaUnderlyingReturnValue
            } else {
                var returnValue: Result<String, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = uploadMediaUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                uploadMediaUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    uploadMediaUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var uploadMediaClosure: ((MediaInfo) async -> Result<String, ClientProxyError>)?

    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError> {
        uploadMediaCallsCount += 1
        uploadMediaReceivedMedia = media
        DispatchQueue.main.async {
            self.uploadMediaReceivedInvocations.append(media)
        }
        if let uploadMediaClosure = uploadMediaClosure {
            return await uploadMediaClosure(media)
        } else {
            return uploadMediaReturnValue
        }
    }
    //MARK: - roomForIdentifier

    var roomForIdentifierUnderlyingCallsCount = 0
    var roomForIdentifierCallsCount: Int {
        get {
            if Thread.isMainThread {
                return roomForIdentifierUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = roomForIdentifierUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomForIdentifierUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    roomForIdentifierUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var roomForIdentifierCalled: Bool {
        return roomForIdentifierCallsCount > 0
    }
    var roomForIdentifierReceivedIdentifier: String?
    var roomForIdentifierReceivedInvocations: [String] = []

    var roomForIdentifierUnderlyingReturnValue: RoomProxyType?
    var roomForIdentifierReturnValue: RoomProxyType? {
        get {
            if Thread.isMainThread {
                return roomForIdentifierUnderlyingReturnValue
            } else {
                var returnValue: RoomProxyType?? = nil
                DispatchQueue.main.sync {
                    returnValue = roomForIdentifierUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomForIdentifierUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    roomForIdentifierUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var roomForIdentifierClosure: ((String) async -> RoomProxyType?)?

    func roomForIdentifier(_ identifier: String) async -> RoomProxyType? {
        roomForIdentifierCallsCount += 1
        roomForIdentifierReceivedIdentifier = identifier
        DispatchQueue.main.async {
            self.roomForIdentifierReceivedInvocations.append(identifier)
        }
        if let roomForIdentifierClosure = roomForIdentifierClosure {
            return await roomForIdentifierClosure(identifier)
        } else {
            return roomForIdentifierReturnValue
        }
    }
    //MARK: - roomPreviewForIdentifier

    var roomPreviewForIdentifierViaUnderlyingCallsCount = 0
    var roomPreviewForIdentifierViaCallsCount: Int {
        get {
            if Thread.isMainThread {
                return roomPreviewForIdentifierViaUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = roomPreviewForIdentifierViaUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomPreviewForIdentifierViaUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    roomPreviewForIdentifierViaUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var roomPreviewForIdentifierViaCalled: Bool {
        return roomPreviewForIdentifierViaCallsCount > 0
    }
    var roomPreviewForIdentifierViaReceivedArguments: (identifier: String, via: [String])?
    var roomPreviewForIdentifierViaReceivedInvocations: [(identifier: String, via: [String])] = []

    var roomPreviewForIdentifierViaUnderlyingReturnValue: Result<RoomPreviewDetails, ClientProxyError>!
    var roomPreviewForIdentifierViaReturnValue: Result<RoomPreviewDetails, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return roomPreviewForIdentifierViaUnderlyingReturnValue
            } else {
                var returnValue: Result<RoomPreviewDetails, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = roomPreviewForIdentifierViaUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomPreviewForIdentifierViaUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    roomPreviewForIdentifierViaUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var roomPreviewForIdentifierViaClosure: ((String, [String]) async -> Result<RoomPreviewDetails, ClientProxyError>)?

    func roomPreviewForIdentifier(_ identifier: String, via: [String]) async -> Result<RoomPreviewDetails, ClientProxyError> {
        roomPreviewForIdentifierViaCallsCount += 1
        roomPreviewForIdentifierViaReceivedArguments = (identifier: identifier, via: via)
        DispatchQueue.main.async {
            self.roomPreviewForIdentifierViaReceivedInvocations.append((identifier: identifier, via: via))
        }
        if let roomPreviewForIdentifierViaClosure = roomPreviewForIdentifierViaClosure {
            return await roomPreviewForIdentifierViaClosure(identifier, via)
        } else {
            return roomPreviewForIdentifierViaReturnValue
        }
    }
    //MARK: - loadUserDisplayName

    var loadUserDisplayNameUnderlyingCallsCount = 0
    var loadUserDisplayNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadUserDisplayNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadUserDisplayNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadUserDisplayNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadUserDisplayNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadUserDisplayNameCalled: Bool {
        return loadUserDisplayNameCallsCount > 0
    }

    var loadUserDisplayNameUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var loadUserDisplayNameReturnValue: Result<Void, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return loadUserDisplayNameUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = loadUserDisplayNameUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadUserDisplayNameUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadUserDisplayNameUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadUserDisplayNameClosure: (() async -> Result<Void, ClientProxyError>)?

    @discardableResult
    func loadUserDisplayName() async -> Result<Void, ClientProxyError> {
        loadUserDisplayNameCallsCount += 1
        if let loadUserDisplayNameClosure = loadUserDisplayNameClosure {
            return await loadUserDisplayNameClosure()
        } else {
            return loadUserDisplayNameReturnValue
        }
    }
    //MARK: - setUserDisplayName

    var setUserDisplayNameUnderlyingCallsCount = 0
    var setUserDisplayNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setUserDisplayNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setUserDisplayNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setUserDisplayNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setUserDisplayNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setUserDisplayNameCalled: Bool {
        return setUserDisplayNameCallsCount > 0
    }
    var setUserDisplayNameReceivedName: String?
    var setUserDisplayNameReceivedInvocations: [String] = []

    var setUserDisplayNameUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var setUserDisplayNameReturnValue: Result<Void, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return setUserDisplayNameUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = setUserDisplayNameUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setUserDisplayNameUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    setUserDisplayNameUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var setUserDisplayNameClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func setUserDisplayName(_ name: String) async -> Result<Void, ClientProxyError> {
        setUserDisplayNameCallsCount += 1
        setUserDisplayNameReceivedName = name
        DispatchQueue.main.async {
            self.setUserDisplayNameReceivedInvocations.append(name)
        }
        if let setUserDisplayNameClosure = setUserDisplayNameClosure {
            return await setUserDisplayNameClosure(name)
        } else {
            return setUserDisplayNameReturnValue
        }
    }
    //MARK: - loadUserAvatarURL

    var loadUserAvatarURLUnderlyingCallsCount = 0
    var loadUserAvatarURLCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadUserAvatarURLUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadUserAvatarURLUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadUserAvatarURLUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadUserAvatarURLUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadUserAvatarURLCalled: Bool {
        return loadUserAvatarURLCallsCount > 0
    }

    var loadUserAvatarURLUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var loadUserAvatarURLReturnValue: Result<Void, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return loadUserAvatarURLUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = loadUserAvatarURLUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadUserAvatarURLUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadUserAvatarURLUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadUserAvatarURLClosure: (() async -> Result<Void, ClientProxyError>)?

    @discardableResult
    func loadUserAvatarURL() async -> Result<Void, ClientProxyError> {
        loadUserAvatarURLCallsCount += 1
        if let loadUserAvatarURLClosure = loadUserAvatarURLClosure {
            return await loadUserAvatarURLClosure()
        } else {
            return loadUserAvatarURLReturnValue
        }
    }
    //MARK: - setUserAvatar

    var setUserAvatarMediaUnderlyingCallsCount = 0
    var setUserAvatarMediaCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setUserAvatarMediaUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setUserAvatarMediaUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setUserAvatarMediaUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setUserAvatarMediaUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setUserAvatarMediaCalled: Bool {
        return setUserAvatarMediaCallsCount > 0
    }
    var setUserAvatarMediaReceivedMedia: MediaInfo?
    var setUserAvatarMediaReceivedInvocations: [MediaInfo] = []

    var setUserAvatarMediaUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var setUserAvatarMediaReturnValue: Result<Void, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return setUserAvatarMediaUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = setUserAvatarMediaUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setUserAvatarMediaUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    setUserAvatarMediaUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var setUserAvatarMediaClosure: ((MediaInfo) async -> Result<Void, ClientProxyError>)?

    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError> {
        setUserAvatarMediaCallsCount += 1
        setUserAvatarMediaReceivedMedia = media
        DispatchQueue.main.async {
            self.setUserAvatarMediaReceivedInvocations.append(media)
        }
        if let setUserAvatarMediaClosure = setUserAvatarMediaClosure {
            return await setUserAvatarMediaClosure(media)
        } else {
            return setUserAvatarMediaReturnValue
        }
    }
    //MARK: - removeUserAvatar

    var removeUserAvatarUnderlyingCallsCount = 0
    var removeUserAvatarCallsCount: Int {
        get {
            if Thread.isMainThread {
                return removeUserAvatarUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = removeUserAvatarUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removeUserAvatarUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    removeUserAvatarUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var removeUserAvatarCalled: Bool {
        return removeUserAvatarCallsCount > 0
    }

    var removeUserAvatarUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var removeUserAvatarReturnValue: Result<Void, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return removeUserAvatarUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = removeUserAvatarUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removeUserAvatarUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    removeUserAvatarUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var removeUserAvatarClosure: (() async -> Result<Void, ClientProxyError>)?

    func removeUserAvatar() async -> Result<Void, ClientProxyError> {
        removeUserAvatarCallsCount += 1
        if let removeUserAvatarClosure = removeUserAvatarClosure {
            return await removeUserAvatarClosure()
        } else {
            return removeUserAvatarReturnValue
        }
    }
    //MARK: - sessionVerificationControllerProxy

    var sessionVerificationControllerProxyUnderlyingCallsCount = 0
    var sessionVerificationControllerProxyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sessionVerificationControllerProxyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sessionVerificationControllerProxyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sessionVerificationControllerProxyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sessionVerificationControllerProxyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sessionVerificationControllerProxyCalled: Bool {
        return sessionVerificationControllerProxyCallsCount > 0
    }

    var sessionVerificationControllerProxyUnderlyingReturnValue: Result<SessionVerificationControllerProxyProtocol, ClientProxyError>!
    var sessionVerificationControllerProxyReturnValue: Result<SessionVerificationControllerProxyProtocol, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return sessionVerificationControllerProxyUnderlyingReturnValue
            } else {
                var returnValue: Result<SessionVerificationControllerProxyProtocol, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sessionVerificationControllerProxyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sessionVerificationControllerProxyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sessionVerificationControllerProxyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sessionVerificationControllerProxyClosure: (() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError>)?

    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        sessionVerificationControllerProxyCallsCount += 1
        if let sessionVerificationControllerProxyClosure = sessionVerificationControllerProxyClosure {
            return await sessionVerificationControllerProxyClosure()
        } else {
            return sessionVerificationControllerProxyReturnValue
        }
    }
    //MARK: - deactivateAccount

    var deactivateAccountPasswordEraseDataUnderlyingCallsCount = 0
    var deactivateAccountPasswordEraseDataCallsCount: Int {
        get {
            if Thread.isMainThread {
                return deactivateAccountPasswordEraseDataUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = deactivateAccountPasswordEraseDataUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                deactivateAccountPasswordEraseDataUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    deactivateAccountPasswordEraseDataUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var deactivateAccountPasswordEraseDataCalled: Bool {
        return deactivateAccountPasswordEraseDataCallsCount > 0
    }
    var deactivateAccountPasswordEraseDataReceivedArguments: (password: String?, eraseData: Bool)?
    var deactivateAccountPasswordEraseDataReceivedInvocations: [(password: String?, eraseData: Bool)] = []

    var deactivateAccountPasswordEraseDataUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var deactivateAccountPasswordEraseDataReturnValue: Result<Void, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return deactivateAccountPasswordEraseDataUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = deactivateAccountPasswordEraseDataUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                deactivateAccountPasswordEraseDataUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    deactivateAccountPasswordEraseDataUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var deactivateAccountPasswordEraseDataClosure: ((String?, Bool) async -> Result<Void, ClientProxyError>)?

    func deactivateAccount(password: String?, eraseData: Bool) async -> Result<Void, ClientProxyError> {
        deactivateAccountPasswordEraseDataCallsCount += 1
        deactivateAccountPasswordEraseDataReceivedArguments = (password: password, eraseData: eraseData)
        DispatchQueue.main.async {
            self.deactivateAccountPasswordEraseDataReceivedInvocations.append((password: password, eraseData: eraseData))
        }
        if let deactivateAccountPasswordEraseDataClosure = deactivateAccountPasswordEraseDataClosure {
            return await deactivateAccountPasswordEraseDataClosure(password, eraseData)
        } else {
            return deactivateAccountPasswordEraseDataReturnValue
        }
    }
    //MARK: - logout

    var logoutUnderlyingCallsCount = 0
    var logoutCallsCount: Int {
        get {
            if Thread.isMainThread {
                return logoutUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = logoutUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                logoutUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    logoutUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var logoutCalled: Bool {
        return logoutCallsCount > 0
    }

    var logoutUnderlyingReturnValue: URL?
    var logoutReturnValue: URL? {
        get {
            if Thread.isMainThread {
                return logoutUnderlyingReturnValue
            } else {
                var returnValue: URL?? = nil
                DispatchQueue.main.sync {
                    returnValue = logoutUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                logoutUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    logoutUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var logoutClosure: (() async -> URL?)?

    func logout() async -> URL? {
        logoutCallsCount += 1
        if let logoutClosure = logoutClosure {
            return await logoutClosure()
        } else {
            return logoutReturnValue
        }
    }
    //MARK: - setPusher

    var setPusherWithThrowableError: Error?
    var setPusherWithUnderlyingCallsCount = 0
    var setPusherWithCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setPusherWithUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setPusherWithUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setPusherWithUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setPusherWithUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setPusherWithCalled: Bool {
        return setPusherWithCallsCount > 0
    }
    var setPusherWithReceivedConfiguration: PusherConfiguration?
    var setPusherWithReceivedInvocations: [PusherConfiguration] = []
    var setPusherWithClosure: ((PusherConfiguration) async throws -> Void)?

    func setPusher(with configuration: PusherConfiguration) async throws {
        if let error = setPusherWithThrowableError {
            throw error
        }
        setPusherWithCallsCount += 1
        setPusherWithReceivedConfiguration = configuration
        DispatchQueue.main.async {
            self.setPusherWithReceivedInvocations.append(configuration)
        }
        try await setPusherWithClosure?(configuration)
    }
    //MARK: - searchUsers

    var searchUsersSearchTermLimitUnderlyingCallsCount = 0
    var searchUsersSearchTermLimitCallsCount: Int {
        get {
            if Thread.isMainThread {
                return searchUsersSearchTermLimitUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = searchUsersSearchTermLimitUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                searchUsersSearchTermLimitUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    searchUsersSearchTermLimitUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var searchUsersSearchTermLimitCalled: Bool {
        return searchUsersSearchTermLimitCallsCount > 0
    }
    var searchUsersSearchTermLimitReceivedArguments: (searchTerm: String, limit: UInt)?
    var searchUsersSearchTermLimitReceivedInvocations: [(searchTerm: String, limit: UInt)] = []

    var searchUsersSearchTermLimitUnderlyingReturnValue: Result<SearchUsersResultsProxy, ClientProxyError>!
    var searchUsersSearchTermLimitReturnValue: Result<SearchUsersResultsProxy, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return searchUsersSearchTermLimitUnderlyingReturnValue
            } else {
                var returnValue: Result<SearchUsersResultsProxy, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = searchUsersSearchTermLimitUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                searchUsersSearchTermLimitUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    searchUsersSearchTermLimitUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var searchUsersSearchTermLimitClosure: ((String, UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError>)?

    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError> {
        searchUsersSearchTermLimitCallsCount += 1
        searchUsersSearchTermLimitReceivedArguments = (searchTerm: searchTerm, limit: limit)
        DispatchQueue.main.async {
            self.searchUsersSearchTermLimitReceivedInvocations.append((searchTerm: searchTerm, limit: limit))
        }
        if let searchUsersSearchTermLimitClosure = searchUsersSearchTermLimitClosure {
            return await searchUsersSearchTermLimitClosure(searchTerm, limit)
        } else {
            return searchUsersSearchTermLimitReturnValue
        }
    }
    //MARK: - profile

    var profileForUnderlyingCallsCount = 0
    var profileForCallsCount: Int {
        get {
            if Thread.isMainThread {
                return profileForUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = profileForUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                profileForUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    profileForUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var profileForCalled: Bool {
        return profileForCallsCount > 0
    }
    var profileForReceivedUserID: String?
    var profileForReceivedInvocations: [String] = []

    var profileForUnderlyingReturnValue: Result<UserProfileProxy, ClientProxyError>!
    var profileForReturnValue: Result<UserProfileProxy, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return profileForUnderlyingReturnValue
            } else {
                var returnValue: Result<UserProfileProxy, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = profileForUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                profileForUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    profileForUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var profileForClosure: ((String) async -> Result<UserProfileProxy, ClientProxyError>)?

    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError> {
        profileForCallsCount += 1
        profileForReceivedUserID = userID
        DispatchQueue.main.async {
            self.profileForReceivedInvocations.append(userID)
        }
        if let profileForClosure = profileForClosure {
            return await profileForClosure(userID)
        } else {
            return profileForReturnValue
        }
    }
    //MARK: - roomDirectorySearchProxy

    var roomDirectorySearchProxyUnderlyingCallsCount = 0
    var roomDirectorySearchProxyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return roomDirectorySearchProxyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = roomDirectorySearchProxyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomDirectorySearchProxyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    roomDirectorySearchProxyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var roomDirectorySearchProxyCalled: Bool {
        return roomDirectorySearchProxyCallsCount > 0
    }

    var roomDirectorySearchProxyUnderlyingReturnValue: RoomDirectorySearchProxyProtocol!
    var roomDirectorySearchProxyReturnValue: RoomDirectorySearchProxyProtocol! {
        get {
            if Thread.isMainThread {
                return roomDirectorySearchProxyUnderlyingReturnValue
            } else {
                var returnValue: RoomDirectorySearchProxyProtocol? = nil
                DispatchQueue.main.sync {
                    returnValue = roomDirectorySearchProxyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomDirectorySearchProxyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    roomDirectorySearchProxyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var roomDirectorySearchProxyClosure: (() -> RoomDirectorySearchProxyProtocol)?

    func roomDirectorySearchProxy() -> RoomDirectorySearchProxyProtocol {
        roomDirectorySearchProxyCallsCount += 1
        if let roomDirectorySearchProxyClosure = roomDirectorySearchProxyClosure {
            return roomDirectorySearchProxyClosure()
        } else {
            return roomDirectorySearchProxyReturnValue
        }
    }
    //MARK: - resolveRoomAlias

    var resolveRoomAliasUnderlyingCallsCount = 0
    var resolveRoomAliasCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resolveRoomAliasUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resolveRoomAliasUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resolveRoomAliasUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resolveRoomAliasUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var resolveRoomAliasCalled: Bool {
        return resolveRoomAliasCallsCount > 0
    }
    var resolveRoomAliasReceivedAlias: String?
    var resolveRoomAliasReceivedInvocations: [String] = []

    var resolveRoomAliasUnderlyingReturnValue: Result<ResolvedRoomAlias, ClientProxyError>!
    var resolveRoomAliasReturnValue: Result<ResolvedRoomAlias, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return resolveRoomAliasUnderlyingReturnValue
            } else {
                var returnValue: Result<ResolvedRoomAlias, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = resolveRoomAliasUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resolveRoomAliasUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    resolveRoomAliasUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var resolveRoomAliasClosure: ((String) async -> Result<ResolvedRoomAlias, ClientProxyError>)?

    func resolveRoomAlias(_ alias: String) async -> Result<ResolvedRoomAlias, ClientProxyError> {
        resolveRoomAliasCallsCount += 1
        resolveRoomAliasReceivedAlias = alias
        DispatchQueue.main.async {
            self.resolveRoomAliasReceivedInvocations.append(alias)
        }
        if let resolveRoomAliasClosure = resolveRoomAliasClosure {
            return await resolveRoomAliasClosure(alias)
        } else {
            return resolveRoomAliasReturnValue
        }
    }
    //MARK: - getElementWellKnown

    var getElementWellKnownUnderlyingCallsCount = 0
    var getElementWellKnownCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getElementWellKnownUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getElementWellKnownUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getElementWellKnownUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getElementWellKnownUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var getElementWellKnownCalled: Bool {
        return getElementWellKnownCallsCount > 0
    }

    var getElementWellKnownUnderlyingReturnValue: Result<ElementWellKnown?, ClientProxyError>!
    var getElementWellKnownReturnValue: Result<ElementWellKnown?, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return getElementWellKnownUnderlyingReturnValue
            } else {
                var returnValue: Result<ElementWellKnown?, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = getElementWellKnownUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getElementWellKnownUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getElementWellKnownUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var getElementWellKnownClosure: (() async -> Result<ElementWellKnown?, ClientProxyError>)?

    func getElementWellKnown() async -> Result<ElementWellKnown?, ClientProxyError> {
        getElementWellKnownCallsCount += 1
        if let getElementWellKnownClosure = getElementWellKnownClosure {
            return await getElementWellKnownClosure()
        } else {
            return getElementWellKnownReturnValue
        }
    }
    //MARK: - ignoreUser

    var ignoreUserUnderlyingCallsCount = 0
    var ignoreUserCallsCount: Int {
        get {
            if Thread.isMainThread {
                return ignoreUserUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = ignoreUserUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ignoreUserUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    ignoreUserUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var ignoreUserCalled: Bool {
        return ignoreUserCallsCount > 0
    }
    var ignoreUserReceivedUserID: String?
    var ignoreUserReceivedInvocations: [String] = []

    var ignoreUserUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var ignoreUserReturnValue: Result<Void, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return ignoreUserUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = ignoreUserUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ignoreUserUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    ignoreUserUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var ignoreUserClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func ignoreUser(_ userID: String) async -> Result<Void, ClientProxyError> {
        ignoreUserCallsCount += 1
        ignoreUserReceivedUserID = userID
        DispatchQueue.main.async {
            self.ignoreUserReceivedInvocations.append(userID)
        }
        if let ignoreUserClosure = ignoreUserClosure {
            return await ignoreUserClosure(userID)
        } else {
            return ignoreUserReturnValue
        }
    }
    //MARK: - unignoreUser

    var unignoreUserUnderlyingCallsCount = 0
    var unignoreUserCallsCount: Int {
        get {
            if Thread.isMainThread {
                return unignoreUserUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = unignoreUserUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unignoreUserUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    unignoreUserUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var unignoreUserCalled: Bool {
        return unignoreUserCallsCount > 0
    }
    var unignoreUserReceivedUserID: String?
    var unignoreUserReceivedInvocations: [String] = []

    var unignoreUserUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var unignoreUserReturnValue: Result<Void, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return unignoreUserUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = unignoreUserUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unignoreUserUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    unignoreUserUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var unignoreUserClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func unignoreUser(_ userID: String) async -> Result<Void, ClientProxyError> {
        unignoreUserCallsCount += 1
        unignoreUserReceivedUserID = userID
        DispatchQueue.main.async {
            self.unignoreUserReceivedInvocations.append(userID)
        }
        if let unignoreUserClosure = unignoreUserClosure {
            return await unignoreUserClosure(userID)
        } else {
            return unignoreUserReturnValue
        }
    }
    //MARK: - trackRecentlyVisitedRoom

    var trackRecentlyVisitedRoomUnderlyingCallsCount = 0
    var trackRecentlyVisitedRoomCallsCount: Int {
        get {
            if Thread.isMainThread {
                return trackRecentlyVisitedRoomUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = trackRecentlyVisitedRoomUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                trackRecentlyVisitedRoomUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    trackRecentlyVisitedRoomUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var trackRecentlyVisitedRoomCalled: Bool {
        return trackRecentlyVisitedRoomCallsCount > 0
    }
    var trackRecentlyVisitedRoomReceivedRoomID: String?
    var trackRecentlyVisitedRoomReceivedInvocations: [String] = []

    var trackRecentlyVisitedRoomUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var trackRecentlyVisitedRoomReturnValue: Result<Void, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return trackRecentlyVisitedRoomUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = trackRecentlyVisitedRoomUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                trackRecentlyVisitedRoomUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    trackRecentlyVisitedRoomUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var trackRecentlyVisitedRoomClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func trackRecentlyVisitedRoom(_ roomID: String) async -> Result<Void, ClientProxyError> {
        trackRecentlyVisitedRoomCallsCount += 1
        trackRecentlyVisitedRoomReceivedRoomID = roomID
        DispatchQueue.main.async {
            self.trackRecentlyVisitedRoomReceivedInvocations.append(roomID)
        }
        if let trackRecentlyVisitedRoomClosure = trackRecentlyVisitedRoomClosure {
            return await trackRecentlyVisitedRoomClosure(roomID)
        } else {
            return trackRecentlyVisitedRoomReturnValue
        }
    }
    //MARK: - recentlyVisitedRooms

    var recentlyVisitedRoomsUnderlyingCallsCount = 0
    var recentlyVisitedRoomsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return recentlyVisitedRoomsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = recentlyVisitedRoomsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recentlyVisitedRoomsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    recentlyVisitedRoomsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var recentlyVisitedRoomsCalled: Bool {
        return recentlyVisitedRoomsCallsCount > 0
    }

    var recentlyVisitedRoomsUnderlyingReturnValue: Result<[String], ClientProxyError>!
    var recentlyVisitedRoomsReturnValue: Result<[String], ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return recentlyVisitedRoomsUnderlyingReturnValue
            } else {
                var returnValue: Result<[String], ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = recentlyVisitedRoomsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recentlyVisitedRoomsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    recentlyVisitedRoomsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var recentlyVisitedRoomsClosure: (() async -> Result<[String], ClientProxyError>)?

    func recentlyVisitedRooms() async -> Result<[String], ClientProxyError> {
        recentlyVisitedRoomsCallsCount += 1
        if let recentlyVisitedRoomsClosure = recentlyVisitedRoomsClosure {
            return await recentlyVisitedRoomsClosure()
        } else {
            return recentlyVisitedRoomsReturnValue
        }
    }
    //MARK: - recentConversationCounterparts

    var recentConversationCounterpartsUnderlyingCallsCount = 0
    var recentConversationCounterpartsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return recentConversationCounterpartsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = recentConversationCounterpartsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recentConversationCounterpartsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    recentConversationCounterpartsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var recentConversationCounterpartsCalled: Bool {
        return recentConversationCounterpartsCallsCount > 0
    }

    var recentConversationCounterpartsUnderlyingReturnValue: [UserProfileProxy]!
    var recentConversationCounterpartsReturnValue: [UserProfileProxy]! {
        get {
            if Thread.isMainThread {
                return recentConversationCounterpartsUnderlyingReturnValue
            } else {
                var returnValue: [UserProfileProxy]? = nil
                DispatchQueue.main.sync {
                    returnValue = recentConversationCounterpartsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recentConversationCounterpartsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    recentConversationCounterpartsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var recentConversationCounterpartsClosure: (() async -> [UserProfileProxy])?

    func recentConversationCounterparts() async -> [UserProfileProxy] {
        recentConversationCounterpartsCallsCount += 1
        if let recentConversationCounterpartsClosure = recentConversationCounterpartsClosure {
            return await recentConversationCounterpartsClosure()
        } else {
            return recentConversationCounterpartsReturnValue
        }
    }
    //MARK: - ed25519Base64

    var ed25519Base64UnderlyingCallsCount = 0
    var ed25519Base64CallsCount: Int {
        get {
            if Thread.isMainThread {
                return ed25519Base64UnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = ed25519Base64UnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ed25519Base64UnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    ed25519Base64UnderlyingCallsCount = newValue
                }
            }
        }
    }
    var ed25519Base64Called: Bool {
        return ed25519Base64CallsCount > 0
    }

    var ed25519Base64UnderlyingReturnValue: String?
    var ed25519Base64ReturnValue: String? {
        get {
            if Thread.isMainThread {
                return ed25519Base64UnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = ed25519Base64UnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ed25519Base64UnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    ed25519Base64UnderlyingReturnValue = newValue
                }
            }
        }
    }
    var ed25519Base64Closure: (() async -> String?)?

    func ed25519Base64() async -> String? {
        ed25519Base64CallsCount += 1
        if let ed25519Base64Closure = ed25519Base64Closure {
            return await ed25519Base64Closure()
        } else {
            return ed25519Base64ReturnValue
        }
    }
    //MARK: - curve25519Base64

    var curve25519Base64UnderlyingCallsCount = 0
    var curve25519Base64CallsCount: Int {
        get {
            if Thread.isMainThread {
                return curve25519Base64UnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = curve25519Base64UnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                curve25519Base64UnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    curve25519Base64UnderlyingCallsCount = newValue
                }
            }
        }
    }
    var curve25519Base64Called: Bool {
        return curve25519Base64CallsCount > 0
    }

    var curve25519Base64UnderlyingReturnValue: String?
    var curve25519Base64ReturnValue: String? {
        get {
            if Thread.isMainThread {
                return curve25519Base64UnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = curve25519Base64UnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                curve25519Base64UnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    curve25519Base64UnderlyingReturnValue = newValue
                }
            }
        }
    }
    var curve25519Base64Closure: (() async -> String?)?

    func curve25519Base64() async -> String? {
        curve25519Base64CallsCount += 1
        if let curve25519Base64Closure = curve25519Base64Closure {
            return await curve25519Base64Closure()
        } else {
            return curve25519Base64ReturnValue
        }
    }
    //MARK: - resetIdentity

    var resetIdentityUnderlyingCallsCount = 0
    var resetIdentityCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resetIdentityUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resetIdentityUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetIdentityUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resetIdentityUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var resetIdentityCalled: Bool {
        return resetIdentityCallsCount > 0
    }

    var resetIdentityUnderlyingReturnValue: Result<IdentityResetHandle?, ClientProxyError>!
    var resetIdentityReturnValue: Result<IdentityResetHandle?, ClientProxyError>! {
        get {
            if Thread.isMainThread {
                return resetIdentityUnderlyingReturnValue
            } else {
                var returnValue: Result<IdentityResetHandle?, ClientProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = resetIdentityUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetIdentityUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    resetIdentityUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var resetIdentityClosure: (() async -> Result<IdentityResetHandle?, ClientProxyError>)?

    func resetIdentity() async -> Result<IdentityResetHandle?, ClientProxyError> {
        resetIdentityCallsCount += 1
        if let resetIdentityClosure = resetIdentityClosure {
            return await resetIdentityClosure()
        } else {
            return resetIdentityReturnValue
        }
    }
    //MARK: - loadMediaContentForSource

    var loadMediaContentForSourceThrowableError: Error?
    var loadMediaContentForSourceUnderlyingCallsCount = 0
    var loadMediaContentForSourceCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadMediaContentForSourceUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaContentForSourceUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaContentForSourceUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaContentForSourceUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadMediaContentForSourceCalled: Bool {
        return loadMediaContentForSourceCallsCount > 0
    }
    var loadMediaContentForSourceReceivedSource: MediaSourceProxy?
    var loadMediaContentForSourceReceivedInvocations: [MediaSourceProxy] = []

    var loadMediaContentForSourceUnderlyingReturnValue: Data!
    var loadMediaContentForSourceReturnValue: Data! {
        get {
            if Thread.isMainThread {
                return loadMediaContentForSourceUnderlyingReturnValue
            } else {
                var returnValue: Data? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaContentForSourceUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaContentForSourceUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaContentForSourceUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadMediaContentForSourceClosure: ((MediaSourceProxy) async throws -> Data)?

    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        if let error = loadMediaContentForSourceThrowableError {
            throw error
        }
        loadMediaContentForSourceCallsCount += 1
        loadMediaContentForSourceReceivedSource = source
        DispatchQueue.main.async {
            self.loadMediaContentForSourceReceivedInvocations.append(source)
        }
        if let loadMediaContentForSourceClosure = loadMediaContentForSourceClosure {
            return try await loadMediaContentForSourceClosure(source)
        } else {
            return loadMediaContentForSourceReturnValue
        }
    }
    //MARK: - loadMediaThumbnailForSource

    var loadMediaThumbnailForSourceWidthHeightThrowableError: Error?
    var loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount = 0
    var loadMediaThumbnailForSourceWidthHeightCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadMediaThumbnailForSourceWidthHeightCalled: Bool {
        return loadMediaThumbnailForSourceWidthHeightCallsCount > 0
    }
    var loadMediaThumbnailForSourceWidthHeightReceivedArguments: (source: MediaSourceProxy, width: UInt, height: UInt)?
    var loadMediaThumbnailForSourceWidthHeightReceivedInvocations: [(source: MediaSourceProxy, width: UInt, height: UInt)] = []

    var loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue: Data!
    var loadMediaThumbnailForSourceWidthHeightReturnValue: Data! {
        get {
            if Thread.isMainThread {
                return loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue
            } else {
                var returnValue: Data? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadMediaThumbnailForSourceWidthHeightClosure: ((MediaSourceProxy, UInt, UInt) async throws -> Data)?

    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        if let error = loadMediaThumbnailForSourceWidthHeightThrowableError {
            throw error
        }
        loadMediaThumbnailForSourceWidthHeightCallsCount += 1
        loadMediaThumbnailForSourceWidthHeightReceivedArguments = (source: source, width: width, height: height)
        DispatchQueue.main.async {
            self.loadMediaThumbnailForSourceWidthHeightReceivedInvocations.append((source: source, width: width, height: height))
        }
        if let loadMediaThumbnailForSourceWidthHeightClosure = loadMediaThumbnailForSourceWidthHeightClosure {
            return try await loadMediaThumbnailForSourceWidthHeightClosure(source, width, height)
        } else {
            return loadMediaThumbnailForSourceWidthHeightReturnValue
        }
    }
    //MARK: - loadMediaFileForSource

    var loadMediaFileForSourceBodyThrowableError: Error?
    var loadMediaFileForSourceBodyUnderlyingCallsCount = 0
    var loadMediaFileForSourceBodyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadMediaFileForSourceBodyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaFileForSourceBodyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaFileForSourceBodyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaFileForSourceBodyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadMediaFileForSourceBodyCalled: Bool {
        return loadMediaFileForSourceBodyCallsCount > 0
    }
    var loadMediaFileForSourceBodyReceivedArguments: (source: MediaSourceProxy, body: String?)?
    var loadMediaFileForSourceBodyReceivedInvocations: [(source: MediaSourceProxy, body: String?)] = []

    var loadMediaFileForSourceBodyUnderlyingReturnValue: MediaFileHandleProxy!
    var loadMediaFileForSourceBodyReturnValue: MediaFileHandleProxy! {
        get {
            if Thread.isMainThread {
                return loadMediaFileForSourceBodyUnderlyingReturnValue
            } else {
                var returnValue: MediaFileHandleProxy? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaFileForSourceBodyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaFileForSourceBodyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaFileForSourceBodyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadMediaFileForSourceBodyClosure: ((MediaSourceProxy, String?) async throws -> MediaFileHandleProxy)?

    func loadMediaFileForSource(_ source: MediaSourceProxy, body: String?) async throws -> MediaFileHandleProxy {
        if let error = loadMediaFileForSourceBodyThrowableError {
            throw error
        }
        loadMediaFileForSourceBodyCallsCount += 1
        loadMediaFileForSourceBodyReceivedArguments = (source: source, body: body)
        DispatchQueue.main.async {
            self.loadMediaFileForSourceBodyReceivedInvocations.append((source: source, body: body))
        }
        if let loadMediaFileForSourceBodyClosure = loadMediaFileForSourceBodyClosure {
            return try await loadMediaFileForSourceBodyClosure(source, body)
        } else {
            return loadMediaFileForSourceBodyReturnValue
        }
    }
}
class CompletionSuggestionServiceMock: CompletionSuggestionServiceProtocol {
    var suggestionsPublisher: AnyPublisher<[SuggestionItem], Never> {
        get { return underlyingSuggestionsPublisher }
        set(value) { underlyingSuggestionsPublisher = value }
    }
    var underlyingSuggestionsPublisher: AnyPublisher<[SuggestionItem], Never>!

    //MARK: - processTextMessage

    var processTextMessageUnderlyingCallsCount = 0
    var processTextMessageCallsCount: Int {
        get {
            if Thread.isMainThread {
                return processTextMessageUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = processTextMessageUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                processTextMessageUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    processTextMessageUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var processTextMessageCalled: Bool {
        return processTextMessageCallsCount > 0
    }
    var processTextMessageReceivedTextMessage: String?
    var processTextMessageReceivedInvocations: [String?] = []
    var processTextMessageClosure: ((String?) -> Void)?

    func processTextMessage(_ textMessage: String?) {
        processTextMessageCallsCount += 1
        processTextMessageReceivedTextMessage = textMessage
        DispatchQueue.main.async {
            self.processTextMessageReceivedInvocations.append(textMessage)
        }
        processTextMessageClosure?(textMessage)
    }
    //MARK: - setSuggestionTrigger

    var setSuggestionTriggerUnderlyingCallsCount = 0
    var setSuggestionTriggerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setSuggestionTriggerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setSuggestionTriggerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setSuggestionTriggerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setSuggestionTriggerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setSuggestionTriggerCalled: Bool {
        return setSuggestionTriggerCallsCount > 0
    }
    var setSuggestionTriggerReceivedSuggestionTrigger: SuggestionTrigger?
    var setSuggestionTriggerReceivedInvocations: [SuggestionTrigger?] = []
    var setSuggestionTriggerClosure: ((SuggestionTrigger?) -> Void)?

    func setSuggestionTrigger(_ suggestionTrigger: SuggestionTrigger?) {
        setSuggestionTriggerCallsCount += 1
        setSuggestionTriggerReceivedSuggestionTrigger = suggestionTrigger
        DispatchQueue.main.async {
            self.setSuggestionTriggerReceivedInvocations.append(suggestionTrigger)
        }
        setSuggestionTriggerClosure?(suggestionTrigger)
    }
}
class ComposerDraftServiceMock: ComposerDraftServiceProtocol {

    //MARK: - saveDraft

    var saveDraftUnderlyingCallsCount = 0
    var saveDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return saveDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = saveDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                saveDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    saveDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var saveDraftCalled: Bool {
        return saveDraftCallsCount > 0
    }
    var saveDraftReceivedDraft: ComposerDraftProxy?
    var saveDraftReceivedInvocations: [ComposerDraftProxy] = []

    var saveDraftUnderlyingReturnValue: Result<Void, ComposerDraftServiceError>!
    var saveDraftReturnValue: Result<Void, ComposerDraftServiceError>! {
        get {
            if Thread.isMainThread {
                return saveDraftUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ComposerDraftServiceError>? = nil
                DispatchQueue.main.sync {
                    returnValue = saveDraftUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                saveDraftUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    saveDraftUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var saveDraftClosure: ((ComposerDraftProxy) async -> Result<Void, ComposerDraftServiceError>)?

    func saveDraft(_ draft: ComposerDraftProxy) async -> Result<Void, ComposerDraftServiceError> {
        saveDraftCallsCount += 1
        saveDraftReceivedDraft = draft
        DispatchQueue.main.async {
            self.saveDraftReceivedInvocations.append(draft)
        }
        if let saveDraftClosure = saveDraftClosure {
            return await saveDraftClosure(draft)
        } else {
            return saveDraftReturnValue
        }
    }
    //MARK: - saveVolatileDraft

    var saveVolatileDraftUnderlyingCallsCount = 0
    var saveVolatileDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return saveVolatileDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = saveVolatileDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                saveVolatileDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    saveVolatileDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var saveVolatileDraftCalled: Bool {
        return saveVolatileDraftCallsCount > 0
    }
    var saveVolatileDraftReceivedDraft: ComposerDraftProxy?
    var saveVolatileDraftReceivedInvocations: [ComposerDraftProxy] = []
    var saveVolatileDraftClosure: ((ComposerDraftProxy) -> Void)?

    func saveVolatileDraft(_ draft: ComposerDraftProxy) {
        saveVolatileDraftCallsCount += 1
        saveVolatileDraftReceivedDraft = draft
        DispatchQueue.main.async {
            self.saveVolatileDraftReceivedInvocations.append(draft)
        }
        saveVolatileDraftClosure?(draft)
    }
    //MARK: - loadDraft

    var loadDraftUnderlyingCallsCount = 0
    var loadDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadDraftCalled: Bool {
        return loadDraftCallsCount > 0
    }

    var loadDraftUnderlyingReturnValue: Result<ComposerDraftProxy?, ComposerDraftServiceError>!
    var loadDraftReturnValue: Result<ComposerDraftProxy?, ComposerDraftServiceError>! {
        get {
            if Thread.isMainThread {
                return loadDraftUnderlyingReturnValue
            } else {
                var returnValue: Result<ComposerDraftProxy?, ComposerDraftServiceError>? = nil
                DispatchQueue.main.sync {
                    returnValue = loadDraftUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadDraftUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadDraftUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadDraftClosure: (() async -> Result<ComposerDraftProxy?, ComposerDraftServiceError>)?

    func loadDraft() async -> Result<ComposerDraftProxy?, ComposerDraftServiceError> {
        loadDraftCallsCount += 1
        if let loadDraftClosure = loadDraftClosure {
            return await loadDraftClosure()
        } else {
            return loadDraftReturnValue
        }
    }
    //MARK: - loadVolatileDraft

    var loadVolatileDraftUnderlyingCallsCount = 0
    var loadVolatileDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadVolatileDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadVolatileDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadVolatileDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadVolatileDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadVolatileDraftCalled: Bool {
        return loadVolatileDraftCallsCount > 0
    }

    var loadVolatileDraftUnderlyingReturnValue: ComposerDraftProxy?
    var loadVolatileDraftReturnValue: ComposerDraftProxy? {
        get {
            if Thread.isMainThread {
                return loadVolatileDraftUnderlyingReturnValue
            } else {
                var returnValue: ComposerDraftProxy?? = nil
                DispatchQueue.main.sync {
                    returnValue = loadVolatileDraftUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadVolatileDraftUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadVolatileDraftUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadVolatileDraftClosure: (() -> ComposerDraftProxy?)?

    func loadVolatileDraft() -> ComposerDraftProxy? {
        loadVolatileDraftCallsCount += 1
        if let loadVolatileDraftClosure = loadVolatileDraftClosure {
            return loadVolatileDraftClosure()
        } else {
            return loadVolatileDraftReturnValue
        }
    }
    //MARK: - clearDraft

    var clearDraftUnderlyingCallsCount = 0
    var clearDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return clearDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = clearDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                clearDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    clearDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var clearDraftCalled: Bool {
        return clearDraftCallsCount > 0
    }

    var clearDraftUnderlyingReturnValue: Result<Void, ComposerDraftServiceError>!
    var clearDraftReturnValue: Result<Void, ComposerDraftServiceError>! {
        get {
            if Thread.isMainThread {
                return clearDraftUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, ComposerDraftServiceError>? = nil
                DispatchQueue.main.sync {
                    returnValue = clearDraftUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                clearDraftUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    clearDraftUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var clearDraftClosure: (() async -> Result<Void, ComposerDraftServiceError>)?

    func clearDraft() async -> Result<Void, ComposerDraftServiceError> {
        clearDraftCallsCount += 1
        if let clearDraftClosure = clearDraftClosure {
            return await clearDraftClosure()
        } else {
            return clearDraftReturnValue
        }
    }
    //MARK: - clearVolatileDraft

    var clearVolatileDraftUnderlyingCallsCount = 0
    var clearVolatileDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return clearVolatileDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = clearVolatileDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                clearVolatileDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    clearVolatileDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var clearVolatileDraftCalled: Bool {
        return clearVolatileDraftCallsCount > 0
    }
    var clearVolatileDraftClosure: (() -> Void)?

    func clearVolatileDraft() {
        clearVolatileDraftCallsCount += 1
        clearVolatileDraftClosure?()
    }
    //MARK: - getReply

    var getReplyEventIDUnderlyingCallsCount = 0
    var getReplyEventIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getReplyEventIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getReplyEventIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getReplyEventIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getReplyEventIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var getReplyEventIDCalled: Bool {
        return getReplyEventIDCallsCount > 0
    }
    var getReplyEventIDReceivedEventID: String?
    var getReplyEventIDReceivedInvocations: [String] = []

    var getReplyEventIDUnderlyingReturnValue: Result<TimelineItemReply, ComposerDraftServiceError>!
    var getReplyEventIDReturnValue: Result<TimelineItemReply, ComposerDraftServiceError>! {
        get {
            if Thread.isMainThread {
                return getReplyEventIDUnderlyingReturnValue
            } else {
                var returnValue: Result<TimelineItemReply, ComposerDraftServiceError>? = nil
                DispatchQueue.main.sync {
                    returnValue = getReplyEventIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getReplyEventIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getReplyEventIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var getReplyEventIDClosure: ((String) async -> Result<TimelineItemReply, ComposerDraftServiceError>)?

    func getReply(eventID: String) async -> Result<TimelineItemReply, ComposerDraftServiceError> {
        getReplyEventIDCallsCount += 1
        getReplyEventIDReceivedEventID = eventID
        DispatchQueue.main.async {
            self.getReplyEventIDReceivedInvocations.append(eventID)
        }
        if let getReplyEventIDClosure = getReplyEventIDClosure {
            return await getReplyEventIDClosure(eventID)
        } else {
            return getReplyEventIDReturnValue
        }
    }
}
class ElementCallServiceMock: ElementCallServiceProtocol {
    var actions: AnyPublisher<ElementCallServiceAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<ElementCallServiceAction, Never>!
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> {
        get { return underlyingOngoingCallRoomIDPublisher }
        set(value) { underlyingOngoingCallRoomIDPublisher = value }
    }
    var underlyingOngoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never>!

    //MARK: - setClientProxy

    var setClientProxyUnderlyingCallsCount = 0
    var setClientProxyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setClientProxyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setClientProxyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setClientProxyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setClientProxyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setClientProxyCalled: Bool {
        return setClientProxyCallsCount > 0
    }
    var setClientProxyReceivedClientProxy: ClientProxyProtocol?
    var setClientProxyReceivedInvocations: [ClientProxyProtocol] = []
    var setClientProxyClosure: ((ClientProxyProtocol) -> Void)?

    func setClientProxy(_ clientProxy: ClientProxyProtocol) {
        setClientProxyCallsCount += 1
        setClientProxyReceivedClientProxy = clientProxy
        DispatchQueue.main.async {
            self.setClientProxyReceivedInvocations.append(clientProxy)
        }
        setClientProxyClosure?(clientProxy)
    }
    //MARK: - setupCallSession

    var setupCallSessionRoomIDRoomDisplayNameUnderlyingCallsCount = 0
    var setupCallSessionRoomIDRoomDisplayNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setupCallSessionRoomIDRoomDisplayNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setupCallSessionRoomIDRoomDisplayNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setupCallSessionRoomIDRoomDisplayNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setupCallSessionRoomIDRoomDisplayNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setupCallSessionRoomIDRoomDisplayNameCalled: Bool {
        return setupCallSessionRoomIDRoomDisplayNameCallsCount > 0
    }
    var setupCallSessionRoomIDRoomDisplayNameReceivedArguments: (roomID: String, roomDisplayName: String)?
    var setupCallSessionRoomIDRoomDisplayNameReceivedInvocations: [(roomID: String, roomDisplayName: String)] = []
    var setupCallSessionRoomIDRoomDisplayNameClosure: ((String, String) async -> Void)?

    func setupCallSession(roomID: String, roomDisplayName: String) async {
        setupCallSessionRoomIDRoomDisplayNameCallsCount += 1
        setupCallSessionRoomIDRoomDisplayNameReceivedArguments = (roomID: roomID, roomDisplayName: roomDisplayName)
        DispatchQueue.main.async {
            self.setupCallSessionRoomIDRoomDisplayNameReceivedInvocations.append((roomID: roomID, roomDisplayName: roomDisplayName))
        }
        await setupCallSessionRoomIDRoomDisplayNameClosure?(roomID, roomDisplayName)
    }
    //MARK: - tearDownCallSession

    var tearDownCallSessionUnderlyingCallsCount = 0
    var tearDownCallSessionCallsCount: Int {
        get {
            if Thread.isMainThread {
                return tearDownCallSessionUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = tearDownCallSessionUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                tearDownCallSessionUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    tearDownCallSessionUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var tearDownCallSessionCalled: Bool {
        return tearDownCallSessionCallsCount > 0
    }
    var tearDownCallSessionClosure: (() -> Void)?

    func tearDownCallSession() {
        tearDownCallSessionCallsCount += 1
        tearDownCallSessionClosure?()
    }
    //MARK: - setAudioEnabled

    var setAudioEnabledRoomIDUnderlyingCallsCount = 0
    var setAudioEnabledRoomIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setAudioEnabledRoomIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setAudioEnabledRoomIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setAudioEnabledRoomIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setAudioEnabledRoomIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setAudioEnabledRoomIDCalled: Bool {
        return setAudioEnabledRoomIDCallsCount > 0
    }
    var setAudioEnabledRoomIDReceivedArguments: (enabled: Bool, roomID: String)?
    var setAudioEnabledRoomIDReceivedInvocations: [(enabled: Bool, roomID: String)] = []
    var setAudioEnabledRoomIDClosure: ((Bool, String) -> Void)?

    func setAudioEnabled(_ enabled: Bool, roomID: String) {
        setAudioEnabledRoomIDCallsCount += 1
        setAudioEnabledRoomIDReceivedArguments = (enabled: enabled, roomID: roomID)
        DispatchQueue.main.async {
            self.setAudioEnabledRoomIDReceivedInvocations.append((enabled: enabled, roomID: roomID))
        }
        setAudioEnabledRoomIDClosure?(enabled, roomID)
    }
}
class ElementCallWidgetDriverMock: ElementCallWidgetDriverProtocol {
    var widgetID: String {
        get { return underlyingWidgetID }
        set(value) { underlyingWidgetID = value }
    }
    var underlyingWidgetID: String!
    var messagePublisher: PassthroughSubject<String, Never> {
        get { return underlyingMessagePublisher }
        set(value) { underlyingMessagePublisher = value }
    }
    var underlyingMessagePublisher: PassthroughSubject<String, Never>!
    var actions: AnyPublisher<ElementCallWidgetDriverAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<ElementCallWidgetDriverAction, Never>!

    //MARK: - start

    var startBaseURLClientIDColorSchemeUnderlyingCallsCount = 0
    var startBaseURLClientIDColorSchemeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return startBaseURLClientIDColorSchemeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = startBaseURLClientIDColorSchemeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startBaseURLClientIDColorSchemeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    startBaseURLClientIDColorSchemeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var startBaseURLClientIDColorSchemeCalled: Bool {
        return startBaseURLClientIDColorSchemeCallsCount > 0
    }
    var startBaseURLClientIDColorSchemeReceivedArguments: (baseURL: URL, clientID: String, colorScheme: ColorScheme)?
    var startBaseURLClientIDColorSchemeReceivedInvocations: [(baseURL: URL, clientID: String, colorScheme: ColorScheme)] = []

    var startBaseURLClientIDColorSchemeUnderlyingReturnValue: Result<URL, ElementCallWidgetDriverError>!
    var startBaseURLClientIDColorSchemeReturnValue: Result<URL, ElementCallWidgetDriverError>! {
        get {
            if Thread.isMainThread {
                return startBaseURLClientIDColorSchemeUnderlyingReturnValue
            } else {
                var returnValue: Result<URL, ElementCallWidgetDriverError>? = nil
                DispatchQueue.main.sync {
                    returnValue = startBaseURLClientIDColorSchemeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startBaseURLClientIDColorSchemeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    startBaseURLClientIDColorSchemeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var startBaseURLClientIDColorSchemeClosure: ((URL, String, ColorScheme) async -> Result<URL, ElementCallWidgetDriverError>)?

    func start(baseURL: URL, clientID: String, colorScheme: ColorScheme) async -> Result<URL, ElementCallWidgetDriverError> {
        startBaseURLClientIDColorSchemeCallsCount += 1
        startBaseURLClientIDColorSchemeReceivedArguments = (baseURL: baseURL, clientID: clientID, colorScheme: colorScheme)
        DispatchQueue.main.async {
            self.startBaseURLClientIDColorSchemeReceivedInvocations.append((baseURL: baseURL, clientID: clientID, colorScheme: colorScheme))
        }
        if let startBaseURLClientIDColorSchemeClosure = startBaseURLClientIDColorSchemeClosure {
            return await startBaseURLClientIDColorSchemeClosure(baseURL, clientID, colorScheme)
        } else {
            return startBaseURLClientIDColorSchemeReturnValue
        }
    }
    //MARK: - handleMessage

    var handleMessageUnderlyingCallsCount = 0
    var handleMessageCallsCount: Int {
        get {
            if Thread.isMainThread {
                return handleMessageUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = handleMessageUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                handleMessageUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    handleMessageUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var handleMessageCalled: Bool {
        return handleMessageCallsCount > 0
    }
    var handleMessageReceivedMessage: String?
    var handleMessageReceivedInvocations: [String] = []

    var handleMessageUnderlyingReturnValue: Result<Bool, ElementCallWidgetDriverError>!
    var handleMessageReturnValue: Result<Bool, ElementCallWidgetDriverError>! {
        get {
            if Thread.isMainThread {
                return handleMessageUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, ElementCallWidgetDriverError>? = nil
                DispatchQueue.main.sync {
                    returnValue = handleMessageUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                handleMessageUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    handleMessageUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var handleMessageClosure: ((String) async -> Result<Bool, ElementCallWidgetDriverError>)?

    func handleMessage(_ message: String) async -> Result<Bool, ElementCallWidgetDriverError> {
        handleMessageCallsCount += 1
        handleMessageReceivedMessage = message
        DispatchQueue.main.async {
            self.handleMessageReceivedInvocations.append(message)
        }
        if let handleMessageClosure = handleMessageClosure {
            return await handleMessageClosure(message)
        } else {
            return handleMessageReturnValue
        }
    }
}
class InvitedRoomProxyMock: InvitedRoomProxyProtocol {
    var inviterCallsCount = 0
    var inviterCalled: Bool {
        return inviterCallsCount > 0
    }

    var inviter: RoomMemberProxyProtocol? {
        get async {
            inviterCallsCount += 1
            if let inviterClosure = inviterClosure {
                return await inviterClosure()
            } else {
                return underlyingInviter
            }
        }
    }
    var underlyingInviter: RoomMemberProxyProtocol?
    var inviterClosure: (() async -> RoomMemberProxyProtocol?)?
    var id: String {
        get { return underlyingId }
        set(value) { underlyingId = value }
    }
    var underlyingId: String!
    var canonicalAlias: String?
    var ownUserID: String {
        get { return underlyingOwnUserID }
        set(value) { underlyingOwnUserID = value }
    }
    var underlyingOwnUserID: String!
    var name: String?
    var topic: String?
    var avatar: RoomAvatar {
        get { return underlyingAvatar }
        set(value) { underlyingAvatar = value }
    }
    var underlyingAvatar: RoomAvatar!
    var avatarURL: URL?
    var isPublic: Bool {
        get { return underlyingIsPublic }
        set(value) { underlyingIsPublic = value }
    }
    var underlyingIsPublic: Bool!
    var isDirect: Bool {
        get { return underlyingIsDirect }
        set(value) { underlyingIsDirect = value }
    }
    var underlyingIsDirect: Bool!
    var isSpace: Bool {
        get { return underlyingIsSpace }
        set(value) { underlyingIsSpace = value }
    }
    var underlyingIsSpace: Bool!
    var joinedMembersCount: Int {
        get { return underlyingJoinedMembersCount }
        set(value) { underlyingJoinedMembersCount = value }
    }
    var underlyingJoinedMembersCount: Int!
    var activeMembersCount: Int {
        get { return underlyingActiveMembersCount }
        set(value) { underlyingActiveMembersCount = value }
    }
    var underlyingActiveMembersCount: Int!

    //MARK: - rejectInvitation

    var rejectInvitationUnderlyingCallsCount = 0
    var rejectInvitationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return rejectInvitationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = rejectInvitationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                rejectInvitationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    rejectInvitationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var rejectInvitationCalled: Bool {
        return rejectInvitationCallsCount > 0
    }

    var rejectInvitationUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var rejectInvitationReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return rejectInvitationUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = rejectInvitationUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                rejectInvitationUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    rejectInvitationUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var rejectInvitationClosure: (() async -> Result<Void, RoomProxyError>)?

    func rejectInvitation() async -> Result<Void, RoomProxyError> {
        rejectInvitationCallsCount += 1
        if let rejectInvitationClosure = rejectInvitationClosure {
            return await rejectInvitationClosure()
        } else {
            return rejectInvitationReturnValue
        }
    }
    //MARK: - acceptInvitation

    var acceptInvitationUnderlyingCallsCount = 0
    var acceptInvitationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return acceptInvitationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = acceptInvitationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                acceptInvitationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    acceptInvitationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var acceptInvitationCalled: Bool {
        return acceptInvitationCallsCount > 0
    }

    var acceptInvitationUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var acceptInvitationReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return acceptInvitationUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = acceptInvitationUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                acceptInvitationUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    acceptInvitationUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var acceptInvitationClosure: (() async -> Result<Void, RoomProxyError>)?

    func acceptInvitation() async -> Result<Void, RoomProxyError> {
        acceptInvitationCallsCount += 1
        if let acceptInvitationClosure = acceptInvitationClosure {
            return await acceptInvitationClosure()
        } else {
            return acceptInvitationReturnValue
        }
    }
}
class JoinedRoomProxyMock: JoinedRoomProxyProtocol {
    var isEncrypted: Bool {
        get { return underlyingIsEncrypted }
        set(value) { underlyingIsEncrypted = value }
    }
    var underlyingIsEncrypted: Bool!
    var isFavouriteCallsCount = 0
    var isFavouriteCalled: Bool {
        return isFavouriteCallsCount > 0
    }

    var isFavourite: Bool {
        get async {
            isFavouriteCallsCount += 1
            if let isFavouriteClosure = isFavouriteClosure {
                return await isFavouriteClosure()
            } else {
                return underlyingIsFavourite
            }
        }
    }
    var underlyingIsFavourite: Bool!
    var isFavouriteClosure: (() async -> Bool)?
    var pinnedEventIDsCallsCount = 0
    var pinnedEventIDsCalled: Bool {
        return pinnedEventIDsCallsCount > 0
    }

    var pinnedEventIDs: Set<String> {
        get async {
            pinnedEventIDsCallsCount += 1
            if let pinnedEventIDsClosure = pinnedEventIDsClosure {
                return await pinnedEventIDsClosure()
            } else {
                return underlyingPinnedEventIDs
            }
        }
    }
    var underlyingPinnedEventIDs: Set<String>!
    var pinnedEventIDsClosure: (() async -> Set<String>)?
    var hasOngoingCall: Bool {
        get { return underlyingHasOngoingCall }
        set(value) { underlyingHasOngoingCall = value }
    }
    var underlyingHasOngoingCall: Bool!
    var activeRoomCallParticipants: [String] = []
    var membersPublisher: CurrentValuePublisher<[RoomMemberProxyProtocol], Never> {
        get { return underlyingMembersPublisher }
        set(value) { underlyingMembersPublisher = value }
    }
    var underlyingMembersPublisher: CurrentValuePublisher<[RoomMemberProxyProtocol], Never>!
    var typingMembersPublisher: CurrentValuePublisher<[String], Never> {
        get { return underlyingTypingMembersPublisher }
        set(value) { underlyingTypingMembersPublisher = value }
    }
    var underlyingTypingMembersPublisher: CurrentValuePublisher<[String], Never>!
    var actionsPublisher: AnyPublisher<JoinedRoomProxyAction, Never> {
        get { return underlyingActionsPublisher }
        set(value) { underlyingActionsPublisher = value }
    }
    var underlyingActionsPublisher: AnyPublisher<JoinedRoomProxyAction, Never>!
    var timeline: TimelineProxyProtocol {
        get { return underlyingTimeline }
        set(value) { underlyingTimeline = value }
    }
    var underlyingTimeline: TimelineProxyProtocol!
    var pinnedEventsTimelineCallsCount = 0
    var pinnedEventsTimelineCalled: Bool {
        return pinnedEventsTimelineCallsCount > 0
    }

    var pinnedEventsTimeline: TimelineProxyProtocol? {
        get async {
            pinnedEventsTimelineCallsCount += 1
            if let pinnedEventsTimelineClosure = pinnedEventsTimelineClosure {
                return await pinnedEventsTimelineClosure()
            } else {
                return underlyingPinnedEventsTimeline
            }
        }
    }
    var underlyingPinnedEventsTimeline: TimelineProxyProtocol?
    var pinnedEventsTimelineClosure: (() async -> TimelineProxyProtocol?)?
    var id: String {
        get { return underlyingId }
        set(value) { underlyingId = value }
    }
    var underlyingId: String!
    var canonicalAlias: String?
    var ownUserID: String {
        get { return underlyingOwnUserID }
        set(value) { underlyingOwnUserID = value }
    }
    var underlyingOwnUserID: String!
    var name: String?
    var topic: String?
    var avatar: RoomAvatar {
        get { return underlyingAvatar }
        set(value) { underlyingAvatar = value }
    }
    var underlyingAvatar: RoomAvatar!
    var avatarURL: URL?
    var isPublic: Bool {
        get { return underlyingIsPublic }
        set(value) { underlyingIsPublic = value }
    }
    var underlyingIsPublic: Bool!
    var isDirect: Bool {
        get { return underlyingIsDirect }
        set(value) { underlyingIsDirect = value }
    }
    var underlyingIsDirect: Bool!
    var isSpace: Bool {
        get { return underlyingIsSpace }
        set(value) { underlyingIsSpace = value }
    }
    var underlyingIsSpace: Bool!
    var joinedMembersCount: Int {
        get { return underlyingJoinedMembersCount }
        set(value) { underlyingJoinedMembersCount = value }
    }
    var underlyingJoinedMembersCount: Int!
    var activeMembersCount: Int {
        get { return underlyingActiveMembersCount }
        set(value) { underlyingActiveMembersCount = value }
    }
    var underlyingActiveMembersCount: Int!

    //MARK: - subscribeForUpdates

    var subscribeForUpdatesUnderlyingCallsCount = 0
    var subscribeForUpdatesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return subscribeForUpdatesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeForUpdatesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeForUpdatesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeForUpdatesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var subscribeForUpdatesCalled: Bool {
        return subscribeForUpdatesCallsCount > 0
    }
    var subscribeForUpdatesClosure: (() async -> Void)?

    func subscribeForUpdates() async {
        subscribeForUpdatesCallsCount += 1
        await subscribeForUpdatesClosure?()
    }
    //MARK: - subscribeToRoomInfoUpdates

    var subscribeToRoomInfoUpdatesUnderlyingCallsCount = 0
    var subscribeToRoomInfoUpdatesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return subscribeToRoomInfoUpdatesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToRoomInfoUpdatesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToRoomInfoUpdatesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToRoomInfoUpdatesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var subscribeToRoomInfoUpdatesCalled: Bool {
        return subscribeToRoomInfoUpdatesCallsCount > 0
    }
    var subscribeToRoomInfoUpdatesClosure: (() -> Void)?

    func subscribeToRoomInfoUpdates() {
        subscribeToRoomInfoUpdatesCallsCount += 1
        subscribeToRoomInfoUpdatesClosure?()
    }
    //MARK: - timelineFocusedOnEvent

    var timelineFocusedOnEventEventIDNumberOfEventsUnderlyingCallsCount = 0
    var timelineFocusedOnEventEventIDNumberOfEventsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return timelineFocusedOnEventEventIDNumberOfEventsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = timelineFocusedOnEventEventIDNumberOfEventsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                timelineFocusedOnEventEventIDNumberOfEventsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    timelineFocusedOnEventEventIDNumberOfEventsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var timelineFocusedOnEventEventIDNumberOfEventsCalled: Bool {
        return timelineFocusedOnEventEventIDNumberOfEventsCallsCount > 0
    }
    var timelineFocusedOnEventEventIDNumberOfEventsReceivedArguments: (eventID: String, numberOfEvents: UInt16)?
    var timelineFocusedOnEventEventIDNumberOfEventsReceivedInvocations: [(eventID: String, numberOfEvents: UInt16)] = []

    var timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReturnValue: Result<TimelineProxyProtocol, RoomProxyError>!
    var timelineFocusedOnEventEventIDNumberOfEventsReturnValue: Result<TimelineProxyProtocol, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReturnValue
            } else {
                var returnValue: Result<TimelineProxyProtocol, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var timelineFocusedOnEventEventIDNumberOfEventsClosure: ((String, UInt16) async -> Result<TimelineProxyProtocol, RoomProxyError>)?

    func timelineFocusedOnEvent(eventID: String, numberOfEvents: UInt16) async -> Result<TimelineProxyProtocol, RoomProxyError> {
        timelineFocusedOnEventEventIDNumberOfEventsCallsCount += 1
        timelineFocusedOnEventEventIDNumberOfEventsReceivedArguments = (eventID: eventID, numberOfEvents: numberOfEvents)
        DispatchQueue.main.async {
            self.timelineFocusedOnEventEventIDNumberOfEventsReceivedInvocations.append((eventID: eventID, numberOfEvents: numberOfEvents))
        }
        if let timelineFocusedOnEventEventIDNumberOfEventsClosure = timelineFocusedOnEventEventIDNumberOfEventsClosure {
            return await timelineFocusedOnEventEventIDNumberOfEventsClosure(eventID, numberOfEvents)
        } else {
            return timelineFocusedOnEventEventIDNumberOfEventsReturnValue
        }
    }
    //MARK: - redact

    var redactUnderlyingCallsCount = 0
    var redactCallsCount: Int {
        get {
            if Thread.isMainThread {
                return redactUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = redactUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                redactUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    redactUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var redactCalled: Bool {
        return redactCallsCount > 0
    }
    var redactReceivedEventID: String?
    var redactReceivedInvocations: [String] = []

    var redactUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var redactReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return redactUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = redactUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                redactUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    redactUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var redactClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        redactCallsCount += 1
        redactReceivedEventID = eventID
        DispatchQueue.main.async {
            self.redactReceivedInvocations.append(eventID)
        }
        if let redactClosure = redactClosure {
            return await redactClosure(eventID)
        } else {
            return redactReturnValue
        }
    }
    //MARK: - reportContent

    var reportContentReasonUnderlyingCallsCount = 0
    var reportContentReasonCallsCount: Int {
        get {
            if Thread.isMainThread {
                return reportContentReasonUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = reportContentReasonUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                reportContentReasonUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    reportContentReasonUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var reportContentReasonCalled: Bool {
        return reportContentReasonCallsCount > 0
    }
    var reportContentReasonReceivedArguments: (eventID: String, reason: String?)?
    var reportContentReasonReceivedInvocations: [(eventID: String, reason: String?)] = []

    var reportContentReasonUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var reportContentReasonReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return reportContentReasonUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = reportContentReasonUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                reportContentReasonUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    reportContentReasonUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var reportContentReasonClosure: ((String, String?) async -> Result<Void, RoomProxyError>)?

    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        reportContentReasonCallsCount += 1
        reportContentReasonReceivedArguments = (eventID: eventID, reason: reason)
        DispatchQueue.main.async {
            self.reportContentReasonReceivedInvocations.append((eventID: eventID, reason: reason))
        }
        if let reportContentReasonClosure = reportContentReasonClosure {
            return await reportContentReasonClosure(eventID, reason)
        } else {
            return reportContentReasonReturnValue
        }
    }
    //MARK: - leaveRoom

    var leaveRoomUnderlyingCallsCount = 0
    var leaveRoomCallsCount: Int {
        get {
            if Thread.isMainThread {
                return leaveRoomUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = leaveRoomUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                leaveRoomUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    leaveRoomUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var leaveRoomCalled: Bool {
        return leaveRoomCallsCount > 0
    }

    var leaveRoomUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var leaveRoomReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return leaveRoomUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = leaveRoomUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                leaveRoomUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    leaveRoomUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var leaveRoomClosure: (() async -> Result<Void, RoomProxyError>)?

    func leaveRoom() async -> Result<Void, RoomProxyError> {
        leaveRoomCallsCount += 1
        if let leaveRoomClosure = leaveRoomClosure {
            return await leaveRoomClosure()
        } else {
            return leaveRoomReturnValue
        }
    }
    //MARK: - updateMembers

    var updateMembersUnderlyingCallsCount = 0
    var updateMembersCallsCount: Int {
        get {
            if Thread.isMainThread {
                return updateMembersUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = updateMembersUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                updateMembersUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    updateMembersUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var updateMembersCalled: Bool {
        return updateMembersCallsCount > 0
    }
    var updateMembersClosure: (() async -> Void)?

    func updateMembers() async {
        updateMembersCallsCount += 1
        await updateMembersClosure?()
    }
    //MARK: - getMember

    var getMemberUserIDUnderlyingCallsCount = 0
    var getMemberUserIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getMemberUserIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getMemberUserIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getMemberUserIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getMemberUserIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var getMemberUserIDCalled: Bool {
        return getMemberUserIDCallsCount > 0
    }
    var getMemberUserIDReceivedUserID: String?
    var getMemberUserIDReceivedInvocations: [String] = []

    var getMemberUserIDUnderlyingReturnValue: Result<RoomMemberProxyProtocol, RoomProxyError>!
    var getMemberUserIDReturnValue: Result<RoomMemberProxyProtocol, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return getMemberUserIDUnderlyingReturnValue
            } else {
                var returnValue: Result<RoomMemberProxyProtocol, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = getMemberUserIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getMemberUserIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getMemberUserIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var getMemberUserIDClosure: ((String) async -> Result<RoomMemberProxyProtocol, RoomProxyError>)?

    func getMember(userID: String) async -> Result<RoomMemberProxyProtocol, RoomProxyError> {
        getMemberUserIDCallsCount += 1
        getMemberUserIDReceivedUserID = userID
        DispatchQueue.main.async {
            self.getMemberUserIDReceivedInvocations.append(userID)
        }
        if let getMemberUserIDClosure = getMemberUserIDClosure {
            return await getMemberUserIDClosure(userID)
        } else {
            return getMemberUserIDReturnValue
        }
    }
    //MARK: - invite

    var inviteUserIDUnderlyingCallsCount = 0
    var inviteUserIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return inviteUserIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = inviteUserIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                inviteUserIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    inviteUserIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var inviteUserIDCalled: Bool {
        return inviteUserIDCallsCount > 0
    }
    var inviteUserIDReceivedUserID: String?
    var inviteUserIDReceivedInvocations: [String] = []

    var inviteUserIDUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var inviteUserIDReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return inviteUserIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = inviteUserIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                inviteUserIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    inviteUserIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var inviteUserIDClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func invite(userID: String) async -> Result<Void, RoomProxyError> {
        inviteUserIDCallsCount += 1
        inviteUserIDReceivedUserID = userID
        DispatchQueue.main.async {
            self.inviteUserIDReceivedInvocations.append(userID)
        }
        if let inviteUserIDClosure = inviteUserIDClosure {
            return await inviteUserIDClosure(userID)
        } else {
            return inviteUserIDReturnValue
        }
    }
    //MARK: - setName

    var setNameUnderlyingCallsCount = 0
    var setNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setNameCalled: Bool {
        return setNameCallsCount > 0
    }
    var setNameReceivedName: String?
    var setNameReceivedInvocations: [String] = []

    var setNameUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var setNameReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return setNameUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = setNameUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setNameUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    setNameUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var setNameClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func setName(_ name: String) async -> Result<Void, RoomProxyError> {
        setNameCallsCount += 1
        setNameReceivedName = name
        DispatchQueue.main.async {
            self.setNameReceivedInvocations.append(name)
        }
        if let setNameClosure = setNameClosure {
            return await setNameClosure(name)
        } else {
            return setNameReturnValue
        }
    }
    //MARK: - setTopic

    var setTopicUnderlyingCallsCount = 0
    var setTopicCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setTopicUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setTopicUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setTopicUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setTopicUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setTopicCalled: Bool {
        return setTopicCallsCount > 0
    }
    var setTopicReceivedTopic: String?
    var setTopicReceivedInvocations: [String] = []

    var setTopicUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var setTopicReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return setTopicUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = setTopicUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setTopicUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    setTopicUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var setTopicClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func setTopic(_ topic: String) async -> Result<Void, RoomProxyError> {
        setTopicCallsCount += 1
        setTopicReceivedTopic = topic
        DispatchQueue.main.async {
            self.setTopicReceivedInvocations.append(topic)
        }
        if let setTopicClosure = setTopicClosure {
            return await setTopicClosure(topic)
        } else {
            return setTopicReturnValue
        }
    }
    //MARK: - removeAvatar

    var removeAvatarUnderlyingCallsCount = 0
    var removeAvatarCallsCount: Int {
        get {
            if Thread.isMainThread {
                return removeAvatarUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = removeAvatarUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removeAvatarUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    removeAvatarUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var removeAvatarCalled: Bool {
        return removeAvatarCallsCount > 0
    }

    var removeAvatarUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var removeAvatarReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return removeAvatarUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = removeAvatarUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removeAvatarUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    removeAvatarUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var removeAvatarClosure: (() async -> Result<Void, RoomProxyError>)?

    func removeAvatar() async -> Result<Void, RoomProxyError> {
        removeAvatarCallsCount += 1
        if let removeAvatarClosure = removeAvatarClosure {
            return await removeAvatarClosure()
        } else {
            return removeAvatarReturnValue
        }
    }
    //MARK: - uploadAvatar

    var uploadAvatarMediaUnderlyingCallsCount = 0
    var uploadAvatarMediaCallsCount: Int {
        get {
            if Thread.isMainThread {
                return uploadAvatarMediaUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = uploadAvatarMediaUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                uploadAvatarMediaUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    uploadAvatarMediaUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var uploadAvatarMediaCalled: Bool {
        return uploadAvatarMediaCallsCount > 0
    }
    var uploadAvatarMediaReceivedMedia: MediaInfo?
    var uploadAvatarMediaReceivedInvocations: [MediaInfo] = []

    var uploadAvatarMediaUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var uploadAvatarMediaReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return uploadAvatarMediaUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = uploadAvatarMediaUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                uploadAvatarMediaUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    uploadAvatarMediaUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var uploadAvatarMediaClosure: ((MediaInfo) async -> Result<Void, RoomProxyError>)?

    func uploadAvatar(media: MediaInfo) async -> Result<Void, RoomProxyError> {
        uploadAvatarMediaCallsCount += 1
        uploadAvatarMediaReceivedMedia = media
        DispatchQueue.main.async {
            self.uploadAvatarMediaReceivedInvocations.append(media)
        }
        if let uploadAvatarMediaClosure = uploadAvatarMediaClosure {
            return await uploadAvatarMediaClosure(media)
        } else {
            return uploadAvatarMediaReturnValue
        }
    }
    //MARK: - markAsRead

    var markAsReadReceiptTypeUnderlyingCallsCount = 0
    var markAsReadReceiptTypeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return markAsReadReceiptTypeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = markAsReadReceiptTypeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                markAsReadReceiptTypeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    markAsReadReceiptTypeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var markAsReadReceiptTypeCalled: Bool {
        return markAsReadReceiptTypeCallsCount > 0
    }
    var markAsReadReceiptTypeReceivedReceiptType: ReceiptType?
    var markAsReadReceiptTypeReceivedInvocations: [ReceiptType] = []

    var markAsReadReceiptTypeUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var markAsReadReceiptTypeReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return markAsReadReceiptTypeUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = markAsReadReceiptTypeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                markAsReadReceiptTypeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    markAsReadReceiptTypeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var markAsReadReceiptTypeClosure: ((ReceiptType) async -> Result<Void, RoomProxyError>)?

    func markAsRead(receiptType: ReceiptType) async -> Result<Void, RoomProxyError> {
        markAsReadReceiptTypeCallsCount += 1
        markAsReadReceiptTypeReceivedReceiptType = receiptType
        DispatchQueue.main.async {
            self.markAsReadReceiptTypeReceivedInvocations.append(receiptType)
        }
        if let markAsReadReceiptTypeClosure = markAsReadReceiptTypeClosure {
            return await markAsReadReceiptTypeClosure(receiptType)
        } else {
            return markAsReadReceiptTypeReturnValue
        }
    }
    //MARK: - edit

    var editEventIDNewContentUnderlyingCallsCount = 0
    var editEventIDNewContentCallsCount: Int {
        get {
            if Thread.isMainThread {
                return editEventIDNewContentUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = editEventIDNewContentUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                editEventIDNewContentUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    editEventIDNewContentUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var editEventIDNewContentCalled: Bool {
        return editEventIDNewContentCallsCount > 0
    }
    var editEventIDNewContentReceivedArguments: (eventID: String, newContent: RoomMessageEventContentWithoutRelation)?
    var editEventIDNewContentReceivedInvocations: [(eventID: String, newContent: RoomMessageEventContentWithoutRelation)] = []

    var editEventIDNewContentUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var editEventIDNewContentReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return editEventIDNewContentUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = editEventIDNewContentUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                editEventIDNewContentUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    editEventIDNewContentUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var editEventIDNewContentClosure: ((String, RoomMessageEventContentWithoutRelation) async -> Result<Void, RoomProxyError>)?

    func edit(eventID: String, newContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, RoomProxyError> {
        editEventIDNewContentCallsCount += 1
        editEventIDNewContentReceivedArguments = (eventID: eventID, newContent: newContent)
        DispatchQueue.main.async {
            self.editEventIDNewContentReceivedInvocations.append((eventID: eventID, newContent: newContent))
        }
        if let editEventIDNewContentClosure = editEventIDNewContentClosure {
            return await editEventIDNewContentClosure(eventID, newContent)
        } else {
            return editEventIDNewContentReturnValue
        }
    }
    //MARK: - sendTypingNotification

    var sendTypingNotificationIsTypingUnderlyingCallsCount = 0
    var sendTypingNotificationIsTypingCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendTypingNotificationIsTypingUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendTypingNotificationIsTypingUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendTypingNotificationIsTypingUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendTypingNotificationIsTypingUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendTypingNotificationIsTypingCalled: Bool {
        return sendTypingNotificationIsTypingCallsCount > 0
    }
    var sendTypingNotificationIsTypingReceivedIsTyping: Bool?
    var sendTypingNotificationIsTypingReceivedInvocations: [Bool] = []

    var sendTypingNotificationIsTypingUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var sendTypingNotificationIsTypingReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return sendTypingNotificationIsTypingUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendTypingNotificationIsTypingUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendTypingNotificationIsTypingUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendTypingNotificationIsTypingUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendTypingNotificationIsTypingClosure: ((Bool) async -> Result<Void, RoomProxyError>)?

    @discardableResult
    func sendTypingNotification(isTyping: Bool) async -> Result<Void, RoomProxyError> {
        sendTypingNotificationIsTypingCallsCount += 1
        sendTypingNotificationIsTypingReceivedIsTyping = isTyping
        DispatchQueue.main.async {
            self.sendTypingNotificationIsTypingReceivedInvocations.append(isTyping)
        }
        if let sendTypingNotificationIsTypingClosure = sendTypingNotificationIsTypingClosure {
            return await sendTypingNotificationIsTypingClosure(isTyping)
        } else {
            return sendTypingNotificationIsTypingReturnValue
        }
    }
    //MARK: - resend

    var resendItemIDUnderlyingCallsCount = 0
    var resendItemIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resendItemIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resendItemIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resendItemIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resendItemIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var resendItemIDCalled: Bool {
        return resendItemIDCallsCount > 0
    }
    var resendItemIDReceivedItemID: TimelineItemIdentifier?
    var resendItemIDReceivedInvocations: [TimelineItemIdentifier] = []

    var resendItemIDUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var resendItemIDReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return resendItemIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = resendItemIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resendItemIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    resendItemIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var resendItemIDClosure: ((TimelineItemIdentifier) async -> Result<Void, RoomProxyError>)?

    func resend(itemID: TimelineItemIdentifier) async -> Result<Void, RoomProxyError> {
        resendItemIDCallsCount += 1
        resendItemIDReceivedItemID = itemID
        DispatchQueue.main.async {
            self.resendItemIDReceivedInvocations.append(itemID)
        }
        if let resendItemIDClosure = resendItemIDClosure {
            return await resendItemIDClosure(itemID)
        } else {
            return resendItemIDReturnValue
        }
    }
    //MARK: - ignoreDeviceTrustAndResend

    var ignoreDeviceTrustAndResendDevicesItemIDUnderlyingCallsCount = 0
    var ignoreDeviceTrustAndResendDevicesItemIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return ignoreDeviceTrustAndResendDevicesItemIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = ignoreDeviceTrustAndResendDevicesItemIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ignoreDeviceTrustAndResendDevicesItemIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    ignoreDeviceTrustAndResendDevicesItemIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var ignoreDeviceTrustAndResendDevicesItemIDCalled: Bool {
        return ignoreDeviceTrustAndResendDevicesItemIDCallsCount > 0
    }
    var ignoreDeviceTrustAndResendDevicesItemIDReceivedArguments: (devices: [String: [String]], itemID: TimelineItemIdentifier)?
    var ignoreDeviceTrustAndResendDevicesItemIDReceivedInvocations: [(devices: [String: [String]], itemID: TimelineItemIdentifier)] = []

    var ignoreDeviceTrustAndResendDevicesItemIDUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var ignoreDeviceTrustAndResendDevicesItemIDReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return ignoreDeviceTrustAndResendDevicesItemIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = ignoreDeviceTrustAndResendDevicesItemIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ignoreDeviceTrustAndResendDevicesItemIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    ignoreDeviceTrustAndResendDevicesItemIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var ignoreDeviceTrustAndResendDevicesItemIDClosure: (([String: [String]], TimelineItemIdentifier) async -> Result<Void, RoomProxyError>)?

    func ignoreDeviceTrustAndResend(devices: [String: [String]], itemID: TimelineItemIdentifier) async -> Result<Void, RoomProxyError> {
        ignoreDeviceTrustAndResendDevicesItemIDCallsCount += 1
        ignoreDeviceTrustAndResendDevicesItemIDReceivedArguments = (devices: devices, itemID: itemID)
        DispatchQueue.main.async {
            self.ignoreDeviceTrustAndResendDevicesItemIDReceivedInvocations.append((devices: devices, itemID: itemID))
        }
        if let ignoreDeviceTrustAndResendDevicesItemIDClosure = ignoreDeviceTrustAndResendDevicesItemIDClosure {
            return await ignoreDeviceTrustAndResendDevicesItemIDClosure(devices, itemID)
        } else {
            return ignoreDeviceTrustAndResendDevicesItemIDReturnValue
        }
    }
    //MARK: - withdrawVerificationAndResend

    var withdrawVerificationAndResendUserIDsItemIDUnderlyingCallsCount = 0
    var withdrawVerificationAndResendUserIDsItemIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return withdrawVerificationAndResendUserIDsItemIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = withdrawVerificationAndResendUserIDsItemIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                withdrawVerificationAndResendUserIDsItemIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    withdrawVerificationAndResendUserIDsItemIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var withdrawVerificationAndResendUserIDsItemIDCalled: Bool {
        return withdrawVerificationAndResendUserIDsItemIDCallsCount > 0
    }
    var withdrawVerificationAndResendUserIDsItemIDReceivedArguments: (userIDs: [String], itemID: TimelineItemIdentifier)?
    var withdrawVerificationAndResendUserIDsItemIDReceivedInvocations: [(userIDs: [String], itemID: TimelineItemIdentifier)] = []

    var withdrawVerificationAndResendUserIDsItemIDUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var withdrawVerificationAndResendUserIDsItemIDReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return withdrawVerificationAndResendUserIDsItemIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = withdrawVerificationAndResendUserIDsItemIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                withdrawVerificationAndResendUserIDsItemIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    withdrawVerificationAndResendUserIDsItemIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var withdrawVerificationAndResendUserIDsItemIDClosure: (([String], TimelineItemIdentifier) async -> Result<Void, RoomProxyError>)?

    func withdrawVerificationAndResend(userIDs: [String], itemID: TimelineItemIdentifier) async -> Result<Void, RoomProxyError> {
        withdrawVerificationAndResendUserIDsItemIDCallsCount += 1
        withdrawVerificationAndResendUserIDsItemIDReceivedArguments = (userIDs: userIDs, itemID: itemID)
        DispatchQueue.main.async {
            self.withdrawVerificationAndResendUserIDsItemIDReceivedInvocations.append((userIDs: userIDs, itemID: itemID))
        }
        if let withdrawVerificationAndResendUserIDsItemIDClosure = withdrawVerificationAndResendUserIDsItemIDClosure {
            return await withdrawVerificationAndResendUserIDsItemIDClosure(userIDs, itemID)
        } else {
            return withdrawVerificationAndResendUserIDsItemIDReturnValue
        }
    }
    //MARK: - flagAsUnread

    var flagAsUnreadUnderlyingCallsCount = 0
    var flagAsUnreadCallsCount: Int {
        get {
            if Thread.isMainThread {
                return flagAsUnreadUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = flagAsUnreadUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                flagAsUnreadUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    flagAsUnreadUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var flagAsUnreadCalled: Bool {
        return flagAsUnreadCallsCount > 0
    }
    var flagAsUnreadReceivedIsUnread: Bool?
    var flagAsUnreadReceivedInvocations: [Bool] = []

    var flagAsUnreadUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var flagAsUnreadReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return flagAsUnreadUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = flagAsUnreadUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                flagAsUnreadUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    flagAsUnreadUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var flagAsUnreadClosure: ((Bool) async -> Result<Void, RoomProxyError>)?

    func flagAsUnread(_ isUnread: Bool) async -> Result<Void, RoomProxyError> {
        flagAsUnreadCallsCount += 1
        flagAsUnreadReceivedIsUnread = isUnread
        DispatchQueue.main.async {
            self.flagAsUnreadReceivedInvocations.append(isUnread)
        }
        if let flagAsUnreadClosure = flagAsUnreadClosure {
            return await flagAsUnreadClosure(isUnread)
        } else {
            return flagAsUnreadReturnValue
        }
    }
    //MARK: - flagAsFavourite

    var flagAsFavouriteUnderlyingCallsCount = 0
    var flagAsFavouriteCallsCount: Int {
        get {
            if Thread.isMainThread {
                return flagAsFavouriteUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = flagAsFavouriteUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                flagAsFavouriteUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    flagAsFavouriteUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var flagAsFavouriteCalled: Bool {
        return flagAsFavouriteCallsCount > 0
    }
    var flagAsFavouriteReceivedIsFavourite: Bool?
    var flagAsFavouriteReceivedInvocations: [Bool] = []

    var flagAsFavouriteUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var flagAsFavouriteReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return flagAsFavouriteUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = flagAsFavouriteUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                flagAsFavouriteUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    flagAsFavouriteUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var flagAsFavouriteClosure: ((Bool) async -> Result<Void, RoomProxyError>)?

    func flagAsFavourite(_ isFavourite: Bool) async -> Result<Void, RoomProxyError> {
        flagAsFavouriteCallsCount += 1
        flagAsFavouriteReceivedIsFavourite = isFavourite
        DispatchQueue.main.async {
            self.flagAsFavouriteReceivedInvocations.append(isFavourite)
        }
        if let flagAsFavouriteClosure = flagAsFavouriteClosure {
            return await flagAsFavouriteClosure(isFavourite)
        } else {
            return flagAsFavouriteReturnValue
        }
    }
    //MARK: - powerLevels

    var powerLevelsUnderlyingCallsCount = 0
    var powerLevelsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return powerLevelsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = powerLevelsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                powerLevelsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    powerLevelsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var powerLevelsCalled: Bool {
        return powerLevelsCallsCount > 0
    }

    var powerLevelsUnderlyingReturnValue: Result<RoomPowerLevels, RoomProxyError>!
    var powerLevelsReturnValue: Result<RoomPowerLevels, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return powerLevelsUnderlyingReturnValue
            } else {
                var returnValue: Result<RoomPowerLevels, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = powerLevelsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                powerLevelsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    powerLevelsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var powerLevelsClosure: (() async -> Result<RoomPowerLevels, RoomProxyError>)?

    func powerLevels() async -> Result<RoomPowerLevels, RoomProxyError> {
        powerLevelsCallsCount += 1
        if let powerLevelsClosure = powerLevelsClosure {
            return await powerLevelsClosure()
        } else {
            return powerLevelsReturnValue
        }
    }
    //MARK: - applyPowerLevelChanges

    var applyPowerLevelChangesUnderlyingCallsCount = 0
    var applyPowerLevelChangesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return applyPowerLevelChangesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = applyPowerLevelChangesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                applyPowerLevelChangesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    applyPowerLevelChangesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var applyPowerLevelChangesCalled: Bool {
        return applyPowerLevelChangesCallsCount > 0
    }
    var applyPowerLevelChangesReceivedChanges: RoomPowerLevelChanges?
    var applyPowerLevelChangesReceivedInvocations: [RoomPowerLevelChanges] = []

    var applyPowerLevelChangesUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var applyPowerLevelChangesReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return applyPowerLevelChangesUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = applyPowerLevelChangesUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                applyPowerLevelChangesUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    applyPowerLevelChangesUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var applyPowerLevelChangesClosure: ((RoomPowerLevelChanges) async -> Result<Void, RoomProxyError>)?

    func applyPowerLevelChanges(_ changes: RoomPowerLevelChanges) async -> Result<Void, RoomProxyError> {
        applyPowerLevelChangesCallsCount += 1
        applyPowerLevelChangesReceivedChanges = changes
        DispatchQueue.main.async {
            self.applyPowerLevelChangesReceivedInvocations.append(changes)
        }
        if let applyPowerLevelChangesClosure = applyPowerLevelChangesClosure {
            return await applyPowerLevelChangesClosure(changes)
        } else {
            return applyPowerLevelChangesReturnValue
        }
    }
    //MARK: - resetPowerLevels

    var resetPowerLevelsUnderlyingCallsCount = 0
    var resetPowerLevelsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resetPowerLevelsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resetPowerLevelsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetPowerLevelsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resetPowerLevelsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var resetPowerLevelsCalled: Bool {
        return resetPowerLevelsCallsCount > 0
    }

    var resetPowerLevelsUnderlyingReturnValue: Result<RoomPowerLevels, RoomProxyError>!
    var resetPowerLevelsReturnValue: Result<RoomPowerLevels, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return resetPowerLevelsUnderlyingReturnValue
            } else {
                var returnValue: Result<RoomPowerLevels, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = resetPowerLevelsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetPowerLevelsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    resetPowerLevelsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var resetPowerLevelsClosure: (() async -> Result<RoomPowerLevels, RoomProxyError>)?

    func resetPowerLevels() async -> Result<RoomPowerLevels, RoomProxyError> {
        resetPowerLevelsCallsCount += 1
        if let resetPowerLevelsClosure = resetPowerLevelsClosure {
            return await resetPowerLevelsClosure()
        } else {
            return resetPowerLevelsReturnValue
        }
    }
    //MARK: - suggestedRole

    var suggestedRoleForUnderlyingCallsCount = 0
    var suggestedRoleForCallsCount: Int {
        get {
            if Thread.isMainThread {
                return suggestedRoleForUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = suggestedRoleForUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                suggestedRoleForUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    suggestedRoleForUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var suggestedRoleForCalled: Bool {
        return suggestedRoleForCallsCount > 0
    }
    var suggestedRoleForReceivedUserID: String?
    var suggestedRoleForReceivedInvocations: [String] = []

    var suggestedRoleForUnderlyingReturnValue: Result<RoomMemberRole, RoomProxyError>!
    var suggestedRoleForReturnValue: Result<RoomMemberRole, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return suggestedRoleForUnderlyingReturnValue
            } else {
                var returnValue: Result<RoomMemberRole, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = suggestedRoleForUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                suggestedRoleForUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    suggestedRoleForUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var suggestedRoleForClosure: ((String) async -> Result<RoomMemberRole, RoomProxyError>)?

    func suggestedRole(for userID: String) async -> Result<RoomMemberRole, RoomProxyError> {
        suggestedRoleForCallsCount += 1
        suggestedRoleForReceivedUserID = userID
        DispatchQueue.main.async {
            self.suggestedRoleForReceivedInvocations.append(userID)
        }
        if let suggestedRoleForClosure = suggestedRoleForClosure {
            return await suggestedRoleForClosure(userID)
        } else {
            return suggestedRoleForReturnValue
        }
    }
    //MARK: - updatePowerLevelsForUsers

    var updatePowerLevelsForUsersUnderlyingCallsCount = 0
    var updatePowerLevelsForUsersCallsCount: Int {
        get {
            if Thread.isMainThread {
                return updatePowerLevelsForUsersUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = updatePowerLevelsForUsersUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                updatePowerLevelsForUsersUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    updatePowerLevelsForUsersUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var updatePowerLevelsForUsersCalled: Bool {
        return updatePowerLevelsForUsersCallsCount > 0
    }
    var updatePowerLevelsForUsersReceivedUpdates: [(userID: String, powerLevel: Int64)]?
    var updatePowerLevelsForUsersReceivedInvocations: [[(userID: String, powerLevel: Int64)]] = []

    var updatePowerLevelsForUsersUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var updatePowerLevelsForUsersReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return updatePowerLevelsForUsersUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = updatePowerLevelsForUsersUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                updatePowerLevelsForUsersUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    updatePowerLevelsForUsersUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var updatePowerLevelsForUsersClosure: (([(userID: String, powerLevel: Int64)]) async -> Result<Void, RoomProxyError>)?

    func updatePowerLevelsForUsers(_ updates: [(userID: String, powerLevel: Int64)]) async -> Result<Void, RoomProxyError> {
        updatePowerLevelsForUsersCallsCount += 1
        updatePowerLevelsForUsersReceivedUpdates = updates
        DispatchQueue.main.async {
            self.updatePowerLevelsForUsersReceivedInvocations.append(updates)
        }
        if let updatePowerLevelsForUsersClosure = updatePowerLevelsForUsersClosure {
            return await updatePowerLevelsForUsersClosure(updates)
        } else {
            return updatePowerLevelsForUsersReturnValue
        }
    }
    //MARK: - canUser

    var canUserUserIDSendStateEventUnderlyingCallsCount = 0
    var canUserUserIDSendStateEventCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserUserIDSendStateEventUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserUserIDSendStateEventUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserUserIDSendStateEventUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserUserIDSendStateEventUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var canUserUserIDSendStateEventCalled: Bool {
        return canUserUserIDSendStateEventCallsCount > 0
    }
    var canUserUserIDSendStateEventReceivedArguments: (userID: String, event: StateEventType)?
    var canUserUserIDSendStateEventReceivedInvocations: [(userID: String, event: StateEventType)] = []

    var canUserUserIDSendStateEventUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserUserIDSendStateEventReturnValue: Result<Bool, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return canUserUserIDSendStateEventUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserUserIDSendStateEventUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserUserIDSendStateEventUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserUserIDSendStateEventUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var canUserUserIDSendStateEventClosure: ((String, StateEventType) async -> Result<Bool, RoomProxyError>)?

    func canUser(userID: String, sendStateEvent event: StateEventType) async -> Result<Bool, RoomProxyError> {
        canUserUserIDSendStateEventCallsCount += 1
        canUserUserIDSendStateEventReceivedArguments = (userID: userID, event: event)
        DispatchQueue.main.async {
            self.canUserUserIDSendStateEventReceivedInvocations.append((userID: userID, event: event))
        }
        if let canUserUserIDSendStateEventClosure = canUserUserIDSendStateEventClosure {
            return await canUserUserIDSendStateEventClosure(userID, event)
        } else {
            return canUserUserIDSendStateEventReturnValue
        }
    }
    //MARK: - canUserInvite

    var canUserInviteUserIDUnderlyingCallsCount = 0
    var canUserInviteUserIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserInviteUserIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserInviteUserIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserInviteUserIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserInviteUserIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var canUserInviteUserIDCalled: Bool {
        return canUserInviteUserIDCallsCount > 0
    }
    var canUserInviteUserIDReceivedUserID: String?
    var canUserInviteUserIDReceivedInvocations: [String] = []

    var canUserInviteUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserInviteUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return canUserInviteUserIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserInviteUserIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserInviteUserIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserInviteUserIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var canUserInviteUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserInvite(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserInviteUserIDCallsCount += 1
        canUserInviteUserIDReceivedUserID = userID
        DispatchQueue.main.async {
            self.canUserInviteUserIDReceivedInvocations.append(userID)
        }
        if let canUserInviteUserIDClosure = canUserInviteUserIDClosure {
            return await canUserInviteUserIDClosure(userID)
        } else {
            return canUserInviteUserIDReturnValue
        }
    }
    //MARK: - canUserRedactOther

    var canUserRedactOtherUserIDUnderlyingCallsCount = 0
    var canUserRedactOtherUserIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserRedactOtherUserIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserRedactOtherUserIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserRedactOtherUserIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserRedactOtherUserIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var canUserRedactOtherUserIDCalled: Bool {
        return canUserRedactOtherUserIDCallsCount > 0
    }
    var canUserRedactOtherUserIDReceivedUserID: String?
    var canUserRedactOtherUserIDReceivedInvocations: [String] = []

    var canUserRedactOtherUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserRedactOtherUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return canUserRedactOtherUserIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserRedactOtherUserIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserRedactOtherUserIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserRedactOtherUserIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var canUserRedactOtherUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserRedactOther(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserRedactOtherUserIDCallsCount += 1
        canUserRedactOtherUserIDReceivedUserID = userID
        DispatchQueue.main.async {
            self.canUserRedactOtherUserIDReceivedInvocations.append(userID)
        }
        if let canUserRedactOtherUserIDClosure = canUserRedactOtherUserIDClosure {
            return await canUserRedactOtherUserIDClosure(userID)
        } else {
            return canUserRedactOtherUserIDReturnValue
        }
    }
    //MARK: - canUserRedactOwn

    var canUserRedactOwnUserIDUnderlyingCallsCount = 0
    var canUserRedactOwnUserIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserRedactOwnUserIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserRedactOwnUserIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserRedactOwnUserIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserRedactOwnUserIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var canUserRedactOwnUserIDCalled: Bool {
        return canUserRedactOwnUserIDCallsCount > 0
    }
    var canUserRedactOwnUserIDReceivedUserID: String?
    var canUserRedactOwnUserIDReceivedInvocations: [String] = []

    var canUserRedactOwnUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserRedactOwnUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return canUserRedactOwnUserIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserRedactOwnUserIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserRedactOwnUserIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserRedactOwnUserIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var canUserRedactOwnUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserRedactOwn(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserRedactOwnUserIDCallsCount += 1
        canUserRedactOwnUserIDReceivedUserID = userID
        DispatchQueue.main.async {
            self.canUserRedactOwnUserIDReceivedInvocations.append(userID)
        }
        if let canUserRedactOwnUserIDClosure = canUserRedactOwnUserIDClosure {
            return await canUserRedactOwnUserIDClosure(userID)
        } else {
            return canUserRedactOwnUserIDReturnValue
        }
    }
    //MARK: - canUserKick

    var canUserKickUserIDUnderlyingCallsCount = 0
    var canUserKickUserIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserKickUserIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserKickUserIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserKickUserIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserKickUserIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var canUserKickUserIDCalled: Bool {
        return canUserKickUserIDCallsCount > 0
    }
    var canUserKickUserIDReceivedUserID: String?
    var canUserKickUserIDReceivedInvocations: [String] = []

    var canUserKickUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserKickUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return canUserKickUserIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserKickUserIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserKickUserIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserKickUserIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var canUserKickUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserKick(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserKickUserIDCallsCount += 1
        canUserKickUserIDReceivedUserID = userID
        DispatchQueue.main.async {
            self.canUserKickUserIDReceivedInvocations.append(userID)
        }
        if let canUserKickUserIDClosure = canUserKickUserIDClosure {
            return await canUserKickUserIDClosure(userID)
        } else {
            return canUserKickUserIDReturnValue
        }
    }
    //MARK: - canUserBan

    var canUserBanUserIDUnderlyingCallsCount = 0
    var canUserBanUserIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserBanUserIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserBanUserIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserBanUserIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserBanUserIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var canUserBanUserIDCalled: Bool {
        return canUserBanUserIDCallsCount > 0
    }
    var canUserBanUserIDReceivedUserID: String?
    var canUserBanUserIDReceivedInvocations: [String] = []

    var canUserBanUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserBanUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return canUserBanUserIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserBanUserIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserBanUserIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserBanUserIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var canUserBanUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserBan(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserBanUserIDCallsCount += 1
        canUserBanUserIDReceivedUserID = userID
        DispatchQueue.main.async {
            self.canUserBanUserIDReceivedInvocations.append(userID)
        }
        if let canUserBanUserIDClosure = canUserBanUserIDClosure {
            return await canUserBanUserIDClosure(userID)
        } else {
            return canUserBanUserIDReturnValue
        }
    }
    //MARK: - canUserTriggerRoomNotification

    var canUserTriggerRoomNotificationUserIDUnderlyingCallsCount = 0
    var canUserTriggerRoomNotificationUserIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserTriggerRoomNotificationUserIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserTriggerRoomNotificationUserIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserTriggerRoomNotificationUserIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserTriggerRoomNotificationUserIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var canUserTriggerRoomNotificationUserIDCalled: Bool {
        return canUserTriggerRoomNotificationUserIDCallsCount > 0
    }
    var canUserTriggerRoomNotificationUserIDReceivedUserID: String?
    var canUserTriggerRoomNotificationUserIDReceivedInvocations: [String] = []

    var canUserTriggerRoomNotificationUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserTriggerRoomNotificationUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return canUserTriggerRoomNotificationUserIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserTriggerRoomNotificationUserIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserTriggerRoomNotificationUserIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserTriggerRoomNotificationUserIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var canUserTriggerRoomNotificationUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserTriggerRoomNotification(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserTriggerRoomNotificationUserIDCallsCount += 1
        canUserTriggerRoomNotificationUserIDReceivedUserID = userID
        DispatchQueue.main.async {
            self.canUserTriggerRoomNotificationUserIDReceivedInvocations.append(userID)
        }
        if let canUserTriggerRoomNotificationUserIDClosure = canUserTriggerRoomNotificationUserIDClosure {
            return await canUserTriggerRoomNotificationUserIDClosure(userID)
        } else {
            return canUserTriggerRoomNotificationUserIDReturnValue
        }
    }
    //MARK: - canUserPinOrUnpin

    var canUserPinOrUnpinUserIDUnderlyingCallsCount = 0
    var canUserPinOrUnpinUserIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserPinOrUnpinUserIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserPinOrUnpinUserIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserPinOrUnpinUserIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserPinOrUnpinUserIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var canUserPinOrUnpinUserIDCalled: Bool {
        return canUserPinOrUnpinUserIDCallsCount > 0
    }
    var canUserPinOrUnpinUserIDReceivedUserID: String?
    var canUserPinOrUnpinUserIDReceivedInvocations: [String] = []

    var canUserPinOrUnpinUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserPinOrUnpinUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return canUserPinOrUnpinUserIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserPinOrUnpinUserIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserPinOrUnpinUserIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserPinOrUnpinUserIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var canUserPinOrUnpinUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserPinOrUnpin(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserPinOrUnpinUserIDCallsCount += 1
        canUserPinOrUnpinUserIDReceivedUserID = userID
        DispatchQueue.main.async {
            self.canUserPinOrUnpinUserIDReceivedInvocations.append(userID)
        }
        if let canUserPinOrUnpinUserIDClosure = canUserPinOrUnpinUserIDClosure {
            return await canUserPinOrUnpinUserIDClosure(userID)
        } else {
            return canUserPinOrUnpinUserIDReturnValue
        }
    }
    //MARK: - kickUser

    var kickUserUnderlyingCallsCount = 0
    var kickUserCallsCount: Int {
        get {
            if Thread.isMainThread {
                return kickUserUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = kickUserUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                kickUserUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    kickUserUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var kickUserCalled: Bool {
        return kickUserCallsCount > 0
    }
    var kickUserReceivedUserID: String?
    var kickUserReceivedInvocations: [String] = []

    var kickUserUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var kickUserReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return kickUserUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = kickUserUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                kickUserUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    kickUserUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var kickUserClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func kickUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        kickUserCallsCount += 1
        kickUserReceivedUserID = userID
        DispatchQueue.main.async {
            self.kickUserReceivedInvocations.append(userID)
        }
        if let kickUserClosure = kickUserClosure {
            return await kickUserClosure(userID)
        } else {
            return kickUserReturnValue
        }
    }
    //MARK: - banUser

    var banUserUnderlyingCallsCount = 0
    var banUserCallsCount: Int {
        get {
            if Thread.isMainThread {
                return banUserUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = banUserUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                banUserUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    banUserUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var banUserCalled: Bool {
        return banUserCallsCount > 0
    }
    var banUserReceivedUserID: String?
    var banUserReceivedInvocations: [String] = []

    var banUserUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var banUserReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return banUserUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = banUserUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                banUserUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    banUserUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var banUserClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func banUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        banUserCallsCount += 1
        banUserReceivedUserID = userID
        DispatchQueue.main.async {
            self.banUserReceivedInvocations.append(userID)
        }
        if let banUserClosure = banUserClosure {
            return await banUserClosure(userID)
        } else {
            return banUserReturnValue
        }
    }
    //MARK: - unbanUser

    var unbanUserUnderlyingCallsCount = 0
    var unbanUserCallsCount: Int {
        get {
            if Thread.isMainThread {
                return unbanUserUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = unbanUserUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unbanUserUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    unbanUserUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var unbanUserCalled: Bool {
        return unbanUserCallsCount > 0
    }
    var unbanUserReceivedUserID: String?
    var unbanUserReceivedInvocations: [String] = []

    var unbanUserUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var unbanUserReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return unbanUserUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = unbanUserUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unbanUserUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    unbanUserUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var unbanUserClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func unbanUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        unbanUserCallsCount += 1
        unbanUserReceivedUserID = userID
        DispatchQueue.main.async {
            self.unbanUserReceivedInvocations.append(userID)
        }
        if let unbanUserClosure = unbanUserClosure {
            return await unbanUserClosure(userID)
        } else {
            return unbanUserReturnValue
        }
    }
    //MARK: - canUserJoinCall

    var canUserJoinCallUserIDUnderlyingCallsCount = 0
    var canUserJoinCallUserIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserJoinCallUserIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserJoinCallUserIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserJoinCallUserIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserJoinCallUserIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var canUserJoinCallUserIDCalled: Bool {
        return canUserJoinCallUserIDCallsCount > 0
    }
    var canUserJoinCallUserIDReceivedUserID: String?
    var canUserJoinCallUserIDReceivedInvocations: [String] = []

    var canUserJoinCallUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserJoinCallUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return canUserJoinCallUserIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserJoinCallUserIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserJoinCallUserIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserJoinCallUserIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var canUserJoinCallUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserJoinCall(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserJoinCallUserIDCallsCount += 1
        canUserJoinCallUserIDReceivedUserID = userID
        DispatchQueue.main.async {
            self.canUserJoinCallUserIDReceivedInvocations.append(userID)
        }
        if let canUserJoinCallUserIDClosure = canUserJoinCallUserIDClosure {
            return await canUserJoinCallUserIDClosure(userID)
        } else {
            return canUserJoinCallUserIDReturnValue
        }
    }
    //MARK: - elementCallWidgetDriver

    var elementCallWidgetDriverDeviceIDUnderlyingCallsCount = 0
    var elementCallWidgetDriverDeviceIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return elementCallWidgetDriverDeviceIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = elementCallWidgetDriverDeviceIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                elementCallWidgetDriverDeviceIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    elementCallWidgetDriverDeviceIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var elementCallWidgetDriverDeviceIDCalled: Bool {
        return elementCallWidgetDriverDeviceIDCallsCount > 0
    }
    var elementCallWidgetDriverDeviceIDReceivedDeviceID: String?
    var elementCallWidgetDriverDeviceIDReceivedInvocations: [String] = []

    var elementCallWidgetDriverDeviceIDUnderlyingReturnValue: ElementCallWidgetDriverProtocol!
    var elementCallWidgetDriverDeviceIDReturnValue: ElementCallWidgetDriverProtocol! {
        get {
            if Thread.isMainThread {
                return elementCallWidgetDriverDeviceIDUnderlyingReturnValue
            } else {
                var returnValue: ElementCallWidgetDriverProtocol? = nil
                DispatchQueue.main.sync {
                    returnValue = elementCallWidgetDriverDeviceIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                elementCallWidgetDriverDeviceIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    elementCallWidgetDriverDeviceIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var elementCallWidgetDriverDeviceIDClosure: ((String) -> ElementCallWidgetDriverProtocol)?

    func elementCallWidgetDriver(deviceID: String) -> ElementCallWidgetDriverProtocol {
        elementCallWidgetDriverDeviceIDCallsCount += 1
        elementCallWidgetDriverDeviceIDReceivedDeviceID = deviceID
        DispatchQueue.main.async {
            self.elementCallWidgetDriverDeviceIDReceivedInvocations.append(deviceID)
        }
        if let elementCallWidgetDriverDeviceIDClosure = elementCallWidgetDriverDeviceIDClosure {
            return elementCallWidgetDriverDeviceIDClosure(deviceID)
        } else {
            return elementCallWidgetDriverDeviceIDReturnValue
        }
    }
    //MARK: - sendCallNotificationIfNeeded

    var sendCallNotificationIfNeededUnderlyingCallsCount = 0
    var sendCallNotificationIfNeededCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendCallNotificationIfNeededUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendCallNotificationIfNeededUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendCallNotificationIfNeededUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendCallNotificationIfNeededUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendCallNotificationIfNeededCalled: Bool {
        return sendCallNotificationIfNeededCallsCount > 0
    }

    var sendCallNotificationIfNeededUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var sendCallNotificationIfNeededReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return sendCallNotificationIfNeededUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendCallNotificationIfNeededUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendCallNotificationIfNeededUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendCallNotificationIfNeededUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendCallNotificationIfNeededClosure: (() async -> Result<Void, RoomProxyError>)?

    func sendCallNotificationIfNeeded() async -> Result<Void, RoomProxyError> {
        sendCallNotificationIfNeededCallsCount += 1
        if let sendCallNotificationIfNeededClosure = sendCallNotificationIfNeededClosure {
            return await sendCallNotificationIfNeededClosure()
        } else {
            return sendCallNotificationIfNeededReturnValue
        }
    }
    //MARK: - matrixToPermalink

    var matrixToPermalinkUnderlyingCallsCount = 0
    var matrixToPermalinkCallsCount: Int {
        get {
            if Thread.isMainThread {
                return matrixToPermalinkUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = matrixToPermalinkUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                matrixToPermalinkUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    matrixToPermalinkUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var matrixToPermalinkCalled: Bool {
        return matrixToPermalinkCallsCount > 0
    }

    var matrixToPermalinkUnderlyingReturnValue: Result<URL, RoomProxyError>!
    var matrixToPermalinkReturnValue: Result<URL, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return matrixToPermalinkUnderlyingReturnValue
            } else {
                var returnValue: Result<URL, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = matrixToPermalinkUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                matrixToPermalinkUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    matrixToPermalinkUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var matrixToPermalinkClosure: (() async -> Result<URL, RoomProxyError>)?

    func matrixToPermalink() async -> Result<URL, RoomProxyError> {
        matrixToPermalinkCallsCount += 1
        if let matrixToPermalinkClosure = matrixToPermalinkClosure {
            return await matrixToPermalinkClosure()
        } else {
            return matrixToPermalinkReturnValue
        }
    }
    //MARK: - matrixToEventPermalink

    var matrixToEventPermalinkUnderlyingCallsCount = 0
    var matrixToEventPermalinkCallsCount: Int {
        get {
            if Thread.isMainThread {
                return matrixToEventPermalinkUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = matrixToEventPermalinkUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                matrixToEventPermalinkUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    matrixToEventPermalinkUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var matrixToEventPermalinkCalled: Bool {
        return matrixToEventPermalinkCallsCount > 0
    }
    var matrixToEventPermalinkReceivedEventID: String?
    var matrixToEventPermalinkReceivedInvocations: [String] = []

    var matrixToEventPermalinkUnderlyingReturnValue: Result<URL, RoomProxyError>!
    var matrixToEventPermalinkReturnValue: Result<URL, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return matrixToEventPermalinkUnderlyingReturnValue
            } else {
                var returnValue: Result<URL, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = matrixToEventPermalinkUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                matrixToEventPermalinkUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    matrixToEventPermalinkUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var matrixToEventPermalinkClosure: ((String) async -> Result<URL, RoomProxyError>)?

    func matrixToEventPermalink(_ eventID: String) async -> Result<URL, RoomProxyError> {
        matrixToEventPermalinkCallsCount += 1
        matrixToEventPermalinkReceivedEventID = eventID
        DispatchQueue.main.async {
            self.matrixToEventPermalinkReceivedInvocations.append(eventID)
        }
        if let matrixToEventPermalinkClosure = matrixToEventPermalinkClosure {
            return await matrixToEventPermalinkClosure(eventID)
        } else {
            return matrixToEventPermalinkReturnValue
        }
    }
    //MARK: - saveDraft

    var saveDraftUnderlyingCallsCount = 0
    var saveDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return saveDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = saveDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                saveDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    saveDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var saveDraftCalled: Bool {
        return saveDraftCallsCount > 0
    }
    var saveDraftReceivedDraft: ComposerDraft?
    var saveDraftReceivedInvocations: [ComposerDraft] = []

    var saveDraftUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var saveDraftReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return saveDraftUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = saveDraftUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                saveDraftUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    saveDraftUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var saveDraftClosure: ((ComposerDraft) async -> Result<Void, RoomProxyError>)?

    func saveDraft(_ draft: ComposerDraft) async -> Result<Void, RoomProxyError> {
        saveDraftCallsCount += 1
        saveDraftReceivedDraft = draft
        DispatchQueue.main.async {
            self.saveDraftReceivedInvocations.append(draft)
        }
        if let saveDraftClosure = saveDraftClosure {
            return await saveDraftClosure(draft)
        } else {
            return saveDraftReturnValue
        }
    }
    //MARK: - loadDraft

    var loadDraftUnderlyingCallsCount = 0
    var loadDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadDraftCalled: Bool {
        return loadDraftCallsCount > 0
    }

    var loadDraftUnderlyingReturnValue: Result<ComposerDraft?, RoomProxyError>!
    var loadDraftReturnValue: Result<ComposerDraft?, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return loadDraftUnderlyingReturnValue
            } else {
                var returnValue: Result<ComposerDraft?, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = loadDraftUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadDraftUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadDraftUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadDraftClosure: (() async -> Result<ComposerDraft?, RoomProxyError>)?

    func loadDraft() async -> Result<ComposerDraft?, RoomProxyError> {
        loadDraftCallsCount += 1
        if let loadDraftClosure = loadDraftClosure {
            return await loadDraftClosure()
        } else {
            return loadDraftReturnValue
        }
    }
    //MARK: - clearDraft

    var clearDraftUnderlyingCallsCount = 0
    var clearDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return clearDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = clearDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                clearDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    clearDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var clearDraftCalled: Bool {
        return clearDraftCallsCount > 0
    }

    var clearDraftUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var clearDraftReturnValue: Result<Void, RoomProxyError>! {
        get {
            if Thread.isMainThread {
                return clearDraftUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = clearDraftUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                clearDraftUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    clearDraftUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var clearDraftClosure: (() async -> Result<Void, RoomProxyError>)?

    func clearDraft() async -> Result<Void, RoomProxyError> {
        clearDraftCallsCount += 1
        if let clearDraftClosure = clearDraftClosure {
            return await clearDraftClosure()
        } else {
            return clearDraftReturnValue
        }
    }
}
class KeychainControllerMock: KeychainControllerProtocol {

    //MARK: - setRestorationToken

    var setRestorationTokenForUsernameUnderlyingCallsCount = 0
    var setRestorationTokenForUsernameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setRestorationTokenForUsernameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setRestorationTokenForUsernameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setRestorationTokenForUsernameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setRestorationTokenForUsernameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setRestorationTokenForUsernameCalled: Bool {
        return setRestorationTokenForUsernameCallsCount > 0
    }
    var setRestorationTokenForUsernameReceivedArguments: (restorationToken: RestorationToken, forUsername: String)?
    var setRestorationTokenForUsernameReceivedInvocations: [(restorationToken: RestorationToken, forUsername: String)] = []
    var setRestorationTokenForUsernameClosure: ((RestorationToken, String) -> Void)?

    func setRestorationToken(_ restorationToken: RestorationToken, forUsername: String) {
        setRestorationTokenForUsernameCallsCount += 1
        setRestorationTokenForUsernameReceivedArguments = (restorationToken: restorationToken, forUsername: forUsername)
        DispatchQueue.main.async {
            self.setRestorationTokenForUsernameReceivedInvocations.append((restorationToken: restorationToken, forUsername: forUsername))
        }
        setRestorationTokenForUsernameClosure?(restorationToken, forUsername)
    }
    //MARK: - restorationTokens

    var restorationTokensUnderlyingCallsCount = 0
    var restorationTokensCallsCount: Int {
        get {
            if Thread.isMainThread {
                return restorationTokensUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = restorationTokensUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                restorationTokensUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    restorationTokensUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var restorationTokensCalled: Bool {
        return restorationTokensCallsCount > 0
    }

    var restorationTokensUnderlyingReturnValue: [KeychainCredentials]!
    var restorationTokensReturnValue: [KeychainCredentials]! {
        get {
            if Thread.isMainThread {
                return restorationTokensUnderlyingReturnValue
            } else {
                var returnValue: [KeychainCredentials]? = nil
                DispatchQueue.main.sync {
                    returnValue = restorationTokensUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                restorationTokensUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    restorationTokensUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var restorationTokensClosure: (() -> [KeychainCredentials])?

    func restorationTokens() -> [KeychainCredentials] {
        restorationTokensCallsCount += 1
        if let restorationTokensClosure = restorationTokensClosure {
            return restorationTokensClosure()
        } else {
            return restorationTokensReturnValue
        }
    }
    //MARK: - removeRestorationTokenForUsername

    var removeRestorationTokenForUsernameUnderlyingCallsCount = 0
    var removeRestorationTokenForUsernameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return removeRestorationTokenForUsernameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = removeRestorationTokenForUsernameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removeRestorationTokenForUsernameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    removeRestorationTokenForUsernameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var removeRestorationTokenForUsernameCalled: Bool {
        return removeRestorationTokenForUsernameCallsCount > 0
    }
    var removeRestorationTokenForUsernameReceivedUsername: String?
    var removeRestorationTokenForUsernameReceivedInvocations: [String] = []
    var removeRestorationTokenForUsernameClosure: ((String) -> Void)?

    func removeRestorationTokenForUsername(_ username: String) {
        removeRestorationTokenForUsernameCallsCount += 1
        removeRestorationTokenForUsernameReceivedUsername = username
        DispatchQueue.main.async {
            self.removeRestorationTokenForUsernameReceivedInvocations.append(username)
        }
        removeRestorationTokenForUsernameClosure?(username)
    }
    //MARK: - removeAllRestorationTokens

    var removeAllRestorationTokensUnderlyingCallsCount = 0
    var removeAllRestorationTokensCallsCount: Int {
        get {
            if Thread.isMainThread {
                return removeAllRestorationTokensUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = removeAllRestorationTokensUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removeAllRestorationTokensUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    removeAllRestorationTokensUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var removeAllRestorationTokensCalled: Bool {
        return removeAllRestorationTokensCallsCount > 0
    }
    var removeAllRestorationTokensClosure: (() -> Void)?

    func removeAllRestorationTokens() {
        removeAllRestorationTokensCallsCount += 1
        removeAllRestorationTokensClosure?()
    }
    //MARK: - containsPINCode

    var containsPINCodeThrowableError: Error?
    var containsPINCodeUnderlyingCallsCount = 0
    var containsPINCodeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return containsPINCodeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = containsPINCodeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                containsPINCodeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    containsPINCodeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var containsPINCodeCalled: Bool {
        return containsPINCodeCallsCount > 0
    }

    var containsPINCodeUnderlyingReturnValue: Bool!
    var containsPINCodeReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return containsPINCodeUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = containsPINCodeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                containsPINCodeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    containsPINCodeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var containsPINCodeClosure: (() throws -> Bool)?

    func containsPINCode() throws -> Bool {
        if let error = containsPINCodeThrowableError {
            throw error
        }
        containsPINCodeCallsCount += 1
        if let containsPINCodeClosure = containsPINCodeClosure {
            return try containsPINCodeClosure()
        } else {
            return containsPINCodeReturnValue
        }
    }
    //MARK: - setPINCode

    var setPINCodeThrowableError: Error?
    var setPINCodeUnderlyingCallsCount = 0
    var setPINCodeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setPINCodeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setPINCodeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setPINCodeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setPINCodeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setPINCodeCalled: Bool {
        return setPINCodeCallsCount > 0
    }
    var setPINCodeReceivedPinCode: String?
    var setPINCodeReceivedInvocations: [String] = []
    var setPINCodeClosure: ((String) throws -> Void)?

    func setPINCode(_ pinCode: String) throws {
        if let error = setPINCodeThrowableError {
            throw error
        }
        setPINCodeCallsCount += 1
        setPINCodeReceivedPinCode = pinCode
        DispatchQueue.main.async {
            self.setPINCodeReceivedInvocations.append(pinCode)
        }
        try setPINCodeClosure?(pinCode)
    }
    //MARK: - pinCode

    var pinCodeUnderlyingCallsCount = 0
    var pinCodeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return pinCodeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = pinCodeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pinCodeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    pinCodeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var pinCodeCalled: Bool {
        return pinCodeCallsCount > 0
    }

    var pinCodeUnderlyingReturnValue: String?
    var pinCodeReturnValue: String? {
        get {
            if Thread.isMainThread {
                return pinCodeUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = pinCodeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pinCodeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    pinCodeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var pinCodeClosure: (() -> String?)?

    func pinCode() -> String? {
        pinCodeCallsCount += 1
        if let pinCodeClosure = pinCodeClosure {
            return pinCodeClosure()
        } else {
            return pinCodeReturnValue
        }
    }
    //MARK: - removePINCode

    var removePINCodeUnderlyingCallsCount = 0
    var removePINCodeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return removePINCodeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = removePINCodeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removePINCodeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    removePINCodeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var removePINCodeCalled: Bool {
        return removePINCodeCallsCount > 0
    }
    var removePINCodeClosure: (() -> Void)?

    func removePINCode() {
        removePINCodeCallsCount += 1
        removePINCodeClosure?()
    }
    //MARK: - containsPINCodeBiometricState

    var containsPINCodeBiometricStateUnderlyingCallsCount = 0
    var containsPINCodeBiometricStateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return containsPINCodeBiometricStateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = containsPINCodeBiometricStateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                containsPINCodeBiometricStateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    containsPINCodeBiometricStateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var containsPINCodeBiometricStateCalled: Bool {
        return containsPINCodeBiometricStateCallsCount > 0
    }

    var containsPINCodeBiometricStateUnderlyingReturnValue: Bool!
    var containsPINCodeBiometricStateReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return containsPINCodeBiometricStateUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = containsPINCodeBiometricStateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                containsPINCodeBiometricStateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    containsPINCodeBiometricStateUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var containsPINCodeBiometricStateClosure: (() -> Bool)?

    func containsPINCodeBiometricState() -> Bool {
        containsPINCodeBiometricStateCallsCount += 1
        if let containsPINCodeBiometricStateClosure = containsPINCodeBiometricStateClosure {
            return containsPINCodeBiometricStateClosure()
        } else {
            return containsPINCodeBiometricStateReturnValue
        }
    }
    //MARK: - setPINCodeBiometricState

    var setPINCodeBiometricStateThrowableError: Error?
    var setPINCodeBiometricStateUnderlyingCallsCount = 0
    var setPINCodeBiometricStateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setPINCodeBiometricStateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setPINCodeBiometricStateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setPINCodeBiometricStateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setPINCodeBiometricStateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setPINCodeBiometricStateCalled: Bool {
        return setPINCodeBiometricStateCallsCount > 0
    }
    var setPINCodeBiometricStateReceivedState: Data?
    var setPINCodeBiometricStateReceivedInvocations: [Data] = []
    var setPINCodeBiometricStateClosure: ((Data) throws -> Void)?

    func setPINCodeBiometricState(_ state: Data) throws {
        if let error = setPINCodeBiometricStateThrowableError {
            throw error
        }
        setPINCodeBiometricStateCallsCount += 1
        setPINCodeBiometricStateReceivedState = state
        DispatchQueue.main.async {
            self.setPINCodeBiometricStateReceivedInvocations.append(state)
        }
        try setPINCodeBiometricStateClosure?(state)
    }
    //MARK: - pinCodeBiometricState

    var pinCodeBiometricStateUnderlyingCallsCount = 0
    var pinCodeBiometricStateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return pinCodeBiometricStateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = pinCodeBiometricStateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pinCodeBiometricStateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    pinCodeBiometricStateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var pinCodeBiometricStateCalled: Bool {
        return pinCodeBiometricStateCallsCount > 0
    }

    var pinCodeBiometricStateUnderlyingReturnValue: Data?
    var pinCodeBiometricStateReturnValue: Data? {
        get {
            if Thread.isMainThread {
                return pinCodeBiometricStateUnderlyingReturnValue
            } else {
                var returnValue: Data?? = nil
                DispatchQueue.main.sync {
                    returnValue = pinCodeBiometricStateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pinCodeBiometricStateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    pinCodeBiometricStateUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var pinCodeBiometricStateClosure: (() -> Data?)?

    func pinCodeBiometricState() -> Data? {
        pinCodeBiometricStateCallsCount += 1
        if let pinCodeBiometricStateClosure = pinCodeBiometricStateClosure {
            return pinCodeBiometricStateClosure()
        } else {
            return pinCodeBiometricStateReturnValue
        }
    }
    //MARK: - removePINCodeBiometricState

    var removePINCodeBiometricStateUnderlyingCallsCount = 0
    var removePINCodeBiometricStateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return removePINCodeBiometricStateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = removePINCodeBiometricStateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removePINCodeBiometricStateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    removePINCodeBiometricStateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var removePINCodeBiometricStateCalled: Bool {
        return removePINCodeBiometricStateCallsCount > 0
    }
    var removePINCodeBiometricStateClosure: (() -> Void)?

    func removePINCodeBiometricState() {
        removePINCodeBiometricStateCallsCount += 1
        removePINCodeBiometricStateClosure?()
    }
}
class MediaLoaderMock: MediaLoaderProtocol {

    //MARK: - loadMediaContentForSource

    var loadMediaContentForSourceThrowableError: Error?
    var loadMediaContentForSourceUnderlyingCallsCount = 0
    var loadMediaContentForSourceCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadMediaContentForSourceUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaContentForSourceUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaContentForSourceUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaContentForSourceUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadMediaContentForSourceCalled: Bool {
        return loadMediaContentForSourceCallsCount > 0
    }
    var loadMediaContentForSourceReceivedSource: MediaSourceProxy?
    var loadMediaContentForSourceReceivedInvocations: [MediaSourceProxy] = []

    var loadMediaContentForSourceUnderlyingReturnValue: Data!
    var loadMediaContentForSourceReturnValue: Data! {
        get {
            if Thread.isMainThread {
                return loadMediaContentForSourceUnderlyingReturnValue
            } else {
                var returnValue: Data? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaContentForSourceUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaContentForSourceUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaContentForSourceUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadMediaContentForSourceClosure: ((MediaSourceProxy) async throws -> Data)?

    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        if let error = loadMediaContentForSourceThrowableError {
            throw error
        }
        loadMediaContentForSourceCallsCount += 1
        loadMediaContentForSourceReceivedSource = source
        DispatchQueue.main.async {
            self.loadMediaContentForSourceReceivedInvocations.append(source)
        }
        if let loadMediaContentForSourceClosure = loadMediaContentForSourceClosure {
            return try await loadMediaContentForSourceClosure(source)
        } else {
            return loadMediaContentForSourceReturnValue
        }
    }
    //MARK: - loadMediaThumbnailForSource

    var loadMediaThumbnailForSourceWidthHeightThrowableError: Error?
    var loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount = 0
    var loadMediaThumbnailForSourceWidthHeightCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadMediaThumbnailForSourceWidthHeightCalled: Bool {
        return loadMediaThumbnailForSourceWidthHeightCallsCount > 0
    }
    var loadMediaThumbnailForSourceWidthHeightReceivedArguments: (source: MediaSourceProxy, width: UInt, height: UInt)?
    var loadMediaThumbnailForSourceWidthHeightReceivedInvocations: [(source: MediaSourceProxy, width: UInt, height: UInt)] = []

    var loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue: Data!
    var loadMediaThumbnailForSourceWidthHeightReturnValue: Data! {
        get {
            if Thread.isMainThread {
                return loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue
            } else {
                var returnValue: Data? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadMediaThumbnailForSourceWidthHeightClosure: ((MediaSourceProxy, UInt, UInt) async throws -> Data)?

    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        if let error = loadMediaThumbnailForSourceWidthHeightThrowableError {
            throw error
        }
        loadMediaThumbnailForSourceWidthHeightCallsCount += 1
        loadMediaThumbnailForSourceWidthHeightReceivedArguments = (source: source, width: width, height: height)
        DispatchQueue.main.async {
            self.loadMediaThumbnailForSourceWidthHeightReceivedInvocations.append((source: source, width: width, height: height))
        }
        if let loadMediaThumbnailForSourceWidthHeightClosure = loadMediaThumbnailForSourceWidthHeightClosure {
            return try await loadMediaThumbnailForSourceWidthHeightClosure(source, width, height)
        } else {
            return loadMediaThumbnailForSourceWidthHeightReturnValue
        }
    }
    //MARK: - loadMediaFileForSource

    var loadMediaFileForSourceBodyThrowableError: Error?
    var loadMediaFileForSourceBodyUnderlyingCallsCount = 0
    var loadMediaFileForSourceBodyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadMediaFileForSourceBodyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaFileForSourceBodyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaFileForSourceBodyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaFileForSourceBodyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadMediaFileForSourceBodyCalled: Bool {
        return loadMediaFileForSourceBodyCallsCount > 0
    }
    var loadMediaFileForSourceBodyReceivedArguments: (source: MediaSourceProxy, body: String?)?
    var loadMediaFileForSourceBodyReceivedInvocations: [(source: MediaSourceProxy, body: String?)] = []

    var loadMediaFileForSourceBodyUnderlyingReturnValue: MediaFileHandleProxy!
    var loadMediaFileForSourceBodyReturnValue: MediaFileHandleProxy! {
        get {
            if Thread.isMainThread {
                return loadMediaFileForSourceBodyUnderlyingReturnValue
            } else {
                var returnValue: MediaFileHandleProxy? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaFileForSourceBodyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaFileForSourceBodyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaFileForSourceBodyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadMediaFileForSourceBodyClosure: ((MediaSourceProxy, String?) async throws -> MediaFileHandleProxy)?

    func loadMediaFileForSource(_ source: MediaSourceProxy, body: String?) async throws -> MediaFileHandleProxy {
        if let error = loadMediaFileForSourceBodyThrowableError {
            throw error
        }
        loadMediaFileForSourceBodyCallsCount += 1
        loadMediaFileForSourceBodyReceivedArguments = (source: source, body: body)
        DispatchQueue.main.async {
            self.loadMediaFileForSourceBodyReceivedInvocations.append((source: source, body: body))
        }
        if let loadMediaFileForSourceBodyClosure = loadMediaFileForSourceBodyClosure {
            return try await loadMediaFileForSourceBodyClosure(source, body)
        } else {
            return loadMediaFileForSourceBodyReturnValue
        }
    }
}
class MediaPlayerMock: MediaPlayerProtocol {
    var mediaSource: MediaSourceProxy?
    var duration: TimeInterval {
        get { return underlyingDuration }
        set(value) { underlyingDuration = value }
    }
    var underlyingDuration: TimeInterval!
    var currentTime: TimeInterval {
        get { return underlyingCurrentTime }
        set(value) { underlyingCurrentTime = value }
    }
    var underlyingCurrentTime: TimeInterval!
    var url: URL?
    var state: MediaPlayerState {
        get { return underlyingState }
        set(value) { underlyingState = value }
    }
    var underlyingState: MediaPlayerState!

    //MARK: - load

    var loadMediaSourceUsingAutoplayUnderlyingCallsCount = 0
    var loadMediaSourceUsingAutoplayCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadMediaSourceUsingAutoplayUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadMediaSourceUsingAutoplayUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadMediaSourceUsingAutoplayUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadMediaSourceUsingAutoplayUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadMediaSourceUsingAutoplayCalled: Bool {
        return loadMediaSourceUsingAutoplayCallsCount > 0
    }
    var loadMediaSourceUsingAutoplayReceivedArguments: (mediaSource: MediaSourceProxy, url: URL, autoplay: Bool)?
    var loadMediaSourceUsingAutoplayReceivedInvocations: [(mediaSource: MediaSourceProxy, url: URL, autoplay: Bool)] = []
    var loadMediaSourceUsingAutoplayClosure: ((MediaSourceProxy, URL, Bool) -> Void)?

    func load(mediaSource: MediaSourceProxy, using url: URL, autoplay: Bool) {
        loadMediaSourceUsingAutoplayCallsCount += 1
        loadMediaSourceUsingAutoplayReceivedArguments = (mediaSource: mediaSource, url: url, autoplay: autoplay)
        DispatchQueue.main.async {
            self.loadMediaSourceUsingAutoplayReceivedInvocations.append((mediaSource: mediaSource, url: url, autoplay: autoplay))
        }
        loadMediaSourceUsingAutoplayClosure?(mediaSource, url, autoplay)
    }
    //MARK: - reset

    var resetUnderlyingCallsCount = 0
    var resetCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resetUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resetUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resetUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCount += 1
        resetClosure?()
    }
    //MARK: - play

    var playUnderlyingCallsCount = 0
    var playCallsCount: Int {
        get {
            if Thread.isMainThread {
                return playUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = playUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                playUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    playUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var playCalled: Bool {
        return playCallsCount > 0
    }
    var playClosure: (() -> Void)?

    func play() {
        playCallsCount += 1
        playClosure?()
    }
    //MARK: - pause

    var pauseUnderlyingCallsCount = 0
    var pauseCallsCount: Int {
        get {
            if Thread.isMainThread {
                return pauseUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = pauseUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pauseUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    pauseUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var pauseCalled: Bool {
        return pauseCallsCount > 0
    }
    var pauseClosure: (() -> Void)?

    func pause() {
        pauseCallsCount += 1
        pauseClosure?()
    }
    //MARK: - stop

    var stopUnderlyingCallsCount = 0
    var stopCallsCount: Int {
        get {
            if Thread.isMainThread {
                return stopUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = stopUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stopUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    stopUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCount += 1
        stopClosure?()
    }
    //MARK: - seek

    var seekToUnderlyingCallsCount = 0
    var seekToCallsCount: Int {
        get {
            if Thread.isMainThread {
                return seekToUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = seekToUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                seekToUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    seekToUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var seekToCalled: Bool {
        return seekToCallsCount > 0
    }
    var seekToReceivedProgress: Double?
    var seekToReceivedInvocations: [Double] = []
    var seekToClosure: ((Double) async -> Void)?

    func seek(to progress: Double) async {
        seekToCallsCount += 1
        seekToReceivedProgress = progress
        DispatchQueue.main.async {
            self.seekToReceivedInvocations.append(progress)
        }
        await seekToClosure?(progress)
    }
}
class MediaPlayerProviderMock: MediaPlayerProviderProtocol {

    //MARK: - player

    var playerForUnderlyingCallsCount = 0
    var playerForCallsCount: Int {
        get {
            if Thread.isMainThread {
                return playerForUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = playerForUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                playerForUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    playerForUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var playerForCalled: Bool {
        return playerForCallsCount > 0
    }
    var playerForReceivedMediaSource: MediaSourceProxy?
    var playerForReceivedInvocations: [MediaSourceProxy] = []

    var playerForUnderlyingReturnValue: Result<MediaPlayerProtocol, MediaPlayerProviderError>!
    var playerForReturnValue: Result<MediaPlayerProtocol, MediaPlayerProviderError>! {
        get {
            if Thread.isMainThread {
                return playerForUnderlyingReturnValue
            } else {
                var returnValue: Result<MediaPlayerProtocol, MediaPlayerProviderError>? = nil
                DispatchQueue.main.sync {
                    returnValue = playerForUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                playerForUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    playerForUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var playerForClosure: ((MediaSourceProxy) -> Result<MediaPlayerProtocol, MediaPlayerProviderError>)?

    func player(for mediaSource: MediaSourceProxy) -> Result<MediaPlayerProtocol, MediaPlayerProviderError> {
        playerForCallsCount += 1
        playerForReceivedMediaSource = mediaSource
        DispatchQueue.main.async {
            self.playerForReceivedInvocations.append(mediaSource)
        }
        if let playerForClosure = playerForClosure {
            return playerForClosure(mediaSource)
        } else {
            return playerForReturnValue
        }
    }
    //MARK: - playerState

    var playerStateForUnderlyingCallsCount = 0
    var playerStateForCallsCount: Int {
        get {
            if Thread.isMainThread {
                return playerStateForUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = playerStateForUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                playerStateForUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    playerStateForUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var playerStateForCalled: Bool {
        return playerStateForCallsCount > 0
    }
    var playerStateForReceivedId: AudioPlayerStateIdentifier?
    var playerStateForReceivedInvocations: [AudioPlayerStateIdentifier] = []

    var playerStateForUnderlyingReturnValue: AudioPlayerState?
    var playerStateForReturnValue: AudioPlayerState? {
        get {
            if Thread.isMainThread {
                return playerStateForUnderlyingReturnValue
            } else {
                var returnValue: AudioPlayerState?? = nil
                DispatchQueue.main.sync {
                    returnValue = playerStateForUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                playerStateForUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    playerStateForUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var playerStateForClosure: ((AudioPlayerStateIdentifier) -> AudioPlayerState?)?

    func playerState(for id: AudioPlayerStateIdentifier) -> AudioPlayerState? {
        playerStateForCallsCount += 1
        playerStateForReceivedId = id
        DispatchQueue.main.async {
            self.playerStateForReceivedInvocations.append(id)
        }
        if let playerStateForClosure = playerStateForClosure {
            return playerStateForClosure(id)
        } else {
            return playerStateForReturnValue
        }
    }
    //MARK: - register

    var registerAudioPlayerStateUnderlyingCallsCount = 0
    var registerAudioPlayerStateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return registerAudioPlayerStateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = registerAudioPlayerStateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                registerAudioPlayerStateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    registerAudioPlayerStateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var registerAudioPlayerStateCalled: Bool {
        return registerAudioPlayerStateCallsCount > 0
    }
    var registerAudioPlayerStateReceivedAudioPlayerState: AudioPlayerState?
    var registerAudioPlayerStateReceivedInvocations: [AudioPlayerState] = []
    var registerAudioPlayerStateClosure: ((AudioPlayerState) -> Void)?

    func register(audioPlayerState: AudioPlayerState) {
        registerAudioPlayerStateCallsCount += 1
        registerAudioPlayerStateReceivedAudioPlayerState = audioPlayerState
        DispatchQueue.main.async {
            self.registerAudioPlayerStateReceivedInvocations.append(audioPlayerState)
        }
        registerAudioPlayerStateClosure?(audioPlayerState)
    }
    //MARK: - unregister

    var unregisterAudioPlayerStateUnderlyingCallsCount = 0
    var unregisterAudioPlayerStateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return unregisterAudioPlayerStateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = unregisterAudioPlayerStateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unregisterAudioPlayerStateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    unregisterAudioPlayerStateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var unregisterAudioPlayerStateCalled: Bool {
        return unregisterAudioPlayerStateCallsCount > 0
    }
    var unregisterAudioPlayerStateReceivedAudioPlayerState: AudioPlayerState?
    var unregisterAudioPlayerStateReceivedInvocations: [AudioPlayerState] = []
    var unregisterAudioPlayerStateClosure: ((AudioPlayerState) -> Void)?

    func unregister(audioPlayerState: AudioPlayerState) {
        unregisterAudioPlayerStateCallsCount += 1
        unregisterAudioPlayerStateReceivedAudioPlayerState = audioPlayerState
        DispatchQueue.main.async {
            self.unregisterAudioPlayerStateReceivedInvocations.append(audioPlayerState)
        }
        unregisterAudioPlayerStateClosure?(audioPlayerState)
    }
    //MARK: - detachAllStates

    var detachAllStatesExceptUnderlyingCallsCount = 0
    var detachAllStatesExceptCallsCount: Int {
        get {
            if Thread.isMainThread {
                return detachAllStatesExceptUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = detachAllStatesExceptUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                detachAllStatesExceptUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    detachAllStatesExceptUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var detachAllStatesExceptCalled: Bool {
        return detachAllStatesExceptCallsCount > 0
    }
    var detachAllStatesExceptReceivedException: AudioPlayerState?
    var detachAllStatesExceptReceivedInvocations: [AudioPlayerState?] = []
    var detachAllStatesExceptClosure: ((AudioPlayerState?) async -> Void)?

    func detachAllStates(except exception: AudioPlayerState?) async {
        detachAllStatesExceptCallsCount += 1
        detachAllStatesExceptReceivedException = exception
        DispatchQueue.main.async {
            self.detachAllStatesExceptReceivedInvocations.append(exception)
        }
        await detachAllStatesExceptClosure?(exception)
    }
}
class NetworkMonitorMock: NetworkMonitorProtocol {
    var reachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> {
        get { return underlyingReachabilityPublisher }
        set(value) { underlyingReachabilityPublisher = value }
    }
    var underlyingReachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never>!

}
class NotificationManagerMock: NotificationManagerProtocol {
    weak var delegate: NotificationManagerDelegate?

    //MARK: - start

    var startUnderlyingCallsCount = 0
    var startCallsCount: Int {
        get {
            if Thread.isMainThread {
                return startUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = startUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    startUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var startCalled: Bool {
        return startCallsCount > 0
    }
    var startClosure: (() -> Void)?

    func start() {
        startCallsCount += 1
        startClosure?()
    }
    //MARK: - register

    var registerWithUnderlyingCallsCount = 0
    var registerWithCallsCount: Int {
        get {
            if Thread.isMainThread {
                return registerWithUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = registerWithUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                registerWithUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    registerWithUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var registerWithCalled: Bool {
        return registerWithCallsCount > 0
    }
    var registerWithReceivedDeviceToken: Data?
    var registerWithReceivedInvocations: [Data] = []

    var registerWithUnderlyingReturnValue: Bool!
    var registerWithReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return registerWithUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = registerWithUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                registerWithUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    registerWithUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var registerWithClosure: ((Data) async -> Bool)?

    func register(with deviceToken: Data) async -> Bool {
        registerWithCallsCount += 1
        registerWithReceivedDeviceToken = deviceToken
        DispatchQueue.main.async {
            self.registerWithReceivedInvocations.append(deviceToken)
        }
        if let registerWithClosure = registerWithClosure {
            return await registerWithClosure(deviceToken)
        } else {
            return registerWithReturnValue
        }
    }
    //MARK: - registrationFailed

    var registrationFailedWithUnderlyingCallsCount = 0
    var registrationFailedWithCallsCount: Int {
        get {
            if Thread.isMainThread {
                return registrationFailedWithUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = registrationFailedWithUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                registrationFailedWithUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    registrationFailedWithUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var registrationFailedWithCalled: Bool {
        return registrationFailedWithCallsCount > 0
    }
    var registrationFailedWithReceivedError: Error?
    var registrationFailedWithReceivedInvocations: [Error] = []
    var registrationFailedWithClosure: ((Error) -> Void)?

    func registrationFailed(with error: Error) {
        registrationFailedWithCallsCount += 1
        registrationFailedWithReceivedError = error
        DispatchQueue.main.async {
            self.registrationFailedWithReceivedInvocations.append(error)
        }
        registrationFailedWithClosure?(error)
    }
    //MARK: - showLocalNotification

    var showLocalNotificationWithSubtitleUnderlyingCallsCount = 0
    var showLocalNotificationWithSubtitleCallsCount: Int {
        get {
            if Thread.isMainThread {
                return showLocalNotificationWithSubtitleUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = showLocalNotificationWithSubtitleUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                showLocalNotificationWithSubtitleUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    showLocalNotificationWithSubtitleUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var showLocalNotificationWithSubtitleCalled: Bool {
        return showLocalNotificationWithSubtitleCallsCount > 0
    }
    var showLocalNotificationWithSubtitleReceivedArguments: (title: String, subtitle: String?)?
    var showLocalNotificationWithSubtitleReceivedInvocations: [(title: String, subtitle: String?)] = []
    var showLocalNotificationWithSubtitleClosure: ((String, String?) async -> Void)?

    func showLocalNotification(with title: String, subtitle: String?) async {
        showLocalNotificationWithSubtitleCallsCount += 1
        showLocalNotificationWithSubtitleReceivedArguments = (title: title, subtitle: subtitle)
        DispatchQueue.main.async {
            self.showLocalNotificationWithSubtitleReceivedInvocations.append((title: title, subtitle: subtitle))
        }
        await showLocalNotificationWithSubtitleClosure?(title, subtitle)
    }
    //MARK: - setUserSession

    var setUserSessionUnderlyingCallsCount = 0
    var setUserSessionCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setUserSessionUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setUserSessionUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setUserSessionUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setUserSessionUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setUserSessionCalled: Bool {
        return setUserSessionCallsCount > 0
    }
    var setUserSessionReceivedUserSession: UserSessionProtocol?
    var setUserSessionReceivedInvocations: [UserSessionProtocol?] = []
    var setUserSessionClosure: ((UserSessionProtocol?) -> Void)?

    func setUserSession(_ userSession: UserSessionProtocol?) {
        setUserSessionCallsCount += 1
        setUserSessionReceivedUserSession = userSession
        DispatchQueue.main.async {
            self.setUserSessionReceivedInvocations.append(userSession)
        }
        setUserSessionClosure?(userSession)
    }
    //MARK: - requestAuthorization

    var requestAuthorizationUnderlyingCallsCount = 0
    var requestAuthorizationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return requestAuthorizationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = requestAuthorizationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                requestAuthorizationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    requestAuthorizationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var requestAuthorizationCalled: Bool {
        return requestAuthorizationCallsCount > 0
    }
    var requestAuthorizationClosure: (() -> Void)?

    func requestAuthorization() {
        requestAuthorizationCallsCount += 1
        requestAuthorizationClosure?()
    }
    //MARK: - removeDeliveredMessageNotifications

    var removeDeliveredMessageNotificationsForUnderlyingCallsCount = 0
    var removeDeliveredMessageNotificationsForCallsCount: Int {
        get {
            if Thread.isMainThread {
                return removeDeliveredMessageNotificationsForUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = removeDeliveredMessageNotificationsForUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removeDeliveredMessageNotificationsForUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    removeDeliveredMessageNotificationsForUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var removeDeliveredMessageNotificationsForCalled: Bool {
        return removeDeliveredMessageNotificationsForCallsCount > 0
    }
    var removeDeliveredMessageNotificationsForReceivedRoomID: String?
    var removeDeliveredMessageNotificationsForReceivedInvocations: [String] = []
    var removeDeliveredMessageNotificationsForClosure: ((String) async -> Void)?

    func removeDeliveredMessageNotifications(for roomID: String) async {
        removeDeliveredMessageNotificationsForCallsCount += 1
        removeDeliveredMessageNotificationsForReceivedRoomID = roomID
        DispatchQueue.main.async {
            self.removeDeliveredMessageNotificationsForReceivedInvocations.append(roomID)
        }
        await removeDeliveredMessageNotificationsForClosure?(roomID)
    }
    //MARK: - removeDeliveredInviteNotifications

    var removeDeliveredInviteNotificationsUnderlyingCallsCount = 0
    var removeDeliveredInviteNotificationsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return removeDeliveredInviteNotificationsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = removeDeliveredInviteNotificationsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removeDeliveredInviteNotificationsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    removeDeliveredInviteNotificationsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var removeDeliveredInviteNotificationsCalled: Bool {
        return removeDeliveredInviteNotificationsCallsCount > 0
    }
    var removeDeliveredInviteNotificationsClosure: (() async -> Void)?

    func removeDeliveredInviteNotifications() async {
        removeDeliveredInviteNotificationsCallsCount += 1
        await removeDeliveredInviteNotificationsClosure?()
    }
}
class NotificationSettingsProxyMock: NotificationSettingsProxyProtocol {
    var callbacks: PassthroughSubject<NotificationSettingsProxyCallback, Never> {
        get { return underlyingCallbacks }
        set(value) { underlyingCallbacks = value }
    }
    var underlyingCallbacks: PassthroughSubject<NotificationSettingsProxyCallback, Never>!

    //MARK: - getNotificationSettings

    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneThrowableError: Error?
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = 0
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneCalled: Bool {
        return getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCount > 0
    }
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedArguments: (roomId: String, isEncrypted: Bool, isOneToOne: Bool)?
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedInvocations: [(roomId: String, isEncrypted: Bool, isOneToOne: Bool)] = []

    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue: RoomNotificationSettingsProxyProtocol!
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue: RoomNotificationSettingsProxyProtocol! {
        get {
            if Thread.isMainThread {
                return getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue
            } else {
                var returnValue: RoomNotificationSettingsProxyProtocol? = nil
                DispatchQueue.main.sync {
                    returnValue = getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure: ((String, Bool, Bool) async throws -> RoomNotificationSettingsProxyProtocol)?

    func getNotificationSettings(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws -> RoomNotificationSettingsProxyProtocol {
        if let error = getNotificationSettingsRoomIdIsEncryptedIsOneToOneThrowableError {
            throw error
        }
        getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCount += 1
        getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedArguments = (roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        DispatchQueue.main.async {
            self.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedInvocations.append((roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne))
        }
        if let getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure = getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure {
            return try await getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure(roomId, isEncrypted, isOneToOne)
        } else {
            return getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue
        }
    }
    //MARK: - setNotificationMode

    var setNotificationModeRoomIdModeThrowableError: Error?
    var setNotificationModeRoomIdModeUnderlyingCallsCount = 0
    var setNotificationModeRoomIdModeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setNotificationModeRoomIdModeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setNotificationModeRoomIdModeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setNotificationModeRoomIdModeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setNotificationModeRoomIdModeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setNotificationModeRoomIdModeCalled: Bool {
        return setNotificationModeRoomIdModeCallsCount > 0
    }
    var setNotificationModeRoomIdModeReceivedArguments: (roomId: String, mode: RoomNotificationModeProxy)?
    var setNotificationModeRoomIdModeReceivedInvocations: [(roomId: String, mode: RoomNotificationModeProxy)] = []
    var setNotificationModeRoomIdModeClosure: ((String, RoomNotificationModeProxy) async throws -> Void)?

    func setNotificationMode(roomId: String, mode: RoomNotificationModeProxy) async throws {
        if let error = setNotificationModeRoomIdModeThrowableError {
            throw error
        }
        setNotificationModeRoomIdModeCallsCount += 1
        setNotificationModeRoomIdModeReceivedArguments = (roomId: roomId, mode: mode)
        DispatchQueue.main.async {
            self.setNotificationModeRoomIdModeReceivedInvocations.append((roomId: roomId, mode: mode))
        }
        try await setNotificationModeRoomIdModeClosure?(roomId, mode)
    }
    //MARK: - getUserDefinedRoomNotificationMode

    var getUserDefinedRoomNotificationModeRoomIdThrowableError: Error?
    var getUserDefinedRoomNotificationModeRoomIdUnderlyingCallsCount = 0
    var getUserDefinedRoomNotificationModeRoomIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getUserDefinedRoomNotificationModeRoomIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getUserDefinedRoomNotificationModeRoomIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getUserDefinedRoomNotificationModeRoomIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getUserDefinedRoomNotificationModeRoomIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var getUserDefinedRoomNotificationModeRoomIdCalled: Bool {
        return getUserDefinedRoomNotificationModeRoomIdCallsCount > 0
    }
    var getUserDefinedRoomNotificationModeRoomIdReceivedRoomId: String?
    var getUserDefinedRoomNotificationModeRoomIdReceivedInvocations: [String] = []

    var getUserDefinedRoomNotificationModeRoomIdUnderlyingReturnValue: RoomNotificationModeProxy?
    var getUserDefinedRoomNotificationModeRoomIdReturnValue: RoomNotificationModeProxy? {
        get {
            if Thread.isMainThread {
                return getUserDefinedRoomNotificationModeRoomIdUnderlyingReturnValue
            } else {
                var returnValue: RoomNotificationModeProxy?? = nil
                DispatchQueue.main.sync {
                    returnValue = getUserDefinedRoomNotificationModeRoomIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getUserDefinedRoomNotificationModeRoomIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getUserDefinedRoomNotificationModeRoomIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var getUserDefinedRoomNotificationModeRoomIdClosure: ((String) async throws -> RoomNotificationModeProxy?)?

    func getUserDefinedRoomNotificationMode(roomId: String) async throws -> RoomNotificationModeProxy? {
        if let error = getUserDefinedRoomNotificationModeRoomIdThrowableError {
            throw error
        }
        getUserDefinedRoomNotificationModeRoomIdCallsCount += 1
        getUserDefinedRoomNotificationModeRoomIdReceivedRoomId = roomId
        DispatchQueue.main.async {
            self.getUserDefinedRoomNotificationModeRoomIdReceivedInvocations.append(roomId)
        }
        if let getUserDefinedRoomNotificationModeRoomIdClosure = getUserDefinedRoomNotificationModeRoomIdClosure {
            return try await getUserDefinedRoomNotificationModeRoomIdClosure(roomId)
        } else {
            return getUserDefinedRoomNotificationModeRoomIdReturnValue
        }
    }
    //MARK: - getDefaultRoomNotificationMode

    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingCallsCount = 0
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneCalled: Bool {
        return getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount > 0
    }
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedArguments: (isEncrypted: Bool, isOneToOne: Bool)?
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocations: [(isEncrypted: Bool, isOneToOne: Bool)] = []

    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReturnValue: RoomNotificationModeProxy!
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue: RoomNotificationModeProxy! {
        get {
            if Thread.isMainThread {
                return getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReturnValue
            } else {
                var returnValue: RoomNotificationModeProxy? = nil
                DispatchQueue.main.sync {
                    returnValue = getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure: ((Bool, Bool) async -> RoomNotificationModeProxy)?

    func getDefaultRoomNotificationMode(isEncrypted: Bool, isOneToOne: Bool) async -> RoomNotificationModeProxy {
        getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount += 1
        getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedArguments = (isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        DispatchQueue.main.async {
            self.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocations.append((isEncrypted: isEncrypted, isOneToOne: isOneToOne))
        }
        if let getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure {
            return await getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure(isEncrypted, isOneToOne)
        } else {
            return getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue
        }
    }
    //MARK: - setDefaultRoomNotificationMode

    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeThrowableError: Error?
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingCallsCount = 0
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCalled: Bool {
        return setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount > 0
    }
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedArguments: (isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationModeProxy)?
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations: [(isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationModeProxy)] = []
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeClosure: ((Bool, Bool, RoomNotificationModeProxy) async throws -> Void)?

    func setDefaultRoomNotificationMode(isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationModeProxy) async throws {
        if let error = setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeThrowableError {
            throw error
        }
        setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount += 1
        setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedArguments = (isEncrypted: isEncrypted, isOneToOne: isOneToOne, mode: mode)
        DispatchQueue.main.async {
            self.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations.append((isEncrypted: isEncrypted, isOneToOne: isOneToOne, mode: mode))
        }
        try await setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeClosure?(isEncrypted, isOneToOne, mode)
    }
    //MARK: - restoreDefaultNotificationMode

    var restoreDefaultNotificationModeRoomIdThrowableError: Error?
    var restoreDefaultNotificationModeRoomIdUnderlyingCallsCount = 0
    var restoreDefaultNotificationModeRoomIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return restoreDefaultNotificationModeRoomIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = restoreDefaultNotificationModeRoomIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                restoreDefaultNotificationModeRoomIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    restoreDefaultNotificationModeRoomIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var restoreDefaultNotificationModeRoomIdCalled: Bool {
        return restoreDefaultNotificationModeRoomIdCallsCount > 0
    }
    var restoreDefaultNotificationModeRoomIdReceivedRoomId: String?
    var restoreDefaultNotificationModeRoomIdReceivedInvocations: [String] = []
    var restoreDefaultNotificationModeRoomIdClosure: ((String) async throws -> Void)?

    func restoreDefaultNotificationMode(roomId: String) async throws {
        if let error = restoreDefaultNotificationModeRoomIdThrowableError {
            throw error
        }
        restoreDefaultNotificationModeRoomIdCallsCount += 1
        restoreDefaultNotificationModeRoomIdReceivedRoomId = roomId
        DispatchQueue.main.async {
            self.restoreDefaultNotificationModeRoomIdReceivedInvocations.append(roomId)
        }
        try await restoreDefaultNotificationModeRoomIdClosure?(roomId)
    }
    //MARK: - unmuteRoom

    var unmuteRoomRoomIdIsEncryptedIsOneToOneThrowableError: Error?
    var unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = 0
    var unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCount: Int {
        get {
            if Thread.isMainThread {
                return unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var unmuteRoomRoomIdIsEncryptedIsOneToOneCalled: Bool {
        return unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCount > 0
    }
    var unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedArguments: (roomId: String, isEncrypted: Bool, isOneToOne: Bool)?
    var unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedInvocations: [(roomId: String, isEncrypted: Bool, isOneToOne: Bool)] = []
    var unmuteRoomRoomIdIsEncryptedIsOneToOneClosure: ((String, Bool, Bool) async throws -> Void)?

    func unmuteRoom(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws {
        if let error = unmuteRoomRoomIdIsEncryptedIsOneToOneThrowableError {
            throw error
        }
        unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCount += 1
        unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedArguments = (roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        DispatchQueue.main.async {
            self.unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedInvocations.append((roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne))
        }
        try await unmuteRoomRoomIdIsEncryptedIsOneToOneClosure?(roomId, isEncrypted, isOneToOne)
    }
    //MARK: - isRoomMentionEnabled

    var isRoomMentionEnabledThrowableError: Error?
    var isRoomMentionEnabledUnderlyingCallsCount = 0
    var isRoomMentionEnabledCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isRoomMentionEnabledUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isRoomMentionEnabledUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isRoomMentionEnabledUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isRoomMentionEnabledUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var isRoomMentionEnabledCalled: Bool {
        return isRoomMentionEnabledCallsCount > 0
    }

    var isRoomMentionEnabledUnderlyingReturnValue: Bool!
    var isRoomMentionEnabledReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isRoomMentionEnabledUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isRoomMentionEnabledUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isRoomMentionEnabledUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isRoomMentionEnabledUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var isRoomMentionEnabledClosure: (() async throws -> Bool)?

    func isRoomMentionEnabled() async throws -> Bool {
        if let error = isRoomMentionEnabledThrowableError {
            throw error
        }
        isRoomMentionEnabledCallsCount += 1
        if let isRoomMentionEnabledClosure = isRoomMentionEnabledClosure {
            return try await isRoomMentionEnabledClosure()
        } else {
            return isRoomMentionEnabledReturnValue
        }
    }
    //MARK: - setRoomMentionEnabled

    var setRoomMentionEnabledEnabledThrowableError: Error?
    var setRoomMentionEnabledEnabledUnderlyingCallsCount = 0
    var setRoomMentionEnabledEnabledCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setRoomMentionEnabledEnabledUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setRoomMentionEnabledEnabledUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setRoomMentionEnabledEnabledUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setRoomMentionEnabledEnabledUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setRoomMentionEnabledEnabledCalled: Bool {
        return setRoomMentionEnabledEnabledCallsCount > 0
    }
    var setRoomMentionEnabledEnabledReceivedEnabled: Bool?
    var setRoomMentionEnabledEnabledReceivedInvocations: [Bool] = []
    var setRoomMentionEnabledEnabledClosure: ((Bool) async throws -> Void)?

    func setRoomMentionEnabled(enabled: Bool) async throws {
        if let error = setRoomMentionEnabledEnabledThrowableError {
            throw error
        }
        setRoomMentionEnabledEnabledCallsCount += 1
        setRoomMentionEnabledEnabledReceivedEnabled = enabled
        DispatchQueue.main.async {
            self.setRoomMentionEnabledEnabledReceivedInvocations.append(enabled)
        }
        try await setRoomMentionEnabledEnabledClosure?(enabled)
    }
    //MARK: - isCallEnabled

    var isCallEnabledThrowableError: Error?
    var isCallEnabledUnderlyingCallsCount = 0
    var isCallEnabledCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isCallEnabledUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isCallEnabledUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isCallEnabledUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isCallEnabledUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var isCallEnabledCalled: Bool {
        return isCallEnabledCallsCount > 0
    }

    var isCallEnabledUnderlyingReturnValue: Bool!
    var isCallEnabledReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isCallEnabledUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isCallEnabledUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isCallEnabledUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isCallEnabledUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var isCallEnabledClosure: (() async throws -> Bool)?

    func isCallEnabled() async throws -> Bool {
        if let error = isCallEnabledThrowableError {
            throw error
        }
        isCallEnabledCallsCount += 1
        if let isCallEnabledClosure = isCallEnabledClosure {
            return try await isCallEnabledClosure()
        } else {
            return isCallEnabledReturnValue
        }
    }
    //MARK: - setCallEnabled

    var setCallEnabledEnabledThrowableError: Error?
    var setCallEnabledEnabledUnderlyingCallsCount = 0
    var setCallEnabledEnabledCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setCallEnabledEnabledUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setCallEnabledEnabledUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setCallEnabledEnabledUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setCallEnabledEnabledUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setCallEnabledEnabledCalled: Bool {
        return setCallEnabledEnabledCallsCount > 0
    }
    var setCallEnabledEnabledReceivedEnabled: Bool?
    var setCallEnabledEnabledReceivedInvocations: [Bool] = []
    var setCallEnabledEnabledClosure: ((Bool) async throws -> Void)?

    func setCallEnabled(enabled: Bool) async throws {
        if let error = setCallEnabledEnabledThrowableError {
            throw error
        }
        setCallEnabledEnabledCallsCount += 1
        setCallEnabledEnabledReceivedEnabled = enabled
        DispatchQueue.main.async {
            self.setCallEnabledEnabledReceivedInvocations.append(enabled)
        }
        try await setCallEnabledEnabledClosure?(enabled)
    }
    //MARK: - isInviteForMeEnabled

    var isInviteForMeEnabledThrowableError: Error?
    var isInviteForMeEnabledUnderlyingCallsCount = 0
    var isInviteForMeEnabledCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isInviteForMeEnabledUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isInviteForMeEnabledUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isInviteForMeEnabledUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isInviteForMeEnabledUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var isInviteForMeEnabledCalled: Bool {
        return isInviteForMeEnabledCallsCount > 0
    }

    var isInviteForMeEnabledUnderlyingReturnValue: Bool!
    var isInviteForMeEnabledReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isInviteForMeEnabledUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isInviteForMeEnabledUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isInviteForMeEnabledUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isInviteForMeEnabledUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var isInviteForMeEnabledClosure: (() async throws -> Bool)?

    func isInviteForMeEnabled() async throws -> Bool {
        if let error = isInviteForMeEnabledThrowableError {
            throw error
        }
        isInviteForMeEnabledCallsCount += 1
        if let isInviteForMeEnabledClosure = isInviteForMeEnabledClosure {
            return try await isInviteForMeEnabledClosure()
        } else {
            return isInviteForMeEnabledReturnValue
        }
    }
    //MARK: - setInviteForMeEnabled

    var setInviteForMeEnabledEnabledThrowableError: Error?
    var setInviteForMeEnabledEnabledUnderlyingCallsCount = 0
    var setInviteForMeEnabledEnabledCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setInviteForMeEnabledEnabledUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setInviteForMeEnabledEnabledUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setInviteForMeEnabledEnabledUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setInviteForMeEnabledEnabledUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setInviteForMeEnabledEnabledCalled: Bool {
        return setInviteForMeEnabledEnabledCallsCount > 0
    }
    var setInviteForMeEnabledEnabledReceivedEnabled: Bool?
    var setInviteForMeEnabledEnabledReceivedInvocations: [Bool] = []
    var setInviteForMeEnabledEnabledClosure: ((Bool) async throws -> Void)?

    func setInviteForMeEnabled(enabled: Bool) async throws {
        if let error = setInviteForMeEnabledEnabledThrowableError {
            throw error
        }
        setInviteForMeEnabledEnabledCallsCount += 1
        setInviteForMeEnabledEnabledReceivedEnabled = enabled
        DispatchQueue.main.async {
            self.setInviteForMeEnabledEnabledReceivedInvocations.append(enabled)
        }
        try await setInviteForMeEnabledEnabledClosure?(enabled)
    }
    //MARK: - getRoomsWithUserDefinedRules

    var getRoomsWithUserDefinedRulesThrowableError: Error?
    var getRoomsWithUserDefinedRulesUnderlyingCallsCount = 0
    var getRoomsWithUserDefinedRulesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getRoomsWithUserDefinedRulesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomsWithUserDefinedRulesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomsWithUserDefinedRulesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomsWithUserDefinedRulesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var getRoomsWithUserDefinedRulesCalled: Bool {
        return getRoomsWithUserDefinedRulesCallsCount > 0
    }

    var getRoomsWithUserDefinedRulesUnderlyingReturnValue: [String]!
    var getRoomsWithUserDefinedRulesReturnValue: [String]! {
        get {
            if Thread.isMainThread {
                return getRoomsWithUserDefinedRulesUnderlyingReturnValue
            } else {
                var returnValue: [String]? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomsWithUserDefinedRulesUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomsWithUserDefinedRulesUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomsWithUserDefinedRulesUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var getRoomsWithUserDefinedRulesClosure: (() async throws -> [String])?

    func getRoomsWithUserDefinedRules() async throws -> [String] {
        if let error = getRoomsWithUserDefinedRulesThrowableError {
            throw error
        }
        getRoomsWithUserDefinedRulesCallsCount += 1
        if let getRoomsWithUserDefinedRulesClosure = getRoomsWithUserDefinedRulesClosure {
            return try await getRoomsWithUserDefinedRulesClosure()
        } else {
            return getRoomsWithUserDefinedRulesReturnValue
        }
    }
    //MARK: - canPushEncryptedEventsToDevice

    var canPushEncryptedEventsToDeviceUnderlyingCallsCount = 0
    var canPushEncryptedEventsToDeviceCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canPushEncryptedEventsToDeviceUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canPushEncryptedEventsToDeviceUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canPushEncryptedEventsToDeviceUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canPushEncryptedEventsToDeviceUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var canPushEncryptedEventsToDeviceCalled: Bool {
        return canPushEncryptedEventsToDeviceCallsCount > 0
    }

    var canPushEncryptedEventsToDeviceUnderlyingReturnValue: Bool!
    var canPushEncryptedEventsToDeviceReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canPushEncryptedEventsToDeviceUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canPushEncryptedEventsToDeviceUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canPushEncryptedEventsToDeviceUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canPushEncryptedEventsToDeviceUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var canPushEncryptedEventsToDeviceClosure: (() async -> Bool)?

    func canPushEncryptedEventsToDevice() async -> Bool {
        canPushEncryptedEventsToDeviceCallsCount += 1
        if let canPushEncryptedEventsToDeviceClosure = canPushEncryptedEventsToDeviceClosure {
            return await canPushEncryptedEventsToDeviceClosure()
        } else {
            return canPushEncryptedEventsToDeviceReturnValue
        }
    }
}
class OrientationManagerMock: OrientationManagerProtocol {

    //MARK: - setOrientation

    var setOrientationUnderlyingCallsCount = 0
    var setOrientationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setOrientationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setOrientationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setOrientationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setOrientationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setOrientationCalled: Bool {
        return setOrientationCallsCount > 0
    }
    var setOrientationReceivedOrientation: UIInterfaceOrientationMask?
    var setOrientationReceivedInvocations: [UIInterfaceOrientationMask] = []
    var setOrientationClosure: ((UIInterfaceOrientationMask) -> Void)?

    func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        setOrientationCallsCount += 1
        setOrientationReceivedOrientation = orientation
        DispatchQueue.main.async {
            self.setOrientationReceivedInvocations.append(orientation)
        }
        setOrientationClosure?(orientation)
    }
    //MARK: - lockOrientation

    var lockOrientationUnderlyingCallsCount = 0
    var lockOrientationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return lockOrientationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = lockOrientationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                lockOrientationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    lockOrientationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var lockOrientationCalled: Bool {
        return lockOrientationCallsCount > 0
    }
    var lockOrientationReceivedOrientation: UIInterfaceOrientationMask?
    var lockOrientationReceivedInvocations: [UIInterfaceOrientationMask] = []
    var lockOrientationClosure: ((UIInterfaceOrientationMask) -> Void)?

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        lockOrientationCallsCount += 1
        lockOrientationReceivedOrientation = orientation
        DispatchQueue.main.async {
            self.lockOrientationReceivedInvocations.append(orientation)
        }
        lockOrientationClosure?(orientation)
    }
}
class PHGPostHogMock: PHGPostHogProtocol {

    //MARK: - optIn

    var optInUnderlyingCallsCount = 0
    var optInCallsCount: Int {
        get {
            if Thread.isMainThread {
                return optInUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = optInUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                optInUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    optInUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var optInCalled: Bool {
        return optInCallsCount > 0
    }
    var optInClosure: (() -> Void)?

    func optIn() {
        optInCallsCount += 1
        optInClosure?()
    }
    //MARK: - optOut

    var optOutUnderlyingCallsCount = 0
    var optOutCallsCount: Int {
        get {
            if Thread.isMainThread {
                return optOutUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = optOutUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                optOutUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    optOutUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var optOutCalled: Bool {
        return optOutCallsCount > 0
    }
    var optOutClosure: (() -> Void)?

    func optOut() {
        optOutCallsCount += 1
        optOutClosure?()
    }
    //MARK: - reset

    var resetUnderlyingCallsCount = 0
    var resetCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resetUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resetUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resetUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCount += 1
        resetClosure?()
    }
    //MARK: - capture

    var capturePropertiesUserPropertiesUnderlyingCallsCount = 0
    var capturePropertiesUserPropertiesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return capturePropertiesUserPropertiesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = capturePropertiesUserPropertiesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                capturePropertiesUserPropertiesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    capturePropertiesUserPropertiesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var capturePropertiesUserPropertiesCalled: Bool {
        return capturePropertiesUserPropertiesCallsCount > 0
    }
    var capturePropertiesUserPropertiesReceivedArguments: (event: String, properties: [String: Any]?, userProperties: [String: Any]?)?
    var capturePropertiesUserPropertiesReceivedInvocations: [(event: String, properties: [String: Any]?, userProperties: [String: Any]?)] = []
    var capturePropertiesUserPropertiesClosure: ((String, [String: Any]?, [String: Any]?) -> Void)?

    func capture(_ event: String, properties: [String: Any]?, userProperties: [String: Any]?) {
        capturePropertiesUserPropertiesCallsCount += 1
        capturePropertiesUserPropertiesReceivedArguments = (event: event, properties: properties, userProperties: userProperties)
        DispatchQueue.main.async {
            self.capturePropertiesUserPropertiesReceivedInvocations.append((event: event, properties: properties, userProperties: userProperties))
        }
        capturePropertiesUserPropertiesClosure?(event, properties, userProperties)
    }
    //MARK: - screen

    var screenPropertiesUnderlyingCallsCount = 0
    var screenPropertiesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return screenPropertiesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = screenPropertiesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                screenPropertiesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    screenPropertiesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var screenPropertiesCalled: Bool {
        return screenPropertiesCallsCount > 0
    }
    var screenPropertiesReceivedArguments: (screenTitle: String, properties: [String: Any]?)?
    var screenPropertiesReceivedInvocations: [(screenTitle: String, properties: [String: Any]?)] = []
    var screenPropertiesClosure: ((String, [String: Any]?) -> Void)?

    func screen(_ screenTitle: String, properties: [String: Any]?) {
        screenPropertiesCallsCount += 1
        screenPropertiesReceivedArguments = (screenTitle: screenTitle, properties: properties)
        DispatchQueue.main.async {
            self.screenPropertiesReceivedInvocations.append((screenTitle: screenTitle, properties: properties))
        }
        screenPropertiesClosure?(screenTitle, properties)
    }
}
class PollInteractionHandlerMock: PollInteractionHandlerProtocol {

    //MARK: - sendPollResponse

    var sendPollResponsePollStartIDOptionIDUnderlyingCallsCount = 0
    var sendPollResponsePollStartIDOptionIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendPollResponsePollStartIDOptionIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendPollResponsePollStartIDOptionIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendPollResponsePollStartIDOptionIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendPollResponsePollStartIDOptionIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendPollResponsePollStartIDOptionIDCalled: Bool {
        return sendPollResponsePollStartIDOptionIDCallsCount > 0
    }
    var sendPollResponsePollStartIDOptionIDReceivedArguments: (pollStartID: String, optionID: String)?
    var sendPollResponsePollStartIDOptionIDReceivedInvocations: [(pollStartID: String, optionID: String)] = []

    var sendPollResponsePollStartIDOptionIDUnderlyingReturnValue: Result<Void, Error>!
    var sendPollResponsePollStartIDOptionIDReturnValue: Result<Void, Error>! {
        get {
            if Thread.isMainThread {
                return sendPollResponsePollStartIDOptionIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, Error>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendPollResponsePollStartIDOptionIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendPollResponsePollStartIDOptionIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendPollResponsePollStartIDOptionIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendPollResponsePollStartIDOptionIDClosure: ((String, String) async -> Result<Void, Error>)?

    func sendPollResponse(pollStartID: String, optionID: String) async -> Result<Void, Error> {
        sendPollResponsePollStartIDOptionIDCallsCount += 1
        sendPollResponsePollStartIDOptionIDReceivedArguments = (pollStartID: pollStartID, optionID: optionID)
        DispatchQueue.main.async {
            self.sendPollResponsePollStartIDOptionIDReceivedInvocations.append((pollStartID: pollStartID, optionID: optionID))
        }
        if let sendPollResponsePollStartIDOptionIDClosure = sendPollResponsePollStartIDOptionIDClosure {
            return await sendPollResponsePollStartIDOptionIDClosure(pollStartID, optionID)
        } else {
            return sendPollResponsePollStartIDOptionIDReturnValue
        }
    }
    //MARK: - endPoll

    var endPollPollStartIDUnderlyingCallsCount = 0
    var endPollPollStartIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return endPollPollStartIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = endPollPollStartIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                endPollPollStartIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    endPollPollStartIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var endPollPollStartIDCalled: Bool {
        return endPollPollStartIDCallsCount > 0
    }
    var endPollPollStartIDReceivedPollStartID: String?
    var endPollPollStartIDReceivedInvocations: [String] = []

    var endPollPollStartIDUnderlyingReturnValue: Result<Void, Error>!
    var endPollPollStartIDReturnValue: Result<Void, Error>! {
        get {
            if Thread.isMainThread {
                return endPollPollStartIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, Error>? = nil
                DispatchQueue.main.sync {
                    returnValue = endPollPollStartIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                endPollPollStartIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    endPollPollStartIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var endPollPollStartIDClosure: ((String) async -> Result<Void, Error>)?

    func endPoll(pollStartID: String) async -> Result<Void, Error> {
        endPollPollStartIDCallsCount += 1
        endPollPollStartIDReceivedPollStartID = pollStartID
        DispatchQueue.main.async {
            self.endPollPollStartIDReceivedInvocations.append(pollStartID)
        }
        if let endPollPollStartIDClosure = endPollPollStartIDClosure {
            return await endPollPollStartIDClosure(pollStartID)
        } else {
            return endPollPollStartIDReturnValue
        }
    }
}
class QRCodeLoginServiceMock: QRCodeLoginServiceProtocol {
    var qrLoginProgressPublisher: AnyPublisher<QrLoginProgress, Never> {
        get { return underlyingQrLoginProgressPublisher }
        set(value) { underlyingQrLoginProgressPublisher = value }
    }
    var underlyingQrLoginProgressPublisher: AnyPublisher<QrLoginProgress, Never>!

    //MARK: - loginWithQRCode

    var loginWithQRCodeDataUnderlyingCallsCount = 0
    var loginWithQRCodeDataCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loginWithQRCodeDataUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loginWithQRCodeDataUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loginWithQRCodeDataUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loginWithQRCodeDataUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loginWithQRCodeDataCalled: Bool {
        return loginWithQRCodeDataCallsCount > 0
    }
    var loginWithQRCodeDataReceivedData: Data?
    var loginWithQRCodeDataReceivedInvocations: [Data] = []

    var loginWithQRCodeDataUnderlyingReturnValue: Result<UserSessionProtocol, QRCodeLoginServiceError>!
    var loginWithQRCodeDataReturnValue: Result<UserSessionProtocol, QRCodeLoginServiceError>! {
        get {
            if Thread.isMainThread {
                return loginWithQRCodeDataUnderlyingReturnValue
            } else {
                var returnValue: Result<UserSessionProtocol, QRCodeLoginServiceError>? = nil
                DispatchQueue.main.sync {
                    returnValue = loginWithQRCodeDataUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loginWithQRCodeDataUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loginWithQRCodeDataUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loginWithQRCodeDataClosure: ((Data) async -> Result<UserSessionProtocol, QRCodeLoginServiceError>)?

    func loginWithQRCode(data: Data) async -> Result<UserSessionProtocol, QRCodeLoginServiceError> {
        loginWithQRCodeDataCallsCount += 1
        loginWithQRCodeDataReceivedData = data
        DispatchQueue.main.async {
            self.loginWithQRCodeDataReceivedInvocations.append(data)
        }
        if let loginWithQRCodeDataClosure = loginWithQRCodeDataClosure {
            return await loginWithQRCodeDataClosure(data)
        } else {
            return loginWithQRCodeDataReturnValue
        }
    }
}
class RoomDirectorySearchProxyMock: RoomDirectorySearchProxyProtocol {
    var resultsPublisher: CurrentValuePublisher<[RoomDirectorySearchResult], Never> {
        get { return underlyingResultsPublisher }
        set(value) { underlyingResultsPublisher = value }
    }
    var underlyingResultsPublisher: CurrentValuePublisher<[RoomDirectorySearchResult], Never>!

    //MARK: - search

    var searchQueryUnderlyingCallsCount = 0
    var searchQueryCallsCount: Int {
        get {
            if Thread.isMainThread {
                return searchQueryUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = searchQueryUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                searchQueryUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    searchQueryUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var searchQueryCalled: Bool {
        return searchQueryCallsCount > 0
    }
    var searchQueryReceivedQuery: String?
    var searchQueryReceivedInvocations: [String?] = []

    var searchQueryUnderlyingReturnValue: Result<Void, RoomDirectorySearchError>!
    var searchQueryReturnValue: Result<Void, RoomDirectorySearchError>! {
        get {
            if Thread.isMainThread {
                return searchQueryUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomDirectorySearchError>? = nil
                DispatchQueue.main.sync {
                    returnValue = searchQueryUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                searchQueryUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    searchQueryUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var searchQueryClosure: ((String?) async -> Result<Void, RoomDirectorySearchError>)?

    func search(query: String?) async -> Result<Void, RoomDirectorySearchError> {
        searchQueryCallsCount += 1
        searchQueryReceivedQuery = query
        DispatchQueue.main.async {
            self.searchQueryReceivedInvocations.append(query)
        }
        if let searchQueryClosure = searchQueryClosure {
            return await searchQueryClosure(query)
        } else {
            return searchQueryReturnValue
        }
    }
    //MARK: - nextPage

    var nextPageUnderlyingCallsCount = 0
    var nextPageCallsCount: Int {
        get {
            if Thread.isMainThread {
                return nextPageUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = nextPageUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                nextPageUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    nextPageUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var nextPageCalled: Bool {
        return nextPageCallsCount > 0
    }

    var nextPageUnderlyingReturnValue: Result<Void, RoomDirectorySearchError>!
    var nextPageReturnValue: Result<Void, RoomDirectorySearchError>! {
        get {
            if Thread.isMainThread {
                return nextPageUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, RoomDirectorySearchError>? = nil
                DispatchQueue.main.sync {
                    returnValue = nextPageUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                nextPageUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    nextPageUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var nextPageClosure: (() async -> Result<Void, RoomDirectorySearchError>)?

    func nextPage() async -> Result<Void, RoomDirectorySearchError> {
        nextPageCallsCount += 1
        if let nextPageClosure = nextPageClosure {
            return await nextPageClosure()
        } else {
            return nextPageReturnValue
        }
    }
}
class RoomMemberProxyMock: RoomMemberProxyProtocol {
    var userID: String {
        get { return underlyingUserID }
        set(value) { underlyingUserID = value }
    }
    var underlyingUserID: String!
    var displayName: String?
    var avatarURL: URL?
    var membership: MembershipState {
        get { return underlyingMembership }
        set(value) { underlyingMembership = value }
    }
    var underlyingMembership: MembershipState!
    var isIgnored: Bool {
        get { return underlyingIsIgnored }
        set(value) { underlyingIsIgnored = value }
    }
    var underlyingIsIgnored: Bool!
    var powerLevel: Int {
        get { return underlyingPowerLevel }
        set(value) { underlyingPowerLevel = value }
    }
    var underlyingPowerLevel: Int!
    var role: RoomMemberRole {
        get { return underlyingRole }
        set(value) { underlyingRole = value }
    }
    var underlyingRole: RoomMemberRole!

}
class RoomNotificationSettingsProxyMock: RoomNotificationSettingsProxyProtocol {
    var mode: RoomNotificationModeProxy {
        get { return underlyingMode }
        set(value) { underlyingMode = value }
    }
    var underlyingMode: RoomNotificationModeProxy!
    var isDefault: Bool {
        get { return underlyingIsDefault }
        set(value) { underlyingIsDefault = value }
    }
    var underlyingIsDefault: Bool!

}
class RoomProxyMock: RoomProxyProtocol {
    var id: String {
        get { return underlyingId }
        set(value) { underlyingId = value }
    }
    var underlyingId: String!
    var canonicalAlias: String?
    var ownUserID: String {
        get { return underlyingOwnUserID }
        set(value) { underlyingOwnUserID = value }
    }
    var underlyingOwnUserID: String!
    var name: String?
    var topic: String?
    var avatar: RoomAvatar {
        get { return underlyingAvatar }
        set(value) { underlyingAvatar = value }
    }
    var underlyingAvatar: RoomAvatar!
    var avatarURL: URL?
    var isPublic: Bool {
        get { return underlyingIsPublic }
        set(value) { underlyingIsPublic = value }
    }
    var underlyingIsPublic: Bool!
    var isDirect: Bool {
        get { return underlyingIsDirect }
        set(value) { underlyingIsDirect = value }
    }
    var underlyingIsDirect: Bool!
    var isSpace: Bool {
        get { return underlyingIsSpace }
        set(value) { underlyingIsSpace = value }
    }
    var underlyingIsSpace: Bool!
    var joinedMembersCount: Int {
        get { return underlyingJoinedMembersCount }
        set(value) { underlyingJoinedMembersCount = value }
    }
    var underlyingJoinedMembersCount: Int!
    var activeMembersCount: Int {
        get { return underlyingActiveMembersCount }
        set(value) { underlyingActiveMembersCount = value }
    }
    var underlyingActiveMembersCount: Int!

}
class RoomSummaryProviderMock: RoomSummaryProviderProtocol {
    var roomListPublisher: CurrentValuePublisher<[RoomSummary], Never> {
        get { return underlyingRoomListPublisher }
        set(value) { underlyingRoomListPublisher = value }
    }
    var underlyingRoomListPublisher: CurrentValuePublisher<[RoomSummary], Never>!
    var statePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never> {
        get { return underlyingStatePublisher }
        set(value) { underlyingStatePublisher = value }
    }
    var underlyingStatePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never>!

    //MARK: - setRoomList

    var setRoomListUnderlyingCallsCount = 0
    var setRoomListCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setRoomListUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setRoomListUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setRoomListUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setRoomListUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setRoomListCalled: Bool {
        return setRoomListCallsCount > 0
    }
    var setRoomListReceivedRoomList: RoomList?
    var setRoomListReceivedInvocations: [RoomList] = []
    var setRoomListClosure: ((RoomList) -> Void)?

    func setRoomList(_ roomList: RoomList) {
        setRoomListCallsCount += 1
        setRoomListReceivedRoomList = roomList
        DispatchQueue.main.async {
            self.setRoomListReceivedInvocations.append(roomList)
        }
        setRoomListClosure?(roomList)
    }
    //MARK: - updateVisibleRange

    var updateVisibleRangeUnderlyingCallsCount = 0
    var updateVisibleRangeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return updateVisibleRangeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = updateVisibleRangeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                updateVisibleRangeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    updateVisibleRangeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var updateVisibleRangeCalled: Bool {
        return updateVisibleRangeCallsCount > 0
    }
    var updateVisibleRangeReceivedRange: Range<Int>?
    var updateVisibleRangeReceivedInvocations: [Range<Int>] = []
    var updateVisibleRangeClosure: ((Range<Int>) -> Void)?

    func updateVisibleRange(_ range: Range<Int>) {
        updateVisibleRangeCallsCount += 1
        updateVisibleRangeReceivedRange = range
        DispatchQueue.main.async {
            self.updateVisibleRangeReceivedInvocations.append(range)
        }
        updateVisibleRangeClosure?(range)
    }
    //MARK: - setFilter

    var setFilterUnderlyingCallsCount = 0
    var setFilterCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setFilterUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setFilterUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setFilterUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setFilterUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setFilterCalled: Bool {
        return setFilterCallsCount > 0
    }
    var setFilterReceivedFilter: RoomSummaryProviderFilter?
    var setFilterReceivedInvocations: [RoomSummaryProviderFilter] = []
    var setFilterClosure: ((RoomSummaryProviderFilter) -> Void)?

    func setFilter(_ filter: RoomSummaryProviderFilter) {
        setFilterCallsCount += 1
        setFilterReceivedFilter = filter
        DispatchQueue.main.async {
            self.setFilterReceivedInvocations.append(filter)
        }
        setFilterClosure?(filter)
    }
}
class RoomTimelineControllerFactoryMock: RoomTimelineControllerFactoryProtocol {

    //MARK: - buildRoomTimelineController

    var buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryUnderlyingCallsCount = 0
    var buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryCallsCount: Int {
        get {
            if Thread.isMainThread {
                return buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryCalled: Bool {
        return buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryCallsCount > 0
    }
    var buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryReceivedArguments: (roomProxy: JoinedRoomProxyProtocol, initialFocussedEventID: String?, timelineItemFactory: RoomTimelineItemFactoryProtocol)?
    var buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryReceivedInvocations: [(roomProxy: JoinedRoomProxyProtocol, initialFocussedEventID: String?, timelineItemFactory: RoomTimelineItemFactoryProtocol)] = []

    var buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryUnderlyingReturnValue: RoomTimelineControllerProtocol!
    var buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryReturnValue: RoomTimelineControllerProtocol! {
        get {
            if Thread.isMainThread {
                return buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryUnderlyingReturnValue
            } else {
                var returnValue: RoomTimelineControllerProtocol? = nil
                DispatchQueue.main.sync {
                    returnValue = buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryClosure: ((JoinedRoomProxyProtocol, String?, RoomTimelineItemFactoryProtocol) -> RoomTimelineControllerProtocol)?

    func buildRoomTimelineController(roomProxy: JoinedRoomProxyProtocol, initialFocussedEventID: String?, timelineItemFactory: RoomTimelineItemFactoryProtocol) -> RoomTimelineControllerProtocol {
        buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryCallsCount += 1
        buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryReceivedArguments = (roomProxy: roomProxy, initialFocussedEventID: initialFocussedEventID, timelineItemFactory: timelineItemFactory)
        DispatchQueue.main.async {
            self.buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryReceivedInvocations.append((roomProxy: roomProxy, initialFocussedEventID: initialFocussedEventID, timelineItemFactory: timelineItemFactory))
        }
        if let buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryClosure = buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryClosure {
            return buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryClosure(roomProxy, initialFocussedEventID, timelineItemFactory)
        } else {
            return buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryReturnValue
        }
    }
    //MARK: - buildRoomPinnedTimelineController

    var buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryUnderlyingCallsCount = 0
    var buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryCallsCount: Int {
        get {
            if Thread.isMainThread {
                return buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryCalled: Bool {
        return buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryCallsCount > 0
    }
    var buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryReceivedArguments: (roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol)?
    var buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryReceivedInvocations: [(roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol)] = []

    var buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryUnderlyingReturnValue: RoomTimelineControllerProtocol?
    var buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryReturnValue: RoomTimelineControllerProtocol? {
        get {
            if Thread.isMainThread {
                return buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryUnderlyingReturnValue
            } else {
                var returnValue: RoomTimelineControllerProtocol?? = nil
                DispatchQueue.main.sync {
                    returnValue = buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryClosure: ((JoinedRoomProxyProtocol, RoomTimelineItemFactoryProtocol) async -> RoomTimelineControllerProtocol?)?

    func buildRoomPinnedTimelineController(roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol) async -> RoomTimelineControllerProtocol? {
        buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryCallsCount += 1
        buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryReceivedArguments = (roomProxy: roomProxy, timelineItemFactory: timelineItemFactory)
        DispatchQueue.main.async {
            self.buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryReceivedInvocations.append((roomProxy: roomProxy, timelineItemFactory: timelineItemFactory))
        }
        if let buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryClosure = buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryClosure {
            return await buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryClosure(roomProxy, timelineItemFactory)
        } else {
            return buildRoomPinnedTimelineControllerRoomProxyTimelineItemFactoryReturnValue
        }
    }
}
class RoomTimelineProviderMock: RoomTimelineProviderProtocol {
    var updatePublisher: AnyPublisher<([TimelineItemProxy], PaginationState), Never> {
        get { return underlyingUpdatePublisher }
        set(value) { underlyingUpdatePublisher = value }
    }
    var underlyingUpdatePublisher: AnyPublisher<([TimelineItemProxy], PaginationState), Never>!
    var itemProxies: [TimelineItemProxy] = []
    var paginationState: PaginationState {
        get { return underlyingPaginationState }
        set(value) { underlyingPaginationState = value }
    }
    var underlyingPaginationState: PaginationState!
    var kind: TimelineKind {
        get { return underlyingKind }
        set(value) { underlyingKind = value }
    }
    var underlyingKind: TimelineKind!
    var membershipChangePublisher: AnyPublisher<Void, Never> {
        get { return underlyingMembershipChangePublisher }
        set(value) { underlyingMembershipChangePublisher = value }
    }
    var underlyingMembershipChangePublisher: AnyPublisher<Void, Never>!

}
class SecureBackupControllerMock: SecureBackupControllerProtocol {
    var recoveryState: CurrentValuePublisher<SecureBackupRecoveryState, Never> {
        get { return underlyingRecoveryState }
        set(value) { underlyingRecoveryState = value }
    }
    var underlyingRecoveryState: CurrentValuePublisher<SecureBackupRecoveryState, Never>!
    var keyBackupState: CurrentValuePublisher<SecureBackupKeyBackupState, Never> {
        get { return underlyingKeyBackupState }
        set(value) { underlyingKeyBackupState = value }
    }
    var underlyingKeyBackupState: CurrentValuePublisher<SecureBackupKeyBackupState, Never>!

    //MARK: - enable

    var enableUnderlyingCallsCount = 0
    var enableCallsCount: Int {
        get {
            if Thread.isMainThread {
                return enableUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = enableUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enableUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    enableUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var enableCalled: Bool {
        return enableCallsCount > 0
    }

    var enableUnderlyingReturnValue: Result<Void, SecureBackupControllerError>!
    var enableReturnValue: Result<Void, SecureBackupControllerError>! {
        get {
            if Thread.isMainThread {
                return enableUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, SecureBackupControllerError>? = nil
                DispatchQueue.main.sync {
                    returnValue = enableUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enableUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    enableUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var enableClosure: (() async -> Result<Void, SecureBackupControllerError>)?

    func enable() async -> Result<Void, SecureBackupControllerError> {
        enableCallsCount += 1
        if let enableClosure = enableClosure {
            return await enableClosure()
        } else {
            return enableReturnValue
        }
    }
    //MARK: - disable

    var disableUnderlyingCallsCount = 0
    var disableCallsCount: Int {
        get {
            if Thread.isMainThread {
                return disableUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = disableUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                disableUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    disableUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var disableCalled: Bool {
        return disableCallsCount > 0
    }

    var disableUnderlyingReturnValue: Result<Void, SecureBackupControllerError>!
    var disableReturnValue: Result<Void, SecureBackupControllerError>! {
        get {
            if Thread.isMainThread {
                return disableUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, SecureBackupControllerError>? = nil
                DispatchQueue.main.sync {
                    returnValue = disableUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                disableUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    disableUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var disableClosure: (() async -> Result<Void, SecureBackupControllerError>)?

    func disable() async -> Result<Void, SecureBackupControllerError> {
        disableCallsCount += 1
        if let disableClosure = disableClosure {
            return await disableClosure()
        } else {
            return disableReturnValue
        }
    }
    //MARK: - generateRecoveryKey

    var generateRecoveryKeyUnderlyingCallsCount = 0
    var generateRecoveryKeyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return generateRecoveryKeyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = generateRecoveryKeyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                generateRecoveryKeyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    generateRecoveryKeyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var generateRecoveryKeyCalled: Bool {
        return generateRecoveryKeyCallsCount > 0
    }

    var generateRecoveryKeyUnderlyingReturnValue: Result<String, SecureBackupControllerError>!
    var generateRecoveryKeyReturnValue: Result<String, SecureBackupControllerError>! {
        get {
            if Thread.isMainThread {
                return generateRecoveryKeyUnderlyingReturnValue
            } else {
                var returnValue: Result<String, SecureBackupControllerError>? = nil
                DispatchQueue.main.sync {
                    returnValue = generateRecoveryKeyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                generateRecoveryKeyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    generateRecoveryKeyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var generateRecoveryKeyClosure: (() async -> Result<String, SecureBackupControllerError>)?

    func generateRecoveryKey() async -> Result<String, SecureBackupControllerError> {
        generateRecoveryKeyCallsCount += 1
        if let generateRecoveryKeyClosure = generateRecoveryKeyClosure {
            return await generateRecoveryKeyClosure()
        } else {
            return generateRecoveryKeyReturnValue
        }
    }
    //MARK: - confirmRecoveryKey

    var confirmRecoveryKeyUnderlyingCallsCount = 0
    var confirmRecoveryKeyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return confirmRecoveryKeyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = confirmRecoveryKeyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                confirmRecoveryKeyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    confirmRecoveryKeyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var confirmRecoveryKeyCalled: Bool {
        return confirmRecoveryKeyCallsCount > 0
    }
    var confirmRecoveryKeyReceivedKey: String?
    var confirmRecoveryKeyReceivedInvocations: [String] = []

    var confirmRecoveryKeyUnderlyingReturnValue: Result<Void, SecureBackupControllerError>!
    var confirmRecoveryKeyReturnValue: Result<Void, SecureBackupControllerError>! {
        get {
            if Thread.isMainThread {
                return confirmRecoveryKeyUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, SecureBackupControllerError>? = nil
                DispatchQueue.main.sync {
                    returnValue = confirmRecoveryKeyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                confirmRecoveryKeyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    confirmRecoveryKeyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var confirmRecoveryKeyClosure: ((String) async -> Result<Void, SecureBackupControllerError>)?

    func confirmRecoveryKey(_ key: String) async -> Result<Void, SecureBackupControllerError> {
        confirmRecoveryKeyCallsCount += 1
        confirmRecoveryKeyReceivedKey = key
        DispatchQueue.main.async {
            self.confirmRecoveryKeyReceivedInvocations.append(key)
        }
        if let confirmRecoveryKeyClosure = confirmRecoveryKeyClosure {
            return await confirmRecoveryKeyClosure(key)
        } else {
            return confirmRecoveryKeyReturnValue
        }
    }
    //MARK: - waitForKeyBackupUpload

    var waitForKeyBackupUploadUnderlyingCallsCount = 0
    var waitForKeyBackupUploadCallsCount: Int {
        get {
            if Thread.isMainThread {
                return waitForKeyBackupUploadUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = waitForKeyBackupUploadUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                waitForKeyBackupUploadUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    waitForKeyBackupUploadUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var waitForKeyBackupUploadCalled: Bool {
        return waitForKeyBackupUploadCallsCount > 0
    }

    var waitForKeyBackupUploadUnderlyingReturnValue: Result<Void, SecureBackupControllerError>!
    var waitForKeyBackupUploadReturnValue: Result<Void, SecureBackupControllerError>! {
        get {
            if Thread.isMainThread {
                return waitForKeyBackupUploadUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, SecureBackupControllerError>? = nil
                DispatchQueue.main.sync {
                    returnValue = waitForKeyBackupUploadUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                waitForKeyBackupUploadUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    waitForKeyBackupUploadUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var waitForKeyBackupUploadClosure: (() async -> Result<Void, SecureBackupControllerError>)?

    func waitForKeyBackupUpload() async -> Result<Void, SecureBackupControllerError> {
        waitForKeyBackupUploadCallsCount += 1
        if let waitForKeyBackupUploadClosure = waitForKeyBackupUploadClosure {
            return await waitForKeyBackupUploadClosure()
        } else {
            return waitForKeyBackupUploadReturnValue
        }
    }
}
class SessionVerificationControllerProxyMock: SessionVerificationControllerProxyProtocol {
    var callbacks: PassthroughSubject<SessionVerificationControllerProxyCallback, Never> {
        get { return underlyingCallbacks }
        set(value) { underlyingCallbacks = value }
    }
    var underlyingCallbacks: PassthroughSubject<SessionVerificationControllerProxyCallback, Never>!

    //MARK: - requestVerification

    var requestVerificationUnderlyingCallsCount = 0
    var requestVerificationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return requestVerificationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = requestVerificationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                requestVerificationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    requestVerificationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var requestVerificationCalled: Bool {
        return requestVerificationCallsCount > 0
    }

    var requestVerificationUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var requestVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get {
            if Thread.isMainThread {
                return requestVerificationUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, SessionVerificationControllerProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = requestVerificationUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                requestVerificationUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    requestVerificationUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var requestVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func requestVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        requestVerificationCallsCount += 1
        if let requestVerificationClosure = requestVerificationClosure {
            return await requestVerificationClosure()
        } else {
            return requestVerificationReturnValue
        }
    }
    //MARK: - startSasVerification

    var startSasVerificationUnderlyingCallsCount = 0
    var startSasVerificationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return startSasVerificationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = startSasVerificationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startSasVerificationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    startSasVerificationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var startSasVerificationCalled: Bool {
        return startSasVerificationCallsCount > 0
    }

    var startSasVerificationUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var startSasVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get {
            if Thread.isMainThread {
                return startSasVerificationUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, SessionVerificationControllerProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = startSasVerificationUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startSasVerificationUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    startSasVerificationUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var startSasVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func startSasVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        startSasVerificationCallsCount += 1
        if let startSasVerificationClosure = startSasVerificationClosure {
            return await startSasVerificationClosure()
        } else {
            return startSasVerificationReturnValue
        }
    }
    //MARK: - approveVerification

    var approveVerificationUnderlyingCallsCount = 0
    var approveVerificationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return approveVerificationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = approveVerificationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                approveVerificationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    approveVerificationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var approveVerificationCalled: Bool {
        return approveVerificationCallsCount > 0
    }

    var approveVerificationUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var approveVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get {
            if Thread.isMainThread {
                return approveVerificationUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, SessionVerificationControllerProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = approveVerificationUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                approveVerificationUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    approveVerificationUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var approveVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func approveVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        approveVerificationCallsCount += 1
        if let approveVerificationClosure = approveVerificationClosure {
            return await approveVerificationClosure()
        } else {
            return approveVerificationReturnValue
        }
    }
    //MARK: - declineVerification

    var declineVerificationUnderlyingCallsCount = 0
    var declineVerificationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return declineVerificationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = declineVerificationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                declineVerificationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    declineVerificationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var declineVerificationCalled: Bool {
        return declineVerificationCallsCount > 0
    }

    var declineVerificationUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var declineVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get {
            if Thread.isMainThread {
                return declineVerificationUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, SessionVerificationControllerProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = declineVerificationUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                declineVerificationUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    declineVerificationUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var declineVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func declineVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        declineVerificationCallsCount += 1
        if let declineVerificationClosure = declineVerificationClosure {
            return await declineVerificationClosure()
        } else {
            return declineVerificationReturnValue
        }
    }
    //MARK: - cancelVerification

    var cancelVerificationUnderlyingCallsCount = 0
    var cancelVerificationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return cancelVerificationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = cancelVerificationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                cancelVerificationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    cancelVerificationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var cancelVerificationCalled: Bool {
        return cancelVerificationCallsCount > 0
    }

    var cancelVerificationUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var cancelVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get {
            if Thread.isMainThread {
                return cancelVerificationUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, SessionVerificationControllerProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = cancelVerificationUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                cancelVerificationUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    cancelVerificationUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var cancelVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func cancelVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        cancelVerificationCallsCount += 1
        if let cancelVerificationClosure = cancelVerificationClosure {
            return await cancelVerificationClosure()
        } else {
            return cancelVerificationReturnValue
        }
    }
}
class TimelineProxyMock: TimelineProxyProtocol {
    var timelineProvider: RoomTimelineProviderProtocol {
        get { return underlyingTimelineProvider }
        set(value) { underlyingTimelineProvider = value }
    }
    var underlyingTimelineProvider: RoomTimelineProviderProtocol!

    //MARK: - subscribeForUpdates

    var subscribeForUpdatesUnderlyingCallsCount = 0
    var subscribeForUpdatesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return subscribeForUpdatesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeForUpdatesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeForUpdatesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeForUpdatesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var subscribeForUpdatesCalled: Bool {
        return subscribeForUpdatesCallsCount > 0
    }
    var subscribeForUpdatesClosure: (() async -> Void)?

    func subscribeForUpdates() async {
        subscribeForUpdatesCallsCount += 1
        await subscribeForUpdatesClosure?()
    }
    //MARK: - fetchDetails

    var fetchDetailsForUnderlyingCallsCount = 0
    var fetchDetailsForCallsCount: Int {
        get {
            if Thread.isMainThread {
                return fetchDetailsForUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = fetchDetailsForUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                fetchDetailsForUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    fetchDetailsForUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var fetchDetailsForCalled: Bool {
        return fetchDetailsForCallsCount > 0
    }
    var fetchDetailsForReceivedEventID: String?
    var fetchDetailsForReceivedInvocations: [String] = []
    var fetchDetailsForClosure: ((String) -> Void)?

    func fetchDetails(for eventID: String) {
        fetchDetailsForCallsCount += 1
        fetchDetailsForReceivedEventID = eventID
        DispatchQueue.main.async {
            self.fetchDetailsForReceivedInvocations.append(eventID)
        }
        fetchDetailsForClosure?(eventID)
    }
    //MARK: - messageEventContent

    var messageEventContentForUnderlyingCallsCount = 0
    var messageEventContentForCallsCount: Int {
        get {
            if Thread.isMainThread {
                return messageEventContentForUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = messageEventContentForUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                messageEventContentForUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    messageEventContentForUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var messageEventContentForCalled: Bool {
        return messageEventContentForCallsCount > 0
    }
    var messageEventContentForReceivedTimelineItemID: TimelineItemIdentifier?
    var messageEventContentForReceivedInvocations: [TimelineItemIdentifier] = []

    var messageEventContentForUnderlyingReturnValue: RoomMessageEventContentWithoutRelation?
    var messageEventContentForReturnValue: RoomMessageEventContentWithoutRelation? {
        get {
            if Thread.isMainThread {
                return messageEventContentForUnderlyingReturnValue
            } else {
                var returnValue: RoomMessageEventContentWithoutRelation?? = nil
                DispatchQueue.main.sync {
                    returnValue = messageEventContentForUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                messageEventContentForUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    messageEventContentForUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var messageEventContentForClosure: ((TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation?)?

    func messageEventContent(for timelineItemID: TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation? {
        messageEventContentForCallsCount += 1
        messageEventContentForReceivedTimelineItemID = timelineItemID
        DispatchQueue.main.async {
            self.messageEventContentForReceivedInvocations.append(timelineItemID)
        }
        if let messageEventContentForClosure = messageEventContentForClosure {
            return await messageEventContentForClosure(timelineItemID)
        } else {
            return messageEventContentForReturnValue
        }
    }
    //MARK: - retryDecryption

    var retryDecryptionForUnderlyingCallsCount = 0
    var retryDecryptionForCallsCount: Int {
        get {
            if Thread.isMainThread {
                return retryDecryptionForUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = retryDecryptionForUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                retryDecryptionForUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    retryDecryptionForUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var retryDecryptionForCalled: Bool {
        return retryDecryptionForCallsCount > 0
    }
    var retryDecryptionForReceivedSessionID: String?
    var retryDecryptionForReceivedInvocations: [String] = []
    var retryDecryptionForClosure: ((String) async -> Void)?

    func retryDecryption(for sessionID: String) async {
        retryDecryptionForCallsCount += 1
        retryDecryptionForReceivedSessionID = sessionID
        DispatchQueue.main.async {
            self.retryDecryptionForReceivedInvocations.append(sessionID)
        }
        await retryDecryptionForClosure?(sessionID)
    }
    //MARK: - paginateBackwards

    var paginateBackwardsRequestSizeUnderlyingCallsCount = 0
    var paginateBackwardsRequestSizeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return paginateBackwardsRequestSizeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = paginateBackwardsRequestSizeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                paginateBackwardsRequestSizeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    paginateBackwardsRequestSizeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var paginateBackwardsRequestSizeCalled: Bool {
        return paginateBackwardsRequestSizeCallsCount > 0
    }
    var paginateBackwardsRequestSizeReceivedRequestSize: UInt16?
    var paginateBackwardsRequestSizeReceivedInvocations: [UInt16] = []

    var paginateBackwardsRequestSizeUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var paginateBackwardsRequestSizeReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return paginateBackwardsRequestSizeUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = paginateBackwardsRequestSizeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                paginateBackwardsRequestSizeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    paginateBackwardsRequestSizeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var paginateBackwardsRequestSizeClosure: ((UInt16) async -> Result<Void, TimelineProxyError>)?

    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        paginateBackwardsRequestSizeCallsCount += 1
        paginateBackwardsRequestSizeReceivedRequestSize = requestSize
        DispatchQueue.main.async {
            self.paginateBackwardsRequestSizeReceivedInvocations.append(requestSize)
        }
        if let paginateBackwardsRequestSizeClosure = paginateBackwardsRequestSizeClosure {
            return await paginateBackwardsRequestSizeClosure(requestSize)
        } else {
            return paginateBackwardsRequestSizeReturnValue
        }
    }
    //MARK: - paginateForwards

    var paginateForwardsRequestSizeUnderlyingCallsCount = 0
    var paginateForwardsRequestSizeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return paginateForwardsRequestSizeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = paginateForwardsRequestSizeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                paginateForwardsRequestSizeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    paginateForwardsRequestSizeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var paginateForwardsRequestSizeCalled: Bool {
        return paginateForwardsRequestSizeCallsCount > 0
    }
    var paginateForwardsRequestSizeReceivedRequestSize: UInt16?
    var paginateForwardsRequestSizeReceivedInvocations: [UInt16] = []

    var paginateForwardsRequestSizeUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var paginateForwardsRequestSizeReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return paginateForwardsRequestSizeUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = paginateForwardsRequestSizeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                paginateForwardsRequestSizeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    paginateForwardsRequestSizeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var paginateForwardsRequestSizeClosure: ((UInt16) async -> Result<Void, TimelineProxyError>)?

    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        paginateForwardsRequestSizeCallsCount += 1
        paginateForwardsRequestSizeReceivedRequestSize = requestSize
        DispatchQueue.main.async {
            self.paginateForwardsRequestSizeReceivedInvocations.append(requestSize)
        }
        if let paginateForwardsRequestSizeClosure = paginateForwardsRequestSizeClosure {
            return await paginateForwardsRequestSizeClosure(requestSize)
        } else {
            return paginateForwardsRequestSizeReturnValue
        }
    }
    //MARK: - edit

    var editNewContentUnderlyingCallsCount = 0
    var editNewContentCallsCount: Int {
        get {
            if Thread.isMainThread {
                return editNewContentUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = editNewContentUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                editNewContentUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    editNewContentUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var editNewContentCalled: Bool {
        return editNewContentCallsCount > 0
    }
    var editNewContentReceivedArguments: (timelineItem: EventTimelineItem, newContent: RoomMessageEventContentWithoutRelation)?
    var editNewContentReceivedInvocations: [(timelineItem: EventTimelineItem, newContent: RoomMessageEventContentWithoutRelation)] = []

    var editNewContentUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var editNewContentReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return editNewContentUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = editNewContentUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                editNewContentUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    editNewContentUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var editNewContentClosure: ((EventTimelineItem, RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError>)?

    func edit(_ timelineItem: EventTimelineItem, newContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError> {
        editNewContentCallsCount += 1
        editNewContentReceivedArguments = (timelineItem: timelineItem, newContent: newContent)
        DispatchQueue.main.async {
            self.editNewContentReceivedInvocations.append((timelineItem: timelineItem, newContent: newContent))
        }
        if let editNewContentClosure = editNewContentClosure {
            return await editNewContentClosure(timelineItem, newContent)
        } else {
            return editNewContentReturnValue
        }
    }
    //MARK: - redact

    var redactReasonUnderlyingCallsCount = 0
    var redactReasonCallsCount: Int {
        get {
            if Thread.isMainThread {
                return redactReasonUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = redactReasonUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                redactReasonUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    redactReasonUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var redactReasonCalled: Bool {
        return redactReasonCallsCount > 0
    }
    var redactReasonReceivedArguments: (timelineItemID: TimelineItemIdentifier, reason: String?)?
    var redactReasonReceivedInvocations: [(timelineItemID: TimelineItemIdentifier, reason: String?)] = []

    var redactReasonUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var redactReasonReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return redactReasonUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = redactReasonUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                redactReasonUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    redactReasonUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var redactReasonClosure: ((TimelineItemIdentifier, String?) async -> Result<Void, TimelineProxyError>)?

    func redact(_ timelineItemID: TimelineItemIdentifier, reason: String?) async -> Result<Void, TimelineProxyError> {
        redactReasonCallsCount += 1
        redactReasonReceivedArguments = (timelineItemID: timelineItemID, reason: reason)
        DispatchQueue.main.async {
            self.redactReasonReceivedInvocations.append((timelineItemID: timelineItemID, reason: reason))
        }
        if let redactReasonClosure = redactReasonClosure {
            return await redactReasonClosure(timelineItemID, reason)
        } else {
            return redactReasonReturnValue
        }
    }
    //MARK: - pin

    var pinEventIDUnderlyingCallsCount = 0
    var pinEventIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return pinEventIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = pinEventIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pinEventIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    pinEventIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var pinEventIDCalled: Bool {
        return pinEventIDCallsCount > 0
    }
    var pinEventIDReceivedEventID: String?
    var pinEventIDReceivedInvocations: [String] = []

    var pinEventIDUnderlyingReturnValue: Result<Bool, TimelineProxyError>!
    var pinEventIDReturnValue: Result<Bool, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return pinEventIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = pinEventIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pinEventIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    pinEventIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var pinEventIDClosure: ((String) async -> Result<Bool, TimelineProxyError>)?

    func pin(eventID: String) async -> Result<Bool, TimelineProxyError> {
        pinEventIDCallsCount += 1
        pinEventIDReceivedEventID = eventID
        DispatchQueue.main.async {
            self.pinEventIDReceivedInvocations.append(eventID)
        }
        if let pinEventIDClosure = pinEventIDClosure {
            return await pinEventIDClosure(eventID)
        } else {
            return pinEventIDReturnValue
        }
    }
    //MARK: - unpin

    var unpinEventIDUnderlyingCallsCount = 0
    var unpinEventIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return unpinEventIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = unpinEventIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unpinEventIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    unpinEventIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var unpinEventIDCalled: Bool {
        return unpinEventIDCallsCount > 0
    }
    var unpinEventIDReceivedEventID: String?
    var unpinEventIDReceivedInvocations: [String] = []

    var unpinEventIDUnderlyingReturnValue: Result<Bool, TimelineProxyError>!
    var unpinEventIDReturnValue: Result<Bool, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return unpinEventIDUnderlyingReturnValue
            } else {
                var returnValue: Result<Bool, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = unpinEventIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unpinEventIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    unpinEventIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var unpinEventIDClosure: ((String) async -> Result<Bool, TimelineProxyError>)?

    func unpin(eventID: String) async -> Result<Bool, TimelineProxyError> {
        unpinEventIDCallsCount += 1
        unpinEventIDReceivedEventID = eventID
        DispatchQueue.main.async {
            self.unpinEventIDReceivedInvocations.append(eventID)
        }
        if let unpinEventIDClosure = unpinEventIDClosure {
            return await unpinEventIDClosure(eventID)
        } else {
            return unpinEventIDReturnValue
        }
    }
    //MARK: - sendAudio

    var sendAudioUrlAudioInfoProgressSubjectRequestHandleUnderlyingCallsCount = 0
    var sendAudioUrlAudioInfoProgressSubjectRequestHandleCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendAudioUrlAudioInfoProgressSubjectRequestHandleUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendAudioUrlAudioInfoProgressSubjectRequestHandleUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendAudioUrlAudioInfoProgressSubjectRequestHandleUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendAudioUrlAudioInfoProgressSubjectRequestHandleUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendAudioUrlAudioInfoProgressSubjectRequestHandleCalled: Bool {
        return sendAudioUrlAudioInfoProgressSubjectRequestHandleCallsCount > 0
    }

    var sendAudioUrlAudioInfoProgressSubjectRequestHandleUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendAudioUrlAudioInfoProgressSubjectRequestHandleReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return sendAudioUrlAudioInfoProgressSubjectRequestHandleUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendAudioUrlAudioInfoProgressSubjectRequestHandleUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendAudioUrlAudioInfoProgressSubjectRequestHandleUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendAudioUrlAudioInfoProgressSubjectRequestHandleUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendAudioUrlAudioInfoProgressSubjectRequestHandleClosure: ((URL, AudioInfo, CurrentValueSubject<Double, Never>?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>)?

    func sendAudio(url: URL, audioInfo: AudioInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendAudioUrlAudioInfoProgressSubjectRequestHandleCallsCount += 1
        if let sendAudioUrlAudioInfoProgressSubjectRequestHandleClosure = sendAudioUrlAudioInfoProgressSubjectRequestHandleClosure {
            return await sendAudioUrlAudioInfoProgressSubjectRequestHandleClosure(url, audioInfo, progressSubject, requestHandle)
        } else {
            return sendAudioUrlAudioInfoProgressSubjectRequestHandleReturnValue
        }
    }
    //MARK: - sendFile

    var sendFileUrlFileInfoProgressSubjectRequestHandleUnderlyingCallsCount = 0
    var sendFileUrlFileInfoProgressSubjectRequestHandleCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendFileUrlFileInfoProgressSubjectRequestHandleUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendFileUrlFileInfoProgressSubjectRequestHandleUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendFileUrlFileInfoProgressSubjectRequestHandleUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendFileUrlFileInfoProgressSubjectRequestHandleUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendFileUrlFileInfoProgressSubjectRequestHandleCalled: Bool {
        return sendFileUrlFileInfoProgressSubjectRequestHandleCallsCount > 0
    }

    var sendFileUrlFileInfoProgressSubjectRequestHandleUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendFileUrlFileInfoProgressSubjectRequestHandleReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return sendFileUrlFileInfoProgressSubjectRequestHandleUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendFileUrlFileInfoProgressSubjectRequestHandleUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendFileUrlFileInfoProgressSubjectRequestHandleUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendFileUrlFileInfoProgressSubjectRequestHandleUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendFileUrlFileInfoProgressSubjectRequestHandleClosure: ((URL, FileInfo, CurrentValueSubject<Double, Never>?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>)?

    func sendFile(url: URL, fileInfo: FileInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendFileUrlFileInfoProgressSubjectRequestHandleCallsCount += 1
        if let sendFileUrlFileInfoProgressSubjectRequestHandleClosure = sendFileUrlFileInfoProgressSubjectRequestHandleClosure {
            return await sendFileUrlFileInfoProgressSubjectRequestHandleClosure(url, fileInfo, progressSubject, requestHandle)
        } else {
            return sendFileUrlFileInfoProgressSubjectRequestHandleReturnValue
        }
    }
    //MARK: - sendImage

    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleUnderlyingCallsCount = 0
    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleCalled: Bool {
        return sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleCallsCount > 0
    }

    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleClosure: ((URL, URL, ImageInfo, CurrentValueSubject<Double, Never>?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>)?

    func sendImage(url: URL, thumbnailURL: URL, imageInfo: ImageInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleCallsCount += 1
        if let sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleClosure = sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleClosure {
            return await sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleClosure(url, thumbnailURL, imageInfo, progressSubject, requestHandle)
        } else {
            return sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleReturnValue
        }
    }
    //MARK: - sendLocation

    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount = 0
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCalled: Bool {
        return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount > 0
    }
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArguments: (body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)?
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocations: [(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)] = []

    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure: ((String, GeoURI, String?, UInt8?, AssetType?) async -> Result<Void, TimelineProxyError>)?

    func sendLocation(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?) async -> Result<Void, TimelineProxyError> {
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount += 1
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArguments = (body: body, geoURI: geoURI, description: description, zoomLevel: zoomLevel, assetType: assetType)
        DispatchQueue.main.async {
            self.sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocations.append((body: body, geoURI: geoURI, description: description, zoomLevel: zoomLevel, assetType: assetType))
        }
        if let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure = sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure {
            return await sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure(body, geoURI, description, zoomLevel, assetType)
        } else {
            return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValue
        }
    }
    //MARK: - sendVideo

    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleUnderlyingCallsCount = 0
    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleCalled: Bool {
        return sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleCallsCount > 0
    }

    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleClosure: ((URL, URL, VideoInfo, CurrentValueSubject<Double, Never>?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>)?

    func sendVideo(url: URL, thumbnailURL: URL, videoInfo: VideoInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleCallsCount += 1
        if let sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleClosure = sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleClosure {
            return await sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleClosure(url, thumbnailURL, videoInfo, progressSubject, requestHandle)
        } else {
            return sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleReturnValue
        }
    }
    //MARK: - sendVoiceMessage

    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleUnderlyingCallsCount = 0
    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCalled: Bool {
        return sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCallsCount > 0
    }

    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleClosure: ((URL, AudioInfo, [UInt16], CurrentValueSubject<Double, Never>?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>)?

    func sendVoiceMessage(url: URL, audioInfo: AudioInfo, waveform: [UInt16], progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCallsCount += 1
        if let sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleClosure = sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleClosure {
            return await sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleClosure(url, audioInfo, waveform, progressSubject, requestHandle)
        } else {
            return sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleReturnValue
        }
    }
    //MARK: - sendReadReceipt

    var sendReadReceiptForTypeUnderlyingCallsCount = 0
    var sendReadReceiptForTypeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendReadReceiptForTypeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendReadReceiptForTypeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendReadReceiptForTypeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendReadReceiptForTypeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendReadReceiptForTypeCalled: Bool {
        return sendReadReceiptForTypeCallsCount > 0
    }
    var sendReadReceiptForTypeReceivedArguments: (eventID: String, type: ReceiptType)?
    var sendReadReceiptForTypeReceivedInvocations: [(eventID: String, type: ReceiptType)] = []

    var sendReadReceiptForTypeUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendReadReceiptForTypeReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return sendReadReceiptForTypeUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendReadReceiptForTypeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendReadReceiptForTypeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendReadReceiptForTypeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendReadReceiptForTypeClosure: ((String, ReceiptType) async -> Result<Void, TimelineProxyError>)?

    func sendReadReceipt(for eventID: String, type: ReceiptType) async -> Result<Void, TimelineProxyError> {
        sendReadReceiptForTypeCallsCount += 1
        sendReadReceiptForTypeReceivedArguments = (eventID: eventID, type: type)
        DispatchQueue.main.async {
            self.sendReadReceiptForTypeReceivedInvocations.append((eventID: eventID, type: type))
        }
        if let sendReadReceiptForTypeClosure = sendReadReceiptForTypeClosure {
            return await sendReadReceiptForTypeClosure(eventID, type)
        } else {
            return sendReadReceiptForTypeReturnValue
        }
    }
    //MARK: - sendMessageEventContent

    var sendMessageEventContentUnderlyingCallsCount = 0
    var sendMessageEventContentCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendMessageEventContentUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendMessageEventContentUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendMessageEventContentUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendMessageEventContentUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendMessageEventContentCalled: Bool {
        return sendMessageEventContentCallsCount > 0
    }
    var sendMessageEventContentReceivedMessageContent: RoomMessageEventContentWithoutRelation?
    var sendMessageEventContentReceivedInvocations: [RoomMessageEventContentWithoutRelation] = []

    var sendMessageEventContentUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendMessageEventContentReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return sendMessageEventContentUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendMessageEventContentUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendMessageEventContentUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendMessageEventContentUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendMessageEventContentClosure: ((RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError>)?

    func sendMessageEventContent(_ messageContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError> {
        sendMessageEventContentCallsCount += 1
        sendMessageEventContentReceivedMessageContent = messageContent
        DispatchQueue.main.async {
            self.sendMessageEventContentReceivedInvocations.append(messageContent)
        }
        if let sendMessageEventContentClosure = sendMessageEventContentClosure {
            return await sendMessageEventContentClosure(messageContent)
        } else {
            return sendMessageEventContentReturnValue
        }
    }
    //MARK: - sendMessage

    var sendMessageHtmlInReplyToIntentionalMentionsUnderlyingCallsCount = 0
    var sendMessageHtmlInReplyToIntentionalMentionsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendMessageHtmlInReplyToIntentionalMentionsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendMessageHtmlInReplyToIntentionalMentionsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendMessageHtmlInReplyToIntentionalMentionsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendMessageHtmlInReplyToIntentionalMentionsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendMessageHtmlInReplyToIntentionalMentionsCalled: Bool {
        return sendMessageHtmlInReplyToIntentionalMentionsCallsCount > 0
    }
    var sendMessageHtmlInReplyToIntentionalMentionsReceivedArguments: (message: String, html: String?, eventID: String?, intentionalMentions: IntentionalMentions)?
    var sendMessageHtmlInReplyToIntentionalMentionsReceivedInvocations: [(message: String, html: String?, eventID: String?, intentionalMentions: IntentionalMentions)] = []

    var sendMessageHtmlInReplyToIntentionalMentionsUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendMessageHtmlInReplyToIntentionalMentionsReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return sendMessageHtmlInReplyToIntentionalMentionsUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendMessageHtmlInReplyToIntentionalMentionsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendMessageHtmlInReplyToIntentionalMentionsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendMessageHtmlInReplyToIntentionalMentionsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendMessageHtmlInReplyToIntentionalMentionsClosure: ((String, String?, String?, IntentionalMentions) async -> Result<Void, TimelineProxyError>)?

    func sendMessage(_ message: String, html: String?, inReplyTo eventID: String?, intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError> {
        sendMessageHtmlInReplyToIntentionalMentionsCallsCount += 1
        sendMessageHtmlInReplyToIntentionalMentionsReceivedArguments = (message: message, html: html, eventID: eventID, intentionalMentions: intentionalMentions)
        DispatchQueue.main.async {
            self.sendMessageHtmlInReplyToIntentionalMentionsReceivedInvocations.append((message: message, html: html, eventID: eventID, intentionalMentions: intentionalMentions))
        }
        if let sendMessageHtmlInReplyToIntentionalMentionsClosure = sendMessageHtmlInReplyToIntentionalMentionsClosure {
            return await sendMessageHtmlInReplyToIntentionalMentionsClosure(message, html, eventID, intentionalMentions)
        } else {
            return sendMessageHtmlInReplyToIntentionalMentionsReturnValue
        }
    }
    //MARK: - toggleReaction

    var toggleReactionToUnderlyingCallsCount = 0
    var toggleReactionToCallsCount: Int {
        get {
            if Thread.isMainThread {
                return toggleReactionToUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = toggleReactionToUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                toggleReactionToUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    toggleReactionToUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var toggleReactionToCalled: Bool {
        return toggleReactionToCallsCount > 0
    }
    var toggleReactionToReceivedArguments: (reaction: String, itemID: TimelineItemIdentifier)?
    var toggleReactionToReceivedInvocations: [(reaction: String, itemID: TimelineItemIdentifier)] = []

    var toggleReactionToUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var toggleReactionToReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return toggleReactionToUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = toggleReactionToUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                toggleReactionToUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    toggleReactionToUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var toggleReactionToClosure: ((String, TimelineItemIdentifier) async -> Result<Void, TimelineProxyError>)?

    func toggleReaction(_ reaction: String, to itemID: TimelineItemIdentifier) async -> Result<Void, TimelineProxyError> {
        toggleReactionToCallsCount += 1
        toggleReactionToReceivedArguments = (reaction: reaction, itemID: itemID)
        DispatchQueue.main.async {
            self.toggleReactionToReceivedInvocations.append((reaction: reaction, itemID: itemID))
        }
        if let toggleReactionToClosure = toggleReactionToClosure {
            return await toggleReactionToClosure(reaction, itemID)
        } else {
            return toggleReactionToReturnValue
        }
    }
    //MARK: - createPoll

    var createPollQuestionAnswersPollKindUnderlyingCallsCount = 0
    var createPollQuestionAnswersPollKindCallsCount: Int {
        get {
            if Thread.isMainThread {
                return createPollQuestionAnswersPollKindUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = createPollQuestionAnswersPollKindUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                createPollQuestionAnswersPollKindUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    createPollQuestionAnswersPollKindUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var createPollQuestionAnswersPollKindCalled: Bool {
        return createPollQuestionAnswersPollKindCallsCount > 0
    }
    var createPollQuestionAnswersPollKindReceivedArguments: (question: String, answers: [String], pollKind: Poll.Kind)?
    var createPollQuestionAnswersPollKindReceivedInvocations: [(question: String, answers: [String], pollKind: Poll.Kind)] = []

    var createPollQuestionAnswersPollKindUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var createPollQuestionAnswersPollKindReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return createPollQuestionAnswersPollKindUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = createPollQuestionAnswersPollKindUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                createPollQuestionAnswersPollKindUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    createPollQuestionAnswersPollKindUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var createPollQuestionAnswersPollKindClosure: ((String, [String], Poll.Kind) async -> Result<Void, TimelineProxyError>)?

    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        createPollQuestionAnswersPollKindCallsCount += 1
        createPollQuestionAnswersPollKindReceivedArguments = (question: question, answers: answers, pollKind: pollKind)
        DispatchQueue.main.async {
            self.createPollQuestionAnswersPollKindReceivedInvocations.append((question: question, answers: answers, pollKind: pollKind))
        }
        if let createPollQuestionAnswersPollKindClosure = createPollQuestionAnswersPollKindClosure {
            return await createPollQuestionAnswersPollKindClosure(question, answers, pollKind)
        } else {
            return createPollQuestionAnswersPollKindReturnValue
        }
    }
    //MARK: - editPoll

    var editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount = 0
    var editPollOriginalQuestionAnswersPollKindCallsCount: Int {
        get {
            if Thread.isMainThread {
                return editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var editPollOriginalQuestionAnswersPollKindCalled: Bool {
        return editPollOriginalQuestionAnswersPollKindCallsCount > 0
    }
    var editPollOriginalQuestionAnswersPollKindReceivedArguments: (eventID: String, question: String, answers: [String], pollKind: Poll.Kind)?
    var editPollOriginalQuestionAnswersPollKindReceivedInvocations: [(eventID: String, question: String, answers: [String], pollKind: Poll.Kind)] = []

    var editPollOriginalQuestionAnswersPollKindUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var editPollOriginalQuestionAnswersPollKindReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return editPollOriginalQuestionAnswersPollKindUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = editPollOriginalQuestionAnswersPollKindUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                editPollOriginalQuestionAnswersPollKindUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    editPollOriginalQuestionAnswersPollKindUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var editPollOriginalQuestionAnswersPollKindClosure: ((String, String, [String], Poll.Kind) async -> Result<Void, TimelineProxyError>)?

    func editPoll(original eventID: String, question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        editPollOriginalQuestionAnswersPollKindCallsCount += 1
        editPollOriginalQuestionAnswersPollKindReceivedArguments = (eventID: eventID, question: question, answers: answers, pollKind: pollKind)
        DispatchQueue.main.async {
            self.editPollOriginalQuestionAnswersPollKindReceivedInvocations.append((eventID: eventID, question: question, answers: answers, pollKind: pollKind))
        }
        if let editPollOriginalQuestionAnswersPollKindClosure = editPollOriginalQuestionAnswersPollKindClosure {
            return await editPollOriginalQuestionAnswersPollKindClosure(eventID, question, answers, pollKind)
        } else {
            return editPollOriginalQuestionAnswersPollKindReturnValue
        }
    }
    //MARK: - endPoll

    var endPollPollStartIDTextUnderlyingCallsCount = 0
    var endPollPollStartIDTextCallsCount: Int {
        get {
            if Thread.isMainThread {
                return endPollPollStartIDTextUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = endPollPollStartIDTextUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                endPollPollStartIDTextUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    endPollPollStartIDTextUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var endPollPollStartIDTextCalled: Bool {
        return endPollPollStartIDTextCallsCount > 0
    }
    var endPollPollStartIDTextReceivedArguments: (pollStartID: String, text: String)?
    var endPollPollStartIDTextReceivedInvocations: [(pollStartID: String, text: String)] = []

    var endPollPollStartIDTextUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var endPollPollStartIDTextReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return endPollPollStartIDTextUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = endPollPollStartIDTextUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                endPollPollStartIDTextUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    endPollPollStartIDTextUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var endPollPollStartIDTextClosure: ((String, String) async -> Result<Void, TimelineProxyError>)?

    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineProxyError> {
        endPollPollStartIDTextCallsCount += 1
        endPollPollStartIDTextReceivedArguments = (pollStartID: pollStartID, text: text)
        DispatchQueue.main.async {
            self.endPollPollStartIDTextReceivedInvocations.append((pollStartID: pollStartID, text: text))
        }
        if let endPollPollStartIDTextClosure = endPollPollStartIDTextClosure {
            return await endPollPollStartIDTextClosure(pollStartID, text)
        } else {
            return endPollPollStartIDTextReturnValue
        }
    }
    //MARK: - sendPollResponse

    var sendPollResponsePollStartIDAnswersUnderlyingCallsCount = 0
    var sendPollResponsePollStartIDAnswersCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendPollResponsePollStartIDAnswersUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendPollResponsePollStartIDAnswersUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendPollResponsePollStartIDAnswersUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendPollResponsePollStartIDAnswersUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendPollResponsePollStartIDAnswersCalled: Bool {
        return sendPollResponsePollStartIDAnswersCallsCount > 0
    }
    var sendPollResponsePollStartIDAnswersReceivedArguments: (pollStartID: String, answers: [String])?
    var sendPollResponsePollStartIDAnswersReceivedInvocations: [(pollStartID: String, answers: [String])] = []

    var sendPollResponsePollStartIDAnswersUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendPollResponsePollStartIDAnswersReturnValue: Result<Void, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return sendPollResponsePollStartIDAnswersUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendPollResponsePollStartIDAnswersUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendPollResponsePollStartIDAnswersUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendPollResponsePollStartIDAnswersUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendPollResponsePollStartIDAnswersClosure: ((String, [String]) async -> Result<Void, TimelineProxyError>)?

    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineProxyError> {
        sendPollResponsePollStartIDAnswersCallsCount += 1
        sendPollResponsePollStartIDAnswersReceivedArguments = (pollStartID: pollStartID, answers: answers)
        DispatchQueue.main.async {
            self.sendPollResponsePollStartIDAnswersReceivedInvocations.append((pollStartID: pollStartID, answers: answers))
        }
        if let sendPollResponsePollStartIDAnswersClosure = sendPollResponsePollStartIDAnswersClosure {
            return await sendPollResponsePollStartIDAnswersClosure(pollStartID, answers)
        } else {
            return sendPollResponsePollStartIDAnswersReturnValue
        }
    }
    //MARK: - getLoadedReplyDetails

    var getLoadedReplyDetailsEventIDUnderlyingCallsCount = 0
    var getLoadedReplyDetailsEventIDCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getLoadedReplyDetailsEventIDUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getLoadedReplyDetailsEventIDUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getLoadedReplyDetailsEventIDUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getLoadedReplyDetailsEventIDUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var getLoadedReplyDetailsEventIDCalled: Bool {
        return getLoadedReplyDetailsEventIDCallsCount > 0
    }
    var getLoadedReplyDetailsEventIDReceivedEventID: String?
    var getLoadedReplyDetailsEventIDReceivedInvocations: [String] = []

    var getLoadedReplyDetailsEventIDUnderlyingReturnValue: Result<InReplyToDetails, TimelineProxyError>!
    var getLoadedReplyDetailsEventIDReturnValue: Result<InReplyToDetails, TimelineProxyError>! {
        get {
            if Thread.isMainThread {
                return getLoadedReplyDetailsEventIDUnderlyingReturnValue
            } else {
                var returnValue: Result<InReplyToDetails, TimelineProxyError>? = nil
                DispatchQueue.main.sync {
                    returnValue = getLoadedReplyDetailsEventIDUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getLoadedReplyDetailsEventIDUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getLoadedReplyDetailsEventIDUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var getLoadedReplyDetailsEventIDClosure: ((String) async -> Result<InReplyToDetails, TimelineProxyError>)?

    func getLoadedReplyDetails(eventID: String) async -> Result<InReplyToDetails, TimelineProxyError> {
        getLoadedReplyDetailsEventIDCallsCount += 1
        getLoadedReplyDetailsEventIDReceivedEventID = eventID
        DispatchQueue.main.async {
            self.getLoadedReplyDetailsEventIDReceivedInvocations.append(eventID)
        }
        if let getLoadedReplyDetailsEventIDClosure = getLoadedReplyDetailsEventIDClosure {
            return await getLoadedReplyDetailsEventIDClosure(eventID)
        } else {
            return getLoadedReplyDetailsEventIDReturnValue
        }
    }
    //MARK: - buildMessageContentFor

    var buildMessageContentForHtmlIntentionalMentionsUnderlyingCallsCount = 0
    var buildMessageContentForHtmlIntentionalMentionsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return buildMessageContentForHtmlIntentionalMentionsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = buildMessageContentForHtmlIntentionalMentionsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                buildMessageContentForHtmlIntentionalMentionsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    buildMessageContentForHtmlIntentionalMentionsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var buildMessageContentForHtmlIntentionalMentionsCalled: Bool {
        return buildMessageContentForHtmlIntentionalMentionsCallsCount > 0
    }
    var buildMessageContentForHtmlIntentionalMentionsReceivedArguments: (message: String, html: String?, intentionalMentions: Mentions)?
    var buildMessageContentForHtmlIntentionalMentionsReceivedInvocations: [(message: String, html: String?, intentionalMentions: Mentions)] = []

    var buildMessageContentForHtmlIntentionalMentionsUnderlyingReturnValue: RoomMessageEventContentWithoutRelation!
    var buildMessageContentForHtmlIntentionalMentionsReturnValue: RoomMessageEventContentWithoutRelation! {
        get {
            if Thread.isMainThread {
                return buildMessageContentForHtmlIntentionalMentionsUnderlyingReturnValue
            } else {
                var returnValue: RoomMessageEventContentWithoutRelation? = nil
                DispatchQueue.main.sync {
                    returnValue = buildMessageContentForHtmlIntentionalMentionsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                buildMessageContentForHtmlIntentionalMentionsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    buildMessageContentForHtmlIntentionalMentionsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var buildMessageContentForHtmlIntentionalMentionsClosure: ((String, String?, Mentions) -> RoomMessageEventContentWithoutRelation)?

    func buildMessageContentFor(_ message: String, html: String?, intentionalMentions: Mentions) -> RoomMessageEventContentWithoutRelation {
        buildMessageContentForHtmlIntentionalMentionsCallsCount += 1
        buildMessageContentForHtmlIntentionalMentionsReceivedArguments = (message: message, html: html, intentionalMentions: intentionalMentions)
        DispatchQueue.main.async {
            self.buildMessageContentForHtmlIntentionalMentionsReceivedInvocations.append((message: message, html: html, intentionalMentions: intentionalMentions))
        }
        if let buildMessageContentForHtmlIntentionalMentionsClosure = buildMessageContentForHtmlIntentionalMentionsClosure {
            return buildMessageContentForHtmlIntentionalMentionsClosure(message, html, intentionalMentions)
        } else {
            return buildMessageContentForHtmlIntentionalMentionsReturnValue
        }
    }
}
class UserDiscoveryServiceMock: UserDiscoveryServiceProtocol {

    //MARK: - searchProfiles

    var searchProfilesWithUnderlyingCallsCount = 0
    var searchProfilesWithCallsCount: Int {
        get {
            if Thread.isMainThread {
                return searchProfilesWithUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = searchProfilesWithUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                searchProfilesWithUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    searchProfilesWithUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var searchProfilesWithCalled: Bool {
        return searchProfilesWithCallsCount > 0
    }
    var searchProfilesWithReceivedSearchQuery: String?
    var searchProfilesWithReceivedInvocations: [String] = []

    var searchProfilesWithUnderlyingReturnValue: Result<[UserProfileProxy], UserDiscoveryErrorType>!
    var searchProfilesWithReturnValue: Result<[UserProfileProxy], UserDiscoveryErrorType>! {
        get {
            if Thread.isMainThread {
                return searchProfilesWithUnderlyingReturnValue
            } else {
                var returnValue: Result<[UserProfileProxy], UserDiscoveryErrorType>? = nil
                DispatchQueue.main.sync {
                    returnValue = searchProfilesWithUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                searchProfilesWithUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    searchProfilesWithUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var searchProfilesWithClosure: ((String) async -> Result<[UserProfileProxy], UserDiscoveryErrorType>)?

    func searchProfiles(with searchQuery: String) async -> Result<[UserProfileProxy], UserDiscoveryErrorType> {
        searchProfilesWithCallsCount += 1
        searchProfilesWithReceivedSearchQuery = searchQuery
        DispatchQueue.main.async {
            self.searchProfilesWithReceivedInvocations.append(searchQuery)
        }
        if let searchProfilesWithClosure = searchProfilesWithClosure {
            return await searchProfilesWithClosure(searchQuery)
        } else {
            return searchProfilesWithReturnValue
        }
    }
}
class UserIndicatorControllerMock: UserIndicatorControllerProtocol {
    var window: UIWindow?
    var alertInfo: AlertInfo<UUID>?

    //MARK: - submitIndicator

    var submitIndicatorDelayUnderlyingCallsCount = 0
    var submitIndicatorDelayCallsCount: Int {
        get {
            if Thread.isMainThread {
                return submitIndicatorDelayUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = submitIndicatorDelayUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                submitIndicatorDelayUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    submitIndicatorDelayUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var submitIndicatorDelayCalled: Bool {
        return submitIndicatorDelayCallsCount > 0
    }
    var submitIndicatorDelayReceivedArguments: (indicator: UserIndicator, delay: Duration?)?
    var submitIndicatorDelayReceivedInvocations: [(indicator: UserIndicator, delay: Duration?)] = []
    var submitIndicatorDelayClosure: ((UserIndicator, Duration?) -> Void)?

    func submitIndicator(_ indicator: UserIndicator, delay: Duration?) {
        submitIndicatorDelayCallsCount += 1
        submitIndicatorDelayReceivedArguments = (indicator: indicator, delay: delay)
        DispatchQueue.main.async {
            self.submitIndicatorDelayReceivedInvocations.append((indicator: indicator, delay: delay))
        }
        submitIndicatorDelayClosure?(indicator, delay)
    }
    //MARK: - retractIndicatorWithId

    var retractIndicatorWithIdUnderlyingCallsCount = 0
    var retractIndicatorWithIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return retractIndicatorWithIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = retractIndicatorWithIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                retractIndicatorWithIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    retractIndicatorWithIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var retractIndicatorWithIdCalled: Bool {
        return retractIndicatorWithIdCallsCount > 0
    }
    var retractIndicatorWithIdReceivedId: String?
    var retractIndicatorWithIdReceivedInvocations: [String] = []
    var retractIndicatorWithIdClosure: ((String) -> Void)?

    func retractIndicatorWithId(_ id: String) {
        retractIndicatorWithIdCallsCount += 1
        retractIndicatorWithIdReceivedId = id
        DispatchQueue.main.async {
            self.retractIndicatorWithIdReceivedInvocations.append(id)
        }
        retractIndicatorWithIdClosure?(id)
    }
    //MARK: - retractAllIndicators

    var retractAllIndicatorsUnderlyingCallsCount = 0
    var retractAllIndicatorsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return retractAllIndicatorsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = retractAllIndicatorsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                retractAllIndicatorsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    retractAllIndicatorsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var retractAllIndicatorsCalled: Bool {
        return retractAllIndicatorsCallsCount > 0
    }
    var retractAllIndicatorsClosure: (() -> Void)?

    func retractAllIndicators() {
        retractAllIndicatorsCallsCount += 1
        retractAllIndicatorsClosure?()
    }
    //MARK: - start

    var startUnderlyingCallsCount = 0
    var startCallsCount: Int {
        get {
            if Thread.isMainThread {
                return startUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = startUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    startUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var startCalled: Bool {
        return startCallsCount > 0
    }
    var startClosure: (() -> Void)?

    func start() {
        startCallsCount += 1
        startClosure?()
    }
    //MARK: - stop

    var stopUnderlyingCallsCount = 0
    var stopCallsCount: Int {
        get {
            if Thread.isMainThread {
                return stopUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = stopUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stopUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    stopUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCount += 1
        stopClosure?()
    }
    //MARK: - toPresentable

    var toPresentableUnderlyingCallsCount = 0
    var toPresentableCallsCount: Int {
        get {
            if Thread.isMainThread {
                return toPresentableUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = toPresentableUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                toPresentableUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    toPresentableUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var toPresentableCalled: Bool {
        return toPresentableCallsCount > 0
    }

    var toPresentableUnderlyingReturnValue: AnyView!
    var toPresentableReturnValue: AnyView! {
        get {
            if Thread.isMainThread {
                return toPresentableUnderlyingReturnValue
            } else {
                var returnValue: AnyView? = nil
                DispatchQueue.main.sync {
                    returnValue = toPresentableUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                toPresentableUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    toPresentableUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var toPresentableClosure: (() -> AnyView)?

    func toPresentable() -> AnyView {
        toPresentableCallsCount += 1
        if let toPresentableClosure = toPresentableClosure {
            return toPresentableClosure()
        } else {
            return toPresentableReturnValue
        }
    }
}
class UserNotificationCenterMock: UserNotificationCenterProtocol {
    weak var delegate: UNUserNotificationCenterDelegate?

    //MARK: - add

    var addThrowableError: Error?
    var addUnderlyingCallsCount = 0
    var addCallsCount: Int {
        get {
            if Thread.isMainThread {
                return addUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = addUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                addUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    addUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var addCalled: Bool {
        return addCallsCount > 0
    }
    var addReceivedRequest: UNNotificationRequest?
    var addReceivedInvocations: [UNNotificationRequest] = []
    var addClosure: ((UNNotificationRequest) async throws -> Void)?

    func add(_ request: UNNotificationRequest) async throws {
        if let error = addThrowableError {
            throw error
        }
        addCallsCount += 1
        addReceivedRequest = request
        DispatchQueue.main.async {
            self.addReceivedInvocations.append(request)
        }
        try await addClosure?(request)
    }
    //MARK: - requestAuthorization

    var requestAuthorizationOptionsThrowableError: Error?
    var requestAuthorizationOptionsUnderlyingCallsCount = 0
    var requestAuthorizationOptionsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return requestAuthorizationOptionsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = requestAuthorizationOptionsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                requestAuthorizationOptionsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    requestAuthorizationOptionsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var requestAuthorizationOptionsCalled: Bool {
        return requestAuthorizationOptionsCallsCount > 0
    }
    var requestAuthorizationOptionsReceivedOptions: UNAuthorizationOptions?
    var requestAuthorizationOptionsReceivedInvocations: [UNAuthorizationOptions] = []

    var requestAuthorizationOptionsUnderlyingReturnValue: Bool!
    var requestAuthorizationOptionsReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return requestAuthorizationOptionsUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = requestAuthorizationOptionsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                requestAuthorizationOptionsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    requestAuthorizationOptionsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var requestAuthorizationOptionsClosure: ((UNAuthorizationOptions) async throws -> Bool)?

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        if let error = requestAuthorizationOptionsThrowableError {
            throw error
        }
        requestAuthorizationOptionsCallsCount += 1
        requestAuthorizationOptionsReceivedOptions = options
        DispatchQueue.main.async {
            self.requestAuthorizationOptionsReceivedInvocations.append(options)
        }
        if let requestAuthorizationOptionsClosure = requestAuthorizationOptionsClosure {
            return try await requestAuthorizationOptionsClosure(options)
        } else {
            return requestAuthorizationOptionsReturnValue
        }
    }
    //MARK: - deliveredNotifications

    var deliveredNotificationsUnderlyingCallsCount = 0
    var deliveredNotificationsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return deliveredNotificationsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = deliveredNotificationsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                deliveredNotificationsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    deliveredNotificationsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var deliveredNotificationsCalled: Bool {
        return deliveredNotificationsCallsCount > 0
    }

    var deliveredNotificationsUnderlyingReturnValue: [UNNotification]!
    var deliveredNotificationsReturnValue: [UNNotification]! {
        get {
            if Thread.isMainThread {
                return deliveredNotificationsUnderlyingReturnValue
            } else {
                var returnValue: [UNNotification]? = nil
                DispatchQueue.main.sync {
                    returnValue = deliveredNotificationsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                deliveredNotificationsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    deliveredNotificationsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var deliveredNotificationsClosure: (() async -> [UNNotification])?

    func deliveredNotifications() async -> [UNNotification] {
        deliveredNotificationsCallsCount += 1
        if let deliveredNotificationsClosure = deliveredNotificationsClosure {
            return await deliveredNotificationsClosure()
        } else {
            return deliveredNotificationsReturnValue
        }
    }
    //MARK: - removeDeliveredNotifications

    var removeDeliveredNotificationsWithIdentifiersUnderlyingCallsCount = 0
    var removeDeliveredNotificationsWithIdentifiersCallsCount: Int {
        get {
            if Thread.isMainThread {
                return removeDeliveredNotificationsWithIdentifiersUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = removeDeliveredNotificationsWithIdentifiersUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removeDeliveredNotificationsWithIdentifiersUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    removeDeliveredNotificationsWithIdentifiersUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var removeDeliveredNotificationsWithIdentifiersCalled: Bool {
        return removeDeliveredNotificationsWithIdentifiersCallsCount > 0
    }
    var removeDeliveredNotificationsWithIdentifiersReceivedIdentifiers: [String]?
    var removeDeliveredNotificationsWithIdentifiersReceivedInvocations: [[String]] = []
    var removeDeliveredNotificationsWithIdentifiersClosure: (([String]) -> Void)?

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removeDeliveredNotificationsWithIdentifiersCallsCount += 1
        removeDeliveredNotificationsWithIdentifiersReceivedIdentifiers = identifiers
        DispatchQueue.main.async {
            self.removeDeliveredNotificationsWithIdentifiersReceivedInvocations.append(identifiers)
        }
        removeDeliveredNotificationsWithIdentifiersClosure?(identifiers)
    }
    //MARK: - setNotificationCategories

    var setNotificationCategoriesUnderlyingCallsCount = 0
    var setNotificationCategoriesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setNotificationCategoriesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setNotificationCategoriesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setNotificationCategoriesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setNotificationCategoriesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setNotificationCategoriesCalled: Bool {
        return setNotificationCategoriesCallsCount > 0
    }
    var setNotificationCategoriesReceivedCategories: Set<UNNotificationCategory>?
    var setNotificationCategoriesReceivedInvocations: [Set<UNNotificationCategory>] = []
    var setNotificationCategoriesClosure: ((Set<UNNotificationCategory>) -> Void)?

    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        setNotificationCategoriesCallsCount += 1
        setNotificationCategoriesReceivedCategories = categories
        DispatchQueue.main.async {
            self.setNotificationCategoriesReceivedInvocations.append(categories)
        }
        setNotificationCategoriesClosure?(categories)
    }
    //MARK: - authorizationStatus

    var authorizationStatusUnderlyingCallsCount = 0
    var authorizationStatusCallsCount: Int {
        get {
            if Thread.isMainThread {
                return authorizationStatusUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = authorizationStatusUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                authorizationStatusUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    authorizationStatusUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var authorizationStatusCalled: Bool {
        return authorizationStatusCallsCount > 0
    }

    var authorizationStatusUnderlyingReturnValue: UNAuthorizationStatus!
    var authorizationStatusReturnValue: UNAuthorizationStatus! {
        get {
            if Thread.isMainThread {
                return authorizationStatusUnderlyingReturnValue
            } else {
                var returnValue: UNAuthorizationStatus? = nil
                DispatchQueue.main.sync {
                    returnValue = authorizationStatusUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                authorizationStatusUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    authorizationStatusUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var authorizationStatusClosure: (() async -> UNAuthorizationStatus)?

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatusCallsCount += 1
        if let authorizationStatusClosure = authorizationStatusClosure {
            return await authorizationStatusClosure()
        } else {
            return authorizationStatusReturnValue
        }
    }
}
class UserSessionMock: UserSessionProtocol {
    var clientProxy: ClientProxyProtocol {
        get { return underlyingClientProxy }
        set(value) { underlyingClientProxy = value }
    }
    var underlyingClientProxy: ClientProxyProtocol!
    var mediaProvider: MediaProviderProtocol {
        get { return underlyingMediaProvider }
        set(value) { underlyingMediaProvider = value }
    }
    var underlyingMediaProvider: MediaProviderProtocol!
    var voiceMessageMediaManager: VoiceMessageMediaManagerProtocol {
        get { return underlyingVoiceMessageMediaManager }
        set(value) { underlyingVoiceMessageMediaManager = value }
    }
    var underlyingVoiceMessageMediaManager: VoiceMessageMediaManagerProtocol!
    var sessionSecurityStatePublisher: CurrentValuePublisher<SessionSecurityState, Never> {
        get { return underlyingSessionSecurityStatePublisher }
        set(value) { underlyingSessionSecurityStatePublisher = value }
    }
    var underlyingSessionSecurityStatePublisher: CurrentValuePublisher<SessionSecurityState, Never>!
    var callbacks: PassthroughSubject<UserSessionCallback, Never> {
        get { return underlyingCallbacks }
        set(value) { underlyingCallbacks = value }
    }
    var underlyingCallbacks: PassthroughSubject<UserSessionCallback, Never>!

}
class VoiceMessageCacheMock: VoiceMessageCacheProtocol {
    var urlForRecording: URL {
        get { return underlyingUrlForRecording }
        set(value) { underlyingUrlForRecording = value }
    }
    var underlyingUrlForRecording: URL!

    //MARK: - fileURL

    var fileURLForUnderlyingCallsCount = 0
    var fileURLForCallsCount: Int {
        get {
            if Thread.isMainThread {
                return fileURLForUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = fileURLForUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                fileURLForUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    fileURLForUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var fileURLForCalled: Bool {
        return fileURLForCallsCount > 0
    }
    var fileURLForReceivedMediaSource: MediaSourceProxy?
    var fileURLForReceivedInvocations: [MediaSourceProxy] = []

    var fileURLForUnderlyingReturnValue: URL?
    var fileURLForReturnValue: URL? {
        get {
            if Thread.isMainThread {
                return fileURLForUnderlyingReturnValue
            } else {
                var returnValue: URL?? = nil
                DispatchQueue.main.sync {
                    returnValue = fileURLForUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                fileURLForUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    fileURLForUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var fileURLForClosure: ((MediaSourceProxy) -> URL?)?

    func fileURL(for mediaSource: MediaSourceProxy) -> URL? {
        fileURLForCallsCount += 1
        fileURLForReceivedMediaSource = mediaSource
        DispatchQueue.main.async {
            self.fileURLForReceivedInvocations.append(mediaSource)
        }
        if let fileURLForClosure = fileURLForClosure {
            return fileURLForClosure(mediaSource)
        } else {
            return fileURLForReturnValue
        }
    }
    //MARK: - cache

    var cacheMediaSourceUsingMoveUnderlyingCallsCount = 0
    var cacheMediaSourceUsingMoveCallsCount: Int {
        get {
            if Thread.isMainThread {
                return cacheMediaSourceUsingMoveUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = cacheMediaSourceUsingMoveUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                cacheMediaSourceUsingMoveUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    cacheMediaSourceUsingMoveUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var cacheMediaSourceUsingMoveCalled: Bool {
        return cacheMediaSourceUsingMoveCallsCount > 0
    }
    var cacheMediaSourceUsingMoveReceivedArguments: (mediaSource: MediaSourceProxy, fileURL: URL, move: Bool)?
    var cacheMediaSourceUsingMoveReceivedInvocations: [(mediaSource: MediaSourceProxy, fileURL: URL, move: Bool)] = []

    var cacheMediaSourceUsingMoveUnderlyingReturnValue: Result<URL, VoiceMessageCacheError>!
    var cacheMediaSourceUsingMoveReturnValue: Result<URL, VoiceMessageCacheError>! {
        get {
            if Thread.isMainThread {
                return cacheMediaSourceUsingMoveUnderlyingReturnValue
            } else {
                var returnValue: Result<URL, VoiceMessageCacheError>? = nil
                DispatchQueue.main.sync {
                    returnValue = cacheMediaSourceUsingMoveUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                cacheMediaSourceUsingMoveUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    cacheMediaSourceUsingMoveUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var cacheMediaSourceUsingMoveClosure: ((MediaSourceProxy, URL, Bool) -> Result<URL, VoiceMessageCacheError>)?

    func cache(mediaSource: MediaSourceProxy, using fileURL: URL, move: Bool) -> Result<URL, VoiceMessageCacheError> {
        cacheMediaSourceUsingMoveCallsCount += 1
        cacheMediaSourceUsingMoveReceivedArguments = (mediaSource: mediaSource, fileURL: fileURL, move: move)
        DispatchQueue.main.async {
            self.cacheMediaSourceUsingMoveReceivedInvocations.append((mediaSource: mediaSource, fileURL: fileURL, move: move))
        }
        if let cacheMediaSourceUsingMoveClosure = cacheMediaSourceUsingMoveClosure {
            return cacheMediaSourceUsingMoveClosure(mediaSource, fileURL, move)
        } else {
            return cacheMediaSourceUsingMoveReturnValue
        }
    }
    //MARK: - clearCache

    var clearCacheUnderlyingCallsCount = 0
    var clearCacheCallsCount: Int {
        get {
            if Thread.isMainThread {
                return clearCacheUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = clearCacheUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                clearCacheUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    clearCacheUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var clearCacheCalled: Bool {
        return clearCacheCallsCount > 0
    }
    var clearCacheClosure: (() -> Void)?

    func clearCache() {
        clearCacheCallsCount += 1
        clearCacheClosure?()
    }
}
class VoiceMessageMediaManagerMock: VoiceMessageMediaManagerProtocol {

    //MARK: - loadVoiceMessageFromSource

    var loadVoiceMessageFromSourceBodyThrowableError: Error?
    var loadVoiceMessageFromSourceBodyUnderlyingCallsCount = 0
    var loadVoiceMessageFromSourceBodyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadVoiceMessageFromSourceBodyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadVoiceMessageFromSourceBodyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadVoiceMessageFromSourceBodyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadVoiceMessageFromSourceBodyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var loadVoiceMessageFromSourceBodyCalled: Bool {
        return loadVoiceMessageFromSourceBodyCallsCount > 0
    }
    var loadVoiceMessageFromSourceBodyReceivedArguments: (source: MediaSourceProxy, body: String?)?
    var loadVoiceMessageFromSourceBodyReceivedInvocations: [(source: MediaSourceProxy, body: String?)] = []

    var loadVoiceMessageFromSourceBodyUnderlyingReturnValue: URL!
    var loadVoiceMessageFromSourceBodyReturnValue: URL! {
        get {
            if Thread.isMainThread {
                return loadVoiceMessageFromSourceBodyUnderlyingReturnValue
            } else {
                var returnValue: URL? = nil
                DispatchQueue.main.sync {
                    returnValue = loadVoiceMessageFromSourceBodyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadVoiceMessageFromSourceBodyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadVoiceMessageFromSourceBodyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var loadVoiceMessageFromSourceBodyClosure: ((MediaSourceProxy, String?) async throws -> URL)?

    func loadVoiceMessageFromSource(_ source: MediaSourceProxy, body: String?) async throws -> URL {
        if let error = loadVoiceMessageFromSourceBodyThrowableError {
            throw error
        }
        loadVoiceMessageFromSourceBodyCallsCount += 1
        loadVoiceMessageFromSourceBodyReceivedArguments = (source: source, body: body)
        DispatchQueue.main.async {
            self.loadVoiceMessageFromSourceBodyReceivedInvocations.append((source: source, body: body))
        }
        if let loadVoiceMessageFromSourceBodyClosure = loadVoiceMessageFromSourceBodyClosure {
            return try await loadVoiceMessageFromSourceBodyClosure(source, body)
        } else {
            return loadVoiceMessageFromSourceBodyReturnValue
        }
    }
}
class VoiceMessageRecorderMock: VoiceMessageRecorderProtocol {
    var previewAudioPlayerState: AudioPlayerState?
    var isRecording: Bool {
        get { return underlyingIsRecording }
        set(value) { underlyingIsRecording = value }
    }
    var underlyingIsRecording: Bool!
    var recordingURL: URL?
    var actions: AnyPublisher<VoiceMessageRecorderAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<VoiceMessageRecorderAction, Never>!

    //MARK: - startRecording

    var startRecordingUnderlyingCallsCount = 0
    var startRecordingCallsCount: Int {
        get {
            if Thread.isMainThread {
                return startRecordingUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = startRecordingUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startRecordingUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    startRecordingUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var startRecordingCalled: Bool {
        return startRecordingCallsCount > 0
    }
    var startRecordingClosure: (() async -> Void)?

    func startRecording() async {
        startRecordingCallsCount += 1
        await startRecordingClosure?()
    }
    //MARK: - stopRecording

    var stopRecordingUnderlyingCallsCount = 0
    var stopRecordingCallsCount: Int {
        get {
            if Thread.isMainThread {
                return stopRecordingUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = stopRecordingUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stopRecordingUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    stopRecordingUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var stopRecordingCalled: Bool {
        return stopRecordingCallsCount > 0
    }
    var stopRecordingClosure: (() async -> Void)?

    func stopRecording() async {
        stopRecordingCallsCount += 1
        await stopRecordingClosure?()
    }
    //MARK: - cancelRecording

    var cancelRecordingUnderlyingCallsCount = 0
    var cancelRecordingCallsCount: Int {
        get {
            if Thread.isMainThread {
                return cancelRecordingUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = cancelRecordingUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                cancelRecordingUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    cancelRecordingUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var cancelRecordingCalled: Bool {
        return cancelRecordingCallsCount > 0
    }
    var cancelRecordingClosure: (() async -> Void)?

    func cancelRecording() async {
        cancelRecordingCallsCount += 1
        await cancelRecordingClosure?()
    }
    //MARK: - startPlayback

    var startPlaybackUnderlyingCallsCount = 0
    var startPlaybackCallsCount: Int {
        get {
            if Thread.isMainThread {
                return startPlaybackUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = startPlaybackUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startPlaybackUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    startPlaybackUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var startPlaybackCalled: Bool {
        return startPlaybackCallsCount > 0
    }

    var startPlaybackUnderlyingReturnValue: Result<Void, VoiceMessageRecorderError>!
    var startPlaybackReturnValue: Result<Void, VoiceMessageRecorderError>! {
        get {
            if Thread.isMainThread {
                return startPlaybackUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, VoiceMessageRecorderError>? = nil
                DispatchQueue.main.sync {
                    returnValue = startPlaybackUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startPlaybackUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    startPlaybackUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var startPlaybackClosure: (() async -> Result<Void, VoiceMessageRecorderError>)?

    func startPlayback() async -> Result<Void, VoiceMessageRecorderError> {
        startPlaybackCallsCount += 1
        if let startPlaybackClosure = startPlaybackClosure {
            return await startPlaybackClosure()
        } else {
            return startPlaybackReturnValue
        }
    }
    //MARK: - pausePlayback

    var pausePlaybackUnderlyingCallsCount = 0
    var pausePlaybackCallsCount: Int {
        get {
            if Thread.isMainThread {
                return pausePlaybackUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = pausePlaybackUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pausePlaybackUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    pausePlaybackUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var pausePlaybackCalled: Bool {
        return pausePlaybackCallsCount > 0
    }
    var pausePlaybackClosure: (() -> Void)?

    func pausePlayback() {
        pausePlaybackCallsCount += 1
        pausePlaybackClosure?()
    }
    //MARK: - stopPlayback

    var stopPlaybackUnderlyingCallsCount = 0
    var stopPlaybackCallsCount: Int {
        get {
            if Thread.isMainThread {
                return stopPlaybackUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = stopPlaybackUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stopPlaybackUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    stopPlaybackUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var stopPlaybackCalled: Bool {
        return stopPlaybackCallsCount > 0
    }
    var stopPlaybackClosure: (() async -> Void)?

    func stopPlayback() async {
        stopPlaybackCallsCount += 1
        await stopPlaybackClosure?()
    }
    //MARK: - seekPlayback

    var seekPlaybackToUnderlyingCallsCount = 0
    var seekPlaybackToCallsCount: Int {
        get {
            if Thread.isMainThread {
                return seekPlaybackToUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = seekPlaybackToUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                seekPlaybackToUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    seekPlaybackToUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var seekPlaybackToCalled: Bool {
        return seekPlaybackToCallsCount > 0
    }
    var seekPlaybackToReceivedProgress: Double?
    var seekPlaybackToReceivedInvocations: [Double] = []
    var seekPlaybackToClosure: ((Double) async -> Void)?

    func seekPlayback(to progress: Double) async {
        seekPlaybackToCallsCount += 1
        seekPlaybackToReceivedProgress = progress
        DispatchQueue.main.async {
            self.seekPlaybackToReceivedInvocations.append(progress)
        }
        await seekPlaybackToClosure?(progress)
    }
    //MARK: - deleteRecording

    var deleteRecordingUnderlyingCallsCount = 0
    var deleteRecordingCallsCount: Int {
        get {
            if Thread.isMainThread {
                return deleteRecordingUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = deleteRecordingUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                deleteRecordingUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    deleteRecordingUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var deleteRecordingCalled: Bool {
        return deleteRecordingCallsCount > 0
    }
    var deleteRecordingClosure: (() async -> Void)?

    func deleteRecording() async {
        deleteRecordingCallsCount += 1
        await deleteRecordingClosure?()
    }
    //MARK: - sendVoiceMessage

    var sendVoiceMessageInRoomAudioConverterUnderlyingCallsCount = 0
    var sendVoiceMessageInRoomAudioConverterCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendVoiceMessageInRoomAudioConverterUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendVoiceMessageInRoomAudioConverterUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendVoiceMessageInRoomAudioConverterUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendVoiceMessageInRoomAudioConverterUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var sendVoiceMessageInRoomAudioConverterCalled: Bool {
        return sendVoiceMessageInRoomAudioConverterCallsCount > 0
    }
    var sendVoiceMessageInRoomAudioConverterReceivedArguments: (roomProxy: JoinedRoomProxyProtocol, audioConverter: AudioConverterProtocol)?
    var sendVoiceMessageInRoomAudioConverterReceivedInvocations: [(roomProxy: JoinedRoomProxyProtocol, audioConverter: AudioConverterProtocol)] = []

    var sendVoiceMessageInRoomAudioConverterUnderlyingReturnValue: Result<Void, VoiceMessageRecorderError>!
    var sendVoiceMessageInRoomAudioConverterReturnValue: Result<Void, VoiceMessageRecorderError>! {
        get {
            if Thread.isMainThread {
                return sendVoiceMessageInRoomAudioConverterUnderlyingReturnValue
            } else {
                var returnValue: Result<Void, VoiceMessageRecorderError>? = nil
                DispatchQueue.main.sync {
                    returnValue = sendVoiceMessageInRoomAudioConverterUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendVoiceMessageInRoomAudioConverterUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendVoiceMessageInRoomAudioConverterUnderlyingReturnValue = newValue
                }
            }
        }
    }
    var sendVoiceMessageInRoomAudioConverterClosure: ((JoinedRoomProxyProtocol, AudioConverterProtocol) async -> Result<Void, VoiceMessageRecorderError>)?

    func sendVoiceMessage(inRoom roomProxy: JoinedRoomProxyProtocol, audioConverter: AudioConverterProtocol) async -> Result<Void, VoiceMessageRecorderError> {
        sendVoiceMessageInRoomAudioConverterCallsCount += 1
        sendVoiceMessageInRoomAudioConverterReceivedArguments = (roomProxy: roomProxy, audioConverter: audioConverter)
        DispatchQueue.main.async {
            self.sendVoiceMessageInRoomAudioConverterReceivedInvocations.append((roomProxy: roomProxy, audioConverter: audioConverter))
        }
        if let sendVoiceMessageInRoomAudioConverterClosure = sendVoiceMessageInRoomAudioConverterClosure {
            return await sendVoiceMessageInRoomAudioConverterClosure(roomProxy, audioConverter)
        } else {
            return sendVoiceMessageInRoomAudioConverterReturnValue
        }
    }
}
class WindowManagerMock: WindowManagerProtocol {
    var mainWindow: UIWindow!
    var overlayWindow: UIWindow!
    var globalSearchWindow: UIWindow!
    var alternateWindow: UIWindow!
    var windows: [UIWindow] = []

    //MARK: - showGlobalSearch

    var showGlobalSearchUnderlyingCallsCount = 0
    var showGlobalSearchCallsCount: Int {
        get {
            if Thread.isMainThread {
                return showGlobalSearchUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = showGlobalSearchUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                showGlobalSearchUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    showGlobalSearchUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var showGlobalSearchCalled: Bool {
        return showGlobalSearchCallsCount > 0
    }
    var showGlobalSearchClosure: (() -> Void)?

    func showGlobalSearch() {
        showGlobalSearchCallsCount += 1
        showGlobalSearchClosure?()
    }
    //MARK: - hideGlobalSearch

    var hideGlobalSearchUnderlyingCallsCount = 0
    var hideGlobalSearchCallsCount: Int {
        get {
            if Thread.isMainThread {
                return hideGlobalSearchUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = hideGlobalSearchUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                hideGlobalSearchUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    hideGlobalSearchUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var hideGlobalSearchCalled: Bool {
        return hideGlobalSearchCallsCount > 0
    }
    var hideGlobalSearchClosure: (() -> Void)?

    func hideGlobalSearch() {
        hideGlobalSearchCallsCount += 1
        hideGlobalSearchClosure?()
    }
    //MARK: - setOrientation

    var setOrientationUnderlyingCallsCount = 0
    var setOrientationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setOrientationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setOrientationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setOrientationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setOrientationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var setOrientationCalled: Bool {
        return setOrientationCallsCount > 0
    }
    var setOrientationReceivedOrientation: UIInterfaceOrientationMask?
    var setOrientationReceivedInvocations: [UIInterfaceOrientationMask] = []
    var setOrientationClosure: ((UIInterfaceOrientationMask) -> Void)?

    func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        setOrientationCallsCount += 1
        setOrientationReceivedOrientation = orientation
        DispatchQueue.main.async {
            self.setOrientationReceivedInvocations.append(orientation)
        }
        setOrientationClosure?(orientation)
    }
    //MARK: - lockOrientation

    var lockOrientationUnderlyingCallsCount = 0
    var lockOrientationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return lockOrientationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = lockOrientationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                lockOrientationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    lockOrientationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var lockOrientationCalled: Bool {
        return lockOrientationCallsCount > 0
    }
    var lockOrientationReceivedOrientation: UIInterfaceOrientationMask?
    var lockOrientationReceivedInvocations: [UIInterfaceOrientationMask] = []
    var lockOrientationClosure: ((UIInterfaceOrientationMask) -> Void)?

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        lockOrientationCallsCount += 1
        lockOrientationReceivedOrientation = orientation
        DispatchQueue.main.async {
            self.lockOrientationReceivedInvocations.append(orientation)
        }
        lockOrientationClosure?(orientation)
    }
}
// swiftlint:enable all
