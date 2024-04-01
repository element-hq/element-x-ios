// Generated using Sourcery 2.1.8 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
import Foundation
import MatrixRustSDK
class SDKClientMock: SDKClientProtocol {

    //MARK: - accountData

    public var accountDataEventTypeThrowableError: Error?
    public var accountDataEventTypeCallsCount = 0
    public var accountDataEventTypeCalled: Bool {
        return accountDataEventTypeCallsCount > 0
    }
    public var accountDataEventTypeReceivedEventType: String?
    public var accountDataEventTypeReceivedInvocations: [String] = []
    public var accountDataEventTypeReturnValue: String?
    public var accountDataEventTypeClosure: ((String) throws -> String?)?

    public func accountData(eventType: String) throws -> String? {
        if let error = accountDataEventTypeThrowableError {
            throw error
        }
        accountDataEventTypeCallsCount += 1
        accountDataEventTypeReceivedEventType = eventType
        accountDataEventTypeReceivedInvocations.append(eventType)
        if let accountDataEventTypeClosure = accountDataEventTypeClosure {
            return try accountDataEventTypeClosure(eventType)
        } else {
            return accountDataEventTypeReturnValue
        }
    }
    //MARK: - accountUrl

    public var accountUrlActionThrowableError: Error?
    public var accountUrlActionCallsCount = 0
    public var accountUrlActionCalled: Bool {
        return accountUrlActionCallsCount > 0
    }
    public var accountUrlActionReceivedAction: AccountManagementAction?
    public var accountUrlActionReceivedInvocations: [AccountManagementAction?] = []
    public var accountUrlActionReturnValue: String?
    public var accountUrlActionClosure: ((AccountManagementAction?) throws -> String?)?

    public func accountUrl(action: AccountManagementAction?) throws -> String? {
        if let error = accountUrlActionThrowableError {
            throw error
        }
        accountUrlActionCallsCount += 1
        accountUrlActionReceivedAction = action
        accountUrlActionReceivedInvocations.append(action)
        if let accountUrlActionClosure = accountUrlActionClosure {
            return try accountUrlActionClosure(action)
        } else {
            return accountUrlActionReturnValue
        }
    }
    //MARK: - avatarUrl

    public var avatarUrlThrowableError: Error?
    public var avatarUrlCallsCount = 0
    public var avatarUrlCalled: Bool {
        return avatarUrlCallsCount > 0
    }
    public var avatarUrlReturnValue: String?
    public var avatarUrlClosure: (() throws -> String?)?

    public func avatarUrl() throws -> String? {
        if let error = avatarUrlThrowableError {
            throw error
        }
        avatarUrlCallsCount += 1
        if let avatarUrlClosure = avatarUrlClosure {
            return try avatarUrlClosure()
        } else {
            return avatarUrlReturnValue
        }
    }
    //MARK: - cachedAvatarUrl

    public var cachedAvatarUrlThrowableError: Error?
    public var cachedAvatarUrlCallsCount = 0
    public var cachedAvatarUrlCalled: Bool {
        return cachedAvatarUrlCallsCount > 0
    }
    public var cachedAvatarUrlReturnValue: String?
    public var cachedAvatarUrlClosure: (() throws -> String?)?

    public func cachedAvatarUrl() throws -> String? {
        if let error = cachedAvatarUrlThrowableError {
            throw error
        }
        cachedAvatarUrlCallsCount += 1
        if let cachedAvatarUrlClosure = cachedAvatarUrlClosure {
            return try cachedAvatarUrlClosure()
        } else {
            return cachedAvatarUrlReturnValue
        }
    }
    //MARK: - createRoom

    public var createRoomRequestThrowableError: Error?
    public var createRoomRequestCallsCount = 0
    public var createRoomRequestCalled: Bool {
        return createRoomRequestCallsCount > 0
    }
    public var createRoomRequestReceivedRequest: CreateRoomParameters?
    public var createRoomRequestReceivedInvocations: [CreateRoomParameters] = []
    public var createRoomRequestReturnValue: String!
    public var createRoomRequestClosure: ((CreateRoomParameters) throws -> String)?

    public func createRoom(request: CreateRoomParameters) throws -> String {
        if let error = createRoomRequestThrowableError {
            throw error
        }
        createRoomRequestCallsCount += 1
        createRoomRequestReceivedRequest = request
        createRoomRequestReceivedInvocations.append(request)
        if let createRoomRequestClosure = createRoomRequestClosure {
            return try createRoomRequestClosure(request)
        } else {
            return createRoomRequestReturnValue
        }
    }
    //MARK: - deletePusher

    public var deletePusherIdentifiersThrowableError: Error?
    public var deletePusherIdentifiersCallsCount = 0
    public var deletePusherIdentifiersCalled: Bool {
        return deletePusherIdentifiersCallsCount > 0
    }
    public var deletePusherIdentifiersReceivedIdentifiers: PusherIdentifiers?
    public var deletePusherIdentifiersReceivedInvocations: [PusherIdentifiers] = []
    public var deletePusherIdentifiersClosure: ((PusherIdentifiers) async throws -> Void)?

    public func deletePusher(identifiers: PusherIdentifiers) async throws {
        if let error = deletePusherIdentifiersThrowableError {
            throw error
        }
        deletePusherIdentifiersCallsCount += 1
        deletePusherIdentifiersReceivedIdentifiers = identifiers
        deletePusherIdentifiersReceivedInvocations.append(identifiers)
        try await deletePusherIdentifiersClosure?(identifiers)
    }
    //MARK: - deviceId

    public var deviceIdThrowableError: Error?
    public var deviceIdCallsCount = 0
    public var deviceIdCalled: Bool {
        return deviceIdCallsCount > 0
    }
    public var deviceIdReturnValue: String!
    public var deviceIdClosure: (() throws -> String)?

    public func deviceId() throws -> String {
        if let error = deviceIdThrowableError {
            throw error
        }
        deviceIdCallsCount += 1
        if let deviceIdClosure = deviceIdClosure {
            return try deviceIdClosure()
        } else {
            return deviceIdReturnValue
        }
    }
    //MARK: - displayName

    public var displayNameThrowableError: Error?
    public var displayNameCallsCount = 0
    public var displayNameCalled: Bool {
        return displayNameCallsCount > 0
    }
    public var displayNameReturnValue: String!
    public var displayNameClosure: (() throws -> String)?

    public func displayName() throws -> String {
        if let error = displayNameThrowableError {
            throw error
        }
        displayNameCallsCount += 1
        if let displayNameClosure = displayNameClosure {
            return try displayNameClosure()
        } else {
            return displayNameReturnValue
        }
    }
    //MARK: - encryption

    public var encryptionCallsCount = 0
    public var encryptionCalled: Bool {
        return encryptionCallsCount > 0
    }
    public var encryptionReturnValue: Encryption!
    public var encryptionClosure: (() -> Encryption)?

    public func encryption() -> Encryption {
        encryptionCallsCount += 1
        if let encryptionClosure = encryptionClosure {
            return encryptionClosure()
        } else {
            return encryptionReturnValue
        }
    }
    //MARK: - getDmRoom

    public var getDmRoomUserIdThrowableError: Error?
    public var getDmRoomUserIdCallsCount = 0
    public var getDmRoomUserIdCalled: Bool {
        return getDmRoomUserIdCallsCount > 0
    }
    public var getDmRoomUserIdReceivedUserId: String?
    public var getDmRoomUserIdReceivedInvocations: [String] = []
    public var getDmRoomUserIdReturnValue: Room?
    public var getDmRoomUserIdClosure: ((String) throws -> Room?)?

    public func getDmRoom(userId: String) throws -> Room? {
        if let error = getDmRoomUserIdThrowableError {
            throw error
        }
        getDmRoomUserIdCallsCount += 1
        getDmRoomUserIdReceivedUserId = userId
        getDmRoomUserIdReceivedInvocations.append(userId)
        if let getDmRoomUserIdClosure = getDmRoomUserIdClosure {
            return try getDmRoomUserIdClosure(userId)
        } else {
            return getDmRoomUserIdReturnValue
        }
    }
    //MARK: - getMediaContent

    public var getMediaContentMediaSourceThrowableError: Error?
    public var getMediaContentMediaSourceCallsCount = 0
    public var getMediaContentMediaSourceCalled: Bool {
        return getMediaContentMediaSourceCallsCount > 0
    }
    public var getMediaContentMediaSourceReceivedMediaSource: MediaSource?
    public var getMediaContentMediaSourceReceivedInvocations: [MediaSource] = []
    public var getMediaContentMediaSourceReturnValue: Data!
    public var getMediaContentMediaSourceClosure: ((MediaSource) async throws -> Data)?

    public func getMediaContent(mediaSource: MediaSource) async throws -> Data {
        if let error = getMediaContentMediaSourceThrowableError {
            throw error
        }
        getMediaContentMediaSourceCallsCount += 1
        getMediaContentMediaSourceReceivedMediaSource = mediaSource
        getMediaContentMediaSourceReceivedInvocations.append(mediaSource)
        if let getMediaContentMediaSourceClosure = getMediaContentMediaSourceClosure {
            return try await getMediaContentMediaSourceClosure(mediaSource)
        } else {
            return getMediaContentMediaSourceReturnValue
        }
    }
    //MARK: - getMediaFile

    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirThrowableError: Error?
    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirCallsCount = 0
    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirCalled: Bool {
        return getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirCallsCount > 0
    }
    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReceivedArguments: (mediaSource: MediaSource, body: String?, mimeType: String, useCache: Bool, tempDir: String?)?
    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReceivedInvocations: [(mediaSource: MediaSource, body: String?, mimeType: String, useCache: Bool, tempDir: String?)] = []
    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReturnValue: MediaFileHandle!
    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirClosure: ((MediaSource, String?, String, Bool, String?) async throws -> MediaFileHandle)?

    public func getMediaFile(mediaSource: MediaSource, body: String?, mimeType: String, useCache: Bool, tempDir: String?) async throws -> MediaFileHandle {
        if let error = getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirThrowableError {
            throw error
        }
        getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirCallsCount += 1
        getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReceivedArguments = (mediaSource: mediaSource, body: body, mimeType: mimeType, useCache: useCache, tempDir: tempDir)
        getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReceivedInvocations.append((mediaSource: mediaSource, body: body, mimeType: mimeType, useCache: useCache, tempDir: tempDir))
        if let getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirClosure = getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirClosure {
            return try await getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirClosure(mediaSource, body, mimeType, useCache, tempDir)
        } else {
            return getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReturnValue
        }
    }
    //MARK: - getMediaThumbnail

    public var getMediaThumbnailMediaSourceWidthHeightThrowableError: Error?
    public var getMediaThumbnailMediaSourceWidthHeightCallsCount = 0
    public var getMediaThumbnailMediaSourceWidthHeightCalled: Bool {
        return getMediaThumbnailMediaSourceWidthHeightCallsCount > 0
    }
    public var getMediaThumbnailMediaSourceWidthHeightReceivedArguments: (mediaSource: MediaSource, width: UInt64, height: UInt64)?
    public var getMediaThumbnailMediaSourceWidthHeightReceivedInvocations: [(mediaSource: MediaSource, width: UInt64, height: UInt64)] = []
    public var getMediaThumbnailMediaSourceWidthHeightReturnValue: Data!
    public var getMediaThumbnailMediaSourceWidthHeightClosure: ((MediaSource, UInt64, UInt64) async throws -> Data)?

    public func getMediaThumbnail(mediaSource: MediaSource, width: UInt64, height: UInt64) async throws -> Data {
        if let error = getMediaThumbnailMediaSourceWidthHeightThrowableError {
            throw error
        }
        getMediaThumbnailMediaSourceWidthHeightCallsCount += 1
        getMediaThumbnailMediaSourceWidthHeightReceivedArguments = (mediaSource: mediaSource, width: width, height: height)
        getMediaThumbnailMediaSourceWidthHeightReceivedInvocations.append((mediaSource: mediaSource, width: width, height: height))
        if let getMediaThumbnailMediaSourceWidthHeightClosure = getMediaThumbnailMediaSourceWidthHeightClosure {
            return try await getMediaThumbnailMediaSourceWidthHeightClosure(mediaSource, width, height)
        } else {
            return getMediaThumbnailMediaSourceWidthHeightReturnValue
        }
    }
    //MARK: - getNotificationSettings

    public var getNotificationSettingsCallsCount = 0
    public var getNotificationSettingsCalled: Bool {
        return getNotificationSettingsCallsCount > 0
    }
    public var getNotificationSettingsReturnValue: NotificationSettings!
    public var getNotificationSettingsClosure: (() -> NotificationSettings)?

    public func getNotificationSettings() -> NotificationSettings {
        getNotificationSettingsCallsCount += 1
        if let getNotificationSettingsClosure = getNotificationSettingsClosure {
            return getNotificationSettingsClosure()
        } else {
            return getNotificationSettingsReturnValue
        }
    }
    //MARK: - getProfile

    public var getProfileUserIdThrowableError: Error?
    public var getProfileUserIdCallsCount = 0
    public var getProfileUserIdCalled: Bool {
        return getProfileUserIdCallsCount > 0
    }
    public var getProfileUserIdReceivedUserId: String?
    public var getProfileUserIdReceivedInvocations: [String] = []
    public var getProfileUserIdReturnValue: UserProfile!
    public var getProfileUserIdClosure: ((String) throws -> UserProfile)?

    public func getProfile(userId: String) throws -> UserProfile {
        if let error = getProfileUserIdThrowableError {
            throw error
        }
        getProfileUserIdCallsCount += 1
        getProfileUserIdReceivedUserId = userId
        getProfileUserIdReceivedInvocations.append(userId)
        if let getProfileUserIdClosure = getProfileUserIdClosure {
            return try getProfileUserIdClosure(userId)
        } else {
            return getProfileUserIdReturnValue
        }
    }
    //MARK: - getRecentlyVisitedRooms

    public var getRecentlyVisitedRoomsThrowableError: Error?
    public var getRecentlyVisitedRoomsCallsCount = 0
    public var getRecentlyVisitedRoomsCalled: Bool {
        return getRecentlyVisitedRoomsCallsCount > 0
    }
    public var getRecentlyVisitedRoomsReturnValue: [String]!
    public var getRecentlyVisitedRoomsClosure: (() async throws -> [String])?

    public func getRecentlyVisitedRooms() async throws -> [String] {
        if let error = getRecentlyVisitedRoomsThrowableError {
            throw error
        }
        getRecentlyVisitedRoomsCallsCount += 1
        if let getRecentlyVisitedRoomsClosure = getRecentlyVisitedRoomsClosure {
            return try await getRecentlyVisitedRoomsClosure()
        } else {
            return getRecentlyVisitedRoomsReturnValue
        }
    }
    //MARK: - getSessionVerificationController

    public var getSessionVerificationControllerThrowableError: Error?
    public var getSessionVerificationControllerCallsCount = 0
    public var getSessionVerificationControllerCalled: Bool {
        return getSessionVerificationControllerCallsCount > 0
    }
    public var getSessionVerificationControllerReturnValue: SessionVerificationController!
    public var getSessionVerificationControllerClosure: (() throws -> SessionVerificationController)?

    public func getSessionVerificationController() throws -> SessionVerificationController {
        if let error = getSessionVerificationControllerThrowableError {
            throw error
        }
        getSessionVerificationControllerCallsCount += 1
        if let getSessionVerificationControllerClosure = getSessionVerificationControllerClosure {
            return try getSessionVerificationControllerClosure()
        } else {
            return getSessionVerificationControllerReturnValue
        }
    }
    //MARK: - homeserver

    public var homeserverCallsCount = 0
    public var homeserverCalled: Bool {
        return homeserverCallsCount > 0
    }
    public var homeserverReturnValue: String!
    public var homeserverClosure: (() -> String)?

    public func homeserver() -> String {
        homeserverCallsCount += 1
        if let homeserverClosure = homeserverClosure {
            return homeserverClosure()
        } else {
            return homeserverReturnValue
        }
    }
    //MARK: - ignoreUser

    public var ignoreUserUserIdThrowableError: Error?
    public var ignoreUserUserIdCallsCount = 0
    public var ignoreUserUserIdCalled: Bool {
        return ignoreUserUserIdCallsCount > 0
    }
    public var ignoreUserUserIdReceivedUserId: String?
    public var ignoreUserUserIdReceivedInvocations: [String] = []
    public var ignoreUserUserIdClosure: ((String) async throws -> Void)?

    public func ignoreUser(userId: String) async throws {
        if let error = ignoreUserUserIdThrowableError {
            throw error
        }
        ignoreUserUserIdCallsCount += 1
        ignoreUserUserIdReceivedUserId = userId
        ignoreUserUserIdReceivedInvocations.append(userId)
        try await ignoreUserUserIdClosure?(userId)
    }
    //MARK: - ignoredUsers

    public var ignoredUsersThrowableError: Error?
    public var ignoredUsersCallsCount = 0
    public var ignoredUsersCalled: Bool {
        return ignoredUsersCallsCount > 0
    }
    public var ignoredUsersReturnValue: [String]!
    public var ignoredUsersClosure: (() async throws -> [String])?

    public func ignoredUsers() async throws -> [String] {
        if let error = ignoredUsersThrowableError {
            throw error
        }
        ignoredUsersCallsCount += 1
        if let ignoredUsersClosure = ignoredUsersClosure {
            return try await ignoredUsersClosure()
        } else {
            return ignoredUsersReturnValue
        }
    }
    //MARK: - joinRoomById

    public var joinRoomByIdRoomIdThrowableError: Error?
    public var joinRoomByIdRoomIdCallsCount = 0
    public var joinRoomByIdRoomIdCalled: Bool {
        return joinRoomByIdRoomIdCallsCount > 0
    }
    public var joinRoomByIdRoomIdReceivedRoomId: String?
    public var joinRoomByIdRoomIdReceivedInvocations: [String] = []
    public var joinRoomByIdRoomIdReturnValue: Room!
    public var joinRoomByIdRoomIdClosure: ((String) async throws -> Room)?

    public func joinRoomById(roomId: String) async throws -> Room {
        if let error = joinRoomByIdRoomIdThrowableError {
            throw error
        }
        joinRoomByIdRoomIdCallsCount += 1
        joinRoomByIdRoomIdReceivedRoomId = roomId
        joinRoomByIdRoomIdReceivedInvocations.append(roomId)
        if let joinRoomByIdRoomIdClosure = joinRoomByIdRoomIdClosure {
            return try await joinRoomByIdRoomIdClosure(roomId)
        } else {
            return joinRoomByIdRoomIdReturnValue
        }
    }
    //MARK: - login

    public var loginUsernamePasswordInitialDeviceNameDeviceIdThrowableError: Error?
    public var loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount = 0
    public var loginUsernamePasswordInitialDeviceNameDeviceIdCalled: Bool {
        return loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount > 0
    }
    public var loginUsernamePasswordInitialDeviceNameDeviceIdReceivedArguments: (username: String, password: String, initialDeviceName: String?, deviceId: String?)?
    public var loginUsernamePasswordInitialDeviceNameDeviceIdReceivedInvocations: [(username: String, password: String, initialDeviceName: String?, deviceId: String?)] = []
    public var loginUsernamePasswordInitialDeviceNameDeviceIdClosure: ((String, String, String?, String?) throws -> Void)?

    public func login(username: String, password: String, initialDeviceName: String?, deviceId: String?) throws {
        if let error = loginUsernamePasswordInitialDeviceNameDeviceIdThrowableError {
            throw error
        }
        loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount += 1
        loginUsernamePasswordInitialDeviceNameDeviceIdReceivedArguments = (username: username, password: password, initialDeviceName: initialDeviceName, deviceId: deviceId)
        loginUsernamePasswordInitialDeviceNameDeviceIdReceivedInvocations.append((username: username, password: password, initialDeviceName: initialDeviceName, deviceId: deviceId))
        try loginUsernamePasswordInitialDeviceNameDeviceIdClosure?(username, password, initialDeviceName, deviceId)
    }
    //MARK: - logout

    public var logoutThrowableError: Error?
    public var logoutCallsCount = 0
    public var logoutCalled: Bool {
        return logoutCallsCount > 0
    }
    public var logoutReturnValue: String?
    public var logoutClosure: (() throws -> String?)?

    public func logout() throws -> String? {
        if let error = logoutThrowableError {
            throw error
        }
        logoutCallsCount += 1
        if let logoutClosure = logoutClosure {
            return try logoutClosure()
        } else {
            return logoutReturnValue
        }
    }
    //MARK: - notificationClient

    public var notificationClientProcessSetupThrowableError: Error?
    public var notificationClientProcessSetupCallsCount = 0
    public var notificationClientProcessSetupCalled: Bool {
        return notificationClientProcessSetupCallsCount > 0
    }
    public var notificationClientProcessSetupReceivedProcessSetup: NotificationProcessSetup?
    public var notificationClientProcessSetupReceivedInvocations: [NotificationProcessSetup] = []
    public var notificationClientProcessSetupReturnValue: NotificationClientBuilder!
    public var notificationClientProcessSetupClosure: ((NotificationProcessSetup) throws -> NotificationClientBuilder)?

    public func notificationClient(processSetup: NotificationProcessSetup) throws -> NotificationClientBuilder {
        if let error = notificationClientProcessSetupThrowableError {
            throw error
        }
        notificationClientProcessSetupCallsCount += 1
        notificationClientProcessSetupReceivedProcessSetup = processSetup
        notificationClientProcessSetupReceivedInvocations.append(processSetup)
        if let notificationClientProcessSetupClosure = notificationClientProcessSetupClosure {
            return try notificationClientProcessSetupClosure(processSetup)
        } else {
            return notificationClientProcessSetupReturnValue
        }
    }
    //MARK: - removeAvatar

    public var removeAvatarThrowableError: Error?
    public var removeAvatarCallsCount = 0
    public var removeAvatarCalled: Bool {
        return removeAvatarCallsCount > 0
    }
    public var removeAvatarClosure: (() throws -> Void)?

    public func removeAvatar() throws {
        if let error = removeAvatarThrowableError {
            throw error
        }
        removeAvatarCallsCount += 1
        try removeAvatarClosure?()
    }
    //MARK: - restoreSession

    public var restoreSessionSessionThrowableError: Error?
    public var restoreSessionSessionCallsCount = 0
    public var restoreSessionSessionCalled: Bool {
        return restoreSessionSessionCallsCount > 0
    }
    public var restoreSessionSessionReceivedSession: Session?
    public var restoreSessionSessionReceivedInvocations: [Session] = []
    public var restoreSessionSessionClosure: ((Session) throws -> Void)?

    public func restoreSession(session: Session) throws {
        if let error = restoreSessionSessionThrowableError {
            throw error
        }
        restoreSessionSessionCallsCount += 1
        restoreSessionSessionReceivedSession = session
        restoreSessionSessionReceivedInvocations.append(session)
        try restoreSessionSessionClosure?(session)
    }
    //MARK: - roomDirectorySearch

    public var roomDirectorySearchCallsCount = 0
    public var roomDirectorySearchCalled: Bool {
        return roomDirectorySearchCallsCount > 0
    }
    public var roomDirectorySearchReturnValue: RoomDirectorySearch!
    public var roomDirectorySearchClosure: (() -> RoomDirectorySearch)?

    public func roomDirectorySearch() -> RoomDirectorySearch {
        roomDirectorySearchCallsCount += 1
        if let roomDirectorySearchClosure = roomDirectorySearchClosure {
            return roomDirectorySearchClosure()
        } else {
            return roomDirectorySearchReturnValue
        }
    }
    //MARK: - rooms

    public var roomsCallsCount = 0
    public var roomsCalled: Bool {
        return roomsCallsCount > 0
    }
    public var roomsReturnValue: [Room]!
    public var roomsClosure: (() -> [Room])?

    public func rooms() -> [Room] {
        roomsCallsCount += 1
        if let roomsClosure = roomsClosure {
            return roomsClosure()
        } else {
            return roomsReturnValue
        }
    }
    //MARK: - searchUsers

    public var searchUsersSearchTermLimitThrowableError: Error?
    public var searchUsersSearchTermLimitCallsCount = 0
    public var searchUsersSearchTermLimitCalled: Bool {
        return searchUsersSearchTermLimitCallsCount > 0
    }
    public var searchUsersSearchTermLimitReceivedArguments: (searchTerm: String, limit: UInt64)?
    public var searchUsersSearchTermLimitReceivedInvocations: [(searchTerm: String, limit: UInt64)] = []
    public var searchUsersSearchTermLimitReturnValue: SearchUsersResults!
    public var searchUsersSearchTermLimitClosure: ((String, UInt64) throws -> SearchUsersResults)?

    public func searchUsers(searchTerm: String, limit: UInt64) throws -> SearchUsersResults {
        if let error = searchUsersSearchTermLimitThrowableError {
            throw error
        }
        searchUsersSearchTermLimitCallsCount += 1
        searchUsersSearchTermLimitReceivedArguments = (searchTerm: searchTerm, limit: limit)
        searchUsersSearchTermLimitReceivedInvocations.append((searchTerm: searchTerm, limit: limit))
        if let searchUsersSearchTermLimitClosure = searchUsersSearchTermLimitClosure {
            return try searchUsersSearchTermLimitClosure(searchTerm, limit)
        } else {
            return searchUsersSearchTermLimitReturnValue
        }
    }
    //MARK: - session

    public var sessionThrowableError: Error?
    public var sessionCallsCount = 0
    public var sessionCalled: Bool {
        return sessionCallsCount > 0
    }
    public var sessionReturnValue: Session!
    public var sessionClosure: (() throws -> Session)?

    public func session() throws -> Session {
        if let error = sessionThrowableError {
            throw error
        }
        sessionCallsCount += 1
        if let sessionClosure = sessionClosure {
            return try sessionClosure()
        } else {
            return sessionReturnValue
        }
    }
    //MARK: - setAccountData

    public var setAccountDataEventTypeContentThrowableError: Error?
    public var setAccountDataEventTypeContentCallsCount = 0
    public var setAccountDataEventTypeContentCalled: Bool {
        return setAccountDataEventTypeContentCallsCount > 0
    }
    public var setAccountDataEventTypeContentReceivedArguments: (eventType: String, content: String)?
    public var setAccountDataEventTypeContentReceivedInvocations: [(eventType: String, content: String)] = []
    public var setAccountDataEventTypeContentClosure: ((String, String) throws -> Void)?

    public func setAccountData(eventType: String, content: String) throws {
        if let error = setAccountDataEventTypeContentThrowableError {
            throw error
        }
        setAccountDataEventTypeContentCallsCount += 1
        setAccountDataEventTypeContentReceivedArguments = (eventType: eventType, content: content)
        setAccountDataEventTypeContentReceivedInvocations.append((eventType: eventType, content: content))
        try setAccountDataEventTypeContentClosure?(eventType, content)
    }
    //MARK: - setDelegate

    public var setDelegateDelegateCallsCount = 0
    public var setDelegateDelegateCalled: Bool {
        return setDelegateDelegateCallsCount > 0
    }
    public var setDelegateDelegateReceivedDelegate: ClientDelegate?
    public var setDelegateDelegateReceivedInvocations: [ClientDelegate?] = []
    public var setDelegateDelegateReturnValue: TaskHandle?
    public var setDelegateDelegateClosure: ((ClientDelegate?) -> TaskHandle?)?

    public func setDelegate(delegate: ClientDelegate?) -> TaskHandle? {
        setDelegateDelegateCallsCount += 1
        setDelegateDelegateReceivedDelegate = delegate
        setDelegateDelegateReceivedInvocations.append(delegate)
        if let setDelegateDelegateClosure = setDelegateDelegateClosure {
            return setDelegateDelegateClosure(delegate)
        } else {
            return setDelegateDelegateReturnValue
        }
    }
    //MARK: - setDisplayName

    public var setDisplayNameNameThrowableError: Error?
    public var setDisplayNameNameCallsCount = 0
    public var setDisplayNameNameCalled: Bool {
        return setDisplayNameNameCallsCount > 0
    }
    public var setDisplayNameNameReceivedName: String?
    public var setDisplayNameNameReceivedInvocations: [String] = []
    public var setDisplayNameNameClosure: ((String) throws -> Void)?

    public func setDisplayName(name: String) throws {
        if let error = setDisplayNameNameThrowableError {
            throw error
        }
        setDisplayNameNameCallsCount += 1
        setDisplayNameNameReceivedName = name
        setDisplayNameNameReceivedInvocations.append(name)
        try setDisplayNameNameClosure?(name)
    }
    //MARK: - setPusher

    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangThrowableError: Error?
    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCallsCount = 0
    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCalled: Bool {
        return setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCallsCount > 0
    }
    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedArguments: (identifiers: PusherIdentifiers, kind: PusherKind, appDisplayName: String, deviceDisplayName: String, profileTag: String?, lang: String)?
    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedInvocations: [(identifiers: PusherIdentifiers, kind: PusherKind, appDisplayName: String, deviceDisplayName: String, profileTag: String?, lang: String)] = []
    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangClosure: ((PusherIdentifiers, PusherKind, String, String, String?, String) async throws -> Void)?

    public func setPusher(identifiers: PusherIdentifiers, kind: PusherKind, appDisplayName: String, deviceDisplayName: String, profileTag: String?, lang: String) async throws {
        if let error = setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangThrowableError {
            throw error
        }
        setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCallsCount += 1
        setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedArguments = (identifiers: identifiers, kind: kind, appDisplayName: appDisplayName, deviceDisplayName: deviceDisplayName, profileTag: profileTag, lang: lang)
        setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedInvocations.append((identifiers: identifiers, kind: kind, appDisplayName: appDisplayName, deviceDisplayName: deviceDisplayName, profileTag: profileTag, lang: lang))
        try await setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangClosure?(identifiers, kind, appDisplayName, deviceDisplayName, profileTag, lang)
    }
    //MARK: - subscribeToIgnoredUsers

    public var subscribeToIgnoredUsersListenerCallsCount = 0
    public var subscribeToIgnoredUsersListenerCalled: Bool {
        return subscribeToIgnoredUsersListenerCallsCount > 0
    }
    public var subscribeToIgnoredUsersListenerReceivedListener: IgnoredUsersListener?
    public var subscribeToIgnoredUsersListenerReceivedInvocations: [IgnoredUsersListener] = []
    public var subscribeToIgnoredUsersListenerReturnValue: TaskHandle!
    public var subscribeToIgnoredUsersListenerClosure: ((IgnoredUsersListener) -> TaskHandle)?

    public func subscribeToIgnoredUsers(listener: IgnoredUsersListener) -> TaskHandle {
        subscribeToIgnoredUsersListenerCallsCount += 1
        subscribeToIgnoredUsersListenerReceivedListener = listener
        subscribeToIgnoredUsersListenerReceivedInvocations.append(listener)
        if let subscribeToIgnoredUsersListenerClosure = subscribeToIgnoredUsersListenerClosure {
            return subscribeToIgnoredUsersListenerClosure(listener)
        } else {
            return subscribeToIgnoredUsersListenerReturnValue
        }
    }
    //MARK: - syncService

    public var syncServiceCallsCount = 0
    public var syncServiceCalled: Bool {
        return syncServiceCallsCount > 0
    }
    public var syncServiceReturnValue: SyncServiceBuilder!
    public var syncServiceClosure: (() -> SyncServiceBuilder)?

    public func syncService() -> SyncServiceBuilder {
        syncServiceCallsCount += 1
        if let syncServiceClosure = syncServiceClosure {
            return syncServiceClosure()
        } else {
            return syncServiceReturnValue
        }
    }
    //MARK: - trackRecentlyVisitedRoom

    public var trackRecentlyVisitedRoomRoomThrowableError: Error?
    public var trackRecentlyVisitedRoomRoomCallsCount = 0
    public var trackRecentlyVisitedRoomRoomCalled: Bool {
        return trackRecentlyVisitedRoomRoomCallsCount > 0
    }
    public var trackRecentlyVisitedRoomRoomReceivedRoom: String?
    public var trackRecentlyVisitedRoomRoomReceivedInvocations: [String] = []
    public var trackRecentlyVisitedRoomRoomClosure: ((String) async throws -> Void)?

    public func trackRecentlyVisitedRoom(room: String) async throws {
        if let error = trackRecentlyVisitedRoomRoomThrowableError {
            throw error
        }
        trackRecentlyVisitedRoomRoomCallsCount += 1
        trackRecentlyVisitedRoomRoomReceivedRoom = room
        trackRecentlyVisitedRoomRoomReceivedInvocations.append(room)
        try await trackRecentlyVisitedRoomRoomClosure?(room)
    }
    //MARK: - unignoreUser

    public var unignoreUserUserIdThrowableError: Error?
    public var unignoreUserUserIdCallsCount = 0
    public var unignoreUserUserIdCalled: Bool {
        return unignoreUserUserIdCallsCount > 0
    }
    public var unignoreUserUserIdReceivedUserId: String?
    public var unignoreUserUserIdReceivedInvocations: [String] = []
    public var unignoreUserUserIdClosure: ((String) async throws -> Void)?

    public func unignoreUser(userId: String) async throws {
        if let error = unignoreUserUserIdThrowableError {
            throw error
        }
        unignoreUserUserIdCallsCount += 1
        unignoreUserUserIdReceivedUserId = userId
        unignoreUserUserIdReceivedInvocations.append(userId)
        try await unignoreUserUserIdClosure?(userId)
    }
    //MARK: - uploadAvatar

    public var uploadAvatarMimeTypeDataThrowableError: Error?
    public var uploadAvatarMimeTypeDataCallsCount = 0
    public var uploadAvatarMimeTypeDataCalled: Bool {
        return uploadAvatarMimeTypeDataCallsCount > 0
    }
    public var uploadAvatarMimeTypeDataReceivedArguments: (mimeType: String, data: Data)?
    public var uploadAvatarMimeTypeDataReceivedInvocations: [(mimeType: String, data: Data)] = []
    public var uploadAvatarMimeTypeDataClosure: ((String, Data) throws -> Void)?

    public func uploadAvatar(mimeType: String, data: Data) throws {
        if let error = uploadAvatarMimeTypeDataThrowableError {
            throw error
        }
        uploadAvatarMimeTypeDataCallsCount += 1
        uploadAvatarMimeTypeDataReceivedArguments = (mimeType: mimeType, data: data)
        uploadAvatarMimeTypeDataReceivedInvocations.append((mimeType: mimeType, data: data))
        try uploadAvatarMimeTypeDataClosure?(mimeType, data)
    }
    //MARK: - uploadMedia

    public var uploadMediaMimeTypeDataProgressWatcherThrowableError: Error?
    public var uploadMediaMimeTypeDataProgressWatcherCallsCount = 0
    public var uploadMediaMimeTypeDataProgressWatcherCalled: Bool {
        return uploadMediaMimeTypeDataProgressWatcherCallsCount > 0
    }
    public var uploadMediaMimeTypeDataProgressWatcherReceivedArguments: (mimeType: String, data: Data, progressWatcher: ProgressWatcher?)?
    public var uploadMediaMimeTypeDataProgressWatcherReceivedInvocations: [(mimeType: String, data: Data, progressWatcher: ProgressWatcher?)] = []
    public var uploadMediaMimeTypeDataProgressWatcherReturnValue: String!
    public var uploadMediaMimeTypeDataProgressWatcherClosure: ((String, Data, ProgressWatcher?) async throws -> String)?

    public func uploadMedia(mimeType: String, data: Data, progressWatcher: ProgressWatcher?) async throws -> String {
        if let error = uploadMediaMimeTypeDataProgressWatcherThrowableError {
            throw error
        }
        uploadMediaMimeTypeDataProgressWatcherCallsCount += 1
        uploadMediaMimeTypeDataProgressWatcherReceivedArguments = (mimeType: mimeType, data: data, progressWatcher: progressWatcher)
        uploadMediaMimeTypeDataProgressWatcherReceivedInvocations.append((mimeType: mimeType, data: data, progressWatcher: progressWatcher))
        if let uploadMediaMimeTypeDataProgressWatcherClosure = uploadMediaMimeTypeDataProgressWatcherClosure {
            return try await uploadMediaMimeTypeDataProgressWatcherClosure(mimeType, data, progressWatcher)
        } else {
            return uploadMediaMimeTypeDataProgressWatcherReturnValue
        }
    }
    //MARK: - userId

    public var userIdThrowableError: Error?
    public var userIdCallsCount = 0
    public var userIdCalled: Bool {
        return userIdCallsCount > 0
    }
    public var userIdReturnValue: String!
    public var userIdClosure: (() throws -> String)?

    public func userId() throws -> String {
        if let error = userIdThrowableError {
            throw error
        }
        userIdCallsCount += 1
        if let userIdClosure = userIdClosure {
            return try userIdClosure()
        } else {
            return userIdReturnValue
        }
    }
}
// swiftlint:enable all
