// Generated using Sourcery 2.1.7 — https://github.com/krzysztofzablocki/Sourcery
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

    var computeNeedsUnlockDidBecomeActiveAtCallsCount = 0
    var computeNeedsUnlockDidBecomeActiveAtCalled: Bool {
        return computeNeedsUnlockDidBecomeActiveAtCallsCount > 0
    }
    var computeNeedsUnlockDidBecomeActiveAtReceivedDate: Date?
    var computeNeedsUnlockDidBecomeActiveAtReceivedInvocations: [Date] = []
    var computeNeedsUnlockDidBecomeActiveAtReturnValue: Bool!
    var computeNeedsUnlockDidBecomeActiveAtClosure: ((Date) -> Bool)?

    func computeNeedsUnlock(didBecomeActiveAt date: Date) -> Bool {
        computeNeedsUnlockDidBecomeActiveAtCallsCount += 1
        computeNeedsUnlockDidBecomeActiveAtReceivedDate = date
        computeNeedsUnlockDidBecomeActiveAtReceivedInvocations.append(date)
        if let computeNeedsUnlockDidBecomeActiveAtClosure = computeNeedsUnlockDidBecomeActiveAtClosure {
            return computeNeedsUnlockDidBecomeActiveAtClosure(date)
        } else {
            return computeNeedsUnlockDidBecomeActiveAtReturnValue
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
    var unlockWithBiometricsReturnValue: AppLockServiceBiometricResult!
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
    var audioFileURL: URL?

    //MARK: - record

    var recordAudioFileURLCallsCount = 0
    var recordAudioFileURLCalled: Bool {
        return recordAudioFileURLCallsCount > 0
    }
    var recordAudioFileURLReceivedAudioFileURL: URL?
    var recordAudioFileURLReceivedInvocations: [URL] = []
    var recordAudioFileURLClosure: ((URL) async -> Void)?

    func record(audioFileURL: URL) async {
        recordAudioFileURLCallsCount += 1
        recordAudioFileURLReceivedAudioFileURL = audioFileURL
        recordAudioFileURLReceivedInvocations.append(audioFileURL)
        await recordAudioFileURLClosure?(audioFileURL)
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
    var alternateRoomSummaryProvider: RoomSummaryProviderProtocol?
    var inviteSummaryProvider: RoomSummaryProviderProtocol?
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

    var isOnlyDeviceLeftCallsCount = 0
    var isOnlyDeviceLeftCalled: Bool {
        return isOnlyDeviceLeftCallsCount > 0
    }
    var isOnlyDeviceLeftReturnValue: Result<Bool, ClientProxyError>!
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

    var startSyncCallsCount = 0
    var startSyncCalled: Bool {
        return startSyncCallsCount > 0
    }
    var startSyncClosure: (() -> Void)?

    func startSync() {
        startSyncCallsCount += 1
        startSyncClosure?()
    }
    //MARK: - stopSync

    var stopSyncCallsCount = 0
    var stopSyncCalled: Bool {
        return stopSyncCallsCount > 0
    }
    var stopSyncClosure: (() -> Void)?

    func stopSync() {
        stopSyncCallsCount += 1
        stopSyncClosure?()
    }
    //MARK: - accountURL

    var accountURLActionCallsCount = 0
    var accountURLActionCalled: Bool {
        return accountURLActionCallsCount > 0
    }
    var accountURLActionReceivedAction: AccountManagementAction?
    var accountURLActionReceivedInvocations: [AccountManagementAction] = []
    var accountURLActionReturnValue: URL?
    var accountURLActionClosure: ((AccountManagementAction) -> URL?)?

    func accountURL(action: AccountManagementAction) -> URL? {
        accountURLActionCallsCount += 1
        accountURLActionReceivedAction = action
        accountURLActionReceivedInvocations.append(action)
        if let accountURLActionClosure = accountURLActionClosure {
            return accountURLActionClosure(action)
        } else {
            return accountURLActionReturnValue
        }
    }
    //MARK: - directRoomForUserID

    var directRoomForUserIDCallsCount = 0
    var directRoomForUserIDCalled: Bool {
        return directRoomForUserIDCallsCount > 0
    }
    var directRoomForUserIDReceivedUserID: String?
    var directRoomForUserIDReceivedInvocations: [String] = []
    var directRoomForUserIDReturnValue: Result<String?, ClientProxyError>!
    var directRoomForUserIDClosure: ((String) async -> Result<String?, ClientProxyError>)?

    func directRoomForUserID(_ userID: String) async -> Result<String?, ClientProxyError> {
        directRoomForUserIDCallsCount += 1
        directRoomForUserIDReceivedUserID = userID
        directRoomForUserIDReceivedInvocations.append(userID)
        if let directRoomForUserIDClosure = directRoomForUserIDClosure {
            return await directRoomForUserIDClosure(userID)
        } else {
            return directRoomForUserIDReturnValue
        }
    }
    //MARK: - createDirectRoom

    var createDirectRoomWithExpectedRoomNameCallsCount = 0
    var createDirectRoomWithExpectedRoomNameCalled: Bool {
        return createDirectRoomWithExpectedRoomNameCallsCount > 0
    }
    var createDirectRoomWithExpectedRoomNameReceivedArguments: (userID: String, expectedRoomName: String?)?
    var createDirectRoomWithExpectedRoomNameReceivedInvocations: [(userID: String, expectedRoomName: String?)] = []
    var createDirectRoomWithExpectedRoomNameReturnValue: Result<String, ClientProxyError>!
    var createDirectRoomWithExpectedRoomNameClosure: ((String, String?) async -> Result<String, ClientProxyError>)?

    func createDirectRoom(with userID: String, expectedRoomName: String?) async -> Result<String, ClientProxyError> {
        createDirectRoomWithExpectedRoomNameCallsCount += 1
        createDirectRoomWithExpectedRoomNameReceivedArguments = (userID: userID, expectedRoomName: expectedRoomName)
        createDirectRoomWithExpectedRoomNameReceivedInvocations.append((userID: userID, expectedRoomName: expectedRoomName))
        if let createDirectRoomWithExpectedRoomNameClosure = createDirectRoomWithExpectedRoomNameClosure {
            return await createDirectRoomWithExpectedRoomNameClosure(userID, expectedRoomName)
        } else {
            return createDirectRoomWithExpectedRoomNameReturnValue
        }
    }
    //MARK: - createRoom

    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLCallsCount = 0
    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLCalled: Bool {
        return createRoomNameTopicIsRoomPrivateUserIDsAvatarURLCallsCount > 0
    }
    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReceivedArguments: (name: String, topic: String?, isRoomPrivate: Bool, userIDs: [String], avatarURL: URL?)?
    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReceivedInvocations: [(name: String, topic: String?, isRoomPrivate: Bool, userIDs: [String], avatarURL: URL?)] = []
    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReturnValue: Result<String, ClientProxyError>!
    var createRoomNameTopicIsRoomPrivateUserIDsAvatarURLClosure: ((String, String?, Bool, [String], URL?) async -> Result<String, ClientProxyError>)?

    func createRoom(name: String, topic: String?, isRoomPrivate: Bool, userIDs: [String], avatarURL: URL?) async -> Result<String, ClientProxyError> {
        createRoomNameTopicIsRoomPrivateUserIDsAvatarURLCallsCount += 1
        createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReceivedArguments = (name: name, topic: topic, isRoomPrivate: isRoomPrivate, userIDs: userIDs, avatarURL: avatarURL)
        createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReceivedInvocations.append((name: name, topic: topic, isRoomPrivate: isRoomPrivate, userIDs: userIDs, avatarURL: avatarURL))
        if let createRoomNameTopicIsRoomPrivateUserIDsAvatarURLClosure = createRoomNameTopicIsRoomPrivateUserIDsAvatarURLClosure {
            return await createRoomNameTopicIsRoomPrivateUserIDsAvatarURLClosure(name, topic, isRoomPrivate, userIDs, avatarURL)
        } else {
            return createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReturnValue
        }
    }
    //MARK: - uploadMedia

    var uploadMediaCallsCount = 0
    var uploadMediaCalled: Bool {
        return uploadMediaCallsCount > 0
    }
    var uploadMediaReceivedMedia: MediaInfo?
    var uploadMediaReceivedInvocations: [MediaInfo] = []
    var uploadMediaReturnValue: Result<String, ClientProxyError>!
    var uploadMediaClosure: ((MediaInfo) async -> Result<String, ClientProxyError>)?

    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError> {
        uploadMediaCallsCount += 1
        uploadMediaReceivedMedia = media
        uploadMediaReceivedInvocations.append(media)
        if let uploadMediaClosure = uploadMediaClosure {
            return await uploadMediaClosure(media)
        } else {
            return uploadMediaReturnValue
        }
    }
    //MARK: - roomForIdentifier

    var roomForIdentifierCallsCount = 0
    var roomForIdentifierCalled: Bool {
        return roomForIdentifierCallsCount > 0
    }
    var roomForIdentifierReceivedIdentifier: String?
    var roomForIdentifierReceivedInvocations: [String] = []
    var roomForIdentifierReturnValue: RoomProxyProtocol?
    var roomForIdentifierClosure: ((String) async -> RoomProxyProtocol?)?

    func roomForIdentifier(_ identifier: String) async -> RoomProxyProtocol? {
        roomForIdentifierCallsCount += 1
        roomForIdentifierReceivedIdentifier = identifier
        roomForIdentifierReceivedInvocations.append(identifier)
        if let roomForIdentifierClosure = roomForIdentifierClosure {
            return await roomForIdentifierClosure(identifier)
        } else {
            return roomForIdentifierReturnValue
        }
    }
    //MARK: - loadUserDisplayName

    var loadUserDisplayNameCallsCount = 0
    var loadUserDisplayNameCalled: Bool {
        return loadUserDisplayNameCallsCount > 0
    }
    var loadUserDisplayNameReturnValue: Result<Void, ClientProxyError>!
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

    var setUserDisplayNameCallsCount = 0
    var setUserDisplayNameCalled: Bool {
        return setUserDisplayNameCallsCount > 0
    }
    var setUserDisplayNameReceivedName: String?
    var setUserDisplayNameReceivedInvocations: [String] = []
    var setUserDisplayNameReturnValue: Result<Void, ClientProxyError>!
    var setUserDisplayNameClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func setUserDisplayName(_ name: String) async -> Result<Void, ClientProxyError> {
        setUserDisplayNameCallsCount += 1
        setUserDisplayNameReceivedName = name
        setUserDisplayNameReceivedInvocations.append(name)
        if let setUserDisplayNameClosure = setUserDisplayNameClosure {
            return await setUserDisplayNameClosure(name)
        } else {
            return setUserDisplayNameReturnValue
        }
    }
    //MARK: - loadUserAvatarURL

    var loadUserAvatarURLCallsCount = 0
    var loadUserAvatarURLCalled: Bool {
        return loadUserAvatarURLCallsCount > 0
    }
    var loadUserAvatarURLReturnValue: Result<Void, ClientProxyError>!
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

    var setUserAvatarMediaCallsCount = 0
    var setUserAvatarMediaCalled: Bool {
        return setUserAvatarMediaCallsCount > 0
    }
    var setUserAvatarMediaReceivedMedia: MediaInfo?
    var setUserAvatarMediaReceivedInvocations: [MediaInfo] = []
    var setUserAvatarMediaReturnValue: Result<Void, ClientProxyError>!
    var setUserAvatarMediaClosure: ((MediaInfo) async -> Result<Void, ClientProxyError>)?

    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError> {
        setUserAvatarMediaCallsCount += 1
        setUserAvatarMediaReceivedMedia = media
        setUserAvatarMediaReceivedInvocations.append(media)
        if let setUserAvatarMediaClosure = setUserAvatarMediaClosure {
            return await setUserAvatarMediaClosure(media)
        } else {
            return setUserAvatarMediaReturnValue
        }
    }
    //MARK: - removeUserAvatar

    var removeUserAvatarCallsCount = 0
    var removeUserAvatarCalled: Bool {
        return removeUserAvatarCallsCount > 0
    }
    var removeUserAvatarReturnValue: Result<Void, ClientProxyError>!
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

    var sessionVerificationControllerProxyCallsCount = 0
    var sessionVerificationControllerProxyCalled: Bool {
        return sessionVerificationControllerProxyCallsCount > 0
    }
    var sessionVerificationControllerProxyReturnValue: Result<SessionVerificationControllerProxyProtocol, ClientProxyError>!
    var sessionVerificationControllerProxyClosure: (() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError>)?

    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        sessionVerificationControllerProxyCallsCount += 1
        if let sessionVerificationControllerProxyClosure = sessionVerificationControllerProxyClosure {
            return await sessionVerificationControllerProxyClosure()
        } else {
            return sessionVerificationControllerProxyReturnValue
        }
    }
    //MARK: - logout

    var logoutCallsCount = 0
    var logoutCalled: Bool {
        return logoutCallsCount > 0
    }
    var logoutReturnValue: URL?
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
    var setPusherWithCallsCount = 0
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
        setPusherWithReceivedInvocations.append(configuration)
        try await setPusherWithClosure?(configuration)
    }
    //MARK: - searchUsers

    var searchUsersSearchTermLimitCallsCount = 0
    var searchUsersSearchTermLimitCalled: Bool {
        return searchUsersSearchTermLimitCallsCount > 0
    }
    var searchUsersSearchTermLimitReceivedArguments: (searchTerm: String, limit: UInt)?
    var searchUsersSearchTermLimitReceivedInvocations: [(searchTerm: String, limit: UInt)] = []
    var searchUsersSearchTermLimitReturnValue: Result<SearchUsersResultsProxy, ClientProxyError>!
    var searchUsersSearchTermLimitClosure: ((String, UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError>)?

    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError> {
        searchUsersSearchTermLimitCallsCount += 1
        searchUsersSearchTermLimitReceivedArguments = (searchTerm: searchTerm, limit: limit)
        searchUsersSearchTermLimitReceivedInvocations.append((searchTerm: searchTerm, limit: limit))
        if let searchUsersSearchTermLimitClosure = searchUsersSearchTermLimitClosure {
            return await searchUsersSearchTermLimitClosure(searchTerm, limit)
        } else {
            return searchUsersSearchTermLimitReturnValue
        }
    }
    //MARK: - profile

    var profileForCallsCount = 0
    var profileForCalled: Bool {
        return profileForCallsCount > 0
    }
    var profileForReceivedUserID: String?
    var profileForReceivedInvocations: [String] = []
    var profileForReturnValue: Result<UserProfileProxy, ClientProxyError>!
    var profileForClosure: ((String) async -> Result<UserProfileProxy, ClientProxyError>)?

    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError> {
        profileForCallsCount += 1
        profileForReceivedUserID = userID
        profileForReceivedInvocations.append(userID)
        if let profileForClosure = profileForClosure {
            return await profileForClosure(userID)
        } else {
            return profileForReturnValue
        }
    }
    //MARK: - ignoreUser

    var ignoreUserCallsCount = 0
    var ignoreUserCalled: Bool {
        return ignoreUserCallsCount > 0
    }
    var ignoreUserReceivedUserID: String?
    var ignoreUserReceivedInvocations: [String] = []
    var ignoreUserReturnValue: Result<Void, ClientProxyError>!
    var ignoreUserClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func ignoreUser(_ userID: String) async -> Result<Void, ClientProxyError> {
        ignoreUserCallsCount += 1
        ignoreUserReceivedUserID = userID
        ignoreUserReceivedInvocations.append(userID)
        if let ignoreUserClosure = ignoreUserClosure {
            return await ignoreUserClosure(userID)
        } else {
            return ignoreUserReturnValue
        }
    }
    //MARK: - unignoreUser

    var unignoreUserCallsCount = 0
    var unignoreUserCalled: Bool {
        return unignoreUserCallsCount > 0
    }
    var unignoreUserReceivedUserID: String?
    var unignoreUserReceivedInvocations: [String] = []
    var unignoreUserReturnValue: Result<Void, ClientProxyError>!
    var unignoreUserClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func unignoreUser(_ userID: String) async -> Result<Void, ClientProxyError> {
        unignoreUserCallsCount += 1
        unignoreUserReceivedUserID = userID
        unignoreUserReceivedInvocations.append(userID)
        if let unignoreUserClosure = unignoreUserClosure {
            return await unignoreUserClosure(userID)
        } else {
            return unignoreUserReturnValue
        }
    }
    //MARK: - loadMediaContentForSource

    var loadMediaContentForSourceThrowableError: Error?
    var loadMediaContentForSourceCallsCount = 0
    var loadMediaContentForSourceCalled: Bool {
        return loadMediaContentForSourceCallsCount > 0
    }
    var loadMediaContentForSourceReceivedSource: MediaSourceProxy?
    var loadMediaContentForSourceReceivedInvocations: [MediaSourceProxy] = []
    var loadMediaContentForSourceReturnValue: Data!
    var loadMediaContentForSourceClosure: ((MediaSourceProxy) async throws -> Data)?

    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        if let error = loadMediaContentForSourceThrowableError {
            throw error
        }
        loadMediaContentForSourceCallsCount += 1
        loadMediaContentForSourceReceivedSource = source
        loadMediaContentForSourceReceivedInvocations.append(source)
        if let loadMediaContentForSourceClosure = loadMediaContentForSourceClosure {
            return try await loadMediaContentForSourceClosure(source)
        } else {
            return loadMediaContentForSourceReturnValue
        }
    }
    //MARK: - loadMediaThumbnailForSource

    var loadMediaThumbnailForSourceWidthHeightThrowableError: Error?
    var loadMediaThumbnailForSourceWidthHeightCallsCount = 0
    var loadMediaThumbnailForSourceWidthHeightCalled: Bool {
        return loadMediaThumbnailForSourceWidthHeightCallsCount > 0
    }
    var loadMediaThumbnailForSourceWidthHeightReceivedArguments: (source: MediaSourceProxy, width: UInt, height: UInt)?
    var loadMediaThumbnailForSourceWidthHeightReceivedInvocations: [(source: MediaSourceProxy, width: UInt, height: UInt)] = []
    var loadMediaThumbnailForSourceWidthHeightReturnValue: Data!
    var loadMediaThumbnailForSourceWidthHeightClosure: ((MediaSourceProxy, UInt, UInt) async throws -> Data)?

    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        if let error = loadMediaThumbnailForSourceWidthHeightThrowableError {
            throw error
        }
        loadMediaThumbnailForSourceWidthHeightCallsCount += 1
        loadMediaThumbnailForSourceWidthHeightReceivedArguments = (source: source, width: width, height: height)
        loadMediaThumbnailForSourceWidthHeightReceivedInvocations.append((source: source, width: width, height: height))
        if let loadMediaThumbnailForSourceWidthHeightClosure = loadMediaThumbnailForSourceWidthHeightClosure {
            return try await loadMediaThumbnailForSourceWidthHeightClosure(source, width, height)
        } else {
            return loadMediaThumbnailForSourceWidthHeightReturnValue
        }
    }
    //MARK: - loadMediaFileForSource

    var loadMediaFileForSourceBodyThrowableError: Error?
    var loadMediaFileForSourceBodyCallsCount = 0
    var loadMediaFileForSourceBodyCalled: Bool {
        return loadMediaFileForSourceBodyCallsCount > 0
    }
    var loadMediaFileForSourceBodyReceivedArguments: (source: MediaSourceProxy, body: String?)?
    var loadMediaFileForSourceBodyReceivedInvocations: [(source: MediaSourceProxy, body: String?)] = []
    var loadMediaFileForSourceBodyReturnValue: MediaFileHandleProxy!
    var loadMediaFileForSourceBodyClosure: ((MediaSourceProxy, String?) async throws -> MediaFileHandleProxy)?

    func loadMediaFileForSource(_ source: MediaSourceProxy, body: String?) async throws -> MediaFileHandleProxy {
        if let error = loadMediaFileForSourceBodyThrowableError {
            throw error
        }
        loadMediaFileForSourceBodyCallsCount += 1
        loadMediaFileForSourceBodyReceivedArguments = (source: source, body: body)
        loadMediaFileForSourceBodyReceivedInvocations.append((source: source, body: body))
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

    var startBaseURLClientIDCallsCount = 0
    var startBaseURLClientIDCalled: Bool {
        return startBaseURLClientIDCallsCount > 0
    }
    var startBaseURLClientIDReceivedArguments: (baseURL: URL, clientID: String)?
    var startBaseURLClientIDReceivedInvocations: [(baseURL: URL, clientID: String)] = []
    var startBaseURLClientIDReturnValue: Result<URL, ElementCallWidgetDriverError>!
    var startBaseURLClientIDClosure: ((URL, String) async -> Result<URL, ElementCallWidgetDriverError>)?

    func start(baseURL: URL, clientID: String) async -> Result<URL, ElementCallWidgetDriverError> {
        startBaseURLClientIDCallsCount += 1
        startBaseURLClientIDReceivedArguments = (baseURL: baseURL, clientID: clientID)
        startBaseURLClientIDReceivedInvocations.append((baseURL: baseURL, clientID: clientID))
        if let startBaseURLClientIDClosure = startBaseURLClientIDClosure {
            return await startBaseURLClientIDClosure(baseURL, clientID)
        } else {
            return startBaseURLClientIDReturnValue
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
    //MARK: - isInviteForMeEnabled

    var isInviteForMeEnabledThrowableError: Error?
    var isInviteForMeEnabledCallsCount = 0
    var isInviteForMeEnabledCalled: Bool {
        return isInviteForMeEnabledCallsCount > 0
    }
    var isInviteForMeEnabledReturnValue: Bool!
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
    var setInviteForMeEnabledEnabledCallsCount = 0
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
        setInviteForMeEnabledEnabledReceivedInvocations.append(enabled)
        try await setInviteForMeEnabledEnabledClosure?(enabled)
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
    //MARK: - canPushEncryptedEventsToDevice

    var canPushEncryptedEventsToDeviceCallsCount = 0
    var canPushEncryptedEventsToDeviceCalled: Bool {
        return canPushEncryptedEventsToDeviceCallsCount > 0
    }
    var canPushEncryptedEventsToDeviceReturnValue: Bool!
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

    var setOrientationCallsCount = 0
    var setOrientationCalled: Bool {
        return setOrientationCallsCount > 0
    }
    var setOrientationReceivedOrientation: UIInterfaceOrientationMask?
    var setOrientationReceivedInvocations: [UIInterfaceOrientationMask] = []
    var setOrientationClosure: ((UIInterfaceOrientationMask) -> Void)?

    func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        setOrientationCallsCount += 1
        setOrientationReceivedOrientation = orientation
        setOrientationReceivedInvocations.append(orientation)
        setOrientationClosure?(orientation)
    }
    //MARK: - lockOrientation

    var lockOrientationCallsCount = 0
    var lockOrientationCalled: Bool {
        return lockOrientationCallsCount > 0
    }
    var lockOrientationReceivedOrientation: UIInterfaceOrientationMask?
    var lockOrientationReceivedInvocations: [UIInterfaceOrientationMask] = []
    var lockOrientationClosure: ((UIInterfaceOrientationMask) -> Void)?

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        lockOrientationCallsCount += 1
        lockOrientationReceivedOrientation = orientation
        lockOrientationReceivedInvocations.append(orientation)
        lockOrientationClosure?(orientation)
    }
}
class PollInteractionHandlerMock: PollInteractionHandlerProtocol {

    //MARK: - sendPollResponse

    var sendPollResponsePollStartIDOptionIDCallsCount = 0
    var sendPollResponsePollStartIDOptionIDCalled: Bool {
        return sendPollResponsePollStartIDOptionIDCallsCount > 0
    }
    var sendPollResponsePollStartIDOptionIDReceivedArguments: (pollStartID: String, optionID: String)?
    var sendPollResponsePollStartIDOptionIDReceivedInvocations: [(pollStartID: String, optionID: String)] = []
    var sendPollResponsePollStartIDOptionIDReturnValue: Result<Void, Error>!
    var sendPollResponsePollStartIDOptionIDClosure: ((String, String) async -> Result<Void, Error>)?

    func sendPollResponse(pollStartID: String, optionID: String) async -> Result<Void, Error> {
        sendPollResponsePollStartIDOptionIDCallsCount += 1
        sendPollResponsePollStartIDOptionIDReceivedArguments = (pollStartID: pollStartID, optionID: optionID)
        sendPollResponsePollStartIDOptionIDReceivedInvocations.append((pollStartID: pollStartID, optionID: optionID))
        if let sendPollResponsePollStartIDOptionIDClosure = sendPollResponsePollStartIDOptionIDClosure {
            return await sendPollResponsePollStartIDOptionIDClosure(pollStartID, optionID)
        } else {
            return sendPollResponsePollStartIDOptionIDReturnValue
        }
    }
    //MARK: - endPoll

    var endPollPollStartIDCallsCount = 0
    var endPollPollStartIDCalled: Bool {
        return endPollPollStartIDCallsCount > 0
    }
    var endPollPollStartIDReceivedPollStartID: String?
    var endPollPollStartIDReceivedInvocations: [String] = []
    var endPollPollStartIDReturnValue: Result<Void, Error>!
    var endPollPollStartIDClosure: ((String) async -> Result<Void, Error>)?

    func endPoll(pollStartID: String) async -> Result<Void, Error> {
        endPollPollStartIDCallsCount += 1
        endPollPollStartIDReceivedPollStartID = pollStartID
        endPollPollStartIDReceivedInvocations.append(pollStartID)
        if let endPollPollStartIDClosure = endPollPollStartIDClosure {
            return await endPollPollStartIDClosure(pollStartID)
        } else {
            return endPollPollStartIDReturnValue
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
    var membership: Membership {
        get { return underlyingMembership }
        set(value) { underlyingMembership = value }
    }
    var underlyingMembership: Membership!
    var hasOngoingCall: Bool {
        get { return underlyingHasOngoingCall }
        set(value) { underlyingHasOngoingCall = value }
    }
    var underlyingHasOngoingCall: Bool!
    var canonicalAlias: String?
    var ownUserID: String {
        get { return underlyingOwnUserID }
        set(value) { underlyingOwnUserID = value }
    }
    var underlyingOwnUserID: String!
    var name: String?
    var topic: String?
    var avatarURL: URL?
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
    var actionsPublisher: AnyPublisher<RoomProxyAction, Never> {
        get { return underlyingActionsPublisher }
        set(value) { underlyingActionsPublisher = value }
    }
    var underlyingActionsPublisher: AnyPublisher<RoomProxyAction, Never>!
    var timeline: TimelineProxyProtocol {
        get { return underlyingTimeline }
        set(value) { underlyingTimeline = value }
    }
    var underlyingTimeline: TimelineProxyProtocol!

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
    //MARK: - unsubscribeFromUpdates

    var unsubscribeFromUpdatesCallsCount = 0
    var unsubscribeFromUpdatesCalled: Bool {
        return unsubscribeFromUpdatesCallsCount > 0
    }
    var unsubscribeFromUpdatesClosure: (() -> Void)?

    func unsubscribeFromUpdates() {
        unsubscribeFromUpdatesCallsCount += 1
        unsubscribeFromUpdatesClosure?()
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
    //MARK: - markAsRead

    var markAsReadReceiptTypeCallsCount = 0
    var markAsReadReceiptTypeCalled: Bool {
        return markAsReadReceiptTypeCallsCount > 0
    }
    var markAsReadReceiptTypeReceivedReceiptType: ReceiptType?
    var markAsReadReceiptTypeReceivedInvocations: [ReceiptType] = []
    var markAsReadReceiptTypeReturnValue: Result<Void, RoomProxyError>!
    var markAsReadReceiptTypeClosure: ((ReceiptType) async -> Result<Void, RoomProxyError>)?

    func markAsRead(receiptType: ReceiptType) async -> Result<Void, RoomProxyError> {
        markAsReadReceiptTypeCallsCount += 1
        markAsReadReceiptTypeReceivedReceiptType = receiptType
        markAsReadReceiptTypeReceivedInvocations.append(receiptType)
        if let markAsReadReceiptTypeClosure = markAsReadReceiptTypeClosure {
            return await markAsReadReceiptTypeClosure(receiptType)
        } else {
            return markAsReadReceiptTypeReturnValue
        }
    }
    //MARK: - sendTypingNotification

    var sendTypingNotificationIsTypingCallsCount = 0
    var sendTypingNotificationIsTypingCalled: Bool {
        return sendTypingNotificationIsTypingCallsCount > 0
    }
    var sendTypingNotificationIsTypingReceivedIsTyping: Bool?
    var sendTypingNotificationIsTypingReceivedInvocations: [Bool] = []
    var sendTypingNotificationIsTypingReturnValue: Result<Void, RoomProxyError>!
    var sendTypingNotificationIsTypingClosure: ((Bool) async -> Result<Void, RoomProxyError>)?

    @discardableResult
    func sendTypingNotification(isTyping: Bool) async -> Result<Void, RoomProxyError> {
        sendTypingNotificationIsTypingCallsCount += 1
        sendTypingNotificationIsTypingReceivedIsTyping = isTyping
        sendTypingNotificationIsTypingReceivedInvocations.append(isTyping)
        if let sendTypingNotificationIsTypingClosure = sendTypingNotificationIsTypingClosure {
            return await sendTypingNotificationIsTypingClosure(isTyping)
        } else {
            return sendTypingNotificationIsTypingReturnValue
        }
    }
    //MARK: - flagAsUnread

    var flagAsUnreadCallsCount = 0
    var flagAsUnreadCalled: Bool {
        return flagAsUnreadCallsCount > 0
    }
    var flagAsUnreadReceivedIsUnread: Bool?
    var flagAsUnreadReceivedInvocations: [Bool] = []
    var flagAsUnreadReturnValue: Result<Void, RoomProxyError>!
    var flagAsUnreadClosure: ((Bool) async -> Result<Void, RoomProxyError>)?

    func flagAsUnread(_ isUnread: Bool) async -> Result<Void, RoomProxyError> {
        flagAsUnreadCallsCount += 1
        flagAsUnreadReceivedIsUnread = isUnread
        flagAsUnreadReceivedInvocations.append(isUnread)
        if let flagAsUnreadClosure = flagAsUnreadClosure {
            return await flagAsUnreadClosure(isUnread)
        } else {
            return flagAsUnreadReturnValue
        }
    }
    //MARK: - flagAsFavourite

    var flagAsFavouriteCallsCount = 0
    var flagAsFavouriteCalled: Bool {
        return flagAsFavouriteCallsCount > 0
    }
    var flagAsFavouriteReceivedIsFavourite: Bool?
    var flagAsFavouriteReceivedInvocations: [Bool] = []
    var flagAsFavouriteReturnValue: Result<Void, RoomProxyError>!
    var flagAsFavouriteClosure: ((Bool) async -> Result<Void, RoomProxyError>)?

    func flagAsFavourite(_ isFavourite: Bool) async -> Result<Void, RoomProxyError> {
        flagAsFavouriteCallsCount += 1
        flagAsFavouriteReceivedIsFavourite = isFavourite
        flagAsFavouriteReceivedInvocations.append(isFavourite)
        if let flagAsFavouriteClosure = flagAsFavouriteClosure {
            return await flagAsFavouriteClosure(isFavourite)
        } else {
            return flagAsFavouriteReturnValue
        }
    }
    //MARK: - powerLevels

    var powerLevelsCallsCount = 0
    var powerLevelsCalled: Bool {
        return powerLevelsCallsCount > 0
    }
    var powerLevelsReturnValue: Result<RoomPowerLevels, RoomProxyError>!
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

    var applyPowerLevelChangesCallsCount = 0
    var applyPowerLevelChangesCalled: Bool {
        return applyPowerLevelChangesCallsCount > 0
    }
    var applyPowerLevelChangesReceivedChanges: RoomPowerLevelChanges?
    var applyPowerLevelChangesReceivedInvocations: [RoomPowerLevelChanges] = []
    var applyPowerLevelChangesReturnValue: Result<Void, RoomProxyError>!
    var applyPowerLevelChangesClosure: ((RoomPowerLevelChanges) async -> Result<Void, RoomProxyError>)?

    func applyPowerLevelChanges(_ changes: RoomPowerLevelChanges) async -> Result<Void, RoomProxyError> {
        applyPowerLevelChangesCallsCount += 1
        applyPowerLevelChangesReceivedChanges = changes
        applyPowerLevelChangesReceivedInvocations.append(changes)
        if let applyPowerLevelChangesClosure = applyPowerLevelChangesClosure {
            return await applyPowerLevelChangesClosure(changes)
        } else {
            return applyPowerLevelChangesReturnValue
        }
    }
    //MARK: - suggestedRole

    var suggestedRoleForCallsCount = 0
    var suggestedRoleForCalled: Bool {
        return suggestedRoleForCallsCount > 0
    }
    var suggestedRoleForReceivedUserID: String?
    var suggestedRoleForReceivedInvocations: [String] = []
    var suggestedRoleForReturnValue: Result<RoomMemberRole, RoomProxyError>!
    var suggestedRoleForClosure: ((String) async -> Result<RoomMemberRole, RoomProxyError>)?

    func suggestedRole(for userID: String) async -> Result<RoomMemberRole, RoomProxyError> {
        suggestedRoleForCallsCount += 1
        suggestedRoleForReceivedUserID = userID
        suggestedRoleForReceivedInvocations.append(userID)
        if let suggestedRoleForClosure = suggestedRoleForClosure {
            return await suggestedRoleForClosure(userID)
        } else {
            return suggestedRoleForReturnValue
        }
    }
    //MARK: - updatePowerLevelsForUsers

    var updatePowerLevelsForUsersCallsCount = 0
    var updatePowerLevelsForUsersCalled: Bool {
        return updatePowerLevelsForUsersCallsCount > 0
    }
    var updatePowerLevelsForUsersReceivedUpdates: [(userID: String, powerLevel: Int64)]?
    var updatePowerLevelsForUsersReceivedInvocations: [[(userID: String, powerLevel: Int64)]] = []
    var updatePowerLevelsForUsersReturnValue: Result<Void, RoomProxyError>!
    var updatePowerLevelsForUsersClosure: (([(userID: String, powerLevel: Int64)]) async -> Result<Void, RoomProxyError>)?

    func updatePowerLevelsForUsers(_ updates: [(userID: String, powerLevel: Int64)]) async -> Result<Void, RoomProxyError> {
        updatePowerLevelsForUsersCallsCount += 1
        updatePowerLevelsForUsersReceivedUpdates = updates
        updatePowerLevelsForUsersReceivedInvocations.append(updates)
        if let updatePowerLevelsForUsersClosure = updatePowerLevelsForUsersClosure {
            return await updatePowerLevelsForUsersClosure(updates)
        } else {
            return updatePowerLevelsForUsersReturnValue
        }
    }
    //MARK: - canUser

    var canUserUserIDSendStateEventCallsCount = 0
    var canUserUserIDSendStateEventCalled: Bool {
        return canUserUserIDSendStateEventCallsCount > 0
    }
    var canUserUserIDSendStateEventReceivedArguments: (userID: String, event: StateEventType)?
    var canUserUserIDSendStateEventReceivedInvocations: [(userID: String, event: StateEventType)] = []
    var canUserUserIDSendStateEventReturnValue: Result<Bool, RoomProxyError>!
    var canUserUserIDSendStateEventClosure: ((String, StateEventType) async -> Result<Bool, RoomProxyError>)?

    func canUser(userID: String, sendStateEvent event: StateEventType) async -> Result<Bool, RoomProxyError> {
        canUserUserIDSendStateEventCallsCount += 1
        canUserUserIDSendStateEventReceivedArguments = (userID: userID, event: event)
        canUserUserIDSendStateEventReceivedInvocations.append((userID: userID, event: event))
        if let canUserUserIDSendStateEventClosure = canUserUserIDSendStateEventClosure {
            return await canUserUserIDSendStateEventClosure(userID, event)
        } else {
            return canUserUserIDSendStateEventReturnValue
        }
    }
    //MARK: - canUserInvite

    var canUserInviteUserIDCallsCount = 0
    var canUserInviteUserIDCalled: Bool {
        return canUserInviteUserIDCallsCount > 0
    }
    var canUserInviteUserIDReceivedUserID: String?
    var canUserInviteUserIDReceivedInvocations: [String] = []
    var canUserInviteUserIDReturnValue: Result<Bool, RoomProxyError>!
    var canUserInviteUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserInvite(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserInviteUserIDCallsCount += 1
        canUserInviteUserIDReceivedUserID = userID
        canUserInviteUserIDReceivedInvocations.append(userID)
        if let canUserInviteUserIDClosure = canUserInviteUserIDClosure {
            return await canUserInviteUserIDClosure(userID)
        } else {
            return canUserInviteUserIDReturnValue
        }
    }
    //MARK: - canUserRedactOther

    var canUserRedactOtherUserIDCallsCount = 0
    var canUserRedactOtherUserIDCalled: Bool {
        return canUserRedactOtherUserIDCallsCount > 0
    }
    var canUserRedactOtherUserIDReceivedUserID: String?
    var canUserRedactOtherUserIDReceivedInvocations: [String] = []
    var canUserRedactOtherUserIDReturnValue: Result<Bool, RoomProxyError>!
    var canUserRedactOtherUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserRedactOther(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserRedactOtherUserIDCallsCount += 1
        canUserRedactOtherUserIDReceivedUserID = userID
        canUserRedactOtherUserIDReceivedInvocations.append(userID)
        if let canUserRedactOtherUserIDClosure = canUserRedactOtherUserIDClosure {
            return await canUserRedactOtherUserIDClosure(userID)
        } else {
            return canUserRedactOtherUserIDReturnValue
        }
    }
    //MARK: - canUserRedactOwn

    var canUserRedactOwnUserIDCallsCount = 0
    var canUserRedactOwnUserIDCalled: Bool {
        return canUserRedactOwnUserIDCallsCount > 0
    }
    var canUserRedactOwnUserIDReceivedUserID: String?
    var canUserRedactOwnUserIDReceivedInvocations: [String] = []
    var canUserRedactOwnUserIDReturnValue: Result<Bool, RoomProxyError>!
    var canUserRedactOwnUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserRedactOwn(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserRedactOwnUserIDCallsCount += 1
        canUserRedactOwnUserIDReceivedUserID = userID
        canUserRedactOwnUserIDReceivedInvocations.append(userID)
        if let canUserRedactOwnUserIDClosure = canUserRedactOwnUserIDClosure {
            return await canUserRedactOwnUserIDClosure(userID)
        } else {
            return canUserRedactOwnUserIDReturnValue
        }
    }
    //MARK: - canUserKick

    var canUserKickUserIDCallsCount = 0
    var canUserKickUserIDCalled: Bool {
        return canUserKickUserIDCallsCount > 0
    }
    var canUserKickUserIDReceivedUserID: String?
    var canUserKickUserIDReceivedInvocations: [String] = []
    var canUserKickUserIDReturnValue: Result<Bool, RoomProxyError>!
    var canUserKickUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserKick(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserKickUserIDCallsCount += 1
        canUserKickUserIDReceivedUserID = userID
        canUserKickUserIDReceivedInvocations.append(userID)
        if let canUserKickUserIDClosure = canUserKickUserIDClosure {
            return await canUserKickUserIDClosure(userID)
        } else {
            return canUserKickUserIDReturnValue
        }
    }
    //MARK: - canUserBan

    var canUserBanUserIDCallsCount = 0
    var canUserBanUserIDCalled: Bool {
        return canUserBanUserIDCallsCount > 0
    }
    var canUserBanUserIDReceivedUserID: String?
    var canUserBanUserIDReceivedInvocations: [String] = []
    var canUserBanUserIDReturnValue: Result<Bool, RoomProxyError>!
    var canUserBanUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserBan(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserBanUserIDCallsCount += 1
        canUserBanUserIDReceivedUserID = userID
        canUserBanUserIDReceivedInvocations.append(userID)
        if let canUserBanUserIDClosure = canUserBanUserIDClosure {
            return await canUserBanUserIDClosure(userID)
        } else {
            return canUserBanUserIDReturnValue
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
    //MARK: - kickUser

    var kickUserCallsCount = 0
    var kickUserCalled: Bool {
        return kickUserCallsCount > 0
    }
    var kickUserReceivedUserID: String?
    var kickUserReceivedInvocations: [String] = []
    var kickUserReturnValue: Result<Void, RoomProxyError>!
    var kickUserClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func kickUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        kickUserCallsCount += 1
        kickUserReceivedUserID = userID
        kickUserReceivedInvocations.append(userID)
        if let kickUserClosure = kickUserClosure {
            return await kickUserClosure(userID)
        } else {
            return kickUserReturnValue
        }
    }
    //MARK: - banUser

    var banUserCallsCount = 0
    var banUserCalled: Bool {
        return banUserCallsCount > 0
    }
    var banUserReceivedUserID: String?
    var banUserReceivedInvocations: [String] = []
    var banUserReturnValue: Result<Void, RoomProxyError>!
    var banUserClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func banUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        banUserCallsCount += 1
        banUserReceivedUserID = userID
        banUserReceivedInvocations.append(userID)
        if let banUserClosure = banUserClosure {
            return await banUserClosure(userID)
        } else {
            return banUserReturnValue
        }
    }
    //MARK: - unbanUser

    var unbanUserCallsCount = 0
    var unbanUserCalled: Bool {
        return unbanUserCallsCount > 0
    }
    var unbanUserReceivedUserID: String?
    var unbanUserReceivedInvocations: [String] = []
    var unbanUserReturnValue: Result<Void, RoomProxyError>!
    var unbanUserClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func unbanUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        unbanUserCallsCount += 1
        unbanUserReceivedUserID = userID
        unbanUserReceivedInvocations.append(userID)
        if let unbanUserClosure = unbanUserClosure {
            return await unbanUserClosure(userID)
        } else {
            return unbanUserReturnValue
        }
    }
    //MARK: - canUserJoinCall

    var canUserJoinCallUserIDCallsCount = 0
    var canUserJoinCallUserIDCalled: Bool {
        return canUserJoinCallUserIDCallsCount > 0
    }
    var canUserJoinCallUserIDReceivedUserID: String?
    var canUserJoinCallUserIDReceivedInvocations: [String] = []
    var canUserJoinCallUserIDReturnValue: Result<Bool, RoomProxyError>!
    var canUserJoinCallUserIDClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func canUserJoinCall(userID: String) async -> Result<Bool, RoomProxyError> {
        canUserJoinCallUserIDCallsCount += 1
        canUserJoinCallUserIDReceivedUserID = userID
        canUserJoinCallUserIDReceivedInvocations.append(userID)
        if let canUserJoinCallUserIDClosure = canUserJoinCallUserIDClosure {
            return await canUserJoinCallUserIDClosure(userID)
        } else {
            return canUserJoinCallUserIDReturnValue
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

    var setRoomListCallsCount = 0
    var setRoomListCalled: Bool {
        return setRoomListCallsCount > 0
    }
    var setRoomListReceivedRoomList: RoomList?
    var setRoomListReceivedInvocations: [RoomList] = []
    var setRoomListClosure: ((RoomList) -> Void)?

    func setRoomList(_ roomList: RoomList) {
        setRoomListCallsCount += 1
        setRoomListReceivedRoomList = roomList
        setRoomListReceivedInvocations.append(roomList)
        setRoomListClosure?(roomList)
    }
    //MARK: - updateVisibleRange

    var updateVisibleRangeCallsCount = 0
    var updateVisibleRangeCalled: Bool {
        return updateVisibleRangeCallsCount > 0
    }
    var updateVisibleRangeReceivedRange: Range<Int>?
    var updateVisibleRangeReceivedInvocations: [Range<Int>] = []
    var updateVisibleRangeClosure: ((Range<Int>) -> Void)?

    func updateVisibleRange(_ range: Range<Int>) {
        updateVisibleRangeCallsCount += 1
        updateVisibleRangeReceivedRange = range
        updateVisibleRangeReceivedInvocations.append(range)
        updateVisibleRangeClosure?(range)
    }
    //MARK: - setFilter

    var setFilterCallsCount = 0
    var setFilterCalled: Bool {
        return setFilterCallsCount > 0
    }
    var setFilterReceivedFilter: RoomSummaryProviderFilter?
    var setFilterReceivedInvocations: [RoomSummaryProviderFilter] = []
    var setFilterClosure: ((RoomSummaryProviderFilter) -> Void)?

    func setFilter(_ filter: RoomSummaryProviderFilter) {
        setFilterCallsCount += 1
        setFilterReceivedFilter = filter
        setFilterReceivedInvocations.append(filter)
        setFilterClosure?(filter)
    }
}
class RoomTimelineProviderMock: RoomTimelineProviderProtocol {
    var updatePublisher: AnyPublisher<Void, Never> {
        get { return underlyingUpdatePublisher }
        set(value) { underlyingUpdatePublisher = value }
    }
    var underlyingUpdatePublisher: AnyPublisher<Void, Never>!
    var itemProxies: [TimelineItemProxy] = []
    var backPaginationState: BackPaginationStatus {
        get { return underlyingBackPaginationState }
        set(value) { underlyingBackPaginationState = value }
    }
    var underlyingBackPaginationState: BackPaginationStatus!
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
class TimelineProxyMock: TimelineProxyProtocol {
    var actions: AnyPublisher<TimelineProxyAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<TimelineProxyAction, Never>!
    var timelineProvider: RoomTimelineProviderProtocol {
        get { return underlyingTimelineProvider }
        set(value) { underlyingTimelineProvider = value }
    }
    var underlyingTimelineProvider: RoomTimelineProviderProtocol!
    var timelineStartReached: Bool {
        get { return underlyingTimelineStartReached }
        set(value) { underlyingTimelineStartReached = value }
    }
    var underlyingTimelineStartReached: Bool!

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
    var editMessageHtmlOriginalIntentionalMentionsReceivedArguments: (message: String, html: String?, eventID: String, intentionalMentions: IntentionalMentions)?
    var editMessageHtmlOriginalIntentionalMentionsReceivedInvocations: [(message: String, html: String?, eventID: String, intentionalMentions: IntentionalMentions)] = []
    var editMessageHtmlOriginalIntentionalMentionsReturnValue: Result<Void, TimelineProxyError>!
    var editMessageHtmlOriginalIntentionalMentionsClosure: ((String, String?, String, IntentionalMentions) async -> Result<Void, TimelineProxyError>)?

    func editMessage(_ message: String, html: String?, original eventID: String, intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError> {
        editMessageHtmlOriginalIntentionalMentionsCallsCount += 1
        editMessageHtmlOriginalIntentionalMentionsReceivedArguments = (message: message, html: html, eventID: eventID, intentionalMentions: intentionalMentions)
        editMessageHtmlOriginalIntentionalMentionsReceivedInvocations.append((message: message, html: html, eventID: eventID, intentionalMentions: intentionalMentions))
        if let editMessageHtmlOriginalIntentionalMentionsClosure = editMessageHtmlOriginalIntentionalMentionsClosure {
            return await editMessageHtmlOriginalIntentionalMentionsClosure(message, html, eventID, intentionalMentions)
        } else {
            return editMessageHtmlOriginalIntentionalMentionsReturnValue
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
    //MARK: - paginateBackwards

    var paginateBackwardsRequestSizeCallsCount = 0
    var paginateBackwardsRequestSizeCalled: Bool {
        return paginateBackwardsRequestSizeCallsCount > 0
    }
    var paginateBackwardsRequestSizeReceivedRequestSize: UInt?
    var paginateBackwardsRequestSizeReceivedInvocations: [UInt] = []
    var paginateBackwardsRequestSizeReturnValue: Result<Void, TimelineProxyError>!
    var paginateBackwardsRequestSizeClosure: ((UInt) async -> Result<Void, TimelineProxyError>)?

    func paginateBackwards(requestSize: UInt) async -> Result<Void, TimelineProxyError> {
        paginateBackwardsRequestSizeCallsCount += 1
        paginateBackwardsRequestSizeReceivedRequestSize = requestSize
        paginateBackwardsRequestSizeReceivedInvocations.append(requestSize)
        if let paginateBackwardsRequestSizeClosure = paginateBackwardsRequestSizeClosure {
            return await paginateBackwardsRequestSizeClosure(requestSize)
        } else {
            return paginateBackwardsRequestSizeReturnValue
        }
    }
    //MARK: - paginateBackwards

    var paginateBackwardsRequestSizeUntilNumberOfItemsCallsCount = 0
    var paginateBackwardsRequestSizeUntilNumberOfItemsCalled: Bool {
        return paginateBackwardsRequestSizeUntilNumberOfItemsCallsCount > 0
    }
    var paginateBackwardsRequestSizeUntilNumberOfItemsReceivedArguments: (requestSize: UInt, untilNumberOfItems: UInt)?
    var paginateBackwardsRequestSizeUntilNumberOfItemsReceivedInvocations: [(requestSize: UInt, untilNumberOfItems: UInt)] = []
    var paginateBackwardsRequestSizeUntilNumberOfItemsReturnValue: Result<Void, TimelineProxyError>!
    var paginateBackwardsRequestSizeUntilNumberOfItemsClosure: ((UInt, UInt) async -> Result<Void, TimelineProxyError>)?

    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, TimelineProxyError> {
        paginateBackwardsRequestSizeUntilNumberOfItemsCallsCount += 1
        paginateBackwardsRequestSizeUntilNumberOfItemsReceivedArguments = (requestSize: requestSize, untilNumberOfItems: untilNumberOfItems)
        paginateBackwardsRequestSizeUntilNumberOfItemsReceivedInvocations.append((requestSize: requestSize, untilNumberOfItems: untilNumberOfItems))
        if let paginateBackwardsRequestSizeUntilNumberOfItemsClosure = paginateBackwardsRequestSizeUntilNumberOfItemsClosure {
            return await paginateBackwardsRequestSizeUntilNumberOfItemsClosure(requestSize, untilNumberOfItems)
        } else {
            return paginateBackwardsRequestSizeUntilNumberOfItemsReturnValue
        }
    }
    //MARK: - sendAudio

    var sendAudioUrlAudioInfoProgressSubjectRequestHandleCallsCount = 0
    var sendAudioUrlAudioInfoProgressSubjectRequestHandleCalled: Bool {
        return sendAudioUrlAudioInfoProgressSubjectRequestHandleCallsCount > 0
    }
    var sendAudioUrlAudioInfoProgressSubjectRequestHandleReturnValue: Result<Void, TimelineProxyError>!
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

    var sendFileUrlFileInfoProgressSubjectRequestHandleCallsCount = 0
    var sendFileUrlFileInfoProgressSubjectRequestHandleCalled: Bool {
        return sendFileUrlFileInfoProgressSubjectRequestHandleCallsCount > 0
    }
    var sendFileUrlFileInfoProgressSubjectRequestHandleReturnValue: Result<Void, TimelineProxyError>!
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

    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleCallsCount = 0
    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleCalled: Bool {
        return sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleCallsCount > 0
    }
    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleReturnValue: Result<Void, TimelineProxyError>!
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

    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount = 0
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCalled: Bool {
        return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount > 0
    }
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArguments: (body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)?
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocations: [(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)] = []
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValue: Result<Void, TimelineProxyError>!
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure: ((String, GeoURI, String?, UInt8?, AssetType?) async -> Result<Void, TimelineProxyError>)?

    func sendLocation(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?) async -> Result<Void, TimelineProxyError> {
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount += 1
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArguments = (body: body, geoURI: geoURI, description: description, zoomLevel: zoomLevel, assetType: assetType)
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocations.append((body: body, geoURI: geoURI, description: description, zoomLevel: zoomLevel, assetType: assetType))
        if let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure = sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure {
            return await sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure(body, geoURI, description, zoomLevel, assetType)
        } else {
            return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValue
        }
    }
    //MARK: - sendVideo

    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleCallsCount = 0
    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleCalled: Bool {
        return sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleCallsCount > 0
    }
    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleReturnValue: Result<Void, TimelineProxyError>!
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

    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCallsCount = 0
    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCalled: Bool {
        return sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCallsCount > 0
    }
    var sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleReturnValue: Result<Void, TimelineProxyError>!
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

    var sendReadReceiptForTypeCallsCount = 0
    var sendReadReceiptForTypeCalled: Bool {
        return sendReadReceiptForTypeCallsCount > 0
    }
    var sendReadReceiptForTypeReceivedArguments: (eventID: String, type: ReceiptType)?
    var sendReadReceiptForTypeReceivedInvocations: [(eventID: String, type: ReceiptType)] = []
    var sendReadReceiptForTypeReturnValue: Result<Void, TimelineProxyError>!
    var sendReadReceiptForTypeClosure: ((String, ReceiptType) async -> Result<Void, TimelineProxyError>)?

    func sendReadReceipt(for eventID: String, type: ReceiptType) async -> Result<Void, TimelineProxyError> {
        sendReadReceiptForTypeCallsCount += 1
        sendReadReceiptForTypeReceivedArguments = (eventID: eventID, type: type)
        sendReadReceiptForTypeReceivedInvocations.append((eventID: eventID, type: type))
        if let sendReadReceiptForTypeClosure = sendReadReceiptForTypeClosure {
            return await sendReadReceiptForTypeClosure(eventID, type)
        } else {
            return sendReadReceiptForTypeReturnValue
        }
    }
    //MARK: - sendMessageEventContent

    var sendMessageEventContentCallsCount = 0
    var sendMessageEventContentCalled: Bool {
        return sendMessageEventContentCallsCount > 0
    }
    var sendMessageEventContentReceivedMessageContent: RoomMessageEventContentWithoutRelation?
    var sendMessageEventContentReceivedInvocations: [RoomMessageEventContentWithoutRelation] = []
    var sendMessageEventContentReturnValue: Result<Void, TimelineProxyError>!
    var sendMessageEventContentClosure: ((RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError>)?

    func sendMessageEventContent(_ messageContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError> {
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
    var sendMessageHtmlInReplyToIntentionalMentionsReturnValue: Result<Void, TimelineProxyError>!
    var sendMessageHtmlInReplyToIntentionalMentionsClosure: ((String, String?, String?, IntentionalMentions) async -> Result<Void, TimelineProxyError>)?

    func sendMessage(_ message: String, html: String?, inReplyTo eventID: String?, intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError> {
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
    var toggleReactionToReturnValue: Result<Void, TimelineProxyError>!
    var toggleReactionToClosure: ((String, String) async -> Result<Void, TimelineProxyError>)?

    func toggleReaction(_ reaction: String, to eventID: String) async -> Result<Void, TimelineProxyError> {
        toggleReactionToCallsCount += 1
        toggleReactionToReceivedArguments = (reaction: reaction, eventID: eventID)
        toggleReactionToReceivedInvocations.append((reaction: reaction, eventID: eventID))
        if let toggleReactionToClosure = toggleReactionToClosure {
            return await toggleReactionToClosure(reaction, eventID)
        } else {
            return toggleReactionToReturnValue
        }
    }
    //MARK: - createPoll

    var createPollQuestionAnswersPollKindCallsCount = 0
    var createPollQuestionAnswersPollKindCalled: Bool {
        return createPollQuestionAnswersPollKindCallsCount > 0
    }
    var createPollQuestionAnswersPollKindReceivedArguments: (question: String, answers: [String], pollKind: Poll.Kind)?
    var createPollQuestionAnswersPollKindReceivedInvocations: [(question: String, answers: [String], pollKind: Poll.Kind)] = []
    var createPollQuestionAnswersPollKindReturnValue: Result<Void, TimelineProxyError>!
    var createPollQuestionAnswersPollKindClosure: ((String, [String], Poll.Kind) async -> Result<Void, TimelineProxyError>)?

    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        createPollQuestionAnswersPollKindCallsCount += 1
        createPollQuestionAnswersPollKindReceivedArguments = (question: question, answers: answers, pollKind: pollKind)
        createPollQuestionAnswersPollKindReceivedInvocations.append((question: question, answers: answers, pollKind: pollKind))
        if let createPollQuestionAnswersPollKindClosure = createPollQuestionAnswersPollKindClosure {
            return await createPollQuestionAnswersPollKindClosure(question, answers, pollKind)
        } else {
            return createPollQuestionAnswersPollKindReturnValue
        }
    }
    //MARK: - editPoll

    var editPollOriginalQuestionAnswersPollKindCallsCount = 0
    var editPollOriginalQuestionAnswersPollKindCalled: Bool {
        return editPollOriginalQuestionAnswersPollKindCallsCount > 0
    }
    var editPollOriginalQuestionAnswersPollKindReceivedArguments: (eventID: String, question: String, answers: [String], pollKind: Poll.Kind)?
    var editPollOriginalQuestionAnswersPollKindReceivedInvocations: [(eventID: String, question: String, answers: [String], pollKind: Poll.Kind)] = []
    var editPollOriginalQuestionAnswersPollKindReturnValue: Result<Void, TimelineProxyError>!
    var editPollOriginalQuestionAnswersPollKindClosure: ((String, String, [String], Poll.Kind) async -> Result<Void, TimelineProxyError>)?

    func editPoll(original eventID: String, question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        editPollOriginalQuestionAnswersPollKindCallsCount += 1
        editPollOriginalQuestionAnswersPollKindReceivedArguments = (eventID: eventID, question: question, answers: answers, pollKind: pollKind)
        editPollOriginalQuestionAnswersPollKindReceivedInvocations.append((eventID: eventID, question: question, answers: answers, pollKind: pollKind))
        if let editPollOriginalQuestionAnswersPollKindClosure = editPollOriginalQuestionAnswersPollKindClosure {
            return await editPollOriginalQuestionAnswersPollKindClosure(eventID, question, answers, pollKind)
        } else {
            return editPollOriginalQuestionAnswersPollKindReturnValue
        }
    }
    //MARK: - endPoll

    var endPollPollStartIDTextCallsCount = 0
    var endPollPollStartIDTextCalled: Bool {
        return endPollPollStartIDTextCallsCount > 0
    }
    var endPollPollStartIDTextReceivedArguments: (pollStartID: String, text: String)?
    var endPollPollStartIDTextReceivedInvocations: [(pollStartID: String, text: String)] = []
    var endPollPollStartIDTextReturnValue: Result<Void, TimelineProxyError>!
    var endPollPollStartIDTextClosure: ((String, String) async -> Result<Void, TimelineProxyError>)?

    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineProxyError> {
        endPollPollStartIDTextCallsCount += 1
        endPollPollStartIDTextReceivedArguments = (pollStartID: pollStartID, text: text)
        endPollPollStartIDTextReceivedInvocations.append((pollStartID: pollStartID, text: text))
        if let endPollPollStartIDTextClosure = endPollPollStartIDTextClosure {
            return await endPollPollStartIDTextClosure(pollStartID, text)
        } else {
            return endPollPollStartIDTextReturnValue
        }
    }
    //MARK: - sendPollResponse

    var sendPollResponsePollStartIDAnswersCallsCount = 0
    var sendPollResponsePollStartIDAnswersCalled: Bool {
        return sendPollResponsePollStartIDAnswersCallsCount > 0
    }
    var sendPollResponsePollStartIDAnswersReceivedArguments: (pollStartID: String, answers: [String])?
    var sendPollResponsePollStartIDAnswersReceivedInvocations: [(pollStartID: String, answers: [String])] = []
    var sendPollResponsePollStartIDAnswersReturnValue: Result<Void, TimelineProxyError>!
    var sendPollResponsePollStartIDAnswersClosure: ((String, [String]) async -> Result<Void, TimelineProxyError>)?

    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineProxyError> {
        sendPollResponsePollStartIDAnswersCallsCount += 1
        sendPollResponsePollStartIDAnswersReceivedArguments = (pollStartID: pollStartID, answers: answers)
        sendPollResponsePollStartIDAnswersReceivedInvocations.append((pollStartID: pollStartID, answers: answers))
        if let sendPollResponsePollStartIDAnswersClosure = sendPollResponsePollStartIDAnswersClosure {
            return await sendPollResponsePollStartIDAnswersClosure(pollStartID, answers)
        } else {
            return sendPollResponsePollStartIDAnswersReturnValue
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
    var urlForRecording: URL {
        get { return underlyingUrlForRecording }
        set(value) { underlyingUrlForRecording = value }
    }
    var underlyingUrlForRecording: URL!

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
