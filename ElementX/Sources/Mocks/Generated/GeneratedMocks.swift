// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
import Combine
import Foundation
import SwiftUI
import AnalyticsEvents
import MatrixRustSDK
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

    var getNotificationSettingsRoomIdIsEncryptedActiveMembersCountThrowableError: Error?
    var getNotificationSettingsRoomIdIsEncryptedActiveMembersCountCallsCount = 0
    var getNotificationSettingsRoomIdIsEncryptedActiveMembersCountCalled: Bool {
        return getNotificationSettingsRoomIdIsEncryptedActiveMembersCountCallsCount > 0
    }
    var getNotificationSettingsRoomIdIsEncryptedActiveMembersCountReceivedArguments: (roomId: String, isEncrypted: Bool, activeMembersCount: UInt64)?
    var getNotificationSettingsRoomIdIsEncryptedActiveMembersCountReceivedInvocations: [(roomId: String, isEncrypted: Bool, activeMembersCount: UInt64)] = []
    var getNotificationSettingsRoomIdIsEncryptedActiveMembersCountReturnValue: RoomNotificationSettingsProxyProtocol!
    var getNotificationSettingsRoomIdIsEncryptedActiveMembersCountClosure: ((String, Bool, UInt64) async throws -> RoomNotificationSettingsProxyProtocol)?

    func getNotificationSettings(roomId: String, isEncrypted: Bool, activeMembersCount: UInt64) async throws -> RoomNotificationSettingsProxyProtocol {
        if let error = getNotificationSettingsRoomIdIsEncryptedActiveMembersCountThrowableError {
            throw error
        }
        getNotificationSettingsRoomIdIsEncryptedActiveMembersCountCallsCount += 1
        getNotificationSettingsRoomIdIsEncryptedActiveMembersCountReceivedArguments = (roomId: roomId, isEncrypted: isEncrypted, activeMembersCount: activeMembersCount)
        getNotificationSettingsRoomIdIsEncryptedActiveMembersCountReceivedInvocations.append((roomId: roomId, isEncrypted: isEncrypted, activeMembersCount: activeMembersCount))
        if let getNotificationSettingsRoomIdIsEncryptedActiveMembersCountClosure = getNotificationSettingsRoomIdIsEncryptedActiveMembersCountClosure {
            return try await getNotificationSettingsRoomIdIsEncryptedActiveMembersCountClosure(roomId, isEncrypted, activeMembersCount)
        } else {
            return getNotificationSettingsRoomIdIsEncryptedActiveMembersCountReturnValue
        }
    }
    //MARK: - setNotificationMode

    var setNotificationModeRoomIdModeThrowableError: Error?
    var setNotificationModeRoomIdModeCallsCount = 0
    var setNotificationModeRoomIdModeCalled: Bool {
        return setNotificationModeRoomIdModeCallsCount > 0
    }
    var setNotificationModeRoomIdModeReceivedArguments: (roomId: String, mode: RoomNotificationMode)?
    var setNotificationModeRoomIdModeReceivedInvocations: [(roomId: String, mode: RoomNotificationMode)] = []
    var setNotificationModeRoomIdModeClosure: ((String, RoomNotificationMode) async throws -> Void)?

    func setNotificationMode(roomId: String, mode: RoomNotificationMode) async throws {
        if let error = setNotificationModeRoomIdModeThrowableError {
            throw error
        }
        setNotificationModeRoomIdModeCallsCount += 1
        setNotificationModeRoomIdModeReceivedArguments = (roomId: roomId, mode: mode)
        setNotificationModeRoomIdModeReceivedInvocations.append((roomId: roomId, mode: mode))
        try await setNotificationModeRoomIdModeClosure?(roomId, mode)
    }
    //MARK: - getDefaultNotificationRoomMode

    var getDefaultNotificationRoomModeIsEncryptedActiveMembersCountCallsCount = 0
    var getDefaultNotificationRoomModeIsEncryptedActiveMembersCountCalled: Bool {
        return getDefaultNotificationRoomModeIsEncryptedActiveMembersCountCallsCount > 0
    }
    var getDefaultNotificationRoomModeIsEncryptedActiveMembersCountReceivedArguments: (isEncrypted: Bool, activeMembersCount: UInt64)?
    var getDefaultNotificationRoomModeIsEncryptedActiveMembersCountReceivedInvocations: [(isEncrypted: Bool, activeMembersCount: UInt64)] = []
    var getDefaultNotificationRoomModeIsEncryptedActiveMembersCountReturnValue: RoomNotificationMode!
    var getDefaultNotificationRoomModeIsEncryptedActiveMembersCountClosure: ((Bool, UInt64) async -> RoomNotificationMode)?

    func getDefaultNotificationRoomMode(isEncrypted: Bool, activeMembersCount: UInt64) async -> RoomNotificationMode {
        getDefaultNotificationRoomModeIsEncryptedActiveMembersCountCallsCount += 1
        getDefaultNotificationRoomModeIsEncryptedActiveMembersCountReceivedArguments = (isEncrypted: isEncrypted, activeMembersCount: activeMembersCount)
        getDefaultNotificationRoomModeIsEncryptedActiveMembersCountReceivedInvocations.append((isEncrypted: isEncrypted, activeMembersCount: activeMembersCount))
        if let getDefaultNotificationRoomModeIsEncryptedActiveMembersCountClosure = getDefaultNotificationRoomModeIsEncryptedActiveMembersCountClosure {
            return await getDefaultNotificationRoomModeIsEncryptedActiveMembersCountClosure(isEncrypted, activeMembersCount)
        } else {
            return getDefaultNotificationRoomModeIsEncryptedActiveMembersCountReturnValue
        }
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

    var unmuteRoomRoomIdIsEncryptedActiveMembersCountThrowableError: Error?
    var unmuteRoomRoomIdIsEncryptedActiveMembersCountCallsCount = 0
    var unmuteRoomRoomIdIsEncryptedActiveMembersCountCalled: Bool {
        return unmuteRoomRoomIdIsEncryptedActiveMembersCountCallsCount > 0
    }
    var unmuteRoomRoomIdIsEncryptedActiveMembersCountReceivedArguments: (roomId: String, isEncrypted: Bool, activeMembersCount: UInt64)?
    var unmuteRoomRoomIdIsEncryptedActiveMembersCountReceivedInvocations: [(roomId: String, isEncrypted: Bool, activeMembersCount: UInt64)] = []
    var unmuteRoomRoomIdIsEncryptedActiveMembersCountClosure: ((String, Bool, UInt64) async throws -> Void)?

    func unmuteRoom(roomId: String, isEncrypted: Bool, activeMembersCount: UInt64) async throws {
        if let error = unmuteRoomRoomIdIsEncryptedActiveMembersCountThrowableError {
            throw error
        }
        unmuteRoomRoomIdIsEncryptedActiveMembersCountCallsCount += 1
        unmuteRoomRoomIdIsEncryptedActiveMembersCountReceivedArguments = (roomId: roomId, isEncrypted: isEncrypted, activeMembersCount: activeMembersCount)
        unmuteRoomRoomIdIsEncryptedActiveMembersCountReceivedInvocations.append((roomId: roomId, isEncrypted: isEncrypted, activeMembersCount: activeMembersCount))
        try await unmuteRoomRoomIdIsEncryptedActiveMembersCountClosure?(roomId, isEncrypted, activeMembersCount)
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
    var mode: RoomNotificationMode {
        get { return underlyingMode }
        set(value) { underlyingMode = value }
    }
    var underlyingMode: RoomNotificationMode!
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
    var canonicalAlias: String?
    var alternativeAliases: [String] = []
    var hasUnreadNotifications: Bool {
        get { return underlyingHasUnreadNotifications }
        set(value) { underlyingHasUnreadNotifications = value }
    }
    var underlyingHasUnreadNotifications: Bool!
    var currentUserID: String {
        get { return underlyingCurrentUserID }
        set(value) { underlyingCurrentUserID = value }
    }
    var underlyingCurrentUserID: String!
    var name: String?
    var displayName: String?
    var topic: String?
    var avatarURL: URL?
    var membersPublisher: AnyPublisher<[RoomMemberProxyProtocol], Never> {
        get { return underlyingMembersPublisher }
        set(value) { underlyingMembersPublisher = value }
    }
    var underlyingMembersPublisher: AnyPublisher<[RoomMemberProxyProtocol], Never>!
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
    var updatesPublisher: AnyPublisher<TimelineDiff, Never> {
        get { return underlyingUpdatesPublisher }
        set(value) { underlyingUpdatesPublisher = value }
    }
    var underlyingUpdatesPublisher: AnyPublisher<TimelineDiff, Never>!
    var timelineProvider: RoomTimelineProviderProtocol {
        get { return underlyingTimelineProvider }
        set(value) { underlyingTimelineProvider = value }
    }
    var underlyingTimelineProvider: RoomTimelineProviderProtocol!

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
    var messageEventContentForReturnValue: RoomMessageEventContent?
    var messageEventContentForClosure: ((String) -> RoomMessageEventContent?)?

    func messageEventContent(for eventID: String) -> RoomMessageEventContent? {
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
    var sendMessageEventContentReceivedMessageContent: RoomMessageEventContent?
    var sendMessageEventContentReceivedInvocations: [RoomMessageEventContent] = []
    var sendMessageEventContentReturnValue: Result<Void, RoomProxyError>!
    var sendMessageEventContentClosure: ((RoomMessageEventContent) async -> Result<Void, RoomProxyError>)?

    func sendMessageEventContent(_ messageContent: RoomMessageEventContent) async -> Result<Void, RoomProxyError> {
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

    var sendMessageInReplyToCallsCount = 0
    var sendMessageInReplyToCalled: Bool {
        return sendMessageInReplyToCallsCount > 0
    }
    var sendMessageInReplyToReceivedArguments: (message: String, eventID: String?)?
    var sendMessageInReplyToReceivedInvocations: [(message: String, eventID: String?)] = []
    var sendMessageInReplyToReturnValue: Result<Void, RoomProxyError>!
    var sendMessageInReplyToClosure: ((String, String?) async -> Result<Void, RoomProxyError>)?

    func sendMessage(_ message: String, inReplyTo eventID: String?) async -> Result<Void, RoomProxyError> {
        sendMessageInReplyToCallsCount += 1
        sendMessageInReplyToReceivedArguments = (message: message, eventID: eventID)
        sendMessageInReplyToReceivedInvocations.append((message: message, eventID: eventID))
        if let sendMessageInReplyToClosure = sendMessageInReplyToClosure {
            return await sendMessageInReplyToClosure(message, eventID)
        } else {
            return sendMessageInReplyToReturnValue
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
    var sendImageUrlThumbnailURLImageInfoProgressSubjectRequestHandleClosure: ((URL, URL, ImageInfo, CurrentValueSubject<Double, Never>?, (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>)?

    func sendImage(url: URL, thumbnailURL: URL, imageInfo: ImageInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
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
    var sendVideoUrlThumbnailURLVideoInfoProgressSubjectRequestHandleClosure: ((URL, URL, VideoInfo, CurrentValueSubject<Double, Never>?, (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>)?

    func sendVideo(url: URL, thumbnailURL: URL, videoInfo: VideoInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
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
    var sendAudioUrlAudioInfoProgressSubjectRequestHandleClosure: ((URL, AudioInfo, CurrentValueSubject<Double, Never>?, (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>)?

    func sendAudio(url: URL, audioInfo: AudioInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
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
    var sendFileUrlFileInfoProgressSubjectRequestHandleClosure: ((URL, FileInfo, CurrentValueSubject<Double, Never>?, (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>)?

    func sendFile(url: URL, fileInfo: FileInfo, progressSubject: CurrentValueSubject<Double, Never>?, requestHandle: (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
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

    var editMessageOriginalCallsCount = 0
    var editMessageOriginalCalled: Bool {
        return editMessageOriginalCallsCount > 0
    }
    var editMessageOriginalReceivedArguments: (newMessage: String, eventID: String)?
    var editMessageOriginalReceivedInvocations: [(newMessage: String, eventID: String)] = []
    var editMessageOriginalReturnValue: Result<Void, RoomProxyError>!
    var editMessageOriginalClosure: ((String, String) async -> Result<Void, RoomProxyError>)?

    func editMessage(_ newMessage: String, original eventID: String) async -> Result<Void, RoomProxyError> {
        editMessageOriginalCallsCount += 1
        editMessageOriginalReceivedArguments = (newMessage: newMessage, eventID: eventID)
        editMessageOriginalReceivedInvocations.append((newMessage: newMessage, eventID: eventID))
        if let editMessageOriginalClosure = editMessageOriginalClosure {
            return await editMessageOriginalClosure(newMessage, eventID)
        } else {
            return editMessageOriginalReturnValue
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
    var setNameReceivedInvocations: [String?] = []
    var setNameReturnValue: Result<Void, RoomProxyError>!
    var setNameClosure: ((String?) async -> Result<Void, RoomProxyError>)?

    func setName(_ name: String?) async -> Result<Void, RoomProxyError> {
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
class SessionVerificationControllerProxyMock: SessionVerificationControllerProxyProtocol {
    var callbacks: PassthroughSubject<SessionVerificationControllerProxyCallback, Never> {
        get { return underlyingCallbacks }
        set(value) { underlyingCallbacks = value }
    }
    var underlyingCallbacks: PassthroughSubject<SessionVerificationControllerProxyCallback, Never>!
    var isVerified: Bool {
        get { return underlyingIsVerified }
        set(value) { underlyingIsVerified = value }
    }
    var underlyingIsVerified: Bool!

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
// swiftlint:enable all
