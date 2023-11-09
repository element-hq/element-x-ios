// Generated using Sourcery 2.1.1 — https://github.com/krzysztofzablocki/Sourcery
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

    var startAnalyticsConfigurationCallsCount = 0
    var startAnalyticsConfigurationCalled: Bool {
        return startAnalyticsConfigurationCallsCount > 0
    }
    var startAnalyticsConfigurationReceivedAnalyticsConfiguration: AnalyticsConfiguration?
    var startAnalyticsConfigurationReceivedInvocations: [AnalyticsConfiguration] = []
    var startAnalyticsConfigurationClosure: ((AnalyticsConfiguration) -> Void)?

    func start(analyticsConfiguration: AnalyticsConfiguration) {
        startAnalyticsConfigurationCallsCount += 1
        startAnalyticsConfigurationReceivedAnalyticsConfiguration = analyticsConfiguration
        startAnalyticsConfigurationReceivedInvocations.append(analyticsConfiguration)
        startAnalyticsConfigurationClosure?(analyticsConfiguration)
    }
    //MARK: - reset

    var resetCallsCount = 0
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCount += 1
        resetClosure?()
    }
    //MARK: - stop

    var stopCallsCount = 0
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCount += 1
        stopClosure?()
    }
    //MARK: - flush

    var flushCallsCount = 0
    var flushCalled: Bool {
        return flushCallsCount > 0
    }
    var flushClosure: (() -> Void)?

    func flush() {
        flushCallsCount += 1
        flushClosure?()
    }
    //MARK: - capture

    var captureCallsCount = 0
    var captureCalled: Bool {
        return captureCallsCount > 0
    }
    var captureReceivedEvent: AnalyticsEventProtocol?
    var captureReceivedInvocations: [AnalyticsEventProtocol] = []
    var captureClosure: ((AnalyticsEventProtocol) -> Void)?

    func capture(_ event: AnalyticsEventProtocol) {
        captureCallsCount += 1
        captureReceivedEvent = event
        captureReceivedInvocations.append(event)
        captureClosure?(event)
    }
    //MARK: - screen

    var screenCallsCount = 0
    var screenCalled: Bool {
        return screenCallsCount > 0
    }
    var screenReceivedEvent: AnalyticsScreenProtocol?
    var screenReceivedInvocations: [AnalyticsScreenProtocol] = []
    var screenClosure: ((AnalyticsScreenProtocol) -> Void)?

    func screen(_ event: AnalyticsScreenProtocol) {
        screenCallsCount += 1
        screenReceivedEvent = event
        screenReceivedInvocations.append(event)
        screenClosure?(event)
    }
    //MARK: - updateUserProperties

    var updateUserPropertiesCallsCount = 0
    var updateUserPropertiesCalled: Bool {
        return updateUserPropertiesCallsCount > 0
    }
    var updateUserPropertiesReceivedUserProperties: AnalyticsEvent.UserProperties?
    var updateUserPropertiesReceivedInvocations: [AnalyticsEvent.UserProperties] = []
    var updateUserPropertiesClosure: ((AnalyticsEvent.UserProperties) -> Void)?

    func updateUserProperties(_ userProperties: AnalyticsEvent.UserProperties) {
        updateUserPropertiesCallsCount += 1
        updateUserPropertiesReceivedUserProperties = userProperties
        updateUserPropertiesReceivedInvocations.append(userProperties)
        updateUserPropertiesClosure?(userProperties)
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
    var disabledPublisher: AnyPublisher<Void, Never> {
        get { return underlyingDisabledPublisher }
        set(value) { underlyingDisabledPublisher = value }
    }
    var underlyingDisabledPublisher: AnyPublisher<Void, Never>!
    var numberOfPINAttempts: AnyPublisher<Int, Never> {
        get { return underlyingNumberOfPINAttempts }
        set(value) { underlyingNumberOfPINAttempts = value }
    }
    var underlyingNumberOfPINAttempts: AnyPublisher<Int, Never>!

    //MARK: - setupPINCode

    var setupPINCodeCallsCount = 0
    var setupPINCodeCalled: Bool {
        return setupPINCodeCallsCount > 0
    }
    var setupPINCodeReceivedPinCode: String?
    var setupPINCodeReceivedInvocations: [String] = []
    var setupPINCodeReturnValue: Result<Void, AppLockServiceError>!
    var setupPINCodeClosure: ((String) -> Result<Void, AppLockServiceError>)?

    func setupPINCode(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        setupPINCodeCallsCount += 1
        setupPINCodeReceivedPinCode = pinCode
        setupPINCodeReceivedInvocations.append(pinCode)
        if let setupPINCodeClosure = setupPINCodeClosure {
            return setupPINCodeClosure(pinCode)
        } else {
            return setupPINCodeReturnValue
        }
    }
    //MARK: - validate

    var validateCallsCount = 0
    var validateCalled: Bool {
        return validateCallsCount > 0
    }
    var validateReceivedPinCode: String?
    var validateReceivedInvocations: [String] = []
    var validateReturnValue: Result<Void, AppLockServiceError>!
    var validateClosure: ((String) -> Result<Void, AppLockServiceError>)?

    func validate(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        validateCallsCount += 1
        validateReceivedPinCode = pinCode
        validateReceivedInvocations.append(pinCode)
        if let validateClosure = validateClosure {
            return validateClosure(pinCode)
        } else {
            return validateReturnValue
        }
    }
    //MARK: - enableBiometricUnlock

    var enableBiometricUnlockCallsCount = 0
    var enableBiometricUnlockCalled: Bool {
        return enableBiometricUnlockCallsCount > 0
    }
    var enableBiometricUnlockReturnValue: Result<Void, AppLockServiceError>!
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

    var disableBiometricUnlockCallsCount = 0
    var disableBiometricUnlockCalled: Bool {
        return disableBiometricUnlockCallsCount > 0
    }
    var disableBiometricUnlockClosure: (() -> Void)?

    func disableBiometricUnlock() {
        disableBiometricUnlockCallsCount += 1
        disableBiometricUnlockClosure?()
    }
    //MARK: - disable

    var disableCallsCount = 0
    var disableCalled: Bool {
        return disableCallsCount > 0
    }
    var disableClosure: (() -> Void)?

    func disable() {
        disableCallsCount += 1
        disableClosure?()
    }
    //MARK: - applicationDidEnterBackground

    var applicationDidEnterBackgroundCallsCount = 0
    var applicationDidEnterBackgroundCalled: Bool {
        return applicationDidEnterBackgroundCallsCount > 0
    }
    var applicationDidEnterBackgroundClosure: (() -> Void)?

    func applicationDidEnterBackground() {
        applicationDidEnterBackgroundCallsCount += 1
        applicationDidEnterBackgroundClosure?()
    }
    //MARK: - computeNeedsUnlock

    var computeNeedsUnlockWillEnterForegroundAtCallsCount = 0
    var computeNeedsUnlockWillEnterForegroundAtCalled: Bool {
        return computeNeedsUnlockWillEnterForegroundAtCallsCount > 0
    }
    var computeNeedsUnlockWillEnterForegroundAtReceivedDate: Date?
    var computeNeedsUnlockWillEnterForegroundAtReceivedInvocations: [Date] = []
    var computeNeedsUnlockWillEnterForegroundAtReturnValue: Bool!
    var computeNeedsUnlockWillEnterForegroundAtClosure: ((Date) -> Bool)?

    func computeNeedsUnlock(willEnterForegroundAt date: Date) -> Bool {
        computeNeedsUnlockWillEnterForegroundAtCallsCount += 1
        computeNeedsUnlockWillEnterForegroundAtReceivedDate = date
        computeNeedsUnlockWillEnterForegroundAtReceivedInvocations.append(date)
        if let computeNeedsUnlockWillEnterForegroundAtClosure = computeNeedsUnlockWillEnterForegroundAtClosure {
            return computeNeedsUnlockWillEnterForegroundAtClosure(date)
        } else {
            return computeNeedsUnlockWillEnterForegroundAtReturnValue
        }
    }
    //MARK: - unlock

    var unlockWithCallsCount = 0
    var unlockWithCalled: Bool {
        return unlockWithCallsCount > 0
    }
    var unlockWithReceivedPinCode: String?
    var unlockWithReceivedInvocations: [String] = []
    var unlockWithReturnValue: Bool!
    var unlockWithClosure: ((String) -> Bool)?

    func unlock(with pinCode: String) -> Bool {
        unlockWithCallsCount += 1
        unlockWithReceivedPinCode = pinCode
        unlockWithReceivedInvocations.append(pinCode)
        if let unlockWithClosure = unlockWithClosure {
            return unlockWithClosure(pinCode)
        } else {
            return unlockWithReturnValue
        }
    }
    //MARK: - unlockWithBiometrics

    var unlockWithBiometricsCallsCount = 0
    var unlockWithBiometricsCalled: Bool {
        return unlockWithBiometricsCallsCount > 0
    }
    var unlockWithBiometricsReturnValue: Bool!
    var unlockWithBiometricsClosure: (() async -> Bool)?

    func unlockWithBiometrics() async -> Bool {
        unlockWithBiometricsCallsCount += 1
        if let unlockWithBiometricsClosure = unlockWithBiometricsClosure {
            return await unlockWithBiometricsClosure()
        } else {
            return unlockWithBiometricsReturnValue
        }
    }
}
class ApplicationMock: ApplicationProtocol {
    var backgroundTimeRemaining: TimeInterval {
        get { return underlyingBackgroundTimeRemaining }
        set(value) { underlyingBackgroundTimeRemaining = value }
    }
    var underlyingBackgroundTimeRemaining: TimeInterval!
    var applicationState: UIApplication.State {
        get { return underlyingApplicationState }
        set(value) { underlyingApplicationState = value }
    }
    var underlyingApplicationState: UIApplication.State!

    //MARK: - beginBackgroundTask

    var beginBackgroundTaskExpirationHandlerCallsCount = 0
    var beginBackgroundTaskExpirationHandlerCalled: Bool {
        return beginBackgroundTaskExpirationHandlerCallsCount > 0
    }
    var beginBackgroundTaskExpirationHandlerReturnValue: UIBackgroundTaskIdentifier!
    var beginBackgroundTaskExpirationHandlerClosure: (((() -> Void)?) -> UIBackgroundTaskIdentifier)?

    func beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        beginBackgroundTaskExpirationHandlerCallsCount += 1
        if let beginBackgroundTaskExpirationHandlerClosure = beginBackgroundTaskExpirationHandlerClosure {
            return beginBackgroundTaskExpirationHandlerClosure(handler)
        } else {
            return beginBackgroundTaskExpirationHandlerReturnValue
        }
    }
    //MARK: - beginBackgroundTask

    var beginBackgroundTaskWithNameExpirationHandlerCallsCount = 0
    var beginBackgroundTaskWithNameExpirationHandlerCalled: Bool {
        return beginBackgroundTaskWithNameExpirationHandlerCallsCount > 0
    }
    var beginBackgroundTaskWithNameExpirationHandlerReturnValue: UIBackgroundTaskIdentifier!
    var beginBackgroundTaskWithNameExpirationHandlerClosure: ((String?, (() -> Void)?) -> UIBackgroundTaskIdentifier)?

    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        beginBackgroundTaskWithNameExpirationHandlerCallsCount += 1
        if let beginBackgroundTaskWithNameExpirationHandlerClosure = beginBackgroundTaskWithNameExpirationHandlerClosure {
            return beginBackgroundTaskWithNameExpirationHandlerClosure(taskName, handler)
        } else {
            return beginBackgroundTaskWithNameExpirationHandlerReturnValue
        }
    }
    //MARK: - endBackgroundTask

    var endBackgroundTaskCallsCount = 0
    var endBackgroundTaskCalled: Bool {
        return endBackgroundTaskCallsCount > 0
    }
    var endBackgroundTaskReceivedIdentifier: UIBackgroundTaskIdentifier?
    var endBackgroundTaskReceivedInvocations: [UIBackgroundTaskIdentifier] = []
    var endBackgroundTaskClosure: ((UIBackgroundTaskIdentifier) -> Void)?

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        endBackgroundTaskCallsCount += 1
        endBackgroundTaskReceivedIdentifier = identifier
        endBackgroundTaskReceivedInvocations.append(identifier)
        endBackgroundTaskClosure?(identifier)
    }
    //MARK: - open

    var openCallsCount = 0
    var openCalled: Bool {
        return openCallsCount > 0
    }
    var openReceivedUrl: URL?
    var openReceivedInvocations: [URL] = []
    var openClosure: ((URL) -> Void)?

    func open(_ url: URL) {
        openCallsCount += 1
        openReceivedUrl = url
        openReceivedInvocations.append(url)
        openClosure?(url)
    }
}
class AudioConverterMock: AudioConverterProtocol {

    //MARK: - convertToOpusOgg

    var convertToOpusOggSourceURLDestinationURLThrowableError: Error?
    var convertToOpusOggSourceURLDestinationURLCallsCount = 0
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
        convertToOpusOggSourceURLDestinationURLReceivedInvocations.append((sourceURL: sourceURL, destinationURL: destinationURL))
        try convertToOpusOggSourceURLDestinationURLClosure?(sourceURL, destinationURL)
    }
    //MARK: - convertToMPEG4AAC

    var convertToMPEG4AACSourceURLDestinationURLThrowableError: Error?
    var convertToMPEG4AACSourceURLDestinationURLCallsCount = 0
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
        convertToMPEG4AACSourceURLDestinationURLReceivedInvocations.append((sourceURL: sourceURL, destinationURL: destinationURL))
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

    var loadMediaSourceUsingAutoplayCallsCount = 0
    var loadMediaSourceUsingAutoplayCalled: Bool {
        return loadMediaSourceUsingAutoplayCallsCount > 0
    }
    var loadMediaSourceUsingAutoplayReceivedArguments: (mediaSource: MediaSourceProxy, url: URL, autoplay: Bool)?
    var loadMediaSourceUsingAutoplayReceivedInvocations: [(mediaSource: MediaSourceProxy, url: URL, autoplay: Bool)] = []
    var loadMediaSourceUsingAutoplayClosure: ((MediaSourceProxy, URL, Bool) -> Void)?

    func load(mediaSource: MediaSourceProxy, using url: URL, autoplay: Bool) {
        loadMediaSourceUsingAutoplayCallsCount += 1
        loadMediaSourceUsingAutoplayReceivedArguments = (mediaSource: mediaSource, url: url, autoplay: autoplay)
        loadMediaSourceUsingAutoplayReceivedInvocations.append((mediaSource: mediaSource, url: url, autoplay: autoplay))
        loadMediaSourceUsingAutoplayClosure?(mediaSource, url, autoplay)
    }
    //MARK: - play

    var playCallsCount = 0
    var playCalled: Bool {
        return playCallsCount > 0
    }
    var playClosure: (() -> Void)?

    func play() {
        playCallsCount += 1
        playClosure?()
    }
    //MARK: - pause

    var pauseCallsCount = 0
    var pauseCalled: Bool {
        return pauseCallsCount > 0
    }
    var pauseClosure: (() -> Void)?

    func pause() {
        pauseCallsCount += 1
        pauseClosure?()
    }
    //MARK: - stop

    var stopCallsCount = 0
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCount += 1
        stopClosure?()
    }
    //MARK: - seek

    var seekToCallsCount = 0
    var seekToCalled: Bool {
        return seekToCallsCount > 0
    }
    var seekToReceivedProgress: Double?
    var seekToReceivedInvocations: [Double] = []
    var seekToClosure: ((Double) async -> Void)?

    func seek(to progress: Double) async {
        seekToCallsCount += 1
        seekToReceivedProgress = progress
        seekToReceivedInvocations.append(progress)
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
    var audioFileUrl: URL?

    //MARK: - record

    var recordWithCallsCount = 0
    var recordWithCalled: Bool {
        return recordWithCallsCount > 0
    }
    var recordWithReceivedRecordID: AudioRecordingIdentifier?
    var recordWithReceivedInvocations: [AudioRecordingIdentifier] = []
    var recordWithClosure: ((AudioRecordingIdentifier) async -> Void)?

    func record(with recordID: AudioRecordingIdentifier) async {
        recordWithCallsCount += 1
        recordWithReceivedRecordID = recordID
        recordWithReceivedInvocations.append(recordID)
        await recordWithClosure?(recordID)
    }
    //MARK: - stopRecording

    var stopRecordingCallsCount = 0
    var stopRecordingCalled: Bool {
        return stopRecordingCallsCount > 0
    }
    var stopRecordingClosure: (() async -> Void)?

    func stopRecording() async {
        stopRecordingCallsCount += 1
        await stopRecordingClosure?()
    }
    //MARK: - deleteRecording

    var deleteRecordingCallsCount = 0
    var deleteRecordingCalled: Bool {
        return deleteRecordingCallsCount > 0
    }
    var deleteRecordingClosure: (() async -> Void)?

    func deleteRecording() async {
        deleteRecordingCallsCount += 1
        await deleteRecordingClosure?()
    }
    //MARK: - averagePower

    var averagePowerCallsCount = 0
    var averagePowerCalled: Bool {
        return averagePowerCallsCount > 0
    }
    var averagePowerReturnValue: Float!
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

    var requestRecordPermissionCallsCount = 0
    var requestRecordPermissionCalled: Bool {
        return requestRecordPermissionCallsCount > 0
    }
    var requestRecordPermissionReceivedResponse: ((Bool) -> Void)?
    var requestRecordPermissionReceivedInvocations: [((Bool) -> Void)] = []
    var requestRecordPermissionClosure: ((@escaping (Bool) -> Void) -> Void)?

    func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        requestRecordPermissionCallsCount += 1
        requestRecordPermissionReceivedResponse = response
        requestRecordPermissionReceivedInvocations.append(response)
        requestRecordPermissionClosure?(response)
    }
    //MARK: - setAllowHapticsAndSystemSoundsDuringRecording

    var setAllowHapticsAndSystemSoundsDuringRecordingThrowableError: Error?
    var setAllowHapticsAndSystemSoundsDuringRecordingCallsCount = 0
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
        setAllowHapticsAndSystemSoundsDuringRecordingReceivedInvocations.append(inValue)
        try setAllowHapticsAndSystemSoundsDuringRecordingClosure?(inValue)
    }
    //MARK: - setCategory

    var setCategoryModeOptionsThrowableError: Error?
    var setCategoryModeOptionsCallsCount = 0
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
        setCategoryModeOptionsReceivedInvocations.append((category: category, mode: mode, options: options))
        try setCategoryModeOptionsClosure?(category, mode, options)
    }
    //MARK: - setActive

    var setActiveOptionsThrowableError: Error?
    var setActiveOptionsCallsCount = 0
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
        setActiveOptionsReceivedInvocations.append((active: active, options: options))
        try setActiveOptionsClosure?(active, options)
    }
}
class BugReportServiceMock: BugReportServiceProtocol {
    var isRunning: Bool {
        get { return underlyingIsRunning }
        set(value) { underlyingIsRunning = value }
    }
    var underlyingIsRunning: Bool!
    var crashedLastRun: Bool {
        get { return underlyingCrashedLastRun }
        set(value) { underlyingCrashedLastRun = value }
    }
    var underlyingCrashedLastRun: Bool!

    //MARK: - start

    var startCallsCount = 0
    var startCalled: Bool {
        return startCallsCount > 0
    }
    var startClosure: (() -> Void)?

    func start() {
        startCallsCount += 1
        startClosure?()
    }
    //MARK: - stop

    var stopCallsCount = 0
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCount += 1
        stopClosure?()
    }
    //MARK: - reset

    var resetCallsCount = 0
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCount += 1
        resetClosure?()
    }
    //MARK: - crash

    var crashCallsCount = 0
    var crashCalled: Bool {
        return crashCallsCount > 0
    }
    var crashClosure: (() -> Void)?

    func crash() {
        crashCallsCount += 1
        crashClosure?()
    }
    //MARK: - submitBugReport

    var submitBugReportProgressListenerCallsCount = 0
    var submitBugReportProgressListenerCalled: Bool {
        return submitBugReportProgressListenerCallsCount > 0
    }
    var submitBugReportProgressListenerReceivedArguments: (bugReport: BugReport, progressListener: CurrentValueSubject<Double, Never>)?
    var submitBugReportProgressListenerReceivedInvocations: [(bugReport: BugReport, progressListener: CurrentValueSubject<Double, Never>)] = []
    var submitBugReportProgressListenerReturnValue: Result<SubmitBugReportResponse, BugReportServiceError>!
    var submitBugReportProgressListenerClosure: ((BugReport, CurrentValueSubject<Double, Never>) async -> Result<SubmitBugReportResponse, BugReportServiceError>)?

    func submitBugReport(_ bugReport: BugReport, progressListener: CurrentValueSubject<Double, Never>) async -> Result<SubmitBugReportResponse, BugReportServiceError> {
        submitBugReportProgressListenerCallsCount += 1
        submitBugReportProgressListenerReceivedArguments = (bugReport: bugReport, progressListener: progressListener)
        submitBugReportProgressListenerReceivedInvocations.append((bugReport: bugReport, progressListener: progressListener))
        if let submitBugReportProgressListenerClosure = submitBugReportProgressListenerClosure {
            return await submitBugReportProgressListenerClosure(bugReport, progressListener)
        } else {
            return submitBugReportProgressListenerReturnValue
        }
    }
}
class CompletionSuggestionServiceMock: CompletionSuggestionServiceProtocol {
    var suggestionsPublisher: AnyPublisher<[SuggestionItem], Never> {
        get { return underlyingSuggestionsPublisher }
        set(value) { underlyingSuggestionsPublisher = value }
    }
    var underlyingSuggestionsPublisher: AnyPublisher<[SuggestionItem], Never>!

    //MARK: - setSuggestionTrigger

    var setSuggestionTriggerCallsCount = 0
    var setSuggestionTriggerCalled: Bool {
        return setSuggestionTriggerCallsCount > 0
    }
    var setSuggestionTriggerReceivedSuggestionTrigger: SuggestionPattern?
    var setSuggestionTriggerReceivedInvocations: [SuggestionPattern?] = []
    var setSuggestionTriggerClosure: ((SuggestionPattern?) -> Void)?

    func setSuggestionTrigger(_ suggestionTrigger: SuggestionPattern?) {
        setSuggestionTriggerCallsCount += 1
        setSuggestionTriggerReceivedSuggestionTrigger = suggestionTrigger
        setSuggestionTriggerReceivedInvocations.append(suggestionTrigger)
        setSuggestionTriggerClosure?(suggestionTrigger)
    }
}
class ElementCallWidgetDriverMock: ElementCallWidgetDriverProtocol {
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

    var startBaseURLClientIDUseEncryptionCallsCount = 0
    var startBaseURLClientIDUseEncryptionCalled: Bool {
        return startBaseURLClientIDUseEncryptionCallsCount > 0
    }
    var startBaseURLClientIDUseEncryptionReceivedArguments: (baseURL: URL, clientID: String, useEncryption: Bool)?
    var startBaseURLClientIDUseEncryptionReceivedInvocations: [(baseURL: URL, clientID: String, useEncryption: Bool)] = []
    var startBaseURLClientIDUseEncryptionReturnValue: Result<URL, ElementCallWidgetDriverError>!
    var startBaseURLClientIDUseEncryptionClosure: ((URL, String, Bool) async -> Result<URL, ElementCallWidgetDriverError>)?

    func start(baseURL: URL, clientID: String, useEncryption: Bool) async -> Result<URL, ElementCallWidgetDriverError> {
        startBaseURLClientIDUseEncryptionCallsCount += 1
        startBaseURLClientIDUseEncryptionReceivedArguments = (baseURL: baseURL, clientID: clientID, useEncryption: useEncryption)
        startBaseURLClientIDUseEncryptionReceivedInvocations.append((baseURL: baseURL, clientID: clientID, useEncryption: useEncryption))
        if let startBaseURLClientIDUseEncryptionClosure = startBaseURLClientIDUseEncryptionClosure {
            return await startBaseURLClientIDUseEncryptionClosure(baseURL, clientID, useEncryption)
        } else {
            return startBaseURLClientIDUseEncryptionReturnValue
        }
    }
    //MARK: - sendMessage

    var sendMessageCallsCount = 0
    var sendMessageCalled: Bool {
        return sendMessageCallsCount > 0
    }
    var sendMessageReceivedMessage: String?
    var sendMessageReceivedInvocations: [String] = []
    var sendMessageReturnValue: Result<Bool, ElementCallWidgetDriverError>!
    var sendMessageClosure: ((String) async -> Result<Bool, ElementCallWidgetDriverError>)?

    func sendMessage(_ message: String) async -> Result<Bool, ElementCallWidgetDriverError> {
        sendMessageCallsCount += 1
        sendMessageReceivedMessage = message
        sendMessageReceivedInvocations.append(message)
        if let sendMessageClosure = sendMessageClosure {
            return await sendMessageClosure(message)
        } else {
            return sendMessageReturnValue
        }
    }
}
class KeychainControllerMock: KeychainControllerProtocol {

    //MARK: - setRestorationToken

    var setRestorationTokenForUsernameCallsCount = 0
    var setRestorationTokenForUsernameCalled: Bool {
        return setRestorationTokenForUsernameCallsCount > 0
    }
    var setRestorationTokenForUsernameReceivedArguments: (restorationToken: RestorationToken, forUsername: String)?
    var setRestorationTokenForUsernameReceivedInvocations: [(restorationToken: RestorationToken, forUsername: String)] = []
    var setRestorationTokenForUsernameClosure: ((RestorationToken, String) -> Void)?

    func setRestorationToken(_ restorationToken: RestorationToken, forUsername: String) {
        setRestorationTokenForUsernameCallsCount += 1
        setRestorationTokenForUsernameReceivedArguments = (restorationToken: restorationToken, forUsername: forUsername)
        setRestorationTokenForUsernameReceivedInvocations.append((restorationToken: restorationToken, forUsername: forUsername))
        setRestorationTokenForUsernameClosure?(restorationToken, forUsername)
    }
    //MARK: - restorationTokenForUsername

    var restorationTokenForUsernameCallsCount = 0
    var restorationTokenForUsernameCalled: Bool {
        return restorationTokenForUsernameCallsCount > 0
    }
    var restorationTokenForUsernameReceivedUsername: String?
    var restorationTokenForUsernameReceivedInvocations: [String] = []
    var restorationTokenForUsernameReturnValue: RestorationToken?
    var restorationTokenForUsernameClosure: ((String) -> RestorationToken?)?

    func restorationTokenForUsername(_ username: String) -> RestorationToken? {
        restorationTokenForUsernameCallsCount += 1
        restorationTokenForUsernameReceivedUsername = username
        restorationTokenForUsernameReceivedInvocations.append(username)
        if let restorationTokenForUsernameClosure = restorationTokenForUsernameClosure {
            return restorationTokenForUsernameClosure(username)
        } else {
            return restorationTokenForUsernameReturnValue
        }
    }
    //MARK: - restorationTokens

    var restorationTokensCallsCount = 0
    var restorationTokensCalled: Bool {
        return restorationTokensCallsCount > 0
    }
    var restorationTokensReturnValue: [KeychainCredentials]!
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

    var removeRestorationTokenForUsernameCallsCount = 0
    var removeRestorationTokenForUsernameCalled: Bool {
        return removeRestorationTokenForUsernameCallsCount > 0
    }
    var removeRestorationTokenForUsernameReceivedUsername: String?
    var removeRestorationTokenForUsernameReceivedInvocations: [String] = []
    var removeRestorationTokenForUsernameClosure: ((String) -> Void)?

    func removeRestorationTokenForUsername(_ username: String) {
        removeRestorationTokenForUsernameCallsCount += 1
        removeRestorationTokenForUsernameReceivedUsername = username
        removeRestorationTokenForUsernameReceivedInvocations.append(username)
        removeRestorationTokenForUsernameClosure?(username)
    }
    //MARK: - removeAllRestorationTokens

    var removeAllRestorationTokensCallsCount = 0
    var removeAllRestorationTokensCalled: Bool {
        return removeAllRestorationTokensCallsCount > 0
    }
    var removeAllRestorationTokensClosure: (() -> Void)?

    func removeAllRestorationTokens() {
        removeAllRestorationTokensCallsCount += 1
        removeAllRestorationTokensClosure?()
    }
    //MARK: - resetSecrets

    var resetSecretsCallsCount = 0
    var resetSecretsCalled: Bool {
        return resetSecretsCallsCount > 0
    }
    var resetSecretsClosure: (() -> Void)?

    func resetSecrets() {
        resetSecretsCallsCount += 1
        resetSecretsClosure?()
    }
    //MARK: - containsPINCode

    var containsPINCodeThrowableError: Error?
    var containsPINCodeCallsCount = 0
    var containsPINCodeCalled: Bool {
        return containsPINCodeCallsCount > 0
    }
    var containsPINCodeReturnValue: Bool!
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
    var setPINCodeCallsCount = 0
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
        setPINCodeReceivedInvocations.append(pinCode)
        try setPINCodeClosure?(pinCode)
    }
    //MARK: - pinCode

    var pinCodeCallsCount = 0
    var pinCodeCalled: Bool {
        return pinCodeCallsCount > 0
    }
    var pinCodeReturnValue: String?
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

    var removePINCodeCallsCount = 0
    var removePINCodeCalled: Bool {
        return removePINCodeCallsCount > 0
    }
    var removePINCodeClosure: (() -> Void)?

    func removePINCode() {
        removePINCodeCallsCount += 1
        removePINCodeClosure?()
    }
    //MARK: - containsPINCodeBiometricState

    var containsPINCodeBiometricStateCallsCount = 0
    var containsPINCodeBiometricStateCalled: Bool {
        return containsPINCodeBiometricStateCallsCount > 0
    }
    var containsPINCodeBiometricStateReturnValue: Bool!
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
    var setPINCodeBiometricStateCallsCount = 0
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
        setPINCodeBiometricStateReceivedInvocations.append(state)
        try setPINCodeBiometricStateClosure?(state)
    }
    //MARK: - pinCodeBiometricState

    var pinCodeBiometricStateCallsCount = 0
    var pinCodeBiometricStateCalled: Bool {
        return pinCodeBiometricStateCallsCount > 0
    }
    var pinCodeBiometricStateReturnValue: Data?
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

    var removePINCodeBiometricStateCallsCount = 0
    var removePINCodeBiometricStateCalled: Bool {
        return removePINCodeBiometricStateCallsCount > 0
    }
    var removePINCodeBiometricStateClosure: (() -> Void)?

    func removePINCodeBiometricState() {
        removePINCodeBiometricStateCallsCount += 1
        removePINCodeBiometricStateClosure?()
    }
}
class MediaPlayerMock: MediaPlayerProtocol {
    var mediaSource: MediaSourceProxy?
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

    var loadMediaSourceUsingAutoplayCallsCount = 0
    var loadMediaSourceUsingAutoplayCalled: Bool {
        return loadMediaSourceUsingAutoplayCallsCount > 0
    }
    var loadMediaSourceUsingAutoplayReceivedArguments: (mediaSource: MediaSourceProxy, url: URL, autoplay: Bool)?
    var loadMediaSourceUsingAutoplayReceivedInvocations: [(mediaSource: MediaSourceProxy, url: URL, autoplay: Bool)] = []
    var loadMediaSourceUsingAutoplayClosure: ((MediaSourceProxy, URL, Bool) -> Void)?

    func load(mediaSource: MediaSourceProxy, using url: URL, autoplay: Bool) {
        loadMediaSourceUsingAutoplayCallsCount += 1
        loadMediaSourceUsingAutoplayReceivedArguments = (mediaSource: mediaSource, url: url, autoplay: autoplay)
        loadMediaSourceUsingAutoplayReceivedInvocations.append((mediaSource: mediaSource, url: url, autoplay: autoplay))
        loadMediaSourceUsingAutoplayClosure?(mediaSource, url, autoplay)
    }
    //MARK: - play

    var playCallsCount = 0
    var playCalled: Bool {
        return playCallsCount > 0
    }
    var playClosure: (() -> Void)?

    func play() {
        playCallsCount += 1
        playClosure?()
    }
    //MARK: - pause

    var pauseCallsCount = 0
    var pauseCalled: Bool {
        return pauseCallsCount > 0
    }
    var pauseClosure: (() -> Void)?

    func pause() {
        pauseCallsCount += 1
        pauseClosure?()
    }
    //MARK: - stop

    var stopCallsCount = 0
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCount += 1
        stopClosure?()
    }
    //MARK: - seek

    var seekToCallsCount = 0
    var seekToCalled: Bool {
        return seekToCallsCount > 0
    }
    var seekToReceivedProgress: Double?
    var seekToReceivedInvocations: [Double] = []
    var seekToClosure: ((Double) async -> Void)?

    func seek(to progress: Double) async {
        seekToCallsCount += 1
        seekToReceivedProgress = progress
        seekToReceivedInvocations.append(progress)
        await seekToClosure?(progress)
    }
}
class MediaPlayerProviderMock: MediaPlayerProviderProtocol {

    //MARK: - player

    var playerForCallsCount = 0
    var playerForCalled: Bool {
        return playerForCallsCount > 0
    }
    var playerForReceivedMediaSource: MediaSourceProxy?
    var playerForReceivedInvocations: [MediaSourceProxy] = []
    var playerForReturnValue: Result<MediaPlayerProtocol, MediaPlayerProviderError>!
    var playerForClosure: ((MediaSourceProxy) -> Result<MediaPlayerProtocol, MediaPlayerProviderError>)?

    func player(for mediaSource: MediaSourceProxy) -> Result<MediaPlayerProtocol, MediaPlayerProviderError> {
        playerForCallsCount += 1
        playerForReceivedMediaSource = mediaSource
        playerForReceivedInvocations.append(mediaSource)
        if let playerForClosure = playerForClosure {
            return playerForClosure(mediaSource)
        } else {
            return playerForReturnValue
        }
    }
    //MARK: - playerState

    var playerStateForCallsCount = 0
    var playerStateForCalled: Bool {
        return playerStateForCallsCount > 0
    }
    var playerStateForReceivedId: AudioPlayerStateIdentifier?
    var playerStateForReceivedInvocations: [AudioPlayerStateIdentifier] = []
    var playerStateForReturnValue: AudioPlayerState?
    var playerStateForClosure: ((AudioPlayerStateIdentifier) -> AudioPlayerState?)?

    func playerState(for id: AudioPlayerStateIdentifier) -> AudioPlayerState? {
        playerStateForCallsCount += 1
        playerStateForReceivedId = id
        playerStateForReceivedInvocations.append(id)
        if let playerStateForClosure = playerStateForClosure {
            return playerStateForClosure(id)
        } else {
            return playerStateForReturnValue
        }
    }
    //MARK: - register

    var registerAudioPlayerStateCallsCount = 0
    var registerAudioPlayerStateCalled: Bool {
        return registerAudioPlayerStateCallsCount > 0
    }
    var registerAudioPlayerStateReceivedAudioPlayerState: AudioPlayerState?
    var registerAudioPlayerStateReceivedInvocations: [AudioPlayerState] = []
    var registerAudioPlayerStateClosure: ((AudioPlayerState) -> Void)?

    func register(audioPlayerState: AudioPlayerState) {
        registerAudioPlayerStateCallsCount += 1
        registerAudioPlayerStateReceivedAudioPlayerState = audioPlayerState
        registerAudioPlayerStateReceivedInvocations.append(audioPlayerState)
        registerAudioPlayerStateClosure?(audioPlayerState)
    }
    //MARK: - unregister

    var unregisterAudioPlayerStateCallsCount = 0
    var unregisterAudioPlayerStateCalled: Bool {
        return unregisterAudioPlayerStateCallsCount > 0
    }
    var unregisterAudioPlayerStateReceivedAudioPlayerState: AudioPlayerState?
    var unregisterAudioPlayerStateReceivedInvocations: [AudioPlayerState] = []
    var unregisterAudioPlayerStateClosure: ((AudioPlayerState) -> Void)?

    func unregister(audioPlayerState: AudioPlayerState) {
        unregisterAudioPlayerStateCallsCount += 1
        unregisterAudioPlayerStateReceivedAudioPlayerState = audioPlayerState
        unregisterAudioPlayerStateReceivedInvocations.append(audioPlayerState)
        unregisterAudioPlayerStateClosure?(audioPlayerState)
    }
    //MARK: - detachAllStates

    var detachAllStatesExceptCallsCount = 0
    var detachAllStatesExceptCalled: Bool {
        return detachAllStatesExceptCallsCount > 0
    }
    var detachAllStatesExceptReceivedException: AudioPlayerState?
    var detachAllStatesExceptReceivedInvocations: [AudioPlayerState?] = []
    var detachAllStatesExceptClosure: ((AudioPlayerState?) async -> Void)?

    func detachAllStates(except exception: AudioPlayerState?) async {
        detachAllStatesExceptCallsCount += 1
        detachAllStatesExceptReceivedException = exception
        detachAllStatesExceptReceivedInvocations.append(exception)
        await detachAllStatesExceptClosure?(exception)
    }
}
class NetworkMonitorMock: NetworkMonitorProtocol {
    var reachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> {
        get { return underlyingReachabilityPublisher }
        set(value) { underlyingReachabilityPublisher = value }
    }
    var underlyingReachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never>!
    var isCurrentConnectionExpensive: Bool {
        get { return underlyingIsCurrentConnectionExpensive }
        set(value) { underlyingIsCurrentConnectionExpensive = value }
    }
    var underlyingIsCurrentConnectionExpensive: Bool!
    var isCurrentConnectionConstrained: Bool {
        get { return underlyingIsCurrentConnectionConstrained }
        set(value) { underlyingIsCurrentConnectionConstrained = value }
    }
    var underlyingIsCurrentConnectionConstrained: Bool!

}
class NotificationCenterMock: NotificationCenterProtocol {

    //MARK: - post

    var postNameObjectCallsCount = 0
    var postNameObjectCalled: Bool {
        return postNameObjectCallsCount > 0
    }
    var postNameObjectReceivedArguments: (aName: NSNotification.Name, anObject: Any?)?
    var postNameObjectReceivedInvocations: [(aName: NSNotification.Name, anObject: Any?)] = []
    var postNameObjectClosure: ((NSNotification.Name, Any?) -> Void)?

    func post(name aName: NSNotification.Name, object anObject: Any?) {
        postNameObjectCallsCount += 1
        postNameObjectReceivedArguments = (aName: aName, anObject: anObject)
        postNameObjectReceivedInvocations.append((aName: aName, anObject: anObject))
        postNameObjectClosure?(aName, anObject)
    }
}
class NotificationManagerMock: NotificationManagerProtocol {
    weak var delegate: NotificationManagerDelegate?

    //MARK: - start

    var startCallsCount = 0
    var startCalled: Bool {
        return startCallsCount > 0
    }
    var startClosure: (() -> Void)?

    func start() {
        startCallsCount += 1
        startClosure?()
    }
    //MARK: - register

    var registerWithCallsCount = 0
    var registerWithCalled: Bool {
        return registerWithCallsCount > 0
    }
    var registerWithReceivedDeviceToken: Data?
    var registerWithReceivedInvocations: [Data] = []
    var registerWithReturnValue: Bool!
    var registerWithClosure: ((Data) async -> Bool)?

    func register(with deviceToken: Data) async -> Bool {
        registerWithCallsCount += 1
        registerWithReceivedDeviceToken = deviceToken
        registerWithReceivedInvocations.append(deviceToken)
        if let registerWithClosure = registerWithClosure {
            return await registerWithClosure(deviceToken)
        } else {
            return registerWithReturnValue
        }
    }
    //MARK: - registrationFailed

    var registrationFailedWithCallsCount = 0
    var registrationFailedWithCalled: Bool {
        return registrationFailedWithCallsCount > 0
    }
    var registrationFailedWithReceivedError: Error?
    var registrationFailedWithReceivedInvocations: [Error] = []
    var registrationFailedWithClosure: ((Error) -> Void)?

    func registrationFailed(with error: Error) {
        registrationFailedWithCallsCount += 1
        registrationFailedWithReceivedError = error
        registrationFailedWithReceivedInvocations.append(error)
        registrationFailedWithClosure?(error)
    }
    //MARK: - showLocalNotification

    var showLocalNotificationWithSubtitleCallsCount = 0
    var showLocalNotificationWithSubtitleCalled: Bool {
        return showLocalNotificationWithSubtitleCallsCount > 0
    }
    var showLocalNotificationWithSubtitleReceivedArguments: (title: String, subtitle: String?)?
    var showLocalNotificationWithSubtitleReceivedInvocations: [(title: String, subtitle: String?)] = []
    var showLocalNotificationWithSubtitleClosure: ((String, String?) async -> Void)?

    func showLocalNotification(with title: String, subtitle: String?) async {
        showLocalNotificationWithSubtitleCallsCount += 1
        showLocalNotificationWithSubtitleReceivedArguments = (title: title, subtitle: subtitle)
        showLocalNotificationWithSubtitleReceivedInvocations.append((title: title, subtitle: subtitle))
        await showLocalNotificationWithSubtitleClosure?(title, subtitle)
    }
    //MARK: - setUserSession

    var setUserSessionCallsCount = 0
    var setUserSessionCalled: Bool {
        return setUserSessionCallsCount > 0
    }
    var setUserSessionReceivedUserSession: UserSessionProtocol?
    var setUserSessionReceivedInvocations: [UserSessionProtocol?] = []
    var setUserSessionClosure: ((UserSessionProtocol?) -> Void)?

    func setUserSession(_ userSession: UserSessionProtocol?) {
        setUserSessionCallsCount += 1
        setUserSessionReceivedUserSession = userSession
        setUserSessionReceivedInvocations.append(userSession)
        setUserSessionClosure?(userSession)
    }
    //MARK: - requestAuthorization

    var requestAuthorizationCallsCount = 0
    var requestAuthorizationCalled: Bool {
        return requestAuthorizationCallsCount > 0
    }
    var requestAuthorizationClosure: (() -> Void)?

    func requestAuthorization() {
        requestAuthorizationCallsCount += 1
        requestAuthorizationClosure?()
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
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCount = 0
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneCalled: Bool {
        return getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCount > 0
    }
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedArguments: (roomId: String, isEncrypted: Bool, isOneToOne: Bool)?
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedInvocations: [(roomId: String, isEncrypted: Bool, isOneToOne: Bool)] = []
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue: RoomNotificationSettingsProxyProtocol!
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure: ((String, Bool, Bool) async throws -> RoomNotificationSettingsProxyProtocol)?

    func getNotificationSettings(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws -> RoomNotificationSettingsProxyProtocol {
        if let error = getNotificationSettingsRoomIdIsEncryptedIsOneToOneThrowableError {
            throw error
        }
        getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCount += 1
        getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedArguments = (roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedInvocations.append((roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne))
        if let getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure = getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure {
            return try await getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure(roomId, isEncrypted, isOneToOne)
        } else {
            return getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue
        }
    }
    //MARK: - setNotificationMode

    var setNotificationModeRoomIdModeThrowableError: Error?
    var setNotificationModeRoomIdModeCallsCount = 0
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
        setNotificationModeRoomIdModeReceivedInvocations.append((roomId: roomId, mode: mode))
        try await setNotificationModeRoomIdModeClosure?(roomId, mode)
    }
    //MARK: - getUserDefinedRoomNotificationMode

    var getUserDefinedRoomNotificationModeRoomIdThrowableError: Error?
    var getUserDefinedRoomNotificationModeRoomIdCallsCount = 0
    var getUserDefinedRoomNotificationModeRoomIdCalled: Bool {
        return getUserDefinedRoomNotificationModeRoomIdCallsCount > 0
    }
    var getUserDefinedRoomNotificationModeRoomIdReceivedRoomId: String?
    var getUserDefinedRoomNotificationModeRoomIdReceivedInvocations: [String] = []
    var getUserDefinedRoomNotificationModeRoomIdReturnValue: RoomNotificationModeProxy?
    var getUserDefinedRoomNotificationModeRoomIdClosure: ((String) async throws -> RoomNotificationModeProxy?)?

    func getUserDefinedRoomNotificationMode(roomId: String) async throws -> RoomNotificationModeProxy? {
        if let error = getUserDefinedRoomNotificationModeRoomIdThrowableError {
            throw error
        }
        getUserDefinedRoomNotificationModeRoomIdCallsCount += 1
        getUserDefinedRoomNotificationModeRoomIdReceivedRoomId = roomId
        getUserDefinedRoomNotificationModeRoomIdReceivedInvocations.append(roomId)
        if let getUserDefinedRoomNotificationModeRoomIdClosure = getUserDefinedRoomNotificationModeRoomIdClosure {
            return try await getUserDefinedRoomNotificationModeRoomIdClosure(roomId)
        } else {
            return getUserDefinedRoomNotificationModeRoomIdReturnValue
        }
    }
    //MARK: - getDefaultRoomNotificationMode

    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount = 0
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneCalled: Bool {
        return getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount > 0
    }
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedArguments: (isEncrypted: Bool, isOneToOne: Bool)?
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocations: [(isEncrypted: Bool, isOneToOne: Bool)] = []
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue: RoomNotificationModeProxy!
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure: ((Bool, Bool) async -> RoomNotificationModeProxy)?

    func getDefaultRoomNotificationMode(isEncrypted: Bool, isOneToOne: Bool) async -> RoomNotificationModeProxy {
        getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount += 1
        getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedArguments = (isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocations.append((isEncrypted: isEncrypted, isOneToOne: isOneToOne))
        if let getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure {
            return await getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure(isEncrypted, isOneToOne)
        } else {
            return getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue
        }
    }
    //MARK: - setDefaultRoomNotificationMode

    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeThrowableError: Error?
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount = 0
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
        setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations.append((isEncrypted: isEncrypted, isOneToOne: isOneToOne, mode: mode))
        try await setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeClosure?(isEncrypted, isOneToOne, mode)
    }
    //MARK: - restoreDefaultNotificationMode

    var restoreDefaultNotificationModeRoomIdThrowableError: Error?
    var restoreDefaultNotificationModeRoomIdCallsCount = 0
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
        restoreDefaultNotificationModeRoomIdReceivedInvocations.append(roomId)
        try await restoreDefaultNotificationModeRoomIdClosure?(roomId)
    }
    //MARK: - containsKeywordsRules

    var containsKeywordsRulesCallsCount = 0
    var containsKeywordsRulesCalled: Bool {
        return containsKeywordsRulesCallsCount > 0
    }
    var containsKeywordsRulesReturnValue: Bool!
    var containsKeywordsRulesClosure: (() async -> Bool)?

    func containsKeywordsRules() async -> Bool {
        containsKeywordsRulesCallsCount += 1
        if let containsKeywordsRulesClosure = containsKeywordsRulesClosure {
            return await containsKeywordsRulesClosure()
        } else {
            return containsKeywordsRulesReturnValue
        }
    }
    //MARK: - unmuteRoom

    var unmuteRoomRoomIdIsEncryptedIsOneToOneThrowableError: Error?
    var unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCount = 0
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
        unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedInvocations.append((roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne))
        try await unmuteRoomRoomIdIsEncryptedIsOneToOneClosure?(roomId, isEncrypted, isOneToOne)
    }
    //MARK: - isRoomMentionEnabled

    var isRoomMentionEnabledThrowableError: Error?
    var isRoomMentionEnabledCallsCount = 0
    var isRoomMentionEnabledCalled: Bool {
        return isRoomMentionEnabledCallsCount > 0
    }
    var isRoomMentionEnabledReturnValue: Bool!
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
    var setRoomMentionEnabledEnabledCallsCount = 0
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
        setRoomMentionEnabledEnabledReceivedInvocations.append(enabled)
        try await setRoomMentionEnabledEnabledClosure?(enabled)
    }
    //MARK: - isUserMentionEnabled

    var isUserMentionEnabledThrowableError: Error?
    var isUserMentionEnabledCallsCount = 0
    var isUserMentionEnabledCalled: Bool {
        return isUserMentionEnabledCallsCount > 0
    }
    var isUserMentionEnabledReturnValue: Bool!
    var isUserMentionEnabledClosure: (() async throws -> Bool)?

    func isUserMentionEnabled() async throws -> Bool {
        if let error = isUserMentionEnabledThrowableError {
            throw error
        }
        isUserMentionEnabledCallsCount += 1
        if let isUserMentionEnabledClosure = isUserMentionEnabledClosure {
            return try await isUserMentionEnabledClosure()
        } else {
            return isUserMentionEnabledReturnValue
        }
    }
    //MARK: - setUserMentionEnabled

    var setUserMentionEnabledEnabledThrowableError: Error?
    var setUserMentionEnabledEnabledCallsCount = 0
    var setUserMentionEnabledEnabledCalled: Bool {
        return setUserMentionEnabledEnabledCallsCount > 0
    }
    var setUserMentionEnabledEnabledReceivedEnabled: Bool?
    var setUserMentionEnabledEnabledReceivedInvocations: [Bool] = []
    var setUserMentionEnabledEnabledClosure: ((Bool) async throws -> Void)?

    func setUserMentionEnabled(enabled: Bool) async throws {
        if let error = setUserMentionEnabledEnabledThrowableError {
            throw error
        }
        setUserMentionEnabledEnabledCallsCount += 1
        setUserMentionEnabledEnabledReceivedEnabled = enabled
        setUserMentionEnabledEnabledReceivedInvocations.append(enabled)
        try await setUserMentionEnabledEnabledClosure?(enabled)
    }
    //MARK: - isCallEnabled

    var isCallEnabledThrowableError: Error?
    var isCallEnabledCallsCount = 0
    var isCallEnabledCalled: Bool {
        return isCallEnabledCallsCount > 0
    }
    var isCallEnabledReturnValue: Bool!
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
    var setCallEnabledEnabledCallsCount = 0
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
        setCallEnabledEnabledReceivedInvocations.append(enabled)
        try await setCallEnabledEnabledClosure?(enabled)
    }
    //MARK: - getRoomsWithUserDefinedRules

    var getRoomsWithUserDefinedRulesThrowableError: Error?
    var getRoomsWithUserDefinedRulesCallsCount = 0
    var getRoomsWithUserDefinedRulesCalled: Bool {
        return getRoomsWithUserDefinedRulesCallsCount > 0
    }
    var getRoomsWithUserDefinedRulesReturnValue: [String]!
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
    var isNameAmbiguous: Bool {
        get { return underlyingIsNameAmbiguous }
        set(value) { underlyingIsNameAmbiguous = value }
    }
    var underlyingIsNameAmbiguous: Bool!
    var powerLevel: Int {
        get { return underlyingPowerLevel }
        set(value) { underlyingPowerLevel = value }
    }
    var underlyingPowerLevel: Int!
    var normalizedPowerLevel: Int {
        get { return underlyingNormalizedPowerLevel }
        set(value) { underlyingNormalizedPowerLevel = value }
    }
    var underlyingNormalizedPowerLevel: Int!
    var isAccountOwner: Bool {
        get { return underlyingIsAccountOwner }
        set(value) { underlyingIsAccountOwner = value }
    }
    var underlyingIsAccountOwner: Bool!
    var isIgnored: Bool {
        get { return underlyingIsIgnored }
        set(value) { underlyingIsIgnored = value }
    }
    var underlyingIsIgnored: Bool!
    var canInviteUsers: Bool {
        get { return underlyingCanInviteUsers }
        set(value) { underlyingCanInviteUsers = value }
    }
    var underlyingCanInviteUsers: Bool!

    //MARK: - ignoreUser

    var ignoreUserCallsCount = 0
    var ignoreUserCalled: Bool {
        return ignoreUserCallsCount > 0
    }
    var ignoreUserReturnValue: Result<Void, RoomMemberProxyError>!
    var ignoreUserClosure: (() async -> Result<Void, RoomMemberProxyError>)?

    func ignoreUser() async -> Result<Void, RoomMemberProxyError> {
        ignoreUserCallsCount += 1
        if let ignoreUserClosure = ignoreUserClosure {
            return await ignoreUserClosure()
        } else {
            return ignoreUserReturnValue
        }
    }
    //MARK: - unignoreUser

    var unignoreUserCallsCount = 0
    var unignoreUserCalled: Bool {
        return unignoreUserCallsCount > 0
    }
    var unignoreUserReturnValue: Result<Void, RoomMemberProxyError>!
    var unignoreUserClosure: (() async -> Result<Void, RoomMemberProxyError>)?

    func unignoreUser() async -> Result<Void, RoomMemberProxyError> {
        unignoreUserCallsCount += 1
        if let unignoreUserClosure = unignoreUserClosure {
            return await unignoreUserClosure()
        } else {
            return unignoreUserReturnValue
        }
    }
    //MARK: - canSendStateEvent

    var canSendStateEventTypeCallsCount = 0
    var canSendStateEventTypeCalled: Bool {
        return canSendStateEventTypeCallsCount > 0
    }
    var canSendStateEventTypeReceivedType: StateEventType?
    var canSendStateEventTypeReceivedInvocations: [StateEventType] = []
    var canSendStateEventTypeReturnValue: Bool!
    var canSendStateEventTypeClosure: ((StateEventType) -> Bool)?

    func canSendStateEvent(type: StateEventType) -> Bool {
        canSendStateEventTypeCallsCount += 1
        canSendStateEventTypeReceivedType = type
        canSendStateEventTypeReceivedInvocations.append(type)
        if let canSendStateEventTypeClosure = canSendStateEventTypeClosure {
            return canSendStateEventTypeClosure(type)
        } else {
            return canSendStateEventTypeReturnValue
        }
    }
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
    var isDirect: Bool {
        get { return underlyingIsDirect }
        set(value) { underlyingIsDirect = value }
    }
    var underlyingIsDirect: Bool!
    var isPublic: Bool {
        get { return underlyingIsPublic }
        set(value) { underlyingIsPublic = value }
    }
    var underlyingIsPublic: Bool!
    var isSpace: Bool {
        get { return underlyingIsSpace }
        set(value) { underlyingIsSpace = value }
    }
    var underlyingIsSpace: Bool!
    var isEncrypted: Bool {
        get { return underlyingIsEncrypted }
        set(value) { underlyingIsEncrypted = value }
    }
    var underlyingIsEncrypted: Bool!
    var isTombstoned: Bool {
        get { return underlyingIsTombstoned }
        set(value) { underlyingIsTombstoned = value }
    }
    var underlyingIsTombstoned: Bool!
    var isCallOngoing: Bool {
        get { return underlyingIsCallOngoing }
        set(value) { underlyingIsCallOngoing = value }
    }
    var underlyingIsCallOngoing: Bool!
    var canonicalAlias: String?
    var alternativeAliases: [String] = []
    var hasUnreadNotifications: Bool {
        get { return underlyingHasUnreadNotifications }
        set(value) { underlyingHasUnreadNotifications = value }
    }
    var underlyingHasUnreadNotifications: Bool!
    var ownUserID: String {
        get { return underlyingOwnUserID }
        set(value) { underlyingOwnUserID = value }
    }
    var underlyingOwnUserID: String!
    var name: String?
    var displayName: String?
    var topic: String?
    var avatarURL: URL?
    var members: CurrentValuePublisher<[RoomMemberProxyProtocol], Never> {
        get { return underlyingMembers }
        set(value) { underlyingMembers = value }
    }
    var underlyingMembers: CurrentValuePublisher<[RoomMemberProxyProtocol], Never>!
    var invitedMembersCount: Int {
        get { return underlyingInvitedMembersCount }
        set(value) { underlyingInvitedMembersCount = value }
    }
    var underlyingInvitedMembersCount: Int!
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
    var stateUpdatesPublisher: AnyPublisher<Void, Never> {
        get { return underlyingStateUpdatesPublisher }
        set(value) { underlyingStateUpdatesPublisher = value }
    }
    var underlyingStateUpdatesPublisher: AnyPublisher<Void, Never>!
    var timelineProvider: RoomTimelineProviderProtocol {
        get { return underlyingTimelineProvider }
        set(value) { underlyingTimelineProvider = value }
    }
    var underlyingTimelineProvider: RoomTimelineProviderProtocol!

    //MARK: - subscribeForUpdates

    var subscribeForUpdatesCallsCount = 0
    var subscribeForUpdatesCalled: Bool {
        return subscribeForUpdatesCallsCount > 0
    }
    var subscribeForUpdatesClosure: (() async -> Void)?

    func subscribeForUpdates() async {
        subscribeForUpdatesCallsCount += 1
        await subscribeForUpdatesClosure?()
    }
    //MARK: - loadAvatarURLForUserId

    var loadAvatarURLForUserIdCallsCount = 0
    var loadAvatarURLForUserIdCalled: Bool {
        return loadAvatarURLForUserIdCallsCount > 0
    }
    var loadAvatarURLForUserIdReceivedUserId: String?
    var loadAvatarURLForUserIdReceivedInvocations: [String] = []
    var loadAvatarURLForUserIdReturnValue: Result<URL?, RoomProxyError>!
    var loadAvatarURLForUserIdClosure: ((String) async -> Result<URL?, RoomProxyError>)?

    func loadAvatarURLForUserId(_ userId: String) async -> Result<URL?, RoomProxyError> {
        loadAvatarURLForUserIdCallsCount += 1
        loadAvatarURLForUserIdReceivedUserId = userId
        loadAvatarURLForUserIdReceivedInvocations.append(userId)
        if let loadAvatarURLForUserIdClosure = loadAvatarURLForUserIdClosure {
            return await loadAvatarURLForUserIdClosure(userId)
        } else {
            return loadAvatarURLForUserIdReturnValue
        }
    }
    //MARK: - loadDisplayNameForUserId

    var loadDisplayNameForUserIdCallsCount = 0
    var loadDisplayNameForUserIdCalled: Bool {
        return loadDisplayNameForUserIdCallsCount > 0
    }
    var loadDisplayNameForUserIdReceivedUserId: String?
    var loadDisplayNameForUserIdReceivedInvocations: [String] = []
    var loadDisplayNameForUserIdReturnValue: Result<String?, RoomProxyError>!
    var loadDisplayNameForUserIdClosure: ((String) async -> Result<String?, RoomProxyError>)?

    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        loadDisplayNameForUserIdCallsCount += 1
        loadDisplayNameForUserIdReceivedUserId = userId
        loadDisplayNameForUserIdReceivedInvocations.append(userId)
        if let loadDisplayNameForUserIdClosure = loadDisplayNameForUserIdClosure {
            return await loadDisplayNameForUserIdClosure(userId)
        } else {
            return loadDisplayNameForUserIdReturnValue
        }
    }
    //MARK: - paginateBackwards

    var paginateBackwardsRequestSizeUntilNumberOfItemsCallsCount = 0
    var paginateBackwardsRequestSizeUntilNumberOfItemsCalled: Bool {
        return paginateBackwardsRequestSizeUntilNumberOfItemsCallsCount > 0
    }
    var paginateBackwardsRequestSizeUntilNumberOfItemsReceivedArguments: (requestSize: UInt, untilNumberOfItems: UInt)?
    var paginateBackwardsRequestSizeUntilNumberOfItemsReceivedInvocations: [(requestSize: UInt, untilNumberOfItems: UInt)] = []
    var paginateBackwardsRequestSizeUntilNumberOfItemsReturnValue: Result<Void, RoomProxyError>!
    var paginateBackwardsRequestSizeUntilNumberOfItemsClosure: ((UInt, UInt) async -> Result<Void, RoomProxyError>)?

    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomProxyError> {
        paginateBackwardsRequestSizeUntilNumberOfItemsCallsCount += 1
        paginateBackwardsRequestSizeUntilNumberOfItemsReceivedArguments = (requestSize: requestSize, untilNumberOfItems: untilNumberOfItems)
        paginateBackwardsRequestSizeUntilNumberOfItemsReceivedInvocations.append((requestSize: requestSize, untilNumberOfItems: untilNumberOfItems))
        if let paginateBackwardsRequestSizeUntilNumberOfItemsClosure = paginateBackwardsRequestSizeUntilNumberOfItemsClosure {
            return await paginateBackwardsRequestSizeUntilNumberOfItemsClosure(requestSize, untilNumberOfItems)
        } else {
            return paginateBackwardsRequestSizeUntilNumberOfItemsReturnValue
        }
    }
    //MARK: - sendReadReceipt

    var sendReadReceiptForCallsCount = 0
    var sendReadReceiptForCalled: Bool {
        return sendReadReceiptForCallsCount > 0
    }
    var sendReadReceiptForReceivedEventID: String?
    var sendReadReceiptForReceivedInvocations: [String] = []
    var sendReadReceiptForReturnValue: Result<Void, RoomProxyError>!
    var sendReadReceiptForClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func sendReadReceipt(for eventID: String) async -> Result<Void, RoomProxyError> {
        sendReadReceiptForCallsCount += 1
        sendReadReceiptForReceivedEventID = eventID
        sendReadReceiptForReceivedInvocations.append(eventID)
        if let sendReadReceiptForClosure = sendReadReceiptForClosure {
            return await sendReadReceiptForClosure(eventID)
        } else {
            return sendReadReceiptForReturnValue
        }
    }
    //MARK: - messageEventContent

    var messageEventContentForCallsCount = 0
    var messageEventContentForCalled: Bool {
        return messageEventContentForCallsCount > 0
    }
    var messageEventContentForReceivedEventID: String?
    var messageEventContentForReceivedInvocations: [String] = []
    var messageEventContentForReturnValue: RoomMessageEventContentWithoutRelation?
    var messageEventContentForClosure: ((String) -> RoomMessageEventContentWithoutRelation?)?

    func messageEventContent(for eventID: String) -> RoomMessageEventContentWithoutRelation? {
        messageEventContentForCallsCount += 1
        messageEventContentForReceivedEventID = eventID
        messageEventContentForReceivedInvocations.append(eventID)
        if let messageEventContentForClosure = messageEventContentForClosure {
            return messageEventContentForClosure(eventID)
        } else {
            return messageEventContentForReturnValue
        }
    }
    //MARK: - sendMessageEventContent

    var sendMessageEventContentCallsCount = 0
    var sendMessageEventContentCalled: Bool {
        return sendMessageEventContentCallsCount > 0
    }
    var sendMessageEventContentReceivedMessageContent: RoomMessageEventContentWithoutRelation?
    var sendMessageEventContentReceivedInvocations: [RoomMessageEventContentWithoutRelation] = []
    var sendMessageEventContentReturnValue: Result<Void, RoomProxyError>!
    var sendMessageEventContentClosure: ((RoomMessageEventContentWithoutRelation) async -> Result<Void, RoomProxyError>)?

    func sendMessageEventContent(_ messageContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, RoomProxyError> {
        sendMessageEventContentCallsCount += 1
        sendMessageEventContentReceivedMessageContent = messageContent
        sendMessageEventContentReceivedInvocations.append(messageContent)
        if let sendMessageEventContentClosure = sendMessageEventContentClosure {
            return await sendMessageEventContentClosure(messageContent)
        } else {
            return sendMessageEventContentReturnValue
        }
    }
    //MARK: - sendMessage

    var sendMessageHtmlInReplyToIntentionalMentionsCallsCount = 0
    var sendMessageHtmlInReplyToIntentionalMentionsCalled: Bool {
        return sendMessageHtmlInReplyToIntentionalMentionsCallsCount > 0
    }
    var sendMessageHtmlInReplyToIntentionalMentionsReceivedArguments: (message: String, html: String?, eventID: String?, intentionalMentions: IntentionalMentions)?
    var sendMessageHtmlInReplyToIntentionalMentionsReceivedInvocations: [(message: String, html: String?, eventID: String?, intentionalMentions: IntentionalMentions)] = []
    var sendMessageHtmlInReplyToIntentionalMentionsReturnValue: Result<Void, RoomProxyError>!
    var sendMessageHtmlInReplyToIntentionalMentionsClosure: ((String, String?, String?, IntentionalMentions) async -> Result<Void, RoomProxyError>)?

    func sendMessage(_ message: String, html: String?, inReplyTo eventID: String?, intentionalMentions: IntentionalMentions) async -> Result<Void, RoomProxyError> {
        sendMessageHtmlInReplyToIntentionalMentionsCallsCount += 1
        sendMessageHtmlInReplyToIntentionalMentionsReceivedArguments = (message: message, html: html, eventID: eventID, intentionalMentions: intentionalMentions)
        sendMessageHtmlInReplyToIntentionalMentionsReceivedInvocations.append((message: message, html: html, eventID: eventID, intentionalMentions: intentionalMentions))
        if let sendMessageHtmlInReplyToIntentionalMentionsClosure = sendMessageHtmlInReplyToIntentionalMentionsClosure {
            return await sendMessageHtmlInReplyToIntentionalMentionsClosure(message, html, eventID, intentionalMentions)
        } else {
            return sendMessageHtmlInReplyToIntentionalMentionsReturnValue
        }
    }
    //MARK: - toggleReaction

    var toggleReactionToCallsCount = 0
    var toggleReactionToCalled: Bool {
        return toggleReactionToCallsCount > 0
    }
    var toggleReactionToReceivedArguments: (reaction: String, eventID: String)?
    var toggleReactionToReceivedInvocations: [(reaction: String, eventID: String)] = []
    var toggleReactionToReturnValue: Result<Void, RoomProxyError>!
    var toggleReactionToClosure: ((String, String) async -> Result<Void, RoomProxyError>)?

    func toggleReaction(_ reaction: String, to eventID: String) async -> Result<Void, RoomProxyError> {
        toggleReactionToCallsCount += 1
        toggleReactionToReceivedArguments = (reaction: reaction, eventID: eventID)
        toggleReactionToReceivedInvocations.append((reaction: reaction, eventID: eventID))
        if let toggleReactionToClosure = toggleReactionToClosure {
            return await toggleReactionToClosure(reaction, eventID)
        } else {
            return toggleReactionToReturnValue
        }
    }
    //MARK: - sendImage

    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleCallsCount = 0
    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleCalled: Bool {
        return sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleCallsCount > 0
    }
    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleReturnValue: Result<Void, RoomProxyError>!
    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleClosure: ((URL, URL, ImageInfo, CurrentValueSubject<Double, Never>?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>)?

    func sendImage(url: URL, thumbnailURL: URL, imageInfo: ImageInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleCallsCount += 1
        if let sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleClosure = sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleClosure {
            return await sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleClosure(url, thumbnailURL, imageInfo, progressSubject, requestHandle)
        } else {
            return sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleReturnValue
        }
    }
    //MARK: - sendVideo

    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleCallsCount = 0
    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleCalled: Bool {
        return sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleCallsCount > 0
    }
    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleReturnValue: Result<Void, RoomProxyError>!
    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleClosure: ((URL, URL, VideoInfo, CurrentValueSubject<Double, Never>?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>)?

    func sendVideo(url: URL, thumbnailURL: URL, videoInfo: VideoInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleCallsCount += 1
        if let sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleClosure = sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleClosure {
            return await sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleClosure(url, thumbnailURL, videoInfo, progressSubject, requestHandle)
        } else {
            return sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleReturnValue
        }
    }
    //MARK: - sendAudio

    var sendAudioUrlAudioInfoProgressSubjectRequestHandleCallsCount = 0
    var sendAudioUrlAudioInfoProgressSubjectRequestHandleCalled: Bool {
        return sendAudioUrlAudioInfoProgressSubjectRequestHandleCallsCount > 0
    }
    var sendAudioUrlAudioInfoProgressSubjectRequestHandleReturnValue: Result<Void, RoomProxyError>!
    var sendAudioUrlAudioInfoProgressSubjectRequestHandleClosure: ((URL, AudioInfo, CurrentValueSubject<Double, Never>?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>)?

    func sendAudio(url: URL, audioInfo: AudioInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendAudioUrlAudioInfoProgressSubjectRequestHandleCallsCount += 1
        if let sendAudioUrlAudioInfoProgressSubjectRequestHandleClosure = sendAudioUrlAudioInfoProgressSubjectRequestHandleClosure {
            return await sendAudioUrlAudioInfoProgressSubjectRequestHandleClosure(url, audioInfo, progressSubject, requestHandle)
        } else {
            return sendAudioUrlAudioInfoProgressSubjectRequestHandleReturnValue
        }
    }
    //MARK: - sendFile

    var sendFileUrlFileInfoProgressSubjectRequestHandleCallsCount = 0
    var sendFileUrlFileInfoProgressSubjectRequestHandleCalled: Bool {
        return sendFileUrlFileInfoProgressSubjectRequestHandleCallsCount > 0
    }
    var sendFileUrlFileInfoProgressSubjectRequestHandleReturnValue: Result<Void, RoomProxyError>!
    var sendFileUrlFileInfoProgressSubjectRequestHandleClosure: ((URL, FileInfo, CurrentValueSubject<Double, Never>?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>)?

    func sendFile(url: URL, fileInfo: FileInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendFileUrlFileInfoProgressSubjectRequestHandleCallsCount += 1
        if let sendFileUrlFileInfoProgressSubjectRequestHandleClosure = sendFileUrlFileInfoProgressSubjectRequestHandleClosure {
            return await sendFileUrlFileInfoProgressSubjectRequestHandleClosure(url, fileInfo, progressSubject, requestHandle)
        } else {
            return sendFileUrlFileInfoProgressSubjectRequestHandleReturnValue
        }
    }
    //MARK: - sendLocation

    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount = 0
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCalled: Bool {
        return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount > 0
    }
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArguments: (body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)?
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocations: [(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)] = []
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValue: Result<Void, RoomProxyError>!
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure: ((String, GeoURI, String?, UInt8?, AssetType?) async -> Result<Void, RoomProxyError>)?

    func sendLocation(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?) async -> Result<Void, RoomProxyError> {
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount += 1
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArguments = (body: body, geoURI: geoURI, description: description, zoomLevel: zoomLevel, assetType: assetType)
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocations.append((body: body, geoURI: geoURI, description: description, zoomLevel: zoomLevel, assetType: assetType))
        if let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure = sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure {
            return await sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure(body, geoURI, description, zoomLevel, assetType)
        } else {
            return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValue
        }
    }
    //MARK: - sendVoiceMessage

    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCallsCount = 0
    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCalled: Bool {
        return sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCallsCount > 0
    }
    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleReturnValue: Result<Void, RoomProxyError>!
    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleClosure: ((URL, AudioInfo, [UInt16], CurrentValueSubject<Double, Never>?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>)?

    func sendVoiceMessage(url: URL, audioInfo: AudioInfo, waveform: [UInt16], progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCallsCount += 1
        if let sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleClosure = sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleClosure {
            return await sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleClosure(url, audioInfo, waveform, progressSubject, requestHandle)
        } else {
            return sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleReturnValue
        }
    }
    //MARK: - retrySend

    var retrySendTransactionIDCallsCount = 0
    var retrySendTransactionIDCalled: Bool {
        return retrySendTransactionIDCallsCount > 0
    }
    var retrySendTransactionIDReceivedTransactionID: String?
    var retrySendTransactionIDReceivedInvocations: [String] = []
    var retrySendTransactionIDClosure: ((String) async -> Void)?

    func retrySend(transactionID: String) async {
        retrySendTransactionIDCallsCount += 1
        retrySendTransactionIDReceivedTransactionID = transactionID
        retrySendTransactionIDReceivedInvocations.append(transactionID)
        await retrySendTransactionIDClosure?(transactionID)
    }
    //MARK: - cancelSend

    var cancelSendTransactionIDCallsCount = 0
    var cancelSendTransactionIDCalled: Bool {
        return cancelSendTransactionIDCallsCount > 0
    }
    var cancelSendTransactionIDReceivedTransactionID: String?
    var cancelSendTransactionIDReceivedInvocations: [String] = []
    var cancelSendTransactionIDClosure: ((String) async -> Void)?

    func cancelSend(transactionID: String) async {
        cancelSendTransactionIDCallsCount += 1
        cancelSendTransactionIDReceivedTransactionID = transactionID
        cancelSendTransactionIDReceivedInvocations.append(transactionID)
        await cancelSendTransactionIDClosure?(transactionID)
    }
    //MARK: - editMessage

    var editMessageHtmlOriginalIntentionalMentionsCallsCount = 0
    var editMessageHtmlOriginalIntentionalMentionsCalled: Bool {
        return editMessageHtmlOriginalIntentionalMentionsCallsCount > 0
    }
    var editMessageHtmlOriginalIntentionalMentionsReceivedArguments: (newMessage: String, html: String?, eventID: String, intentionalMentions: IntentionalMentions)?
    var editMessageHtmlOriginalIntentionalMentionsReceivedInvocations: [(newMessage: String, html: String?, eventID: String, intentionalMentions: IntentionalMentions)] = []
    var editMessageHtmlOriginalIntentionalMentionsReturnValue: Result<Void, RoomProxyError>!
    var editMessageHtmlOriginalIntentionalMentionsClosure: ((String, String?, String, IntentionalMentions) async -> Result<Void, RoomProxyError>)?

    func editMessage(_ newMessage: String, html: String?, original eventID: String, intentionalMentions: IntentionalMentions) async -> Result<Void, RoomProxyError> {
        editMessageHtmlOriginalIntentionalMentionsCallsCount += 1
        editMessageHtmlOriginalIntentionalMentionsReceivedArguments = (newMessage: newMessage, html: html, eventID: eventID, intentionalMentions: intentionalMentions)
        editMessageHtmlOriginalIntentionalMentionsReceivedInvocations.append((newMessage: newMessage, html: html, eventID: eventID, intentionalMentions: intentionalMentions))
        if let editMessageHtmlOriginalIntentionalMentionsClosure = editMessageHtmlOriginalIntentionalMentionsClosure {
            return await editMessageHtmlOriginalIntentionalMentionsClosure(newMessage, html, eventID, intentionalMentions)
        } else {
            return editMessageHtmlOriginalIntentionalMentionsReturnValue
        }
    }
    //MARK: - redact

    var redactCallsCount = 0
    var redactCalled: Bool {
        return redactCallsCount > 0
    }
    var redactReceivedEventID: String?
    var redactReceivedInvocations: [String] = []
    var redactReturnValue: Result<Void, RoomProxyError>!
    var redactClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        redactCallsCount += 1
        redactReceivedEventID = eventID
        redactReceivedInvocations.append(eventID)
        if let redactClosure = redactClosure {
            return await redactClosure(eventID)
        } else {
            return redactReturnValue
        }
    }
    //MARK: - reportContent

    var reportContentReasonCallsCount = 0
    var reportContentReasonCalled: Bool {
        return reportContentReasonCallsCount > 0
    }
    var reportContentReasonReceivedArguments: (eventID: String, reason: String?)?
    var reportContentReasonReceivedInvocations: [(eventID: String, reason: String?)] = []
    var reportContentReasonReturnValue: Result<Void, RoomProxyError>!
    var reportContentReasonClosure: ((String, String?) async -> Result<Void, RoomProxyError>)?

    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        reportContentReasonCallsCount += 1
        reportContentReasonReceivedArguments = (eventID: eventID, reason: reason)
        reportContentReasonReceivedInvocations.append((eventID: eventID, reason: reason))
        if let reportContentReasonClosure = reportContentReasonClosure {
            return await reportContentReasonClosure(eventID, reason)
        } else {
            return reportContentReasonReturnValue
        }
    }
    //MARK: - ignoreUser

    var ignoreUserCallsCount = 0
    var ignoreUserCalled: Bool {
        return ignoreUserCallsCount > 0
    }
    var ignoreUserReceivedUserID: String?
    var ignoreUserReceivedInvocations: [String] = []
    var ignoreUserReturnValue: Result<Void, RoomProxyError>!
    var ignoreUserClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func ignoreUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        ignoreUserCallsCount += 1
        ignoreUserReceivedUserID = userID
        ignoreUserReceivedInvocations.append(userID)
        if let ignoreUserClosure = ignoreUserClosure {
            return await ignoreUserClosure(userID)
        } else {
            return ignoreUserReturnValue
        }
    }
    //MARK: - retryDecryption

    var retryDecryptionForCallsCount = 0
    var retryDecryptionForCalled: Bool {
        return retryDecryptionForCallsCount > 0
    }
    var retryDecryptionForReceivedSessionID: String?
    var retryDecryptionForReceivedInvocations: [String] = []
    var retryDecryptionForClosure: ((String) async -> Void)?

    func retryDecryption(for sessionID: String) async {
        retryDecryptionForCallsCount += 1
        retryDecryptionForReceivedSessionID = sessionID
        retryDecryptionForReceivedInvocations.append(sessionID)
        await retryDecryptionForClosure?(sessionID)
    }
    //MARK: - leaveRoom

    var leaveRoomCallsCount = 0
    var leaveRoomCalled: Bool {
        return leaveRoomCallsCount > 0
    }
    var leaveRoomReturnValue: Result<Void, RoomProxyError>!
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

    var updateMembersCallsCount = 0
    var updateMembersCalled: Bool {
        return updateMembersCallsCount > 0
    }
    var updateMembersClosure: (() async -> Void)?

    func updateMembers() async {
        updateMembersCallsCount += 1
        await updateMembersClosure?()
    }
    //MARK: - getMember

    var getMemberUserIDCallsCount = 0
    var getMemberUserIDCalled: Bool {
        return getMemberUserIDCallsCount > 0
    }
    var getMemberUserIDReceivedUserID: String?
    var getMemberUserIDReceivedInvocations: [String] = []
    var getMemberUserIDReturnValue: Result<RoomMemberProxyProtocol, RoomProxyError>!
    var getMemberUserIDClosure: ((String) async -> Result<RoomMemberProxyProtocol, RoomProxyError>)?

    func getMember(userID: String) async -> Result<RoomMemberProxyProtocol, RoomProxyError> {
        getMemberUserIDCallsCount += 1
        getMemberUserIDReceivedUserID = userID
        getMemberUserIDReceivedInvocations.append(userID)
        if let getMemberUserIDClosure = getMemberUserIDClosure {
            return await getMemberUserIDClosure(userID)
        } else {
            return getMemberUserIDReturnValue
        }
    }
    //MARK: - inviter

    var inviterCallsCount = 0
    var inviterCalled: Bool {
        return inviterCallsCount > 0
    }
    var inviterReturnValue: RoomMemberProxyProtocol?
    var inviterClosure: (() async -> RoomMemberProxyProtocol?)?

    func inviter() async -> RoomMemberProxyProtocol? {
        inviterCallsCount += 1
        if let inviterClosure = inviterClosure {
            return await inviterClosure()
        } else {
            return inviterReturnValue
        }
    }
    //MARK: - rejectInvitation

    var rejectInvitationCallsCount = 0
    var rejectInvitationCalled: Bool {
        return rejectInvitationCallsCount > 0
    }
    var rejectInvitationReturnValue: Result<Void, RoomProxyError>!
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

    var acceptInvitationCallsCount = 0
    var acceptInvitationCalled: Bool {
        return acceptInvitationCallsCount > 0
    }
    var acceptInvitationReturnValue: Result<Void, RoomProxyError>!
    var acceptInvitationClosure: (() async -> Result<Void, RoomProxyError>)?

    func acceptInvitation() async -> Result<Void, RoomProxyError> {
        acceptInvitationCallsCount += 1
        if let acceptInvitationClosure = acceptInvitationClosure {
            return await acceptInvitationClosure()
        } else {
            return acceptInvitationReturnValue
        }
    }
    //MARK: - fetchDetails

    var fetchDetailsForCallsCount = 0
    var fetchDetailsForCalled: Bool {
        return fetchDetailsForCallsCount > 0
    }
    var fetchDetailsForReceivedEventID: String?
    var fetchDetailsForReceivedInvocations: [String] = []
    var fetchDetailsForClosure: ((String) -> Void)?

    func fetchDetails(for eventID: String) {
        fetchDetailsForCallsCount += 1
        fetchDetailsForReceivedEventID = eventID
        fetchDetailsForReceivedInvocations.append(eventID)
        fetchDetailsForClosure?(eventID)
    }
    //MARK: - invite

    var inviteUserIDCallsCount = 0
    var inviteUserIDCalled: Bool {
        return inviteUserIDCallsCount > 0
    }
    var inviteUserIDReceivedUserID: String?
    var inviteUserIDReceivedInvocations: [String] = []
    var inviteUserIDReturnValue: Result<Void, RoomProxyError>!
    var inviteUserIDClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func invite(userID: String) async -> Result<Void, RoomProxyError> {
        inviteUserIDCallsCount += 1
        inviteUserIDReceivedUserID = userID
        inviteUserIDReceivedInvocations.append(userID)
        if let inviteUserIDClosure = inviteUserIDClosure {
            return await inviteUserIDClosure(userID)
        } else {
            return inviteUserIDReturnValue
        }
    }
    //MARK: - setName

    var setNameCallsCount = 0
    var setNameCalled: Bool {
        return setNameCallsCount > 0
    }
    var setNameReceivedName: String?
    var setNameReceivedInvocations: [String] = []
    var setNameReturnValue: Result<Void, RoomProxyError>!
    var setNameClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func setName(_ name: String) async -> Result<Void, RoomProxyError> {
        setNameCallsCount += 1
        setNameReceivedName = name
        setNameReceivedInvocations.append(name)
        if let setNameClosure = setNameClosure {
            return await setNameClosure(name)
        } else {
            return setNameReturnValue
        }
    }
    //MARK: - setTopic

    var setTopicCallsCount = 0
    var setTopicCalled: Bool {
        return setTopicCallsCount > 0
    }
    var setTopicReceivedTopic: String?
    var setTopicReceivedInvocations: [String] = []
    var setTopicReturnValue: Result<Void, RoomProxyError>!
    var setTopicClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func setTopic(_ topic: String) async -> Result<Void, RoomProxyError> {
        setTopicCallsCount += 1
        setTopicReceivedTopic = topic
        setTopicReceivedInvocations.append(topic)
        if let setTopicClosure = setTopicClosure {
            return await setTopicClosure(topic)
        } else {
            return setTopicReturnValue
        }
    }
    //MARK: - removeAvatar

    var removeAvatarCallsCount = 0
    var removeAvatarCalled: Bool {
        return removeAvatarCallsCount > 0
    }
    var removeAvatarReturnValue: Result<Void, RoomProxyError>!
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

    var uploadAvatarMediaCallsCount = 0
    var uploadAvatarMediaCalled: Bool {
        return uploadAvatarMediaCallsCount > 0
    }
    var uploadAvatarMediaReceivedMedia: MediaInfo?
    var uploadAvatarMediaReceivedInvocations: [MediaInfo] = []
    var uploadAvatarMediaReturnValue: Result<Void, RoomProxyError>!
    var uploadAvatarMediaClosure: ((MediaInfo) async -> Result<Void, RoomProxyError>)?

    func uploadAvatar(media: MediaInfo) async -> Result<Void, RoomProxyError> {
        uploadAvatarMediaCallsCount += 1
        uploadAvatarMediaReceivedMedia = media
        uploadAvatarMediaReceivedInvocations.append(media)
        if let uploadAvatarMediaClosure = uploadAvatarMediaClosure {
            return await uploadAvatarMediaClosure(media)
        } else {
            return uploadAvatarMediaReturnValue
        }
    }
    //MARK: - canUserRedact

    var canUserRedactUserIDCallsCount = 0
    var canUserRedactUserIDCalled: Bool {
        return canUserRedactUserIDCallsCount > 0
    }
    var canUserRedactUserIDReceivedUserID: String?
    var canUserRedactUserIDReceivedInvocations: [String] = []
    var canUserRedactUserIDReturnValue: Result<Bool, RoomProxyError>!
    var canUserRedactUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserRedact(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserRedactUserIDCallsCount += 1
        canUserRedactUserIDReceivedUserID = userID
        canUserRedactUserIDReceivedInvocations.append(userID)
        if let canUserRedactUserIDClosure = canUserRedactUserIDClosure {
            return await canUserRedactUserIDClosure(userID)
        } else {
            return canUserRedactUserIDReturnValue
        }
    }
    //MARK: - canUserTriggerRoomNotification

    var canUserTriggerRoomNotificationUserIDCallsCount = 0
    var canUserTriggerRoomNotificationUserIDCalled: Bool {
        return canUserTriggerRoomNotificationUserIDCallsCount > 0
    }
    var canUserTriggerRoomNotificationUserIDReceivedUserID: String?
    var canUserTriggerRoomNotificationUserIDReceivedInvocations: [String] = []
    var canUserTriggerRoomNotificationUserIDReturnValue: Result<Bool, RoomProxyError>!
    var canUserTriggerRoomNotificationUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserTriggerRoomNotification(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserTriggerRoomNotificationUserIDCallsCount += 1
        canUserTriggerRoomNotificationUserIDReceivedUserID = userID
        canUserTriggerRoomNotificationUserIDReceivedInvocations.append(userID)
        if let canUserTriggerRoomNotificationUserIDClosure = canUserTriggerRoomNotificationUserIDClosure {
            return await canUserTriggerRoomNotificationUserIDClosure(userID)
        } else {
            return canUserTriggerRoomNotificationUserIDReturnValue
        }
    }
    //MARK: - createPoll

    var createPollQuestionAnswersPollKindCallsCount = 0
    var createPollQuestionAnswersPollKindCalled: Bool {
        return createPollQuestionAnswersPollKindCallsCount > 0
    }
    var createPollQuestionAnswersPollKindReceivedArguments: (question: String, answers: [String], pollKind: Poll.Kind)?
    var createPollQuestionAnswersPollKindReceivedInvocations: [(question: String, answers: [String], pollKind: Poll.Kind)] = []
    var createPollQuestionAnswersPollKindReturnValue: Result<Void, RoomProxyError>!
    var createPollQuestionAnswersPollKindClosure: ((String, [String], Poll.Kind) async -> Result<Void, RoomProxyError>)?

    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, RoomProxyError> {
        createPollQuestionAnswersPollKindCallsCount += 1
        createPollQuestionAnswersPollKindReceivedArguments = (question: question, answers: answers, pollKind: pollKind)
        createPollQuestionAnswersPollKindReceivedInvocations.append((question: question, answers: answers, pollKind: pollKind))
        if let createPollQuestionAnswersPollKindClosure = createPollQuestionAnswersPollKindClosure {
            return await createPollQuestionAnswersPollKindClosure(question, answers, pollKind)
        } else {
            return createPollQuestionAnswersPollKindReturnValue
        }
    }
    //MARK: - sendPollResponse

    var sendPollResponsePollStartIDAnswersCallsCount = 0
    var sendPollResponsePollStartIDAnswersCalled: Bool {
        return sendPollResponsePollStartIDAnswersCallsCount > 0
    }
    var sendPollResponsePollStartIDAnswersReceivedArguments: (pollStartID: String, answers: [String])?
    var sendPollResponsePollStartIDAnswersReceivedInvocations: [(pollStartID: String, answers: [String])] = []
    var sendPollResponsePollStartIDAnswersReturnValue: Result<Void, RoomProxyError>!
    var sendPollResponsePollStartIDAnswersClosure: ((String, [String]) async -> Result<Void, RoomProxyError>)?

    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, RoomProxyError> {
        sendPollResponsePollStartIDAnswersCallsCount += 1
        sendPollResponsePollStartIDAnswersReceivedArguments = (pollStartID: pollStartID, answers: answers)
        sendPollResponsePollStartIDAnswersReceivedInvocations.append((pollStartID: pollStartID, answers: answers))
        if let sendPollResponsePollStartIDAnswersClosure = sendPollResponsePollStartIDAnswersClosure {
            return await sendPollResponsePollStartIDAnswersClosure(pollStartID, answers)
        } else {
            return sendPollResponsePollStartIDAnswersReturnValue
        }
    }
    //MARK: - endPoll

    var endPollPollStartIDTextCallsCount = 0
    var endPollPollStartIDTextCalled: Bool {
        return endPollPollStartIDTextCallsCount > 0
    }
    var endPollPollStartIDTextReceivedArguments: (pollStartID: String, text: String)?
    var endPollPollStartIDTextReceivedInvocations: [(pollStartID: String, text: String)] = []
    var endPollPollStartIDTextReturnValue: Result<Void, RoomProxyError>!
    var endPollPollStartIDTextClosure: ((String, String) async -> Result<Void, RoomProxyError>)?

    func endPoll(pollStartID: String, text: String) async -> Result<Void, RoomProxyError> {
        endPollPollStartIDTextCallsCount += 1
        endPollPollStartIDTextReceivedArguments = (pollStartID: pollStartID, text: text)
        endPollPollStartIDTextReceivedInvocations.append((pollStartID: pollStartID, text: text))
        if let endPollPollStartIDTextClosure = endPollPollStartIDTextClosure {
            return await endPollPollStartIDTextClosure(pollStartID, text)
        } else {
            return endPollPollStartIDTextReturnValue
        }
    }
    //MARK: - elementCallWidgetDriver

    var elementCallWidgetDriverCallsCount = 0
    var elementCallWidgetDriverCalled: Bool {
        return elementCallWidgetDriverCallsCount > 0
    }
    var elementCallWidgetDriverReturnValue: ElementCallWidgetDriverProtocol!
    var elementCallWidgetDriverClosure: (() -> ElementCallWidgetDriverProtocol)?

    func elementCallWidgetDriver() -> ElementCallWidgetDriverProtocol {
        elementCallWidgetDriverCallsCount += 1
        if let elementCallWidgetDriverClosure = elementCallWidgetDriverClosure {
            return elementCallWidgetDriverClosure()
        } else {
            return elementCallWidgetDriverReturnValue
        }
    }
}
class RoomTimelineProviderMock: RoomTimelineProviderProtocol {
    var updatePublisher: AnyPublisher<TimelineProviderUpdate, Never> {
        get { return underlyingUpdatePublisher }
        set(value) { underlyingUpdatePublisher = value }
    }
    var underlyingUpdatePublisher: AnyPublisher<TimelineProviderUpdate, Never>!
    var itemProxies: [TimelineItemProxy] = []
    var backPaginationState: BackPaginationStatus {
        get { return underlyingBackPaginationState }
        set(value) { underlyingBackPaginationState = value }
    }
    var underlyingBackPaginationState: BackPaginationStatus!

}
class SecureBackupControllerMock: SecureBackupControllerProtocol {
    var recoveryKeyState: CurrentValuePublisher<SecureBackupRecoveryKeyState, Never> {
        get { return underlyingRecoveryKeyState }
        set(value) { underlyingRecoveryKeyState = value }
    }
    var underlyingRecoveryKeyState: CurrentValuePublisher<SecureBackupRecoveryKeyState, Never>!
    var keyBackupState: CurrentValuePublisher<SecureBackupKeyBackupState, Never> {
        get { return underlyingKeyBackupState }
        set(value) { underlyingKeyBackupState = value }
    }
    var underlyingKeyBackupState: CurrentValuePublisher<SecureBackupKeyBackupState, Never>!

    //MARK: - enable

    var enableCallsCount = 0
    var enableCalled: Bool {
        return enableCallsCount > 0
    }
    var enableReturnValue: Result<Void, SecureBackupControllerError>!
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

    var disableCallsCount = 0
    var disableCalled: Bool {
        return disableCallsCount > 0
    }
    var disableReturnValue: Result<Void, SecureBackupControllerError>!
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

    var generateRecoveryKeyCallsCount = 0
    var generateRecoveryKeyCalled: Bool {
        return generateRecoveryKeyCallsCount > 0
    }
    var generateRecoveryKeyReturnValue: Result<String, SecureBackupControllerError>!
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

    var confirmRecoveryKeyCallsCount = 0
    var confirmRecoveryKeyCalled: Bool {
        return confirmRecoveryKeyCallsCount > 0
    }
    var confirmRecoveryKeyReceivedKey: String?
    var confirmRecoveryKeyReceivedInvocations: [String] = []
    var confirmRecoveryKeyReturnValue: Result<Void, SecureBackupControllerError>!
    var confirmRecoveryKeyClosure: ((String) async -> Result<Void, SecureBackupControllerError>)?

    func confirmRecoveryKey(_ key: String) async -> Result<Void, SecureBackupControllerError> {
        confirmRecoveryKeyCallsCount += 1
        confirmRecoveryKeyReceivedKey = key
        confirmRecoveryKeyReceivedInvocations.append(key)
        if let confirmRecoveryKeyClosure = confirmRecoveryKeyClosure {
            return await confirmRecoveryKeyClosure(key)
        } else {
            return confirmRecoveryKeyReturnValue
        }
    }
    //MARK: - isLastSession

    var isLastSessionCallsCount = 0
    var isLastSessionCalled: Bool {
        return isLastSessionCallsCount > 0
    }
    var isLastSessionReturnValue: Result<Bool, SecureBackupControllerError>!
    var isLastSessionClosure: (() async -> Result<Bool, SecureBackupControllerError>)?

    func isLastSession() async -> Result<Bool, SecureBackupControllerError> {
        isLastSessionCallsCount += 1
        if let isLastSessionClosure = isLastSessionClosure {
            return await isLastSessionClosure()
        } else {
            return isLastSessionReturnValue
        }
    }
    //MARK: - waitForKeyBackupUpload

    var waitForKeyBackupUploadCallsCount = 0
    var waitForKeyBackupUploadCalled: Bool {
        return waitForKeyBackupUploadCallsCount > 0
    }
    var waitForKeyBackupUploadReturnValue: Result<Void, SecureBackupControllerError>!
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

    //MARK: - isVerified

    var isVerifiedCallsCount = 0
    var isVerifiedCalled: Bool {
        return isVerifiedCallsCount > 0
    }
    var isVerifiedReturnValue: Result<Bool, SessionVerificationControllerProxyError>!
    var isVerifiedClosure: (() async -> Result<Bool, SessionVerificationControllerProxyError>)?

    func isVerified() async -> Result<Bool, SessionVerificationControllerProxyError> {
        isVerifiedCallsCount += 1
        if let isVerifiedClosure = isVerifiedClosure {
            return await isVerifiedClosure()
        } else {
            return isVerifiedReturnValue
        }
    }
    //MARK: - requestVerification

    var requestVerificationCallsCount = 0
    var requestVerificationCalled: Bool {
        return requestVerificationCallsCount > 0
    }
    var requestVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>!
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

    var startSasVerificationCallsCount = 0
    var startSasVerificationCalled: Bool {
        return startSasVerificationCallsCount > 0
    }
    var startSasVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>!
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

    var approveVerificationCallsCount = 0
    var approveVerificationCalled: Bool {
        return approveVerificationCallsCount > 0
    }
    var approveVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>!
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

    var declineVerificationCallsCount = 0
    var declineVerificationCalled: Bool {
        return declineVerificationCallsCount > 0
    }
    var declineVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>!
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

    var cancelVerificationCallsCount = 0
    var cancelVerificationCalled: Bool {
        return cancelVerificationCallsCount > 0
    }
    var cancelVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>!
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
class UserDiscoveryServiceMock: UserDiscoveryServiceProtocol {

    //MARK: - searchProfiles

    var searchProfilesWithCallsCount = 0
    var searchProfilesWithCalled: Bool {
        return searchProfilesWithCallsCount > 0
    }
    var searchProfilesWithReceivedSearchQuery: String?
    var searchProfilesWithReceivedInvocations: [String] = []
    var searchProfilesWithReturnValue: Result<[UserProfileProxy], UserDiscoveryErrorType>!
    var searchProfilesWithClosure: ((String) async -> Result<[UserProfileProxy], UserDiscoveryErrorType>)?

    func searchProfiles(with searchQuery: String) async -> Result<[UserProfileProxy], UserDiscoveryErrorType> {
        searchProfilesWithCallsCount += 1
        searchProfilesWithReceivedSearchQuery = searchQuery
        searchProfilesWithReceivedInvocations.append(searchQuery)
        if let searchProfilesWithClosure = searchProfilesWithClosure {
            return await searchProfilesWithClosure(searchQuery)
        } else {
            return searchProfilesWithReturnValue
        }
    }
    //MARK: - fetchSuggestions

    var fetchSuggestionsCallsCount = 0
    var fetchSuggestionsCalled: Bool {
        return fetchSuggestionsCallsCount > 0
    }
    var fetchSuggestionsReturnValue: Result<[UserProfileProxy], UserDiscoveryErrorType>!
    var fetchSuggestionsClosure: (() async -> Result<[UserProfileProxy], UserDiscoveryErrorType>)?

    func fetchSuggestions() async -> Result<[UserProfileProxy], UserDiscoveryErrorType> {
        fetchSuggestionsCallsCount += 1
        if let fetchSuggestionsClosure = fetchSuggestionsClosure {
            return await fetchSuggestionsClosure()
        } else {
            return fetchSuggestionsReturnValue
        }
    }
}
class UserIndicatorControllerMock: UserIndicatorControllerProtocol {
    var window: UIWindow?
    var alertInfo: AlertInfo<UUID>?

    //MARK: - submitIndicator

    var submitIndicatorDelayCallsCount = 0
    var submitIndicatorDelayCalled: Bool {
        return submitIndicatorDelayCallsCount > 0
    }
    var submitIndicatorDelayReceivedArguments: (indicator: UserIndicator, delay: Duration?)?
    var submitIndicatorDelayReceivedInvocations: [(indicator: UserIndicator, delay: Duration?)] = []
    var submitIndicatorDelayClosure: ((UserIndicator, Duration?) -> Void)?

    func submitIndicator(_ indicator: UserIndicator, delay: Duration?) {
        submitIndicatorDelayCallsCount += 1
        submitIndicatorDelayReceivedArguments = (indicator: indicator, delay: delay)
        submitIndicatorDelayReceivedInvocations.append((indicator: indicator, delay: delay))
        submitIndicatorDelayClosure?(indicator, delay)
    }
    //MARK: - retractIndicatorWithId

    var retractIndicatorWithIdCallsCount = 0
    var retractIndicatorWithIdCalled: Bool {
        return retractIndicatorWithIdCallsCount > 0
    }
    var retractIndicatorWithIdReceivedId: String?
    var retractIndicatorWithIdReceivedInvocations: [String] = []
    var retractIndicatorWithIdClosure: ((String) -> Void)?

    func retractIndicatorWithId(_ id: String) {
        retractIndicatorWithIdCallsCount += 1
        retractIndicatorWithIdReceivedId = id
        retractIndicatorWithIdReceivedInvocations.append(id)
        retractIndicatorWithIdClosure?(id)
    }
    //MARK: - retractAllIndicators

    var retractAllIndicatorsCallsCount = 0
    var retractAllIndicatorsCalled: Bool {
        return retractAllIndicatorsCallsCount > 0
    }
    var retractAllIndicatorsClosure: (() -> Void)?

    func retractAllIndicators() {
        retractAllIndicatorsCallsCount += 1
        retractAllIndicatorsClosure?()
    }
    //MARK: - start

    var startCallsCount = 0
    var startCalled: Bool {
        return startCallsCount > 0
    }
    var startClosure: (() -> Void)?

    func start() {
        startCallsCount += 1
        startClosure?()
    }
    //MARK: - stop

    var stopCallsCount = 0
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCount += 1
        stopClosure?()
    }
    //MARK: - toPresentable

    var toPresentableCallsCount = 0
    var toPresentableCalled: Bool {
        return toPresentableCallsCount > 0
    }
    var toPresentableReturnValue: AnyView!
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
    var addCallsCount = 0
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
        addReceivedInvocations.append(request)
        try await addClosure?(request)
    }
    //MARK: - requestAuthorization

    var requestAuthorizationOptionsThrowableError: Error?
    var requestAuthorizationOptionsCallsCount = 0
    var requestAuthorizationOptionsCalled: Bool {
        return requestAuthorizationOptionsCallsCount > 0
    }
    var requestAuthorizationOptionsReceivedOptions: UNAuthorizationOptions?
    var requestAuthorizationOptionsReceivedInvocations: [UNAuthorizationOptions] = []
    var requestAuthorizationOptionsReturnValue: Bool!
    var requestAuthorizationOptionsClosure: ((UNAuthorizationOptions) async throws -> Bool)?

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        if let error = requestAuthorizationOptionsThrowableError {
            throw error
        }
        requestAuthorizationOptionsCallsCount += 1
        requestAuthorizationOptionsReceivedOptions = options
        requestAuthorizationOptionsReceivedInvocations.append(options)
        if let requestAuthorizationOptionsClosure = requestAuthorizationOptionsClosure {
            return try await requestAuthorizationOptionsClosure(options)
        } else {
            return requestAuthorizationOptionsReturnValue
        }
    }
    //MARK: - deliveredNotifications

    var deliveredNotificationsCallsCount = 0
    var deliveredNotificationsCalled: Bool {
        return deliveredNotificationsCallsCount > 0
    }
    var deliveredNotificationsReturnValue: [UNNotification]!
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

    var removeDeliveredNotificationsWithIdentifiersCallsCount = 0
    var removeDeliveredNotificationsWithIdentifiersCalled: Bool {
        return removeDeliveredNotificationsWithIdentifiersCallsCount > 0
    }
    var removeDeliveredNotificationsWithIdentifiersReceivedIdentifiers: [String]?
    var removeDeliveredNotificationsWithIdentifiersReceivedInvocations: [[String]] = []
    var removeDeliveredNotificationsWithIdentifiersClosure: (([String]) -> Void)?

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removeDeliveredNotificationsWithIdentifiersCallsCount += 1
        removeDeliveredNotificationsWithIdentifiersReceivedIdentifiers = identifiers
        removeDeliveredNotificationsWithIdentifiersReceivedInvocations.append(identifiers)
        removeDeliveredNotificationsWithIdentifiersClosure?(identifiers)
    }
    //MARK: - setNotificationCategories

    var setNotificationCategoriesCallsCount = 0
    var setNotificationCategoriesCalled: Bool {
        return setNotificationCategoriesCallsCount > 0
    }
    var setNotificationCategoriesReceivedCategories: Set<UNNotificationCategory>?
    var setNotificationCategoriesReceivedInvocations: [Set<UNNotificationCategory>] = []
    var setNotificationCategoriesClosure: ((Set<UNNotificationCategory>) -> Void)?

    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        setNotificationCategoriesCallsCount += 1
        setNotificationCategoriesReceivedCategories = categories
        setNotificationCategoriesReceivedInvocations.append(categories)
        setNotificationCategoriesClosure?(categories)
    }
    //MARK: - authorizationStatus

    var authorizationStatusCallsCount = 0
    var authorizationStatusCalled: Bool {
        return authorizationStatusCallsCount > 0
    }
    var authorizationStatusReturnValue: UNAuthorizationStatus!
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
class VoiceMessageCacheMock: VoiceMessageCacheProtocol {

    //MARK: - fileURL

    var fileURLForCallsCount = 0
    var fileURLForCalled: Bool {
        return fileURLForCallsCount > 0
    }
    var fileURLForReceivedMediaSource: MediaSourceProxy?
    var fileURLForReceivedInvocations: [MediaSourceProxy] = []
    var fileURLForReturnValue: URL?
    var fileURLForClosure: ((MediaSourceProxy) -> URL?)?

    func fileURL(for mediaSource: MediaSourceProxy) -> URL? {
        fileURLForCallsCount += 1
        fileURLForReceivedMediaSource = mediaSource
        fileURLForReceivedInvocations.append(mediaSource)
        if let fileURLForClosure = fileURLForClosure {
            return fileURLForClosure(mediaSource)
        } else {
            return fileURLForReturnValue
        }
    }
    //MARK: - cache

    var cacheMediaSourceUsingMoveCallsCount = 0
    var cacheMediaSourceUsingMoveCalled: Bool {
        return cacheMediaSourceUsingMoveCallsCount > 0
    }
    var cacheMediaSourceUsingMoveReceivedArguments: (mediaSource: MediaSourceProxy, fileURL: URL, move: Bool)?
    var cacheMediaSourceUsingMoveReceivedInvocations: [(mediaSource: MediaSourceProxy, fileURL: URL, move: Bool)] = []
    var cacheMediaSourceUsingMoveReturnValue: Result<URL, VoiceMessageCacheError>!
    var cacheMediaSourceUsingMoveClosure: ((MediaSourceProxy, URL, Bool) -> Result<URL, VoiceMessageCacheError>)?

    func cache(mediaSource: MediaSourceProxy, using fileURL: URL, move: Bool) -> Result<URL, VoiceMessageCacheError> {
        cacheMediaSourceUsingMoveCallsCount += 1
        cacheMediaSourceUsingMoveReceivedArguments = (mediaSource: mediaSource, fileURL: fileURL, move: move)
        cacheMediaSourceUsingMoveReceivedInvocations.append((mediaSource: mediaSource, fileURL: fileURL, move: move))
        if let cacheMediaSourceUsingMoveClosure = cacheMediaSourceUsingMoveClosure {
            return cacheMediaSourceUsingMoveClosure(mediaSource, fileURL, move)
        } else {
            return cacheMediaSourceUsingMoveReturnValue
        }
    }
    //MARK: - clearCache

    var clearCacheCallsCount = 0
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
    var loadVoiceMessageFromSourceBodyCallsCount = 0
    var loadVoiceMessageFromSourceBodyCalled: Bool {
        return loadVoiceMessageFromSourceBodyCallsCount > 0
    }
    var loadVoiceMessageFromSourceBodyReceivedArguments: (source: MediaSourceProxy, body: String?)?
    var loadVoiceMessageFromSourceBodyReceivedInvocations: [(source: MediaSourceProxy, body: String?)] = []
    var loadVoiceMessageFromSourceBodyReturnValue: URL!
    var loadVoiceMessageFromSourceBodyClosure: ((MediaSourceProxy, String?) async throws -> URL)?

    func loadVoiceMessageFromSource(_ source: MediaSourceProxy, body: String?) async throws -> URL {
        if let error = loadVoiceMessageFromSourceBodyThrowableError {
            throw error
        }
        loadVoiceMessageFromSourceBodyCallsCount += 1
        loadVoiceMessageFromSourceBodyReceivedArguments = (source: source, body: body)
        loadVoiceMessageFromSourceBodyReceivedInvocations.append((source: source, body: body))
        if let loadVoiceMessageFromSourceBodyClosure = loadVoiceMessageFromSourceBodyClosure {
            return try await loadVoiceMessageFromSourceBodyClosure(source, body)
        } else {
            return loadVoiceMessageFromSourceBodyReturnValue
        }
    }
}
class VoiceMessageRecorderMock: VoiceMessageRecorderProtocol {
    var audioRecorder: AudioRecorderProtocol {
        get { return underlyingAudioRecorder }
        set(value) { underlyingAudioRecorder = value }
    }
    var underlyingAudioRecorder: AudioRecorderProtocol!
    var previewAudioPlayerState: AudioPlayerState?
    var recordingURL: URL?
    var recordingDuration: TimeInterval {
        get { return underlyingRecordingDuration }
        set(value) { underlyingRecordingDuration = value }
    }
    var underlyingRecordingDuration: TimeInterval!
    var actions: AnyPublisher<VoiceMessageRecorderAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<VoiceMessageRecorderAction, Never>!

    //MARK: - startRecording

    var startRecordingCallsCount = 0
    var startRecordingCalled: Bool {
        return startRecordingCallsCount > 0
    }
    var startRecordingClosure: (() async -> Void)?

    func startRecording() async {
        startRecordingCallsCount += 1
        await startRecordingClosure?()
    }
    //MARK: - stopRecording

    var stopRecordingCallsCount = 0
    var stopRecordingCalled: Bool {
        return stopRecordingCallsCount > 0
    }
    var stopRecordingClosure: (() async -> Void)?

    func stopRecording() async {
        stopRecordingCallsCount += 1
        await stopRecordingClosure?()
    }
    //MARK: - cancelRecording

    var cancelRecordingCallsCount = 0
    var cancelRecordingCalled: Bool {
        return cancelRecordingCallsCount > 0
    }
    var cancelRecordingClosure: (() async -> Void)?

    func cancelRecording() async {
        cancelRecordingCallsCount += 1
        await cancelRecordingClosure?()
    }
    //MARK: - startPlayback

    var startPlaybackCallsCount = 0
    var startPlaybackCalled: Bool {
        return startPlaybackCallsCount > 0
    }
    var startPlaybackReturnValue: Result<Void, VoiceMessageRecorderError>!
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

    var pausePlaybackCallsCount = 0
    var pausePlaybackCalled: Bool {
        return pausePlaybackCallsCount > 0
    }
    var pausePlaybackClosure: (() -> Void)?

    func pausePlayback() {
        pausePlaybackCallsCount += 1
        pausePlaybackClosure?()
    }
    //MARK: - stopPlayback

    var stopPlaybackCallsCount = 0
    var stopPlaybackCalled: Bool {
        return stopPlaybackCallsCount > 0
    }
    var stopPlaybackClosure: (() async -> Void)?

    func stopPlayback() async {
        stopPlaybackCallsCount += 1
        await stopPlaybackClosure?()
    }
    //MARK: - seekPlayback

    var seekPlaybackToCallsCount = 0
    var seekPlaybackToCalled: Bool {
        return seekPlaybackToCallsCount > 0
    }
    var seekPlaybackToReceivedProgress: Double?
    var seekPlaybackToReceivedInvocations: [Double] = []
    var seekPlaybackToClosure: ((Double) async -> Void)?

    func seekPlayback(to progress: Double) async {
        seekPlaybackToCallsCount += 1
        seekPlaybackToReceivedProgress = progress
        seekPlaybackToReceivedInvocations.append(progress)
        await seekPlaybackToClosure?(progress)
    }
    //MARK: - deleteRecording

    var deleteRecordingCallsCount = 0
    var deleteRecordingCalled: Bool {
        return deleteRecordingCallsCount > 0
    }
    var deleteRecordingClosure: (() async -> Void)?

    func deleteRecording() async {
        deleteRecordingCallsCount += 1
        await deleteRecordingClosure?()
    }
    //MARK: - buildRecordingWaveform

    var buildRecordingWaveformCallsCount = 0
    var buildRecordingWaveformCalled: Bool {
        return buildRecordingWaveformCallsCount > 0
    }
    var buildRecordingWaveformReturnValue: Result<[UInt16], VoiceMessageRecorderError>!
    var buildRecordingWaveformClosure: (() async -> Result<[UInt16], VoiceMessageRecorderError>)?

    func buildRecordingWaveform() async -> Result<[UInt16], VoiceMessageRecorderError> {
        buildRecordingWaveformCallsCount += 1
        if let buildRecordingWaveformClosure = buildRecordingWaveformClosure {
            return await buildRecordingWaveformClosure()
        } else {
            return buildRecordingWaveformReturnValue
        }
    }
    //MARK: - sendVoiceMessage

    var sendVoiceMessageInRoomAudioConverterCallsCount = 0
    var sendVoiceMessageInRoomAudioConverterCalled: Bool {
        return sendVoiceMessageInRoomAudioConverterCallsCount > 0
    }
    var sendVoiceMessageInRoomAudioConverterReceivedArguments: (roomProxy: RoomProxyProtocol, audioConverter: AudioConverterProtocol)?
    var sendVoiceMessageInRoomAudioConverterReceivedInvocations: [(roomProxy: RoomProxyProtocol, audioConverter: AudioConverterProtocol)] = []
    var sendVoiceMessageInRoomAudioConverterReturnValue: Result<Void, VoiceMessageRecorderError>!
    var sendVoiceMessageInRoomAudioConverterClosure: ((RoomProxyProtocol, AudioConverterProtocol) async -> Result<Void, VoiceMessageRecorderError>)?

    func sendVoiceMessage(inRoom roomProxy: RoomProxyProtocol, audioConverter: AudioConverterProtocol) async -> Result<Void, VoiceMessageRecorderError> {
        sendVoiceMessageInRoomAudioConverterCallsCount += 1
        sendVoiceMessageInRoomAudioConverterReceivedArguments = (roomProxy: roomProxy, audioConverter: audioConverter)
        sendVoiceMessageInRoomAudioConverterReceivedInvocations.append((roomProxy: roomProxy, audioConverter: audioConverter))
        if let sendVoiceMessageInRoomAudioConverterClosure = sendVoiceMessageInRoomAudioConverterClosure {
            return await sendVoiceMessageInRoomAudioConverterClosure(roomProxy, audioConverter)
        } else {
            return sendVoiceMessageInRoomAudioConverterReturnValue
        }
    }
}
// swiftlint:enable all
