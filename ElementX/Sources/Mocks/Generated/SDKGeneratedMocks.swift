// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
import Foundation
import MatrixRustSDK
class SDKClientMock: SDKClientProtocol {

    //MARK: - accountData

    public var accountDataEventTypeThrowableError: Error?
    var accountDataEventTypeUnderlyingCallsCount = 0
    public var accountDataEventTypeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return accountDataEventTypeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = accountDataEventTypeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                accountDataEventTypeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    accountDataEventTypeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var accountDataEventTypeCalled: Bool {
        return accountDataEventTypeCallsCount > 0
    }
    public var accountDataEventTypeReceivedEventType: String?
    public var accountDataEventTypeReceivedInvocations: [String] = []

    var accountDataEventTypeUnderlyingReturnValue: String?
    public var accountDataEventTypeReturnValue: String? {
        get {
            if Thread.isMainThread {
                return accountDataEventTypeUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = accountDataEventTypeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                accountDataEventTypeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    accountDataEventTypeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    public var accountDataEventTypeClosure: ((String) async throws -> String?)?

    public func accountData(eventType: String) async throws -> String? {
        if let error = accountDataEventTypeThrowableError {
            throw error
        }
        accountDataEventTypeCallsCount += 1
        accountDataEventTypeReceivedEventType = eventType
        accountDataEventTypeReceivedInvocations.append(eventType)
        if let accountDataEventTypeClosure = accountDataEventTypeClosure {
            return try await accountDataEventTypeClosure(eventType)
        } else {
            return accountDataEventTypeReturnValue
        }
    }
    //MARK: - accountUrl

    public var accountUrlActionThrowableError: Error?
    var accountUrlActionUnderlyingCallsCount = 0
    public var accountUrlActionCallsCount: Int {
        get {
            if Thread.isMainThread {
                return accountUrlActionUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = accountUrlActionUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                accountUrlActionUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    accountUrlActionUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var accountUrlActionCalled: Bool {
        return accountUrlActionCallsCount > 0
    }
    public var accountUrlActionReceivedAction: AccountManagementAction?
    public var accountUrlActionReceivedInvocations: [AccountManagementAction?] = []

    var accountUrlActionUnderlyingReturnValue: String?
    public var accountUrlActionReturnValue: String? {
        get {
            if Thread.isMainThread {
                return accountUrlActionUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = accountUrlActionUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                accountUrlActionUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    accountUrlActionUnderlyingReturnValue = newValue
                }
            }
        }
    }
    public var accountUrlActionClosure: ((AccountManagementAction?) async throws -> String?)?

    public func accountUrl(action: AccountManagementAction?) async throws -> String? {
        if let error = accountUrlActionThrowableError {
            throw error
        }
        accountUrlActionCallsCount += 1
        accountUrlActionReceivedAction = action
        accountUrlActionReceivedInvocations.append(action)
        if let accountUrlActionClosure = accountUrlActionClosure {
            return try await accountUrlActionClosure(action)
        } else {
            return accountUrlActionReturnValue
        }
    }
    //MARK: - avatarUrl

    public var avatarUrlThrowableError: Error?
    var avatarUrlUnderlyingCallsCount = 0
    public var avatarUrlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return avatarUrlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = avatarUrlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                avatarUrlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    avatarUrlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var avatarUrlCalled: Bool {
        return avatarUrlCallsCount > 0
    }

    var avatarUrlUnderlyingReturnValue: String?
    public var avatarUrlReturnValue: String? {
        get {
            if Thread.isMainThread {
                return avatarUrlUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = avatarUrlUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                avatarUrlUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    avatarUrlUnderlyingReturnValue = newValue
                }
            }
        }
    }
    public var avatarUrlClosure: (() async throws -> String?)?

    public func avatarUrl() async throws -> String? {
        if let error = avatarUrlThrowableError {
            throw error
        }
        avatarUrlCallsCount += 1
        if let avatarUrlClosure = avatarUrlClosure {
            return try await avatarUrlClosure()
        } else {
            return avatarUrlReturnValue
        }
    }
    //MARK: - cachedAvatarUrl

    public var cachedAvatarUrlThrowableError: Error?
    var cachedAvatarUrlUnderlyingCallsCount = 0
    public var cachedAvatarUrlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return cachedAvatarUrlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = cachedAvatarUrlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                cachedAvatarUrlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    cachedAvatarUrlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var cachedAvatarUrlCalled: Bool {
        return cachedAvatarUrlCallsCount > 0
    }

    var cachedAvatarUrlUnderlyingReturnValue: String?
    public var cachedAvatarUrlReturnValue: String? {
        get {
            if Thread.isMainThread {
                return cachedAvatarUrlUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = cachedAvatarUrlUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                cachedAvatarUrlUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    cachedAvatarUrlUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var createRoomRequestUnderlyingCallsCount = 0
    public var createRoomRequestCallsCount: Int {
        get {
            if Thread.isMainThread {
                return createRoomRequestUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = createRoomRequestUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                createRoomRequestUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    createRoomRequestUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var createRoomRequestCalled: Bool {
        return createRoomRequestCallsCount > 0
    }
    public var createRoomRequestReceivedRequest: CreateRoomParameters?
    public var createRoomRequestReceivedInvocations: [CreateRoomParameters] = []

    var createRoomRequestUnderlyingReturnValue: String!
    public var createRoomRequestReturnValue: String! {
        get {
            if Thread.isMainThread {
                return createRoomRequestUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = createRoomRequestUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                createRoomRequestUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    createRoomRequestUnderlyingReturnValue = newValue
                }
            }
        }
    }
    public var createRoomRequestClosure: ((CreateRoomParameters) async throws -> String)?

    public func createRoom(request: CreateRoomParameters) async throws -> String {
        if let error = createRoomRequestThrowableError {
            throw error
        }
        createRoomRequestCallsCount += 1
        createRoomRequestReceivedRequest = request
        createRoomRequestReceivedInvocations.append(request)
        if let createRoomRequestClosure = createRoomRequestClosure {
            return try await createRoomRequestClosure(request)
        } else {
            return createRoomRequestReturnValue
        }
    }
    //MARK: - deletePusher

    public var deletePusherIdentifiersThrowableError: Error?
    var deletePusherIdentifiersUnderlyingCallsCount = 0
    public var deletePusherIdentifiersCallsCount: Int {
        get {
            if Thread.isMainThread {
                return deletePusherIdentifiersUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = deletePusherIdentifiersUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                deletePusherIdentifiersUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    deletePusherIdentifiersUnderlyingCallsCount = newValue
                }
            }
        }
    }
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
    var deviceIdUnderlyingCallsCount = 0
    public var deviceIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return deviceIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = deviceIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                deviceIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    deviceIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var deviceIdCalled: Bool {
        return deviceIdCallsCount > 0
    }

    var deviceIdUnderlyingReturnValue: String!
    public var deviceIdReturnValue: String! {
        get {
            if Thread.isMainThread {
                return deviceIdUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = deviceIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                deviceIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    deviceIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var displayNameUnderlyingCallsCount = 0
    public var displayNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return displayNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = displayNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                displayNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    displayNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var displayNameCalled: Bool {
        return displayNameCallsCount > 0
    }

    var displayNameUnderlyingReturnValue: String!
    public var displayNameReturnValue: String! {
        get {
            if Thread.isMainThread {
                return displayNameUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = displayNameUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                displayNameUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    displayNameUnderlyingReturnValue = newValue
                }
            }
        }
    }
    public var displayNameClosure: (() async throws -> String)?

    public func displayName() async throws -> String {
        if let error = displayNameThrowableError {
            throw error
        }
        displayNameCallsCount += 1
        if let displayNameClosure = displayNameClosure {
            return try await displayNameClosure()
        } else {
            return displayNameReturnValue
        }
    }
    //MARK: - encryption

    var encryptionUnderlyingCallsCount = 0
    public var encryptionCallsCount: Int {
        get {
            if Thread.isMainThread {
                return encryptionUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = encryptionUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                encryptionUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    encryptionUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var encryptionCalled: Bool {
        return encryptionCallsCount > 0
    }

    var encryptionUnderlyingReturnValue: Encryption!
    public var encryptionReturnValue: Encryption! {
        get {
            if Thread.isMainThread {
                return encryptionUnderlyingReturnValue
            } else {
                var returnValue: Encryption? = nil
                DispatchQueue.main.sync {
                    returnValue = encryptionUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                encryptionUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    encryptionUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var getDmRoomUserIdUnderlyingCallsCount = 0
    public var getDmRoomUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getDmRoomUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getDmRoomUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getDmRoomUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getDmRoomUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var getDmRoomUserIdCalled: Bool {
        return getDmRoomUserIdCallsCount > 0
    }
    public var getDmRoomUserIdReceivedUserId: String?
    public var getDmRoomUserIdReceivedInvocations: [String] = []

    var getDmRoomUserIdUnderlyingReturnValue: Room?
    public var getDmRoomUserIdReturnValue: Room? {
        get {
            if Thread.isMainThread {
                return getDmRoomUserIdUnderlyingReturnValue
            } else {
                var returnValue: Room?? = nil
                DispatchQueue.main.sync {
                    returnValue = getDmRoomUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getDmRoomUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getDmRoomUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var getMediaContentMediaSourceUnderlyingCallsCount = 0
    public var getMediaContentMediaSourceCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getMediaContentMediaSourceUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getMediaContentMediaSourceUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getMediaContentMediaSourceUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getMediaContentMediaSourceUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var getMediaContentMediaSourceCalled: Bool {
        return getMediaContentMediaSourceCallsCount > 0
    }
    public var getMediaContentMediaSourceReceivedMediaSource: MediaSource?
    public var getMediaContentMediaSourceReceivedInvocations: [MediaSource] = []

    var getMediaContentMediaSourceUnderlyingReturnValue: Data!
    public var getMediaContentMediaSourceReturnValue: Data! {
        get {
            if Thread.isMainThread {
                return getMediaContentMediaSourceUnderlyingReturnValue
            } else {
                var returnValue: Data? = nil
                DispatchQueue.main.sync {
                    returnValue = getMediaContentMediaSourceUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getMediaContentMediaSourceUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getMediaContentMediaSourceUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingCallsCount = 0
    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirCalled: Bool {
        return getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirCallsCount > 0
    }
    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReceivedArguments: (mediaSource: MediaSource, body: String?, mimeType: String, useCache: Bool, tempDir: String?)?
    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReceivedInvocations: [(mediaSource: MediaSource, body: String?, mimeType: String, useCache: Bool, tempDir: String?)] = []

    var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingReturnValue: MediaFileHandle!
    public var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReturnValue: MediaFileHandle! {
        get {
            if Thread.isMainThread {
                return getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingReturnValue
            } else {
                var returnValue: MediaFileHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var getMediaThumbnailMediaSourceWidthHeightUnderlyingCallsCount = 0
    public var getMediaThumbnailMediaSourceWidthHeightCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getMediaThumbnailMediaSourceWidthHeightUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getMediaThumbnailMediaSourceWidthHeightUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getMediaThumbnailMediaSourceWidthHeightUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getMediaThumbnailMediaSourceWidthHeightUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var getMediaThumbnailMediaSourceWidthHeightCalled: Bool {
        return getMediaThumbnailMediaSourceWidthHeightCallsCount > 0
    }
    public var getMediaThumbnailMediaSourceWidthHeightReceivedArguments: (mediaSource: MediaSource, width: UInt64, height: UInt64)?
    public var getMediaThumbnailMediaSourceWidthHeightReceivedInvocations: [(mediaSource: MediaSource, width: UInt64, height: UInt64)] = []

    var getMediaThumbnailMediaSourceWidthHeightUnderlyingReturnValue: Data!
    public var getMediaThumbnailMediaSourceWidthHeightReturnValue: Data! {
        get {
            if Thread.isMainThread {
                return getMediaThumbnailMediaSourceWidthHeightUnderlyingReturnValue
            } else {
                var returnValue: Data? = nil
                DispatchQueue.main.sync {
                    returnValue = getMediaThumbnailMediaSourceWidthHeightUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getMediaThumbnailMediaSourceWidthHeightUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getMediaThumbnailMediaSourceWidthHeightUnderlyingReturnValue = newValue
                }
            }
        }
    }
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

    var getNotificationSettingsUnderlyingCallsCount = 0
    public var getNotificationSettingsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getNotificationSettingsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getNotificationSettingsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getNotificationSettingsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getNotificationSettingsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var getNotificationSettingsCalled: Bool {
        return getNotificationSettingsCallsCount > 0
    }

    var getNotificationSettingsUnderlyingReturnValue: NotificationSettings!
    public var getNotificationSettingsReturnValue: NotificationSettings! {
        get {
            if Thread.isMainThread {
                return getNotificationSettingsUnderlyingReturnValue
            } else {
                var returnValue: NotificationSettings? = nil
                DispatchQueue.main.sync {
                    returnValue = getNotificationSettingsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getNotificationSettingsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getNotificationSettingsUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var getProfileUserIdUnderlyingCallsCount = 0
    public var getProfileUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getProfileUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getProfileUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getProfileUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getProfileUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var getProfileUserIdCalled: Bool {
        return getProfileUserIdCallsCount > 0
    }
    public var getProfileUserIdReceivedUserId: String?
    public var getProfileUserIdReceivedInvocations: [String] = []

    var getProfileUserIdUnderlyingReturnValue: UserProfile!
    public var getProfileUserIdReturnValue: UserProfile! {
        get {
            if Thread.isMainThread {
                return getProfileUserIdUnderlyingReturnValue
            } else {
                var returnValue: UserProfile? = nil
                DispatchQueue.main.sync {
                    returnValue = getProfileUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getProfileUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getProfileUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    public var getProfileUserIdClosure: ((String) async throws -> UserProfile)?

    public func getProfile(userId: String) async throws -> UserProfile {
        if let error = getProfileUserIdThrowableError {
            throw error
        }
        getProfileUserIdCallsCount += 1
        getProfileUserIdReceivedUserId = userId
        getProfileUserIdReceivedInvocations.append(userId)
        if let getProfileUserIdClosure = getProfileUserIdClosure {
            return try await getProfileUserIdClosure(userId)
        } else {
            return getProfileUserIdReturnValue
        }
    }
    //MARK: - getRecentlyVisitedRooms

    public var getRecentlyVisitedRoomsThrowableError: Error?
    var getRecentlyVisitedRoomsUnderlyingCallsCount = 0
    public var getRecentlyVisitedRoomsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getRecentlyVisitedRoomsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getRecentlyVisitedRoomsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRecentlyVisitedRoomsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getRecentlyVisitedRoomsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var getRecentlyVisitedRoomsCalled: Bool {
        return getRecentlyVisitedRoomsCallsCount > 0
    }

    var getRecentlyVisitedRoomsUnderlyingReturnValue: [String]!
    public var getRecentlyVisitedRoomsReturnValue: [String]! {
        get {
            if Thread.isMainThread {
                return getRecentlyVisitedRoomsUnderlyingReturnValue
            } else {
                var returnValue: [String]? = nil
                DispatchQueue.main.sync {
                    returnValue = getRecentlyVisitedRoomsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRecentlyVisitedRoomsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getRecentlyVisitedRoomsUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    //MARK: - getRoomPreview

    public var getRoomPreviewRoomIdOrAliasThrowableError: Error?
    var getRoomPreviewRoomIdOrAliasUnderlyingCallsCount = 0
    public var getRoomPreviewRoomIdOrAliasCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getRoomPreviewRoomIdOrAliasUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomPreviewRoomIdOrAliasUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomPreviewRoomIdOrAliasUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomPreviewRoomIdOrAliasUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var getRoomPreviewRoomIdOrAliasCalled: Bool {
        return getRoomPreviewRoomIdOrAliasCallsCount > 0
    }
    public var getRoomPreviewRoomIdOrAliasReceivedRoomIdOrAlias: String?
    public var getRoomPreviewRoomIdOrAliasReceivedInvocations: [String] = []

    var getRoomPreviewRoomIdOrAliasUnderlyingReturnValue: RoomPreview!
    public var getRoomPreviewRoomIdOrAliasReturnValue: RoomPreview! {
        get {
            if Thread.isMainThread {
                return getRoomPreviewRoomIdOrAliasUnderlyingReturnValue
            } else {
                var returnValue: RoomPreview? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomPreviewRoomIdOrAliasUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomPreviewRoomIdOrAliasUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomPreviewRoomIdOrAliasUnderlyingReturnValue = newValue
                }
            }
        }
    }
    public var getRoomPreviewRoomIdOrAliasClosure: ((String) async throws -> RoomPreview)?

    public func getRoomPreview(roomIdOrAlias: String) async throws -> RoomPreview {
        if let error = getRoomPreviewRoomIdOrAliasThrowableError {
            throw error
        }
        getRoomPreviewRoomIdOrAliasCallsCount += 1
        getRoomPreviewRoomIdOrAliasReceivedRoomIdOrAlias = roomIdOrAlias
        getRoomPreviewRoomIdOrAliasReceivedInvocations.append(roomIdOrAlias)
        if let getRoomPreviewRoomIdOrAliasClosure = getRoomPreviewRoomIdOrAliasClosure {
            return try await getRoomPreviewRoomIdOrAliasClosure(roomIdOrAlias)
        } else {
            return getRoomPreviewRoomIdOrAliasReturnValue
        }
    }
    //MARK: - getSessionVerificationController

    public var getSessionVerificationControllerThrowableError: Error?
    var getSessionVerificationControllerUnderlyingCallsCount = 0
    public var getSessionVerificationControllerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getSessionVerificationControllerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getSessionVerificationControllerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getSessionVerificationControllerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getSessionVerificationControllerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var getSessionVerificationControllerCalled: Bool {
        return getSessionVerificationControllerCallsCount > 0
    }

    var getSessionVerificationControllerUnderlyingReturnValue: SessionVerificationController!
    public var getSessionVerificationControllerReturnValue: SessionVerificationController! {
        get {
            if Thread.isMainThread {
                return getSessionVerificationControllerUnderlyingReturnValue
            } else {
                var returnValue: SessionVerificationController? = nil
                DispatchQueue.main.sync {
                    returnValue = getSessionVerificationControllerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getSessionVerificationControllerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getSessionVerificationControllerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    public var getSessionVerificationControllerClosure: (() async throws -> SessionVerificationController)?

    public func getSessionVerificationController() async throws -> SessionVerificationController {
        if let error = getSessionVerificationControllerThrowableError {
            throw error
        }
        getSessionVerificationControllerCallsCount += 1
        if let getSessionVerificationControllerClosure = getSessionVerificationControllerClosure {
            return try await getSessionVerificationControllerClosure()
        } else {
            return getSessionVerificationControllerReturnValue
        }
    }
    //MARK: - homeserver

    var homeserverUnderlyingCallsCount = 0
    public var homeserverCallsCount: Int {
        get {
            if Thread.isMainThread {
                return homeserverUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = homeserverUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                homeserverUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    homeserverUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var homeserverCalled: Bool {
        return homeserverCallsCount > 0
    }

    var homeserverUnderlyingReturnValue: String!
    public var homeserverReturnValue: String! {
        get {
            if Thread.isMainThread {
                return homeserverUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = homeserverUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                homeserverUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    homeserverUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var ignoreUserUserIdUnderlyingCallsCount = 0
    public var ignoreUserUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return ignoreUserUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = ignoreUserUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ignoreUserUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    ignoreUserUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
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
    var ignoredUsersUnderlyingCallsCount = 0
    public var ignoredUsersCallsCount: Int {
        get {
            if Thread.isMainThread {
                return ignoredUsersUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = ignoredUsersUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ignoredUsersUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    ignoredUsersUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var ignoredUsersCalled: Bool {
        return ignoredUsersCallsCount > 0
    }

    var ignoredUsersUnderlyingReturnValue: [String]!
    public var ignoredUsersReturnValue: [String]! {
        get {
            if Thread.isMainThread {
                return ignoredUsersUnderlyingReturnValue
            } else {
                var returnValue: [String]? = nil
                DispatchQueue.main.sync {
                    returnValue = ignoredUsersUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ignoredUsersUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    ignoredUsersUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var joinRoomByIdRoomIdUnderlyingCallsCount = 0
    public var joinRoomByIdRoomIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return joinRoomByIdRoomIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = joinRoomByIdRoomIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinRoomByIdRoomIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    joinRoomByIdRoomIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var joinRoomByIdRoomIdCalled: Bool {
        return joinRoomByIdRoomIdCallsCount > 0
    }
    public var joinRoomByIdRoomIdReceivedRoomId: String?
    public var joinRoomByIdRoomIdReceivedInvocations: [String] = []

    var joinRoomByIdRoomIdUnderlyingReturnValue: Room!
    public var joinRoomByIdRoomIdReturnValue: Room! {
        get {
            if Thread.isMainThread {
                return joinRoomByIdRoomIdUnderlyingReturnValue
            } else {
                var returnValue: Room? = nil
                DispatchQueue.main.sync {
                    returnValue = joinRoomByIdRoomIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinRoomByIdRoomIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    joinRoomByIdRoomIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var loginUsernamePasswordInitialDeviceNameDeviceIdUnderlyingCallsCount = 0
    public var loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loginUsernamePasswordInitialDeviceNameDeviceIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loginUsernamePasswordInitialDeviceNameDeviceIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loginUsernamePasswordInitialDeviceNameDeviceIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loginUsernamePasswordInitialDeviceNameDeviceIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var loginUsernamePasswordInitialDeviceNameDeviceIdCalled: Bool {
        return loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount > 0
    }
    public var loginUsernamePasswordInitialDeviceNameDeviceIdReceivedArguments: (username: String, password: String, initialDeviceName: String?, deviceId: String?)?
    public var loginUsernamePasswordInitialDeviceNameDeviceIdReceivedInvocations: [(username: String, password: String, initialDeviceName: String?, deviceId: String?)] = []
    public var loginUsernamePasswordInitialDeviceNameDeviceIdClosure: ((String, String, String?, String?) async throws -> Void)?

    public func login(username: String, password: String, initialDeviceName: String?, deviceId: String?) async throws {
        if let error = loginUsernamePasswordInitialDeviceNameDeviceIdThrowableError {
            throw error
        }
        loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount += 1
        loginUsernamePasswordInitialDeviceNameDeviceIdReceivedArguments = (username: username, password: password, initialDeviceName: initialDeviceName, deviceId: deviceId)
        loginUsernamePasswordInitialDeviceNameDeviceIdReceivedInvocations.append((username: username, password: password, initialDeviceName: initialDeviceName, deviceId: deviceId))
        try await loginUsernamePasswordInitialDeviceNameDeviceIdClosure?(username, password, initialDeviceName, deviceId)
    }
    //MARK: - logout

    public var logoutThrowableError: Error?
    var logoutUnderlyingCallsCount = 0
    public var logoutCallsCount: Int {
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
    public var logoutCalled: Bool {
        return logoutCallsCount > 0
    }

    var logoutUnderlyingReturnValue: String?
    public var logoutReturnValue: String? {
        get {
            if Thread.isMainThread {
                return logoutUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
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
    public var logoutClosure: (() async throws -> String?)?

    public func logout() async throws -> String? {
        if let error = logoutThrowableError {
            throw error
        }
        logoutCallsCount += 1
        if let logoutClosure = logoutClosure {
            return try await logoutClosure()
        } else {
            return logoutReturnValue
        }
    }
    //MARK: - notificationClient

    public var notificationClientProcessSetupThrowableError: Error?
    var notificationClientProcessSetupUnderlyingCallsCount = 0
    public var notificationClientProcessSetupCallsCount: Int {
        get {
            if Thread.isMainThread {
                return notificationClientProcessSetupUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = notificationClientProcessSetupUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                notificationClientProcessSetupUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    notificationClientProcessSetupUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var notificationClientProcessSetupCalled: Bool {
        return notificationClientProcessSetupCallsCount > 0
    }
    public var notificationClientProcessSetupReceivedProcessSetup: NotificationProcessSetup?
    public var notificationClientProcessSetupReceivedInvocations: [NotificationProcessSetup] = []

    var notificationClientProcessSetupUnderlyingReturnValue: NotificationClient!
    public var notificationClientProcessSetupReturnValue: NotificationClient! {
        get {
            if Thread.isMainThread {
                return notificationClientProcessSetupUnderlyingReturnValue
            } else {
                var returnValue: NotificationClient? = nil
                DispatchQueue.main.sync {
                    returnValue = notificationClientProcessSetupUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                notificationClientProcessSetupUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    notificationClientProcessSetupUnderlyingReturnValue = newValue
                }
            }
        }
    }
    public var notificationClientProcessSetupClosure: ((NotificationProcessSetup) async throws -> NotificationClient)?

    public func notificationClient(processSetup: NotificationProcessSetup) async throws -> NotificationClient {
        if let error = notificationClientProcessSetupThrowableError {
            throw error
        }
        notificationClientProcessSetupCallsCount += 1
        notificationClientProcessSetupReceivedProcessSetup = processSetup
        notificationClientProcessSetupReceivedInvocations.append(processSetup)
        if let notificationClientProcessSetupClosure = notificationClientProcessSetupClosure {
            return try await notificationClientProcessSetupClosure(processSetup)
        } else {
            return notificationClientProcessSetupReturnValue
        }
    }
    //MARK: - removeAvatar

    public var removeAvatarThrowableError: Error?
    var removeAvatarUnderlyingCallsCount = 0
    public var removeAvatarCallsCount: Int {
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
    public var removeAvatarCalled: Bool {
        return removeAvatarCallsCount > 0
    }
    public var removeAvatarClosure: (() async throws -> Void)?

    public func removeAvatar() async throws {
        if let error = removeAvatarThrowableError {
            throw error
        }
        removeAvatarCallsCount += 1
        try await removeAvatarClosure?()
    }
    //MARK: - resolveRoomAlias

    public var resolveRoomAliasRoomAliasThrowableError: Error?
    var resolveRoomAliasRoomAliasUnderlyingCallsCount = 0
    public var resolveRoomAliasRoomAliasCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resolveRoomAliasRoomAliasUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resolveRoomAliasRoomAliasUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resolveRoomAliasRoomAliasUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resolveRoomAliasRoomAliasUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var resolveRoomAliasRoomAliasCalled: Bool {
        return resolveRoomAliasRoomAliasCallsCount > 0
    }
    public var resolveRoomAliasRoomAliasReceivedRoomAlias: String?
    public var resolveRoomAliasRoomAliasReceivedInvocations: [String] = []

    var resolveRoomAliasRoomAliasUnderlyingReturnValue: String!
    public var resolveRoomAliasRoomAliasReturnValue: String! {
        get {
            if Thread.isMainThread {
                return resolveRoomAliasRoomAliasUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = resolveRoomAliasRoomAliasUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resolveRoomAliasRoomAliasUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    resolveRoomAliasRoomAliasUnderlyingReturnValue = newValue
                }
            }
        }
    }
    public var resolveRoomAliasRoomAliasClosure: ((String) async throws -> String)?

    public func resolveRoomAlias(roomAlias: String) async throws -> String {
        if let error = resolveRoomAliasRoomAliasThrowableError {
            throw error
        }
        resolveRoomAliasRoomAliasCallsCount += 1
        resolveRoomAliasRoomAliasReceivedRoomAlias = roomAlias
        resolveRoomAliasRoomAliasReceivedInvocations.append(roomAlias)
        if let resolveRoomAliasRoomAliasClosure = resolveRoomAliasRoomAliasClosure {
            return try await resolveRoomAliasRoomAliasClosure(roomAlias)
        } else {
            return resolveRoomAliasRoomAliasReturnValue
        }
    }
    //MARK: - restoreSession

    public var restoreSessionSessionThrowableError: Error?
    var restoreSessionSessionUnderlyingCallsCount = 0
    public var restoreSessionSessionCallsCount: Int {
        get {
            if Thread.isMainThread {
                return restoreSessionSessionUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = restoreSessionSessionUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                restoreSessionSessionUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    restoreSessionSessionUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var restoreSessionSessionCalled: Bool {
        return restoreSessionSessionCallsCount > 0
    }
    public var restoreSessionSessionReceivedSession: Session?
    public var restoreSessionSessionReceivedInvocations: [Session] = []
    public var restoreSessionSessionClosure: ((Session) async throws -> Void)?

    public func restoreSession(session: Session) async throws {
        if let error = restoreSessionSessionThrowableError {
            throw error
        }
        restoreSessionSessionCallsCount += 1
        restoreSessionSessionReceivedSession = session
        restoreSessionSessionReceivedInvocations.append(session)
        try await restoreSessionSessionClosure?(session)
    }
    //MARK: - roomDirectorySearch

    var roomDirectorySearchUnderlyingCallsCount = 0
    public var roomDirectorySearchCallsCount: Int {
        get {
            if Thread.isMainThread {
                return roomDirectorySearchUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = roomDirectorySearchUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomDirectorySearchUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    roomDirectorySearchUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var roomDirectorySearchCalled: Bool {
        return roomDirectorySearchCallsCount > 0
    }

    var roomDirectorySearchUnderlyingReturnValue: RoomDirectorySearch!
    public var roomDirectorySearchReturnValue: RoomDirectorySearch! {
        get {
            if Thread.isMainThread {
                return roomDirectorySearchUnderlyingReturnValue
            } else {
                var returnValue: RoomDirectorySearch? = nil
                DispatchQueue.main.sync {
                    returnValue = roomDirectorySearchUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomDirectorySearchUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    roomDirectorySearchUnderlyingReturnValue = newValue
                }
            }
        }
    }
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

    var roomsUnderlyingCallsCount = 0
    public var roomsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return roomsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = roomsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    roomsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var roomsCalled: Bool {
        return roomsCallsCount > 0
    }

    var roomsUnderlyingReturnValue: [Room]!
    public var roomsReturnValue: [Room]! {
        get {
            if Thread.isMainThread {
                return roomsUnderlyingReturnValue
            } else {
                var returnValue: [Room]? = nil
                DispatchQueue.main.sync {
                    returnValue = roomsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    roomsUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var searchUsersSearchTermLimitUnderlyingCallsCount = 0
    public var searchUsersSearchTermLimitCallsCount: Int {
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
    public var searchUsersSearchTermLimitCalled: Bool {
        return searchUsersSearchTermLimitCallsCount > 0
    }
    public var searchUsersSearchTermLimitReceivedArguments: (searchTerm: String, limit: UInt64)?
    public var searchUsersSearchTermLimitReceivedInvocations: [(searchTerm: String, limit: UInt64)] = []

    var searchUsersSearchTermLimitUnderlyingReturnValue: SearchUsersResults!
    public var searchUsersSearchTermLimitReturnValue: SearchUsersResults! {
        get {
            if Thread.isMainThread {
                return searchUsersSearchTermLimitUnderlyingReturnValue
            } else {
                var returnValue: SearchUsersResults? = nil
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
    public var searchUsersSearchTermLimitClosure: ((String, UInt64) async throws -> SearchUsersResults)?

    public func searchUsers(searchTerm: String, limit: UInt64) async throws -> SearchUsersResults {
        if let error = searchUsersSearchTermLimitThrowableError {
            throw error
        }
        searchUsersSearchTermLimitCallsCount += 1
        searchUsersSearchTermLimitReceivedArguments = (searchTerm: searchTerm, limit: limit)
        searchUsersSearchTermLimitReceivedInvocations.append((searchTerm: searchTerm, limit: limit))
        if let searchUsersSearchTermLimitClosure = searchUsersSearchTermLimitClosure {
            return try await searchUsersSearchTermLimitClosure(searchTerm, limit)
        } else {
            return searchUsersSearchTermLimitReturnValue
        }
    }
    //MARK: - session

    public var sessionThrowableError: Error?
    var sessionUnderlyingCallsCount = 0
    public var sessionCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sessionUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sessionUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sessionUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sessionUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var sessionCalled: Bool {
        return sessionCallsCount > 0
    }

    var sessionUnderlyingReturnValue: Session!
    public var sessionReturnValue: Session! {
        get {
            if Thread.isMainThread {
                return sessionUnderlyingReturnValue
            } else {
                var returnValue: Session? = nil
                DispatchQueue.main.sync {
                    returnValue = sessionUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sessionUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sessionUnderlyingReturnValue = newValue
                }
            }
        }
    }
    public var sessionClosure: (() async throws -> Session)?

    public func session() async throws -> Session {
        if let error = sessionThrowableError {
            throw error
        }
        sessionCallsCount += 1
        if let sessionClosure = sessionClosure {
            return try await sessionClosure()
        } else {
            return sessionReturnValue
        }
    }
    //MARK: - setAccountData

    public var setAccountDataEventTypeContentThrowableError: Error?
    var setAccountDataEventTypeContentUnderlyingCallsCount = 0
    public var setAccountDataEventTypeContentCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setAccountDataEventTypeContentUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setAccountDataEventTypeContentUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setAccountDataEventTypeContentUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setAccountDataEventTypeContentUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var setAccountDataEventTypeContentCalled: Bool {
        return setAccountDataEventTypeContentCallsCount > 0
    }
    public var setAccountDataEventTypeContentReceivedArguments: (eventType: String, content: String)?
    public var setAccountDataEventTypeContentReceivedInvocations: [(eventType: String, content: String)] = []
    public var setAccountDataEventTypeContentClosure: ((String, String) async throws -> Void)?

    public func setAccountData(eventType: String, content: String) async throws {
        if let error = setAccountDataEventTypeContentThrowableError {
            throw error
        }
        setAccountDataEventTypeContentCallsCount += 1
        setAccountDataEventTypeContentReceivedArguments = (eventType: eventType, content: content)
        setAccountDataEventTypeContentReceivedInvocations.append((eventType: eventType, content: content))
        try await setAccountDataEventTypeContentClosure?(eventType, content)
    }
    //MARK: - setDelegate

    var setDelegateDelegateUnderlyingCallsCount = 0
    public var setDelegateDelegateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setDelegateDelegateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setDelegateDelegateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setDelegateDelegateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setDelegateDelegateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var setDelegateDelegateCalled: Bool {
        return setDelegateDelegateCallsCount > 0
    }
    public var setDelegateDelegateReceivedDelegate: ClientDelegate?
    public var setDelegateDelegateReceivedInvocations: [ClientDelegate?] = []

    var setDelegateDelegateUnderlyingReturnValue: TaskHandle?
    public var setDelegateDelegateReturnValue: TaskHandle? {
        get {
            if Thread.isMainThread {
                return setDelegateDelegateUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle?? = nil
                DispatchQueue.main.sync {
                    returnValue = setDelegateDelegateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setDelegateDelegateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    setDelegateDelegateUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var setDisplayNameNameUnderlyingCallsCount = 0
    public var setDisplayNameNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setDisplayNameNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setDisplayNameNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setDisplayNameNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setDisplayNameNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var setDisplayNameNameCalled: Bool {
        return setDisplayNameNameCallsCount > 0
    }
    public var setDisplayNameNameReceivedName: String?
    public var setDisplayNameNameReceivedInvocations: [String] = []
    public var setDisplayNameNameClosure: ((String) async throws -> Void)?

    public func setDisplayName(name: String) async throws {
        if let error = setDisplayNameNameThrowableError {
            throw error
        }
        setDisplayNameNameCallsCount += 1
        setDisplayNameNameReceivedName = name
        setDisplayNameNameReceivedInvocations.append(name)
        try await setDisplayNameNameClosure?(name)
    }
    //MARK: - setPusher

    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangThrowableError: Error?
    var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangUnderlyingCallsCount = 0
    public var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangUnderlyingCallsCount = newValue
                }
            }
        }
    }
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

    var subscribeToIgnoredUsersListenerUnderlyingCallsCount = 0
    public var subscribeToIgnoredUsersListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return subscribeToIgnoredUsersListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToIgnoredUsersListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToIgnoredUsersListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToIgnoredUsersListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var subscribeToIgnoredUsersListenerCalled: Bool {
        return subscribeToIgnoredUsersListenerCallsCount > 0
    }
    public var subscribeToIgnoredUsersListenerReceivedListener: IgnoredUsersListener?
    public var subscribeToIgnoredUsersListenerReceivedInvocations: [IgnoredUsersListener] = []

    var subscribeToIgnoredUsersListenerUnderlyingReturnValue: TaskHandle!
    public var subscribeToIgnoredUsersListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return subscribeToIgnoredUsersListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToIgnoredUsersListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToIgnoredUsersListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToIgnoredUsersListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
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

    var syncServiceUnderlyingCallsCount = 0
    public var syncServiceCallsCount: Int {
        get {
            if Thread.isMainThread {
                return syncServiceUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = syncServiceUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                syncServiceUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    syncServiceUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var syncServiceCalled: Bool {
        return syncServiceCallsCount > 0
    }

    var syncServiceUnderlyingReturnValue: SyncServiceBuilder!
    public var syncServiceReturnValue: SyncServiceBuilder! {
        get {
            if Thread.isMainThread {
                return syncServiceUnderlyingReturnValue
            } else {
                var returnValue: SyncServiceBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = syncServiceUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                syncServiceUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    syncServiceUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var trackRecentlyVisitedRoomRoomUnderlyingCallsCount = 0
    public var trackRecentlyVisitedRoomRoomCallsCount: Int {
        get {
            if Thread.isMainThread {
                return trackRecentlyVisitedRoomRoomUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = trackRecentlyVisitedRoomRoomUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                trackRecentlyVisitedRoomRoomUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    trackRecentlyVisitedRoomRoomUnderlyingCallsCount = newValue
                }
            }
        }
    }
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
    var unignoreUserUserIdUnderlyingCallsCount = 0
    public var unignoreUserUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return unignoreUserUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = unignoreUserUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unignoreUserUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    unignoreUserUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
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
    var uploadAvatarMimeTypeDataUnderlyingCallsCount = 0
    public var uploadAvatarMimeTypeDataCallsCount: Int {
        get {
            if Thread.isMainThread {
                return uploadAvatarMimeTypeDataUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = uploadAvatarMimeTypeDataUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                uploadAvatarMimeTypeDataUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    uploadAvatarMimeTypeDataUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var uploadAvatarMimeTypeDataCalled: Bool {
        return uploadAvatarMimeTypeDataCallsCount > 0
    }
    public var uploadAvatarMimeTypeDataReceivedArguments: (mimeType: String, data: Data)?
    public var uploadAvatarMimeTypeDataReceivedInvocations: [(mimeType: String, data: Data)] = []
    public var uploadAvatarMimeTypeDataClosure: ((String, Data) async throws -> Void)?

    public func uploadAvatar(mimeType: String, data: Data) async throws {
        if let error = uploadAvatarMimeTypeDataThrowableError {
            throw error
        }
        uploadAvatarMimeTypeDataCallsCount += 1
        uploadAvatarMimeTypeDataReceivedArguments = (mimeType: mimeType, data: data)
        uploadAvatarMimeTypeDataReceivedInvocations.append((mimeType: mimeType, data: data))
        try await uploadAvatarMimeTypeDataClosure?(mimeType, data)
    }
    //MARK: - uploadMedia

    public var uploadMediaMimeTypeDataProgressWatcherThrowableError: Error?
    var uploadMediaMimeTypeDataProgressWatcherUnderlyingCallsCount = 0
    public var uploadMediaMimeTypeDataProgressWatcherCallsCount: Int {
        get {
            if Thread.isMainThread {
                return uploadMediaMimeTypeDataProgressWatcherUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = uploadMediaMimeTypeDataProgressWatcherUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                uploadMediaMimeTypeDataProgressWatcherUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    uploadMediaMimeTypeDataProgressWatcherUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var uploadMediaMimeTypeDataProgressWatcherCalled: Bool {
        return uploadMediaMimeTypeDataProgressWatcherCallsCount > 0
    }
    public var uploadMediaMimeTypeDataProgressWatcherReceivedArguments: (mimeType: String, data: Data, progressWatcher: ProgressWatcher?)?
    public var uploadMediaMimeTypeDataProgressWatcherReceivedInvocations: [(mimeType: String, data: Data, progressWatcher: ProgressWatcher?)] = []

    var uploadMediaMimeTypeDataProgressWatcherUnderlyingReturnValue: String!
    public var uploadMediaMimeTypeDataProgressWatcherReturnValue: String! {
        get {
            if Thread.isMainThread {
                return uploadMediaMimeTypeDataProgressWatcherUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = uploadMediaMimeTypeDataProgressWatcherUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                uploadMediaMimeTypeDataProgressWatcherUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    uploadMediaMimeTypeDataProgressWatcherUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
    var userIdUnderlyingCallsCount = 0
    public var userIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return userIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = userIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                userIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    userIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    public var userIdCalled: Bool {
        return userIdCallsCount > 0
    }

    var userIdUnderlyingReturnValue: String!
    public var userIdReturnValue: String! {
        get {
            if Thread.isMainThread {
                return userIdUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = userIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                userIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    userIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
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
