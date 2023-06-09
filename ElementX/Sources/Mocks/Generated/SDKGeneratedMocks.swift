// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
import Foundation
import MatrixRustSDK
class SDKClientMock: SDKClientProtocol {

    //MARK: - `accountData`

    public var accountDataEventTypeThrowableError: Error?
    public var accountDataEventTypeCallsCount = 0
    public var accountDataEventTypeCalled: Bool {
        return accountDataEventTypeCallsCount > 0
    }
    public var accountDataEventTypeReceivedEventType: String?
    public var accountDataEventTypeReceivedInvocations: [String] = []
    public var accountDataEventTypeReturnValue: String?
    public var accountDataEventTypeClosure: ((String) throws -> String?)?

    public func `accountData`(`eventType`: String) throws -> String? {
        if let error = accountDataEventTypeThrowableError {
            throw error
        }
        accountDataEventTypeCallsCount += 1
        accountDataEventTypeReceivedEventType = eventType
        accountDataEventTypeReceivedInvocations.append(`eventType`)
        if let accountDataEventTypeClosure = accountDataEventTypeClosure {
            return try accountDataEventTypeClosure(`eventType`)
        } else {
            return accountDataEventTypeReturnValue
        }
    }
    //MARK: - `avatarUrl`

    public var avatarUrlThrowableError: Error?
    public var avatarUrlCallsCount = 0
    public var avatarUrlCalled: Bool {
        return avatarUrlCallsCount > 0
    }
    public var avatarUrlReturnValue: String?
    public var avatarUrlClosure: (() throws -> String?)?

    public func `avatarUrl`() throws -> String? {
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
    //MARK: - `cachedAvatarUrl`

    public var cachedAvatarUrlThrowableError: Error?
    public var cachedAvatarUrlCallsCount = 0
    public var cachedAvatarUrlCalled: Bool {
        return cachedAvatarUrlCallsCount > 0
    }
    public var cachedAvatarUrlReturnValue: String?
    public var cachedAvatarUrlClosure: (() throws -> String?)?

    public func `cachedAvatarUrl`() throws -> String? {
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
    //MARK: - `createRoom`

    public var createRoomRequestThrowableError: Error?
    public var createRoomRequestCallsCount = 0
    public var createRoomRequestCalled: Bool {
        return createRoomRequestCallsCount > 0
    }
    public var createRoomRequestReceivedRequest: CreateRoomParameters?
    public var createRoomRequestReceivedInvocations: [CreateRoomParameters] = []
    public var createRoomRequestReturnValue: String!
    public var createRoomRequestClosure: ((CreateRoomParameters) throws -> String)?

    public func `createRoom`(`request`: CreateRoomParameters) throws -> String {
        if let error = createRoomRequestThrowableError {
            throw error
        }
        createRoomRequestCallsCount += 1
        createRoomRequestReceivedRequest = request
        createRoomRequestReceivedInvocations.append(`request`)
        if let createRoomRequestClosure = createRoomRequestClosure {
            return try createRoomRequestClosure(`request`)
        } else {
            return createRoomRequestReturnValue
        }
    }
    //MARK: - `deviceId`

    public var deviceIdThrowableError: Error?
    public var deviceIdCallsCount = 0
    public var deviceIdCalled: Bool {
        return deviceIdCallsCount > 0
    }
    public var deviceIdReturnValue: String!
    public var deviceIdClosure: (() throws -> String)?

    public func `deviceId`() throws -> String {
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
    //MARK: - `displayName`

    public var displayNameThrowableError: Error?
    public var displayNameCallsCount = 0
    public var displayNameCalled: Bool {
        return displayNameCallsCount > 0
    }
    public var displayNameReturnValue: String!
    public var displayNameClosure: (() throws -> String)?

    public func `displayName`() throws -> String {
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
    //MARK: - `getDmRoom`

    public var getDmRoomUserIdThrowableError: Error?
    public var getDmRoomUserIdCallsCount = 0
    public var getDmRoomUserIdCalled: Bool {
        return getDmRoomUserIdCallsCount > 0
    }
    public var getDmRoomUserIdReceivedUserId: String?
    public var getDmRoomUserIdReceivedInvocations: [String] = []
    public var getDmRoomUserIdReturnValue: Room?
    public var getDmRoomUserIdClosure: ((String) throws -> Room?)?

    public func `getDmRoom`(`userId`: String) throws -> Room? {
        if let error = getDmRoomUserIdThrowableError {
            throw error
        }
        getDmRoomUserIdCallsCount += 1
        getDmRoomUserIdReceivedUserId = userId
        getDmRoomUserIdReceivedInvocations.append(`userId`)
        if let getDmRoomUserIdClosure = getDmRoomUserIdClosure {
            return try getDmRoomUserIdClosure(`userId`)
        } else {
            return getDmRoomUserIdReturnValue
        }
    }
    //MARK: - `getMediaContent`

    public var getMediaContentMediaSourceThrowableError: Error?
    public var getMediaContentMediaSourceCallsCount = 0
    public var getMediaContentMediaSourceCalled: Bool {
        return getMediaContentMediaSourceCallsCount > 0
    }
    public var getMediaContentMediaSourceReceivedMediaSource: MediaSource?
    public var getMediaContentMediaSourceReceivedInvocations: [MediaSource] = []
    public var getMediaContentMediaSourceReturnValue: [UInt8]!
    public var getMediaContentMediaSourceClosure: ((MediaSource) throws -> [UInt8])?

    public func `getMediaContent`(`mediaSource`: MediaSource) throws -> [UInt8] {
        if let error = getMediaContentMediaSourceThrowableError {
            throw error
        }
        getMediaContentMediaSourceCallsCount += 1
        getMediaContentMediaSourceReceivedMediaSource = mediaSource
        getMediaContentMediaSourceReceivedInvocations.append(`mediaSource`)
        if let getMediaContentMediaSourceClosure = getMediaContentMediaSourceClosure {
            return try getMediaContentMediaSourceClosure(`mediaSource`)
        } else {
            return getMediaContentMediaSourceReturnValue
        }
    }
    //MARK: - `getMediaFile`

    public var getMediaFileMediaSourceBodyMimeTypeTempDirThrowableError: Error?
    public var getMediaFileMediaSourceBodyMimeTypeTempDirCallsCount = 0
    public var getMediaFileMediaSourceBodyMimeTypeTempDirCalled: Bool {
        return getMediaFileMediaSourceBodyMimeTypeTempDirCallsCount > 0
    }
    public var getMediaFileMediaSourceBodyMimeTypeTempDirReceivedArguments: (`mediaSource`: MediaSource, `body`: String?, `mimeType`: String, `tempDir`: String?)?
    public var getMediaFileMediaSourceBodyMimeTypeTempDirReceivedInvocations: [(`mediaSource`: MediaSource, `body`: String?, `mimeType`: String, `tempDir`: String?)] = []
    public var getMediaFileMediaSourceBodyMimeTypeTempDirReturnValue: MediaFileHandle!
    public var getMediaFileMediaSourceBodyMimeTypeTempDirClosure: ((MediaSource, String?, String, String?) throws -> MediaFileHandle)?

    public func `getMediaFile`(`mediaSource`: MediaSource, `body`: String?, `mimeType`: String, `tempDir`: String?) throws -> MediaFileHandle {
        if let error = getMediaFileMediaSourceBodyMimeTypeTempDirThrowableError {
            throw error
        }
        getMediaFileMediaSourceBodyMimeTypeTempDirCallsCount += 1
        getMediaFileMediaSourceBodyMimeTypeTempDirReceivedArguments = (mediaSource: mediaSource, body: body, mimeType: mimeType, tempDir: tempDir)
        getMediaFileMediaSourceBodyMimeTypeTempDirReceivedInvocations.append((mediaSource: mediaSource, body: body, mimeType: mimeType, tempDir: tempDir))
        if let getMediaFileMediaSourceBodyMimeTypeTempDirClosure = getMediaFileMediaSourceBodyMimeTypeTempDirClosure {
            return try getMediaFileMediaSourceBodyMimeTypeTempDirClosure(`mediaSource`, `body`, `mimeType`, `tempDir`)
        } else {
            return getMediaFileMediaSourceBodyMimeTypeTempDirReturnValue
        }
    }
    //MARK: - `getMediaThumbnail`

    public var getMediaThumbnailMediaSourceWidthHeightThrowableError: Error?
    public var getMediaThumbnailMediaSourceWidthHeightCallsCount = 0
    public var getMediaThumbnailMediaSourceWidthHeightCalled: Bool {
        return getMediaThumbnailMediaSourceWidthHeightCallsCount > 0
    }
    public var getMediaThumbnailMediaSourceWidthHeightReceivedArguments: (`mediaSource`: MediaSource, `width`: UInt64, `height`: UInt64)?
    public var getMediaThumbnailMediaSourceWidthHeightReceivedInvocations: [(`mediaSource`: MediaSource, `width`: UInt64, `height`: UInt64)] = []
    public var getMediaThumbnailMediaSourceWidthHeightReturnValue: [UInt8]!
    public var getMediaThumbnailMediaSourceWidthHeightClosure: ((MediaSource, UInt64, UInt64) throws -> [UInt8])?

    public func `getMediaThumbnail`(`mediaSource`: MediaSource, `width`: UInt64, `height`: UInt64) throws -> [UInt8] {
        if let error = getMediaThumbnailMediaSourceWidthHeightThrowableError {
            throw error
        }
        getMediaThumbnailMediaSourceWidthHeightCallsCount += 1
        getMediaThumbnailMediaSourceWidthHeightReceivedArguments = (mediaSource: mediaSource, width: width, height: height)
        getMediaThumbnailMediaSourceWidthHeightReceivedInvocations.append((mediaSource: mediaSource, width: width, height: height))
        if let getMediaThumbnailMediaSourceWidthHeightClosure = getMediaThumbnailMediaSourceWidthHeightClosure {
            return try getMediaThumbnailMediaSourceWidthHeightClosure(`mediaSource`, `width`, `height`)
        } else {
            return getMediaThumbnailMediaSourceWidthHeightReturnValue
        }
    }
    //MARK: - `getNotificationItem`

    public var getNotificationItemRoomIdEventIdThrowableError: Error?
    public var getNotificationItemRoomIdEventIdCallsCount = 0
    public var getNotificationItemRoomIdEventIdCalled: Bool {
        return getNotificationItemRoomIdEventIdCallsCount > 0
    }
    public var getNotificationItemRoomIdEventIdReceivedArguments: (`roomId`: String, `eventId`: String)?
    public var getNotificationItemRoomIdEventIdReceivedInvocations: [(`roomId`: String, `eventId`: String)] = []
    public var getNotificationItemRoomIdEventIdReturnValue: NotificationItem!
    public var getNotificationItemRoomIdEventIdClosure: ((String, String) throws -> NotificationItem)?

    public func `getNotificationItem`(`roomId`: String, `eventId`: String) throws -> NotificationItem {
        if let error = getNotificationItemRoomIdEventIdThrowableError {
            throw error
        }
        getNotificationItemRoomIdEventIdCallsCount += 1
        getNotificationItemRoomIdEventIdReceivedArguments = (roomId: roomId, eventId: eventId)
        getNotificationItemRoomIdEventIdReceivedInvocations.append((roomId: roomId, eventId: eventId))
        if let getNotificationItemRoomIdEventIdClosure = getNotificationItemRoomIdEventIdClosure {
            return try getNotificationItemRoomIdEventIdClosure(`roomId`, `eventId`)
        } else {
            return getNotificationItemRoomIdEventIdReturnValue
        }
    }
    //MARK: - `getProfile`

    public var getProfileUserIdThrowableError: Error?
    public var getProfileUserIdCallsCount = 0
    public var getProfileUserIdCalled: Bool {
        return getProfileUserIdCallsCount > 0
    }
    public var getProfileUserIdReceivedUserId: String?
    public var getProfileUserIdReceivedInvocations: [String] = []
    public var getProfileUserIdReturnValue: UserProfile!
    public var getProfileUserIdClosure: ((String) throws -> UserProfile)?

    public func `getProfile`(`userId`: String) throws -> UserProfile {
        if let error = getProfileUserIdThrowableError {
            throw error
        }
        getProfileUserIdCallsCount += 1
        getProfileUserIdReceivedUserId = userId
        getProfileUserIdReceivedInvocations.append(`userId`)
        if let getProfileUserIdClosure = getProfileUserIdClosure {
            return try getProfileUserIdClosure(`userId`)
        } else {
            return getProfileUserIdReturnValue
        }
    }
    //MARK: - `getSessionVerificationController`

    public var getSessionVerificationControllerThrowableError: Error?
    public var getSessionVerificationControllerCallsCount = 0
    public var getSessionVerificationControllerCalled: Bool {
        return getSessionVerificationControllerCallsCount > 0
    }
    public var getSessionVerificationControllerReturnValue: SessionVerificationController!
    public var getSessionVerificationControllerClosure: (() throws -> SessionVerificationController)?

    public func `getSessionVerificationController`() throws -> SessionVerificationController {
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
    //MARK: - `homeserver`

    public var homeserverCallsCount = 0
    public var homeserverCalled: Bool {
        return homeserverCallsCount > 0
    }
    public var homeserverReturnValue: String!
    public var homeserverClosure: (() -> String)?

    public func `homeserver`() -> String {
        homeserverCallsCount += 1
        if let homeserverClosure = homeserverClosure {
            return homeserverClosure()
        } else {
            return homeserverReturnValue
        }
    }
    //MARK: - `ignoreUser`

    public var ignoreUserUserIdThrowableError: Error?
    public var ignoreUserUserIdCallsCount = 0
    public var ignoreUserUserIdCalled: Bool {
        return ignoreUserUserIdCallsCount > 0
    }
    public var ignoreUserUserIdReceivedUserId: String?
    public var ignoreUserUserIdReceivedInvocations: [String] = []
    public var ignoreUserUserIdClosure: ((String) throws -> Void)?

    public func `ignoreUser`(`userId`: String) throws {
        if let error = ignoreUserUserIdThrowableError {
            throw error
        }
        ignoreUserUserIdCallsCount += 1
        ignoreUserUserIdReceivedUserId = userId
        ignoreUserUserIdReceivedInvocations.append(`userId`)
        try ignoreUserUserIdClosure?(`userId`)
    }
    //MARK: - `login`

    public var loginUsernamePasswordInitialDeviceNameDeviceIdThrowableError: Error?
    public var loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount = 0
    public var loginUsernamePasswordInitialDeviceNameDeviceIdCalled: Bool {
        return loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount > 0
    }
    public var loginUsernamePasswordInitialDeviceNameDeviceIdReceivedArguments: (`username`: String, `password`: String, `initialDeviceName`: String?, `deviceId`: String?)?
    public var loginUsernamePasswordInitialDeviceNameDeviceIdReceivedInvocations: [(`username`: String, `password`: String, `initialDeviceName`: String?, `deviceId`: String?)] = []
    public var loginUsernamePasswordInitialDeviceNameDeviceIdClosure: ((String, String, String?, String?) throws -> Void)?

    public func `login`(`username`: String, `password`: String, `initialDeviceName`: String?, `deviceId`: String?) throws {
        if let error = loginUsernamePasswordInitialDeviceNameDeviceIdThrowableError {
            throw error
        }
        loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount += 1
        loginUsernamePasswordInitialDeviceNameDeviceIdReceivedArguments = (username: username, password: password, initialDeviceName: initialDeviceName, deviceId: deviceId)
        loginUsernamePasswordInitialDeviceNameDeviceIdReceivedInvocations.append((username: username, password: password, initialDeviceName: initialDeviceName, deviceId: deviceId))
        try loginUsernamePasswordInitialDeviceNameDeviceIdClosure?(`username`, `password`, `initialDeviceName`, `deviceId`)
    }
    //MARK: - `logout`

    public var logoutThrowableError: Error?
    public var logoutCallsCount = 0
    public var logoutCalled: Bool {
        return logoutCallsCount > 0
    }
    public var logoutClosure: (() throws -> Void)?

    public func `logout`() throws {
        if let error = logoutThrowableError {
            throw error
        }
        logoutCallsCount += 1
        try logoutClosure?()
    }
    //MARK: - `restoreSession`

    public var restoreSessionSessionThrowableError: Error?
    public var restoreSessionSessionCallsCount = 0
    public var restoreSessionSessionCalled: Bool {
        return restoreSessionSessionCallsCount > 0
    }
    public var restoreSessionSessionReceivedSession: Session?
    public var restoreSessionSessionReceivedInvocations: [Session] = []
    public var restoreSessionSessionClosure: ((Session) throws -> Void)?

    public func `restoreSession`(`session`: Session) throws {
        if let error = restoreSessionSessionThrowableError {
            throw error
        }
        restoreSessionSessionCallsCount += 1
        restoreSessionSessionReceivedSession = session
        restoreSessionSessionReceivedInvocations.append(`session`)
        try restoreSessionSessionClosure?(`session`)
    }
    //MARK: - `rooms`

    public var roomsCallsCount = 0
    public var roomsCalled: Bool {
        return roomsCallsCount > 0
    }
    public var roomsReturnValue: [Room]!
    public var roomsClosure: (() -> [Room])?

    public func `rooms`() -> [Room] {
        roomsCallsCount += 1
        if let roomsClosure = roomsClosure {
            return roomsClosure()
        } else {
            return roomsReturnValue
        }
    }
    //MARK: - `searchUsers`

    public var searchUsersSearchTermLimitThrowableError: Error?
    public var searchUsersSearchTermLimitCallsCount = 0
    public var searchUsersSearchTermLimitCalled: Bool {
        return searchUsersSearchTermLimitCallsCount > 0
    }
    public var searchUsersSearchTermLimitReceivedArguments: (`searchTerm`: String, `limit`: UInt64)?
    public var searchUsersSearchTermLimitReceivedInvocations: [(`searchTerm`: String, `limit`: UInt64)] = []
    public var searchUsersSearchTermLimitReturnValue: SearchUsersResults!
    public var searchUsersSearchTermLimitClosure: ((String, UInt64) throws -> SearchUsersResults)?

    public func `searchUsers`(`searchTerm`: String, `limit`: UInt64) throws -> SearchUsersResults {
        if let error = searchUsersSearchTermLimitThrowableError {
            throw error
        }
        searchUsersSearchTermLimitCallsCount += 1
        searchUsersSearchTermLimitReceivedArguments = (searchTerm: searchTerm, limit: limit)
        searchUsersSearchTermLimitReceivedInvocations.append((searchTerm: searchTerm, limit: limit))
        if let searchUsersSearchTermLimitClosure = searchUsersSearchTermLimitClosure {
            return try searchUsersSearchTermLimitClosure(`searchTerm`, `limit`)
        } else {
            return searchUsersSearchTermLimitReturnValue
        }
    }
    //MARK: - `session`

    public var sessionThrowableError: Error?
    public var sessionCallsCount = 0
    public var sessionCalled: Bool {
        return sessionCallsCount > 0
    }
    public var sessionReturnValue: Session!
    public var sessionClosure: (() throws -> Session)?

    public func `session`() throws -> Session {
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
    //MARK: - `setAccountData`

    public var setAccountDataEventTypeContentThrowableError: Error?
    public var setAccountDataEventTypeContentCallsCount = 0
    public var setAccountDataEventTypeContentCalled: Bool {
        return setAccountDataEventTypeContentCallsCount > 0
    }
    public var setAccountDataEventTypeContentReceivedArguments: (`eventType`: String, `content`: String)?
    public var setAccountDataEventTypeContentReceivedInvocations: [(`eventType`: String, `content`: String)] = []
    public var setAccountDataEventTypeContentClosure: ((String, String) throws -> Void)?

    public func `setAccountData`(`eventType`: String, `content`: String) throws {
        if let error = setAccountDataEventTypeContentThrowableError {
            throw error
        }
        setAccountDataEventTypeContentCallsCount += 1
        setAccountDataEventTypeContentReceivedArguments = (eventType: eventType, content: content)
        setAccountDataEventTypeContentReceivedInvocations.append((eventType: eventType, content: content))
        try setAccountDataEventTypeContentClosure?(`eventType`, `content`)
    }
    //MARK: - `setDelegate`

    public var setDelegateDelegateCallsCount = 0
    public var setDelegateDelegateCalled: Bool {
        return setDelegateDelegateCallsCount > 0
    }
    public var setDelegateDelegateReceivedDelegate: ClientDelegate?
    public var setDelegateDelegateReceivedInvocations: [ClientDelegate?] = []
    public var setDelegateDelegateClosure: ((ClientDelegate?) -> Void)?

    public func `setDelegate`(`delegate`: ClientDelegate?) {
        setDelegateDelegateCallsCount += 1
        setDelegateDelegateReceivedDelegate = delegate
        setDelegateDelegateReceivedInvocations.append(`delegate`)
        setDelegateDelegateClosure?(`delegate`)
    }
    //MARK: - `setDisplayName`

    public var setDisplayNameNameThrowableError: Error?
    public var setDisplayNameNameCallsCount = 0
    public var setDisplayNameNameCalled: Bool {
        return setDisplayNameNameCallsCount > 0
    }
    public var setDisplayNameNameReceivedName: String?
    public var setDisplayNameNameReceivedInvocations: [String] = []
    public var setDisplayNameNameClosure: ((String) throws -> Void)?

    public func `setDisplayName`(`name`: String) throws {
        if let error = setDisplayNameNameThrowableError {
            throw error
        }
        setDisplayNameNameCallsCount += 1
        setDisplayNameNameReceivedName = name
        setDisplayNameNameReceivedInvocations.append(`name`)
        try setDisplayNameNameClosure?(`name`)
    }
    //MARK: - `setNotificationDelegate`

    public var setNotificationDelegateNotificationDelegateCallsCount = 0
    public var setNotificationDelegateNotificationDelegateCalled: Bool {
        return setNotificationDelegateNotificationDelegateCallsCount > 0
    }
    public var setNotificationDelegateNotificationDelegateReceivedNotificationDelegate: NotificationDelegate?
    public var setNotificationDelegateNotificationDelegateReceivedInvocations: [NotificationDelegate?] = []
    public var setNotificationDelegateNotificationDelegateClosure: ((NotificationDelegate?) -> Void)?

    public func `setNotificationDelegate`(`notificationDelegate`: NotificationDelegate?) {
        setNotificationDelegateNotificationDelegateCallsCount += 1
        setNotificationDelegateNotificationDelegateReceivedNotificationDelegate = notificationDelegate
        setNotificationDelegateNotificationDelegateReceivedInvocations.append(`notificationDelegate`)
        setNotificationDelegateNotificationDelegateClosure?(`notificationDelegate`)
    }
    //MARK: - `setPusher`

    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangThrowableError: Error?
    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCallsCount = 0
    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCalled: Bool {
        return setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCallsCount > 0
    }
    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedArguments: (`identifiers`: PusherIdentifiers, `kind`: PusherKind, `appDisplayName`: String, `deviceDisplayName`: String, `profileTag`: String?, `lang`: String)?
    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedInvocations: [(`identifiers`: PusherIdentifiers, `kind`: PusherKind, `appDisplayName`: String, `deviceDisplayName`: String, `profileTag`: String?, `lang`: String)] = []
    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangClosure: ((PusherIdentifiers, PusherKind, String, String, String?, String) throws -> Void)?

    public func `setPusher`(`identifiers`: PusherIdentifiers, `kind`: PusherKind, `appDisplayName`: String, `deviceDisplayName`: String, `profileTag`: String?, `lang`: String) throws {
        if let error = setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangThrowableError {
            throw error
        }
        setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCallsCount += 1
        setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedArguments = (identifiers: identifiers, kind: kind, appDisplayName: appDisplayName, deviceDisplayName: deviceDisplayName, profileTag: profileTag, lang: lang)
        setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedInvocations.append((identifiers: identifiers, kind: kind, appDisplayName: appDisplayName, deviceDisplayName: deviceDisplayName, profileTag: profileTag, lang: lang))
        try setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangClosure?(`identifiers`, `kind`, `appDisplayName`, `deviceDisplayName`, `profileTag`, `lang`)
    }
    //MARK: - `slidingSync`

    public var slidingSyncIdThrowableError: Error?
    public var slidingSyncIdCallsCount = 0
    public var slidingSyncIdCalled: Bool {
        return slidingSyncIdCallsCount > 0
    }
    public var slidingSyncIdReceivedId: String?
    public var slidingSyncIdReceivedInvocations: [String] = []
    public var slidingSyncIdReturnValue: SlidingSyncBuilder!
    public var slidingSyncIdClosure: ((String) throws -> SlidingSyncBuilder)?

    public func `slidingSync`(`id`: String) throws -> SlidingSyncBuilder {
        if let error = slidingSyncIdThrowableError {
            throw error
        }
        slidingSyncIdCallsCount += 1
        slidingSyncIdReceivedId = id
        slidingSyncIdReceivedInvocations.append(`id`)
        if let slidingSyncIdClosure = slidingSyncIdClosure {
            return try slidingSyncIdClosure(`id`)
        } else {
            return slidingSyncIdReturnValue
        }
    }
    //MARK: - `unignoreUser`

    public var unignoreUserUserIdThrowableError: Error?
    public var unignoreUserUserIdCallsCount = 0
    public var unignoreUserUserIdCalled: Bool {
        return unignoreUserUserIdCallsCount > 0
    }
    public var unignoreUserUserIdReceivedUserId: String?
    public var unignoreUserUserIdReceivedInvocations: [String] = []
    public var unignoreUserUserIdClosure: ((String) throws -> Void)?

    public func `unignoreUser`(`userId`: String) throws {
        if let error = unignoreUserUserIdThrowableError {
            throw error
        }
        unignoreUserUserIdCallsCount += 1
        unignoreUserUserIdReceivedUserId = userId
        unignoreUserUserIdReceivedInvocations.append(`userId`)
        try unignoreUserUserIdClosure?(`userId`)
    }
    //MARK: - `uploadMedia`

    public var uploadMediaMimeTypeDataThrowableError: Error?
    public var uploadMediaMimeTypeDataCallsCount = 0
    public var uploadMediaMimeTypeDataCalled: Bool {
        return uploadMediaMimeTypeDataCallsCount > 0
    }
    public var uploadMediaMimeTypeDataReceivedArguments: (`mimeType`: String, `data`: [UInt8])?
    public var uploadMediaMimeTypeDataReceivedInvocations: [(`mimeType`: String, `data`: [UInt8])] = []
    public var uploadMediaMimeTypeDataReturnValue: String!
    public var uploadMediaMimeTypeDataClosure: ((String, [UInt8]) throws -> String)?

    public func `uploadMedia`(`mimeType`: String, `data`: [UInt8]) throws -> String {
        if let error = uploadMediaMimeTypeDataThrowableError {
            throw error
        }
        uploadMediaMimeTypeDataCallsCount += 1
        uploadMediaMimeTypeDataReceivedArguments = (mimeType: mimeType, data: data)
        uploadMediaMimeTypeDataReceivedInvocations.append((mimeType: mimeType, data: data))
        if let uploadMediaMimeTypeDataClosure = uploadMediaMimeTypeDataClosure {
            return try uploadMediaMimeTypeDataClosure(`mimeType`, `data`)
        } else {
            return uploadMediaMimeTypeDataReturnValue
        }
    }
    //MARK: - `userId`

    public var userIdThrowableError: Error?
    public var userIdCallsCount = 0
    public var userIdCalled: Bool {
        return userIdCallsCount > 0
    }
    public var userIdReturnValue: String!
    public var userIdClosure: (() throws -> String)?

    public func `userId`() throws -> String {
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
