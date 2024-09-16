// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
import Foundation
import MatrixRustSDK
open class ClientSDKMock: MatrixRustSDK.Client {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - abortOidcLogin

    var abortOidcLoginAuthorizationDataUnderlyingCallsCount = 0
    open var abortOidcLoginAuthorizationDataCallsCount: Int {
        get {
            if Thread.isMainThread {
                return abortOidcLoginAuthorizationDataUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = abortOidcLoginAuthorizationDataUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                abortOidcLoginAuthorizationDataUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    abortOidcLoginAuthorizationDataUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var abortOidcLoginAuthorizationDataCalled: Bool {
        return abortOidcLoginAuthorizationDataCallsCount > 0
    }
    open var abortOidcLoginAuthorizationDataReceivedAuthorizationData: OidcAuthorizationData?
    open var abortOidcLoginAuthorizationDataReceivedInvocations: [OidcAuthorizationData] = []
    open var abortOidcLoginAuthorizationDataClosure: ((OidcAuthorizationData) async -> Void)?

    open override func abortOidcLogin(authorizationData: OidcAuthorizationData) async {
        abortOidcLoginAuthorizationDataCallsCount += 1
        abortOidcLoginAuthorizationDataReceivedAuthorizationData = authorizationData
        DispatchQueue.main.async {
            self.abortOidcLoginAuthorizationDataReceivedInvocations.append(authorizationData)
        }
        await abortOidcLoginAuthorizationDataClosure?(authorizationData)
    }

    //MARK: - accountData

    open var accountDataEventTypeThrowableError: Error?
    var accountDataEventTypeUnderlyingCallsCount = 0
    open var accountDataEventTypeCallsCount: Int {
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
    open var accountDataEventTypeCalled: Bool {
        return accountDataEventTypeCallsCount > 0
    }
    open var accountDataEventTypeReceivedEventType: String?
    open var accountDataEventTypeReceivedInvocations: [String] = []

    var accountDataEventTypeUnderlyingReturnValue: String?
    open var accountDataEventTypeReturnValue: String? {
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
    open var accountDataEventTypeClosure: ((String) async throws -> String?)?

    open override func accountData(eventType: String) async throws -> String? {
        if let error = accountDataEventTypeThrowableError {
            throw error
        }
        accountDataEventTypeCallsCount += 1
        accountDataEventTypeReceivedEventType = eventType
        DispatchQueue.main.async {
            self.accountDataEventTypeReceivedInvocations.append(eventType)
        }
        if let accountDataEventTypeClosure = accountDataEventTypeClosure {
            return try await accountDataEventTypeClosure(eventType)
        } else {
            return accountDataEventTypeReturnValue
        }
    }

    //MARK: - accountUrl

    open var accountUrlActionThrowableError: Error?
    var accountUrlActionUnderlyingCallsCount = 0
    open var accountUrlActionCallsCount: Int {
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
    open var accountUrlActionCalled: Bool {
        return accountUrlActionCallsCount > 0
    }
    open var accountUrlActionReceivedAction: AccountManagementAction?
    open var accountUrlActionReceivedInvocations: [AccountManagementAction?] = []

    var accountUrlActionUnderlyingReturnValue: String?
    open var accountUrlActionReturnValue: String? {
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
    open var accountUrlActionClosure: ((AccountManagementAction?) async throws -> String?)?

    open override func accountUrl(action: AccountManagementAction?) async throws -> String? {
        if let error = accountUrlActionThrowableError {
            throw error
        }
        accountUrlActionCallsCount += 1
        accountUrlActionReceivedAction = action
        DispatchQueue.main.async {
            self.accountUrlActionReceivedInvocations.append(action)
        }
        if let accountUrlActionClosure = accountUrlActionClosure {
            return try await accountUrlActionClosure(action)
        } else {
            return accountUrlActionReturnValue
        }
    }

    //MARK: - availableSlidingSyncVersions

    var availableSlidingSyncVersionsUnderlyingCallsCount = 0
    open var availableSlidingSyncVersionsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return availableSlidingSyncVersionsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = availableSlidingSyncVersionsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                availableSlidingSyncVersionsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    availableSlidingSyncVersionsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var availableSlidingSyncVersionsCalled: Bool {
        return availableSlidingSyncVersionsCallsCount > 0
    }

    var availableSlidingSyncVersionsUnderlyingReturnValue: [SlidingSyncVersion]!
    open var availableSlidingSyncVersionsReturnValue: [SlidingSyncVersion]! {
        get {
            if Thread.isMainThread {
                return availableSlidingSyncVersionsUnderlyingReturnValue
            } else {
                var returnValue: [SlidingSyncVersion]? = nil
                DispatchQueue.main.sync {
                    returnValue = availableSlidingSyncVersionsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                availableSlidingSyncVersionsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    availableSlidingSyncVersionsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var availableSlidingSyncVersionsClosure: (() async -> [SlidingSyncVersion])?

    open override func availableSlidingSyncVersions() async -> [SlidingSyncVersion] {
        availableSlidingSyncVersionsCallsCount += 1
        if let availableSlidingSyncVersionsClosure = availableSlidingSyncVersionsClosure {
            return await availableSlidingSyncVersionsClosure()
        } else {
            return availableSlidingSyncVersionsReturnValue
        }
    }

    //MARK: - avatarUrl

    open var avatarUrlThrowableError: Error?
    var avatarUrlUnderlyingCallsCount = 0
    open var avatarUrlCallsCount: Int {
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
    open var avatarUrlCalled: Bool {
        return avatarUrlCallsCount > 0
    }

    var avatarUrlUnderlyingReturnValue: String?
    open var avatarUrlReturnValue: String? {
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
    open var avatarUrlClosure: (() async throws -> String?)?

    open override func avatarUrl() async throws -> String? {
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

    //MARK: - awaitRoomRemoteEcho

    open var awaitRoomRemoteEchoRoomIdThrowableError: Error?
    var awaitRoomRemoteEchoRoomIdUnderlyingCallsCount = 0
    open var awaitRoomRemoteEchoRoomIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return awaitRoomRemoteEchoRoomIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = awaitRoomRemoteEchoRoomIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                awaitRoomRemoteEchoRoomIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    awaitRoomRemoteEchoRoomIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var awaitRoomRemoteEchoRoomIdCalled: Bool {
        return awaitRoomRemoteEchoRoomIdCallsCount > 0
    }
    open var awaitRoomRemoteEchoRoomIdReceivedRoomId: String?
    open var awaitRoomRemoteEchoRoomIdReceivedInvocations: [String] = []

    var awaitRoomRemoteEchoRoomIdUnderlyingReturnValue: Room!
    open var awaitRoomRemoteEchoRoomIdReturnValue: Room! {
        get {
            if Thread.isMainThread {
                return awaitRoomRemoteEchoRoomIdUnderlyingReturnValue
            } else {
                var returnValue: Room? = nil
                DispatchQueue.main.sync {
                    returnValue = awaitRoomRemoteEchoRoomIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                awaitRoomRemoteEchoRoomIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    awaitRoomRemoteEchoRoomIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var awaitRoomRemoteEchoRoomIdClosure: ((String) async throws -> Room)?

    open override func awaitRoomRemoteEcho(roomId: String) async throws -> Room {
        if let error = awaitRoomRemoteEchoRoomIdThrowableError {
            throw error
        }
        awaitRoomRemoteEchoRoomIdCallsCount += 1
        awaitRoomRemoteEchoRoomIdReceivedRoomId = roomId
        DispatchQueue.main.async {
            self.awaitRoomRemoteEchoRoomIdReceivedInvocations.append(roomId)
        }
        if let awaitRoomRemoteEchoRoomIdClosure = awaitRoomRemoteEchoRoomIdClosure {
            return try await awaitRoomRemoteEchoRoomIdClosure(roomId)
        } else {
            return awaitRoomRemoteEchoRoomIdReturnValue
        }
    }

    //MARK: - cachedAvatarUrl

    open var cachedAvatarUrlThrowableError: Error?
    var cachedAvatarUrlUnderlyingCallsCount = 0
    open var cachedAvatarUrlCallsCount: Int {
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
    open var cachedAvatarUrlCalled: Bool {
        return cachedAvatarUrlCallsCount > 0
    }

    var cachedAvatarUrlUnderlyingReturnValue: String?
    open var cachedAvatarUrlReturnValue: String? {
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
    open var cachedAvatarUrlClosure: (() throws -> String?)?

    open override func cachedAvatarUrl() throws -> String? {
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

    //MARK: - canDeactivateAccount

    var canDeactivateAccountUnderlyingCallsCount = 0
    open var canDeactivateAccountCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canDeactivateAccountUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canDeactivateAccountUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canDeactivateAccountUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canDeactivateAccountUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canDeactivateAccountCalled: Bool {
        return canDeactivateAccountCallsCount > 0
    }

    var canDeactivateAccountUnderlyingReturnValue: Bool!
    open var canDeactivateAccountReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canDeactivateAccountUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canDeactivateAccountUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canDeactivateAccountUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canDeactivateAccountUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canDeactivateAccountClosure: (() -> Bool)?

    open override func canDeactivateAccount() -> Bool {
        canDeactivateAccountCallsCount += 1
        if let canDeactivateAccountClosure = canDeactivateAccountClosure {
            return canDeactivateAccountClosure()
        } else {
            return canDeactivateAccountReturnValue
        }
    }

    //MARK: - createRoom

    open var createRoomRequestThrowableError: Error?
    var createRoomRequestUnderlyingCallsCount = 0
    open var createRoomRequestCallsCount: Int {
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
    open var createRoomRequestCalled: Bool {
        return createRoomRequestCallsCount > 0
    }
    open var createRoomRequestReceivedRequest: CreateRoomParameters?
    open var createRoomRequestReceivedInvocations: [CreateRoomParameters] = []

    var createRoomRequestUnderlyingReturnValue: String!
    open var createRoomRequestReturnValue: String! {
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
    open var createRoomRequestClosure: ((CreateRoomParameters) async throws -> String)?

    open override func createRoom(request: CreateRoomParameters) async throws -> String {
        if let error = createRoomRequestThrowableError {
            throw error
        }
        createRoomRequestCallsCount += 1
        createRoomRequestReceivedRequest = request
        DispatchQueue.main.async {
            self.createRoomRequestReceivedInvocations.append(request)
        }
        if let createRoomRequestClosure = createRoomRequestClosure {
            return try await createRoomRequestClosure(request)
        } else {
            return createRoomRequestReturnValue
        }
    }

    //MARK: - deactivateAccount

    open var deactivateAccountAuthDataEraseDataThrowableError: Error?
    var deactivateAccountAuthDataEraseDataUnderlyingCallsCount = 0
    open var deactivateAccountAuthDataEraseDataCallsCount: Int {
        get {
            if Thread.isMainThread {
                return deactivateAccountAuthDataEraseDataUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = deactivateAccountAuthDataEraseDataUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                deactivateAccountAuthDataEraseDataUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    deactivateAccountAuthDataEraseDataUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var deactivateAccountAuthDataEraseDataCalled: Bool {
        return deactivateAccountAuthDataEraseDataCallsCount > 0
    }
    open var deactivateAccountAuthDataEraseDataReceivedArguments: (authData: AuthData?, eraseData: Bool)?
    open var deactivateAccountAuthDataEraseDataReceivedInvocations: [(authData: AuthData?, eraseData: Bool)] = []
    open var deactivateAccountAuthDataEraseDataClosure: ((AuthData?, Bool) async throws -> Void)?

    open override func deactivateAccount(authData: AuthData?, eraseData: Bool) async throws {
        if let error = deactivateAccountAuthDataEraseDataThrowableError {
            throw error
        }
        deactivateAccountAuthDataEraseDataCallsCount += 1
        deactivateAccountAuthDataEraseDataReceivedArguments = (authData: authData, eraseData: eraseData)
        DispatchQueue.main.async {
            self.deactivateAccountAuthDataEraseDataReceivedInvocations.append((authData: authData, eraseData: eraseData))
        }
        try await deactivateAccountAuthDataEraseDataClosure?(authData, eraseData)
    }

    //MARK: - deletePusher

    open var deletePusherIdentifiersThrowableError: Error?
    var deletePusherIdentifiersUnderlyingCallsCount = 0
    open var deletePusherIdentifiersCallsCount: Int {
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
    open var deletePusherIdentifiersCalled: Bool {
        return deletePusherIdentifiersCallsCount > 0
    }
    open var deletePusherIdentifiersReceivedIdentifiers: PusherIdentifiers?
    open var deletePusherIdentifiersReceivedInvocations: [PusherIdentifiers] = []
    open var deletePusherIdentifiersClosure: ((PusherIdentifiers) async throws -> Void)?

    open override func deletePusher(identifiers: PusherIdentifiers) async throws {
        if let error = deletePusherIdentifiersThrowableError {
            throw error
        }
        deletePusherIdentifiersCallsCount += 1
        deletePusherIdentifiersReceivedIdentifiers = identifiers
        DispatchQueue.main.async {
            self.deletePusherIdentifiersReceivedInvocations.append(identifiers)
        }
        try await deletePusherIdentifiersClosure?(identifiers)
    }

    //MARK: - deviceId

    open var deviceIdThrowableError: Error?
    var deviceIdUnderlyingCallsCount = 0
    open var deviceIdCallsCount: Int {
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
    open var deviceIdCalled: Bool {
        return deviceIdCallsCount > 0
    }

    var deviceIdUnderlyingReturnValue: String!
    open var deviceIdReturnValue: String! {
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
    open var deviceIdClosure: (() throws -> String)?

    open override func deviceId() throws -> String {
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

    open var displayNameThrowableError: Error?
    var displayNameUnderlyingCallsCount = 0
    open var displayNameCallsCount: Int {
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
    open var displayNameCalled: Bool {
        return displayNameCallsCount > 0
    }

    var displayNameUnderlyingReturnValue: String!
    open var displayNameReturnValue: String! {
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
    open var displayNameClosure: (() async throws -> String)?

    open override func displayName() async throws -> String {
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

    //MARK: - enableAllSendQueues

    var enableAllSendQueuesEnableUnderlyingCallsCount = 0
    open var enableAllSendQueuesEnableCallsCount: Int {
        get {
            if Thread.isMainThread {
                return enableAllSendQueuesEnableUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = enableAllSendQueuesEnableUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enableAllSendQueuesEnableUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    enableAllSendQueuesEnableUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var enableAllSendQueuesEnableCalled: Bool {
        return enableAllSendQueuesEnableCallsCount > 0
    }
    open var enableAllSendQueuesEnableReceivedEnable: Bool?
    open var enableAllSendQueuesEnableReceivedInvocations: [Bool] = []
    open var enableAllSendQueuesEnableClosure: ((Bool) async -> Void)?

    open override func enableAllSendQueues(enable: Bool) async {
        enableAllSendQueuesEnableCallsCount += 1
        enableAllSendQueuesEnableReceivedEnable = enable
        DispatchQueue.main.async {
            self.enableAllSendQueuesEnableReceivedInvocations.append(enable)
        }
        await enableAllSendQueuesEnableClosure?(enable)
    }

    //MARK: - encryption

    var encryptionUnderlyingCallsCount = 0
    open var encryptionCallsCount: Int {
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
    open var encryptionCalled: Bool {
        return encryptionCallsCount > 0
    }

    var encryptionUnderlyingReturnValue: Encryption!
    open var encryptionReturnValue: Encryption! {
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
    open var encryptionClosure: (() -> Encryption)?

    open override func encryption() -> Encryption {
        encryptionCallsCount += 1
        if let encryptionClosure = encryptionClosure {
            return encryptionClosure()
        } else {
            return encryptionReturnValue
        }
    }

    //MARK: - getDmRoom

    open var getDmRoomUserIdThrowableError: Error?
    var getDmRoomUserIdUnderlyingCallsCount = 0
    open var getDmRoomUserIdCallsCount: Int {
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
    open var getDmRoomUserIdCalled: Bool {
        return getDmRoomUserIdCallsCount > 0
    }
    open var getDmRoomUserIdReceivedUserId: String?
    open var getDmRoomUserIdReceivedInvocations: [String] = []

    var getDmRoomUserIdUnderlyingReturnValue: Room?
    open var getDmRoomUserIdReturnValue: Room? {
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
    open var getDmRoomUserIdClosure: ((String) throws -> Room?)?

    open override func getDmRoom(userId: String) throws -> Room? {
        if let error = getDmRoomUserIdThrowableError {
            throw error
        }
        getDmRoomUserIdCallsCount += 1
        getDmRoomUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.getDmRoomUserIdReceivedInvocations.append(userId)
        }
        if let getDmRoomUserIdClosure = getDmRoomUserIdClosure {
            return try getDmRoomUserIdClosure(userId)
        } else {
            return getDmRoomUserIdReturnValue
        }
    }

    //MARK: - getMediaContent

    open var getMediaContentMediaSourceThrowableError: Error?
    var getMediaContentMediaSourceUnderlyingCallsCount = 0
    open var getMediaContentMediaSourceCallsCount: Int {
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
    open var getMediaContentMediaSourceCalled: Bool {
        return getMediaContentMediaSourceCallsCount > 0
    }
    open var getMediaContentMediaSourceReceivedMediaSource: MediaSource?
    open var getMediaContentMediaSourceReceivedInvocations: [MediaSource] = []

    var getMediaContentMediaSourceUnderlyingReturnValue: Data!
    open var getMediaContentMediaSourceReturnValue: Data! {
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
    open var getMediaContentMediaSourceClosure: ((MediaSource) async throws -> Data)?

    open override func getMediaContent(mediaSource: MediaSource) async throws -> Data {
        if let error = getMediaContentMediaSourceThrowableError {
            throw error
        }
        getMediaContentMediaSourceCallsCount += 1
        getMediaContentMediaSourceReceivedMediaSource = mediaSource
        DispatchQueue.main.async {
            self.getMediaContentMediaSourceReceivedInvocations.append(mediaSource)
        }
        if let getMediaContentMediaSourceClosure = getMediaContentMediaSourceClosure {
            return try await getMediaContentMediaSourceClosure(mediaSource)
        } else {
            return getMediaContentMediaSourceReturnValue
        }
    }

    //MARK: - getMediaFile

    open var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirThrowableError: Error?
    var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingCallsCount = 0
    open var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirCallsCount: Int {
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
    open var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirCalled: Bool {
        return getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirCallsCount > 0
    }
    open var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReceivedArguments: (mediaSource: MediaSource, body: String?, mimeType: String, useCache: Bool, tempDir: String?)?
    open var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReceivedInvocations: [(mediaSource: MediaSource, body: String?, mimeType: String, useCache: Bool, tempDir: String?)] = []

    var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirUnderlyingReturnValue: MediaFileHandle!
    open var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReturnValue: MediaFileHandle! {
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
    open var getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirClosure: ((MediaSource, String?, String, Bool, String?) async throws -> MediaFileHandle)?

    open override func getMediaFile(mediaSource: MediaSource, body: String?, mimeType: String, useCache: Bool, tempDir: String?) async throws -> MediaFileHandle {
        if let error = getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirThrowableError {
            throw error
        }
        getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirCallsCount += 1
        getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReceivedArguments = (mediaSource: mediaSource, body: body, mimeType: mimeType, useCache: useCache, tempDir: tempDir)
        DispatchQueue.main.async {
            self.getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReceivedInvocations.append((mediaSource: mediaSource, body: body, mimeType: mimeType, useCache: useCache, tempDir: tempDir))
        }
        if let getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirClosure = getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirClosure {
            return try await getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirClosure(mediaSource, body, mimeType, useCache, tempDir)
        } else {
            return getMediaFileMediaSourceBodyMimeTypeUseCacheTempDirReturnValue
        }
    }

    //MARK: - getMediaThumbnail

    open var getMediaThumbnailMediaSourceWidthHeightThrowableError: Error?
    var getMediaThumbnailMediaSourceWidthHeightUnderlyingCallsCount = 0
    open var getMediaThumbnailMediaSourceWidthHeightCallsCount: Int {
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
    open var getMediaThumbnailMediaSourceWidthHeightCalled: Bool {
        return getMediaThumbnailMediaSourceWidthHeightCallsCount > 0
    }
    open var getMediaThumbnailMediaSourceWidthHeightReceivedArguments: (mediaSource: MediaSource, width: UInt64, height: UInt64)?
    open var getMediaThumbnailMediaSourceWidthHeightReceivedInvocations: [(mediaSource: MediaSource, width: UInt64, height: UInt64)] = []

    var getMediaThumbnailMediaSourceWidthHeightUnderlyingReturnValue: Data!
    open var getMediaThumbnailMediaSourceWidthHeightReturnValue: Data! {
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
    open var getMediaThumbnailMediaSourceWidthHeightClosure: ((MediaSource, UInt64, UInt64) async throws -> Data)?

    open override func getMediaThumbnail(mediaSource: MediaSource, width: UInt64, height: UInt64) async throws -> Data {
        if let error = getMediaThumbnailMediaSourceWidthHeightThrowableError {
            throw error
        }
        getMediaThumbnailMediaSourceWidthHeightCallsCount += 1
        getMediaThumbnailMediaSourceWidthHeightReceivedArguments = (mediaSource: mediaSource, width: width, height: height)
        DispatchQueue.main.async {
            self.getMediaThumbnailMediaSourceWidthHeightReceivedInvocations.append((mediaSource: mediaSource, width: width, height: height))
        }
        if let getMediaThumbnailMediaSourceWidthHeightClosure = getMediaThumbnailMediaSourceWidthHeightClosure {
            return try await getMediaThumbnailMediaSourceWidthHeightClosure(mediaSource, width, height)
        } else {
            return getMediaThumbnailMediaSourceWidthHeightReturnValue
        }
    }

    //MARK: - getNotificationSettings

    var getNotificationSettingsUnderlyingCallsCount = 0
    open var getNotificationSettingsCallsCount: Int {
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
    open var getNotificationSettingsCalled: Bool {
        return getNotificationSettingsCallsCount > 0
    }

    var getNotificationSettingsUnderlyingReturnValue: NotificationSettings!
    open var getNotificationSettingsReturnValue: NotificationSettings! {
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
    open var getNotificationSettingsClosure: (() -> NotificationSettings)?

    open override func getNotificationSettings() -> NotificationSettings {
        getNotificationSettingsCallsCount += 1
        if let getNotificationSettingsClosure = getNotificationSettingsClosure {
            return getNotificationSettingsClosure()
        } else {
            return getNotificationSettingsReturnValue
        }
    }

    //MARK: - getProfile

    open var getProfileUserIdThrowableError: Error?
    var getProfileUserIdUnderlyingCallsCount = 0
    open var getProfileUserIdCallsCount: Int {
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
    open var getProfileUserIdCalled: Bool {
        return getProfileUserIdCallsCount > 0
    }
    open var getProfileUserIdReceivedUserId: String?
    open var getProfileUserIdReceivedInvocations: [String] = []

    var getProfileUserIdUnderlyingReturnValue: UserProfile!
    open var getProfileUserIdReturnValue: UserProfile! {
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
    open var getProfileUserIdClosure: ((String) async throws -> UserProfile)?

    open override func getProfile(userId: String) async throws -> UserProfile {
        if let error = getProfileUserIdThrowableError {
            throw error
        }
        getProfileUserIdCallsCount += 1
        getProfileUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.getProfileUserIdReceivedInvocations.append(userId)
        }
        if let getProfileUserIdClosure = getProfileUserIdClosure {
            return try await getProfileUserIdClosure(userId)
        } else {
            return getProfileUserIdReturnValue
        }
    }

    //MARK: - getRecentlyVisitedRooms

    open var getRecentlyVisitedRoomsThrowableError: Error?
    var getRecentlyVisitedRoomsUnderlyingCallsCount = 0
    open var getRecentlyVisitedRoomsCallsCount: Int {
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
    open var getRecentlyVisitedRoomsCalled: Bool {
        return getRecentlyVisitedRoomsCallsCount > 0
    }

    var getRecentlyVisitedRoomsUnderlyingReturnValue: [String]!
    open var getRecentlyVisitedRoomsReturnValue: [String]! {
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
    open var getRecentlyVisitedRoomsClosure: (() async throws -> [String])?

    open override func getRecentlyVisitedRooms() async throws -> [String] {
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

    //MARK: - getRoomPreviewFromRoomAlias

    open var getRoomPreviewFromRoomAliasRoomAliasThrowableError: Error?
    var getRoomPreviewFromRoomAliasRoomAliasUnderlyingCallsCount = 0
    open var getRoomPreviewFromRoomAliasRoomAliasCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getRoomPreviewFromRoomAliasRoomAliasUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomPreviewFromRoomAliasRoomAliasUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomPreviewFromRoomAliasRoomAliasUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomPreviewFromRoomAliasRoomAliasUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var getRoomPreviewFromRoomAliasRoomAliasCalled: Bool {
        return getRoomPreviewFromRoomAliasRoomAliasCallsCount > 0
    }
    open var getRoomPreviewFromRoomAliasRoomAliasReceivedRoomAlias: String?
    open var getRoomPreviewFromRoomAliasRoomAliasReceivedInvocations: [String] = []

    var getRoomPreviewFromRoomAliasRoomAliasUnderlyingReturnValue: RoomPreview!
    open var getRoomPreviewFromRoomAliasRoomAliasReturnValue: RoomPreview! {
        get {
            if Thread.isMainThread {
                return getRoomPreviewFromRoomAliasRoomAliasUnderlyingReturnValue
            } else {
                var returnValue: RoomPreview? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomPreviewFromRoomAliasRoomAliasUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomPreviewFromRoomAliasRoomAliasUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomPreviewFromRoomAliasRoomAliasUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var getRoomPreviewFromRoomAliasRoomAliasClosure: ((String) async throws -> RoomPreview)?

    open override func getRoomPreviewFromRoomAlias(roomAlias: String) async throws -> RoomPreview {
        if let error = getRoomPreviewFromRoomAliasRoomAliasThrowableError {
            throw error
        }
        getRoomPreviewFromRoomAliasRoomAliasCallsCount += 1
        getRoomPreviewFromRoomAliasRoomAliasReceivedRoomAlias = roomAlias
        DispatchQueue.main.async {
            self.getRoomPreviewFromRoomAliasRoomAliasReceivedInvocations.append(roomAlias)
        }
        if let getRoomPreviewFromRoomAliasRoomAliasClosure = getRoomPreviewFromRoomAliasRoomAliasClosure {
            return try await getRoomPreviewFromRoomAliasRoomAliasClosure(roomAlias)
        } else {
            return getRoomPreviewFromRoomAliasRoomAliasReturnValue
        }
    }

    //MARK: - getRoomPreviewFromRoomId

    open var getRoomPreviewFromRoomIdRoomIdViaServersThrowableError: Error?
    var getRoomPreviewFromRoomIdRoomIdViaServersUnderlyingCallsCount = 0
    open var getRoomPreviewFromRoomIdRoomIdViaServersCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getRoomPreviewFromRoomIdRoomIdViaServersUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomPreviewFromRoomIdRoomIdViaServersUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomPreviewFromRoomIdRoomIdViaServersUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomPreviewFromRoomIdRoomIdViaServersUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var getRoomPreviewFromRoomIdRoomIdViaServersCalled: Bool {
        return getRoomPreviewFromRoomIdRoomIdViaServersCallsCount > 0
    }
    open var getRoomPreviewFromRoomIdRoomIdViaServersReceivedArguments: (roomId: String, viaServers: [String])?
    open var getRoomPreviewFromRoomIdRoomIdViaServersReceivedInvocations: [(roomId: String, viaServers: [String])] = []

    var getRoomPreviewFromRoomIdRoomIdViaServersUnderlyingReturnValue: RoomPreview!
    open var getRoomPreviewFromRoomIdRoomIdViaServersReturnValue: RoomPreview! {
        get {
            if Thread.isMainThread {
                return getRoomPreviewFromRoomIdRoomIdViaServersUnderlyingReturnValue
            } else {
                var returnValue: RoomPreview? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomPreviewFromRoomIdRoomIdViaServersUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomPreviewFromRoomIdRoomIdViaServersUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomPreviewFromRoomIdRoomIdViaServersUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var getRoomPreviewFromRoomIdRoomIdViaServersClosure: ((String, [String]) async throws -> RoomPreview)?

    open override func getRoomPreviewFromRoomId(roomId: String, viaServers: [String]) async throws -> RoomPreview {
        if let error = getRoomPreviewFromRoomIdRoomIdViaServersThrowableError {
            throw error
        }
        getRoomPreviewFromRoomIdRoomIdViaServersCallsCount += 1
        getRoomPreviewFromRoomIdRoomIdViaServersReceivedArguments = (roomId: roomId, viaServers: viaServers)
        DispatchQueue.main.async {
            self.getRoomPreviewFromRoomIdRoomIdViaServersReceivedInvocations.append((roomId: roomId, viaServers: viaServers))
        }
        if let getRoomPreviewFromRoomIdRoomIdViaServersClosure = getRoomPreviewFromRoomIdRoomIdViaServersClosure {
            return try await getRoomPreviewFromRoomIdRoomIdViaServersClosure(roomId, viaServers)
        } else {
            return getRoomPreviewFromRoomIdRoomIdViaServersReturnValue
        }
    }

    //MARK: - getSessionVerificationController

    open var getSessionVerificationControllerThrowableError: Error?
    var getSessionVerificationControllerUnderlyingCallsCount = 0
    open var getSessionVerificationControllerCallsCount: Int {
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
    open var getSessionVerificationControllerCalled: Bool {
        return getSessionVerificationControllerCallsCount > 0
    }

    var getSessionVerificationControllerUnderlyingReturnValue: SessionVerificationController!
    open var getSessionVerificationControllerReturnValue: SessionVerificationController! {
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
    open var getSessionVerificationControllerClosure: (() async throws -> SessionVerificationController)?

    open override func getSessionVerificationController() async throws -> SessionVerificationController {
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

    //MARK: - getUrl

    open var getUrlUrlThrowableError: Error?
    var getUrlUrlUnderlyingCallsCount = 0
    open var getUrlUrlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getUrlUrlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getUrlUrlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getUrlUrlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getUrlUrlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var getUrlUrlCalled: Bool {
        return getUrlUrlCallsCount > 0
    }
    open var getUrlUrlReceivedUrl: String?
    open var getUrlUrlReceivedInvocations: [String] = []

    var getUrlUrlUnderlyingReturnValue: String!
    open var getUrlUrlReturnValue: String! {
        get {
            if Thread.isMainThread {
                return getUrlUrlUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = getUrlUrlUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getUrlUrlUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getUrlUrlUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var getUrlUrlClosure: ((String) async throws -> String)?

    open override func getUrl(url: String) async throws -> String {
        if let error = getUrlUrlThrowableError {
            throw error
        }
        getUrlUrlCallsCount += 1
        getUrlUrlReceivedUrl = url
        DispatchQueue.main.async {
            self.getUrlUrlReceivedInvocations.append(url)
        }
        if let getUrlUrlClosure = getUrlUrlClosure {
            return try await getUrlUrlClosure(url)
        } else {
            return getUrlUrlReturnValue
        }
    }

    //MARK: - homeserver

    var homeserverUnderlyingCallsCount = 0
    open var homeserverCallsCount: Int {
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
    open var homeserverCalled: Bool {
        return homeserverCallsCount > 0
    }

    var homeserverUnderlyingReturnValue: String!
    open var homeserverReturnValue: String! {
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
    open var homeserverClosure: (() -> String)?

    open override func homeserver() -> String {
        homeserverCallsCount += 1
        if let homeserverClosure = homeserverClosure {
            return homeserverClosure()
        } else {
            return homeserverReturnValue
        }
    }

    //MARK: - homeserverLoginDetails

    var homeserverLoginDetailsUnderlyingCallsCount = 0
    open var homeserverLoginDetailsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return homeserverLoginDetailsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = homeserverLoginDetailsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                homeserverLoginDetailsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    homeserverLoginDetailsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var homeserverLoginDetailsCalled: Bool {
        return homeserverLoginDetailsCallsCount > 0
    }

    var homeserverLoginDetailsUnderlyingReturnValue: HomeserverLoginDetails!
    open var homeserverLoginDetailsReturnValue: HomeserverLoginDetails! {
        get {
            if Thread.isMainThread {
                return homeserverLoginDetailsUnderlyingReturnValue
            } else {
                var returnValue: HomeserverLoginDetails? = nil
                DispatchQueue.main.sync {
                    returnValue = homeserverLoginDetailsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                homeserverLoginDetailsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    homeserverLoginDetailsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var homeserverLoginDetailsClosure: (() async -> HomeserverLoginDetails)?

    open override func homeserverLoginDetails() async -> HomeserverLoginDetails {
        homeserverLoginDetailsCallsCount += 1
        if let homeserverLoginDetailsClosure = homeserverLoginDetailsClosure {
            return await homeserverLoginDetailsClosure()
        } else {
            return homeserverLoginDetailsReturnValue
        }
    }

    //MARK: - ignoreUser

    open var ignoreUserUserIdThrowableError: Error?
    var ignoreUserUserIdUnderlyingCallsCount = 0
    open var ignoreUserUserIdCallsCount: Int {
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
    open var ignoreUserUserIdCalled: Bool {
        return ignoreUserUserIdCallsCount > 0
    }
    open var ignoreUserUserIdReceivedUserId: String?
    open var ignoreUserUserIdReceivedInvocations: [String] = []
    open var ignoreUserUserIdClosure: ((String) async throws -> Void)?

    open override func ignoreUser(userId: String) async throws {
        if let error = ignoreUserUserIdThrowableError {
            throw error
        }
        ignoreUserUserIdCallsCount += 1
        ignoreUserUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.ignoreUserUserIdReceivedInvocations.append(userId)
        }
        try await ignoreUserUserIdClosure?(userId)
    }

    //MARK: - ignoredUsers

    open var ignoredUsersThrowableError: Error?
    var ignoredUsersUnderlyingCallsCount = 0
    open var ignoredUsersCallsCount: Int {
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
    open var ignoredUsersCalled: Bool {
        return ignoredUsersCallsCount > 0
    }

    var ignoredUsersUnderlyingReturnValue: [String]!
    open var ignoredUsersReturnValue: [String]! {
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
    open var ignoredUsersClosure: (() async throws -> [String])?

    open override func ignoredUsers() async throws -> [String] {
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

    open var joinRoomByIdRoomIdThrowableError: Error?
    var joinRoomByIdRoomIdUnderlyingCallsCount = 0
    open var joinRoomByIdRoomIdCallsCount: Int {
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
    open var joinRoomByIdRoomIdCalled: Bool {
        return joinRoomByIdRoomIdCallsCount > 0
    }
    open var joinRoomByIdRoomIdReceivedRoomId: String?
    open var joinRoomByIdRoomIdReceivedInvocations: [String] = []

    var joinRoomByIdRoomIdUnderlyingReturnValue: Room!
    open var joinRoomByIdRoomIdReturnValue: Room! {
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
    open var joinRoomByIdRoomIdClosure: ((String) async throws -> Room)?

    open override func joinRoomById(roomId: String) async throws -> Room {
        if let error = joinRoomByIdRoomIdThrowableError {
            throw error
        }
        joinRoomByIdRoomIdCallsCount += 1
        joinRoomByIdRoomIdReceivedRoomId = roomId
        DispatchQueue.main.async {
            self.joinRoomByIdRoomIdReceivedInvocations.append(roomId)
        }
        if let joinRoomByIdRoomIdClosure = joinRoomByIdRoomIdClosure {
            return try await joinRoomByIdRoomIdClosure(roomId)
        } else {
            return joinRoomByIdRoomIdReturnValue
        }
    }

    //MARK: - joinRoomByIdOrAlias

    open var joinRoomByIdOrAliasRoomIdOrAliasServerNamesThrowableError: Error?
    var joinRoomByIdOrAliasRoomIdOrAliasServerNamesUnderlyingCallsCount = 0
    open var joinRoomByIdOrAliasRoomIdOrAliasServerNamesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return joinRoomByIdOrAliasRoomIdOrAliasServerNamesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = joinRoomByIdOrAliasRoomIdOrAliasServerNamesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinRoomByIdOrAliasRoomIdOrAliasServerNamesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    joinRoomByIdOrAliasRoomIdOrAliasServerNamesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var joinRoomByIdOrAliasRoomIdOrAliasServerNamesCalled: Bool {
        return joinRoomByIdOrAliasRoomIdOrAliasServerNamesCallsCount > 0
    }
    open var joinRoomByIdOrAliasRoomIdOrAliasServerNamesReceivedArguments: (roomIdOrAlias: String, serverNames: [String])?
    open var joinRoomByIdOrAliasRoomIdOrAliasServerNamesReceivedInvocations: [(roomIdOrAlias: String, serverNames: [String])] = []

    var joinRoomByIdOrAliasRoomIdOrAliasServerNamesUnderlyingReturnValue: Room!
    open var joinRoomByIdOrAliasRoomIdOrAliasServerNamesReturnValue: Room! {
        get {
            if Thread.isMainThread {
                return joinRoomByIdOrAliasRoomIdOrAliasServerNamesUnderlyingReturnValue
            } else {
                var returnValue: Room? = nil
                DispatchQueue.main.sync {
                    returnValue = joinRoomByIdOrAliasRoomIdOrAliasServerNamesUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinRoomByIdOrAliasRoomIdOrAliasServerNamesUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    joinRoomByIdOrAliasRoomIdOrAliasServerNamesUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var joinRoomByIdOrAliasRoomIdOrAliasServerNamesClosure: ((String, [String]) async throws -> Room)?

    open override func joinRoomByIdOrAlias(roomIdOrAlias: String, serverNames: [String]) async throws -> Room {
        if let error = joinRoomByIdOrAliasRoomIdOrAliasServerNamesThrowableError {
            throw error
        }
        joinRoomByIdOrAliasRoomIdOrAliasServerNamesCallsCount += 1
        joinRoomByIdOrAliasRoomIdOrAliasServerNamesReceivedArguments = (roomIdOrAlias: roomIdOrAlias, serverNames: serverNames)
        DispatchQueue.main.async {
            self.joinRoomByIdOrAliasRoomIdOrAliasServerNamesReceivedInvocations.append((roomIdOrAlias: roomIdOrAlias, serverNames: serverNames))
        }
        if let joinRoomByIdOrAliasRoomIdOrAliasServerNamesClosure = joinRoomByIdOrAliasRoomIdOrAliasServerNamesClosure {
            return try await joinRoomByIdOrAliasRoomIdOrAliasServerNamesClosure(roomIdOrAlias, serverNames)
        } else {
            return joinRoomByIdOrAliasRoomIdOrAliasServerNamesReturnValue
        }
    }

    //MARK: - login

    open var loginUsernamePasswordInitialDeviceNameDeviceIdThrowableError: Error?
    var loginUsernamePasswordInitialDeviceNameDeviceIdUnderlyingCallsCount = 0
    open var loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount: Int {
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
    open var loginUsernamePasswordInitialDeviceNameDeviceIdCalled: Bool {
        return loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount > 0
    }
    open var loginUsernamePasswordInitialDeviceNameDeviceIdReceivedArguments: (username: String, password: String, initialDeviceName: String?, deviceId: String?)?
    open var loginUsernamePasswordInitialDeviceNameDeviceIdReceivedInvocations: [(username: String, password: String, initialDeviceName: String?, deviceId: String?)] = []
    open var loginUsernamePasswordInitialDeviceNameDeviceIdClosure: ((String, String, String?, String?) async throws -> Void)?

    open override func login(username: String, password: String, initialDeviceName: String?, deviceId: String?) async throws {
        if let error = loginUsernamePasswordInitialDeviceNameDeviceIdThrowableError {
            throw error
        }
        loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount += 1
        loginUsernamePasswordInitialDeviceNameDeviceIdReceivedArguments = (username: username, password: password, initialDeviceName: initialDeviceName, deviceId: deviceId)
        DispatchQueue.main.async {
            self.loginUsernamePasswordInitialDeviceNameDeviceIdReceivedInvocations.append((username: username, password: password, initialDeviceName: initialDeviceName, deviceId: deviceId))
        }
        try await loginUsernamePasswordInitialDeviceNameDeviceIdClosure?(username, password, initialDeviceName, deviceId)
    }

    //MARK: - loginWithEmail

    open var loginWithEmailEmailPasswordInitialDeviceNameDeviceIdThrowableError: Error?
    var loginWithEmailEmailPasswordInitialDeviceNameDeviceIdUnderlyingCallsCount = 0
    open var loginWithEmailEmailPasswordInitialDeviceNameDeviceIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loginWithEmailEmailPasswordInitialDeviceNameDeviceIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loginWithEmailEmailPasswordInitialDeviceNameDeviceIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loginWithEmailEmailPasswordInitialDeviceNameDeviceIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loginWithEmailEmailPasswordInitialDeviceNameDeviceIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var loginWithEmailEmailPasswordInitialDeviceNameDeviceIdCalled: Bool {
        return loginWithEmailEmailPasswordInitialDeviceNameDeviceIdCallsCount > 0
    }
    open var loginWithEmailEmailPasswordInitialDeviceNameDeviceIdReceivedArguments: (email: String, password: String, initialDeviceName: String?, deviceId: String?)?
    open var loginWithEmailEmailPasswordInitialDeviceNameDeviceIdReceivedInvocations: [(email: String, password: String, initialDeviceName: String?, deviceId: String?)] = []
    open var loginWithEmailEmailPasswordInitialDeviceNameDeviceIdClosure: ((String, String, String?, String?) async throws -> Void)?

    open override func loginWithEmail(email: String, password: String, initialDeviceName: String?, deviceId: String?) async throws {
        if let error = loginWithEmailEmailPasswordInitialDeviceNameDeviceIdThrowableError {
            throw error
        }
        loginWithEmailEmailPasswordInitialDeviceNameDeviceIdCallsCount += 1
        loginWithEmailEmailPasswordInitialDeviceNameDeviceIdReceivedArguments = (email: email, password: password, initialDeviceName: initialDeviceName, deviceId: deviceId)
        DispatchQueue.main.async {
            self.loginWithEmailEmailPasswordInitialDeviceNameDeviceIdReceivedInvocations.append((email: email, password: password, initialDeviceName: initialDeviceName, deviceId: deviceId))
        }
        try await loginWithEmailEmailPasswordInitialDeviceNameDeviceIdClosure?(email, password, initialDeviceName, deviceId)
    }

    //MARK: - loginWithOidcCallback

    open var loginWithOidcCallbackAuthorizationDataCallbackUrlThrowableError: Error?
    var loginWithOidcCallbackAuthorizationDataCallbackUrlUnderlyingCallsCount = 0
    open var loginWithOidcCallbackAuthorizationDataCallbackUrlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loginWithOidcCallbackAuthorizationDataCallbackUrlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loginWithOidcCallbackAuthorizationDataCallbackUrlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loginWithOidcCallbackAuthorizationDataCallbackUrlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loginWithOidcCallbackAuthorizationDataCallbackUrlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var loginWithOidcCallbackAuthorizationDataCallbackUrlCalled: Bool {
        return loginWithOidcCallbackAuthorizationDataCallbackUrlCallsCount > 0
    }
    open var loginWithOidcCallbackAuthorizationDataCallbackUrlReceivedArguments: (authorizationData: OidcAuthorizationData, callbackUrl: String)?
    open var loginWithOidcCallbackAuthorizationDataCallbackUrlReceivedInvocations: [(authorizationData: OidcAuthorizationData, callbackUrl: String)] = []
    open var loginWithOidcCallbackAuthorizationDataCallbackUrlClosure: ((OidcAuthorizationData, String) async throws -> Void)?

    open override func loginWithOidcCallback(authorizationData: OidcAuthorizationData, callbackUrl: String) async throws {
        if let error = loginWithOidcCallbackAuthorizationDataCallbackUrlThrowableError {
            throw error
        }
        loginWithOidcCallbackAuthorizationDataCallbackUrlCallsCount += 1
        loginWithOidcCallbackAuthorizationDataCallbackUrlReceivedArguments = (authorizationData: authorizationData, callbackUrl: callbackUrl)
        DispatchQueue.main.async {
            self.loginWithOidcCallbackAuthorizationDataCallbackUrlReceivedInvocations.append((authorizationData: authorizationData, callbackUrl: callbackUrl))
        }
        try await loginWithOidcCallbackAuthorizationDataCallbackUrlClosure?(authorizationData, callbackUrl)
    }

    //MARK: - logout

    open var logoutThrowableError: Error?
    var logoutUnderlyingCallsCount = 0
    open var logoutCallsCount: Int {
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
    open var logoutCalled: Bool {
        return logoutCallsCount > 0
    }

    var logoutUnderlyingReturnValue: String?
    open var logoutReturnValue: String? {
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
    open var logoutClosure: (() async throws -> String?)?

    open override func logout() async throws -> String? {
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

    open var notificationClientProcessSetupThrowableError: Error?
    var notificationClientProcessSetupUnderlyingCallsCount = 0
    open var notificationClientProcessSetupCallsCount: Int {
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
    open var notificationClientProcessSetupCalled: Bool {
        return notificationClientProcessSetupCallsCount > 0
    }
    open var notificationClientProcessSetupReceivedProcessSetup: NotificationProcessSetup?
    open var notificationClientProcessSetupReceivedInvocations: [NotificationProcessSetup] = []

    var notificationClientProcessSetupUnderlyingReturnValue: NotificationClient!
    open var notificationClientProcessSetupReturnValue: NotificationClient! {
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
    open var notificationClientProcessSetupClosure: ((NotificationProcessSetup) async throws -> NotificationClient)?

    open override func notificationClient(processSetup: NotificationProcessSetup) async throws -> NotificationClient {
        if let error = notificationClientProcessSetupThrowableError {
            throw error
        }
        notificationClientProcessSetupCallsCount += 1
        notificationClientProcessSetupReceivedProcessSetup = processSetup
        DispatchQueue.main.async {
            self.notificationClientProcessSetupReceivedInvocations.append(processSetup)
        }
        if let notificationClientProcessSetupClosure = notificationClientProcessSetupClosure {
            return try await notificationClientProcessSetupClosure(processSetup)
        } else {
            return notificationClientProcessSetupReturnValue
        }
    }

    //MARK: - removeAvatar

    open var removeAvatarThrowableError: Error?
    var removeAvatarUnderlyingCallsCount = 0
    open var removeAvatarCallsCount: Int {
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
    open var removeAvatarCalled: Bool {
        return removeAvatarCallsCount > 0
    }
    open var removeAvatarClosure: (() async throws -> Void)?

    open override func removeAvatar() async throws {
        if let error = removeAvatarThrowableError {
            throw error
        }
        removeAvatarCallsCount += 1
        try await removeAvatarClosure?()
    }

    //MARK: - resetServerCapabilities

    open var resetServerCapabilitiesThrowableError: Error?
    var resetServerCapabilitiesUnderlyingCallsCount = 0
    open var resetServerCapabilitiesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resetServerCapabilitiesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resetServerCapabilitiesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetServerCapabilitiesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resetServerCapabilitiesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var resetServerCapabilitiesCalled: Bool {
        return resetServerCapabilitiesCallsCount > 0
    }
    open var resetServerCapabilitiesClosure: (() async throws -> Void)?

    open override func resetServerCapabilities() async throws {
        if let error = resetServerCapabilitiesThrowableError {
            throw error
        }
        resetServerCapabilitiesCallsCount += 1
        try await resetServerCapabilitiesClosure?()
    }

    //MARK: - resolveRoomAlias

    open var resolveRoomAliasRoomAliasThrowableError: Error?
    var resolveRoomAliasRoomAliasUnderlyingCallsCount = 0
    open var resolveRoomAliasRoomAliasCallsCount: Int {
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
    open var resolveRoomAliasRoomAliasCalled: Bool {
        return resolveRoomAliasRoomAliasCallsCount > 0
    }
    open var resolveRoomAliasRoomAliasReceivedRoomAlias: String?
    open var resolveRoomAliasRoomAliasReceivedInvocations: [String] = []

    var resolveRoomAliasRoomAliasUnderlyingReturnValue: ResolvedRoomAlias!
    open var resolveRoomAliasRoomAliasReturnValue: ResolvedRoomAlias! {
        get {
            if Thread.isMainThread {
                return resolveRoomAliasRoomAliasUnderlyingReturnValue
            } else {
                var returnValue: ResolvedRoomAlias? = nil
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
    open var resolveRoomAliasRoomAliasClosure: ((String) async throws -> ResolvedRoomAlias)?

    open override func resolveRoomAlias(roomAlias: String) async throws -> ResolvedRoomAlias {
        if let error = resolveRoomAliasRoomAliasThrowableError {
            throw error
        }
        resolveRoomAliasRoomAliasCallsCount += 1
        resolveRoomAliasRoomAliasReceivedRoomAlias = roomAlias
        DispatchQueue.main.async {
            self.resolveRoomAliasRoomAliasReceivedInvocations.append(roomAlias)
        }
        if let resolveRoomAliasRoomAliasClosure = resolveRoomAliasRoomAliasClosure {
            return try await resolveRoomAliasRoomAliasClosure(roomAlias)
        } else {
            return resolveRoomAliasRoomAliasReturnValue
        }
    }

    //MARK: - restoreSession

    open var restoreSessionSessionThrowableError: Error?
    var restoreSessionSessionUnderlyingCallsCount = 0
    open var restoreSessionSessionCallsCount: Int {
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
    open var restoreSessionSessionCalled: Bool {
        return restoreSessionSessionCallsCount > 0
    }
    open var restoreSessionSessionReceivedSession: Session?
    open var restoreSessionSessionReceivedInvocations: [Session] = []
    open var restoreSessionSessionClosure: ((Session) async throws -> Void)?

    open override func restoreSession(session: Session) async throws {
        if let error = restoreSessionSessionThrowableError {
            throw error
        }
        restoreSessionSessionCallsCount += 1
        restoreSessionSessionReceivedSession = session
        DispatchQueue.main.async {
            self.restoreSessionSessionReceivedInvocations.append(session)
        }
        try await restoreSessionSessionClosure?(session)
    }

    //MARK: - roomDirectorySearch

    var roomDirectorySearchUnderlyingCallsCount = 0
    open var roomDirectorySearchCallsCount: Int {
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
    open var roomDirectorySearchCalled: Bool {
        return roomDirectorySearchCallsCount > 0
    }

    var roomDirectorySearchUnderlyingReturnValue: RoomDirectorySearch!
    open var roomDirectorySearchReturnValue: RoomDirectorySearch! {
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
    open var roomDirectorySearchClosure: (() -> RoomDirectorySearch)?

    open override func roomDirectorySearch() -> RoomDirectorySearch {
        roomDirectorySearchCallsCount += 1
        if let roomDirectorySearchClosure = roomDirectorySearchClosure {
            return roomDirectorySearchClosure()
        } else {
            return roomDirectorySearchReturnValue
        }
    }

    //MARK: - rooms

    var roomsUnderlyingCallsCount = 0
    open var roomsCallsCount: Int {
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
    open var roomsCalled: Bool {
        return roomsCallsCount > 0
    }

    var roomsUnderlyingReturnValue: [Room]!
    open var roomsReturnValue: [Room]! {
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
    open var roomsClosure: (() -> [Room])?

    open override func rooms() -> [Room] {
        roomsCallsCount += 1
        if let roomsClosure = roomsClosure {
            return roomsClosure()
        } else {
            return roomsReturnValue
        }
    }

    //MARK: - searchUsers

    open var searchUsersSearchTermLimitThrowableError: Error?
    var searchUsersSearchTermLimitUnderlyingCallsCount = 0
    open var searchUsersSearchTermLimitCallsCount: Int {
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
    open var searchUsersSearchTermLimitCalled: Bool {
        return searchUsersSearchTermLimitCallsCount > 0
    }
    open var searchUsersSearchTermLimitReceivedArguments: (searchTerm: String, limit: UInt64)?
    open var searchUsersSearchTermLimitReceivedInvocations: [(searchTerm: String, limit: UInt64)] = []

    var searchUsersSearchTermLimitUnderlyingReturnValue: SearchUsersResults!
    open var searchUsersSearchTermLimitReturnValue: SearchUsersResults! {
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
    open var searchUsersSearchTermLimitClosure: ((String, UInt64) async throws -> SearchUsersResults)?

    open override func searchUsers(searchTerm: String, limit: UInt64) async throws -> SearchUsersResults {
        if let error = searchUsersSearchTermLimitThrowableError {
            throw error
        }
        searchUsersSearchTermLimitCallsCount += 1
        searchUsersSearchTermLimitReceivedArguments = (searchTerm: searchTerm, limit: limit)
        DispatchQueue.main.async {
            self.searchUsersSearchTermLimitReceivedInvocations.append((searchTerm: searchTerm, limit: limit))
        }
        if let searchUsersSearchTermLimitClosure = searchUsersSearchTermLimitClosure {
            return try await searchUsersSearchTermLimitClosure(searchTerm, limit)
        } else {
            return searchUsersSearchTermLimitReturnValue
        }
    }

    //MARK: - server

    var serverUnderlyingCallsCount = 0
    open var serverCallsCount: Int {
        get {
            if Thread.isMainThread {
                return serverUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = serverUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                serverUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    serverUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var serverCalled: Bool {
        return serverCallsCount > 0
    }

    var serverUnderlyingReturnValue: String?
    open var serverReturnValue: String? {
        get {
            if Thread.isMainThread {
                return serverUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = serverUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                serverUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    serverUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var serverClosure: (() -> String?)?

    open override func server() -> String? {
        serverCallsCount += 1
        if let serverClosure = serverClosure {
            return serverClosure()
        } else {
            return serverReturnValue
        }
    }

    //MARK: - session

    open var sessionThrowableError: Error?
    var sessionUnderlyingCallsCount = 0
    open var sessionCallsCount: Int {
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
    open var sessionCalled: Bool {
        return sessionCallsCount > 0
    }

    var sessionUnderlyingReturnValue: Session!
    open var sessionReturnValue: Session! {
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
    open var sessionClosure: (() throws -> Session)?

    open override func session() throws -> Session {
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

    open var setAccountDataEventTypeContentThrowableError: Error?
    var setAccountDataEventTypeContentUnderlyingCallsCount = 0
    open var setAccountDataEventTypeContentCallsCount: Int {
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
    open var setAccountDataEventTypeContentCalled: Bool {
        return setAccountDataEventTypeContentCallsCount > 0
    }
    open var setAccountDataEventTypeContentReceivedArguments: (eventType: String, content: String)?
    open var setAccountDataEventTypeContentReceivedInvocations: [(eventType: String, content: String)] = []
    open var setAccountDataEventTypeContentClosure: ((String, String) async throws -> Void)?

    open override func setAccountData(eventType: String, content: String) async throws {
        if let error = setAccountDataEventTypeContentThrowableError {
            throw error
        }
        setAccountDataEventTypeContentCallsCount += 1
        setAccountDataEventTypeContentReceivedArguments = (eventType: eventType, content: content)
        DispatchQueue.main.async {
            self.setAccountDataEventTypeContentReceivedInvocations.append((eventType: eventType, content: content))
        }
        try await setAccountDataEventTypeContentClosure?(eventType, content)
    }

    //MARK: - setDelegate

    var setDelegateDelegateUnderlyingCallsCount = 0
    open var setDelegateDelegateCallsCount: Int {
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
    open var setDelegateDelegateCalled: Bool {
        return setDelegateDelegateCallsCount > 0
    }
    open var setDelegateDelegateReceivedDelegate: ClientDelegate?
    open var setDelegateDelegateReceivedInvocations: [ClientDelegate?] = []

    var setDelegateDelegateUnderlyingReturnValue: TaskHandle?
    open var setDelegateDelegateReturnValue: TaskHandle? {
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
    open var setDelegateDelegateClosure: ((ClientDelegate?) -> TaskHandle?)?

    open override func setDelegate(delegate: ClientDelegate?) -> TaskHandle? {
        setDelegateDelegateCallsCount += 1
        setDelegateDelegateReceivedDelegate = delegate
        DispatchQueue.main.async {
            self.setDelegateDelegateReceivedInvocations.append(delegate)
        }
        if let setDelegateDelegateClosure = setDelegateDelegateClosure {
            return setDelegateDelegateClosure(delegate)
        } else {
            return setDelegateDelegateReturnValue
        }
    }

    //MARK: - setDisplayName

    open var setDisplayNameNameThrowableError: Error?
    var setDisplayNameNameUnderlyingCallsCount = 0
    open var setDisplayNameNameCallsCount: Int {
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
    open var setDisplayNameNameCalled: Bool {
        return setDisplayNameNameCallsCount > 0
    }
    open var setDisplayNameNameReceivedName: String?
    open var setDisplayNameNameReceivedInvocations: [String] = []
    open var setDisplayNameNameClosure: ((String) async throws -> Void)?

    open override func setDisplayName(name: String) async throws {
        if let error = setDisplayNameNameThrowableError {
            throw error
        }
        setDisplayNameNameCallsCount += 1
        setDisplayNameNameReceivedName = name
        DispatchQueue.main.async {
            self.setDisplayNameNameReceivedInvocations.append(name)
        }
        try await setDisplayNameNameClosure?(name)
    }

    //MARK: - setPusher

    open var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangThrowableError: Error?
    var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangUnderlyingCallsCount = 0
    open var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCallsCount: Int {
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
    open var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCalled: Bool {
        return setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCallsCount > 0
    }
    open var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedArguments: (identifiers: PusherIdentifiers, kind: PusherKind, appDisplayName: String, deviceDisplayName: String, profileTag: String?, lang: String)?
    open var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedInvocations: [(identifiers: PusherIdentifiers, kind: PusherKind, appDisplayName: String, deviceDisplayName: String, profileTag: String?, lang: String)] = []
    open var setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangClosure: ((PusherIdentifiers, PusherKind, String, String, String?, String) async throws -> Void)?

    open override func setPusher(identifiers: PusherIdentifiers, kind: PusherKind, appDisplayName: String, deviceDisplayName: String, profileTag: String?, lang: String) async throws {
        if let error = setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangThrowableError {
            throw error
        }
        setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangCallsCount += 1
        setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedArguments = (identifiers: identifiers, kind: kind, appDisplayName: appDisplayName, deviceDisplayName: deviceDisplayName, profileTag: profileTag, lang: lang)
        DispatchQueue.main.async {
            self.setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangReceivedInvocations.append((identifiers: identifiers, kind: kind, appDisplayName: appDisplayName, deviceDisplayName: deviceDisplayName, profileTag: profileTag, lang: lang))
        }
        try await setPusherIdentifiersKindAppDisplayNameDeviceDisplayNameProfileTagLangClosure?(identifiers, kind, appDisplayName, deviceDisplayName, profileTag, lang)
    }

    //MARK: - slidingSyncVersion

    var slidingSyncVersionUnderlyingCallsCount = 0
    open var slidingSyncVersionCallsCount: Int {
        get {
            if Thread.isMainThread {
                return slidingSyncVersionUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = slidingSyncVersionUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                slidingSyncVersionUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    slidingSyncVersionUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var slidingSyncVersionCalled: Bool {
        return slidingSyncVersionCallsCount > 0
    }

    var slidingSyncVersionUnderlyingReturnValue: SlidingSyncVersion!
    open var slidingSyncVersionReturnValue: SlidingSyncVersion! {
        get {
            if Thread.isMainThread {
                return slidingSyncVersionUnderlyingReturnValue
            } else {
                var returnValue: SlidingSyncVersion? = nil
                DispatchQueue.main.sync {
                    returnValue = slidingSyncVersionUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                slidingSyncVersionUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    slidingSyncVersionUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var slidingSyncVersionClosure: (() -> SlidingSyncVersion)?

    open override func slidingSyncVersion() -> SlidingSyncVersion {
        slidingSyncVersionCallsCount += 1
        if let slidingSyncVersionClosure = slidingSyncVersionClosure {
            return slidingSyncVersionClosure()
        } else {
            return slidingSyncVersionReturnValue
        }
    }

    //MARK: - startSsoLogin

    open var startSsoLoginRedirectUrlIdpIdThrowableError: Error?
    var startSsoLoginRedirectUrlIdpIdUnderlyingCallsCount = 0
    open var startSsoLoginRedirectUrlIdpIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return startSsoLoginRedirectUrlIdpIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = startSsoLoginRedirectUrlIdpIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startSsoLoginRedirectUrlIdpIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    startSsoLoginRedirectUrlIdpIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var startSsoLoginRedirectUrlIdpIdCalled: Bool {
        return startSsoLoginRedirectUrlIdpIdCallsCount > 0
    }
    open var startSsoLoginRedirectUrlIdpIdReceivedArguments: (redirectUrl: String, idpId: String?)?
    open var startSsoLoginRedirectUrlIdpIdReceivedInvocations: [(redirectUrl: String, idpId: String?)] = []

    var startSsoLoginRedirectUrlIdpIdUnderlyingReturnValue: SsoHandler!
    open var startSsoLoginRedirectUrlIdpIdReturnValue: SsoHandler! {
        get {
            if Thread.isMainThread {
                return startSsoLoginRedirectUrlIdpIdUnderlyingReturnValue
            } else {
                var returnValue: SsoHandler? = nil
                DispatchQueue.main.sync {
                    returnValue = startSsoLoginRedirectUrlIdpIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                startSsoLoginRedirectUrlIdpIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    startSsoLoginRedirectUrlIdpIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var startSsoLoginRedirectUrlIdpIdClosure: ((String, String?) async throws -> SsoHandler)?

    open override func startSsoLogin(redirectUrl: String, idpId: String?) async throws -> SsoHandler {
        if let error = startSsoLoginRedirectUrlIdpIdThrowableError {
            throw error
        }
        startSsoLoginRedirectUrlIdpIdCallsCount += 1
        startSsoLoginRedirectUrlIdpIdReceivedArguments = (redirectUrl: redirectUrl, idpId: idpId)
        DispatchQueue.main.async {
            self.startSsoLoginRedirectUrlIdpIdReceivedInvocations.append((redirectUrl: redirectUrl, idpId: idpId))
        }
        if let startSsoLoginRedirectUrlIdpIdClosure = startSsoLoginRedirectUrlIdpIdClosure {
            return try await startSsoLoginRedirectUrlIdpIdClosure(redirectUrl, idpId)
        } else {
            return startSsoLoginRedirectUrlIdpIdReturnValue
        }
    }

    //MARK: - subscribeToIgnoredUsers

    var subscribeToIgnoredUsersListenerUnderlyingCallsCount = 0
    open var subscribeToIgnoredUsersListenerCallsCount: Int {
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
    open var subscribeToIgnoredUsersListenerCalled: Bool {
        return subscribeToIgnoredUsersListenerCallsCount > 0
    }
    open var subscribeToIgnoredUsersListenerReceivedListener: IgnoredUsersListener?
    open var subscribeToIgnoredUsersListenerReceivedInvocations: [IgnoredUsersListener] = []

    var subscribeToIgnoredUsersListenerUnderlyingReturnValue: TaskHandle!
    open var subscribeToIgnoredUsersListenerReturnValue: TaskHandle! {
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
    open var subscribeToIgnoredUsersListenerClosure: ((IgnoredUsersListener) -> TaskHandle)?

    open override func subscribeToIgnoredUsers(listener: IgnoredUsersListener) -> TaskHandle {
        subscribeToIgnoredUsersListenerCallsCount += 1
        subscribeToIgnoredUsersListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.subscribeToIgnoredUsersListenerReceivedInvocations.append(listener)
        }
        if let subscribeToIgnoredUsersListenerClosure = subscribeToIgnoredUsersListenerClosure {
            return subscribeToIgnoredUsersListenerClosure(listener)
        } else {
            return subscribeToIgnoredUsersListenerReturnValue
        }
    }

    //MARK: - subscribeToSendQueueStatus

    var subscribeToSendQueueStatusListenerUnderlyingCallsCount = 0
    open var subscribeToSendQueueStatusListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return subscribeToSendQueueStatusListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToSendQueueStatusListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToSendQueueStatusListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToSendQueueStatusListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var subscribeToSendQueueStatusListenerCalled: Bool {
        return subscribeToSendQueueStatusListenerCallsCount > 0
    }
    open var subscribeToSendQueueStatusListenerReceivedListener: SendQueueRoomErrorListener?
    open var subscribeToSendQueueStatusListenerReceivedInvocations: [SendQueueRoomErrorListener] = []

    var subscribeToSendQueueStatusListenerUnderlyingReturnValue: TaskHandle!
    open var subscribeToSendQueueStatusListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return subscribeToSendQueueStatusListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToSendQueueStatusListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToSendQueueStatusListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToSendQueueStatusListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var subscribeToSendQueueStatusListenerClosure: ((SendQueueRoomErrorListener) -> TaskHandle)?

    open override func subscribeToSendQueueStatus(listener: SendQueueRoomErrorListener) -> TaskHandle {
        subscribeToSendQueueStatusListenerCallsCount += 1
        subscribeToSendQueueStatusListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.subscribeToSendQueueStatusListenerReceivedInvocations.append(listener)
        }
        if let subscribeToSendQueueStatusListenerClosure = subscribeToSendQueueStatusListenerClosure {
            return subscribeToSendQueueStatusListenerClosure(listener)
        } else {
            return subscribeToSendQueueStatusListenerReturnValue
        }
    }

    //MARK: - syncService

    var syncServiceUnderlyingCallsCount = 0
    open var syncServiceCallsCount: Int {
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
    open var syncServiceCalled: Bool {
        return syncServiceCallsCount > 0
    }

    var syncServiceUnderlyingReturnValue: SyncServiceBuilder!
    open var syncServiceReturnValue: SyncServiceBuilder! {
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
    open var syncServiceClosure: (() -> SyncServiceBuilder)?

    open override func syncService() -> SyncServiceBuilder {
        syncServiceCallsCount += 1
        if let syncServiceClosure = syncServiceClosure {
            return syncServiceClosure()
        } else {
            return syncServiceReturnValue
        }
    }

    //MARK: - trackRecentlyVisitedRoom

    open var trackRecentlyVisitedRoomRoomThrowableError: Error?
    var trackRecentlyVisitedRoomRoomUnderlyingCallsCount = 0
    open var trackRecentlyVisitedRoomRoomCallsCount: Int {
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
    open var trackRecentlyVisitedRoomRoomCalled: Bool {
        return trackRecentlyVisitedRoomRoomCallsCount > 0
    }
    open var trackRecentlyVisitedRoomRoomReceivedRoom: String?
    open var trackRecentlyVisitedRoomRoomReceivedInvocations: [String] = []
    open var trackRecentlyVisitedRoomRoomClosure: ((String) async throws -> Void)?

    open override func trackRecentlyVisitedRoom(room: String) async throws {
        if let error = trackRecentlyVisitedRoomRoomThrowableError {
            throw error
        }
        trackRecentlyVisitedRoomRoomCallsCount += 1
        trackRecentlyVisitedRoomRoomReceivedRoom = room
        DispatchQueue.main.async {
            self.trackRecentlyVisitedRoomRoomReceivedInvocations.append(room)
        }
        try await trackRecentlyVisitedRoomRoomClosure?(room)
    }

    //MARK: - unignoreUser

    open var unignoreUserUserIdThrowableError: Error?
    var unignoreUserUserIdUnderlyingCallsCount = 0
    open var unignoreUserUserIdCallsCount: Int {
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
    open var unignoreUserUserIdCalled: Bool {
        return unignoreUserUserIdCallsCount > 0
    }
    open var unignoreUserUserIdReceivedUserId: String?
    open var unignoreUserUserIdReceivedInvocations: [String] = []
    open var unignoreUserUserIdClosure: ((String) async throws -> Void)?

    open override func unignoreUser(userId: String) async throws {
        if let error = unignoreUserUserIdThrowableError {
            throw error
        }
        unignoreUserUserIdCallsCount += 1
        unignoreUserUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.unignoreUserUserIdReceivedInvocations.append(userId)
        }
        try await unignoreUserUserIdClosure?(userId)
    }

    //MARK: - uploadAvatar

    open var uploadAvatarMimeTypeDataThrowableError: Error?
    var uploadAvatarMimeTypeDataUnderlyingCallsCount = 0
    open var uploadAvatarMimeTypeDataCallsCount: Int {
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
    open var uploadAvatarMimeTypeDataCalled: Bool {
        return uploadAvatarMimeTypeDataCallsCount > 0
    }
    open var uploadAvatarMimeTypeDataReceivedArguments: (mimeType: String, data: Data)?
    open var uploadAvatarMimeTypeDataReceivedInvocations: [(mimeType: String, data: Data)] = []
    open var uploadAvatarMimeTypeDataClosure: ((String, Data) async throws -> Void)?

    open override func uploadAvatar(mimeType: String, data: Data) async throws {
        if let error = uploadAvatarMimeTypeDataThrowableError {
            throw error
        }
        uploadAvatarMimeTypeDataCallsCount += 1
        uploadAvatarMimeTypeDataReceivedArguments = (mimeType: mimeType, data: data)
        DispatchQueue.main.async {
            self.uploadAvatarMimeTypeDataReceivedInvocations.append((mimeType: mimeType, data: data))
        }
        try await uploadAvatarMimeTypeDataClosure?(mimeType, data)
    }

    //MARK: - uploadMedia

    open var uploadMediaMimeTypeDataProgressWatcherThrowableError: Error?
    var uploadMediaMimeTypeDataProgressWatcherUnderlyingCallsCount = 0
    open var uploadMediaMimeTypeDataProgressWatcherCallsCount: Int {
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
    open var uploadMediaMimeTypeDataProgressWatcherCalled: Bool {
        return uploadMediaMimeTypeDataProgressWatcherCallsCount > 0
    }
    open var uploadMediaMimeTypeDataProgressWatcherReceivedArguments: (mimeType: String, data: Data, progressWatcher: ProgressWatcher?)?
    open var uploadMediaMimeTypeDataProgressWatcherReceivedInvocations: [(mimeType: String, data: Data, progressWatcher: ProgressWatcher?)] = []

    var uploadMediaMimeTypeDataProgressWatcherUnderlyingReturnValue: String!
    open var uploadMediaMimeTypeDataProgressWatcherReturnValue: String! {
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
    open var uploadMediaMimeTypeDataProgressWatcherClosure: ((String, Data, ProgressWatcher?) async throws -> String)?

    open override func uploadMedia(mimeType: String, data: Data, progressWatcher: ProgressWatcher?) async throws -> String {
        if let error = uploadMediaMimeTypeDataProgressWatcherThrowableError {
            throw error
        }
        uploadMediaMimeTypeDataProgressWatcherCallsCount += 1
        uploadMediaMimeTypeDataProgressWatcherReceivedArguments = (mimeType: mimeType, data: data, progressWatcher: progressWatcher)
        DispatchQueue.main.async {
            self.uploadMediaMimeTypeDataProgressWatcherReceivedInvocations.append((mimeType: mimeType, data: data, progressWatcher: progressWatcher))
        }
        if let uploadMediaMimeTypeDataProgressWatcherClosure = uploadMediaMimeTypeDataProgressWatcherClosure {
            return try await uploadMediaMimeTypeDataProgressWatcherClosure(mimeType, data, progressWatcher)
        } else {
            return uploadMediaMimeTypeDataProgressWatcherReturnValue
        }
    }

    //MARK: - urlForOidcLogin

    open var urlForOidcLoginOidcConfigurationThrowableError: Error?
    var urlForOidcLoginOidcConfigurationUnderlyingCallsCount = 0
    open var urlForOidcLoginOidcConfigurationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return urlForOidcLoginOidcConfigurationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = urlForOidcLoginOidcConfigurationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                urlForOidcLoginOidcConfigurationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    urlForOidcLoginOidcConfigurationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var urlForOidcLoginOidcConfigurationCalled: Bool {
        return urlForOidcLoginOidcConfigurationCallsCount > 0
    }
    open var urlForOidcLoginOidcConfigurationReceivedOidcConfiguration: OidcConfiguration?
    open var urlForOidcLoginOidcConfigurationReceivedInvocations: [OidcConfiguration] = []

    var urlForOidcLoginOidcConfigurationUnderlyingReturnValue: OidcAuthorizationData!
    open var urlForOidcLoginOidcConfigurationReturnValue: OidcAuthorizationData! {
        get {
            if Thread.isMainThread {
                return urlForOidcLoginOidcConfigurationUnderlyingReturnValue
            } else {
                var returnValue: OidcAuthorizationData? = nil
                DispatchQueue.main.sync {
                    returnValue = urlForOidcLoginOidcConfigurationUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                urlForOidcLoginOidcConfigurationUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    urlForOidcLoginOidcConfigurationUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var urlForOidcLoginOidcConfigurationClosure: ((OidcConfiguration) async throws -> OidcAuthorizationData)?

    open override func urlForOidcLogin(oidcConfiguration: OidcConfiguration) async throws -> OidcAuthorizationData {
        if let error = urlForOidcLoginOidcConfigurationThrowableError {
            throw error
        }
        urlForOidcLoginOidcConfigurationCallsCount += 1
        urlForOidcLoginOidcConfigurationReceivedOidcConfiguration = oidcConfiguration
        DispatchQueue.main.async {
            self.urlForOidcLoginOidcConfigurationReceivedInvocations.append(oidcConfiguration)
        }
        if let urlForOidcLoginOidcConfigurationClosure = urlForOidcLoginOidcConfigurationClosure {
            return try await urlForOidcLoginOidcConfigurationClosure(oidcConfiguration)
        } else {
            return urlForOidcLoginOidcConfigurationReturnValue
        }
    }

    //MARK: - userId

    open var userIdThrowableError: Error?
    var userIdUnderlyingCallsCount = 0
    open var userIdCallsCount: Int {
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
    open var userIdCalled: Bool {
        return userIdCallsCount > 0
    }

    var userIdUnderlyingReturnValue: String!
    open var userIdReturnValue: String! {
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
    open var userIdClosure: (() throws -> String)?

    open override func userId() throws -> String {
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

    //MARK: - userIdServerName

    open var userIdServerNameThrowableError: Error?
    var userIdServerNameUnderlyingCallsCount = 0
    open var userIdServerNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return userIdServerNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = userIdServerNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                userIdServerNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    userIdServerNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var userIdServerNameCalled: Bool {
        return userIdServerNameCallsCount > 0
    }

    var userIdServerNameUnderlyingReturnValue: String!
    open var userIdServerNameReturnValue: String! {
        get {
            if Thread.isMainThread {
                return userIdServerNameUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = userIdServerNameUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                userIdServerNameUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    userIdServerNameUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var userIdServerNameClosure: (() throws -> String)?

    open override func userIdServerName() throws -> String {
        if let error = userIdServerNameThrowableError {
            throw error
        }
        userIdServerNameCallsCount += 1
        if let userIdServerNameClosure = userIdServerNameClosure {
            return try userIdServerNameClosure()
        } else {
            return userIdServerNameReturnValue
        }
    }
}
open class ClientBuilderSDKMock: MatrixRustSDK.ClientBuilder {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - addRootCertificates

    var addRootCertificatesCertificatesUnderlyingCallsCount = 0
    open var addRootCertificatesCertificatesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return addRootCertificatesCertificatesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = addRootCertificatesCertificatesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                addRootCertificatesCertificatesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    addRootCertificatesCertificatesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var addRootCertificatesCertificatesCalled: Bool {
        return addRootCertificatesCertificatesCallsCount > 0
    }
    open var addRootCertificatesCertificatesReceivedCertificates: [Data]?
    open var addRootCertificatesCertificatesReceivedInvocations: [[Data]] = []

    var addRootCertificatesCertificatesUnderlyingReturnValue: ClientBuilder!
    open var addRootCertificatesCertificatesReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return addRootCertificatesCertificatesUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = addRootCertificatesCertificatesUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                addRootCertificatesCertificatesUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    addRootCertificatesCertificatesUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var addRootCertificatesCertificatesClosure: (([Data]) -> ClientBuilder)?

    open override func addRootCertificates(certificates: [Data]) -> ClientBuilder {
        addRootCertificatesCertificatesCallsCount += 1
        addRootCertificatesCertificatesReceivedCertificates = certificates
        DispatchQueue.main.async {
            self.addRootCertificatesCertificatesReceivedInvocations.append(certificates)
        }
        if let addRootCertificatesCertificatesClosure = addRootCertificatesCertificatesClosure {
            return addRootCertificatesCertificatesClosure(certificates)
        } else {
            return addRootCertificatesCertificatesReturnValue
        }
    }

    //MARK: - autoEnableBackups

    var autoEnableBackupsAutoEnableBackupsUnderlyingCallsCount = 0
    open var autoEnableBackupsAutoEnableBackupsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return autoEnableBackupsAutoEnableBackupsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = autoEnableBackupsAutoEnableBackupsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                autoEnableBackupsAutoEnableBackupsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    autoEnableBackupsAutoEnableBackupsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var autoEnableBackupsAutoEnableBackupsCalled: Bool {
        return autoEnableBackupsAutoEnableBackupsCallsCount > 0
    }
    open var autoEnableBackupsAutoEnableBackupsReceivedAutoEnableBackups: Bool?
    open var autoEnableBackupsAutoEnableBackupsReceivedInvocations: [Bool] = []

    var autoEnableBackupsAutoEnableBackupsUnderlyingReturnValue: ClientBuilder!
    open var autoEnableBackupsAutoEnableBackupsReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return autoEnableBackupsAutoEnableBackupsUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = autoEnableBackupsAutoEnableBackupsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                autoEnableBackupsAutoEnableBackupsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    autoEnableBackupsAutoEnableBackupsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var autoEnableBackupsAutoEnableBackupsClosure: ((Bool) -> ClientBuilder)?

    open override func autoEnableBackups(autoEnableBackups: Bool) -> ClientBuilder {
        autoEnableBackupsAutoEnableBackupsCallsCount += 1
        autoEnableBackupsAutoEnableBackupsReceivedAutoEnableBackups = autoEnableBackups
        DispatchQueue.main.async {
            self.autoEnableBackupsAutoEnableBackupsReceivedInvocations.append(autoEnableBackups)
        }
        if let autoEnableBackupsAutoEnableBackupsClosure = autoEnableBackupsAutoEnableBackupsClosure {
            return autoEnableBackupsAutoEnableBackupsClosure(autoEnableBackups)
        } else {
            return autoEnableBackupsAutoEnableBackupsReturnValue
        }
    }

    //MARK: - autoEnableCrossSigning

    var autoEnableCrossSigningAutoEnableCrossSigningUnderlyingCallsCount = 0
    open var autoEnableCrossSigningAutoEnableCrossSigningCallsCount: Int {
        get {
            if Thread.isMainThread {
                return autoEnableCrossSigningAutoEnableCrossSigningUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = autoEnableCrossSigningAutoEnableCrossSigningUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                autoEnableCrossSigningAutoEnableCrossSigningUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    autoEnableCrossSigningAutoEnableCrossSigningUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var autoEnableCrossSigningAutoEnableCrossSigningCalled: Bool {
        return autoEnableCrossSigningAutoEnableCrossSigningCallsCount > 0
    }
    open var autoEnableCrossSigningAutoEnableCrossSigningReceivedAutoEnableCrossSigning: Bool?
    open var autoEnableCrossSigningAutoEnableCrossSigningReceivedInvocations: [Bool] = []

    var autoEnableCrossSigningAutoEnableCrossSigningUnderlyingReturnValue: ClientBuilder!
    open var autoEnableCrossSigningAutoEnableCrossSigningReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return autoEnableCrossSigningAutoEnableCrossSigningUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = autoEnableCrossSigningAutoEnableCrossSigningUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                autoEnableCrossSigningAutoEnableCrossSigningUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    autoEnableCrossSigningAutoEnableCrossSigningUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var autoEnableCrossSigningAutoEnableCrossSigningClosure: ((Bool) -> ClientBuilder)?

    open override func autoEnableCrossSigning(autoEnableCrossSigning: Bool) -> ClientBuilder {
        autoEnableCrossSigningAutoEnableCrossSigningCallsCount += 1
        autoEnableCrossSigningAutoEnableCrossSigningReceivedAutoEnableCrossSigning = autoEnableCrossSigning
        DispatchQueue.main.async {
            self.autoEnableCrossSigningAutoEnableCrossSigningReceivedInvocations.append(autoEnableCrossSigning)
        }
        if let autoEnableCrossSigningAutoEnableCrossSigningClosure = autoEnableCrossSigningAutoEnableCrossSigningClosure {
            return autoEnableCrossSigningAutoEnableCrossSigningClosure(autoEnableCrossSigning)
        } else {
            return autoEnableCrossSigningAutoEnableCrossSigningReturnValue
        }
    }

    //MARK: - backupDownloadStrategy

    var backupDownloadStrategyBackupDownloadStrategyUnderlyingCallsCount = 0
    open var backupDownloadStrategyBackupDownloadStrategyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return backupDownloadStrategyBackupDownloadStrategyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = backupDownloadStrategyBackupDownloadStrategyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                backupDownloadStrategyBackupDownloadStrategyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    backupDownloadStrategyBackupDownloadStrategyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var backupDownloadStrategyBackupDownloadStrategyCalled: Bool {
        return backupDownloadStrategyBackupDownloadStrategyCallsCount > 0
    }
    open var backupDownloadStrategyBackupDownloadStrategyReceivedBackupDownloadStrategy: BackupDownloadStrategy?
    open var backupDownloadStrategyBackupDownloadStrategyReceivedInvocations: [BackupDownloadStrategy] = []

    var backupDownloadStrategyBackupDownloadStrategyUnderlyingReturnValue: ClientBuilder!
    open var backupDownloadStrategyBackupDownloadStrategyReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return backupDownloadStrategyBackupDownloadStrategyUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = backupDownloadStrategyBackupDownloadStrategyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                backupDownloadStrategyBackupDownloadStrategyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    backupDownloadStrategyBackupDownloadStrategyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var backupDownloadStrategyBackupDownloadStrategyClosure: ((BackupDownloadStrategy) -> ClientBuilder)?

    open override func backupDownloadStrategy(backupDownloadStrategy: BackupDownloadStrategy) -> ClientBuilder {
        backupDownloadStrategyBackupDownloadStrategyCallsCount += 1
        backupDownloadStrategyBackupDownloadStrategyReceivedBackupDownloadStrategy = backupDownloadStrategy
        DispatchQueue.main.async {
            self.backupDownloadStrategyBackupDownloadStrategyReceivedInvocations.append(backupDownloadStrategy)
        }
        if let backupDownloadStrategyBackupDownloadStrategyClosure = backupDownloadStrategyBackupDownloadStrategyClosure {
            return backupDownloadStrategyBackupDownloadStrategyClosure(backupDownloadStrategy)
        } else {
            return backupDownloadStrategyBackupDownloadStrategyReturnValue
        }
    }

    //MARK: - build

    open var buildThrowableError: Error?
    var buildUnderlyingCallsCount = 0
    open var buildCallsCount: Int {
        get {
            if Thread.isMainThread {
                return buildUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = buildUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                buildUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    buildUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var buildCalled: Bool {
        return buildCallsCount > 0
    }

    var buildUnderlyingReturnValue: Client!
    open var buildReturnValue: Client! {
        get {
            if Thread.isMainThread {
                return buildUnderlyingReturnValue
            } else {
                var returnValue: Client? = nil
                DispatchQueue.main.sync {
                    returnValue = buildUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                buildUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    buildUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var buildClosure: (() async throws -> Client)?

    open override func build() async throws -> Client {
        if let error = buildThrowableError {
            throw error
        }
        buildCallsCount += 1
        if let buildClosure = buildClosure {
            return try await buildClosure()
        } else {
            return buildReturnValue
        }
    }

    //MARK: - buildWithQrCode

    open var buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerThrowableError: Error?
    var buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerUnderlyingCallsCount = 0
    open var buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerCalled: Bool {
        return buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerCallsCount > 0
    }
    open var buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerReceivedArguments: (qrCodeData: QrCodeData, oidcConfiguration: OidcConfiguration, progressListener: QrLoginProgressListener)?
    open var buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerReceivedInvocations: [(qrCodeData: QrCodeData, oidcConfiguration: OidcConfiguration, progressListener: QrLoginProgressListener)] = []

    var buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerUnderlyingReturnValue: Client!
    open var buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerReturnValue: Client! {
        get {
            if Thread.isMainThread {
                return buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerUnderlyingReturnValue
            } else {
                var returnValue: Client? = nil
                DispatchQueue.main.sync {
                    returnValue = buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerClosure: ((QrCodeData, OidcConfiguration, QrLoginProgressListener) async throws -> Client)?

    open override func buildWithQrCode(qrCodeData: QrCodeData, oidcConfiguration: OidcConfiguration, progressListener: QrLoginProgressListener) async throws -> Client {
        if let error = buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerThrowableError {
            throw error
        }
        buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerCallsCount += 1
        buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerReceivedArguments = (qrCodeData: qrCodeData, oidcConfiguration: oidcConfiguration, progressListener: progressListener)
        DispatchQueue.main.async {
            self.buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerReceivedInvocations.append((qrCodeData: qrCodeData, oidcConfiguration: oidcConfiguration, progressListener: progressListener))
        }
        if let buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerClosure = buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerClosure {
            return try await buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerClosure(qrCodeData, oidcConfiguration, progressListener)
        } else {
            return buildWithQrCodeQrCodeDataOidcConfigurationProgressListenerReturnValue
        }
    }

    //MARK: - disableAutomaticTokenRefresh

    var disableAutomaticTokenRefreshUnderlyingCallsCount = 0
    open var disableAutomaticTokenRefreshCallsCount: Int {
        get {
            if Thread.isMainThread {
                return disableAutomaticTokenRefreshUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = disableAutomaticTokenRefreshUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                disableAutomaticTokenRefreshUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    disableAutomaticTokenRefreshUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var disableAutomaticTokenRefreshCalled: Bool {
        return disableAutomaticTokenRefreshCallsCount > 0
    }

    var disableAutomaticTokenRefreshUnderlyingReturnValue: ClientBuilder!
    open var disableAutomaticTokenRefreshReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return disableAutomaticTokenRefreshUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = disableAutomaticTokenRefreshUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                disableAutomaticTokenRefreshUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    disableAutomaticTokenRefreshUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var disableAutomaticTokenRefreshClosure: (() -> ClientBuilder)?

    open override func disableAutomaticTokenRefresh() -> ClientBuilder {
        disableAutomaticTokenRefreshCallsCount += 1
        if let disableAutomaticTokenRefreshClosure = disableAutomaticTokenRefreshClosure {
            return disableAutomaticTokenRefreshClosure()
        } else {
            return disableAutomaticTokenRefreshReturnValue
        }
    }

    //MARK: - disableBuiltInRootCertificates

    var disableBuiltInRootCertificatesUnderlyingCallsCount = 0
    open var disableBuiltInRootCertificatesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return disableBuiltInRootCertificatesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = disableBuiltInRootCertificatesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                disableBuiltInRootCertificatesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    disableBuiltInRootCertificatesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var disableBuiltInRootCertificatesCalled: Bool {
        return disableBuiltInRootCertificatesCallsCount > 0
    }

    var disableBuiltInRootCertificatesUnderlyingReturnValue: ClientBuilder!
    open var disableBuiltInRootCertificatesReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return disableBuiltInRootCertificatesUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = disableBuiltInRootCertificatesUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                disableBuiltInRootCertificatesUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    disableBuiltInRootCertificatesUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var disableBuiltInRootCertificatesClosure: (() -> ClientBuilder)?

    open override func disableBuiltInRootCertificates() -> ClientBuilder {
        disableBuiltInRootCertificatesCallsCount += 1
        if let disableBuiltInRootCertificatesClosure = disableBuiltInRootCertificatesClosure {
            return disableBuiltInRootCertificatesClosure()
        } else {
            return disableBuiltInRootCertificatesReturnValue
        }
    }

    //MARK: - disableSslVerification

    var disableSslVerificationUnderlyingCallsCount = 0
    open var disableSslVerificationCallsCount: Int {
        get {
            if Thread.isMainThread {
                return disableSslVerificationUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = disableSslVerificationUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                disableSslVerificationUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    disableSslVerificationUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var disableSslVerificationCalled: Bool {
        return disableSslVerificationCallsCount > 0
    }

    var disableSslVerificationUnderlyingReturnValue: ClientBuilder!
    open var disableSslVerificationReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return disableSslVerificationUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = disableSslVerificationUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                disableSslVerificationUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    disableSslVerificationUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var disableSslVerificationClosure: (() -> ClientBuilder)?

    open override func disableSslVerification() -> ClientBuilder {
        disableSslVerificationCallsCount += 1
        if let disableSslVerificationClosure = disableSslVerificationClosure {
            return disableSslVerificationClosure()
        } else {
            return disableSslVerificationReturnValue
        }
    }

    //MARK: - enableCrossProcessRefreshLock

    var enableCrossProcessRefreshLockProcessIdSessionDelegateUnderlyingCallsCount = 0
    open var enableCrossProcessRefreshLockProcessIdSessionDelegateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return enableCrossProcessRefreshLockProcessIdSessionDelegateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = enableCrossProcessRefreshLockProcessIdSessionDelegateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enableCrossProcessRefreshLockProcessIdSessionDelegateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    enableCrossProcessRefreshLockProcessIdSessionDelegateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var enableCrossProcessRefreshLockProcessIdSessionDelegateCalled: Bool {
        return enableCrossProcessRefreshLockProcessIdSessionDelegateCallsCount > 0
    }
    open var enableCrossProcessRefreshLockProcessIdSessionDelegateReceivedArguments: (processId: String, sessionDelegate: ClientSessionDelegate)?
    open var enableCrossProcessRefreshLockProcessIdSessionDelegateReceivedInvocations: [(processId: String, sessionDelegate: ClientSessionDelegate)] = []

    var enableCrossProcessRefreshLockProcessIdSessionDelegateUnderlyingReturnValue: ClientBuilder!
    open var enableCrossProcessRefreshLockProcessIdSessionDelegateReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return enableCrossProcessRefreshLockProcessIdSessionDelegateUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = enableCrossProcessRefreshLockProcessIdSessionDelegateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enableCrossProcessRefreshLockProcessIdSessionDelegateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    enableCrossProcessRefreshLockProcessIdSessionDelegateUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var enableCrossProcessRefreshLockProcessIdSessionDelegateClosure: ((String, ClientSessionDelegate) -> ClientBuilder)?

    open override func enableCrossProcessRefreshLock(processId: String, sessionDelegate: ClientSessionDelegate) -> ClientBuilder {
        enableCrossProcessRefreshLockProcessIdSessionDelegateCallsCount += 1
        enableCrossProcessRefreshLockProcessIdSessionDelegateReceivedArguments = (processId: processId, sessionDelegate: sessionDelegate)
        DispatchQueue.main.async {
            self.enableCrossProcessRefreshLockProcessIdSessionDelegateReceivedInvocations.append((processId: processId, sessionDelegate: sessionDelegate))
        }
        if let enableCrossProcessRefreshLockProcessIdSessionDelegateClosure = enableCrossProcessRefreshLockProcessIdSessionDelegateClosure {
            return enableCrossProcessRefreshLockProcessIdSessionDelegateClosure(processId, sessionDelegate)
        } else {
            return enableCrossProcessRefreshLockProcessIdSessionDelegateReturnValue
        }
    }

    //MARK: - homeserverUrl

    var homeserverUrlUrlUnderlyingCallsCount = 0
    open var homeserverUrlUrlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return homeserverUrlUrlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = homeserverUrlUrlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                homeserverUrlUrlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    homeserverUrlUrlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var homeserverUrlUrlCalled: Bool {
        return homeserverUrlUrlCallsCount > 0
    }
    open var homeserverUrlUrlReceivedUrl: String?
    open var homeserverUrlUrlReceivedInvocations: [String] = []

    var homeserverUrlUrlUnderlyingReturnValue: ClientBuilder!
    open var homeserverUrlUrlReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return homeserverUrlUrlUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = homeserverUrlUrlUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                homeserverUrlUrlUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    homeserverUrlUrlUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var homeserverUrlUrlClosure: ((String) -> ClientBuilder)?

    open override func homeserverUrl(url: String) -> ClientBuilder {
        homeserverUrlUrlCallsCount += 1
        homeserverUrlUrlReceivedUrl = url
        DispatchQueue.main.async {
            self.homeserverUrlUrlReceivedInvocations.append(url)
        }
        if let homeserverUrlUrlClosure = homeserverUrlUrlClosure {
            return homeserverUrlUrlClosure(url)
        } else {
            return homeserverUrlUrlReturnValue
        }
    }

    //MARK: - passphrase

    var passphrasePassphraseUnderlyingCallsCount = 0
    open var passphrasePassphraseCallsCount: Int {
        get {
            if Thread.isMainThread {
                return passphrasePassphraseUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = passphrasePassphraseUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                passphrasePassphraseUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    passphrasePassphraseUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var passphrasePassphraseCalled: Bool {
        return passphrasePassphraseCallsCount > 0
    }
    open var passphrasePassphraseReceivedPassphrase: String?
    open var passphrasePassphraseReceivedInvocations: [String?] = []

    var passphrasePassphraseUnderlyingReturnValue: ClientBuilder!
    open var passphrasePassphraseReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return passphrasePassphraseUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = passphrasePassphraseUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                passphrasePassphraseUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    passphrasePassphraseUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var passphrasePassphraseClosure: ((String?) -> ClientBuilder)?

    open override func passphrase(passphrase: String?) -> ClientBuilder {
        passphrasePassphraseCallsCount += 1
        passphrasePassphraseReceivedPassphrase = passphrase
        DispatchQueue.main.async {
            self.passphrasePassphraseReceivedInvocations.append(passphrase)
        }
        if let passphrasePassphraseClosure = passphrasePassphraseClosure {
            return passphrasePassphraseClosure(passphrase)
        } else {
            return passphrasePassphraseReturnValue
        }
    }

    //MARK: - proxy

    var proxyUrlUnderlyingCallsCount = 0
    open var proxyUrlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return proxyUrlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = proxyUrlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                proxyUrlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    proxyUrlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var proxyUrlCalled: Bool {
        return proxyUrlCallsCount > 0
    }
    open var proxyUrlReceivedUrl: String?
    open var proxyUrlReceivedInvocations: [String] = []

    var proxyUrlUnderlyingReturnValue: ClientBuilder!
    open var proxyUrlReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return proxyUrlUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = proxyUrlUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                proxyUrlUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    proxyUrlUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var proxyUrlClosure: ((String) -> ClientBuilder)?

    open override func proxy(url: String) -> ClientBuilder {
        proxyUrlCallsCount += 1
        proxyUrlReceivedUrl = url
        DispatchQueue.main.async {
            self.proxyUrlReceivedInvocations.append(url)
        }
        if let proxyUrlClosure = proxyUrlClosure {
            return proxyUrlClosure(url)
        } else {
            return proxyUrlReturnValue
        }
    }

    //MARK: - requestConfig

    var requestConfigConfigUnderlyingCallsCount = 0
    open var requestConfigConfigCallsCount: Int {
        get {
            if Thread.isMainThread {
                return requestConfigConfigUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = requestConfigConfigUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                requestConfigConfigUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    requestConfigConfigUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var requestConfigConfigCalled: Bool {
        return requestConfigConfigCallsCount > 0
    }
    open var requestConfigConfigReceivedConfig: RequestConfig?
    open var requestConfigConfigReceivedInvocations: [RequestConfig] = []

    var requestConfigConfigUnderlyingReturnValue: ClientBuilder!
    open var requestConfigConfigReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return requestConfigConfigUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = requestConfigConfigUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                requestConfigConfigUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    requestConfigConfigUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var requestConfigConfigClosure: ((RequestConfig) -> ClientBuilder)?

    open override func requestConfig(config: RequestConfig) -> ClientBuilder {
        requestConfigConfigCallsCount += 1
        requestConfigConfigReceivedConfig = config
        DispatchQueue.main.async {
            self.requestConfigConfigReceivedInvocations.append(config)
        }
        if let requestConfigConfigClosure = requestConfigConfigClosure {
            return requestConfigConfigClosure(config)
        } else {
            return requestConfigConfigReturnValue
        }
    }

    //MARK: - roomKeyRecipientStrategy

    var roomKeyRecipientStrategyStrategyUnderlyingCallsCount = 0
    open var roomKeyRecipientStrategyStrategyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return roomKeyRecipientStrategyStrategyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = roomKeyRecipientStrategyStrategyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomKeyRecipientStrategyStrategyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    roomKeyRecipientStrategyStrategyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var roomKeyRecipientStrategyStrategyCalled: Bool {
        return roomKeyRecipientStrategyStrategyCallsCount > 0
    }
    open var roomKeyRecipientStrategyStrategyReceivedStrategy: CollectStrategy?
    open var roomKeyRecipientStrategyStrategyReceivedInvocations: [CollectStrategy] = []

    var roomKeyRecipientStrategyStrategyUnderlyingReturnValue: ClientBuilder!
    open var roomKeyRecipientStrategyStrategyReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return roomKeyRecipientStrategyStrategyUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = roomKeyRecipientStrategyStrategyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomKeyRecipientStrategyStrategyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    roomKeyRecipientStrategyStrategyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var roomKeyRecipientStrategyStrategyClosure: ((CollectStrategy) -> ClientBuilder)?

    open override func roomKeyRecipientStrategy(strategy: CollectStrategy) -> ClientBuilder {
        roomKeyRecipientStrategyStrategyCallsCount += 1
        roomKeyRecipientStrategyStrategyReceivedStrategy = strategy
        DispatchQueue.main.async {
            self.roomKeyRecipientStrategyStrategyReceivedInvocations.append(strategy)
        }
        if let roomKeyRecipientStrategyStrategyClosure = roomKeyRecipientStrategyStrategyClosure {
            return roomKeyRecipientStrategyStrategyClosure(strategy)
        } else {
            return roomKeyRecipientStrategyStrategyReturnValue
        }
    }

    //MARK: - serverName

    var serverNameServerNameUnderlyingCallsCount = 0
    open var serverNameServerNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return serverNameServerNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = serverNameServerNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                serverNameServerNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    serverNameServerNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var serverNameServerNameCalled: Bool {
        return serverNameServerNameCallsCount > 0
    }
    open var serverNameServerNameReceivedServerName: String?
    open var serverNameServerNameReceivedInvocations: [String] = []

    var serverNameServerNameUnderlyingReturnValue: ClientBuilder!
    open var serverNameServerNameReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return serverNameServerNameUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = serverNameServerNameUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                serverNameServerNameUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    serverNameServerNameUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var serverNameServerNameClosure: ((String) -> ClientBuilder)?

    open override func serverName(serverName: String) -> ClientBuilder {
        serverNameServerNameCallsCount += 1
        serverNameServerNameReceivedServerName = serverName
        DispatchQueue.main.async {
            self.serverNameServerNameReceivedInvocations.append(serverName)
        }
        if let serverNameServerNameClosure = serverNameServerNameClosure {
            return serverNameServerNameClosure(serverName)
        } else {
            return serverNameServerNameReturnValue
        }
    }

    //MARK: - serverNameOrHomeserverUrl

    var serverNameOrHomeserverUrlServerNameOrUrlUnderlyingCallsCount = 0
    open var serverNameOrHomeserverUrlServerNameOrUrlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return serverNameOrHomeserverUrlServerNameOrUrlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = serverNameOrHomeserverUrlServerNameOrUrlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                serverNameOrHomeserverUrlServerNameOrUrlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    serverNameOrHomeserverUrlServerNameOrUrlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var serverNameOrHomeserverUrlServerNameOrUrlCalled: Bool {
        return serverNameOrHomeserverUrlServerNameOrUrlCallsCount > 0
    }
    open var serverNameOrHomeserverUrlServerNameOrUrlReceivedServerNameOrUrl: String?
    open var serverNameOrHomeserverUrlServerNameOrUrlReceivedInvocations: [String] = []

    var serverNameOrHomeserverUrlServerNameOrUrlUnderlyingReturnValue: ClientBuilder!
    open var serverNameOrHomeserverUrlServerNameOrUrlReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return serverNameOrHomeserverUrlServerNameOrUrlUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = serverNameOrHomeserverUrlServerNameOrUrlUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                serverNameOrHomeserverUrlServerNameOrUrlUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    serverNameOrHomeserverUrlServerNameOrUrlUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var serverNameOrHomeserverUrlServerNameOrUrlClosure: ((String) -> ClientBuilder)?

    open override func serverNameOrHomeserverUrl(serverNameOrUrl: String) -> ClientBuilder {
        serverNameOrHomeserverUrlServerNameOrUrlCallsCount += 1
        serverNameOrHomeserverUrlServerNameOrUrlReceivedServerNameOrUrl = serverNameOrUrl
        DispatchQueue.main.async {
            self.serverNameOrHomeserverUrlServerNameOrUrlReceivedInvocations.append(serverNameOrUrl)
        }
        if let serverNameOrHomeserverUrlServerNameOrUrlClosure = serverNameOrHomeserverUrlServerNameOrUrlClosure {
            return serverNameOrHomeserverUrlServerNameOrUrlClosure(serverNameOrUrl)
        } else {
            return serverNameOrHomeserverUrlServerNameOrUrlReturnValue
        }
    }

    //MARK: - sessionPaths

    var sessionPathsDataPathCachePathUnderlyingCallsCount = 0
    open var sessionPathsDataPathCachePathCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sessionPathsDataPathCachePathUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sessionPathsDataPathCachePathUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sessionPathsDataPathCachePathUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sessionPathsDataPathCachePathUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sessionPathsDataPathCachePathCalled: Bool {
        return sessionPathsDataPathCachePathCallsCount > 0
    }
    open var sessionPathsDataPathCachePathReceivedArguments: (dataPath: String, cachePath: String)?
    open var sessionPathsDataPathCachePathReceivedInvocations: [(dataPath: String, cachePath: String)] = []

    var sessionPathsDataPathCachePathUnderlyingReturnValue: ClientBuilder!
    open var sessionPathsDataPathCachePathReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return sessionPathsDataPathCachePathUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = sessionPathsDataPathCachePathUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sessionPathsDataPathCachePathUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sessionPathsDataPathCachePathUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var sessionPathsDataPathCachePathClosure: ((String, String) -> ClientBuilder)?

    open override func sessionPaths(dataPath: String, cachePath: String) -> ClientBuilder {
        sessionPathsDataPathCachePathCallsCount += 1
        sessionPathsDataPathCachePathReceivedArguments = (dataPath: dataPath, cachePath: cachePath)
        DispatchQueue.main.async {
            self.sessionPathsDataPathCachePathReceivedInvocations.append((dataPath: dataPath, cachePath: cachePath))
        }
        if let sessionPathsDataPathCachePathClosure = sessionPathsDataPathCachePathClosure {
            return sessionPathsDataPathCachePathClosure(dataPath, cachePath)
        } else {
            return sessionPathsDataPathCachePathReturnValue
        }
    }

    //MARK: - setSessionDelegate

    var setSessionDelegateSessionDelegateUnderlyingCallsCount = 0
    open var setSessionDelegateSessionDelegateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setSessionDelegateSessionDelegateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setSessionDelegateSessionDelegateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setSessionDelegateSessionDelegateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setSessionDelegateSessionDelegateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var setSessionDelegateSessionDelegateCalled: Bool {
        return setSessionDelegateSessionDelegateCallsCount > 0
    }
    open var setSessionDelegateSessionDelegateReceivedSessionDelegate: ClientSessionDelegate?
    open var setSessionDelegateSessionDelegateReceivedInvocations: [ClientSessionDelegate] = []

    var setSessionDelegateSessionDelegateUnderlyingReturnValue: ClientBuilder!
    open var setSessionDelegateSessionDelegateReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return setSessionDelegateSessionDelegateUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = setSessionDelegateSessionDelegateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setSessionDelegateSessionDelegateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    setSessionDelegateSessionDelegateUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var setSessionDelegateSessionDelegateClosure: ((ClientSessionDelegate) -> ClientBuilder)?

    open override func setSessionDelegate(sessionDelegate: ClientSessionDelegate) -> ClientBuilder {
        setSessionDelegateSessionDelegateCallsCount += 1
        setSessionDelegateSessionDelegateReceivedSessionDelegate = sessionDelegate
        DispatchQueue.main.async {
            self.setSessionDelegateSessionDelegateReceivedInvocations.append(sessionDelegate)
        }
        if let setSessionDelegateSessionDelegateClosure = setSessionDelegateSessionDelegateClosure {
            return setSessionDelegateSessionDelegateClosure(sessionDelegate)
        } else {
            return setSessionDelegateSessionDelegateReturnValue
        }
    }

    //MARK: - slidingSyncVersionBuilder

    var slidingSyncVersionBuilderVersionBuilderUnderlyingCallsCount = 0
    open var slidingSyncVersionBuilderVersionBuilderCallsCount: Int {
        get {
            if Thread.isMainThread {
                return slidingSyncVersionBuilderVersionBuilderUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = slidingSyncVersionBuilderVersionBuilderUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                slidingSyncVersionBuilderVersionBuilderUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    slidingSyncVersionBuilderVersionBuilderUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var slidingSyncVersionBuilderVersionBuilderCalled: Bool {
        return slidingSyncVersionBuilderVersionBuilderCallsCount > 0
    }
    open var slidingSyncVersionBuilderVersionBuilderReceivedVersionBuilder: SlidingSyncVersionBuilder?
    open var slidingSyncVersionBuilderVersionBuilderReceivedInvocations: [SlidingSyncVersionBuilder] = []

    var slidingSyncVersionBuilderVersionBuilderUnderlyingReturnValue: ClientBuilder!
    open var slidingSyncVersionBuilderVersionBuilderReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return slidingSyncVersionBuilderVersionBuilderUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = slidingSyncVersionBuilderVersionBuilderUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                slidingSyncVersionBuilderVersionBuilderUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    slidingSyncVersionBuilderVersionBuilderUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var slidingSyncVersionBuilderVersionBuilderClosure: ((SlidingSyncVersionBuilder) -> ClientBuilder)?

    open override func slidingSyncVersionBuilder(versionBuilder: SlidingSyncVersionBuilder) -> ClientBuilder {
        slidingSyncVersionBuilderVersionBuilderCallsCount += 1
        slidingSyncVersionBuilderVersionBuilderReceivedVersionBuilder = versionBuilder
        DispatchQueue.main.async {
            self.slidingSyncVersionBuilderVersionBuilderReceivedInvocations.append(versionBuilder)
        }
        if let slidingSyncVersionBuilderVersionBuilderClosure = slidingSyncVersionBuilderVersionBuilderClosure {
            return slidingSyncVersionBuilderVersionBuilderClosure(versionBuilder)
        } else {
            return slidingSyncVersionBuilderVersionBuilderReturnValue
        }
    }

    //MARK: - userAgent

    var userAgentUserAgentUnderlyingCallsCount = 0
    open var userAgentUserAgentCallsCount: Int {
        get {
            if Thread.isMainThread {
                return userAgentUserAgentUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = userAgentUserAgentUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                userAgentUserAgentUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    userAgentUserAgentUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var userAgentUserAgentCalled: Bool {
        return userAgentUserAgentCallsCount > 0
    }
    open var userAgentUserAgentReceivedUserAgent: String?
    open var userAgentUserAgentReceivedInvocations: [String] = []

    var userAgentUserAgentUnderlyingReturnValue: ClientBuilder!
    open var userAgentUserAgentReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return userAgentUserAgentUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = userAgentUserAgentUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                userAgentUserAgentUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    userAgentUserAgentUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var userAgentUserAgentClosure: ((String) -> ClientBuilder)?

    open override func userAgent(userAgent: String) -> ClientBuilder {
        userAgentUserAgentCallsCount += 1
        userAgentUserAgentReceivedUserAgent = userAgent
        DispatchQueue.main.async {
            self.userAgentUserAgentReceivedInvocations.append(userAgent)
        }
        if let userAgentUserAgentClosure = userAgentUserAgentClosure {
            return userAgentUserAgentClosure(userAgent)
        } else {
            return userAgentUserAgentReturnValue
        }
    }

    //MARK: - username

    var usernameUsernameUnderlyingCallsCount = 0
    open var usernameUsernameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return usernameUsernameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = usernameUsernameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                usernameUsernameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    usernameUsernameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var usernameUsernameCalled: Bool {
        return usernameUsernameCallsCount > 0
    }
    open var usernameUsernameReceivedUsername: String?
    open var usernameUsernameReceivedInvocations: [String] = []

    var usernameUsernameUnderlyingReturnValue: ClientBuilder!
    open var usernameUsernameReturnValue: ClientBuilder! {
        get {
            if Thread.isMainThread {
                return usernameUsernameUnderlyingReturnValue
            } else {
                var returnValue: ClientBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = usernameUsernameUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                usernameUsernameUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    usernameUsernameUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var usernameUsernameClosure: ((String) -> ClientBuilder)?

    open override func username(username: String) -> ClientBuilder {
        usernameUsernameCallsCount += 1
        usernameUsernameReceivedUsername = username
        DispatchQueue.main.async {
            self.usernameUsernameReceivedInvocations.append(username)
        }
        if let usernameUsernameClosure = usernameUsernameClosure {
            return usernameUsernameClosure(username)
        } else {
            return usernameUsernameReturnValue
        }
    }
}
open class EncryptionSDKMock: MatrixRustSDK.Encryption {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - backupExistsOnServer

    open var backupExistsOnServerThrowableError: Error?
    var backupExistsOnServerUnderlyingCallsCount = 0
    open var backupExistsOnServerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return backupExistsOnServerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = backupExistsOnServerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                backupExistsOnServerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    backupExistsOnServerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var backupExistsOnServerCalled: Bool {
        return backupExistsOnServerCallsCount > 0
    }

    var backupExistsOnServerUnderlyingReturnValue: Bool!
    open var backupExistsOnServerReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return backupExistsOnServerUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = backupExistsOnServerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                backupExistsOnServerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    backupExistsOnServerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var backupExistsOnServerClosure: (() async throws -> Bool)?

    open override func backupExistsOnServer() async throws -> Bool {
        if let error = backupExistsOnServerThrowableError {
            throw error
        }
        backupExistsOnServerCallsCount += 1
        if let backupExistsOnServerClosure = backupExistsOnServerClosure {
            return try await backupExistsOnServerClosure()
        } else {
            return backupExistsOnServerReturnValue
        }
    }

    //MARK: - backupState

    var backupStateUnderlyingCallsCount = 0
    open var backupStateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return backupStateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = backupStateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                backupStateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    backupStateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var backupStateCalled: Bool {
        return backupStateCallsCount > 0
    }

    var backupStateUnderlyingReturnValue: BackupState!
    open var backupStateReturnValue: BackupState! {
        get {
            if Thread.isMainThread {
                return backupStateUnderlyingReturnValue
            } else {
                var returnValue: BackupState? = nil
                DispatchQueue.main.sync {
                    returnValue = backupStateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                backupStateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    backupStateUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var backupStateClosure: (() -> BackupState)?

    open override func backupState() -> BackupState {
        backupStateCallsCount += 1
        if let backupStateClosure = backupStateClosure {
            return backupStateClosure()
        } else {
            return backupStateReturnValue
        }
    }

    //MARK: - backupStateListener

    var backupStateListenerListenerUnderlyingCallsCount = 0
    open var backupStateListenerListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return backupStateListenerListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = backupStateListenerListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                backupStateListenerListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    backupStateListenerListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var backupStateListenerListenerCalled: Bool {
        return backupStateListenerListenerCallsCount > 0
    }
    open var backupStateListenerListenerReceivedListener: BackupStateListener?
    open var backupStateListenerListenerReceivedInvocations: [BackupStateListener] = []

    var backupStateListenerListenerUnderlyingReturnValue: TaskHandle!
    open var backupStateListenerListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return backupStateListenerListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = backupStateListenerListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                backupStateListenerListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    backupStateListenerListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var backupStateListenerListenerClosure: ((BackupStateListener) -> TaskHandle)?

    open override func backupStateListener(listener: BackupStateListener) -> TaskHandle {
        backupStateListenerListenerCallsCount += 1
        backupStateListenerListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.backupStateListenerListenerReceivedInvocations.append(listener)
        }
        if let backupStateListenerListenerClosure = backupStateListenerListenerClosure {
            return backupStateListenerListenerClosure(listener)
        } else {
            return backupStateListenerListenerReturnValue
        }
    }

    //MARK: - curve25519Key

    var curve25519KeyUnderlyingCallsCount = 0
    open var curve25519KeyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return curve25519KeyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = curve25519KeyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                curve25519KeyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    curve25519KeyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var curve25519KeyCalled: Bool {
        return curve25519KeyCallsCount > 0
    }

    var curve25519KeyUnderlyingReturnValue: String?
    open var curve25519KeyReturnValue: String? {
        get {
            if Thread.isMainThread {
                return curve25519KeyUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = curve25519KeyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                curve25519KeyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    curve25519KeyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var curve25519KeyClosure: (() async -> String?)?

    open override func curve25519Key() async -> String? {
        curve25519KeyCallsCount += 1
        if let curve25519KeyClosure = curve25519KeyClosure {
            return await curve25519KeyClosure()
        } else {
            return curve25519KeyReturnValue
        }
    }

    //MARK: - disableRecovery

    open var disableRecoveryThrowableError: Error?
    var disableRecoveryUnderlyingCallsCount = 0
    open var disableRecoveryCallsCount: Int {
        get {
            if Thread.isMainThread {
                return disableRecoveryUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = disableRecoveryUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                disableRecoveryUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    disableRecoveryUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var disableRecoveryCalled: Bool {
        return disableRecoveryCallsCount > 0
    }
    open var disableRecoveryClosure: (() async throws -> Void)?

    open override func disableRecovery() async throws {
        if let error = disableRecoveryThrowableError {
            throw error
        }
        disableRecoveryCallsCount += 1
        try await disableRecoveryClosure?()
    }

    //MARK: - ed25519Key

    var ed25519KeyUnderlyingCallsCount = 0
    open var ed25519KeyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return ed25519KeyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = ed25519KeyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ed25519KeyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    ed25519KeyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var ed25519KeyCalled: Bool {
        return ed25519KeyCallsCount > 0
    }

    var ed25519KeyUnderlyingReturnValue: String?
    open var ed25519KeyReturnValue: String? {
        get {
            if Thread.isMainThread {
                return ed25519KeyUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = ed25519KeyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ed25519KeyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    ed25519KeyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var ed25519KeyClosure: (() async -> String?)?

    open override func ed25519Key() async -> String? {
        ed25519KeyCallsCount += 1
        if let ed25519KeyClosure = ed25519KeyClosure {
            return await ed25519KeyClosure()
        } else {
            return ed25519KeyReturnValue
        }
    }

    //MARK: - enableBackups

    open var enableBackupsThrowableError: Error?
    var enableBackupsUnderlyingCallsCount = 0
    open var enableBackupsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return enableBackupsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = enableBackupsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enableBackupsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    enableBackupsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var enableBackupsCalled: Bool {
        return enableBackupsCallsCount > 0
    }
    open var enableBackupsClosure: (() async throws -> Void)?

    open override func enableBackups() async throws {
        if let error = enableBackupsThrowableError {
            throw error
        }
        enableBackupsCallsCount += 1
        try await enableBackupsClosure?()
    }

    //MARK: - enableRecovery

    open var enableRecoveryWaitForBackupsToUploadProgressListenerThrowableError: Error?
    var enableRecoveryWaitForBackupsToUploadProgressListenerUnderlyingCallsCount = 0
    open var enableRecoveryWaitForBackupsToUploadProgressListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return enableRecoveryWaitForBackupsToUploadProgressListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = enableRecoveryWaitForBackupsToUploadProgressListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enableRecoveryWaitForBackupsToUploadProgressListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    enableRecoveryWaitForBackupsToUploadProgressListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var enableRecoveryWaitForBackupsToUploadProgressListenerCalled: Bool {
        return enableRecoveryWaitForBackupsToUploadProgressListenerCallsCount > 0
    }
    open var enableRecoveryWaitForBackupsToUploadProgressListenerReceivedArguments: (waitForBackupsToUpload: Bool, progressListener: EnableRecoveryProgressListener)?
    open var enableRecoveryWaitForBackupsToUploadProgressListenerReceivedInvocations: [(waitForBackupsToUpload: Bool, progressListener: EnableRecoveryProgressListener)] = []

    var enableRecoveryWaitForBackupsToUploadProgressListenerUnderlyingReturnValue: String!
    open var enableRecoveryWaitForBackupsToUploadProgressListenerReturnValue: String! {
        get {
            if Thread.isMainThread {
                return enableRecoveryWaitForBackupsToUploadProgressListenerUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = enableRecoveryWaitForBackupsToUploadProgressListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enableRecoveryWaitForBackupsToUploadProgressListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    enableRecoveryWaitForBackupsToUploadProgressListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var enableRecoveryWaitForBackupsToUploadProgressListenerClosure: ((Bool, EnableRecoveryProgressListener) async throws -> String)?

    open override func enableRecovery(waitForBackupsToUpload: Bool, progressListener: EnableRecoveryProgressListener) async throws -> String {
        if let error = enableRecoveryWaitForBackupsToUploadProgressListenerThrowableError {
            throw error
        }
        enableRecoveryWaitForBackupsToUploadProgressListenerCallsCount += 1
        enableRecoveryWaitForBackupsToUploadProgressListenerReceivedArguments = (waitForBackupsToUpload: waitForBackupsToUpload, progressListener: progressListener)
        DispatchQueue.main.async {
            self.enableRecoveryWaitForBackupsToUploadProgressListenerReceivedInvocations.append((waitForBackupsToUpload: waitForBackupsToUpload, progressListener: progressListener))
        }
        if let enableRecoveryWaitForBackupsToUploadProgressListenerClosure = enableRecoveryWaitForBackupsToUploadProgressListenerClosure {
            return try await enableRecoveryWaitForBackupsToUploadProgressListenerClosure(waitForBackupsToUpload, progressListener)
        } else {
            return enableRecoveryWaitForBackupsToUploadProgressListenerReturnValue
        }
    }

    //MARK: - isLastDevice

    open var isLastDeviceThrowableError: Error?
    var isLastDeviceUnderlyingCallsCount = 0
    open var isLastDeviceCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isLastDeviceUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isLastDeviceUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isLastDeviceUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isLastDeviceUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isLastDeviceCalled: Bool {
        return isLastDeviceCallsCount > 0
    }

    var isLastDeviceUnderlyingReturnValue: Bool!
    open var isLastDeviceReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isLastDeviceUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isLastDeviceUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isLastDeviceUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isLastDeviceUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isLastDeviceClosure: (() async throws -> Bool)?

    open override func isLastDevice() async throws -> Bool {
        if let error = isLastDeviceThrowableError {
            throw error
        }
        isLastDeviceCallsCount += 1
        if let isLastDeviceClosure = isLastDeviceClosure {
            return try await isLastDeviceClosure()
        } else {
            return isLastDeviceReturnValue
        }
    }

    //MARK: - recover

    open var recoverRecoveryKeyThrowableError: Error?
    var recoverRecoveryKeyUnderlyingCallsCount = 0
    open var recoverRecoveryKeyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return recoverRecoveryKeyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = recoverRecoveryKeyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recoverRecoveryKeyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    recoverRecoveryKeyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var recoverRecoveryKeyCalled: Bool {
        return recoverRecoveryKeyCallsCount > 0
    }
    open var recoverRecoveryKeyReceivedRecoveryKey: String?
    open var recoverRecoveryKeyReceivedInvocations: [String] = []
    open var recoverRecoveryKeyClosure: ((String) async throws -> Void)?

    open override func recover(recoveryKey: String) async throws {
        if let error = recoverRecoveryKeyThrowableError {
            throw error
        }
        recoverRecoveryKeyCallsCount += 1
        recoverRecoveryKeyReceivedRecoveryKey = recoveryKey
        DispatchQueue.main.async {
            self.recoverRecoveryKeyReceivedInvocations.append(recoveryKey)
        }
        try await recoverRecoveryKeyClosure?(recoveryKey)
    }

    //MARK: - recoverAndReset

    open var recoverAndResetOldRecoveryKeyThrowableError: Error?
    var recoverAndResetOldRecoveryKeyUnderlyingCallsCount = 0
    open var recoverAndResetOldRecoveryKeyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return recoverAndResetOldRecoveryKeyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = recoverAndResetOldRecoveryKeyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recoverAndResetOldRecoveryKeyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    recoverAndResetOldRecoveryKeyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var recoverAndResetOldRecoveryKeyCalled: Bool {
        return recoverAndResetOldRecoveryKeyCallsCount > 0
    }
    open var recoverAndResetOldRecoveryKeyReceivedOldRecoveryKey: String?
    open var recoverAndResetOldRecoveryKeyReceivedInvocations: [String] = []

    var recoverAndResetOldRecoveryKeyUnderlyingReturnValue: String!
    open var recoverAndResetOldRecoveryKeyReturnValue: String! {
        get {
            if Thread.isMainThread {
                return recoverAndResetOldRecoveryKeyUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = recoverAndResetOldRecoveryKeyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recoverAndResetOldRecoveryKeyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    recoverAndResetOldRecoveryKeyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var recoverAndResetOldRecoveryKeyClosure: ((String) async throws -> String)?

    open override func recoverAndReset(oldRecoveryKey: String) async throws -> String {
        if let error = recoverAndResetOldRecoveryKeyThrowableError {
            throw error
        }
        recoverAndResetOldRecoveryKeyCallsCount += 1
        recoverAndResetOldRecoveryKeyReceivedOldRecoveryKey = oldRecoveryKey
        DispatchQueue.main.async {
            self.recoverAndResetOldRecoveryKeyReceivedInvocations.append(oldRecoveryKey)
        }
        if let recoverAndResetOldRecoveryKeyClosure = recoverAndResetOldRecoveryKeyClosure {
            return try await recoverAndResetOldRecoveryKeyClosure(oldRecoveryKey)
        } else {
            return recoverAndResetOldRecoveryKeyReturnValue
        }
    }

    //MARK: - recoveryState

    var recoveryStateUnderlyingCallsCount = 0
    open var recoveryStateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return recoveryStateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = recoveryStateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recoveryStateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    recoveryStateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var recoveryStateCalled: Bool {
        return recoveryStateCallsCount > 0
    }

    var recoveryStateUnderlyingReturnValue: RecoveryState!
    open var recoveryStateReturnValue: RecoveryState! {
        get {
            if Thread.isMainThread {
                return recoveryStateUnderlyingReturnValue
            } else {
                var returnValue: RecoveryState? = nil
                DispatchQueue.main.sync {
                    returnValue = recoveryStateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recoveryStateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    recoveryStateUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var recoveryStateClosure: (() -> RecoveryState)?

    open override func recoveryState() -> RecoveryState {
        recoveryStateCallsCount += 1
        if let recoveryStateClosure = recoveryStateClosure {
            return recoveryStateClosure()
        } else {
            return recoveryStateReturnValue
        }
    }

    //MARK: - recoveryStateListener

    var recoveryStateListenerListenerUnderlyingCallsCount = 0
    open var recoveryStateListenerListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return recoveryStateListenerListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = recoveryStateListenerListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recoveryStateListenerListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    recoveryStateListenerListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var recoveryStateListenerListenerCalled: Bool {
        return recoveryStateListenerListenerCallsCount > 0
    }
    open var recoveryStateListenerListenerReceivedListener: RecoveryStateListener?
    open var recoveryStateListenerListenerReceivedInvocations: [RecoveryStateListener] = []

    var recoveryStateListenerListenerUnderlyingReturnValue: TaskHandle!
    open var recoveryStateListenerListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return recoveryStateListenerListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = recoveryStateListenerListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recoveryStateListenerListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    recoveryStateListenerListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var recoveryStateListenerListenerClosure: ((RecoveryStateListener) -> TaskHandle)?

    open override func recoveryStateListener(listener: RecoveryStateListener) -> TaskHandle {
        recoveryStateListenerListenerCallsCount += 1
        recoveryStateListenerListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.recoveryStateListenerListenerReceivedInvocations.append(listener)
        }
        if let recoveryStateListenerListenerClosure = recoveryStateListenerListenerClosure {
            return recoveryStateListenerListenerClosure(listener)
        } else {
            return recoveryStateListenerListenerReturnValue
        }
    }

    //MARK: - resetIdentity

    open var resetIdentityThrowableError: Error?
    var resetIdentityUnderlyingCallsCount = 0
    open var resetIdentityCallsCount: Int {
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
    open var resetIdentityCalled: Bool {
        return resetIdentityCallsCount > 0
    }

    var resetIdentityUnderlyingReturnValue: IdentityResetHandle?
    open var resetIdentityReturnValue: IdentityResetHandle? {
        get {
            if Thread.isMainThread {
                return resetIdentityUnderlyingReturnValue
            } else {
                var returnValue: IdentityResetHandle?? = nil
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
    open var resetIdentityClosure: (() async throws -> IdentityResetHandle?)?

    open override func resetIdentity() async throws -> IdentityResetHandle? {
        if let error = resetIdentityThrowableError {
            throw error
        }
        resetIdentityCallsCount += 1
        if let resetIdentityClosure = resetIdentityClosure {
            return try await resetIdentityClosure()
        } else {
            return resetIdentityReturnValue
        }
    }

    //MARK: - resetRecoveryKey

    open var resetRecoveryKeyThrowableError: Error?
    var resetRecoveryKeyUnderlyingCallsCount = 0
    open var resetRecoveryKeyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resetRecoveryKeyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resetRecoveryKeyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetRecoveryKeyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resetRecoveryKeyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var resetRecoveryKeyCalled: Bool {
        return resetRecoveryKeyCallsCount > 0
    }

    var resetRecoveryKeyUnderlyingReturnValue: String!
    open var resetRecoveryKeyReturnValue: String! {
        get {
            if Thread.isMainThread {
                return resetRecoveryKeyUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = resetRecoveryKeyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetRecoveryKeyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    resetRecoveryKeyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var resetRecoveryKeyClosure: (() async throws -> String)?

    open override func resetRecoveryKey() async throws -> String {
        if let error = resetRecoveryKeyThrowableError {
            throw error
        }
        resetRecoveryKeyCallsCount += 1
        if let resetRecoveryKeyClosure = resetRecoveryKeyClosure {
            return try await resetRecoveryKeyClosure()
        } else {
            return resetRecoveryKeyReturnValue
        }
    }

    //MARK: - verificationState

    var verificationStateUnderlyingCallsCount = 0
    open var verificationStateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return verificationStateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = verificationStateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                verificationStateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    verificationStateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var verificationStateCalled: Bool {
        return verificationStateCallsCount > 0
    }

    var verificationStateUnderlyingReturnValue: VerificationState!
    open var verificationStateReturnValue: VerificationState! {
        get {
            if Thread.isMainThread {
                return verificationStateUnderlyingReturnValue
            } else {
                var returnValue: VerificationState? = nil
                DispatchQueue.main.sync {
                    returnValue = verificationStateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                verificationStateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    verificationStateUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var verificationStateClosure: (() -> VerificationState)?

    open override func verificationState() -> VerificationState {
        verificationStateCallsCount += 1
        if let verificationStateClosure = verificationStateClosure {
            return verificationStateClosure()
        } else {
            return verificationStateReturnValue
        }
    }

    //MARK: - verificationStateListener

    var verificationStateListenerListenerUnderlyingCallsCount = 0
    open var verificationStateListenerListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return verificationStateListenerListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = verificationStateListenerListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                verificationStateListenerListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    verificationStateListenerListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var verificationStateListenerListenerCalled: Bool {
        return verificationStateListenerListenerCallsCount > 0
    }
    open var verificationStateListenerListenerReceivedListener: VerificationStateListener?
    open var verificationStateListenerListenerReceivedInvocations: [VerificationStateListener] = []

    var verificationStateListenerListenerUnderlyingReturnValue: TaskHandle!
    open var verificationStateListenerListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return verificationStateListenerListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = verificationStateListenerListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                verificationStateListenerListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    verificationStateListenerListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var verificationStateListenerListenerClosure: ((VerificationStateListener) -> TaskHandle)?

    open override func verificationStateListener(listener: VerificationStateListener) -> TaskHandle {
        verificationStateListenerListenerCallsCount += 1
        verificationStateListenerListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.verificationStateListenerListenerReceivedInvocations.append(listener)
        }
        if let verificationStateListenerListenerClosure = verificationStateListenerListenerClosure {
            return verificationStateListenerListenerClosure(listener)
        } else {
            return verificationStateListenerListenerReturnValue
        }
    }

    //MARK: - waitForBackupUploadSteadyState

    open var waitForBackupUploadSteadyStateProgressListenerThrowableError: Error?
    var waitForBackupUploadSteadyStateProgressListenerUnderlyingCallsCount = 0
    open var waitForBackupUploadSteadyStateProgressListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return waitForBackupUploadSteadyStateProgressListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = waitForBackupUploadSteadyStateProgressListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                waitForBackupUploadSteadyStateProgressListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    waitForBackupUploadSteadyStateProgressListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var waitForBackupUploadSteadyStateProgressListenerCalled: Bool {
        return waitForBackupUploadSteadyStateProgressListenerCallsCount > 0
    }
    open var waitForBackupUploadSteadyStateProgressListenerReceivedProgressListener: BackupSteadyStateListener?
    open var waitForBackupUploadSteadyStateProgressListenerReceivedInvocations: [BackupSteadyStateListener?] = []
    open var waitForBackupUploadSteadyStateProgressListenerClosure: ((BackupSteadyStateListener?) async throws -> Void)?

    open override func waitForBackupUploadSteadyState(progressListener: BackupSteadyStateListener?) async throws {
        if let error = waitForBackupUploadSteadyStateProgressListenerThrowableError {
            throw error
        }
        waitForBackupUploadSteadyStateProgressListenerCallsCount += 1
        waitForBackupUploadSteadyStateProgressListenerReceivedProgressListener = progressListener
        DispatchQueue.main.async {
            self.waitForBackupUploadSteadyStateProgressListenerReceivedInvocations.append(progressListener)
        }
        try await waitForBackupUploadSteadyStateProgressListenerClosure?(progressListener)
    }

    //MARK: - waitForE2eeInitializationTasks

    var waitForE2eeInitializationTasksUnderlyingCallsCount = 0
    open var waitForE2eeInitializationTasksCallsCount: Int {
        get {
            if Thread.isMainThread {
                return waitForE2eeInitializationTasksUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = waitForE2eeInitializationTasksUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                waitForE2eeInitializationTasksUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    waitForE2eeInitializationTasksUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var waitForE2eeInitializationTasksCalled: Bool {
        return waitForE2eeInitializationTasksCallsCount > 0
    }
    open var waitForE2eeInitializationTasksClosure: (() async -> Void)?

    open override func waitForE2eeInitializationTasks() async {
        waitForE2eeInitializationTasksCallsCount += 1
        await waitForE2eeInitializationTasksClosure?()
    }
}
open class EventTimelineItemSDKMock: MatrixRustSDK.EventTimelineItem {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - canBeRepliedTo

    var canBeRepliedToUnderlyingCallsCount = 0
    open var canBeRepliedToCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canBeRepliedToUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canBeRepliedToUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canBeRepliedToUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canBeRepliedToUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canBeRepliedToCalled: Bool {
        return canBeRepliedToCallsCount > 0
    }

    var canBeRepliedToUnderlyingReturnValue: Bool!
    open var canBeRepliedToReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canBeRepliedToUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canBeRepliedToUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canBeRepliedToUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canBeRepliedToUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canBeRepliedToClosure: (() -> Bool)?

    open override func canBeRepliedTo() -> Bool {
        canBeRepliedToCallsCount += 1
        if let canBeRepliedToClosure = canBeRepliedToClosure {
            return canBeRepliedToClosure()
        } else {
            return canBeRepliedToReturnValue
        }
    }

    //MARK: - content

    var contentUnderlyingCallsCount = 0
    open var contentCallsCount: Int {
        get {
            if Thread.isMainThread {
                return contentUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = contentUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                contentUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    contentUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var contentCalled: Bool {
        return contentCallsCount > 0
    }

    var contentUnderlyingReturnValue: TimelineItemContent!
    open var contentReturnValue: TimelineItemContent! {
        get {
            if Thread.isMainThread {
                return contentUnderlyingReturnValue
            } else {
                var returnValue: TimelineItemContent? = nil
                DispatchQueue.main.sync {
                    returnValue = contentUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                contentUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    contentUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var contentClosure: (() -> TimelineItemContent)?

    open override func content() -> TimelineItemContent {
        contentCallsCount += 1
        if let contentClosure = contentClosure {
            return contentClosure()
        } else {
            return contentReturnValue
        }
    }

    //MARK: - debugInfo

    var debugInfoUnderlyingCallsCount = 0
    open var debugInfoCallsCount: Int {
        get {
            if Thread.isMainThread {
                return debugInfoUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = debugInfoUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                debugInfoUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    debugInfoUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var debugInfoCalled: Bool {
        return debugInfoCallsCount > 0
    }

    var debugInfoUnderlyingReturnValue: EventTimelineItemDebugInfo!
    open var debugInfoReturnValue: EventTimelineItemDebugInfo! {
        get {
            if Thread.isMainThread {
                return debugInfoUnderlyingReturnValue
            } else {
                var returnValue: EventTimelineItemDebugInfo? = nil
                DispatchQueue.main.sync {
                    returnValue = debugInfoUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                debugInfoUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    debugInfoUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var debugInfoClosure: (() -> EventTimelineItemDebugInfo)?

    open override func debugInfo() -> EventTimelineItemDebugInfo {
        debugInfoCallsCount += 1
        if let debugInfoClosure = debugInfoClosure {
            return debugInfoClosure()
        } else {
            return debugInfoReturnValue
        }
    }

    //MARK: - eventId

    var eventIdUnderlyingCallsCount = 0
    open var eventIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return eventIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = eventIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                eventIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    eventIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var eventIdCalled: Bool {
        return eventIdCallsCount > 0
    }

    var eventIdUnderlyingReturnValue: String?
    open var eventIdReturnValue: String? {
        get {
            if Thread.isMainThread {
                return eventIdUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = eventIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                eventIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    eventIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var eventIdClosure: (() -> String?)?

    open override func eventId() -> String? {
        eventIdCallsCount += 1
        if let eventIdClosure = eventIdClosure {
            return eventIdClosure()
        } else {
            return eventIdReturnValue
        }
    }

    //MARK: - getShield

    var getShieldStrictUnderlyingCallsCount = 0
    open var getShieldStrictCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getShieldStrictUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getShieldStrictUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getShieldStrictUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getShieldStrictUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var getShieldStrictCalled: Bool {
        return getShieldStrictCallsCount > 0
    }
    open var getShieldStrictReceivedStrict: Bool?
    open var getShieldStrictReceivedInvocations: [Bool] = []

    var getShieldStrictUnderlyingReturnValue: ShieldState?
    open var getShieldStrictReturnValue: ShieldState? {
        get {
            if Thread.isMainThread {
                return getShieldStrictUnderlyingReturnValue
            } else {
                var returnValue: ShieldState?? = nil
                DispatchQueue.main.sync {
                    returnValue = getShieldStrictUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getShieldStrictUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getShieldStrictUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var getShieldStrictClosure: ((Bool) -> ShieldState?)?

    open override func getShield(strict: Bool) -> ShieldState? {
        getShieldStrictCallsCount += 1
        getShieldStrictReceivedStrict = strict
        DispatchQueue.main.async {
            self.getShieldStrictReceivedInvocations.append(strict)
        }
        if let getShieldStrictClosure = getShieldStrictClosure {
            return getShieldStrictClosure(strict)
        } else {
            return getShieldStrictReturnValue
        }
    }

    //MARK: - isEditable

    var isEditableUnderlyingCallsCount = 0
    open var isEditableCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isEditableUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isEditableUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isEditableUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isEditableUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isEditableCalled: Bool {
        return isEditableCallsCount > 0
    }

    var isEditableUnderlyingReturnValue: Bool!
    open var isEditableReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isEditableUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isEditableUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isEditableUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isEditableUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isEditableClosure: (() -> Bool)?

    open override func isEditable() -> Bool {
        isEditableCallsCount += 1
        if let isEditableClosure = isEditableClosure {
            return isEditableClosure()
        } else {
            return isEditableReturnValue
        }
    }

    //MARK: - isLocal

    var isLocalUnderlyingCallsCount = 0
    open var isLocalCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isLocalUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isLocalUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isLocalUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isLocalUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isLocalCalled: Bool {
        return isLocalCallsCount > 0
    }

    var isLocalUnderlyingReturnValue: Bool!
    open var isLocalReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isLocalUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isLocalUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isLocalUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isLocalUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isLocalClosure: (() -> Bool)?

    open override func isLocal() -> Bool {
        isLocalCallsCount += 1
        if let isLocalClosure = isLocalClosure {
            return isLocalClosure()
        } else {
            return isLocalReturnValue
        }
    }

    //MARK: - isOwn

    var isOwnUnderlyingCallsCount = 0
    open var isOwnCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isOwnUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isOwnUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isOwnUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isOwnUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isOwnCalled: Bool {
        return isOwnCallsCount > 0
    }

    var isOwnUnderlyingReturnValue: Bool!
    open var isOwnReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isOwnUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isOwnUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isOwnUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isOwnUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isOwnClosure: (() -> Bool)?

    open override func isOwn() -> Bool {
        isOwnCallsCount += 1
        if let isOwnClosure = isOwnClosure {
            return isOwnClosure()
        } else {
            return isOwnReturnValue
        }
    }

    //MARK: - isRemote

    var isRemoteUnderlyingCallsCount = 0
    open var isRemoteCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isRemoteUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isRemoteUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isRemoteUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isRemoteUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isRemoteCalled: Bool {
        return isRemoteCallsCount > 0
    }

    var isRemoteUnderlyingReturnValue: Bool!
    open var isRemoteReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isRemoteUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isRemoteUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isRemoteUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isRemoteUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isRemoteClosure: (() -> Bool)?

    open override func isRemote() -> Bool {
        isRemoteCallsCount += 1
        if let isRemoteClosure = isRemoteClosure {
            return isRemoteClosure()
        } else {
            return isRemoteReturnValue
        }
    }

    //MARK: - localSendState

    var localSendStateUnderlyingCallsCount = 0
    open var localSendStateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return localSendStateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = localSendStateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                localSendStateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    localSendStateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var localSendStateCalled: Bool {
        return localSendStateCallsCount > 0
    }

    var localSendStateUnderlyingReturnValue: EventSendState?
    open var localSendStateReturnValue: EventSendState? {
        get {
            if Thread.isMainThread {
                return localSendStateUnderlyingReturnValue
            } else {
                var returnValue: EventSendState?? = nil
                DispatchQueue.main.sync {
                    returnValue = localSendStateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                localSendStateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    localSendStateUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var localSendStateClosure: (() -> EventSendState?)?

    open override func localSendState() -> EventSendState? {
        localSendStateCallsCount += 1
        if let localSendStateClosure = localSendStateClosure {
            return localSendStateClosure()
        } else {
            return localSendStateReturnValue
        }
    }

    //MARK: - origin

    var originUnderlyingCallsCount = 0
    open var originCallsCount: Int {
        get {
            if Thread.isMainThread {
                return originUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = originUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                originUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    originUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var originCalled: Bool {
        return originCallsCount > 0
    }

    var originUnderlyingReturnValue: EventItemOrigin?
    open var originReturnValue: EventItemOrigin? {
        get {
            if Thread.isMainThread {
                return originUnderlyingReturnValue
            } else {
                var returnValue: EventItemOrigin?? = nil
                DispatchQueue.main.sync {
                    returnValue = originUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                originUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    originUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var originClosure: (() -> EventItemOrigin?)?

    open override func origin() -> EventItemOrigin? {
        originCallsCount += 1
        if let originClosure = originClosure {
            return originClosure()
        } else {
            return originReturnValue
        }
    }

    //MARK: - reactions

    var reactionsUnderlyingCallsCount = 0
    open var reactionsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return reactionsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = reactionsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                reactionsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    reactionsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var reactionsCalled: Bool {
        return reactionsCallsCount > 0
    }

    var reactionsUnderlyingReturnValue: [Reaction]!
    open var reactionsReturnValue: [Reaction]! {
        get {
            if Thread.isMainThread {
                return reactionsUnderlyingReturnValue
            } else {
                var returnValue: [Reaction]? = nil
                DispatchQueue.main.sync {
                    returnValue = reactionsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                reactionsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    reactionsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var reactionsClosure: (() -> [Reaction])?

    open override func reactions() -> [Reaction] {
        reactionsCallsCount += 1
        if let reactionsClosure = reactionsClosure {
            return reactionsClosure()
        } else {
            return reactionsReturnValue
        }
    }

    //MARK: - readReceipts

    var readReceiptsUnderlyingCallsCount = 0
    open var readReceiptsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return readReceiptsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = readReceiptsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                readReceiptsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    readReceiptsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var readReceiptsCalled: Bool {
        return readReceiptsCallsCount > 0
    }

    var readReceiptsUnderlyingReturnValue: [String: Receipt]!
    open var readReceiptsReturnValue: [String: Receipt]! {
        get {
            if Thread.isMainThread {
                return readReceiptsUnderlyingReturnValue
            } else {
                var returnValue: [String: Receipt]? = nil
                DispatchQueue.main.sync {
                    returnValue = readReceiptsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                readReceiptsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    readReceiptsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var readReceiptsClosure: (() -> [String: Receipt])?

    open override func readReceipts() -> [String: Receipt] {
        readReceiptsCallsCount += 1
        if let readReceiptsClosure = readReceiptsClosure {
            return readReceiptsClosure()
        } else {
            return readReceiptsReturnValue
        }
    }

    //MARK: - sender

    var senderUnderlyingCallsCount = 0
    open var senderCallsCount: Int {
        get {
            if Thread.isMainThread {
                return senderUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = senderUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                senderUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    senderUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var senderCalled: Bool {
        return senderCallsCount > 0
    }

    var senderUnderlyingReturnValue: String!
    open var senderReturnValue: String! {
        get {
            if Thread.isMainThread {
                return senderUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = senderUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                senderUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    senderUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var senderClosure: (() -> String)?

    open override func sender() -> String {
        senderCallsCount += 1
        if let senderClosure = senderClosure {
            return senderClosure()
        } else {
            return senderReturnValue
        }
    }

    //MARK: - senderProfile

    var senderProfileUnderlyingCallsCount = 0
    open var senderProfileCallsCount: Int {
        get {
            if Thread.isMainThread {
                return senderProfileUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = senderProfileUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                senderProfileUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    senderProfileUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var senderProfileCalled: Bool {
        return senderProfileCallsCount > 0
    }

    var senderProfileUnderlyingReturnValue: ProfileDetails!
    open var senderProfileReturnValue: ProfileDetails! {
        get {
            if Thread.isMainThread {
                return senderProfileUnderlyingReturnValue
            } else {
                var returnValue: ProfileDetails? = nil
                DispatchQueue.main.sync {
                    returnValue = senderProfileUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                senderProfileUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    senderProfileUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var senderProfileClosure: (() -> ProfileDetails)?

    open override func senderProfile() -> ProfileDetails {
        senderProfileCallsCount += 1
        if let senderProfileClosure = senderProfileClosure {
            return senderProfileClosure()
        } else {
            return senderProfileReturnValue
        }
    }

    //MARK: - timestamp

    var timestampUnderlyingCallsCount = 0
    open var timestampCallsCount: Int {
        get {
            if Thread.isMainThread {
                return timestampUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = timestampUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                timestampUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    timestampUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var timestampCalled: Bool {
        return timestampCallsCount > 0
    }

    var timestampUnderlyingReturnValue: UInt64!
    open var timestampReturnValue: UInt64! {
        get {
            if Thread.isMainThread {
                return timestampUnderlyingReturnValue
            } else {
                var returnValue: UInt64? = nil
                DispatchQueue.main.sync {
                    returnValue = timestampUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                timestampUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    timestampUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var timestampClosure: (() -> UInt64)?

    open override func timestamp() -> UInt64 {
        timestampCallsCount += 1
        if let timestampClosure = timestampClosure {
            return timestampClosure()
        } else {
            return timestampReturnValue
        }
    }

    //MARK: - transactionId

    var transactionIdUnderlyingCallsCount = 0
    open var transactionIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return transactionIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = transactionIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                transactionIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    transactionIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var transactionIdCalled: Bool {
        return transactionIdCallsCount > 0
    }

    var transactionIdUnderlyingReturnValue: String?
    open var transactionIdReturnValue: String? {
        get {
            if Thread.isMainThread {
                return transactionIdUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = transactionIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                transactionIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    transactionIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var transactionIdClosure: (() -> String?)?

    open override func transactionId() -> String? {
        transactionIdCallsCount += 1
        if let transactionIdClosure = transactionIdClosure {
            return transactionIdClosure()
        } else {
            return transactionIdReturnValue
        }
    }
}
open class HomeserverLoginDetailsSDKMock: MatrixRustSDK.HomeserverLoginDetails {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - slidingSyncVersion

    var slidingSyncVersionUnderlyingCallsCount = 0
    open var slidingSyncVersionCallsCount: Int {
        get {
            if Thread.isMainThread {
                return slidingSyncVersionUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = slidingSyncVersionUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                slidingSyncVersionUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    slidingSyncVersionUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var slidingSyncVersionCalled: Bool {
        return slidingSyncVersionCallsCount > 0
    }

    var slidingSyncVersionUnderlyingReturnValue: SlidingSyncVersion!
    open var slidingSyncVersionReturnValue: SlidingSyncVersion! {
        get {
            if Thread.isMainThread {
                return slidingSyncVersionUnderlyingReturnValue
            } else {
                var returnValue: SlidingSyncVersion? = nil
                DispatchQueue.main.sync {
                    returnValue = slidingSyncVersionUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                slidingSyncVersionUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    slidingSyncVersionUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var slidingSyncVersionClosure: (() -> SlidingSyncVersion)?

    open override func slidingSyncVersion() -> SlidingSyncVersion {
        slidingSyncVersionCallsCount += 1
        if let slidingSyncVersionClosure = slidingSyncVersionClosure {
            return slidingSyncVersionClosure()
        } else {
            return slidingSyncVersionReturnValue
        }
    }

    //MARK: - supportsOidcLogin

    var supportsOidcLoginUnderlyingCallsCount = 0
    open var supportsOidcLoginCallsCount: Int {
        get {
            if Thread.isMainThread {
                return supportsOidcLoginUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = supportsOidcLoginUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                supportsOidcLoginUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    supportsOidcLoginUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var supportsOidcLoginCalled: Bool {
        return supportsOidcLoginCallsCount > 0
    }

    var supportsOidcLoginUnderlyingReturnValue: Bool!
    open var supportsOidcLoginReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return supportsOidcLoginUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = supportsOidcLoginUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                supportsOidcLoginUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    supportsOidcLoginUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var supportsOidcLoginClosure: (() -> Bool)?

    open override func supportsOidcLogin() -> Bool {
        supportsOidcLoginCallsCount += 1
        if let supportsOidcLoginClosure = supportsOidcLoginClosure {
            return supportsOidcLoginClosure()
        } else {
            return supportsOidcLoginReturnValue
        }
    }

    //MARK: - supportsPasswordLogin

    var supportsPasswordLoginUnderlyingCallsCount = 0
    open var supportsPasswordLoginCallsCount: Int {
        get {
            if Thread.isMainThread {
                return supportsPasswordLoginUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = supportsPasswordLoginUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                supportsPasswordLoginUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    supportsPasswordLoginUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var supportsPasswordLoginCalled: Bool {
        return supportsPasswordLoginCallsCount > 0
    }

    var supportsPasswordLoginUnderlyingReturnValue: Bool!
    open var supportsPasswordLoginReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return supportsPasswordLoginUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = supportsPasswordLoginUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                supportsPasswordLoginUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    supportsPasswordLoginUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var supportsPasswordLoginClosure: (() -> Bool)?

    open override func supportsPasswordLogin() -> Bool {
        supportsPasswordLoginCallsCount += 1
        if let supportsPasswordLoginClosure = supportsPasswordLoginClosure {
            return supportsPasswordLoginClosure()
        } else {
            return supportsPasswordLoginReturnValue
        }
    }

    //MARK: - url

    var urlUnderlyingCallsCount = 0
    open var urlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return urlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = urlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                urlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    urlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var urlCalled: Bool {
        return urlCallsCount > 0
    }

    var urlUnderlyingReturnValue: String!
    open var urlReturnValue: String! {
        get {
            if Thread.isMainThread {
                return urlUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = urlUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                urlUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    urlUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var urlClosure: (() -> String)?

    open override func url() -> String {
        urlCallsCount += 1
        if let urlClosure = urlClosure {
            return urlClosure()
        } else {
            return urlReturnValue
        }
    }
}
open class IdentityResetHandleSDKMock: MatrixRustSDK.IdentityResetHandle {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - authType

    var authTypeUnderlyingCallsCount = 0
    open var authTypeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return authTypeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = authTypeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                authTypeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    authTypeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var authTypeCalled: Bool {
        return authTypeCallsCount > 0
    }

    var authTypeUnderlyingReturnValue: CrossSigningResetAuthType!
    open var authTypeReturnValue: CrossSigningResetAuthType! {
        get {
            if Thread.isMainThread {
                return authTypeUnderlyingReturnValue
            } else {
                var returnValue: CrossSigningResetAuthType? = nil
                DispatchQueue.main.sync {
                    returnValue = authTypeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                authTypeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    authTypeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var authTypeClosure: (() -> CrossSigningResetAuthType)?

    open override func authType() -> CrossSigningResetAuthType {
        authTypeCallsCount += 1
        if let authTypeClosure = authTypeClosure {
            return authTypeClosure()
        } else {
            return authTypeReturnValue
        }
    }

    //MARK: - cancel

    var cancelUnderlyingCallsCount = 0
    open var cancelCallsCount: Int {
        get {
            if Thread.isMainThread {
                return cancelUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = cancelUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                cancelUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    cancelUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var cancelCalled: Bool {
        return cancelCallsCount > 0
    }
    open var cancelClosure: (() async -> Void)?

    open override func cancel() async {
        cancelCallsCount += 1
        await cancelClosure?()
    }

    //MARK: - reset

    open var resetAuthThrowableError: Error?
    var resetAuthUnderlyingCallsCount = 0
    open var resetAuthCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resetAuthUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resetAuthUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetAuthUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resetAuthUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var resetAuthCalled: Bool {
        return resetAuthCallsCount > 0
    }
    open var resetAuthReceivedAuth: AuthData?
    open var resetAuthReceivedInvocations: [AuthData?] = []
    open var resetAuthClosure: ((AuthData?) async throws -> Void)?

    open override func reset(auth: AuthData?) async throws {
        if let error = resetAuthThrowableError {
            throw error
        }
        resetAuthCallsCount += 1
        resetAuthReceivedAuth = auth
        DispatchQueue.main.async {
            self.resetAuthReceivedInvocations.append(auth)
        }
        try await resetAuthClosure?(auth)
    }
}
open class MediaFileHandleSDKMock: MatrixRustSDK.MediaFileHandle {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - path

    open var pathThrowableError: Error?
    var pathUnderlyingCallsCount = 0
    open var pathCallsCount: Int {
        get {
            if Thread.isMainThread {
                return pathUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = pathUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pathUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    pathUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var pathCalled: Bool {
        return pathCallsCount > 0
    }

    var pathUnderlyingReturnValue: String!
    open var pathReturnValue: String! {
        get {
            if Thread.isMainThread {
                return pathUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = pathUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pathUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    pathUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var pathClosure: (() throws -> String)?

    open override func path() throws -> String {
        if let error = pathThrowableError {
            throw error
        }
        pathCallsCount += 1
        if let pathClosure = pathClosure {
            return try pathClosure()
        } else {
            return pathReturnValue
        }
    }

    //MARK: - persist

    open var persistPathThrowableError: Error?
    var persistPathUnderlyingCallsCount = 0
    open var persistPathCallsCount: Int {
        get {
            if Thread.isMainThread {
                return persistPathUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = persistPathUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                persistPathUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    persistPathUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var persistPathCalled: Bool {
        return persistPathCallsCount > 0
    }
    open var persistPathReceivedPath: String?
    open var persistPathReceivedInvocations: [String] = []

    var persistPathUnderlyingReturnValue: Bool!
    open var persistPathReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return persistPathUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = persistPathUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                persistPathUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    persistPathUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var persistPathClosure: ((String) throws -> Bool)?

    open override func persist(path: String) throws -> Bool {
        if let error = persistPathThrowableError {
            throw error
        }
        persistPathCallsCount += 1
        persistPathReceivedPath = path
        DispatchQueue.main.async {
            self.persistPathReceivedInvocations.append(path)
        }
        if let persistPathClosure = persistPathClosure {
            return try persistPathClosure(path)
        } else {
            return persistPathReturnValue
        }
    }
}
open class MediaSourceSDKMock: MatrixRustSDK.MediaSource {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!
    static func reset()
    {
    }

    //MARK: - toJson

    var toJsonUnderlyingCallsCount = 0
    open var toJsonCallsCount: Int {
        get {
            if Thread.isMainThread {
                return toJsonUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = toJsonUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                toJsonUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    toJsonUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var toJsonCalled: Bool {
        return toJsonCallsCount > 0
    }

    var toJsonUnderlyingReturnValue: String!
    open var toJsonReturnValue: String! {
        get {
            if Thread.isMainThread {
                return toJsonUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = toJsonUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                toJsonUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    toJsonUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var toJsonClosure: (() -> String)?

    open override func toJson() -> String {
        toJsonCallsCount += 1
        if let toJsonClosure = toJsonClosure {
            return toJsonClosure()
        } else {
            return toJsonReturnValue
        }
    }

    //MARK: - url

    var urlUnderlyingCallsCount = 0
    open var urlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return urlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = urlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                urlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    urlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var urlCalled: Bool {
        return urlCallsCount > 0
    }

    var urlUnderlyingReturnValue: String!
    open var urlReturnValue: String! {
        get {
            if Thread.isMainThread {
                return urlUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = urlUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                urlUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    urlUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var urlClosure: (() -> String)?

    open override func url() -> String {
        urlCallsCount += 1
        if let urlClosure = urlClosure {
            return urlClosure()
        } else {
            return urlReturnValue
        }
    }
}
open class MessageSDKMock: MatrixRustSDK.Message {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - body

    var bodyUnderlyingCallsCount = 0
    open var bodyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return bodyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = bodyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                bodyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    bodyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var bodyCalled: Bool {
        return bodyCallsCount > 0
    }

    var bodyUnderlyingReturnValue: String!
    open var bodyReturnValue: String! {
        get {
            if Thread.isMainThread {
                return bodyUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = bodyUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                bodyUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    bodyUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var bodyClosure: (() -> String)?

    open override func body() -> String {
        bodyCallsCount += 1
        if let bodyClosure = bodyClosure {
            return bodyClosure()
        } else {
            return bodyReturnValue
        }
    }

    //MARK: - content

    var contentUnderlyingCallsCount = 0
    open var contentCallsCount: Int {
        get {
            if Thread.isMainThread {
                return contentUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = contentUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                contentUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    contentUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var contentCalled: Bool {
        return contentCallsCount > 0
    }

    var contentUnderlyingReturnValue: RoomMessageEventContentWithoutRelation!
    open var contentReturnValue: RoomMessageEventContentWithoutRelation! {
        get {
            if Thread.isMainThread {
                return contentUnderlyingReturnValue
            } else {
                var returnValue: RoomMessageEventContentWithoutRelation? = nil
                DispatchQueue.main.sync {
                    returnValue = contentUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                contentUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    contentUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var contentClosure: (() -> RoomMessageEventContentWithoutRelation)?

    open override func content() -> RoomMessageEventContentWithoutRelation {
        contentCallsCount += 1
        if let contentClosure = contentClosure {
            return contentClosure()
        } else {
            return contentReturnValue
        }
    }

    //MARK: - inReplyTo

    var inReplyToUnderlyingCallsCount = 0
    open var inReplyToCallsCount: Int {
        get {
            if Thread.isMainThread {
                return inReplyToUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = inReplyToUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                inReplyToUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    inReplyToUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var inReplyToCalled: Bool {
        return inReplyToCallsCount > 0
    }

    var inReplyToUnderlyingReturnValue: InReplyToDetails?
    open var inReplyToReturnValue: InReplyToDetails? {
        get {
            if Thread.isMainThread {
                return inReplyToUnderlyingReturnValue
            } else {
                var returnValue: InReplyToDetails?? = nil
                DispatchQueue.main.sync {
                    returnValue = inReplyToUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                inReplyToUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    inReplyToUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var inReplyToClosure: (() -> InReplyToDetails?)?

    open override func inReplyTo() -> InReplyToDetails? {
        inReplyToCallsCount += 1
        if let inReplyToClosure = inReplyToClosure {
            return inReplyToClosure()
        } else {
            return inReplyToReturnValue
        }
    }

    //MARK: - isEdited

    var isEditedUnderlyingCallsCount = 0
    open var isEditedCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isEditedUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isEditedUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isEditedUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isEditedUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isEditedCalled: Bool {
        return isEditedCallsCount > 0
    }

    var isEditedUnderlyingReturnValue: Bool!
    open var isEditedReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isEditedUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isEditedUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isEditedUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isEditedUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isEditedClosure: (() -> Bool)?

    open override func isEdited() -> Bool {
        isEditedCallsCount += 1
        if let isEditedClosure = isEditedClosure {
            return isEditedClosure()
        } else {
            return isEditedReturnValue
        }
    }

    //MARK: - isThreaded

    var isThreadedUnderlyingCallsCount = 0
    open var isThreadedCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isThreadedUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isThreadedUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isThreadedUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isThreadedUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isThreadedCalled: Bool {
        return isThreadedCallsCount > 0
    }

    var isThreadedUnderlyingReturnValue: Bool!
    open var isThreadedReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isThreadedUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isThreadedUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isThreadedUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isThreadedUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isThreadedClosure: (() -> Bool)?

    open override func isThreaded() -> Bool {
        isThreadedCallsCount += 1
        if let isThreadedClosure = isThreadedClosure {
            return isThreadedClosure()
        } else {
            return isThreadedReturnValue
        }
    }

    //MARK: - msgtype

    var msgtypeUnderlyingCallsCount = 0
    open var msgtypeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return msgtypeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = msgtypeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                msgtypeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    msgtypeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var msgtypeCalled: Bool {
        return msgtypeCallsCount > 0
    }

    var msgtypeUnderlyingReturnValue: MessageType!
    open var msgtypeReturnValue: MessageType! {
        get {
            if Thread.isMainThread {
                return msgtypeUnderlyingReturnValue
            } else {
                var returnValue: MessageType? = nil
                DispatchQueue.main.sync {
                    returnValue = msgtypeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                msgtypeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    msgtypeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var msgtypeClosure: (() -> MessageType)?

    open override func msgtype() -> MessageType {
        msgtypeCallsCount += 1
        if let msgtypeClosure = msgtypeClosure {
            return msgtypeClosure()
        } else {
            return msgtypeReturnValue
        }
    }
}
open class NotificationClientSDKMock: MatrixRustSDK.NotificationClient {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - getNotification

    open var getNotificationRoomIdEventIdThrowableError: Error?
    var getNotificationRoomIdEventIdUnderlyingCallsCount = 0
    open var getNotificationRoomIdEventIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getNotificationRoomIdEventIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getNotificationRoomIdEventIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getNotificationRoomIdEventIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getNotificationRoomIdEventIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var getNotificationRoomIdEventIdCalled: Bool {
        return getNotificationRoomIdEventIdCallsCount > 0
    }
    open var getNotificationRoomIdEventIdReceivedArguments: (roomId: String, eventId: String)?
    open var getNotificationRoomIdEventIdReceivedInvocations: [(roomId: String, eventId: String)] = []

    var getNotificationRoomIdEventIdUnderlyingReturnValue: NotificationItem?
    open var getNotificationRoomIdEventIdReturnValue: NotificationItem? {
        get {
            if Thread.isMainThread {
                return getNotificationRoomIdEventIdUnderlyingReturnValue
            } else {
                var returnValue: NotificationItem?? = nil
                DispatchQueue.main.sync {
                    returnValue = getNotificationRoomIdEventIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getNotificationRoomIdEventIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getNotificationRoomIdEventIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var getNotificationRoomIdEventIdClosure: ((String, String) async throws -> NotificationItem?)?

    open override func getNotification(roomId: String, eventId: String) async throws -> NotificationItem? {
        if let error = getNotificationRoomIdEventIdThrowableError {
            throw error
        }
        getNotificationRoomIdEventIdCallsCount += 1
        getNotificationRoomIdEventIdReceivedArguments = (roomId: roomId, eventId: eventId)
        DispatchQueue.main.async {
            self.getNotificationRoomIdEventIdReceivedInvocations.append((roomId: roomId, eventId: eventId))
        }
        if let getNotificationRoomIdEventIdClosure = getNotificationRoomIdEventIdClosure {
            return try await getNotificationRoomIdEventIdClosure(roomId, eventId)
        } else {
            return getNotificationRoomIdEventIdReturnValue
        }
    }
}
open class NotificationSettingsSDKMock: MatrixRustSDK.NotificationSettings {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - canHomeserverPushEncryptedEventToDevice

    var canHomeserverPushEncryptedEventToDeviceUnderlyingCallsCount = 0
    open var canHomeserverPushEncryptedEventToDeviceCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canHomeserverPushEncryptedEventToDeviceUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canHomeserverPushEncryptedEventToDeviceUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canHomeserverPushEncryptedEventToDeviceUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canHomeserverPushEncryptedEventToDeviceUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canHomeserverPushEncryptedEventToDeviceCalled: Bool {
        return canHomeserverPushEncryptedEventToDeviceCallsCount > 0
    }

    var canHomeserverPushEncryptedEventToDeviceUnderlyingReturnValue: Bool!
    open var canHomeserverPushEncryptedEventToDeviceReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canHomeserverPushEncryptedEventToDeviceUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canHomeserverPushEncryptedEventToDeviceUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canHomeserverPushEncryptedEventToDeviceUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canHomeserverPushEncryptedEventToDeviceUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canHomeserverPushEncryptedEventToDeviceClosure: (() async -> Bool)?

    open override func canHomeserverPushEncryptedEventToDevice() async -> Bool {
        canHomeserverPushEncryptedEventToDeviceCallsCount += 1
        if let canHomeserverPushEncryptedEventToDeviceClosure = canHomeserverPushEncryptedEventToDeviceClosure {
            return await canHomeserverPushEncryptedEventToDeviceClosure()
        } else {
            return canHomeserverPushEncryptedEventToDeviceReturnValue
        }
    }

    //MARK: - canPushEncryptedEventToDevice

    var canPushEncryptedEventToDeviceUnderlyingCallsCount = 0
    open var canPushEncryptedEventToDeviceCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canPushEncryptedEventToDeviceUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canPushEncryptedEventToDeviceUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canPushEncryptedEventToDeviceUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canPushEncryptedEventToDeviceUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canPushEncryptedEventToDeviceCalled: Bool {
        return canPushEncryptedEventToDeviceCallsCount > 0
    }

    var canPushEncryptedEventToDeviceUnderlyingReturnValue: Bool!
    open var canPushEncryptedEventToDeviceReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canPushEncryptedEventToDeviceUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canPushEncryptedEventToDeviceUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canPushEncryptedEventToDeviceUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canPushEncryptedEventToDeviceUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canPushEncryptedEventToDeviceClosure: (() async -> Bool)?

    open override func canPushEncryptedEventToDevice() async -> Bool {
        canPushEncryptedEventToDeviceCallsCount += 1
        if let canPushEncryptedEventToDeviceClosure = canPushEncryptedEventToDeviceClosure {
            return await canPushEncryptedEventToDeviceClosure()
        } else {
            return canPushEncryptedEventToDeviceReturnValue
        }
    }

    //MARK: - containsKeywordsRules

    var containsKeywordsRulesUnderlyingCallsCount = 0
    open var containsKeywordsRulesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return containsKeywordsRulesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = containsKeywordsRulesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                containsKeywordsRulesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    containsKeywordsRulesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var containsKeywordsRulesCalled: Bool {
        return containsKeywordsRulesCallsCount > 0
    }

    var containsKeywordsRulesUnderlyingReturnValue: Bool!
    open var containsKeywordsRulesReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return containsKeywordsRulesUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = containsKeywordsRulesUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                containsKeywordsRulesUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    containsKeywordsRulesUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var containsKeywordsRulesClosure: (() async -> Bool)?

    open override func containsKeywordsRules() async -> Bool {
        containsKeywordsRulesCallsCount += 1
        if let containsKeywordsRulesClosure = containsKeywordsRulesClosure {
            return await containsKeywordsRulesClosure()
        } else {
            return containsKeywordsRulesReturnValue
        }
    }

    //MARK: - getDefaultRoomNotificationMode

    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingCallsCount = 0
    open var getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount: Int {
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
    open var getDefaultRoomNotificationModeIsEncryptedIsOneToOneCalled: Bool {
        return getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount > 0
    }
    open var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedArguments: (isEncrypted: Bool, isOneToOne: Bool)?
    open var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocations: [(isEncrypted: Bool, isOneToOne: Bool)] = []

    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReturnValue: RoomNotificationMode!
    open var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue: RoomNotificationMode! {
        get {
            if Thread.isMainThread {
                return getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReturnValue
            } else {
                var returnValue: RoomNotificationMode? = nil
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
    open var getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure: ((Bool, Bool) async -> RoomNotificationMode)?

    open override func getDefaultRoomNotificationMode(isEncrypted: Bool, isOneToOne: Bool) async -> RoomNotificationMode {
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

    //MARK: - getRoomNotificationSettings

    open var getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneThrowableError: Error?
    var getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = 0
    open var getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneCalled: Bool {
        return getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCount > 0
    }
    open var getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedArguments: (roomId: String, isEncrypted: Bool, isOneToOne: Bool)?
    open var getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedInvocations: [(roomId: String, isEncrypted: Bool, isOneToOne: Bool)] = []

    var getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue: RoomNotificationSettings!
    open var getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue: RoomNotificationSettings! {
        get {
            if Thread.isMainThread {
                return getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue
            } else {
                var returnValue: RoomNotificationSettings? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure: ((String, Bool, Bool) async throws -> RoomNotificationSettings)?

    open override func getRoomNotificationSettings(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws -> RoomNotificationSettings {
        if let error = getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneThrowableError {
            throw error
        }
        getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCount += 1
        getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedArguments = (roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        DispatchQueue.main.async {
            self.getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedInvocations.append((roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne))
        }
        if let getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure = getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure {
            return try await getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure(roomId, isEncrypted, isOneToOne)
        } else {
            return getRoomNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue
        }
    }

    //MARK: - getRoomsWithUserDefinedRules

    var getRoomsWithUserDefinedRulesEnabledUnderlyingCallsCount = 0
    open var getRoomsWithUserDefinedRulesEnabledCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getRoomsWithUserDefinedRulesEnabledUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomsWithUserDefinedRulesEnabledUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomsWithUserDefinedRulesEnabledUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomsWithUserDefinedRulesEnabledUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var getRoomsWithUserDefinedRulesEnabledCalled: Bool {
        return getRoomsWithUserDefinedRulesEnabledCallsCount > 0
    }
    open var getRoomsWithUserDefinedRulesEnabledReceivedEnabled: Bool?
    open var getRoomsWithUserDefinedRulesEnabledReceivedInvocations: [Bool?] = []

    var getRoomsWithUserDefinedRulesEnabledUnderlyingReturnValue: [String]!
    open var getRoomsWithUserDefinedRulesEnabledReturnValue: [String]! {
        get {
            if Thread.isMainThread {
                return getRoomsWithUserDefinedRulesEnabledUnderlyingReturnValue
            } else {
                var returnValue: [String]? = nil
                DispatchQueue.main.sync {
                    returnValue = getRoomsWithUserDefinedRulesEnabledUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getRoomsWithUserDefinedRulesEnabledUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getRoomsWithUserDefinedRulesEnabledUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var getRoomsWithUserDefinedRulesEnabledClosure: ((Bool?) async -> [String])?

    open override func getRoomsWithUserDefinedRules(enabled: Bool?) async -> [String] {
        getRoomsWithUserDefinedRulesEnabledCallsCount += 1
        getRoomsWithUserDefinedRulesEnabledReceivedEnabled = enabled
        DispatchQueue.main.async {
            self.getRoomsWithUserDefinedRulesEnabledReceivedInvocations.append(enabled)
        }
        if let getRoomsWithUserDefinedRulesEnabledClosure = getRoomsWithUserDefinedRulesEnabledClosure {
            return await getRoomsWithUserDefinedRulesEnabledClosure(enabled)
        } else {
            return getRoomsWithUserDefinedRulesEnabledReturnValue
        }
    }

    //MARK: - getUserDefinedRoomNotificationMode

    open var getUserDefinedRoomNotificationModeRoomIdThrowableError: Error?
    var getUserDefinedRoomNotificationModeRoomIdUnderlyingCallsCount = 0
    open var getUserDefinedRoomNotificationModeRoomIdCallsCount: Int {
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
    open var getUserDefinedRoomNotificationModeRoomIdCalled: Bool {
        return getUserDefinedRoomNotificationModeRoomIdCallsCount > 0
    }
    open var getUserDefinedRoomNotificationModeRoomIdReceivedRoomId: String?
    open var getUserDefinedRoomNotificationModeRoomIdReceivedInvocations: [String] = []

    var getUserDefinedRoomNotificationModeRoomIdUnderlyingReturnValue: RoomNotificationMode?
    open var getUserDefinedRoomNotificationModeRoomIdReturnValue: RoomNotificationMode? {
        get {
            if Thread.isMainThread {
                return getUserDefinedRoomNotificationModeRoomIdUnderlyingReturnValue
            } else {
                var returnValue: RoomNotificationMode?? = nil
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
    open var getUserDefinedRoomNotificationModeRoomIdClosure: ((String) async throws -> RoomNotificationMode?)?

    open override func getUserDefinedRoomNotificationMode(roomId: String) async throws -> RoomNotificationMode? {
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

    //MARK: - isCallEnabled

    open var isCallEnabledThrowableError: Error?
    var isCallEnabledUnderlyingCallsCount = 0
    open var isCallEnabledCallsCount: Int {
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
    open var isCallEnabledCalled: Bool {
        return isCallEnabledCallsCount > 0
    }

    var isCallEnabledUnderlyingReturnValue: Bool!
    open var isCallEnabledReturnValue: Bool! {
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
    open var isCallEnabledClosure: (() async throws -> Bool)?

    open override func isCallEnabled() async throws -> Bool {
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

    //MARK: - isInviteForMeEnabled

    open var isInviteForMeEnabledThrowableError: Error?
    var isInviteForMeEnabledUnderlyingCallsCount = 0
    open var isInviteForMeEnabledCallsCount: Int {
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
    open var isInviteForMeEnabledCalled: Bool {
        return isInviteForMeEnabledCallsCount > 0
    }

    var isInviteForMeEnabledUnderlyingReturnValue: Bool!
    open var isInviteForMeEnabledReturnValue: Bool! {
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
    open var isInviteForMeEnabledClosure: (() async throws -> Bool)?

    open override func isInviteForMeEnabled() async throws -> Bool {
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

    //MARK: - isRoomMentionEnabled

    open var isRoomMentionEnabledThrowableError: Error?
    var isRoomMentionEnabledUnderlyingCallsCount = 0
    open var isRoomMentionEnabledCallsCount: Int {
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
    open var isRoomMentionEnabledCalled: Bool {
        return isRoomMentionEnabledCallsCount > 0
    }

    var isRoomMentionEnabledUnderlyingReturnValue: Bool!
    open var isRoomMentionEnabledReturnValue: Bool! {
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
    open var isRoomMentionEnabledClosure: (() async throws -> Bool)?

    open override func isRoomMentionEnabled() async throws -> Bool {
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

    //MARK: - isUserMentionEnabled

    open var isUserMentionEnabledThrowableError: Error?
    var isUserMentionEnabledUnderlyingCallsCount = 0
    open var isUserMentionEnabledCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isUserMentionEnabledUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isUserMentionEnabledUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isUserMentionEnabledUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isUserMentionEnabledUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isUserMentionEnabledCalled: Bool {
        return isUserMentionEnabledCallsCount > 0
    }

    var isUserMentionEnabledUnderlyingReturnValue: Bool!
    open var isUserMentionEnabledReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isUserMentionEnabledUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isUserMentionEnabledUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isUserMentionEnabledUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isUserMentionEnabledUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isUserMentionEnabledClosure: (() async throws -> Bool)?

    open override func isUserMentionEnabled() async throws -> Bool {
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

    //MARK: - restoreDefaultRoomNotificationMode

    open var restoreDefaultRoomNotificationModeRoomIdThrowableError: Error?
    var restoreDefaultRoomNotificationModeRoomIdUnderlyingCallsCount = 0
    open var restoreDefaultRoomNotificationModeRoomIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return restoreDefaultRoomNotificationModeRoomIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = restoreDefaultRoomNotificationModeRoomIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                restoreDefaultRoomNotificationModeRoomIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    restoreDefaultRoomNotificationModeRoomIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var restoreDefaultRoomNotificationModeRoomIdCalled: Bool {
        return restoreDefaultRoomNotificationModeRoomIdCallsCount > 0
    }
    open var restoreDefaultRoomNotificationModeRoomIdReceivedRoomId: String?
    open var restoreDefaultRoomNotificationModeRoomIdReceivedInvocations: [String] = []
    open var restoreDefaultRoomNotificationModeRoomIdClosure: ((String) async throws -> Void)?

    open override func restoreDefaultRoomNotificationMode(roomId: String) async throws {
        if let error = restoreDefaultRoomNotificationModeRoomIdThrowableError {
            throw error
        }
        restoreDefaultRoomNotificationModeRoomIdCallsCount += 1
        restoreDefaultRoomNotificationModeRoomIdReceivedRoomId = roomId
        DispatchQueue.main.async {
            self.restoreDefaultRoomNotificationModeRoomIdReceivedInvocations.append(roomId)
        }
        try await restoreDefaultRoomNotificationModeRoomIdClosure?(roomId)
    }

    //MARK: - setCallEnabled

    open var setCallEnabledEnabledThrowableError: Error?
    var setCallEnabledEnabledUnderlyingCallsCount = 0
    open var setCallEnabledEnabledCallsCount: Int {
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
    open var setCallEnabledEnabledCalled: Bool {
        return setCallEnabledEnabledCallsCount > 0
    }
    open var setCallEnabledEnabledReceivedEnabled: Bool?
    open var setCallEnabledEnabledReceivedInvocations: [Bool] = []
    open var setCallEnabledEnabledClosure: ((Bool) async throws -> Void)?

    open override func setCallEnabled(enabled: Bool) async throws {
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

    //MARK: - setDefaultRoomNotificationMode

    open var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeThrowableError: Error?
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingCallsCount = 0
    open var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount: Int {
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
    open var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCalled: Bool {
        return setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount > 0
    }
    open var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedArguments: (isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationMode)?
    open var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations: [(isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationMode)] = []
    open var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeClosure: ((Bool, Bool, RoomNotificationMode) async throws -> Void)?

    open override func setDefaultRoomNotificationMode(isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationMode) async throws {
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

    //MARK: - setDelegate

    var setDelegateDelegateUnderlyingCallsCount = 0
    open var setDelegateDelegateCallsCount: Int {
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
    open var setDelegateDelegateCalled: Bool {
        return setDelegateDelegateCallsCount > 0
    }
    open var setDelegateDelegateReceivedDelegate: NotificationSettingsDelegate?
    open var setDelegateDelegateReceivedInvocations: [NotificationSettingsDelegate?] = []
    open var setDelegateDelegateClosure: ((NotificationSettingsDelegate?) -> Void)?

    open override func setDelegate(delegate: NotificationSettingsDelegate?) {
        setDelegateDelegateCallsCount += 1
        setDelegateDelegateReceivedDelegate = delegate
        DispatchQueue.main.async {
            self.setDelegateDelegateReceivedInvocations.append(delegate)
        }
        setDelegateDelegateClosure?(delegate)
    }

    //MARK: - setInviteForMeEnabled

    open var setInviteForMeEnabledEnabledThrowableError: Error?
    var setInviteForMeEnabledEnabledUnderlyingCallsCount = 0
    open var setInviteForMeEnabledEnabledCallsCount: Int {
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
    open var setInviteForMeEnabledEnabledCalled: Bool {
        return setInviteForMeEnabledEnabledCallsCount > 0
    }
    open var setInviteForMeEnabledEnabledReceivedEnabled: Bool?
    open var setInviteForMeEnabledEnabledReceivedInvocations: [Bool] = []
    open var setInviteForMeEnabledEnabledClosure: ((Bool) async throws -> Void)?

    open override func setInviteForMeEnabled(enabled: Bool) async throws {
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

    //MARK: - setRoomMentionEnabled

    open var setRoomMentionEnabledEnabledThrowableError: Error?
    var setRoomMentionEnabledEnabledUnderlyingCallsCount = 0
    open var setRoomMentionEnabledEnabledCallsCount: Int {
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
    open var setRoomMentionEnabledEnabledCalled: Bool {
        return setRoomMentionEnabledEnabledCallsCount > 0
    }
    open var setRoomMentionEnabledEnabledReceivedEnabled: Bool?
    open var setRoomMentionEnabledEnabledReceivedInvocations: [Bool] = []
    open var setRoomMentionEnabledEnabledClosure: ((Bool) async throws -> Void)?

    open override func setRoomMentionEnabled(enabled: Bool) async throws {
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

    //MARK: - setRoomNotificationMode

    open var setRoomNotificationModeRoomIdModeThrowableError: Error?
    var setRoomNotificationModeRoomIdModeUnderlyingCallsCount = 0
    open var setRoomNotificationModeRoomIdModeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setRoomNotificationModeRoomIdModeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setRoomNotificationModeRoomIdModeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setRoomNotificationModeRoomIdModeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setRoomNotificationModeRoomIdModeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var setRoomNotificationModeRoomIdModeCalled: Bool {
        return setRoomNotificationModeRoomIdModeCallsCount > 0
    }
    open var setRoomNotificationModeRoomIdModeReceivedArguments: (roomId: String, mode: RoomNotificationMode)?
    open var setRoomNotificationModeRoomIdModeReceivedInvocations: [(roomId: String, mode: RoomNotificationMode)] = []
    open var setRoomNotificationModeRoomIdModeClosure: ((String, RoomNotificationMode) async throws -> Void)?

    open override func setRoomNotificationMode(roomId: String, mode: RoomNotificationMode) async throws {
        if let error = setRoomNotificationModeRoomIdModeThrowableError {
            throw error
        }
        setRoomNotificationModeRoomIdModeCallsCount += 1
        setRoomNotificationModeRoomIdModeReceivedArguments = (roomId: roomId, mode: mode)
        DispatchQueue.main.async {
            self.setRoomNotificationModeRoomIdModeReceivedInvocations.append((roomId: roomId, mode: mode))
        }
        try await setRoomNotificationModeRoomIdModeClosure?(roomId, mode)
    }

    //MARK: - setUserMentionEnabled

    open var setUserMentionEnabledEnabledThrowableError: Error?
    var setUserMentionEnabledEnabledUnderlyingCallsCount = 0
    open var setUserMentionEnabledEnabledCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setUserMentionEnabledEnabledUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setUserMentionEnabledEnabledUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setUserMentionEnabledEnabledUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setUserMentionEnabledEnabledUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var setUserMentionEnabledEnabledCalled: Bool {
        return setUserMentionEnabledEnabledCallsCount > 0
    }
    open var setUserMentionEnabledEnabledReceivedEnabled: Bool?
    open var setUserMentionEnabledEnabledReceivedInvocations: [Bool] = []
    open var setUserMentionEnabledEnabledClosure: ((Bool) async throws -> Void)?

    open override func setUserMentionEnabled(enabled: Bool) async throws {
        if let error = setUserMentionEnabledEnabledThrowableError {
            throw error
        }
        setUserMentionEnabledEnabledCallsCount += 1
        setUserMentionEnabledEnabledReceivedEnabled = enabled
        DispatchQueue.main.async {
            self.setUserMentionEnabledEnabledReceivedInvocations.append(enabled)
        }
        try await setUserMentionEnabledEnabledClosure?(enabled)
    }

    //MARK: - unmuteRoom

    open var unmuteRoomRoomIdIsEncryptedIsOneToOneThrowableError: Error?
    var unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = 0
    open var unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCount: Int {
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
    open var unmuteRoomRoomIdIsEncryptedIsOneToOneCalled: Bool {
        return unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCount > 0
    }
    open var unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedArguments: (roomId: String, isEncrypted: Bool, isOneToOne: Bool)?
    open var unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedInvocations: [(roomId: String, isEncrypted: Bool, isOneToOne: Bool)] = []
    open var unmuteRoomRoomIdIsEncryptedIsOneToOneClosure: ((String, Bool, Bool) async throws -> Void)?

    open override func unmuteRoom(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws {
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
}
open class OidcAuthorizationDataSDKMock: MatrixRustSDK.OidcAuthorizationData {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - loginUrl

    var loginUrlUnderlyingCallsCount = 0
    open var loginUrlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loginUrlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loginUrlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loginUrlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loginUrlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var loginUrlCalled: Bool {
        return loginUrlCallsCount > 0
    }

    var loginUrlUnderlyingReturnValue: String!
    open var loginUrlReturnValue: String! {
        get {
            if Thread.isMainThread {
                return loginUrlUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = loginUrlUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loginUrlUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loginUrlUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var loginUrlClosure: (() -> String)?

    open override func loginUrl() -> String {
        loginUrlCallsCount += 1
        if let loginUrlClosure = loginUrlClosure {
            return loginUrlClosure()
        } else {
            return loginUrlReturnValue
        }
    }
}
open class QrCodeDataSDKMock: MatrixRustSDK.QrCodeData {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!
    static func reset()
    {
    }
}
open class RoomSDKMock: MatrixRustSDK.Room {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - activeMembersCount

    var activeMembersCountUnderlyingCallsCount = 0
    open var activeMembersCountCallsCount: Int {
        get {
            if Thread.isMainThread {
                return activeMembersCountUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = activeMembersCountUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                activeMembersCountUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    activeMembersCountUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var activeMembersCountCalled: Bool {
        return activeMembersCountCallsCount > 0
    }

    var activeMembersCountUnderlyingReturnValue: UInt64!
    open var activeMembersCountReturnValue: UInt64! {
        get {
            if Thread.isMainThread {
                return activeMembersCountUnderlyingReturnValue
            } else {
                var returnValue: UInt64? = nil
                DispatchQueue.main.sync {
                    returnValue = activeMembersCountUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                activeMembersCountUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    activeMembersCountUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var activeMembersCountClosure: (() -> UInt64)?

    open override func activeMembersCount() -> UInt64 {
        activeMembersCountCallsCount += 1
        if let activeMembersCountClosure = activeMembersCountClosure {
            return activeMembersCountClosure()
        } else {
            return activeMembersCountReturnValue
        }
    }

    //MARK: - activeRoomCallParticipants

    var activeRoomCallParticipantsUnderlyingCallsCount = 0
    open var activeRoomCallParticipantsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return activeRoomCallParticipantsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = activeRoomCallParticipantsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                activeRoomCallParticipantsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    activeRoomCallParticipantsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var activeRoomCallParticipantsCalled: Bool {
        return activeRoomCallParticipantsCallsCount > 0
    }

    var activeRoomCallParticipantsUnderlyingReturnValue: [String]!
    open var activeRoomCallParticipantsReturnValue: [String]! {
        get {
            if Thread.isMainThread {
                return activeRoomCallParticipantsUnderlyingReturnValue
            } else {
                var returnValue: [String]? = nil
                DispatchQueue.main.sync {
                    returnValue = activeRoomCallParticipantsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                activeRoomCallParticipantsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    activeRoomCallParticipantsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var activeRoomCallParticipantsClosure: (() -> [String])?

    open override func activeRoomCallParticipants() -> [String] {
        activeRoomCallParticipantsCallsCount += 1
        if let activeRoomCallParticipantsClosure = activeRoomCallParticipantsClosure {
            return activeRoomCallParticipantsClosure()
        } else {
            return activeRoomCallParticipantsReturnValue
        }
    }

    //MARK: - alternativeAliases

    var alternativeAliasesUnderlyingCallsCount = 0
    open var alternativeAliasesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return alternativeAliasesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = alternativeAliasesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                alternativeAliasesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    alternativeAliasesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var alternativeAliasesCalled: Bool {
        return alternativeAliasesCallsCount > 0
    }

    var alternativeAliasesUnderlyingReturnValue: [String]!
    open var alternativeAliasesReturnValue: [String]! {
        get {
            if Thread.isMainThread {
                return alternativeAliasesUnderlyingReturnValue
            } else {
                var returnValue: [String]? = nil
                DispatchQueue.main.sync {
                    returnValue = alternativeAliasesUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                alternativeAliasesUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    alternativeAliasesUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var alternativeAliasesClosure: (() -> [String])?

    open override func alternativeAliases() -> [String] {
        alternativeAliasesCallsCount += 1
        if let alternativeAliasesClosure = alternativeAliasesClosure {
            return alternativeAliasesClosure()
        } else {
            return alternativeAliasesReturnValue
        }
    }

    //MARK: - applyPowerLevelChanges

    open var applyPowerLevelChangesChangesThrowableError: Error?
    var applyPowerLevelChangesChangesUnderlyingCallsCount = 0
    open var applyPowerLevelChangesChangesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return applyPowerLevelChangesChangesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = applyPowerLevelChangesChangesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                applyPowerLevelChangesChangesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    applyPowerLevelChangesChangesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var applyPowerLevelChangesChangesCalled: Bool {
        return applyPowerLevelChangesChangesCallsCount > 0
    }
    open var applyPowerLevelChangesChangesReceivedChanges: RoomPowerLevelChanges?
    open var applyPowerLevelChangesChangesReceivedInvocations: [RoomPowerLevelChanges] = []
    open var applyPowerLevelChangesChangesClosure: ((RoomPowerLevelChanges) async throws -> Void)?

    open override func applyPowerLevelChanges(changes: RoomPowerLevelChanges) async throws {
        if let error = applyPowerLevelChangesChangesThrowableError {
            throw error
        }
        applyPowerLevelChangesChangesCallsCount += 1
        applyPowerLevelChangesChangesReceivedChanges = changes
        DispatchQueue.main.async {
            self.applyPowerLevelChangesChangesReceivedInvocations.append(changes)
        }
        try await applyPowerLevelChangesChangesClosure?(changes)
    }

    //MARK: - avatarUrl

    var avatarUrlUnderlyingCallsCount = 0
    open var avatarUrlCallsCount: Int {
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
    open var avatarUrlCalled: Bool {
        return avatarUrlCallsCount > 0
    }

    var avatarUrlUnderlyingReturnValue: String?
    open var avatarUrlReturnValue: String? {
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
    open var avatarUrlClosure: (() -> String?)?

    open override func avatarUrl() -> String? {
        avatarUrlCallsCount += 1
        if let avatarUrlClosure = avatarUrlClosure {
            return avatarUrlClosure()
        } else {
            return avatarUrlReturnValue
        }
    }

    //MARK: - banUser

    open var banUserUserIdReasonThrowableError: Error?
    var banUserUserIdReasonUnderlyingCallsCount = 0
    open var banUserUserIdReasonCallsCount: Int {
        get {
            if Thread.isMainThread {
                return banUserUserIdReasonUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = banUserUserIdReasonUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                banUserUserIdReasonUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    banUserUserIdReasonUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var banUserUserIdReasonCalled: Bool {
        return banUserUserIdReasonCallsCount > 0
    }
    open var banUserUserIdReasonReceivedArguments: (userId: String, reason: String?)?
    open var banUserUserIdReasonReceivedInvocations: [(userId: String, reason: String?)] = []
    open var banUserUserIdReasonClosure: ((String, String?) async throws -> Void)?

    open override func banUser(userId: String, reason: String?) async throws {
        if let error = banUserUserIdReasonThrowableError {
            throw error
        }
        banUserUserIdReasonCallsCount += 1
        banUserUserIdReasonReceivedArguments = (userId: userId, reason: reason)
        DispatchQueue.main.async {
            self.banUserUserIdReasonReceivedInvocations.append((userId: userId, reason: reason))
        }
        try await banUserUserIdReasonClosure?(userId, reason)
    }

    //MARK: - canUserBan

    open var canUserBanUserIdThrowableError: Error?
    var canUserBanUserIdUnderlyingCallsCount = 0
    open var canUserBanUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserBanUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserBanUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserBanUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserBanUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canUserBanUserIdCalled: Bool {
        return canUserBanUserIdCallsCount > 0
    }
    open var canUserBanUserIdReceivedUserId: String?
    open var canUserBanUserIdReceivedInvocations: [String] = []

    var canUserBanUserIdUnderlyingReturnValue: Bool!
    open var canUserBanUserIdReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canUserBanUserIdUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserBanUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserBanUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserBanUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canUserBanUserIdClosure: ((String) async throws -> Bool)?

    open override func canUserBan(userId: String) async throws -> Bool {
        if let error = canUserBanUserIdThrowableError {
            throw error
        }
        canUserBanUserIdCallsCount += 1
        canUserBanUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.canUserBanUserIdReceivedInvocations.append(userId)
        }
        if let canUserBanUserIdClosure = canUserBanUserIdClosure {
            return try await canUserBanUserIdClosure(userId)
        } else {
            return canUserBanUserIdReturnValue
        }
    }

    //MARK: - canUserInvite

    open var canUserInviteUserIdThrowableError: Error?
    var canUserInviteUserIdUnderlyingCallsCount = 0
    open var canUserInviteUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserInviteUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserInviteUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserInviteUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserInviteUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canUserInviteUserIdCalled: Bool {
        return canUserInviteUserIdCallsCount > 0
    }
    open var canUserInviteUserIdReceivedUserId: String?
    open var canUserInviteUserIdReceivedInvocations: [String] = []

    var canUserInviteUserIdUnderlyingReturnValue: Bool!
    open var canUserInviteUserIdReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canUserInviteUserIdUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserInviteUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserInviteUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserInviteUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canUserInviteUserIdClosure: ((String) async throws -> Bool)?

    open override func canUserInvite(userId: String) async throws -> Bool {
        if let error = canUserInviteUserIdThrowableError {
            throw error
        }
        canUserInviteUserIdCallsCount += 1
        canUserInviteUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.canUserInviteUserIdReceivedInvocations.append(userId)
        }
        if let canUserInviteUserIdClosure = canUserInviteUserIdClosure {
            return try await canUserInviteUserIdClosure(userId)
        } else {
            return canUserInviteUserIdReturnValue
        }
    }

    //MARK: - canUserKick

    open var canUserKickUserIdThrowableError: Error?
    var canUserKickUserIdUnderlyingCallsCount = 0
    open var canUserKickUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserKickUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserKickUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserKickUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserKickUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canUserKickUserIdCalled: Bool {
        return canUserKickUserIdCallsCount > 0
    }
    open var canUserKickUserIdReceivedUserId: String?
    open var canUserKickUserIdReceivedInvocations: [String] = []

    var canUserKickUserIdUnderlyingReturnValue: Bool!
    open var canUserKickUserIdReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canUserKickUserIdUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserKickUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserKickUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserKickUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canUserKickUserIdClosure: ((String) async throws -> Bool)?

    open override func canUserKick(userId: String) async throws -> Bool {
        if let error = canUserKickUserIdThrowableError {
            throw error
        }
        canUserKickUserIdCallsCount += 1
        canUserKickUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.canUserKickUserIdReceivedInvocations.append(userId)
        }
        if let canUserKickUserIdClosure = canUserKickUserIdClosure {
            return try await canUserKickUserIdClosure(userId)
        } else {
            return canUserKickUserIdReturnValue
        }
    }

    //MARK: - canUserPinUnpin

    open var canUserPinUnpinUserIdThrowableError: Error?
    var canUserPinUnpinUserIdUnderlyingCallsCount = 0
    open var canUserPinUnpinUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserPinUnpinUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserPinUnpinUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserPinUnpinUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserPinUnpinUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canUserPinUnpinUserIdCalled: Bool {
        return canUserPinUnpinUserIdCallsCount > 0
    }
    open var canUserPinUnpinUserIdReceivedUserId: String?
    open var canUserPinUnpinUserIdReceivedInvocations: [String] = []

    var canUserPinUnpinUserIdUnderlyingReturnValue: Bool!
    open var canUserPinUnpinUserIdReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canUserPinUnpinUserIdUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserPinUnpinUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserPinUnpinUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserPinUnpinUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canUserPinUnpinUserIdClosure: ((String) async throws -> Bool)?

    open override func canUserPinUnpin(userId: String) async throws -> Bool {
        if let error = canUserPinUnpinUserIdThrowableError {
            throw error
        }
        canUserPinUnpinUserIdCallsCount += 1
        canUserPinUnpinUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.canUserPinUnpinUserIdReceivedInvocations.append(userId)
        }
        if let canUserPinUnpinUserIdClosure = canUserPinUnpinUserIdClosure {
            return try await canUserPinUnpinUserIdClosure(userId)
        } else {
            return canUserPinUnpinUserIdReturnValue
        }
    }

    //MARK: - canUserRedactOther

    open var canUserRedactOtherUserIdThrowableError: Error?
    var canUserRedactOtherUserIdUnderlyingCallsCount = 0
    open var canUserRedactOtherUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserRedactOtherUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserRedactOtherUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserRedactOtherUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserRedactOtherUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canUserRedactOtherUserIdCalled: Bool {
        return canUserRedactOtherUserIdCallsCount > 0
    }
    open var canUserRedactOtherUserIdReceivedUserId: String?
    open var canUserRedactOtherUserIdReceivedInvocations: [String] = []

    var canUserRedactOtherUserIdUnderlyingReturnValue: Bool!
    open var canUserRedactOtherUserIdReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canUserRedactOtherUserIdUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserRedactOtherUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserRedactOtherUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserRedactOtherUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canUserRedactOtherUserIdClosure: ((String) async throws -> Bool)?

    open override func canUserRedactOther(userId: String) async throws -> Bool {
        if let error = canUserRedactOtherUserIdThrowableError {
            throw error
        }
        canUserRedactOtherUserIdCallsCount += 1
        canUserRedactOtherUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.canUserRedactOtherUserIdReceivedInvocations.append(userId)
        }
        if let canUserRedactOtherUserIdClosure = canUserRedactOtherUserIdClosure {
            return try await canUserRedactOtherUserIdClosure(userId)
        } else {
            return canUserRedactOtherUserIdReturnValue
        }
    }

    //MARK: - canUserRedactOwn

    open var canUserRedactOwnUserIdThrowableError: Error?
    var canUserRedactOwnUserIdUnderlyingCallsCount = 0
    open var canUserRedactOwnUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserRedactOwnUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserRedactOwnUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserRedactOwnUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserRedactOwnUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canUserRedactOwnUserIdCalled: Bool {
        return canUserRedactOwnUserIdCallsCount > 0
    }
    open var canUserRedactOwnUserIdReceivedUserId: String?
    open var canUserRedactOwnUserIdReceivedInvocations: [String] = []

    var canUserRedactOwnUserIdUnderlyingReturnValue: Bool!
    open var canUserRedactOwnUserIdReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canUserRedactOwnUserIdUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserRedactOwnUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserRedactOwnUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserRedactOwnUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canUserRedactOwnUserIdClosure: ((String) async throws -> Bool)?

    open override func canUserRedactOwn(userId: String) async throws -> Bool {
        if let error = canUserRedactOwnUserIdThrowableError {
            throw error
        }
        canUserRedactOwnUserIdCallsCount += 1
        canUserRedactOwnUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.canUserRedactOwnUserIdReceivedInvocations.append(userId)
        }
        if let canUserRedactOwnUserIdClosure = canUserRedactOwnUserIdClosure {
            return try await canUserRedactOwnUserIdClosure(userId)
        } else {
            return canUserRedactOwnUserIdReturnValue
        }
    }

    //MARK: - canUserSendMessage

    open var canUserSendMessageUserIdMessageThrowableError: Error?
    var canUserSendMessageUserIdMessageUnderlyingCallsCount = 0
    open var canUserSendMessageUserIdMessageCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserSendMessageUserIdMessageUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserSendMessageUserIdMessageUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserSendMessageUserIdMessageUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserSendMessageUserIdMessageUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canUserSendMessageUserIdMessageCalled: Bool {
        return canUserSendMessageUserIdMessageCallsCount > 0
    }
    open var canUserSendMessageUserIdMessageReceivedArguments: (userId: String, message: MessageLikeEventType)?
    open var canUserSendMessageUserIdMessageReceivedInvocations: [(userId: String, message: MessageLikeEventType)] = []

    var canUserSendMessageUserIdMessageUnderlyingReturnValue: Bool!
    open var canUserSendMessageUserIdMessageReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canUserSendMessageUserIdMessageUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserSendMessageUserIdMessageUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserSendMessageUserIdMessageUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserSendMessageUserIdMessageUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canUserSendMessageUserIdMessageClosure: ((String, MessageLikeEventType) async throws -> Bool)?

    open override func canUserSendMessage(userId: String, message: MessageLikeEventType) async throws -> Bool {
        if let error = canUserSendMessageUserIdMessageThrowableError {
            throw error
        }
        canUserSendMessageUserIdMessageCallsCount += 1
        canUserSendMessageUserIdMessageReceivedArguments = (userId: userId, message: message)
        DispatchQueue.main.async {
            self.canUserSendMessageUserIdMessageReceivedInvocations.append((userId: userId, message: message))
        }
        if let canUserSendMessageUserIdMessageClosure = canUserSendMessageUserIdMessageClosure {
            return try await canUserSendMessageUserIdMessageClosure(userId, message)
        } else {
            return canUserSendMessageUserIdMessageReturnValue
        }
    }

    //MARK: - canUserSendState

    open var canUserSendStateUserIdStateEventThrowableError: Error?
    var canUserSendStateUserIdStateEventUnderlyingCallsCount = 0
    open var canUserSendStateUserIdStateEventCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserSendStateUserIdStateEventUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserSendStateUserIdStateEventUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserSendStateUserIdStateEventUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserSendStateUserIdStateEventUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canUserSendStateUserIdStateEventCalled: Bool {
        return canUserSendStateUserIdStateEventCallsCount > 0
    }
    open var canUserSendStateUserIdStateEventReceivedArguments: (userId: String, stateEvent: StateEventType)?
    open var canUserSendStateUserIdStateEventReceivedInvocations: [(userId: String, stateEvent: StateEventType)] = []

    var canUserSendStateUserIdStateEventUnderlyingReturnValue: Bool!
    open var canUserSendStateUserIdStateEventReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canUserSendStateUserIdStateEventUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserSendStateUserIdStateEventUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserSendStateUserIdStateEventUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserSendStateUserIdStateEventUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canUserSendStateUserIdStateEventClosure: ((String, StateEventType) async throws -> Bool)?

    open override func canUserSendState(userId: String, stateEvent: StateEventType) async throws -> Bool {
        if let error = canUserSendStateUserIdStateEventThrowableError {
            throw error
        }
        canUserSendStateUserIdStateEventCallsCount += 1
        canUserSendStateUserIdStateEventReceivedArguments = (userId: userId, stateEvent: stateEvent)
        DispatchQueue.main.async {
            self.canUserSendStateUserIdStateEventReceivedInvocations.append((userId: userId, stateEvent: stateEvent))
        }
        if let canUserSendStateUserIdStateEventClosure = canUserSendStateUserIdStateEventClosure {
            return try await canUserSendStateUserIdStateEventClosure(userId, stateEvent)
        } else {
            return canUserSendStateUserIdStateEventReturnValue
        }
    }

    //MARK: - canUserTriggerRoomNotification

    open var canUserTriggerRoomNotificationUserIdThrowableError: Error?
    var canUserTriggerRoomNotificationUserIdUnderlyingCallsCount = 0
    open var canUserTriggerRoomNotificationUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canUserTriggerRoomNotificationUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserTriggerRoomNotificationUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserTriggerRoomNotificationUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserTriggerRoomNotificationUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canUserTriggerRoomNotificationUserIdCalled: Bool {
        return canUserTriggerRoomNotificationUserIdCallsCount > 0
    }
    open var canUserTriggerRoomNotificationUserIdReceivedUserId: String?
    open var canUserTriggerRoomNotificationUserIdReceivedInvocations: [String] = []

    var canUserTriggerRoomNotificationUserIdUnderlyingReturnValue: Bool!
    open var canUserTriggerRoomNotificationUserIdReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return canUserTriggerRoomNotificationUserIdUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = canUserTriggerRoomNotificationUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canUserTriggerRoomNotificationUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canUserTriggerRoomNotificationUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canUserTriggerRoomNotificationUserIdClosure: ((String) async throws -> Bool)?

    open override func canUserTriggerRoomNotification(userId: String) async throws -> Bool {
        if let error = canUserTriggerRoomNotificationUserIdThrowableError {
            throw error
        }
        canUserTriggerRoomNotificationUserIdCallsCount += 1
        canUserTriggerRoomNotificationUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.canUserTriggerRoomNotificationUserIdReceivedInvocations.append(userId)
        }
        if let canUserTriggerRoomNotificationUserIdClosure = canUserTriggerRoomNotificationUserIdClosure {
            return try await canUserTriggerRoomNotificationUserIdClosure(userId)
        } else {
            return canUserTriggerRoomNotificationUserIdReturnValue
        }
    }

    //MARK: - canonicalAlias

    var canonicalAliasUnderlyingCallsCount = 0
    open var canonicalAliasCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canonicalAliasUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canonicalAliasUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canonicalAliasUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canonicalAliasUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canonicalAliasCalled: Bool {
        return canonicalAliasCallsCount > 0
    }

    var canonicalAliasUnderlyingReturnValue: String?
    open var canonicalAliasReturnValue: String? {
        get {
            if Thread.isMainThread {
                return canonicalAliasUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = canonicalAliasUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canonicalAliasUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canonicalAliasUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canonicalAliasClosure: (() -> String?)?

    open override func canonicalAlias() -> String? {
        canonicalAliasCallsCount += 1
        if let canonicalAliasClosure = canonicalAliasClosure {
            return canonicalAliasClosure()
        } else {
            return canonicalAliasReturnValue
        }
    }

    //MARK: - clearComposerDraft

    open var clearComposerDraftThrowableError: Error?
    var clearComposerDraftUnderlyingCallsCount = 0
    open var clearComposerDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return clearComposerDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = clearComposerDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                clearComposerDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    clearComposerDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var clearComposerDraftCalled: Bool {
        return clearComposerDraftCallsCount > 0
    }
    open var clearComposerDraftClosure: (() async throws -> Void)?

    open override func clearComposerDraft() async throws {
        if let error = clearComposerDraftThrowableError {
            throw error
        }
        clearComposerDraftCallsCount += 1
        try await clearComposerDraftClosure?()
    }

    //MARK: - discardRoomKey

    open var discardRoomKeyThrowableError: Error?
    var discardRoomKeyUnderlyingCallsCount = 0
    open var discardRoomKeyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return discardRoomKeyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = discardRoomKeyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                discardRoomKeyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    discardRoomKeyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var discardRoomKeyCalled: Bool {
        return discardRoomKeyCallsCount > 0
    }
    open var discardRoomKeyClosure: (() async throws -> Void)?

    open override func discardRoomKey() async throws {
        if let error = discardRoomKeyThrowableError {
            throw error
        }
        discardRoomKeyCallsCount += 1
        try await discardRoomKeyClosure?()
    }

    //MARK: - displayName

    var displayNameUnderlyingCallsCount = 0
    open var displayNameCallsCount: Int {
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
    open var displayNameCalled: Bool {
        return displayNameCallsCount > 0
    }

    var displayNameUnderlyingReturnValue: String?
    open var displayNameReturnValue: String? {
        get {
            if Thread.isMainThread {
                return displayNameUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
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
    open var displayNameClosure: (() -> String?)?

    open override func displayName() -> String? {
        displayNameCallsCount += 1
        if let displayNameClosure = displayNameClosure {
            return displayNameClosure()
        } else {
            return displayNameReturnValue
        }
    }

    //MARK: - edit

    open var editEventIdNewContentThrowableError: Error?
    var editEventIdNewContentUnderlyingCallsCount = 0
    open var editEventIdNewContentCallsCount: Int {
        get {
            if Thread.isMainThread {
                return editEventIdNewContentUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = editEventIdNewContentUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                editEventIdNewContentUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    editEventIdNewContentUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var editEventIdNewContentCalled: Bool {
        return editEventIdNewContentCallsCount > 0
    }
    open var editEventIdNewContentReceivedArguments: (eventId: String, newContent: RoomMessageEventContentWithoutRelation)?
    open var editEventIdNewContentReceivedInvocations: [(eventId: String, newContent: RoomMessageEventContentWithoutRelation)] = []
    open var editEventIdNewContentClosure: ((String, RoomMessageEventContentWithoutRelation) async throws -> Void)?

    open override func edit(eventId: String, newContent: RoomMessageEventContentWithoutRelation) async throws {
        if let error = editEventIdNewContentThrowableError {
            throw error
        }
        editEventIdNewContentCallsCount += 1
        editEventIdNewContentReceivedArguments = (eventId: eventId, newContent: newContent)
        DispatchQueue.main.async {
            self.editEventIdNewContentReceivedInvocations.append((eventId: eventId, newContent: newContent))
        }
        try await editEventIdNewContentClosure?(eventId, newContent)
    }

    //MARK: - enableSendQueue

    var enableSendQueueEnableUnderlyingCallsCount = 0
    open var enableSendQueueEnableCallsCount: Int {
        get {
            if Thread.isMainThread {
                return enableSendQueueEnableUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = enableSendQueueEnableUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enableSendQueueEnableUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    enableSendQueueEnableUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var enableSendQueueEnableCalled: Bool {
        return enableSendQueueEnableCallsCount > 0
    }
    open var enableSendQueueEnableReceivedEnable: Bool?
    open var enableSendQueueEnableReceivedInvocations: [Bool] = []
    open var enableSendQueueEnableClosure: ((Bool) -> Void)?

    open override func enableSendQueue(enable: Bool) {
        enableSendQueueEnableCallsCount += 1
        enableSendQueueEnableReceivedEnable = enable
        DispatchQueue.main.async {
            self.enableSendQueueEnableReceivedInvocations.append(enable)
        }
        enableSendQueueEnableClosure?(enable)
    }

    //MARK: - getPowerLevels

    open var getPowerLevelsThrowableError: Error?
    var getPowerLevelsUnderlyingCallsCount = 0
    open var getPowerLevelsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getPowerLevelsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getPowerLevelsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getPowerLevelsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getPowerLevelsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var getPowerLevelsCalled: Bool {
        return getPowerLevelsCallsCount > 0
    }

    var getPowerLevelsUnderlyingReturnValue: RoomPowerLevels!
    open var getPowerLevelsReturnValue: RoomPowerLevels! {
        get {
            if Thread.isMainThread {
                return getPowerLevelsUnderlyingReturnValue
            } else {
                var returnValue: RoomPowerLevels? = nil
                DispatchQueue.main.sync {
                    returnValue = getPowerLevelsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getPowerLevelsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getPowerLevelsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var getPowerLevelsClosure: (() async throws -> RoomPowerLevels)?

    open override func getPowerLevels() async throws -> RoomPowerLevels {
        if let error = getPowerLevelsThrowableError {
            throw error
        }
        getPowerLevelsCallsCount += 1
        if let getPowerLevelsClosure = getPowerLevelsClosure {
            return try await getPowerLevelsClosure()
        } else {
            return getPowerLevelsReturnValue
        }
    }

    //MARK: - hasActiveRoomCall

    var hasActiveRoomCallUnderlyingCallsCount = 0
    open var hasActiveRoomCallCallsCount: Int {
        get {
            if Thread.isMainThread {
                return hasActiveRoomCallUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = hasActiveRoomCallUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                hasActiveRoomCallUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    hasActiveRoomCallUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var hasActiveRoomCallCalled: Bool {
        return hasActiveRoomCallCallsCount > 0
    }

    var hasActiveRoomCallUnderlyingReturnValue: Bool!
    open var hasActiveRoomCallReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return hasActiveRoomCallUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = hasActiveRoomCallUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                hasActiveRoomCallUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    hasActiveRoomCallUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var hasActiveRoomCallClosure: (() -> Bool)?

    open override func hasActiveRoomCall() -> Bool {
        hasActiveRoomCallCallsCount += 1
        if let hasActiveRoomCallClosure = hasActiveRoomCallClosure {
            return hasActiveRoomCallClosure()
        } else {
            return hasActiveRoomCallReturnValue
        }
    }

    //MARK: - heroes

    var heroesUnderlyingCallsCount = 0
    open var heroesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return heroesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = heroesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                heroesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    heroesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var heroesCalled: Bool {
        return heroesCallsCount > 0
    }

    var heroesUnderlyingReturnValue: [RoomHero]!
    open var heroesReturnValue: [RoomHero]! {
        get {
            if Thread.isMainThread {
                return heroesUnderlyingReturnValue
            } else {
                var returnValue: [RoomHero]? = nil
                DispatchQueue.main.sync {
                    returnValue = heroesUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                heroesUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    heroesUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var heroesClosure: (() -> [RoomHero])?

    open override func heroes() -> [RoomHero] {
        heroesCallsCount += 1
        if let heroesClosure = heroesClosure {
            return heroesClosure()
        } else {
            return heroesReturnValue
        }
    }

    //MARK: - id

    var idUnderlyingCallsCount = 0
    open var idCallsCount: Int {
        get {
            if Thread.isMainThread {
                return idUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = idUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                idUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    idUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var idCalled: Bool {
        return idCallsCount > 0
    }

    var idUnderlyingReturnValue: String!
    open var idReturnValue: String! {
        get {
            if Thread.isMainThread {
                return idUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = idUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                idUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    idUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var idClosure: (() -> String)?

    open override func id() -> String {
        idCallsCount += 1
        if let idClosure = idClosure {
            return idClosure()
        } else {
            return idReturnValue
        }
    }

    //MARK: - ignoreDeviceTrustAndResend

    open var ignoreDeviceTrustAndResendDevicesTransactionIdThrowableError: Error?
    var ignoreDeviceTrustAndResendDevicesTransactionIdUnderlyingCallsCount = 0
    open var ignoreDeviceTrustAndResendDevicesTransactionIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return ignoreDeviceTrustAndResendDevicesTransactionIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = ignoreDeviceTrustAndResendDevicesTransactionIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ignoreDeviceTrustAndResendDevicesTransactionIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    ignoreDeviceTrustAndResendDevicesTransactionIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var ignoreDeviceTrustAndResendDevicesTransactionIdCalled: Bool {
        return ignoreDeviceTrustAndResendDevicesTransactionIdCallsCount > 0
    }
    open var ignoreDeviceTrustAndResendDevicesTransactionIdReceivedArguments: (devices: [String: [String]], transactionId: String)?
    open var ignoreDeviceTrustAndResendDevicesTransactionIdReceivedInvocations: [(devices: [String: [String]], transactionId: String)] = []
    open var ignoreDeviceTrustAndResendDevicesTransactionIdClosure: (([String: [String]], String) async throws -> Void)?

    open override func ignoreDeviceTrustAndResend(devices: [String: [String]], transactionId: String) async throws {
        if let error = ignoreDeviceTrustAndResendDevicesTransactionIdThrowableError {
            throw error
        }
        ignoreDeviceTrustAndResendDevicesTransactionIdCallsCount += 1
        ignoreDeviceTrustAndResendDevicesTransactionIdReceivedArguments = (devices: devices, transactionId: transactionId)
        DispatchQueue.main.async {
            self.ignoreDeviceTrustAndResendDevicesTransactionIdReceivedInvocations.append((devices: devices, transactionId: transactionId))
        }
        try await ignoreDeviceTrustAndResendDevicesTransactionIdClosure?(devices, transactionId)
    }

    //MARK: - ignoreUser

    open var ignoreUserUserIdThrowableError: Error?
    var ignoreUserUserIdUnderlyingCallsCount = 0
    open var ignoreUserUserIdCallsCount: Int {
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
    open var ignoreUserUserIdCalled: Bool {
        return ignoreUserUserIdCallsCount > 0
    }
    open var ignoreUserUserIdReceivedUserId: String?
    open var ignoreUserUserIdReceivedInvocations: [String] = []
    open var ignoreUserUserIdClosure: ((String) async throws -> Void)?

    open override func ignoreUser(userId: String) async throws {
        if let error = ignoreUserUserIdThrowableError {
            throw error
        }
        ignoreUserUserIdCallsCount += 1
        ignoreUserUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.ignoreUserUserIdReceivedInvocations.append(userId)
        }
        try await ignoreUserUserIdClosure?(userId)
    }

    //MARK: - inviteUserById

    open var inviteUserByIdUserIdThrowableError: Error?
    var inviteUserByIdUserIdUnderlyingCallsCount = 0
    open var inviteUserByIdUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return inviteUserByIdUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = inviteUserByIdUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                inviteUserByIdUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    inviteUserByIdUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var inviteUserByIdUserIdCalled: Bool {
        return inviteUserByIdUserIdCallsCount > 0
    }
    open var inviteUserByIdUserIdReceivedUserId: String?
    open var inviteUserByIdUserIdReceivedInvocations: [String] = []
    open var inviteUserByIdUserIdClosure: ((String) async throws -> Void)?

    open override func inviteUserById(userId: String) async throws {
        if let error = inviteUserByIdUserIdThrowableError {
            throw error
        }
        inviteUserByIdUserIdCallsCount += 1
        inviteUserByIdUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.inviteUserByIdUserIdReceivedInvocations.append(userId)
        }
        try await inviteUserByIdUserIdClosure?(userId)
    }

    //MARK: - invitedMembersCount

    var invitedMembersCountUnderlyingCallsCount = 0
    open var invitedMembersCountCallsCount: Int {
        get {
            if Thread.isMainThread {
                return invitedMembersCountUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = invitedMembersCountUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                invitedMembersCountUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    invitedMembersCountUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var invitedMembersCountCalled: Bool {
        return invitedMembersCountCallsCount > 0
    }

    var invitedMembersCountUnderlyingReturnValue: UInt64!
    open var invitedMembersCountReturnValue: UInt64! {
        get {
            if Thread.isMainThread {
                return invitedMembersCountUnderlyingReturnValue
            } else {
                var returnValue: UInt64? = nil
                DispatchQueue.main.sync {
                    returnValue = invitedMembersCountUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                invitedMembersCountUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    invitedMembersCountUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var invitedMembersCountClosure: (() -> UInt64)?

    open override func invitedMembersCount() -> UInt64 {
        invitedMembersCountCallsCount += 1
        if let invitedMembersCountClosure = invitedMembersCountClosure {
            return invitedMembersCountClosure()
        } else {
            return invitedMembersCountReturnValue
        }
    }

    //MARK: - inviter

    var inviterUnderlyingCallsCount = 0
    open var inviterCallsCount: Int {
        get {
            if Thread.isMainThread {
                return inviterUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = inviterUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                inviterUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    inviterUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var inviterCalled: Bool {
        return inviterCallsCount > 0
    }

    var inviterUnderlyingReturnValue: RoomMember?
    open var inviterReturnValue: RoomMember? {
        get {
            if Thread.isMainThread {
                return inviterUnderlyingReturnValue
            } else {
                var returnValue: RoomMember?? = nil
                DispatchQueue.main.sync {
                    returnValue = inviterUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                inviterUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    inviterUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var inviterClosure: (() async -> RoomMember?)?

    open override func inviter() async -> RoomMember? {
        inviterCallsCount += 1
        if let inviterClosure = inviterClosure {
            return await inviterClosure()
        } else {
            return inviterReturnValue
        }
    }

    //MARK: - isDirect

    var isDirectUnderlyingCallsCount = 0
    open var isDirectCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isDirectUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isDirectUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isDirectUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isDirectUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isDirectCalled: Bool {
        return isDirectCallsCount > 0
    }

    var isDirectUnderlyingReturnValue: Bool!
    open var isDirectReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isDirectUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isDirectUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isDirectUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isDirectUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isDirectClosure: (() -> Bool)?

    open override func isDirect() -> Bool {
        isDirectCallsCount += 1
        if let isDirectClosure = isDirectClosure {
            return isDirectClosure()
        } else {
            return isDirectReturnValue
        }
    }

    //MARK: - isEncrypted

    open var isEncryptedThrowableError: Error?
    var isEncryptedUnderlyingCallsCount = 0
    open var isEncryptedCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isEncryptedUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isEncryptedUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isEncryptedUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isEncryptedUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isEncryptedCalled: Bool {
        return isEncryptedCallsCount > 0
    }

    var isEncryptedUnderlyingReturnValue: Bool!
    open var isEncryptedReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isEncryptedUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isEncryptedUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isEncryptedUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isEncryptedUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isEncryptedClosure: (() throws -> Bool)?

    open override func isEncrypted() throws -> Bool {
        if let error = isEncryptedThrowableError {
            throw error
        }
        isEncryptedCallsCount += 1
        if let isEncryptedClosure = isEncryptedClosure {
            return try isEncryptedClosure()
        } else {
            return isEncryptedReturnValue
        }
    }

    //MARK: - isPublic

    var isPublicUnderlyingCallsCount = 0
    open var isPublicCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isPublicUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isPublicUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isPublicUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isPublicUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isPublicCalled: Bool {
        return isPublicCallsCount > 0
    }

    var isPublicUnderlyingReturnValue: Bool!
    open var isPublicReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isPublicUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isPublicUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isPublicUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isPublicUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isPublicClosure: (() -> Bool)?

    open override func isPublic() -> Bool {
        isPublicCallsCount += 1
        if let isPublicClosure = isPublicClosure {
            return isPublicClosure()
        } else {
            return isPublicReturnValue
        }
    }

    //MARK: - isSendQueueEnabled

    var isSendQueueEnabledUnderlyingCallsCount = 0
    open var isSendQueueEnabledCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isSendQueueEnabledUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isSendQueueEnabledUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isSendQueueEnabledUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isSendQueueEnabledUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isSendQueueEnabledCalled: Bool {
        return isSendQueueEnabledCallsCount > 0
    }

    var isSendQueueEnabledUnderlyingReturnValue: Bool!
    open var isSendQueueEnabledReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isSendQueueEnabledUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isSendQueueEnabledUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isSendQueueEnabledUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isSendQueueEnabledUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isSendQueueEnabledClosure: (() -> Bool)?

    open override func isSendQueueEnabled() -> Bool {
        isSendQueueEnabledCallsCount += 1
        if let isSendQueueEnabledClosure = isSendQueueEnabledClosure {
            return isSendQueueEnabledClosure()
        } else {
            return isSendQueueEnabledReturnValue
        }
    }

    //MARK: - isSpace

    var isSpaceUnderlyingCallsCount = 0
    open var isSpaceCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isSpaceUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isSpaceUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isSpaceUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isSpaceUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isSpaceCalled: Bool {
        return isSpaceCallsCount > 0
    }

    var isSpaceUnderlyingReturnValue: Bool!
    open var isSpaceReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isSpaceUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isSpaceUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isSpaceUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isSpaceUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isSpaceClosure: (() -> Bool)?

    open override func isSpace() -> Bool {
        isSpaceCallsCount += 1
        if let isSpaceClosure = isSpaceClosure {
            return isSpaceClosure()
        } else {
            return isSpaceReturnValue
        }
    }

    //MARK: - isTombstoned

    var isTombstonedUnderlyingCallsCount = 0
    open var isTombstonedCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isTombstonedUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isTombstonedUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isTombstonedUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isTombstonedUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isTombstonedCalled: Bool {
        return isTombstonedCallsCount > 0
    }

    var isTombstonedUnderlyingReturnValue: Bool!
    open var isTombstonedReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isTombstonedUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isTombstonedUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isTombstonedUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isTombstonedUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isTombstonedClosure: (() -> Bool)?

    open override func isTombstoned() -> Bool {
        isTombstonedCallsCount += 1
        if let isTombstonedClosure = isTombstonedClosure {
            return isTombstonedClosure()
        } else {
            return isTombstonedReturnValue
        }
    }

    //MARK: - join

    open var joinThrowableError: Error?
    var joinUnderlyingCallsCount = 0
    open var joinCallsCount: Int {
        get {
            if Thread.isMainThread {
                return joinUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = joinUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    joinUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var joinCalled: Bool {
        return joinCallsCount > 0
    }
    open var joinClosure: (() async throws -> Void)?

    open override func join() async throws {
        if let error = joinThrowableError {
            throw error
        }
        joinCallsCount += 1
        try await joinClosure?()
    }

    //MARK: - joinedMembersCount

    var joinedMembersCountUnderlyingCallsCount = 0
    open var joinedMembersCountCallsCount: Int {
        get {
            if Thread.isMainThread {
                return joinedMembersCountUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = joinedMembersCountUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinedMembersCountUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    joinedMembersCountUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var joinedMembersCountCalled: Bool {
        return joinedMembersCountCallsCount > 0
    }

    var joinedMembersCountUnderlyingReturnValue: UInt64!
    open var joinedMembersCountReturnValue: UInt64! {
        get {
            if Thread.isMainThread {
                return joinedMembersCountUnderlyingReturnValue
            } else {
                var returnValue: UInt64? = nil
                DispatchQueue.main.sync {
                    returnValue = joinedMembersCountUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinedMembersCountUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    joinedMembersCountUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var joinedMembersCountClosure: (() -> UInt64)?

    open override func joinedMembersCount() -> UInt64 {
        joinedMembersCountCallsCount += 1
        if let joinedMembersCountClosure = joinedMembersCountClosure {
            return joinedMembersCountClosure()
        } else {
            return joinedMembersCountReturnValue
        }
    }

    //MARK: - kickUser

    open var kickUserUserIdReasonThrowableError: Error?
    var kickUserUserIdReasonUnderlyingCallsCount = 0
    open var kickUserUserIdReasonCallsCount: Int {
        get {
            if Thread.isMainThread {
                return kickUserUserIdReasonUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = kickUserUserIdReasonUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                kickUserUserIdReasonUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    kickUserUserIdReasonUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var kickUserUserIdReasonCalled: Bool {
        return kickUserUserIdReasonCallsCount > 0
    }
    open var kickUserUserIdReasonReceivedArguments: (userId: String, reason: String?)?
    open var kickUserUserIdReasonReceivedInvocations: [(userId: String, reason: String?)] = []
    open var kickUserUserIdReasonClosure: ((String, String?) async throws -> Void)?

    open override func kickUser(userId: String, reason: String?) async throws {
        if let error = kickUserUserIdReasonThrowableError {
            throw error
        }
        kickUserUserIdReasonCallsCount += 1
        kickUserUserIdReasonReceivedArguments = (userId: userId, reason: reason)
        DispatchQueue.main.async {
            self.kickUserUserIdReasonReceivedInvocations.append((userId: userId, reason: reason))
        }
        try await kickUserUserIdReasonClosure?(userId, reason)
    }

    //MARK: - leave

    open var leaveThrowableError: Error?
    var leaveUnderlyingCallsCount = 0
    open var leaveCallsCount: Int {
        get {
            if Thread.isMainThread {
                return leaveUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = leaveUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                leaveUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    leaveUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var leaveCalled: Bool {
        return leaveCallsCount > 0
    }
    open var leaveClosure: (() async throws -> Void)?

    open override func leave() async throws {
        if let error = leaveThrowableError {
            throw error
        }
        leaveCallsCount += 1
        try await leaveClosure?()
    }

    //MARK: - loadComposerDraft

    open var loadComposerDraftThrowableError: Error?
    var loadComposerDraftUnderlyingCallsCount = 0
    open var loadComposerDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadComposerDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadComposerDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadComposerDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadComposerDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var loadComposerDraftCalled: Bool {
        return loadComposerDraftCallsCount > 0
    }

    var loadComposerDraftUnderlyingReturnValue: ComposerDraft?
    open var loadComposerDraftReturnValue: ComposerDraft? {
        get {
            if Thread.isMainThread {
                return loadComposerDraftUnderlyingReturnValue
            } else {
                var returnValue: ComposerDraft?? = nil
                DispatchQueue.main.sync {
                    returnValue = loadComposerDraftUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadComposerDraftUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadComposerDraftUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var loadComposerDraftClosure: (() async throws -> ComposerDraft?)?

    open override func loadComposerDraft() async throws -> ComposerDraft? {
        if let error = loadComposerDraftThrowableError {
            throw error
        }
        loadComposerDraftCallsCount += 1
        if let loadComposerDraftClosure = loadComposerDraftClosure {
            return try await loadComposerDraftClosure()
        } else {
            return loadComposerDraftReturnValue
        }
    }

    //MARK: - markAsRead

    open var markAsReadReceiptTypeThrowableError: Error?
    var markAsReadReceiptTypeUnderlyingCallsCount = 0
    open var markAsReadReceiptTypeCallsCount: Int {
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
    open var markAsReadReceiptTypeCalled: Bool {
        return markAsReadReceiptTypeCallsCount > 0
    }
    open var markAsReadReceiptTypeReceivedReceiptType: ReceiptType?
    open var markAsReadReceiptTypeReceivedInvocations: [ReceiptType] = []
    open var markAsReadReceiptTypeClosure: ((ReceiptType) async throws -> Void)?

    open override func markAsRead(receiptType: ReceiptType) async throws {
        if let error = markAsReadReceiptTypeThrowableError {
            throw error
        }
        markAsReadReceiptTypeCallsCount += 1
        markAsReadReceiptTypeReceivedReceiptType = receiptType
        DispatchQueue.main.async {
            self.markAsReadReceiptTypeReceivedInvocations.append(receiptType)
        }
        try await markAsReadReceiptTypeClosure?(receiptType)
    }

    //MARK: - matrixToEventPermalink

    open var matrixToEventPermalinkEventIdThrowableError: Error?
    var matrixToEventPermalinkEventIdUnderlyingCallsCount = 0
    open var matrixToEventPermalinkEventIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return matrixToEventPermalinkEventIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = matrixToEventPermalinkEventIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                matrixToEventPermalinkEventIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    matrixToEventPermalinkEventIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var matrixToEventPermalinkEventIdCalled: Bool {
        return matrixToEventPermalinkEventIdCallsCount > 0
    }
    open var matrixToEventPermalinkEventIdReceivedEventId: String?
    open var matrixToEventPermalinkEventIdReceivedInvocations: [String] = []

    var matrixToEventPermalinkEventIdUnderlyingReturnValue: String!
    open var matrixToEventPermalinkEventIdReturnValue: String! {
        get {
            if Thread.isMainThread {
                return matrixToEventPermalinkEventIdUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = matrixToEventPermalinkEventIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                matrixToEventPermalinkEventIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    matrixToEventPermalinkEventIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var matrixToEventPermalinkEventIdClosure: ((String) async throws -> String)?

    open override func matrixToEventPermalink(eventId: String) async throws -> String {
        if let error = matrixToEventPermalinkEventIdThrowableError {
            throw error
        }
        matrixToEventPermalinkEventIdCallsCount += 1
        matrixToEventPermalinkEventIdReceivedEventId = eventId
        DispatchQueue.main.async {
            self.matrixToEventPermalinkEventIdReceivedInvocations.append(eventId)
        }
        if let matrixToEventPermalinkEventIdClosure = matrixToEventPermalinkEventIdClosure {
            return try await matrixToEventPermalinkEventIdClosure(eventId)
        } else {
            return matrixToEventPermalinkEventIdReturnValue
        }
    }

    //MARK: - matrixToPermalink

    open var matrixToPermalinkThrowableError: Error?
    var matrixToPermalinkUnderlyingCallsCount = 0
    open var matrixToPermalinkCallsCount: Int {
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
    open var matrixToPermalinkCalled: Bool {
        return matrixToPermalinkCallsCount > 0
    }

    var matrixToPermalinkUnderlyingReturnValue: String!
    open var matrixToPermalinkReturnValue: String! {
        get {
            if Thread.isMainThread {
                return matrixToPermalinkUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
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
    open var matrixToPermalinkClosure: (() async throws -> String)?

    open override func matrixToPermalink() async throws -> String {
        if let error = matrixToPermalinkThrowableError {
            throw error
        }
        matrixToPermalinkCallsCount += 1
        if let matrixToPermalinkClosure = matrixToPermalinkClosure {
            return try await matrixToPermalinkClosure()
        } else {
            return matrixToPermalinkReturnValue
        }
    }

    //MARK: - member

    open var memberUserIdThrowableError: Error?
    var memberUserIdUnderlyingCallsCount = 0
    open var memberUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return memberUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = memberUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                memberUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    memberUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var memberUserIdCalled: Bool {
        return memberUserIdCallsCount > 0
    }
    open var memberUserIdReceivedUserId: String?
    open var memberUserIdReceivedInvocations: [String] = []

    var memberUserIdUnderlyingReturnValue: RoomMember!
    open var memberUserIdReturnValue: RoomMember! {
        get {
            if Thread.isMainThread {
                return memberUserIdUnderlyingReturnValue
            } else {
                var returnValue: RoomMember? = nil
                DispatchQueue.main.sync {
                    returnValue = memberUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                memberUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    memberUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var memberUserIdClosure: ((String) async throws -> RoomMember)?

    open override func member(userId: String) async throws -> RoomMember {
        if let error = memberUserIdThrowableError {
            throw error
        }
        memberUserIdCallsCount += 1
        memberUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.memberUserIdReceivedInvocations.append(userId)
        }
        if let memberUserIdClosure = memberUserIdClosure {
            return try await memberUserIdClosure(userId)
        } else {
            return memberUserIdReturnValue
        }
    }

    //MARK: - memberAvatarUrl

    open var memberAvatarUrlUserIdThrowableError: Error?
    var memberAvatarUrlUserIdUnderlyingCallsCount = 0
    open var memberAvatarUrlUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return memberAvatarUrlUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = memberAvatarUrlUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                memberAvatarUrlUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    memberAvatarUrlUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var memberAvatarUrlUserIdCalled: Bool {
        return memberAvatarUrlUserIdCallsCount > 0
    }
    open var memberAvatarUrlUserIdReceivedUserId: String?
    open var memberAvatarUrlUserIdReceivedInvocations: [String] = []

    var memberAvatarUrlUserIdUnderlyingReturnValue: String?
    open var memberAvatarUrlUserIdReturnValue: String? {
        get {
            if Thread.isMainThread {
                return memberAvatarUrlUserIdUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = memberAvatarUrlUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                memberAvatarUrlUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    memberAvatarUrlUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var memberAvatarUrlUserIdClosure: ((String) async throws -> String?)?

    open override func memberAvatarUrl(userId: String) async throws -> String? {
        if let error = memberAvatarUrlUserIdThrowableError {
            throw error
        }
        memberAvatarUrlUserIdCallsCount += 1
        memberAvatarUrlUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.memberAvatarUrlUserIdReceivedInvocations.append(userId)
        }
        if let memberAvatarUrlUserIdClosure = memberAvatarUrlUserIdClosure {
            return try await memberAvatarUrlUserIdClosure(userId)
        } else {
            return memberAvatarUrlUserIdReturnValue
        }
    }

    //MARK: - memberDisplayName

    open var memberDisplayNameUserIdThrowableError: Error?
    var memberDisplayNameUserIdUnderlyingCallsCount = 0
    open var memberDisplayNameUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return memberDisplayNameUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = memberDisplayNameUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                memberDisplayNameUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    memberDisplayNameUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var memberDisplayNameUserIdCalled: Bool {
        return memberDisplayNameUserIdCallsCount > 0
    }
    open var memberDisplayNameUserIdReceivedUserId: String?
    open var memberDisplayNameUserIdReceivedInvocations: [String] = []

    var memberDisplayNameUserIdUnderlyingReturnValue: String?
    open var memberDisplayNameUserIdReturnValue: String? {
        get {
            if Thread.isMainThread {
                return memberDisplayNameUserIdUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = memberDisplayNameUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                memberDisplayNameUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    memberDisplayNameUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var memberDisplayNameUserIdClosure: ((String) async throws -> String?)?

    open override func memberDisplayName(userId: String) async throws -> String? {
        if let error = memberDisplayNameUserIdThrowableError {
            throw error
        }
        memberDisplayNameUserIdCallsCount += 1
        memberDisplayNameUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.memberDisplayNameUserIdReceivedInvocations.append(userId)
        }
        if let memberDisplayNameUserIdClosure = memberDisplayNameUserIdClosure {
            return try await memberDisplayNameUserIdClosure(userId)
        } else {
            return memberDisplayNameUserIdReturnValue
        }
    }

    //MARK: - members

    open var membersThrowableError: Error?
    var membersUnderlyingCallsCount = 0
    open var membersCallsCount: Int {
        get {
            if Thread.isMainThread {
                return membersUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = membersUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                membersUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    membersUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var membersCalled: Bool {
        return membersCallsCount > 0
    }

    var membersUnderlyingReturnValue: RoomMembersIterator!
    open var membersReturnValue: RoomMembersIterator! {
        get {
            if Thread.isMainThread {
                return membersUnderlyingReturnValue
            } else {
                var returnValue: RoomMembersIterator? = nil
                DispatchQueue.main.sync {
                    returnValue = membersUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                membersUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    membersUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var membersClosure: (() async throws -> RoomMembersIterator)?

    open override func members() async throws -> RoomMembersIterator {
        if let error = membersThrowableError {
            throw error
        }
        membersCallsCount += 1
        if let membersClosure = membersClosure {
            return try await membersClosure()
        } else {
            return membersReturnValue
        }
    }

    //MARK: - membersNoSync

    open var membersNoSyncThrowableError: Error?
    var membersNoSyncUnderlyingCallsCount = 0
    open var membersNoSyncCallsCount: Int {
        get {
            if Thread.isMainThread {
                return membersNoSyncUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = membersNoSyncUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                membersNoSyncUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    membersNoSyncUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var membersNoSyncCalled: Bool {
        return membersNoSyncCallsCount > 0
    }

    var membersNoSyncUnderlyingReturnValue: RoomMembersIterator!
    open var membersNoSyncReturnValue: RoomMembersIterator! {
        get {
            if Thread.isMainThread {
                return membersNoSyncUnderlyingReturnValue
            } else {
                var returnValue: RoomMembersIterator? = nil
                DispatchQueue.main.sync {
                    returnValue = membersNoSyncUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                membersNoSyncUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    membersNoSyncUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var membersNoSyncClosure: (() async throws -> RoomMembersIterator)?

    open override func membersNoSync() async throws -> RoomMembersIterator {
        if let error = membersNoSyncThrowableError {
            throw error
        }
        membersNoSyncCallsCount += 1
        if let membersNoSyncClosure = membersNoSyncClosure {
            return try await membersNoSyncClosure()
        } else {
            return membersNoSyncReturnValue
        }
    }

    //MARK: - membership

    var membershipUnderlyingCallsCount = 0
    open var membershipCallsCount: Int {
        get {
            if Thread.isMainThread {
                return membershipUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = membershipUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                membershipUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    membershipUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var membershipCalled: Bool {
        return membershipCallsCount > 0
    }

    var membershipUnderlyingReturnValue: Membership!
    open var membershipReturnValue: Membership! {
        get {
            if Thread.isMainThread {
                return membershipUnderlyingReturnValue
            } else {
                var returnValue: Membership? = nil
                DispatchQueue.main.sync {
                    returnValue = membershipUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                membershipUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    membershipUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var membershipClosure: (() -> Membership)?

    open override func membership() -> Membership {
        membershipCallsCount += 1
        if let membershipClosure = membershipClosure {
            return membershipClosure()
        } else {
            return membershipReturnValue
        }
    }

    //MARK: - ownUserId

    var ownUserIdUnderlyingCallsCount = 0
    open var ownUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return ownUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = ownUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ownUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    ownUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var ownUserIdCalled: Bool {
        return ownUserIdCallsCount > 0
    }

    var ownUserIdUnderlyingReturnValue: String!
    open var ownUserIdReturnValue: String! {
        get {
            if Thread.isMainThread {
                return ownUserIdUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = ownUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                ownUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    ownUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var ownUserIdClosure: (() -> String)?

    open override func ownUserId() -> String {
        ownUserIdCallsCount += 1
        if let ownUserIdClosure = ownUserIdClosure {
            return ownUserIdClosure()
        } else {
            return ownUserIdReturnValue
        }
    }

    //MARK: - pinnedEventsTimeline

    open var pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsThrowableError: Error?
    var pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsUnderlyingCallsCount = 0
    open var pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsCalled: Bool {
        return pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsCallsCount > 0
    }
    open var pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsReceivedArguments: (internalIdPrefix: String?, maxEventsToLoad: UInt16, maxConcurrentRequests: UInt16)?
    open var pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsReceivedInvocations: [(internalIdPrefix: String?, maxEventsToLoad: UInt16, maxConcurrentRequests: UInt16)] = []

    var pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsUnderlyingReturnValue: Timeline!
    open var pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsReturnValue: Timeline! {
        get {
            if Thread.isMainThread {
                return pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsUnderlyingReturnValue
            } else {
                var returnValue: Timeline? = nil
                DispatchQueue.main.sync {
                    returnValue = pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsClosure: ((String?, UInt16, UInt16) async throws -> Timeline)?

    open override func pinnedEventsTimeline(internalIdPrefix: String?, maxEventsToLoad: UInt16, maxConcurrentRequests: UInt16) async throws -> Timeline {
        if let error = pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsThrowableError {
            throw error
        }
        pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsCallsCount += 1
        pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsReceivedArguments = (internalIdPrefix: internalIdPrefix, maxEventsToLoad: maxEventsToLoad, maxConcurrentRequests: maxConcurrentRequests)
        DispatchQueue.main.async {
            self.pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsReceivedInvocations.append((internalIdPrefix: internalIdPrefix, maxEventsToLoad: maxEventsToLoad, maxConcurrentRequests: maxConcurrentRequests))
        }
        if let pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsClosure = pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsClosure {
            return try await pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsClosure(internalIdPrefix, maxEventsToLoad, maxConcurrentRequests)
        } else {
            return pinnedEventsTimelineInternalIdPrefixMaxEventsToLoadMaxConcurrentRequestsReturnValue
        }
    }

    //MARK: - rawName

    var rawNameUnderlyingCallsCount = 0
    open var rawNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return rawNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = rawNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                rawNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    rawNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var rawNameCalled: Bool {
        return rawNameCallsCount > 0
    }

    var rawNameUnderlyingReturnValue: String?
    open var rawNameReturnValue: String? {
        get {
            if Thread.isMainThread {
                return rawNameUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = rawNameUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                rawNameUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    rawNameUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var rawNameClosure: (() -> String?)?

    open override func rawName() -> String? {
        rawNameCallsCount += 1
        if let rawNameClosure = rawNameClosure {
            return rawNameClosure()
        } else {
            return rawNameReturnValue
        }
    }

    //MARK: - redact

    open var redactEventIdReasonThrowableError: Error?
    var redactEventIdReasonUnderlyingCallsCount = 0
    open var redactEventIdReasonCallsCount: Int {
        get {
            if Thread.isMainThread {
                return redactEventIdReasonUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = redactEventIdReasonUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                redactEventIdReasonUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    redactEventIdReasonUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var redactEventIdReasonCalled: Bool {
        return redactEventIdReasonCallsCount > 0
    }
    open var redactEventIdReasonReceivedArguments: (eventId: String, reason: String?)?
    open var redactEventIdReasonReceivedInvocations: [(eventId: String, reason: String?)] = []
    open var redactEventIdReasonClosure: ((String, String?) async throws -> Void)?

    open override func redact(eventId: String, reason: String?) async throws {
        if let error = redactEventIdReasonThrowableError {
            throw error
        }
        redactEventIdReasonCallsCount += 1
        redactEventIdReasonReceivedArguments = (eventId: eventId, reason: reason)
        DispatchQueue.main.async {
            self.redactEventIdReasonReceivedInvocations.append((eventId: eventId, reason: reason))
        }
        try await redactEventIdReasonClosure?(eventId, reason)
    }

    //MARK: - removeAvatar

    open var removeAvatarThrowableError: Error?
    var removeAvatarUnderlyingCallsCount = 0
    open var removeAvatarCallsCount: Int {
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
    open var removeAvatarCalled: Bool {
        return removeAvatarCallsCount > 0
    }
    open var removeAvatarClosure: (() async throws -> Void)?

    open override func removeAvatar() async throws {
        if let error = removeAvatarThrowableError {
            throw error
        }
        removeAvatarCallsCount += 1
        try await removeAvatarClosure?()
    }

    //MARK: - reportContent

    open var reportContentEventIdScoreReasonThrowableError: Error?
    var reportContentEventIdScoreReasonUnderlyingCallsCount = 0
    open var reportContentEventIdScoreReasonCallsCount: Int {
        get {
            if Thread.isMainThread {
                return reportContentEventIdScoreReasonUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = reportContentEventIdScoreReasonUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                reportContentEventIdScoreReasonUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    reportContentEventIdScoreReasonUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var reportContentEventIdScoreReasonCalled: Bool {
        return reportContentEventIdScoreReasonCallsCount > 0
    }
    open var reportContentEventIdScoreReasonReceivedArguments: (eventId: String, score: Int32?, reason: String?)?
    open var reportContentEventIdScoreReasonReceivedInvocations: [(eventId: String, score: Int32?, reason: String?)] = []
    open var reportContentEventIdScoreReasonClosure: ((String, Int32?, String?) async throws -> Void)?

    open override func reportContent(eventId: String, score: Int32?, reason: String?) async throws {
        if let error = reportContentEventIdScoreReasonThrowableError {
            throw error
        }
        reportContentEventIdScoreReasonCallsCount += 1
        reportContentEventIdScoreReasonReceivedArguments = (eventId: eventId, score: score, reason: reason)
        DispatchQueue.main.async {
            self.reportContentEventIdScoreReasonReceivedInvocations.append((eventId: eventId, score: score, reason: reason))
        }
        try await reportContentEventIdScoreReasonClosure?(eventId, score, reason)
    }

    //MARK: - resetPowerLevels

    open var resetPowerLevelsThrowableError: Error?
    var resetPowerLevelsUnderlyingCallsCount = 0
    open var resetPowerLevelsCallsCount: Int {
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
    open var resetPowerLevelsCalled: Bool {
        return resetPowerLevelsCallsCount > 0
    }

    var resetPowerLevelsUnderlyingReturnValue: RoomPowerLevels!
    open var resetPowerLevelsReturnValue: RoomPowerLevels! {
        get {
            if Thread.isMainThread {
                return resetPowerLevelsUnderlyingReturnValue
            } else {
                var returnValue: RoomPowerLevels? = nil
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
    open var resetPowerLevelsClosure: (() async throws -> RoomPowerLevels)?

    open override func resetPowerLevels() async throws -> RoomPowerLevels {
        if let error = resetPowerLevelsThrowableError {
            throw error
        }
        resetPowerLevelsCallsCount += 1
        if let resetPowerLevelsClosure = resetPowerLevelsClosure {
            return try await resetPowerLevelsClosure()
        } else {
            return resetPowerLevelsReturnValue
        }
    }

    //MARK: - roomInfo

    open var roomInfoThrowableError: Error?
    var roomInfoUnderlyingCallsCount = 0
    open var roomInfoCallsCount: Int {
        get {
            if Thread.isMainThread {
                return roomInfoUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = roomInfoUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomInfoUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    roomInfoUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var roomInfoCalled: Bool {
        return roomInfoCallsCount > 0
    }

    var roomInfoUnderlyingReturnValue: RoomInfo!
    open var roomInfoReturnValue: RoomInfo! {
        get {
            if Thread.isMainThread {
                return roomInfoUnderlyingReturnValue
            } else {
                var returnValue: RoomInfo? = nil
                DispatchQueue.main.sync {
                    returnValue = roomInfoUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomInfoUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    roomInfoUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var roomInfoClosure: (() async throws -> RoomInfo)?

    open override func roomInfo() async throws -> RoomInfo {
        if let error = roomInfoThrowableError {
            throw error
        }
        roomInfoCallsCount += 1
        if let roomInfoClosure = roomInfoClosure {
            return try await roomInfoClosure()
        } else {
            return roomInfoReturnValue
        }
    }

    //MARK: - saveComposerDraft

    open var saveComposerDraftDraftThrowableError: Error?
    var saveComposerDraftDraftUnderlyingCallsCount = 0
    open var saveComposerDraftDraftCallsCount: Int {
        get {
            if Thread.isMainThread {
                return saveComposerDraftDraftUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = saveComposerDraftDraftUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                saveComposerDraftDraftUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    saveComposerDraftDraftUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var saveComposerDraftDraftCalled: Bool {
        return saveComposerDraftDraftCallsCount > 0
    }
    open var saveComposerDraftDraftReceivedDraft: ComposerDraft?
    open var saveComposerDraftDraftReceivedInvocations: [ComposerDraft] = []
    open var saveComposerDraftDraftClosure: ((ComposerDraft) async throws -> Void)?

    open override func saveComposerDraft(draft: ComposerDraft) async throws {
        if let error = saveComposerDraftDraftThrowableError {
            throw error
        }
        saveComposerDraftDraftCallsCount += 1
        saveComposerDraftDraftReceivedDraft = draft
        DispatchQueue.main.async {
            self.saveComposerDraftDraftReceivedInvocations.append(draft)
        }
        try await saveComposerDraftDraftClosure?(draft)
    }

    //MARK: - sendCallNotification

    open var sendCallNotificationCallIdApplicationNotifyTypeMentionsThrowableError: Error?
    var sendCallNotificationCallIdApplicationNotifyTypeMentionsUnderlyingCallsCount = 0
    open var sendCallNotificationCallIdApplicationNotifyTypeMentionsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendCallNotificationCallIdApplicationNotifyTypeMentionsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendCallNotificationCallIdApplicationNotifyTypeMentionsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendCallNotificationCallIdApplicationNotifyTypeMentionsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendCallNotificationCallIdApplicationNotifyTypeMentionsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendCallNotificationCallIdApplicationNotifyTypeMentionsCalled: Bool {
        return sendCallNotificationCallIdApplicationNotifyTypeMentionsCallsCount > 0
    }
    open var sendCallNotificationCallIdApplicationNotifyTypeMentionsReceivedArguments: (callId: String, application: RtcApplicationType, notifyType: NotifyType, mentions: Mentions)?
    open var sendCallNotificationCallIdApplicationNotifyTypeMentionsReceivedInvocations: [(callId: String, application: RtcApplicationType, notifyType: NotifyType, mentions: Mentions)] = []
    open var sendCallNotificationCallIdApplicationNotifyTypeMentionsClosure: ((String, RtcApplicationType, NotifyType, Mentions) async throws -> Void)?

    open override func sendCallNotification(callId: String, application: RtcApplicationType, notifyType: NotifyType, mentions: Mentions) async throws {
        if let error = sendCallNotificationCallIdApplicationNotifyTypeMentionsThrowableError {
            throw error
        }
        sendCallNotificationCallIdApplicationNotifyTypeMentionsCallsCount += 1
        sendCallNotificationCallIdApplicationNotifyTypeMentionsReceivedArguments = (callId: callId, application: application, notifyType: notifyType, mentions: mentions)
        DispatchQueue.main.async {
            self.sendCallNotificationCallIdApplicationNotifyTypeMentionsReceivedInvocations.append((callId: callId, application: application, notifyType: notifyType, mentions: mentions))
        }
        try await sendCallNotificationCallIdApplicationNotifyTypeMentionsClosure?(callId, application, notifyType, mentions)
    }

    //MARK: - sendCallNotificationIfNeeded

    open var sendCallNotificationIfNeededThrowableError: Error?
    var sendCallNotificationIfNeededUnderlyingCallsCount = 0
    open var sendCallNotificationIfNeededCallsCount: Int {
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
    open var sendCallNotificationIfNeededCalled: Bool {
        return sendCallNotificationIfNeededCallsCount > 0
    }
    open var sendCallNotificationIfNeededClosure: (() async throws -> Void)?

    open override func sendCallNotificationIfNeeded() async throws {
        if let error = sendCallNotificationIfNeededThrowableError {
            throw error
        }
        sendCallNotificationIfNeededCallsCount += 1
        try await sendCallNotificationIfNeededClosure?()
    }

    //MARK: - setIsFavourite

    open var setIsFavouriteIsFavouriteTagOrderThrowableError: Error?
    var setIsFavouriteIsFavouriteTagOrderUnderlyingCallsCount = 0
    open var setIsFavouriteIsFavouriteTagOrderCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setIsFavouriteIsFavouriteTagOrderUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setIsFavouriteIsFavouriteTagOrderUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setIsFavouriteIsFavouriteTagOrderUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setIsFavouriteIsFavouriteTagOrderUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var setIsFavouriteIsFavouriteTagOrderCalled: Bool {
        return setIsFavouriteIsFavouriteTagOrderCallsCount > 0
    }
    open var setIsFavouriteIsFavouriteTagOrderReceivedArguments: (isFavourite: Bool, tagOrder: Double?)?
    open var setIsFavouriteIsFavouriteTagOrderReceivedInvocations: [(isFavourite: Bool, tagOrder: Double?)] = []
    open var setIsFavouriteIsFavouriteTagOrderClosure: ((Bool, Double?) async throws -> Void)?

    open override func setIsFavourite(isFavourite: Bool, tagOrder: Double?) async throws {
        if let error = setIsFavouriteIsFavouriteTagOrderThrowableError {
            throw error
        }
        setIsFavouriteIsFavouriteTagOrderCallsCount += 1
        setIsFavouriteIsFavouriteTagOrderReceivedArguments = (isFavourite: isFavourite, tagOrder: tagOrder)
        DispatchQueue.main.async {
            self.setIsFavouriteIsFavouriteTagOrderReceivedInvocations.append((isFavourite: isFavourite, tagOrder: tagOrder))
        }
        try await setIsFavouriteIsFavouriteTagOrderClosure?(isFavourite, tagOrder)
    }

    //MARK: - setIsLowPriority

    open var setIsLowPriorityIsLowPriorityTagOrderThrowableError: Error?
    var setIsLowPriorityIsLowPriorityTagOrderUnderlyingCallsCount = 0
    open var setIsLowPriorityIsLowPriorityTagOrderCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setIsLowPriorityIsLowPriorityTagOrderUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setIsLowPriorityIsLowPriorityTagOrderUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setIsLowPriorityIsLowPriorityTagOrderUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setIsLowPriorityIsLowPriorityTagOrderUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var setIsLowPriorityIsLowPriorityTagOrderCalled: Bool {
        return setIsLowPriorityIsLowPriorityTagOrderCallsCount > 0
    }
    open var setIsLowPriorityIsLowPriorityTagOrderReceivedArguments: (isLowPriority: Bool, tagOrder: Double?)?
    open var setIsLowPriorityIsLowPriorityTagOrderReceivedInvocations: [(isLowPriority: Bool, tagOrder: Double?)] = []
    open var setIsLowPriorityIsLowPriorityTagOrderClosure: ((Bool, Double?) async throws -> Void)?

    open override func setIsLowPriority(isLowPriority: Bool, tagOrder: Double?) async throws {
        if let error = setIsLowPriorityIsLowPriorityTagOrderThrowableError {
            throw error
        }
        setIsLowPriorityIsLowPriorityTagOrderCallsCount += 1
        setIsLowPriorityIsLowPriorityTagOrderReceivedArguments = (isLowPriority: isLowPriority, tagOrder: tagOrder)
        DispatchQueue.main.async {
            self.setIsLowPriorityIsLowPriorityTagOrderReceivedInvocations.append((isLowPriority: isLowPriority, tagOrder: tagOrder))
        }
        try await setIsLowPriorityIsLowPriorityTagOrderClosure?(isLowPriority, tagOrder)
    }

    //MARK: - setName

    open var setNameNameThrowableError: Error?
    var setNameNameUnderlyingCallsCount = 0
    open var setNameNameCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setNameNameUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setNameNameUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setNameNameUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setNameNameUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var setNameNameCalled: Bool {
        return setNameNameCallsCount > 0
    }
    open var setNameNameReceivedName: String?
    open var setNameNameReceivedInvocations: [String] = []
    open var setNameNameClosure: ((String) async throws -> Void)?

    open override func setName(name: String) async throws {
        if let error = setNameNameThrowableError {
            throw error
        }
        setNameNameCallsCount += 1
        setNameNameReceivedName = name
        DispatchQueue.main.async {
            self.setNameNameReceivedInvocations.append(name)
        }
        try await setNameNameClosure?(name)
    }

    //MARK: - setTopic

    open var setTopicTopicThrowableError: Error?
    var setTopicTopicUnderlyingCallsCount = 0
    open var setTopicTopicCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setTopicTopicUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setTopicTopicUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setTopicTopicUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setTopicTopicUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var setTopicTopicCalled: Bool {
        return setTopicTopicCallsCount > 0
    }
    open var setTopicTopicReceivedTopic: String?
    open var setTopicTopicReceivedInvocations: [String] = []
    open var setTopicTopicClosure: ((String) async throws -> Void)?

    open override func setTopic(topic: String) async throws {
        if let error = setTopicTopicThrowableError {
            throw error
        }
        setTopicTopicCallsCount += 1
        setTopicTopicReceivedTopic = topic
        DispatchQueue.main.async {
            self.setTopicTopicReceivedInvocations.append(topic)
        }
        try await setTopicTopicClosure?(topic)
    }

    //MARK: - setUnreadFlag

    open var setUnreadFlagNewValueThrowableError: Error?
    var setUnreadFlagNewValueUnderlyingCallsCount = 0
    open var setUnreadFlagNewValueCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setUnreadFlagNewValueUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setUnreadFlagNewValueUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setUnreadFlagNewValueUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setUnreadFlagNewValueUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var setUnreadFlagNewValueCalled: Bool {
        return setUnreadFlagNewValueCallsCount > 0
    }
    open var setUnreadFlagNewValueReceivedNewValue: Bool?
    open var setUnreadFlagNewValueReceivedInvocations: [Bool] = []
    open var setUnreadFlagNewValueClosure: ((Bool) async throws -> Void)?

    open override func setUnreadFlag(newValue: Bool) async throws {
        if let error = setUnreadFlagNewValueThrowableError {
            throw error
        }
        setUnreadFlagNewValueCallsCount += 1
        setUnreadFlagNewValueReceivedNewValue = newValue
        DispatchQueue.main.async {
            self.setUnreadFlagNewValueReceivedInvocations.append(newValue)
        }
        try await setUnreadFlagNewValueClosure?(newValue)
    }

    //MARK: - subscribeToRoomInfoUpdates

    var subscribeToRoomInfoUpdatesListenerUnderlyingCallsCount = 0
    open var subscribeToRoomInfoUpdatesListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return subscribeToRoomInfoUpdatesListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToRoomInfoUpdatesListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToRoomInfoUpdatesListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToRoomInfoUpdatesListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var subscribeToRoomInfoUpdatesListenerCalled: Bool {
        return subscribeToRoomInfoUpdatesListenerCallsCount > 0
    }
    open var subscribeToRoomInfoUpdatesListenerReceivedListener: RoomInfoListener?
    open var subscribeToRoomInfoUpdatesListenerReceivedInvocations: [RoomInfoListener] = []

    var subscribeToRoomInfoUpdatesListenerUnderlyingReturnValue: TaskHandle!
    open var subscribeToRoomInfoUpdatesListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return subscribeToRoomInfoUpdatesListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToRoomInfoUpdatesListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToRoomInfoUpdatesListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToRoomInfoUpdatesListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var subscribeToRoomInfoUpdatesListenerClosure: ((RoomInfoListener) -> TaskHandle)?

    open override func subscribeToRoomInfoUpdates(listener: RoomInfoListener) -> TaskHandle {
        subscribeToRoomInfoUpdatesListenerCallsCount += 1
        subscribeToRoomInfoUpdatesListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.subscribeToRoomInfoUpdatesListenerReceivedInvocations.append(listener)
        }
        if let subscribeToRoomInfoUpdatesListenerClosure = subscribeToRoomInfoUpdatesListenerClosure {
            return subscribeToRoomInfoUpdatesListenerClosure(listener)
        } else {
            return subscribeToRoomInfoUpdatesListenerReturnValue
        }
    }

    //MARK: - subscribeToTypingNotifications

    var subscribeToTypingNotificationsListenerUnderlyingCallsCount = 0
    open var subscribeToTypingNotificationsListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return subscribeToTypingNotificationsListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToTypingNotificationsListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToTypingNotificationsListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToTypingNotificationsListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var subscribeToTypingNotificationsListenerCalled: Bool {
        return subscribeToTypingNotificationsListenerCallsCount > 0
    }
    open var subscribeToTypingNotificationsListenerReceivedListener: TypingNotificationsListener?
    open var subscribeToTypingNotificationsListenerReceivedInvocations: [TypingNotificationsListener] = []

    var subscribeToTypingNotificationsListenerUnderlyingReturnValue: TaskHandle!
    open var subscribeToTypingNotificationsListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return subscribeToTypingNotificationsListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToTypingNotificationsListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToTypingNotificationsListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToTypingNotificationsListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var subscribeToTypingNotificationsListenerClosure: ((TypingNotificationsListener) -> TaskHandle)?

    open override func subscribeToTypingNotifications(listener: TypingNotificationsListener) -> TaskHandle {
        subscribeToTypingNotificationsListenerCallsCount += 1
        subscribeToTypingNotificationsListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.subscribeToTypingNotificationsListenerReceivedInvocations.append(listener)
        }
        if let subscribeToTypingNotificationsListenerClosure = subscribeToTypingNotificationsListenerClosure {
            return subscribeToTypingNotificationsListenerClosure(listener)
        } else {
            return subscribeToTypingNotificationsListenerReturnValue
        }
    }

    //MARK: - suggestedRoleForUser

    open var suggestedRoleForUserUserIdThrowableError: Error?
    var suggestedRoleForUserUserIdUnderlyingCallsCount = 0
    open var suggestedRoleForUserUserIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return suggestedRoleForUserUserIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = suggestedRoleForUserUserIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                suggestedRoleForUserUserIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    suggestedRoleForUserUserIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var suggestedRoleForUserUserIdCalled: Bool {
        return suggestedRoleForUserUserIdCallsCount > 0
    }
    open var suggestedRoleForUserUserIdReceivedUserId: String?
    open var suggestedRoleForUserUserIdReceivedInvocations: [String] = []

    var suggestedRoleForUserUserIdUnderlyingReturnValue: RoomMemberRole!
    open var suggestedRoleForUserUserIdReturnValue: RoomMemberRole! {
        get {
            if Thread.isMainThread {
                return suggestedRoleForUserUserIdUnderlyingReturnValue
            } else {
                var returnValue: RoomMemberRole? = nil
                DispatchQueue.main.sync {
                    returnValue = suggestedRoleForUserUserIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                suggestedRoleForUserUserIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    suggestedRoleForUserUserIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var suggestedRoleForUserUserIdClosure: ((String) async throws -> RoomMemberRole)?

    open override func suggestedRoleForUser(userId: String) async throws -> RoomMemberRole {
        if let error = suggestedRoleForUserUserIdThrowableError {
            throw error
        }
        suggestedRoleForUserUserIdCallsCount += 1
        suggestedRoleForUserUserIdReceivedUserId = userId
        DispatchQueue.main.async {
            self.suggestedRoleForUserUserIdReceivedInvocations.append(userId)
        }
        if let suggestedRoleForUserUserIdClosure = suggestedRoleForUserUserIdClosure {
            return try await suggestedRoleForUserUserIdClosure(userId)
        } else {
            return suggestedRoleForUserUserIdReturnValue
        }
    }

    //MARK: - timeline

    open var timelineThrowableError: Error?
    var timelineUnderlyingCallsCount = 0
    open var timelineCallsCount: Int {
        get {
            if Thread.isMainThread {
                return timelineUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = timelineUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                timelineUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    timelineUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var timelineCalled: Bool {
        return timelineCallsCount > 0
    }

    var timelineUnderlyingReturnValue: Timeline!
    open var timelineReturnValue: Timeline! {
        get {
            if Thread.isMainThread {
                return timelineUnderlyingReturnValue
            } else {
                var returnValue: Timeline? = nil
                DispatchQueue.main.sync {
                    returnValue = timelineUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                timelineUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    timelineUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var timelineClosure: (() async throws -> Timeline)?

    open override func timeline() async throws -> Timeline {
        if let error = timelineThrowableError {
            throw error
        }
        timelineCallsCount += 1
        if let timelineClosure = timelineClosure {
            return try await timelineClosure()
        } else {
            return timelineReturnValue
        }
    }

    //MARK: - timelineFocusedOnEvent

    open var timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixThrowableError: Error?
    var timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixUnderlyingCallsCount = 0
    open var timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixCallsCount: Int {
        get {
            if Thread.isMainThread {
                return timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixCalled: Bool {
        return timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixCallsCount > 0
    }
    open var timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixReceivedArguments: (eventId: String, numContextEvents: UInt16, internalIdPrefix: String?)?
    open var timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixReceivedInvocations: [(eventId: String, numContextEvents: UInt16, internalIdPrefix: String?)] = []

    var timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixUnderlyingReturnValue: Timeline!
    open var timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixReturnValue: Timeline! {
        get {
            if Thread.isMainThread {
                return timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixUnderlyingReturnValue
            } else {
                var returnValue: Timeline? = nil
                DispatchQueue.main.sync {
                    returnValue = timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixClosure: ((String, UInt16, String?) async throws -> Timeline)?

    open override func timelineFocusedOnEvent(eventId: String, numContextEvents: UInt16, internalIdPrefix: String?) async throws -> Timeline {
        if let error = timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixThrowableError {
            throw error
        }
        timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixCallsCount += 1
        timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixReceivedArguments = (eventId: eventId, numContextEvents: numContextEvents, internalIdPrefix: internalIdPrefix)
        DispatchQueue.main.async {
            self.timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixReceivedInvocations.append((eventId: eventId, numContextEvents: numContextEvents, internalIdPrefix: internalIdPrefix))
        }
        if let timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixClosure = timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixClosure {
            return try await timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixClosure(eventId, numContextEvents, internalIdPrefix)
        } else {
            return timelineFocusedOnEventEventIdNumContextEventsInternalIdPrefixReturnValue
        }
    }

    //MARK: - topic

    var topicUnderlyingCallsCount = 0
    open var topicCallsCount: Int {
        get {
            if Thread.isMainThread {
                return topicUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = topicUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                topicUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    topicUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var topicCalled: Bool {
        return topicCallsCount > 0
    }

    var topicUnderlyingReturnValue: String?
    open var topicReturnValue: String? {
        get {
            if Thread.isMainThread {
                return topicUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = topicUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                topicUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    topicUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var topicClosure: (() -> String?)?

    open override func topic() -> String? {
        topicCallsCount += 1
        if let topicClosure = topicClosure {
            return topicClosure()
        } else {
            return topicReturnValue
        }
    }

    //MARK: - tryResend

    open var tryResendTransactionIdThrowableError: Error?
    var tryResendTransactionIdUnderlyingCallsCount = 0
    open var tryResendTransactionIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return tryResendTransactionIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = tryResendTransactionIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                tryResendTransactionIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    tryResendTransactionIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var tryResendTransactionIdCalled: Bool {
        return tryResendTransactionIdCallsCount > 0
    }
    open var tryResendTransactionIdReceivedTransactionId: String?
    open var tryResendTransactionIdReceivedInvocations: [String] = []
    open var tryResendTransactionIdClosure: ((String) async throws -> Void)?

    open override func tryResend(transactionId: String) async throws {
        if let error = tryResendTransactionIdThrowableError {
            throw error
        }
        tryResendTransactionIdCallsCount += 1
        tryResendTransactionIdReceivedTransactionId = transactionId
        DispatchQueue.main.async {
            self.tryResendTransactionIdReceivedInvocations.append(transactionId)
        }
        try await tryResendTransactionIdClosure?(transactionId)
    }

    //MARK: - typingNotice

    open var typingNoticeIsTypingThrowableError: Error?
    var typingNoticeIsTypingUnderlyingCallsCount = 0
    open var typingNoticeIsTypingCallsCount: Int {
        get {
            if Thread.isMainThread {
                return typingNoticeIsTypingUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = typingNoticeIsTypingUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                typingNoticeIsTypingUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    typingNoticeIsTypingUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var typingNoticeIsTypingCalled: Bool {
        return typingNoticeIsTypingCallsCount > 0
    }
    open var typingNoticeIsTypingReceivedIsTyping: Bool?
    open var typingNoticeIsTypingReceivedInvocations: [Bool] = []
    open var typingNoticeIsTypingClosure: ((Bool) async throws -> Void)?

    open override func typingNotice(isTyping: Bool) async throws {
        if let error = typingNoticeIsTypingThrowableError {
            throw error
        }
        typingNoticeIsTypingCallsCount += 1
        typingNoticeIsTypingReceivedIsTyping = isTyping
        DispatchQueue.main.async {
            self.typingNoticeIsTypingReceivedInvocations.append(isTyping)
        }
        try await typingNoticeIsTypingClosure?(isTyping)
    }

    //MARK: - unbanUser

    open var unbanUserUserIdReasonThrowableError: Error?
    var unbanUserUserIdReasonUnderlyingCallsCount = 0
    open var unbanUserUserIdReasonCallsCount: Int {
        get {
            if Thread.isMainThread {
                return unbanUserUserIdReasonUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = unbanUserUserIdReasonUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unbanUserUserIdReasonUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    unbanUserUserIdReasonUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var unbanUserUserIdReasonCalled: Bool {
        return unbanUserUserIdReasonCallsCount > 0
    }
    open var unbanUserUserIdReasonReceivedArguments: (userId: String, reason: String?)?
    open var unbanUserUserIdReasonReceivedInvocations: [(userId: String, reason: String?)] = []
    open var unbanUserUserIdReasonClosure: ((String, String?) async throws -> Void)?

    open override func unbanUser(userId: String, reason: String?) async throws {
        if let error = unbanUserUserIdReasonThrowableError {
            throw error
        }
        unbanUserUserIdReasonCallsCount += 1
        unbanUserUserIdReasonReceivedArguments = (userId: userId, reason: reason)
        DispatchQueue.main.async {
            self.unbanUserUserIdReasonReceivedInvocations.append((userId: userId, reason: reason))
        }
        try await unbanUserUserIdReasonClosure?(userId, reason)
    }

    //MARK: - updatePowerLevelsForUsers

    open var updatePowerLevelsForUsersUpdatesThrowableError: Error?
    var updatePowerLevelsForUsersUpdatesUnderlyingCallsCount = 0
    open var updatePowerLevelsForUsersUpdatesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return updatePowerLevelsForUsersUpdatesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = updatePowerLevelsForUsersUpdatesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                updatePowerLevelsForUsersUpdatesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    updatePowerLevelsForUsersUpdatesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var updatePowerLevelsForUsersUpdatesCalled: Bool {
        return updatePowerLevelsForUsersUpdatesCallsCount > 0
    }
    open var updatePowerLevelsForUsersUpdatesReceivedUpdates: [UserPowerLevelUpdate]?
    open var updatePowerLevelsForUsersUpdatesReceivedInvocations: [[UserPowerLevelUpdate]] = []
    open var updatePowerLevelsForUsersUpdatesClosure: (([UserPowerLevelUpdate]) async throws -> Void)?

    open override func updatePowerLevelsForUsers(updates: [UserPowerLevelUpdate]) async throws {
        if let error = updatePowerLevelsForUsersUpdatesThrowableError {
            throw error
        }
        updatePowerLevelsForUsersUpdatesCallsCount += 1
        updatePowerLevelsForUsersUpdatesReceivedUpdates = updates
        DispatchQueue.main.async {
            self.updatePowerLevelsForUsersUpdatesReceivedInvocations.append(updates)
        }
        try await updatePowerLevelsForUsersUpdatesClosure?(updates)
    }

    //MARK: - uploadAvatar

    open var uploadAvatarMimeTypeDataMediaInfoThrowableError: Error?
    var uploadAvatarMimeTypeDataMediaInfoUnderlyingCallsCount = 0
    open var uploadAvatarMimeTypeDataMediaInfoCallsCount: Int {
        get {
            if Thread.isMainThread {
                return uploadAvatarMimeTypeDataMediaInfoUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = uploadAvatarMimeTypeDataMediaInfoUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                uploadAvatarMimeTypeDataMediaInfoUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    uploadAvatarMimeTypeDataMediaInfoUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var uploadAvatarMimeTypeDataMediaInfoCalled: Bool {
        return uploadAvatarMimeTypeDataMediaInfoCallsCount > 0
    }
    open var uploadAvatarMimeTypeDataMediaInfoReceivedArguments: (mimeType: String, data: Data, mediaInfo: ImageInfo?)?
    open var uploadAvatarMimeTypeDataMediaInfoReceivedInvocations: [(mimeType: String, data: Data, mediaInfo: ImageInfo?)] = []
    open var uploadAvatarMimeTypeDataMediaInfoClosure: ((String, Data, ImageInfo?) async throws -> Void)?

    open override func uploadAvatar(mimeType: String, data: Data, mediaInfo: ImageInfo?) async throws {
        if let error = uploadAvatarMimeTypeDataMediaInfoThrowableError {
            throw error
        }
        uploadAvatarMimeTypeDataMediaInfoCallsCount += 1
        uploadAvatarMimeTypeDataMediaInfoReceivedArguments = (mimeType: mimeType, data: data, mediaInfo: mediaInfo)
        DispatchQueue.main.async {
            self.uploadAvatarMimeTypeDataMediaInfoReceivedInvocations.append((mimeType: mimeType, data: data, mediaInfo: mediaInfo))
        }
        try await uploadAvatarMimeTypeDataMediaInfoClosure?(mimeType, data, mediaInfo)
    }

    //MARK: - withdrawVerificationAndResend

    open var withdrawVerificationAndResendUserIdsTransactionIdThrowableError: Error?
    var withdrawVerificationAndResendUserIdsTransactionIdUnderlyingCallsCount = 0
    open var withdrawVerificationAndResendUserIdsTransactionIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return withdrawVerificationAndResendUserIdsTransactionIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = withdrawVerificationAndResendUserIdsTransactionIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                withdrawVerificationAndResendUserIdsTransactionIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    withdrawVerificationAndResendUserIdsTransactionIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var withdrawVerificationAndResendUserIdsTransactionIdCalled: Bool {
        return withdrawVerificationAndResendUserIdsTransactionIdCallsCount > 0
    }
    open var withdrawVerificationAndResendUserIdsTransactionIdReceivedArguments: (userIds: [String], transactionId: String)?
    open var withdrawVerificationAndResendUserIdsTransactionIdReceivedInvocations: [(userIds: [String], transactionId: String)] = []
    open var withdrawVerificationAndResendUserIdsTransactionIdClosure: (([String], String) async throws -> Void)?

    open override func withdrawVerificationAndResend(userIds: [String], transactionId: String) async throws {
        if let error = withdrawVerificationAndResendUserIdsTransactionIdThrowableError {
            throw error
        }
        withdrawVerificationAndResendUserIdsTransactionIdCallsCount += 1
        withdrawVerificationAndResendUserIdsTransactionIdReceivedArguments = (userIds: userIds, transactionId: transactionId)
        DispatchQueue.main.async {
            self.withdrawVerificationAndResendUserIdsTransactionIdReceivedInvocations.append((userIds: userIds, transactionId: transactionId))
        }
        try await withdrawVerificationAndResendUserIdsTransactionIdClosure?(userIds, transactionId)
    }
}
open class RoomDirectorySearchSDKMock: MatrixRustSDK.RoomDirectorySearch {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - isAtLastPage

    open var isAtLastPageThrowableError: Error?
    var isAtLastPageUnderlyingCallsCount = 0
    open var isAtLastPageCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isAtLastPageUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isAtLastPageUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isAtLastPageUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isAtLastPageUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isAtLastPageCalled: Bool {
        return isAtLastPageCallsCount > 0
    }

    var isAtLastPageUnderlyingReturnValue: Bool!
    open var isAtLastPageReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isAtLastPageUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isAtLastPageUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isAtLastPageUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isAtLastPageUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isAtLastPageClosure: (() async throws -> Bool)?

    open override func isAtLastPage() async throws -> Bool {
        if let error = isAtLastPageThrowableError {
            throw error
        }
        isAtLastPageCallsCount += 1
        if let isAtLastPageClosure = isAtLastPageClosure {
            return try await isAtLastPageClosure()
        } else {
            return isAtLastPageReturnValue
        }
    }

    //MARK: - loadedPages

    open var loadedPagesThrowableError: Error?
    var loadedPagesUnderlyingCallsCount = 0
    open var loadedPagesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadedPagesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadedPagesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadedPagesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadedPagesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var loadedPagesCalled: Bool {
        return loadedPagesCallsCount > 0
    }

    var loadedPagesUnderlyingReturnValue: UInt32!
    open var loadedPagesReturnValue: UInt32! {
        get {
            if Thread.isMainThread {
                return loadedPagesUnderlyingReturnValue
            } else {
                var returnValue: UInt32? = nil
                DispatchQueue.main.sync {
                    returnValue = loadedPagesUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadedPagesUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadedPagesUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var loadedPagesClosure: (() async throws -> UInt32)?

    open override func loadedPages() async throws -> UInt32 {
        if let error = loadedPagesThrowableError {
            throw error
        }
        loadedPagesCallsCount += 1
        if let loadedPagesClosure = loadedPagesClosure {
            return try await loadedPagesClosure()
        } else {
            return loadedPagesReturnValue
        }
    }

    //MARK: - nextPage

    open var nextPageThrowableError: Error?
    var nextPageUnderlyingCallsCount = 0
    open var nextPageCallsCount: Int {
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
    open var nextPageCalled: Bool {
        return nextPageCallsCount > 0
    }
    open var nextPageClosure: (() async throws -> Void)?

    open override func nextPage() async throws {
        if let error = nextPageThrowableError {
            throw error
        }
        nextPageCallsCount += 1
        try await nextPageClosure?()
    }

    //MARK: - results

    var resultsListenerUnderlyingCallsCount = 0
    open var resultsListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resultsListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resultsListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resultsListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resultsListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var resultsListenerCalled: Bool {
        return resultsListenerCallsCount > 0
    }
    open var resultsListenerReceivedListener: RoomDirectorySearchEntriesListener?
    open var resultsListenerReceivedInvocations: [RoomDirectorySearchEntriesListener] = []

    var resultsListenerUnderlyingReturnValue: TaskHandle!
    open var resultsListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return resultsListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = resultsListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resultsListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    resultsListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var resultsListenerClosure: ((RoomDirectorySearchEntriesListener) async -> TaskHandle)?

    open override func results(listener: RoomDirectorySearchEntriesListener) async -> TaskHandle {
        resultsListenerCallsCount += 1
        resultsListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.resultsListenerReceivedInvocations.append(listener)
        }
        if let resultsListenerClosure = resultsListenerClosure {
            return await resultsListenerClosure(listener)
        } else {
            return resultsListenerReturnValue
        }
    }

    //MARK: - search

    open var searchFilterBatchSizeThrowableError: Error?
    var searchFilterBatchSizeUnderlyingCallsCount = 0
    open var searchFilterBatchSizeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return searchFilterBatchSizeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = searchFilterBatchSizeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                searchFilterBatchSizeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    searchFilterBatchSizeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var searchFilterBatchSizeCalled: Bool {
        return searchFilterBatchSizeCallsCount > 0
    }
    open var searchFilterBatchSizeReceivedArguments: (filter: String?, batchSize: UInt32)?
    open var searchFilterBatchSizeReceivedInvocations: [(filter: String?, batchSize: UInt32)] = []
    open var searchFilterBatchSizeClosure: ((String?, UInt32) async throws -> Void)?

    open override func search(filter: String?, batchSize: UInt32) async throws {
        if let error = searchFilterBatchSizeThrowableError {
            throw error
        }
        searchFilterBatchSizeCallsCount += 1
        searchFilterBatchSizeReceivedArguments = (filter: filter, batchSize: batchSize)
        DispatchQueue.main.async {
            self.searchFilterBatchSizeReceivedInvocations.append((filter: filter, batchSize: batchSize))
        }
        try await searchFilterBatchSizeClosure?(filter, batchSize)
    }
}
open class RoomListSDKMock: MatrixRustSDK.RoomList {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - entries

    var entriesListenerUnderlyingCallsCount = 0
    open var entriesListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return entriesListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = entriesListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                entriesListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    entriesListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var entriesListenerCalled: Bool {
        return entriesListenerCallsCount > 0
    }
    open var entriesListenerReceivedListener: RoomListEntriesListener?
    open var entriesListenerReceivedInvocations: [RoomListEntriesListener] = []

    var entriesListenerUnderlyingReturnValue: TaskHandle!
    open var entriesListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return entriesListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = entriesListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                entriesListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    entriesListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var entriesListenerClosure: ((RoomListEntriesListener) -> TaskHandle)?

    open override func entries(listener: RoomListEntriesListener) -> TaskHandle {
        entriesListenerCallsCount += 1
        entriesListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.entriesListenerReceivedInvocations.append(listener)
        }
        if let entriesListenerClosure = entriesListenerClosure {
            return entriesListenerClosure(listener)
        } else {
            return entriesListenerReturnValue
        }
    }

    //MARK: - entriesWithDynamicAdapters

    var entriesWithDynamicAdaptersPageSizeListenerUnderlyingCallsCount = 0
    open var entriesWithDynamicAdaptersPageSizeListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return entriesWithDynamicAdaptersPageSizeListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = entriesWithDynamicAdaptersPageSizeListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                entriesWithDynamicAdaptersPageSizeListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    entriesWithDynamicAdaptersPageSizeListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var entriesWithDynamicAdaptersPageSizeListenerCalled: Bool {
        return entriesWithDynamicAdaptersPageSizeListenerCallsCount > 0
    }
    open var entriesWithDynamicAdaptersPageSizeListenerReceivedArguments: (pageSize: UInt32, listener: RoomListEntriesListener)?
    open var entriesWithDynamicAdaptersPageSizeListenerReceivedInvocations: [(pageSize: UInt32, listener: RoomListEntriesListener)] = []

    var entriesWithDynamicAdaptersPageSizeListenerUnderlyingReturnValue: RoomListEntriesWithDynamicAdaptersResult!
    open var entriesWithDynamicAdaptersPageSizeListenerReturnValue: RoomListEntriesWithDynamicAdaptersResult! {
        get {
            if Thread.isMainThread {
                return entriesWithDynamicAdaptersPageSizeListenerUnderlyingReturnValue
            } else {
                var returnValue: RoomListEntriesWithDynamicAdaptersResult? = nil
                DispatchQueue.main.sync {
                    returnValue = entriesWithDynamicAdaptersPageSizeListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                entriesWithDynamicAdaptersPageSizeListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    entriesWithDynamicAdaptersPageSizeListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var entriesWithDynamicAdaptersPageSizeListenerClosure: ((UInt32, RoomListEntriesListener) -> RoomListEntriesWithDynamicAdaptersResult)?

    open override func entriesWithDynamicAdapters(pageSize: UInt32, listener: RoomListEntriesListener) -> RoomListEntriesWithDynamicAdaptersResult {
        entriesWithDynamicAdaptersPageSizeListenerCallsCount += 1
        entriesWithDynamicAdaptersPageSizeListenerReceivedArguments = (pageSize: pageSize, listener: listener)
        DispatchQueue.main.async {
            self.entriesWithDynamicAdaptersPageSizeListenerReceivedInvocations.append((pageSize: pageSize, listener: listener))
        }
        if let entriesWithDynamicAdaptersPageSizeListenerClosure = entriesWithDynamicAdaptersPageSizeListenerClosure {
            return entriesWithDynamicAdaptersPageSizeListenerClosure(pageSize, listener)
        } else {
            return entriesWithDynamicAdaptersPageSizeListenerReturnValue
        }
    }

    //MARK: - loadingState

    open var loadingStateListenerThrowableError: Error?
    var loadingStateListenerUnderlyingCallsCount = 0
    open var loadingStateListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadingStateListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadingStateListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadingStateListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadingStateListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var loadingStateListenerCalled: Bool {
        return loadingStateListenerCallsCount > 0
    }
    open var loadingStateListenerReceivedListener: RoomListLoadingStateListener?
    open var loadingStateListenerReceivedInvocations: [RoomListLoadingStateListener] = []

    var loadingStateListenerUnderlyingReturnValue: RoomListLoadingStateResult!
    open var loadingStateListenerReturnValue: RoomListLoadingStateResult! {
        get {
            if Thread.isMainThread {
                return loadingStateListenerUnderlyingReturnValue
            } else {
                var returnValue: RoomListLoadingStateResult? = nil
                DispatchQueue.main.sync {
                    returnValue = loadingStateListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadingStateListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadingStateListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var loadingStateListenerClosure: ((RoomListLoadingStateListener) throws -> RoomListLoadingStateResult)?

    open override func loadingState(listener: RoomListLoadingStateListener) throws -> RoomListLoadingStateResult {
        if let error = loadingStateListenerThrowableError {
            throw error
        }
        loadingStateListenerCallsCount += 1
        loadingStateListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.loadingStateListenerReceivedInvocations.append(listener)
        }
        if let loadingStateListenerClosure = loadingStateListenerClosure {
            return try loadingStateListenerClosure(listener)
        } else {
            return loadingStateListenerReturnValue
        }
    }

    //MARK: - room

    open var roomRoomIdThrowableError: Error?
    var roomRoomIdUnderlyingCallsCount = 0
    open var roomRoomIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return roomRoomIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = roomRoomIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomRoomIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    roomRoomIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var roomRoomIdCalled: Bool {
        return roomRoomIdCallsCount > 0
    }
    open var roomRoomIdReceivedRoomId: String?
    open var roomRoomIdReceivedInvocations: [String] = []

    var roomRoomIdUnderlyingReturnValue: RoomListItem!
    open var roomRoomIdReturnValue: RoomListItem! {
        get {
            if Thread.isMainThread {
                return roomRoomIdUnderlyingReturnValue
            } else {
                var returnValue: RoomListItem? = nil
                DispatchQueue.main.sync {
                    returnValue = roomRoomIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomRoomIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    roomRoomIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var roomRoomIdClosure: ((String) throws -> RoomListItem)?

    open override func room(roomId: String) throws -> RoomListItem {
        if let error = roomRoomIdThrowableError {
            throw error
        }
        roomRoomIdCallsCount += 1
        roomRoomIdReceivedRoomId = roomId
        DispatchQueue.main.async {
            self.roomRoomIdReceivedInvocations.append(roomId)
        }
        if let roomRoomIdClosure = roomRoomIdClosure {
            return try roomRoomIdClosure(roomId)
        } else {
            return roomRoomIdReturnValue
        }
    }
}
open class RoomListDynamicEntriesControllerSDKMock: MatrixRustSDK.RoomListDynamicEntriesController {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - addOnePage

    var addOnePageUnderlyingCallsCount = 0
    open var addOnePageCallsCount: Int {
        get {
            if Thread.isMainThread {
                return addOnePageUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = addOnePageUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                addOnePageUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    addOnePageUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var addOnePageCalled: Bool {
        return addOnePageCallsCount > 0
    }
    open var addOnePageClosure: (() -> Void)?

    open override func addOnePage() {
        addOnePageCallsCount += 1
        addOnePageClosure?()
    }

    //MARK: - resetToOnePage

    var resetToOnePageUnderlyingCallsCount = 0
    open var resetToOnePageCallsCount: Int {
        get {
            if Thread.isMainThread {
                return resetToOnePageUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = resetToOnePageUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetToOnePageUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    resetToOnePageUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var resetToOnePageCalled: Bool {
        return resetToOnePageCallsCount > 0
    }
    open var resetToOnePageClosure: (() -> Void)?

    open override func resetToOnePage() {
        resetToOnePageCallsCount += 1
        resetToOnePageClosure?()
    }

    //MARK: - setFilter

    var setFilterKindUnderlyingCallsCount = 0
    open var setFilterKindCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setFilterKindUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setFilterKindUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setFilterKindUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setFilterKindUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var setFilterKindCalled: Bool {
        return setFilterKindCallsCount > 0
    }
    open var setFilterKindReceivedKind: RoomListEntriesDynamicFilterKind?
    open var setFilterKindReceivedInvocations: [RoomListEntriesDynamicFilterKind] = []

    var setFilterKindUnderlyingReturnValue: Bool!
    open var setFilterKindReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return setFilterKindUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = setFilterKindUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setFilterKindUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    setFilterKindUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var setFilterKindClosure: ((RoomListEntriesDynamicFilterKind) -> Bool)?

    open override func setFilter(kind: RoomListEntriesDynamicFilterKind) -> Bool {
        setFilterKindCallsCount += 1
        setFilterKindReceivedKind = kind
        DispatchQueue.main.async {
            self.setFilterKindReceivedInvocations.append(kind)
        }
        if let setFilterKindClosure = setFilterKindClosure {
            return setFilterKindClosure(kind)
        } else {
            return setFilterKindReturnValue
        }
    }
}
open class RoomListEntriesWithDynamicAdaptersResultSDKMock: MatrixRustSDK.RoomListEntriesWithDynamicAdaptersResult {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - controller

    var controllerUnderlyingCallsCount = 0
    open var controllerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return controllerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = controllerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                controllerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    controllerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var controllerCalled: Bool {
        return controllerCallsCount > 0
    }

    var controllerUnderlyingReturnValue: RoomListDynamicEntriesController!
    open var controllerReturnValue: RoomListDynamicEntriesController! {
        get {
            if Thread.isMainThread {
                return controllerUnderlyingReturnValue
            } else {
                var returnValue: RoomListDynamicEntriesController? = nil
                DispatchQueue.main.sync {
                    returnValue = controllerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                controllerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    controllerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var controllerClosure: (() -> RoomListDynamicEntriesController)?

    open override func controller() -> RoomListDynamicEntriesController {
        controllerCallsCount += 1
        if let controllerClosure = controllerClosure {
            return controllerClosure()
        } else {
            return controllerReturnValue
        }
    }

    //MARK: - entriesStream

    var entriesStreamUnderlyingCallsCount = 0
    open var entriesStreamCallsCount: Int {
        get {
            if Thread.isMainThread {
                return entriesStreamUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = entriesStreamUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                entriesStreamUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    entriesStreamUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var entriesStreamCalled: Bool {
        return entriesStreamCallsCount > 0
    }

    var entriesStreamUnderlyingReturnValue: TaskHandle!
    open var entriesStreamReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return entriesStreamUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = entriesStreamUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                entriesStreamUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    entriesStreamUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var entriesStreamClosure: (() -> TaskHandle)?

    open override func entriesStream() -> TaskHandle {
        entriesStreamCallsCount += 1
        if let entriesStreamClosure = entriesStreamClosure {
            return entriesStreamClosure()
        } else {
            return entriesStreamReturnValue
        }
    }
}
open class RoomListItemSDKMock: MatrixRustSDK.RoomListItem {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - avatarUrl

    var avatarUrlUnderlyingCallsCount = 0
    open var avatarUrlCallsCount: Int {
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
    open var avatarUrlCalled: Bool {
        return avatarUrlCallsCount > 0
    }

    var avatarUrlUnderlyingReturnValue: String?
    open var avatarUrlReturnValue: String? {
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
    open var avatarUrlClosure: (() -> String?)?

    open override func avatarUrl() -> String? {
        avatarUrlCallsCount += 1
        if let avatarUrlClosure = avatarUrlClosure {
            return avatarUrlClosure()
        } else {
            return avatarUrlReturnValue
        }
    }

    //MARK: - canonicalAlias

    var canonicalAliasUnderlyingCallsCount = 0
    open var canonicalAliasCallsCount: Int {
        get {
            if Thread.isMainThread {
                return canonicalAliasUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = canonicalAliasUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canonicalAliasUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    canonicalAliasUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var canonicalAliasCalled: Bool {
        return canonicalAliasCallsCount > 0
    }

    var canonicalAliasUnderlyingReturnValue: String?
    open var canonicalAliasReturnValue: String? {
        get {
            if Thread.isMainThread {
                return canonicalAliasUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = canonicalAliasUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                canonicalAliasUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    canonicalAliasUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var canonicalAliasClosure: (() -> String?)?

    open override func canonicalAlias() -> String? {
        canonicalAliasCallsCount += 1
        if let canonicalAliasClosure = canonicalAliasClosure {
            return canonicalAliasClosure()
        } else {
            return canonicalAliasReturnValue
        }
    }

    //MARK: - displayName

    var displayNameUnderlyingCallsCount = 0
    open var displayNameCallsCount: Int {
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
    open var displayNameCalled: Bool {
        return displayNameCallsCount > 0
    }

    var displayNameUnderlyingReturnValue: String?
    open var displayNameReturnValue: String? {
        get {
            if Thread.isMainThread {
                return displayNameUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
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
    open var displayNameClosure: (() -> String?)?

    open override func displayName() -> String? {
        displayNameCallsCount += 1
        if let displayNameClosure = displayNameClosure {
            return displayNameClosure()
        } else {
            return displayNameReturnValue
        }
    }

    //MARK: - fullRoom

    open var fullRoomThrowableError: Error?
    var fullRoomUnderlyingCallsCount = 0
    open var fullRoomCallsCount: Int {
        get {
            if Thread.isMainThread {
                return fullRoomUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = fullRoomUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                fullRoomUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    fullRoomUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var fullRoomCalled: Bool {
        return fullRoomCallsCount > 0
    }

    var fullRoomUnderlyingReturnValue: Room!
    open var fullRoomReturnValue: Room! {
        get {
            if Thread.isMainThread {
                return fullRoomUnderlyingReturnValue
            } else {
                var returnValue: Room? = nil
                DispatchQueue.main.sync {
                    returnValue = fullRoomUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                fullRoomUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    fullRoomUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var fullRoomClosure: (() throws -> Room)?

    open override func fullRoom() throws -> Room {
        if let error = fullRoomThrowableError {
            throw error
        }
        fullRoomCallsCount += 1
        if let fullRoomClosure = fullRoomClosure {
            return try fullRoomClosure()
        } else {
            return fullRoomReturnValue
        }
    }

    //MARK: - id

    var idUnderlyingCallsCount = 0
    open var idCallsCount: Int {
        get {
            if Thread.isMainThread {
                return idUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = idUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                idUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    idUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var idCalled: Bool {
        return idCallsCount > 0
    }

    var idUnderlyingReturnValue: String!
    open var idReturnValue: String! {
        get {
            if Thread.isMainThread {
                return idUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = idUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                idUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    idUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var idClosure: (() -> String)?

    open override func id() -> String {
        idCallsCount += 1
        if let idClosure = idClosure {
            return idClosure()
        } else {
            return idReturnValue
        }
    }

    //MARK: - initTimeline

    open var initTimelineEventTypeFilterInternalIdPrefixThrowableError: Error?
    var initTimelineEventTypeFilterInternalIdPrefixUnderlyingCallsCount = 0
    open var initTimelineEventTypeFilterInternalIdPrefixCallsCount: Int {
        get {
            if Thread.isMainThread {
                return initTimelineEventTypeFilterInternalIdPrefixUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = initTimelineEventTypeFilterInternalIdPrefixUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                initTimelineEventTypeFilterInternalIdPrefixUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    initTimelineEventTypeFilterInternalIdPrefixUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var initTimelineEventTypeFilterInternalIdPrefixCalled: Bool {
        return initTimelineEventTypeFilterInternalIdPrefixCallsCount > 0
    }
    open var initTimelineEventTypeFilterInternalIdPrefixReceivedArguments: (eventTypeFilter: TimelineEventTypeFilter?, internalIdPrefix: String?)?
    open var initTimelineEventTypeFilterInternalIdPrefixReceivedInvocations: [(eventTypeFilter: TimelineEventTypeFilter?, internalIdPrefix: String?)] = []
    open var initTimelineEventTypeFilterInternalIdPrefixClosure: ((TimelineEventTypeFilter?, String?) async throws -> Void)?

    open override func initTimeline(eventTypeFilter: TimelineEventTypeFilter?, internalIdPrefix: String?) async throws {
        if let error = initTimelineEventTypeFilterInternalIdPrefixThrowableError {
            throw error
        }
        initTimelineEventTypeFilterInternalIdPrefixCallsCount += 1
        initTimelineEventTypeFilterInternalIdPrefixReceivedArguments = (eventTypeFilter: eventTypeFilter, internalIdPrefix: internalIdPrefix)
        DispatchQueue.main.async {
            self.initTimelineEventTypeFilterInternalIdPrefixReceivedInvocations.append((eventTypeFilter: eventTypeFilter, internalIdPrefix: internalIdPrefix))
        }
        try await initTimelineEventTypeFilterInternalIdPrefixClosure?(eventTypeFilter, internalIdPrefix)
    }

    //MARK: - invitedRoom

    open var invitedRoomThrowableError: Error?
    var invitedRoomUnderlyingCallsCount = 0
    open var invitedRoomCallsCount: Int {
        get {
            if Thread.isMainThread {
                return invitedRoomUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = invitedRoomUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                invitedRoomUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    invitedRoomUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var invitedRoomCalled: Bool {
        return invitedRoomCallsCount > 0
    }

    var invitedRoomUnderlyingReturnValue: Room!
    open var invitedRoomReturnValue: Room! {
        get {
            if Thread.isMainThread {
                return invitedRoomUnderlyingReturnValue
            } else {
                var returnValue: Room? = nil
                DispatchQueue.main.sync {
                    returnValue = invitedRoomUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                invitedRoomUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    invitedRoomUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var invitedRoomClosure: (() throws -> Room)?

    open override func invitedRoom() throws -> Room {
        if let error = invitedRoomThrowableError {
            throw error
        }
        invitedRoomCallsCount += 1
        if let invitedRoomClosure = invitedRoomClosure {
            return try invitedRoomClosure()
        } else {
            return invitedRoomReturnValue
        }
    }

    //MARK: - isDirect

    var isDirectUnderlyingCallsCount = 0
    open var isDirectCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isDirectUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isDirectUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isDirectUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isDirectUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isDirectCalled: Bool {
        return isDirectCallsCount > 0
    }

    var isDirectUnderlyingReturnValue: Bool!
    open var isDirectReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isDirectUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isDirectUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isDirectUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isDirectUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isDirectClosure: (() -> Bool)?

    open override func isDirect() -> Bool {
        isDirectCallsCount += 1
        if let isDirectClosure = isDirectClosure {
            return isDirectClosure()
        } else {
            return isDirectReturnValue
        }
    }

    //MARK: - isEncrypted

    var isEncryptedUnderlyingCallsCount = 0
    open var isEncryptedCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isEncryptedUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isEncryptedUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isEncryptedUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isEncryptedUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isEncryptedCalled: Bool {
        return isEncryptedCallsCount > 0
    }

    var isEncryptedUnderlyingReturnValue: Bool!
    open var isEncryptedReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isEncryptedUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isEncryptedUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isEncryptedUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isEncryptedUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isEncryptedClosure: (() async -> Bool)?

    open override func isEncrypted() async -> Bool {
        isEncryptedCallsCount += 1
        if let isEncryptedClosure = isEncryptedClosure {
            return await isEncryptedClosure()
        } else {
            return isEncryptedReturnValue
        }
    }

    //MARK: - isTimelineInitialized

    var isTimelineInitializedUnderlyingCallsCount = 0
    open var isTimelineInitializedCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isTimelineInitializedUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isTimelineInitializedUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isTimelineInitializedUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isTimelineInitializedUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isTimelineInitializedCalled: Bool {
        return isTimelineInitializedCallsCount > 0
    }

    var isTimelineInitializedUnderlyingReturnValue: Bool!
    open var isTimelineInitializedReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isTimelineInitializedUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isTimelineInitializedUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isTimelineInitializedUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isTimelineInitializedUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isTimelineInitializedClosure: (() -> Bool)?

    open override func isTimelineInitialized() -> Bool {
        isTimelineInitializedCallsCount += 1
        if let isTimelineInitializedClosure = isTimelineInitializedClosure {
            return isTimelineInitializedClosure()
        } else {
            return isTimelineInitializedReturnValue
        }
    }

    //MARK: - latestEvent

    var latestEventUnderlyingCallsCount = 0
    open var latestEventCallsCount: Int {
        get {
            if Thread.isMainThread {
                return latestEventUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = latestEventUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                latestEventUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    latestEventUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var latestEventCalled: Bool {
        return latestEventCallsCount > 0
    }

    var latestEventUnderlyingReturnValue: EventTimelineItem?
    open var latestEventReturnValue: EventTimelineItem? {
        get {
            if Thread.isMainThread {
                return latestEventUnderlyingReturnValue
            } else {
                var returnValue: EventTimelineItem?? = nil
                DispatchQueue.main.sync {
                    returnValue = latestEventUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                latestEventUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    latestEventUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var latestEventClosure: (() async -> EventTimelineItem?)?

    open override func latestEvent() async -> EventTimelineItem? {
        latestEventCallsCount += 1
        if let latestEventClosure = latestEventClosure {
            return await latestEventClosure()
        } else {
            return latestEventReturnValue
        }
    }

    //MARK: - membership

    var membershipUnderlyingCallsCount = 0
    open var membershipCallsCount: Int {
        get {
            if Thread.isMainThread {
                return membershipUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = membershipUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                membershipUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    membershipUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var membershipCalled: Bool {
        return membershipCallsCount > 0
    }

    var membershipUnderlyingReturnValue: Membership!
    open var membershipReturnValue: Membership! {
        get {
            if Thread.isMainThread {
                return membershipUnderlyingReturnValue
            } else {
                var returnValue: Membership? = nil
                DispatchQueue.main.sync {
                    returnValue = membershipUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                membershipUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    membershipUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var membershipClosure: (() -> Membership)?

    open override func membership() -> Membership {
        membershipCallsCount += 1
        if let membershipClosure = membershipClosure {
            return membershipClosure()
        } else {
            return membershipReturnValue
        }
    }

    //MARK: - roomInfo

    open var roomInfoThrowableError: Error?
    var roomInfoUnderlyingCallsCount = 0
    open var roomInfoCallsCount: Int {
        get {
            if Thread.isMainThread {
                return roomInfoUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = roomInfoUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomInfoUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    roomInfoUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var roomInfoCalled: Bool {
        return roomInfoCallsCount > 0
    }

    var roomInfoUnderlyingReturnValue: RoomInfo!
    open var roomInfoReturnValue: RoomInfo! {
        get {
            if Thread.isMainThread {
                return roomInfoUnderlyingReturnValue
            } else {
                var returnValue: RoomInfo? = nil
                DispatchQueue.main.sync {
                    returnValue = roomInfoUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomInfoUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    roomInfoUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var roomInfoClosure: (() async throws -> RoomInfo)?

    open override func roomInfo() async throws -> RoomInfo {
        if let error = roomInfoThrowableError {
            throw error
        }
        roomInfoCallsCount += 1
        if let roomInfoClosure = roomInfoClosure {
            return try await roomInfoClosure()
        } else {
            return roomInfoReturnValue
        }
    }
}
open class RoomListServiceSDKMock: MatrixRustSDK.RoomListService {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - allRooms

    open var allRoomsThrowableError: Error?
    var allRoomsUnderlyingCallsCount = 0
    open var allRoomsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return allRoomsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = allRoomsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                allRoomsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    allRoomsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var allRoomsCalled: Bool {
        return allRoomsCallsCount > 0
    }

    var allRoomsUnderlyingReturnValue: RoomList!
    open var allRoomsReturnValue: RoomList! {
        get {
            if Thread.isMainThread {
                return allRoomsUnderlyingReturnValue
            } else {
                var returnValue: RoomList? = nil
                DispatchQueue.main.sync {
                    returnValue = allRoomsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                allRoomsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    allRoomsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var allRoomsClosure: (() async throws -> RoomList)?

    open override func allRooms() async throws -> RoomList {
        if let error = allRoomsThrowableError {
            throw error
        }
        allRoomsCallsCount += 1
        if let allRoomsClosure = allRoomsClosure {
            return try await allRoomsClosure()
        } else {
            return allRoomsReturnValue
        }
    }

    //MARK: - room

    open var roomRoomIdThrowableError: Error?
    var roomRoomIdUnderlyingCallsCount = 0
    open var roomRoomIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return roomRoomIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = roomRoomIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomRoomIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    roomRoomIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var roomRoomIdCalled: Bool {
        return roomRoomIdCallsCount > 0
    }
    open var roomRoomIdReceivedRoomId: String?
    open var roomRoomIdReceivedInvocations: [String] = []

    var roomRoomIdUnderlyingReturnValue: RoomListItem!
    open var roomRoomIdReturnValue: RoomListItem! {
        get {
            if Thread.isMainThread {
                return roomRoomIdUnderlyingReturnValue
            } else {
                var returnValue: RoomListItem? = nil
                DispatchQueue.main.sync {
                    returnValue = roomRoomIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomRoomIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    roomRoomIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var roomRoomIdClosure: ((String) throws -> RoomListItem)?

    open override func room(roomId: String) throws -> RoomListItem {
        if let error = roomRoomIdThrowableError {
            throw error
        }
        roomRoomIdCallsCount += 1
        roomRoomIdReceivedRoomId = roomId
        DispatchQueue.main.async {
            self.roomRoomIdReceivedInvocations.append(roomId)
        }
        if let roomRoomIdClosure = roomRoomIdClosure {
            return try roomRoomIdClosure(roomId)
        } else {
            return roomRoomIdReturnValue
        }
    }

    //MARK: - state

    var stateListenerUnderlyingCallsCount = 0
    open var stateListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return stateListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = stateListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stateListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    stateListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var stateListenerCalled: Bool {
        return stateListenerCallsCount > 0
    }
    open var stateListenerReceivedListener: RoomListServiceStateListener?
    open var stateListenerReceivedInvocations: [RoomListServiceStateListener] = []

    var stateListenerUnderlyingReturnValue: TaskHandle!
    open var stateListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return stateListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = stateListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stateListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    stateListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var stateListenerClosure: ((RoomListServiceStateListener) -> TaskHandle)?

    open override func state(listener: RoomListServiceStateListener) -> TaskHandle {
        stateListenerCallsCount += 1
        stateListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.stateListenerReceivedInvocations.append(listener)
        }
        if let stateListenerClosure = stateListenerClosure {
            return stateListenerClosure(listener)
        } else {
            return stateListenerReturnValue
        }
    }

    //MARK: - subscribeToRooms

    open var subscribeToRoomsRoomIdsSettingsThrowableError: Error?
    var subscribeToRoomsRoomIdsSettingsUnderlyingCallsCount = 0
    open var subscribeToRoomsRoomIdsSettingsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return subscribeToRoomsRoomIdsSettingsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToRoomsRoomIdsSettingsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToRoomsRoomIdsSettingsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToRoomsRoomIdsSettingsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var subscribeToRoomsRoomIdsSettingsCalled: Bool {
        return subscribeToRoomsRoomIdsSettingsCallsCount > 0
    }
    open var subscribeToRoomsRoomIdsSettingsReceivedArguments: (roomIds: [String], settings: RoomSubscription?)?
    open var subscribeToRoomsRoomIdsSettingsReceivedInvocations: [(roomIds: [String], settings: RoomSubscription?)] = []
    open var subscribeToRoomsRoomIdsSettingsClosure: (([String], RoomSubscription?) throws -> Void)?

    open override func subscribeToRooms(roomIds: [String], settings: RoomSubscription?) throws {
        if let error = subscribeToRoomsRoomIdsSettingsThrowableError {
            throw error
        }
        subscribeToRoomsRoomIdsSettingsCallsCount += 1
        subscribeToRoomsRoomIdsSettingsReceivedArguments = (roomIds: roomIds, settings: settings)
        DispatchQueue.main.async {
            self.subscribeToRoomsRoomIdsSettingsReceivedInvocations.append((roomIds: roomIds, settings: settings))
        }
        try subscribeToRoomsRoomIdsSettingsClosure?(roomIds, settings)
    }

    //MARK: - syncIndicator

    var syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerUnderlyingCallsCount = 0
    open var syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerCalled: Bool {
        return syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerCallsCount > 0
    }
    open var syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerReceivedArguments: (delayBeforeShowingInMs: UInt32, delayBeforeHidingInMs: UInt32, listener: RoomListServiceSyncIndicatorListener)?
    open var syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerReceivedInvocations: [(delayBeforeShowingInMs: UInt32, delayBeforeHidingInMs: UInt32, listener: RoomListServiceSyncIndicatorListener)] = []

    var syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerUnderlyingReturnValue: TaskHandle!
    open var syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerClosure: ((UInt32, UInt32, RoomListServiceSyncIndicatorListener) -> TaskHandle)?

    open override func syncIndicator(delayBeforeShowingInMs: UInt32, delayBeforeHidingInMs: UInt32, listener: RoomListServiceSyncIndicatorListener) -> TaskHandle {
        syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerCallsCount += 1
        syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerReceivedArguments = (delayBeforeShowingInMs: delayBeforeShowingInMs, delayBeforeHidingInMs: delayBeforeHidingInMs, listener: listener)
        DispatchQueue.main.async {
            self.syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerReceivedInvocations.append((delayBeforeShowingInMs: delayBeforeShowingInMs, delayBeforeHidingInMs: delayBeforeHidingInMs, listener: listener))
        }
        if let syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerClosure = syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerClosure {
            return syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerClosure(delayBeforeShowingInMs, delayBeforeHidingInMs, listener)
        } else {
            return syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerReturnValue
        }
    }
}
open class RoomMembersIteratorSDKMock: MatrixRustSDK.RoomMembersIterator {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - len

    var lenUnderlyingCallsCount = 0
    open var lenCallsCount: Int {
        get {
            if Thread.isMainThread {
                return lenUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = lenUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                lenUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    lenUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var lenCalled: Bool {
        return lenCallsCount > 0
    }

    var lenUnderlyingReturnValue: UInt32!
    open var lenReturnValue: UInt32! {
        get {
            if Thread.isMainThread {
                return lenUnderlyingReturnValue
            } else {
                var returnValue: UInt32? = nil
                DispatchQueue.main.sync {
                    returnValue = lenUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                lenUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    lenUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var lenClosure: (() -> UInt32)?

    open override func len() -> UInt32 {
        lenCallsCount += 1
        if let lenClosure = lenClosure {
            return lenClosure()
        } else {
            return lenReturnValue
        }
    }

    //MARK: - nextChunk

    var nextChunkChunkSizeUnderlyingCallsCount = 0
    open var nextChunkChunkSizeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return nextChunkChunkSizeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = nextChunkChunkSizeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                nextChunkChunkSizeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    nextChunkChunkSizeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var nextChunkChunkSizeCalled: Bool {
        return nextChunkChunkSizeCallsCount > 0
    }
    open var nextChunkChunkSizeReceivedChunkSize: UInt32?
    open var nextChunkChunkSizeReceivedInvocations: [UInt32] = []

    var nextChunkChunkSizeUnderlyingReturnValue: [RoomMember]?
    open var nextChunkChunkSizeReturnValue: [RoomMember]? {
        get {
            if Thread.isMainThread {
                return nextChunkChunkSizeUnderlyingReturnValue
            } else {
                var returnValue: [RoomMember]?? = nil
                DispatchQueue.main.sync {
                    returnValue = nextChunkChunkSizeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                nextChunkChunkSizeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    nextChunkChunkSizeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var nextChunkChunkSizeClosure: ((UInt32) -> [RoomMember]?)?

    open override func nextChunk(chunkSize: UInt32) -> [RoomMember]? {
        nextChunkChunkSizeCallsCount += 1
        nextChunkChunkSizeReceivedChunkSize = chunkSize
        DispatchQueue.main.async {
            self.nextChunkChunkSizeReceivedInvocations.append(chunkSize)
        }
        if let nextChunkChunkSizeClosure = nextChunkChunkSizeClosure {
            return nextChunkChunkSizeClosure(chunkSize)
        } else {
            return nextChunkChunkSizeReturnValue
        }
    }
}
open class RoomMessageEventContentWithoutRelationSDKMock: MatrixRustSDK.RoomMessageEventContentWithoutRelation {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - withMentions

    var withMentionsMentionsUnderlyingCallsCount = 0
    open var withMentionsMentionsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return withMentionsMentionsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = withMentionsMentionsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                withMentionsMentionsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    withMentionsMentionsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var withMentionsMentionsCalled: Bool {
        return withMentionsMentionsCallsCount > 0
    }
    open var withMentionsMentionsReceivedMentions: Mentions?
    open var withMentionsMentionsReceivedInvocations: [Mentions] = []

    var withMentionsMentionsUnderlyingReturnValue: RoomMessageEventContentWithoutRelation!
    open var withMentionsMentionsReturnValue: RoomMessageEventContentWithoutRelation! {
        get {
            if Thread.isMainThread {
                return withMentionsMentionsUnderlyingReturnValue
            } else {
                var returnValue: RoomMessageEventContentWithoutRelation? = nil
                DispatchQueue.main.sync {
                    returnValue = withMentionsMentionsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                withMentionsMentionsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    withMentionsMentionsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var withMentionsMentionsClosure: ((Mentions) -> RoomMessageEventContentWithoutRelation)?

    open override func withMentions(mentions: Mentions) -> RoomMessageEventContentWithoutRelation {
        withMentionsMentionsCallsCount += 1
        withMentionsMentionsReceivedMentions = mentions
        DispatchQueue.main.async {
            self.withMentionsMentionsReceivedInvocations.append(mentions)
        }
        if let withMentionsMentionsClosure = withMentionsMentionsClosure {
            return withMentionsMentionsClosure(mentions)
        } else {
            return withMentionsMentionsReturnValue
        }
    }
}
open class SendAttachmentJoinHandleSDKMock: MatrixRustSDK.SendAttachmentJoinHandle {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - cancel

    var cancelUnderlyingCallsCount = 0
    open var cancelCallsCount: Int {
        get {
            if Thread.isMainThread {
                return cancelUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = cancelUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                cancelUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    cancelUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var cancelCalled: Bool {
        return cancelCallsCount > 0
    }
    open var cancelClosure: (() -> Void)?

    open override func cancel() {
        cancelCallsCount += 1
        cancelClosure?()
    }

    //MARK: - join

    open var joinThrowableError: Error?
    var joinUnderlyingCallsCount = 0
    open var joinCallsCount: Int {
        get {
            if Thread.isMainThread {
                return joinUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = joinUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                joinUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    joinUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var joinCalled: Bool {
        return joinCallsCount > 0
    }
    open var joinClosure: (() async throws -> Void)?

    open override func join() async throws {
        if let error = joinThrowableError {
            throw error
        }
        joinCallsCount += 1
        try await joinClosure?()
    }
}
open class SendHandleSDKMock: MatrixRustSDK.SendHandle {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - abort

    open var abortThrowableError: Error?
    var abortUnderlyingCallsCount = 0
    open var abortCallsCount: Int {
        get {
            if Thread.isMainThread {
                return abortUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = abortUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                abortUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    abortUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var abortCalled: Bool {
        return abortCallsCount > 0
    }

    var abortUnderlyingReturnValue: Bool!
    open var abortReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return abortUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = abortUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                abortUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    abortUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var abortClosure: (() async throws -> Bool)?

    open override func abort() async throws -> Bool {
        if let error = abortThrowableError {
            throw error
        }
        abortCallsCount += 1
        if let abortClosure = abortClosure {
            return try await abortClosure()
        } else {
            return abortReturnValue
        }
    }
}
open class SessionVerificationControllerSDKMock: MatrixRustSDK.SessionVerificationController {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - approveVerification

    open var approveVerificationThrowableError: Error?
    var approveVerificationUnderlyingCallsCount = 0
    open var approveVerificationCallsCount: Int {
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
    open var approveVerificationCalled: Bool {
        return approveVerificationCallsCount > 0
    }
    open var approveVerificationClosure: (() async throws -> Void)?

    open override func approveVerification() async throws {
        if let error = approveVerificationThrowableError {
            throw error
        }
        approveVerificationCallsCount += 1
        try await approveVerificationClosure?()
    }

    //MARK: - cancelVerification

    open var cancelVerificationThrowableError: Error?
    var cancelVerificationUnderlyingCallsCount = 0
    open var cancelVerificationCallsCount: Int {
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
    open var cancelVerificationCalled: Bool {
        return cancelVerificationCallsCount > 0
    }
    open var cancelVerificationClosure: (() async throws -> Void)?

    open override func cancelVerification() async throws {
        if let error = cancelVerificationThrowableError {
            throw error
        }
        cancelVerificationCallsCount += 1
        try await cancelVerificationClosure?()
    }

    //MARK: - declineVerification

    open var declineVerificationThrowableError: Error?
    var declineVerificationUnderlyingCallsCount = 0
    open var declineVerificationCallsCount: Int {
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
    open var declineVerificationCalled: Bool {
        return declineVerificationCallsCount > 0
    }
    open var declineVerificationClosure: (() async throws -> Void)?

    open override func declineVerification() async throws {
        if let error = declineVerificationThrowableError {
            throw error
        }
        declineVerificationCallsCount += 1
        try await declineVerificationClosure?()
    }

    //MARK: - isVerified

    open var isVerifiedThrowableError: Error?
    var isVerifiedUnderlyingCallsCount = 0
    open var isVerifiedCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isVerifiedUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isVerifiedUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isVerifiedUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isVerifiedUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isVerifiedCalled: Bool {
        return isVerifiedCallsCount > 0
    }

    var isVerifiedUnderlyingReturnValue: Bool!
    open var isVerifiedReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isVerifiedUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isVerifiedUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isVerifiedUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isVerifiedUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isVerifiedClosure: (() async throws -> Bool)?

    open override func isVerified() async throws -> Bool {
        if let error = isVerifiedThrowableError {
            throw error
        }
        isVerifiedCallsCount += 1
        if let isVerifiedClosure = isVerifiedClosure {
            return try await isVerifiedClosure()
        } else {
            return isVerifiedReturnValue
        }
    }

    //MARK: - requestVerification

    open var requestVerificationThrowableError: Error?
    var requestVerificationUnderlyingCallsCount = 0
    open var requestVerificationCallsCount: Int {
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
    open var requestVerificationCalled: Bool {
        return requestVerificationCallsCount > 0
    }
    open var requestVerificationClosure: (() async throws -> Void)?

    open override func requestVerification() async throws {
        if let error = requestVerificationThrowableError {
            throw error
        }
        requestVerificationCallsCount += 1
        try await requestVerificationClosure?()
    }

    //MARK: - setDelegate

    var setDelegateDelegateUnderlyingCallsCount = 0
    open var setDelegateDelegateCallsCount: Int {
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
    open var setDelegateDelegateCalled: Bool {
        return setDelegateDelegateCallsCount > 0
    }
    open var setDelegateDelegateReceivedDelegate: SessionVerificationControllerDelegate?
    open var setDelegateDelegateReceivedInvocations: [SessionVerificationControllerDelegate?] = []
    open var setDelegateDelegateClosure: ((SessionVerificationControllerDelegate?) -> Void)?

    open override func setDelegate(delegate: SessionVerificationControllerDelegate?) {
        setDelegateDelegateCallsCount += 1
        setDelegateDelegateReceivedDelegate = delegate
        DispatchQueue.main.async {
            self.setDelegateDelegateReceivedInvocations.append(delegate)
        }
        setDelegateDelegateClosure?(delegate)
    }

    //MARK: - startSasVerification

    open var startSasVerificationThrowableError: Error?
    var startSasVerificationUnderlyingCallsCount = 0
    open var startSasVerificationCallsCount: Int {
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
    open var startSasVerificationCalled: Bool {
        return startSasVerificationCallsCount > 0
    }
    open var startSasVerificationClosure: (() async throws -> Void)?

    open override func startSasVerification() async throws {
        if let error = startSasVerificationThrowableError {
            throw error
        }
        startSasVerificationCallsCount += 1
        try await startSasVerificationClosure?()
    }
}
open class SessionVerificationEmojiSDKMock: MatrixRustSDK.SessionVerificationEmoji {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - description

    var descriptionUnderlyingCallsCount = 0
    open var descriptionCallsCount: Int {
        get {
            if Thread.isMainThread {
                return descriptionUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = descriptionUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                descriptionUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    descriptionUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var descriptionCalled: Bool {
        return descriptionCallsCount > 0
    }

    var descriptionUnderlyingReturnValue: String!
    open var descriptionReturnValue: String! {
        get {
            if Thread.isMainThread {
                return descriptionUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = descriptionUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                descriptionUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    descriptionUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var descriptionClosure: (() -> String)?

    open override func description() -> String {
        descriptionCallsCount += 1
        if let descriptionClosure = descriptionClosure {
            return descriptionClosure()
        } else {
            return descriptionReturnValue
        }
    }

    //MARK: - symbol

    var symbolUnderlyingCallsCount = 0
    open var symbolCallsCount: Int {
        get {
            if Thread.isMainThread {
                return symbolUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = symbolUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                symbolUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    symbolUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var symbolCalled: Bool {
        return symbolCallsCount > 0
    }

    var symbolUnderlyingReturnValue: String!
    open var symbolReturnValue: String! {
        get {
            if Thread.isMainThread {
                return symbolUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = symbolUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                symbolUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    symbolUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var symbolClosure: (() -> String)?

    open override func symbol() -> String {
        symbolCallsCount += 1
        if let symbolClosure = symbolClosure {
            return symbolClosure()
        } else {
            return symbolReturnValue
        }
    }
}
open class SpanSDKMock: MatrixRustSDK.Span {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!
    static func reset()
    {
    }

    //MARK: - enter

    var enterUnderlyingCallsCount = 0
    open var enterCallsCount: Int {
        get {
            if Thread.isMainThread {
                return enterUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = enterUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                enterUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    enterUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var enterCalled: Bool {
        return enterCallsCount > 0
    }
    open var enterClosure: (() -> Void)?

    open override func enter() {
        enterCallsCount += 1
        enterClosure?()
    }

    //MARK: - exit

    var exitUnderlyingCallsCount = 0
    open var exitCallsCount: Int {
        get {
            if Thread.isMainThread {
                return exitUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = exitUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                exitUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    exitUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var exitCalled: Bool {
        return exitCallsCount > 0
    }
    open var exitClosure: (() -> Void)?

    open override func exit() {
        exitCallsCount += 1
        exitClosure?()
    }

    //MARK: - isNone

    var isNoneUnderlyingCallsCount = 0
    open var isNoneCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isNoneUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isNoneUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isNoneUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isNoneUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isNoneCalled: Bool {
        return isNoneCallsCount > 0
    }

    var isNoneUnderlyingReturnValue: Bool!
    open var isNoneReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isNoneUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isNoneUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isNoneUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isNoneUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isNoneClosure: (() -> Bool)?

    open override func isNone() -> Bool {
        isNoneCallsCount += 1
        if let isNoneClosure = isNoneClosure {
            return isNoneClosure()
        } else {
            return isNoneReturnValue
        }
    }
}
open class SsoHandlerSDKMock: MatrixRustSDK.SsoHandler {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - finish

    open var finishCallbackUrlThrowableError: Error?
    var finishCallbackUrlUnderlyingCallsCount = 0
    open var finishCallbackUrlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return finishCallbackUrlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = finishCallbackUrlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                finishCallbackUrlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    finishCallbackUrlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var finishCallbackUrlCalled: Bool {
        return finishCallbackUrlCallsCount > 0
    }
    open var finishCallbackUrlReceivedCallbackUrl: String?
    open var finishCallbackUrlReceivedInvocations: [String] = []
    open var finishCallbackUrlClosure: ((String) async throws -> Void)?

    open override func finish(callbackUrl: String) async throws {
        if let error = finishCallbackUrlThrowableError {
            throw error
        }
        finishCallbackUrlCallsCount += 1
        finishCallbackUrlReceivedCallbackUrl = callbackUrl
        DispatchQueue.main.async {
            self.finishCallbackUrlReceivedInvocations.append(callbackUrl)
        }
        try await finishCallbackUrlClosure?(callbackUrl)
    }

    //MARK: - url

    var urlUnderlyingCallsCount = 0
    open var urlCallsCount: Int {
        get {
            if Thread.isMainThread {
                return urlUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = urlUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                urlUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    urlUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var urlCalled: Bool {
        return urlCallsCount > 0
    }

    var urlUnderlyingReturnValue: String!
    open var urlReturnValue: String! {
        get {
            if Thread.isMainThread {
                return urlUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = urlUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                urlUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    urlUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var urlClosure: (() -> String)?

    open override func url() -> String {
        urlCallsCount += 1
        if let urlClosure = urlClosure {
            return urlClosure()
        } else {
            return urlReturnValue
        }
    }
}
open class SyncServiceSDKMock: MatrixRustSDK.SyncService {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - roomListService

    var roomListServiceUnderlyingCallsCount = 0
    open var roomListServiceCallsCount: Int {
        get {
            if Thread.isMainThread {
                return roomListServiceUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = roomListServiceUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomListServiceUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    roomListServiceUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var roomListServiceCalled: Bool {
        return roomListServiceCallsCount > 0
    }

    var roomListServiceUnderlyingReturnValue: RoomListService!
    open var roomListServiceReturnValue: RoomListService! {
        get {
            if Thread.isMainThread {
                return roomListServiceUnderlyingReturnValue
            } else {
                var returnValue: RoomListService? = nil
                DispatchQueue.main.sync {
                    returnValue = roomListServiceUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                roomListServiceUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    roomListServiceUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var roomListServiceClosure: (() -> RoomListService)?

    open override func roomListService() -> RoomListService {
        roomListServiceCallsCount += 1
        if let roomListServiceClosure = roomListServiceClosure {
            return roomListServiceClosure()
        } else {
            return roomListServiceReturnValue
        }
    }

    //MARK: - start

    var startUnderlyingCallsCount = 0
    open var startCallsCount: Int {
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
    open var startCalled: Bool {
        return startCallsCount > 0
    }
    open var startClosure: (() async -> Void)?

    open override func start() async {
        startCallsCount += 1
        await startClosure?()
    }

    //MARK: - state

    var stateListenerUnderlyingCallsCount = 0
    open var stateListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return stateListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = stateListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stateListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    stateListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var stateListenerCalled: Bool {
        return stateListenerCallsCount > 0
    }
    open var stateListenerReceivedListener: SyncServiceStateObserver?
    open var stateListenerReceivedInvocations: [SyncServiceStateObserver] = []

    var stateListenerUnderlyingReturnValue: TaskHandle!
    open var stateListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return stateListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = stateListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                stateListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    stateListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var stateListenerClosure: ((SyncServiceStateObserver) -> TaskHandle)?

    open override func state(listener: SyncServiceStateObserver) -> TaskHandle {
        stateListenerCallsCount += 1
        stateListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.stateListenerReceivedInvocations.append(listener)
        }
        if let stateListenerClosure = stateListenerClosure {
            return stateListenerClosure(listener)
        } else {
            return stateListenerReturnValue
        }
    }

    //MARK: - stop

    open var stopThrowableError: Error?
    var stopUnderlyingCallsCount = 0
    open var stopCallsCount: Int {
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
    open var stopCalled: Bool {
        return stopCallsCount > 0
    }
    open var stopClosure: (() async throws -> Void)?

    open override func stop() async throws {
        if let error = stopThrowableError {
            throw error
        }
        stopCallsCount += 1
        try await stopClosure?()
    }
}
open class SyncServiceBuilderSDKMock: MatrixRustSDK.SyncServiceBuilder {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - finish

    open var finishThrowableError: Error?
    var finishUnderlyingCallsCount = 0
    open var finishCallsCount: Int {
        get {
            if Thread.isMainThread {
                return finishUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = finishUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                finishUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    finishUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var finishCalled: Bool {
        return finishCallsCount > 0
    }

    var finishUnderlyingReturnValue: SyncService!
    open var finishReturnValue: SyncService! {
        get {
            if Thread.isMainThread {
                return finishUnderlyingReturnValue
            } else {
                var returnValue: SyncService? = nil
                DispatchQueue.main.sync {
                    returnValue = finishUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                finishUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    finishUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var finishClosure: (() async throws -> SyncService)?

    open override func finish() async throws -> SyncService {
        if let error = finishThrowableError {
            throw error
        }
        finishCallsCount += 1
        if let finishClosure = finishClosure {
            return try await finishClosure()
        } else {
            return finishReturnValue
        }
    }

    //MARK: - withCrossProcessLock

    var withCrossProcessLockAppIdentifierUnderlyingCallsCount = 0
    open var withCrossProcessLockAppIdentifierCallsCount: Int {
        get {
            if Thread.isMainThread {
                return withCrossProcessLockAppIdentifierUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = withCrossProcessLockAppIdentifierUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                withCrossProcessLockAppIdentifierUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    withCrossProcessLockAppIdentifierUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var withCrossProcessLockAppIdentifierCalled: Bool {
        return withCrossProcessLockAppIdentifierCallsCount > 0
    }
    open var withCrossProcessLockAppIdentifierReceivedAppIdentifier: String?
    open var withCrossProcessLockAppIdentifierReceivedInvocations: [String?] = []

    var withCrossProcessLockAppIdentifierUnderlyingReturnValue: SyncServiceBuilder!
    open var withCrossProcessLockAppIdentifierReturnValue: SyncServiceBuilder! {
        get {
            if Thread.isMainThread {
                return withCrossProcessLockAppIdentifierUnderlyingReturnValue
            } else {
                var returnValue: SyncServiceBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = withCrossProcessLockAppIdentifierUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                withCrossProcessLockAppIdentifierUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    withCrossProcessLockAppIdentifierUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var withCrossProcessLockAppIdentifierClosure: ((String?) -> SyncServiceBuilder)?

    open override func withCrossProcessLock(appIdentifier: String?) -> SyncServiceBuilder {
        withCrossProcessLockAppIdentifierCallsCount += 1
        withCrossProcessLockAppIdentifierReceivedAppIdentifier = appIdentifier
        DispatchQueue.main.async {
            self.withCrossProcessLockAppIdentifierReceivedInvocations.append(appIdentifier)
        }
        if let withCrossProcessLockAppIdentifierClosure = withCrossProcessLockAppIdentifierClosure {
            return withCrossProcessLockAppIdentifierClosure(appIdentifier)
        } else {
            return withCrossProcessLockAppIdentifierReturnValue
        }
    }

    //MARK: - withUtdHook

    var withUtdHookDelegateUnderlyingCallsCount = 0
    open var withUtdHookDelegateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return withUtdHookDelegateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = withUtdHookDelegateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                withUtdHookDelegateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    withUtdHookDelegateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var withUtdHookDelegateCalled: Bool {
        return withUtdHookDelegateCallsCount > 0
    }
    open var withUtdHookDelegateReceivedDelegate: UnableToDecryptDelegate?
    open var withUtdHookDelegateReceivedInvocations: [UnableToDecryptDelegate] = []

    var withUtdHookDelegateUnderlyingReturnValue: SyncServiceBuilder!
    open var withUtdHookDelegateReturnValue: SyncServiceBuilder! {
        get {
            if Thread.isMainThread {
                return withUtdHookDelegateUnderlyingReturnValue
            } else {
                var returnValue: SyncServiceBuilder? = nil
                DispatchQueue.main.sync {
                    returnValue = withUtdHookDelegateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                withUtdHookDelegateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    withUtdHookDelegateUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var withUtdHookDelegateClosure: ((UnableToDecryptDelegate) async -> SyncServiceBuilder)?

    open override func withUtdHook(delegate: UnableToDecryptDelegate) async -> SyncServiceBuilder {
        withUtdHookDelegateCallsCount += 1
        withUtdHookDelegateReceivedDelegate = delegate
        DispatchQueue.main.async {
            self.withUtdHookDelegateReceivedInvocations.append(delegate)
        }
        if let withUtdHookDelegateClosure = withUtdHookDelegateClosure {
            return await withUtdHookDelegateClosure(delegate)
        } else {
            return withUtdHookDelegateReturnValue
        }
    }
}
open class TaskHandleSDKMock: MatrixRustSDK.TaskHandle {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - cancel

    var cancelUnderlyingCallsCount = 0
    open var cancelCallsCount: Int {
        get {
            if Thread.isMainThread {
                return cancelUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = cancelUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                cancelUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    cancelUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var cancelCalled: Bool {
        return cancelCallsCount > 0
    }
    open var cancelClosure: (() -> Void)?

    open override func cancel() {
        cancelCallsCount += 1
        cancelClosure?()
    }

    //MARK: - isFinished

    var isFinishedUnderlyingCallsCount = 0
    open var isFinishedCallsCount: Int {
        get {
            if Thread.isMainThread {
                return isFinishedUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = isFinishedUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isFinishedUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    isFinishedUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var isFinishedCalled: Bool {
        return isFinishedCallsCount > 0
    }

    var isFinishedUnderlyingReturnValue: Bool!
    open var isFinishedReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return isFinishedUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = isFinishedUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                isFinishedUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    isFinishedUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var isFinishedClosure: (() -> Bool)?

    open override func isFinished() -> Bool {
        isFinishedCallsCount += 1
        if let isFinishedClosure = isFinishedClosure {
            return isFinishedClosure()
        } else {
            return isFinishedReturnValue
        }
    }
}
open class TimelineSDKMock: MatrixRustSDK.Timeline {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - addListener

    var addListenerListenerUnderlyingCallsCount = 0
    open var addListenerListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return addListenerListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = addListenerListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                addListenerListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    addListenerListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var addListenerListenerCalled: Bool {
        return addListenerListenerCallsCount > 0
    }
    open var addListenerListenerReceivedListener: TimelineListener?
    open var addListenerListenerReceivedInvocations: [TimelineListener] = []

    var addListenerListenerUnderlyingReturnValue: TaskHandle!
    open var addListenerListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return addListenerListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = addListenerListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                addListenerListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    addListenerListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var addListenerListenerClosure: ((TimelineListener) async -> TaskHandle)?

    open override func addListener(listener: TimelineListener) async -> TaskHandle {
        addListenerListenerCallsCount += 1
        addListenerListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.addListenerListenerReceivedInvocations.append(listener)
        }
        if let addListenerListenerClosure = addListenerListenerClosure {
            return await addListenerListenerClosure(listener)
        } else {
            return addListenerListenerReturnValue
        }
    }

    //MARK: - createPoll

    open var createPollQuestionAnswersMaxSelectionsPollKindThrowableError: Error?
    var createPollQuestionAnswersMaxSelectionsPollKindUnderlyingCallsCount = 0
    open var createPollQuestionAnswersMaxSelectionsPollKindCallsCount: Int {
        get {
            if Thread.isMainThread {
                return createPollQuestionAnswersMaxSelectionsPollKindUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = createPollQuestionAnswersMaxSelectionsPollKindUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                createPollQuestionAnswersMaxSelectionsPollKindUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    createPollQuestionAnswersMaxSelectionsPollKindUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var createPollQuestionAnswersMaxSelectionsPollKindCalled: Bool {
        return createPollQuestionAnswersMaxSelectionsPollKindCallsCount > 0
    }
    open var createPollQuestionAnswersMaxSelectionsPollKindReceivedArguments: (question: String, answers: [String], maxSelections: UInt8, pollKind: PollKind)?
    open var createPollQuestionAnswersMaxSelectionsPollKindReceivedInvocations: [(question: String, answers: [String], maxSelections: UInt8, pollKind: PollKind)] = []
    open var createPollQuestionAnswersMaxSelectionsPollKindClosure: ((String, [String], UInt8, PollKind) async throws -> Void)?

    open override func createPoll(question: String, answers: [String], maxSelections: UInt8, pollKind: PollKind) async throws {
        if let error = createPollQuestionAnswersMaxSelectionsPollKindThrowableError {
            throw error
        }
        createPollQuestionAnswersMaxSelectionsPollKindCallsCount += 1
        createPollQuestionAnswersMaxSelectionsPollKindReceivedArguments = (question: question, answers: answers, maxSelections: maxSelections, pollKind: pollKind)
        DispatchQueue.main.async {
            self.createPollQuestionAnswersMaxSelectionsPollKindReceivedInvocations.append((question: question, answers: answers, maxSelections: maxSelections, pollKind: pollKind))
        }
        try await createPollQuestionAnswersMaxSelectionsPollKindClosure?(question, answers, maxSelections, pollKind)
    }

    //MARK: - edit

    open var editItemNewContentThrowableError: Error?
    var editItemNewContentUnderlyingCallsCount = 0
    open var editItemNewContentCallsCount: Int {
        get {
            if Thread.isMainThread {
                return editItemNewContentUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = editItemNewContentUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                editItemNewContentUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    editItemNewContentUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var editItemNewContentCalled: Bool {
        return editItemNewContentCallsCount > 0
    }
    open var editItemNewContentReceivedArguments: (item: EventTimelineItem, newContent: EditedContent)?
    open var editItemNewContentReceivedInvocations: [(item: EventTimelineItem, newContent: EditedContent)] = []

    var editItemNewContentUnderlyingReturnValue: Bool!
    open var editItemNewContentReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return editItemNewContentUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = editItemNewContentUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                editItemNewContentUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    editItemNewContentUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var editItemNewContentClosure: ((EventTimelineItem, EditedContent) async throws -> Bool)?

    open override func edit(item: EventTimelineItem, newContent: EditedContent) async throws -> Bool {
        if let error = editItemNewContentThrowableError {
            throw error
        }
        editItemNewContentCallsCount += 1
        editItemNewContentReceivedArguments = (item: item, newContent: newContent)
        DispatchQueue.main.async {
            self.editItemNewContentReceivedInvocations.append((item: item, newContent: newContent))
        }
        if let editItemNewContentClosure = editItemNewContentClosure {
            return try await editItemNewContentClosure(item, newContent)
        } else {
            return editItemNewContentReturnValue
        }
    }

    //MARK: - endPoll

    open var endPollPollStartIdTextThrowableError: Error?
    var endPollPollStartIdTextUnderlyingCallsCount = 0
    open var endPollPollStartIdTextCallsCount: Int {
        get {
            if Thread.isMainThread {
                return endPollPollStartIdTextUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = endPollPollStartIdTextUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                endPollPollStartIdTextUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    endPollPollStartIdTextUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var endPollPollStartIdTextCalled: Bool {
        return endPollPollStartIdTextCallsCount > 0
    }
    open var endPollPollStartIdTextReceivedArguments: (pollStartId: String, text: String)?
    open var endPollPollStartIdTextReceivedInvocations: [(pollStartId: String, text: String)] = []
    open var endPollPollStartIdTextClosure: ((String, String) throws -> Void)?

    open override func endPoll(pollStartId: String, text: String) throws {
        if let error = endPollPollStartIdTextThrowableError {
            throw error
        }
        endPollPollStartIdTextCallsCount += 1
        endPollPollStartIdTextReceivedArguments = (pollStartId: pollStartId, text: text)
        DispatchQueue.main.async {
            self.endPollPollStartIdTextReceivedInvocations.append((pollStartId: pollStartId, text: text))
        }
        try endPollPollStartIdTextClosure?(pollStartId, text)
    }

    //MARK: - fetchDetailsForEvent

    open var fetchDetailsForEventEventIdThrowableError: Error?
    var fetchDetailsForEventEventIdUnderlyingCallsCount = 0
    open var fetchDetailsForEventEventIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return fetchDetailsForEventEventIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = fetchDetailsForEventEventIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                fetchDetailsForEventEventIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    fetchDetailsForEventEventIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var fetchDetailsForEventEventIdCalled: Bool {
        return fetchDetailsForEventEventIdCallsCount > 0
    }
    open var fetchDetailsForEventEventIdReceivedEventId: String?
    open var fetchDetailsForEventEventIdReceivedInvocations: [String] = []
    open var fetchDetailsForEventEventIdClosure: ((String) async throws -> Void)?

    open override func fetchDetailsForEvent(eventId: String) async throws {
        if let error = fetchDetailsForEventEventIdThrowableError {
            throw error
        }
        fetchDetailsForEventEventIdCallsCount += 1
        fetchDetailsForEventEventIdReceivedEventId = eventId
        DispatchQueue.main.async {
            self.fetchDetailsForEventEventIdReceivedInvocations.append(eventId)
        }
        try await fetchDetailsForEventEventIdClosure?(eventId)
    }

    //MARK: - fetchMembers

    var fetchMembersUnderlyingCallsCount = 0
    open var fetchMembersCallsCount: Int {
        get {
            if Thread.isMainThread {
                return fetchMembersUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = fetchMembersUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                fetchMembersUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    fetchMembersUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var fetchMembersCalled: Bool {
        return fetchMembersCallsCount > 0
    }
    open var fetchMembersClosure: (() async -> Void)?

    open override func fetchMembers() async {
        fetchMembersCallsCount += 1
        await fetchMembersClosure?()
    }

    //MARK: - focusedPaginateForwards

    open var focusedPaginateForwardsNumEventsThrowableError: Error?
    var focusedPaginateForwardsNumEventsUnderlyingCallsCount = 0
    open var focusedPaginateForwardsNumEventsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return focusedPaginateForwardsNumEventsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = focusedPaginateForwardsNumEventsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                focusedPaginateForwardsNumEventsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    focusedPaginateForwardsNumEventsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var focusedPaginateForwardsNumEventsCalled: Bool {
        return focusedPaginateForwardsNumEventsCallsCount > 0
    }
    open var focusedPaginateForwardsNumEventsReceivedNumEvents: UInt16?
    open var focusedPaginateForwardsNumEventsReceivedInvocations: [UInt16] = []

    var focusedPaginateForwardsNumEventsUnderlyingReturnValue: Bool!
    open var focusedPaginateForwardsNumEventsReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return focusedPaginateForwardsNumEventsUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = focusedPaginateForwardsNumEventsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                focusedPaginateForwardsNumEventsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    focusedPaginateForwardsNumEventsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var focusedPaginateForwardsNumEventsClosure: ((UInt16) async throws -> Bool)?

    open override func focusedPaginateForwards(numEvents: UInt16) async throws -> Bool {
        if let error = focusedPaginateForwardsNumEventsThrowableError {
            throw error
        }
        focusedPaginateForwardsNumEventsCallsCount += 1
        focusedPaginateForwardsNumEventsReceivedNumEvents = numEvents
        DispatchQueue.main.async {
            self.focusedPaginateForwardsNumEventsReceivedInvocations.append(numEvents)
        }
        if let focusedPaginateForwardsNumEventsClosure = focusedPaginateForwardsNumEventsClosure {
            return try await focusedPaginateForwardsNumEventsClosure(numEvents)
        } else {
            return focusedPaginateForwardsNumEventsReturnValue
        }
    }

    //MARK: - getEventTimelineItemByEventId

    open var getEventTimelineItemByEventIdEventIdThrowableError: Error?
    var getEventTimelineItemByEventIdEventIdUnderlyingCallsCount = 0
    open var getEventTimelineItemByEventIdEventIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getEventTimelineItemByEventIdEventIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getEventTimelineItemByEventIdEventIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getEventTimelineItemByEventIdEventIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getEventTimelineItemByEventIdEventIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var getEventTimelineItemByEventIdEventIdCalled: Bool {
        return getEventTimelineItemByEventIdEventIdCallsCount > 0
    }
    open var getEventTimelineItemByEventIdEventIdReceivedEventId: String?
    open var getEventTimelineItemByEventIdEventIdReceivedInvocations: [String] = []

    var getEventTimelineItemByEventIdEventIdUnderlyingReturnValue: EventTimelineItem!
    open var getEventTimelineItemByEventIdEventIdReturnValue: EventTimelineItem! {
        get {
            if Thread.isMainThread {
                return getEventTimelineItemByEventIdEventIdUnderlyingReturnValue
            } else {
                var returnValue: EventTimelineItem? = nil
                DispatchQueue.main.sync {
                    returnValue = getEventTimelineItemByEventIdEventIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getEventTimelineItemByEventIdEventIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getEventTimelineItemByEventIdEventIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var getEventTimelineItemByEventIdEventIdClosure: ((String) async throws -> EventTimelineItem)?

    open override func getEventTimelineItemByEventId(eventId: String) async throws -> EventTimelineItem {
        if let error = getEventTimelineItemByEventIdEventIdThrowableError {
            throw error
        }
        getEventTimelineItemByEventIdEventIdCallsCount += 1
        getEventTimelineItemByEventIdEventIdReceivedEventId = eventId
        DispatchQueue.main.async {
            self.getEventTimelineItemByEventIdEventIdReceivedInvocations.append(eventId)
        }
        if let getEventTimelineItemByEventIdEventIdClosure = getEventTimelineItemByEventIdEventIdClosure {
            return try await getEventTimelineItemByEventIdEventIdClosure(eventId)
        } else {
            return getEventTimelineItemByEventIdEventIdReturnValue
        }
    }

    //MARK: - getEventTimelineItemByTransactionId

    open var getEventTimelineItemByTransactionIdTransactionIdThrowableError: Error?
    var getEventTimelineItemByTransactionIdTransactionIdUnderlyingCallsCount = 0
    open var getEventTimelineItemByTransactionIdTransactionIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return getEventTimelineItemByTransactionIdTransactionIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = getEventTimelineItemByTransactionIdTransactionIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getEventTimelineItemByTransactionIdTransactionIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    getEventTimelineItemByTransactionIdTransactionIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var getEventTimelineItemByTransactionIdTransactionIdCalled: Bool {
        return getEventTimelineItemByTransactionIdTransactionIdCallsCount > 0
    }
    open var getEventTimelineItemByTransactionIdTransactionIdReceivedTransactionId: String?
    open var getEventTimelineItemByTransactionIdTransactionIdReceivedInvocations: [String] = []

    var getEventTimelineItemByTransactionIdTransactionIdUnderlyingReturnValue: EventTimelineItem!
    open var getEventTimelineItemByTransactionIdTransactionIdReturnValue: EventTimelineItem! {
        get {
            if Thread.isMainThread {
                return getEventTimelineItemByTransactionIdTransactionIdUnderlyingReturnValue
            } else {
                var returnValue: EventTimelineItem? = nil
                DispatchQueue.main.sync {
                    returnValue = getEventTimelineItemByTransactionIdTransactionIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                getEventTimelineItemByTransactionIdTransactionIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    getEventTimelineItemByTransactionIdTransactionIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var getEventTimelineItemByTransactionIdTransactionIdClosure: ((String) async throws -> EventTimelineItem)?

    open override func getEventTimelineItemByTransactionId(transactionId: String) async throws -> EventTimelineItem {
        if let error = getEventTimelineItemByTransactionIdTransactionIdThrowableError {
            throw error
        }
        getEventTimelineItemByTransactionIdTransactionIdCallsCount += 1
        getEventTimelineItemByTransactionIdTransactionIdReceivedTransactionId = transactionId
        DispatchQueue.main.async {
            self.getEventTimelineItemByTransactionIdTransactionIdReceivedInvocations.append(transactionId)
        }
        if let getEventTimelineItemByTransactionIdTransactionIdClosure = getEventTimelineItemByTransactionIdTransactionIdClosure {
            return try await getEventTimelineItemByTransactionIdTransactionIdClosure(transactionId)
        } else {
            return getEventTimelineItemByTransactionIdTransactionIdReturnValue
        }
    }

    //MARK: - loadReplyDetails

    open var loadReplyDetailsEventIdStrThrowableError: Error?
    var loadReplyDetailsEventIdStrUnderlyingCallsCount = 0
    open var loadReplyDetailsEventIdStrCallsCount: Int {
        get {
            if Thread.isMainThread {
                return loadReplyDetailsEventIdStrUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = loadReplyDetailsEventIdStrUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadReplyDetailsEventIdStrUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    loadReplyDetailsEventIdStrUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var loadReplyDetailsEventIdStrCalled: Bool {
        return loadReplyDetailsEventIdStrCallsCount > 0
    }
    open var loadReplyDetailsEventIdStrReceivedEventIdStr: String?
    open var loadReplyDetailsEventIdStrReceivedInvocations: [String] = []

    var loadReplyDetailsEventIdStrUnderlyingReturnValue: InReplyToDetails!
    open var loadReplyDetailsEventIdStrReturnValue: InReplyToDetails! {
        get {
            if Thread.isMainThread {
                return loadReplyDetailsEventIdStrUnderlyingReturnValue
            } else {
                var returnValue: InReplyToDetails? = nil
                DispatchQueue.main.sync {
                    returnValue = loadReplyDetailsEventIdStrUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                loadReplyDetailsEventIdStrUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    loadReplyDetailsEventIdStrUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var loadReplyDetailsEventIdStrClosure: ((String) async throws -> InReplyToDetails)?

    open override func loadReplyDetails(eventIdStr: String) async throws -> InReplyToDetails {
        if let error = loadReplyDetailsEventIdStrThrowableError {
            throw error
        }
        loadReplyDetailsEventIdStrCallsCount += 1
        loadReplyDetailsEventIdStrReceivedEventIdStr = eventIdStr
        DispatchQueue.main.async {
            self.loadReplyDetailsEventIdStrReceivedInvocations.append(eventIdStr)
        }
        if let loadReplyDetailsEventIdStrClosure = loadReplyDetailsEventIdStrClosure {
            return try await loadReplyDetailsEventIdStrClosure(eventIdStr)
        } else {
            return loadReplyDetailsEventIdStrReturnValue
        }
    }

    //MARK: - markAsRead

    open var markAsReadReceiptTypeThrowableError: Error?
    var markAsReadReceiptTypeUnderlyingCallsCount = 0
    open var markAsReadReceiptTypeCallsCount: Int {
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
    open var markAsReadReceiptTypeCalled: Bool {
        return markAsReadReceiptTypeCallsCount > 0
    }
    open var markAsReadReceiptTypeReceivedReceiptType: ReceiptType?
    open var markAsReadReceiptTypeReceivedInvocations: [ReceiptType] = []
    open var markAsReadReceiptTypeClosure: ((ReceiptType) async throws -> Void)?

    open override func markAsRead(receiptType: ReceiptType) async throws {
        if let error = markAsReadReceiptTypeThrowableError {
            throw error
        }
        markAsReadReceiptTypeCallsCount += 1
        markAsReadReceiptTypeReceivedReceiptType = receiptType
        DispatchQueue.main.async {
            self.markAsReadReceiptTypeReceivedInvocations.append(receiptType)
        }
        try await markAsReadReceiptTypeClosure?(receiptType)
    }

    //MARK: - paginateBackwards

    open var paginateBackwardsNumEventsThrowableError: Error?
    var paginateBackwardsNumEventsUnderlyingCallsCount = 0
    open var paginateBackwardsNumEventsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return paginateBackwardsNumEventsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = paginateBackwardsNumEventsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                paginateBackwardsNumEventsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    paginateBackwardsNumEventsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var paginateBackwardsNumEventsCalled: Bool {
        return paginateBackwardsNumEventsCallsCount > 0
    }
    open var paginateBackwardsNumEventsReceivedNumEvents: UInt16?
    open var paginateBackwardsNumEventsReceivedInvocations: [UInt16] = []

    var paginateBackwardsNumEventsUnderlyingReturnValue: Bool!
    open var paginateBackwardsNumEventsReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return paginateBackwardsNumEventsUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = paginateBackwardsNumEventsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                paginateBackwardsNumEventsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    paginateBackwardsNumEventsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var paginateBackwardsNumEventsClosure: ((UInt16) async throws -> Bool)?

    open override func paginateBackwards(numEvents: UInt16) async throws -> Bool {
        if let error = paginateBackwardsNumEventsThrowableError {
            throw error
        }
        paginateBackwardsNumEventsCallsCount += 1
        paginateBackwardsNumEventsReceivedNumEvents = numEvents
        DispatchQueue.main.async {
            self.paginateBackwardsNumEventsReceivedInvocations.append(numEvents)
        }
        if let paginateBackwardsNumEventsClosure = paginateBackwardsNumEventsClosure {
            return try await paginateBackwardsNumEventsClosure(numEvents)
        } else {
            return paginateBackwardsNumEventsReturnValue
        }
    }

    //MARK: - pinEvent

    open var pinEventEventIdThrowableError: Error?
    var pinEventEventIdUnderlyingCallsCount = 0
    open var pinEventEventIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return pinEventEventIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = pinEventEventIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pinEventEventIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    pinEventEventIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var pinEventEventIdCalled: Bool {
        return pinEventEventIdCallsCount > 0
    }
    open var pinEventEventIdReceivedEventId: String?
    open var pinEventEventIdReceivedInvocations: [String] = []

    var pinEventEventIdUnderlyingReturnValue: Bool!
    open var pinEventEventIdReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return pinEventEventIdUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = pinEventEventIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pinEventEventIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    pinEventEventIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var pinEventEventIdClosure: ((String) async throws -> Bool)?

    open override func pinEvent(eventId: String) async throws -> Bool {
        if let error = pinEventEventIdThrowableError {
            throw error
        }
        pinEventEventIdCallsCount += 1
        pinEventEventIdReceivedEventId = eventId
        DispatchQueue.main.async {
            self.pinEventEventIdReceivedInvocations.append(eventId)
        }
        if let pinEventEventIdClosure = pinEventEventIdClosure {
            return try await pinEventEventIdClosure(eventId)
        } else {
            return pinEventEventIdReturnValue
        }
    }

    //MARK: - redactEvent

    open var redactEventItemReasonThrowableError: Error?
    var redactEventItemReasonUnderlyingCallsCount = 0
    open var redactEventItemReasonCallsCount: Int {
        get {
            if Thread.isMainThread {
                return redactEventItemReasonUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = redactEventItemReasonUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                redactEventItemReasonUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    redactEventItemReasonUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var redactEventItemReasonCalled: Bool {
        return redactEventItemReasonCallsCount > 0
    }
    open var redactEventItemReasonReceivedArguments: (item: EventTimelineItem, reason: String?)?
    open var redactEventItemReasonReceivedInvocations: [(item: EventTimelineItem, reason: String?)] = []

    var redactEventItemReasonUnderlyingReturnValue: Bool!
    open var redactEventItemReasonReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return redactEventItemReasonUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = redactEventItemReasonUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                redactEventItemReasonUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    redactEventItemReasonUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var redactEventItemReasonClosure: ((EventTimelineItem, String?) async throws -> Bool)?

    open override func redactEvent(item: EventTimelineItem, reason: String?) async throws -> Bool {
        if let error = redactEventItemReasonThrowableError {
            throw error
        }
        redactEventItemReasonCallsCount += 1
        redactEventItemReasonReceivedArguments = (item: item, reason: reason)
        DispatchQueue.main.async {
            self.redactEventItemReasonReceivedInvocations.append((item: item, reason: reason))
        }
        if let redactEventItemReasonClosure = redactEventItemReasonClosure {
            return try await redactEventItemReasonClosure(item, reason)
        } else {
            return redactEventItemReasonReturnValue
        }
    }

    //MARK: - retryDecryption

    var retryDecryptionSessionIdsUnderlyingCallsCount = 0
    open var retryDecryptionSessionIdsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return retryDecryptionSessionIdsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = retryDecryptionSessionIdsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                retryDecryptionSessionIdsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    retryDecryptionSessionIdsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var retryDecryptionSessionIdsCalled: Bool {
        return retryDecryptionSessionIdsCallsCount > 0
    }
    open var retryDecryptionSessionIdsReceivedSessionIds: [String]?
    open var retryDecryptionSessionIdsReceivedInvocations: [[String]] = []
    open var retryDecryptionSessionIdsClosure: (([String]) -> Void)?

    open override func retryDecryption(sessionIds: [String]) {
        retryDecryptionSessionIdsCallsCount += 1
        retryDecryptionSessionIdsReceivedSessionIds = sessionIds
        DispatchQueue.main.async {
            self.retryDecryptionSessionIdsReceivedInvocations.append(sessionIds)
        }
        retryDecryptionSessionIdsClosure?(sessionIds)
    }

    //MARK: - send

    open var sendMsgThrowableError: Error?
    var sendMsgUnderlyingCallsCount = 0
    open var sendMsgCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendMsgUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendMsgUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendMsgUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendMsgUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendMsgCalled: Bool {
        return sendMsgCallsCount > 0
    }
    open var sendMsgReceivedMsg: RoomMessageEventContentWithoutRelation?
    open var sendMsgReceivedInvocations: [RoomMessageEventContentWithoutRelation] = []

    var sendMsgUnderlyingReturnValue: SendHandle!
    open var sendMsgReturnValue: SendHandle! {
        get {
            if Thread.isMainThread {
                return sendMsgUnderlyingReturnValue
            } else {
                var returnValue: SendHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = sendMsgUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendMsgUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendMsgUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var sendMsgClosure: ((RoomMessageEventContentWithoutRelation) async throws -> SendHandle)?

    open override func send(msg: RoomMessageEventContentWithoutRelation) async throws -> SendHandle {
        if let error = sendMsgThrowableError {
            throw error
        }
        sendMsgCallsCount += 1
        sendMsgReceivedMsg = msg
        DispatchQueue.main.async {
            self.sendMsgReceivedInvocations.append(msg)
        }
        if let sendMsgClosure = sendMsgClosure {
            return try await sendMsgClosure(msg)
        } else {
            return sendMsgReturnValue
        }
    }

    //MARK: - sendAudio

    var sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = 0
    open var sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherCalled: Bool {
        return sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherCallsCount > 0
    }
    open var sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherReceivedArguments: (url: String, audioInfo: AudioInfo, caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?)?
    open var sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherReceivedInvocations: [(url: String, audioInfo: AudioInfo, caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?)] = []

    var sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue: SendAttachmentJoinHandle!
    open var sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherReturnValue: SendAttachmentJoinHandle! {
        get {
            if Thread.isMainThread {
                return sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue
            } else {
                var returnValue: SendAttachmentJoinHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherClosure: ((String, AudioInfo, String?, FormattedBody?, ProgressWatcher?) -> SendAttachmentJoinHandle)?

    open override func sendAudio(url: String, audioInfo: AudioInfo, caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?) -> SendAttachmentJoinHandle {
        sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherCallsCount += 1
        sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherReceivedArguments = (url: url, audioInfo: audioInfo, caption: caption, formattedCaption: formattedCaption, progressWatcher: progressWatcher)
        DispatchQueue.main.async {
            self.sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherReceivedInvocations.append((url: url, audioInfo: audioInfo, caption: caption, formattedCaption: formattedCaption, progressWatcher: progressWatcher))
        }
        if let sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherClosure = sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherClosure {
            return sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherClosure(url, audioInfo, caption, formattedCaption, progressWatcher)
        } else {
            return sendAudioUrlAudioInfoCaptionFormattedCaptionProgressWatcherReturnValue
        }
    }

    //MARK: - sendFile

    var sendFileUrlFileInfoProgressWatcherUnderlyingCallsCount = 0
    open var sendFileUrlFileInfoProgressWatcherCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendFileUrlFileInfoProgressWatcherUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendFileUrlFileInfoProgressWatcherUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendFileUrlFileInfoProgressWatcherUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendFileUrlFileInfoProgressWatcherUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendFileUrlFileInfoProgressWatcherCalled: Bool {
        return sendFileUrlFileInfoProgressWatcherCallsCount > 0
    }
    open var sendFileUrlFileInfoProgressWatcherReceivedArguments: (url: String, fileInfo: FileInfo, progressWatcher: ProgressWatcher?)?
    open var sendFileUrlFileInfoProgressWatcherReceivedInvocations: [(url: String, fileInfo: FileInfo, progressWatcher: ProgressWatcher?)] = []

    var sendFileUrlFileInfoProgressWatcherUnderlyingReturnValue: SendAttachmentJoinHandle!
    open var sendFileUrlFileInfoProgressWatcherReturnValue: SendAttachmentJoinHandle! {
        get {
            if Thread.isMainThread {
                return sendFileUrlFileInfoProgressWatcherUnderlyingReturnValue
            } else {
                var returnValue: SendAttachmentJoinHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = sendFileUrlFileInfoProgressWatcherUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendFileUrlFileInfoProgressWatcherUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendFileUrlFileInfoProgressWatcherUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var sendFileUrlFileInfoProgressWatcherClosure: ((String, FileInfo, ProgressWatcher?) -> SendAttachmentJoinHandle)?

    open override func sendFile(url: String, fileInfo: FileInfo, progressWatcher: ProgressWatcher?) -> SendAttachmentJoinHandle {
        sendFileUrlFileInfoProgressWatcherCallsCount += 1
        sendFileUrlFileInfoProgressWatcherReceivedArguments = (url: url, fileInfo: fileInfo, progressWatcher: progressWatcher)
        DispatchQueue.main.async {
            self.sendFileUrlFileInfoProgressWatcherReceivedInvocations.append((url: url, fileInfo: fileInfo, progressWatcher: progressWatcher))
        }
        if let sendFileUrlFileInfoProgressWatcherClosure = sendFileUrlFileInfoProgressWatcherClosure {
            return sendFileUrlFileInfoProgressWatcherClosure(url, fileInfo, progressWatcher)
        } else {
            return sendFileUrlFileInfoProgressWatcherReturnValue
        }
    }

    //MARK: - sendImage

    var sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = 0
    open var sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherCalled: Bool {
        return sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherCallsCount > 0
    }
    open var sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherReceivedArguments: (url: String, thumbnailUrl: String?, imageInfo: ImageInfo, caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?)?
    open var sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherReceivedInvocations: [(url: String, thumbnailUrl: String?, imageInfo: ImageInfo, caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?)] = []

    var sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue: SendAttachmentJoinHandle!
    open var sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherReturnValue: SendAttachmentJoinHandle! {
        get {
            if Thread.isMainThread {
                return sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue
            } else {
                var returnValue: SendAttachmentJoinHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherClosure: ((String, String?, ImageInfo, String?, FormattedBody?, ProgressWatcher?) -> SendAttachmentJoinHandle)?

    open override func sendImage(url: String, thumbnailUrl: String?, imageInfo: ImageInfo, caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?) -> SendAttachmentJoinHandle {
        sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherCallsCount += 1
        sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherReceivedArguments = (url: url, thumbnailUrl: thumbnailUrl, imageInfo: imageInfo, caption: caption, formattedCaption: formattedCaption, progressWatcher: progressWatcher)
        DispatchQueue.main.async {
            self.sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherReceivedInvocations.append((url: url, thumbnailUrl: thumbnailUrl, imageInfo: imageInfo, caption: caption, formattedCaption: formattedCaption, progressWatcher: progressWatcher))
        }
        if let sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherClosure = sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherClosure {
            return sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherClosure(url, thumbnailUrl, imageInfo, caption, formattedCaption, progressWatcher)
        } else {
            return sendImageUrlThumbnailUrlImageInfoCaptionFormattedCaptionProgressWatcherReturnValue
        }
    }

    //MARK: - sendLocation

    var sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeUnderlyingCallsCount = 0
    open var sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeCalled: Bool {
        return sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeCallsCount > 0
    }
    open var sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeReceivedArguments: (body: String, geoUri: String, description: String?, zoomLevel: UInt8?, assetType: AssetType?)?
    open var sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeReceivedInvocations: [(body: String, geoUri: String, description: String?, zoomLevel: UInt8?, assetType: AssetType?)] = []
    open var sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeClosure: ((String, String, String?, UInt8?, AssetType?) async -> Void)?

    open override func sendLocation(body: String, geoUri: String, description: String?, zoomLevel: UInt8?, assetType: AssetType?) async {
        sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeCallsCount += 1
        sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeReceivedArguments = (body: body, geoUri: geoUri, description: description, zoomLevel: zoomLevel, assetType: assetType)
        DispatchQueue.main.async {
            self.sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeReceivedInvocations.append((body: body, geoUri: geoUri, description: description, zoomLevel: zoomLevel, assetType: assetType))
        }
        await sendLocationBodyGeoUriDescriptionZoomLevelAssetTypeClosure?(body, geoUri, description, zoomLevel, assetType)
    }

    //MARK: - sendPollResponse

    open var sendPollResponsePollStartIdAnswersThrowableError: Error?
    var sendPollResponsePollStartIdAnswersUnderlyingCallsCount = 0
    open var sendPollResponsePollStartIdAnswersCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendPollResponsePollStartIdAnswersUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendPollResponsePollStartIdAnswersUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendPollResponsePollStartIdAnswersUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendPollResponsePollStartIdAnswersUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendPollResponsePollStartIdAnswersCalled: Bool {
        return sendPollResponsePollStartIdAnswersCallsCount > 0
    }
    open var sendPollResponsePollStartIdAnswersReceivedArguments: (pollStartId: String, answers: [String])?
    open var sendPollResponsePollStartIdAnswersReceivedInvocations: [(pollStartId: String, answers: [String])] = []
    open var sendPollResponsePollStartIdAnswersClosure: ((String, [String]) async throws -> Void)?

    open override func sendPollResponse(pollStartId: String, answers: [String]) async throws {
        if let error = sendPollResponsePollStartIdAnswersThrowableError {
            throw error
        }
        sendPollResponsePollStartIdAnswersCallsCount += 1
        sendPollResponsePollStartIdAnswersReceivedArguments = (pollStartId: pollStartId, answers: answers)
        DispatchQueue.main.async {
            self.sendPollResponsePollStartIdAnswersReceivedInvocations.append((pollStartId: pollStartId, answers: answers))
        }
        try await sendPollResponsePollStartIdAnswersClosure?(pollStartId, answers)
    }

    //MARK: - sendReadReceipt

    open var sendReadReceiptReceiptTypeEventIdThrowableError: Error?
    var sendReadReceiptReceiptTypeEventIdUnderlyingCallsCount = 0
    open var sendReadReceiptReceiptTypeEventIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendReadReceiptReceiptTypeEventIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendReadReceiptReceiptTypeEventIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendReadReceiptReceiptTypeEventIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendReadReceiptReceiptTypeEventIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendReadReceiptReceiptTypeEventIdCalled: Bool {
        return sendReadReceiptReceiptTypeEventIdCallsCount > 0
    }
    open var sendReadReceiptReceiptTypeEventIdReceivedArguments: (receiptType: ReceiptType, eventId: String)?
    open var sendReadReceiptReceiptTypeEventIdReceivedInvocations: [(receiptType: ReceiptType, eventId: String)] = []
    open var sendReadReceiptReceiptTypeEventIdClosure: ((ReceiptType, String) async throws -> Void)?

    open override func sendReadReceipt(receiptType: ReceiptType, eventId: String) async throws {
        if let error = sendReadReceiptReceiptTypeEventIdThrowableError {
            throw error
        }
        sendReadReceiptReceiptTypeEventIdCallsCount += 1
        sendReadReceiptReceiptTypeEventIdReceivedArguments = (receiptType: receiptType, eventId: eventId)
        DispatchQueue.main.async {
            self.sendReadReceiptReceiptTypeEventIdReceivedInvocations.append((receiptType: receiptType, eventId: eventId))
        }
        try await sendReadReceiptReceiptTypeEventIdClosure?(receiptType, eventId)
    }

    //MARK: - sendReply

    open var sendReplyMsgEventIdThrowableError: Error?
    var sendReplyMsgEventIdUnderlyingCallsCount = 0
    open var sendReplyMsgEventIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendReplyMsgEventIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendReplyMsgEventIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendReplyMsgEventIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendReplyMsgEventIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendReplyMsgEventIdCalled: Bool {
        return sendReplyMsgEventIdCallsCount > 0
    }
    open var sendReplyMsgEventIdReceivedArguments: (msg: RoomMessageEventContentWithoutRelation, eventId: String)?
    open var sendReplyMsgEventIdReceivedInvocations: [(msg: RoomMessageEventContentWithoutRelation, eventId: String)] = []
    open var sendReplyMsgEventIdClosure: ((RoomMessageEventContentWithoutRelation, String) async throws -> Void)?

    open override func sendReply(msg: RoomMessageEventContentWithoutRelation, eventId: String) async throws {
        if let error = sendReplyMsgEventIdThrowableError {
            throw error
        }
        sendReplyMsgEventIdCallsCount += 1
        sendReplyMsgEventIdReceivedArguments = (msg: msg, eventId: eventId)
        DispatchQueue.main.async {
            self.sendReplyMsgEventIdReceivedInvocations.append((msg: msg, eventId: eventId))
        }
        try await sendReplyMsgEventIdClosure?(msg, eventId)
    }

    //MARK: - sendVideo

    var sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = 0
    open var sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherCalled: Bool {
        return sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherCallsCount > 0
    }
    open var sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherReceivedArguments: (url: String, thumbnailUrl: String?, videoInfo: VideoInfo, caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?)?
    open var sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherReceivedInvocations: [(url: String, thumbnailUrl: String?, videoInfo: VideoInfo, caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?)] = []

    var sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue: SendAttachmentJoinHandle!
    open var sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherReturnValue: SendAttachmentJoinHandle! {
        get {
            if Thread.isMainThread {
                return sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue
            } else {
                var returnValue: SendAttachmentJoinHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherClosure: ((String, String?, VideoInfo, String?, FormattedBody?, ProgressWatcher?) -> SendAttachmentJoinHandle)?

    open override func sendVideo(url: String, thumbnailUrl: String?, videoInfo: VideoInfo, caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?) -> SendAttachmentJoinHandle {
        sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherCallsCount += 1
        sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherReceivedArguments = (url: url, thumbnailUrl: thumbnailUrl, videoInfo: videoInfo, caption: caption, formattedCaption: formattedCaption, progressWatcher: progressWatcher)
        DispatchQueue.main.async {
            self.sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherReceivedInvocations.append((url: url, thumbnailUrl: thumbnailUrl, videoInfo: videoInfo, caption: caption, formattedCaption: formattedCaption, progressWatcher: progressWatcher))
        }
        if let sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherClosure = sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherClosure {
            return sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherClosure(url, thumbnailUrl, videoInfo, caption, formattedCaption, progressWatcher)
        } else {
            return sendVideoUrlThumbnailUrlVideoInfoCaptionFormattedCaptionProgressWatcherReturnValue
        }
    }

    //MARK: - sendVoiceMessage

    var sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = 0
    open var sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherCalled: Bool {
        return sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherCallsCount > 0
    }
    open var sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherReceivedArguments: (url: String, audioInfo: AudioInfo, waveform: [UInt16], caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?)?
    open var sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherReceivedInvocations: [(url: String, audioInfo: AudioInfo, waveform: [UInt16], caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?)] = []

    var sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue: SendAttachmentJoinHandle!
    open var sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherReturnValue: SendAttachmentJoinHandle! {
        get {
            if Thread.isMainThread {
                return sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue
            } else {
                var returnValue: SendAttachmentJoinHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherClosure: ((String, AudioInfo, [UInt16], String?, FormattedBody?, ProgressWatcher?) -> SendAttachmentJoinHandle)?

    open override func sendVoiceMessage(url: String, audioInfo: AudioInfo, waveform: [UInt16], caption: String?, formattedCaption: FormattedBody?, progressWatcher: ProgressWatcher?) -> SendAttachmentJoinHandle {
        sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherCallsCount += 1
        sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherReceivedArguments = (url: url, audioInfo: audioInfo, waveform: waveform, caption: caption, formattedCaption: formattedCaption, progressWatcher: progressWatcher)
        DispatchQueue.main.async {
            self.sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherReceivedInvocations.append((url: url, audioInfo: audioInfo, waveform: waveform, caption: caption, formattedCaption: formattedCaption, progressWatcher: progressWatcher))
        }
        if let sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherClosure = sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherClosure {
            return sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherClosure(url, audioInfo, waveform, caption, formattedCaption, progressWatcher)
        } else {
            return sendVoiceMessageUrlAudioInfoWaveformCaptionFormattedCaptionProgressWatcherReturnValue
        }
    }

    //MARK: - subscribeToBackPaginationStatus

    open var subscribeToBackPaginationStatusListenerThrowableError: Error?
    var subscribeToBackPaginationStatusListenerUnderlyingCallsCount = 0
    open var subscribeToBackPaginationStatusListenerCallsCount: Int {
        get {
            if Thread.isMainThread {
                return subscribeToBackPaginationStatusListenerUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToBackPaginationStatusListenerUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToBackPaginationStatusListenerUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToBackPaginationStatusListenerUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var subscribeToBackPaginationStatusListenerCalled: Bool {
        return subscribeToBackPaginationStatusListenerCallsCount > 0
    }
    open var subscribeToBackPaginationStatusListenerReceivedListener: PaginationStatusListener?
    open var subscribeToBackPaginationStatusListenerReceivedInvocations: [PaginationStatusListener] = []

    var subscribeToBackPaginationStatusListenerUnderlyingReturnValue: TaskHandle!
    open var subscribeToBackPaginationStatusListenerReturnValue: TaskHandle! {
        get {
            if Thread.isMainThread {
                return subscribeToBackPaginationStatusListenerUnderlyingReturnValue
            } else {
                var returnValue: TaskHandle? = nil
                DispatchQueue.main.sync {
                    returnValue = subscribeToBackPaginationStatusListenerUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                subscribeToBackPaginationStatusListenerUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    subscribeToBackPaginationStatusListenerUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var subscribeToBackPaginationStatusListenerClosure: ((PaginationStatusListener) async throws -> TaskHandle)?

    open override func subscribeToBackPaginationStatus(listener: PaginationStatusListener) async throws -> TaskHandle {
        if let error = subscribeToBackPaginationStatusListenerThrowableError {
            throw error
        }
        subscribeToBackPaginationStatusListenerCallsCount += 1
        subscribeToBackPaginationStatusListenerReceivedListener = listener
        DispatchQueue.main.async {
            self.subscribeToBackPaginationStatusListenerReceivedInvocations.append(listener)
        }
        if let subscribeToBackPaginationStatusListenerClosure = subscribeToBackPaginationStatusListenerClosure {
            return try await subscribeToBackPaginationStatusListenerClosure(listener)
        } else {
            return subscribeToBackPaginationStatusListenerReturnValue
        }
    }

    //MARK: - toggleReaction

    open var toggleReactionUniqueIdKeyThrowableError: Error?
    var toggleReactionUniqueIdKeyUnderlyingCallsCount = 0
    open var toggleReactionUniqueIdKeyCallsCount: Int {
        get {
            if Thread.isMainThread {
                return toggleReactionUniqueIdKeyUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = toggleReactionUniqueIdKeyUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                toggleReactionUniqueIdKeyUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    toggleReactionUniqueIdKeyUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var toggleReactionUniqueIdKeyCalled: Bool {
        return toggleReactionUniqueIdKeyCallsCount > 0
    }
    open var toggleReactionUniqueIdKeyReceivedArguments: (uniqueId: String, key: String)?
    open var toggleReactionUniqueIdKeyReceivedInvocations: [(uniqueId: String, key: String)] = []
    open var toggleReactionUniqueIdKeyClosure: ((String, String) async throws -> Void)?

    open override func toggleReaction(uniqueId: String, key: String) async throws {
        if let error = toggleReactionUniqueIdKeyThrowableError {
            throw error
        }
        toggleReactionUniqueIdKeyCallsCount += 1
        toggleReactionUniqueIdKeyReceivedArguments = (uniqueId: uniqueId, key: key)
        DispatchQueue.main.async {
            self.toggleReactionUniqueIdKeyReceivedInvocations.append((uniqueId: uniqueId, key: key))
        }
        try await toggleReactionUniqueIdKeyClosure?(uniqueId, key)
    }

    //MARK: - unpinEvent

    open var unpinEventEventIdThrowableError: Error?
    var unpinEventEventIdUnderlyingCallsCount = 0
    open var unpinEventEventIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return unpinEventEventIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = unpinEventEventIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unpinEventEventIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    unpinEventEventIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var unpinEventEventIdCalled: Bool {
        return unpinEventEventIdCallsCount > 0
    }
    open var unpinEventEventIdReceivedEventId: String?
    open var unpinEventEventIdReceivedInvocations: [String] = []

    var unpinEventEventIdUnderlyingReturnValue: Bool!
    open var unpinEventEventIdReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return unpinEventEventIdUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = unpinEventEventIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                unpinEventEventIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    unpinEventEventIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var unpinEventEventIdClosure: ((String) async throws -> Bool)?

    open override func unpinEvent(eventId: String) async throws -> Bool {
        if let error = unpinEventEventIdThrowableError {
            throw error
        }
        unpinEventEventIdCallsCount += 1
        unpinEventEventIdReceivedEventId = eventId
        DispatchQueue.main.async {
            self.unpinEventEventIdReceivedInvocations.append(eventId)
        }
        if let unpinEventEventIdClosure = unpinEventEventIdClosure {
            return try await unpinEventEventIdClosure(eventId)
        } else {
            return unpinEventEventIdReturnValue
        }
    }
}
open class TimelineDiffSDKMock: MatrixRustSDK.TimelineDiff {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - append

    var appendUnderlyingCallsCount = 0
    open var appendCallsCount: Int {
        get {
            if Thread.isMainThread {
                return appendUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = appendUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                appendUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    appendUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var appendCalled: Bool {
        return appendCallsCount > 0
    }

    var appendUnderlyingReturnValue: [TimelineItem]?
    open var appendReturnValue: [TimelineItem]? {
        get {
            if Thread.isMainThread {
                return appendUnderlyingReturnValue
            } else {
                var returnValue: [TimelineItem]?? = nil
                DispatchQueue.main.sync {
                    returnValue = appendUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                appendUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    appendUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var appendClosure: (() -> [TimelineItem]?)?

    open override func append() -> [TimelineItem]? {
        appendCallsCount += 1
        if let appendClosure = appendClosure {
            return appendClosure()
        } else {
            return appendReturnValue
        }
    }

    //MARK: - change

    var changeUnderlyingCallsCount = 0
    open var changeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return changeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = changeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                changeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    changeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var changeCalled: Bool {
        return changeCallsCount > 0
    }

    var changeUnderlyingReturnValue: TimelineChange!
    open var changeReturnValue: TimelineChange! {
        get {
            if Thread.isMainThread {
                return changeUnderlyingReturnValue
            } else {
                var returnValue: TimelineChange? = nil
                DispatchQueue.main.sync {
                    returnValue = changeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                changeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    changeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var changeClosure: (() -> TimelineChange)?

    open override func change() -> TimelineChange {
        changeCallsCount += 1
        if let changeClosure = changeClosure {
            return changeClosure()
        } else {
            return changeReturnValue
        }
    }

    //MARK: - insert

    var insertUnderlyingCallsCount = 0
    open var insertCallsCount: Int {
        get {
            if Thread.isMainThread {
                return insertUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = insertUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                insertUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    insertUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var insertCalled: Bool {
        return insertCallsCount > 0
    }

    var insertUnderlyingReturnValue: InsertData?
    open var insertReturnValue: InsertData? {
        get {
            if Thread.isMainThread {
                return insertUnderlyingReturnValue
            } else {
                var returnValue: InsertData?? = nil
                DispatchQueue.main.sync {
                    returnValue = insertUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                insertUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    insertUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var insertClosure: (() -> InsertData?)?

    open override func insert() -> InsertData? {
        insertCallsCount += 1
        if let insertClosure = insertClosure {
            return insertClosure()
        } else {
            return insertReturnValue
        }
    }

    //MARK: - pushBack

    var pushBackUnderlyingCallsCount = 0
    open var pushBackCallsCount: Int {
        get {
            if Thread.isMainThread {
                return pushBackUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = pushBackUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pushBackUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    pushBackUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var pushBackCalled: Bool {
        return pushBackCallsCount > 0
    }

    var pushBackUnderlyingReturnValue: TimelineItem?
    open var pushBackReturnValue: TimelineItem? {
        get {
            if Thread.isMainThread {
                return pushBackUnderlyingReturnValue
            } else {
                var returnValue: TimelineItem?? = nil
                DispatchQueue.main.sync {
                    returnValue = pushBackUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pushBackUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    pushBackUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var pushBackClosure: (() -> TimelineItem?)?

    open override func pushBack() -> TimelineItem? {
        pushBackCallsCount += 1
        if let pushBackClosure = pushBackClosure {
            return pushBackClosure()
        } else {
            return pushBackReturnValue
        }
    }

    //MARK: - pushFront

    var pushFrontUnderlyingCallsCount = 0
    open var pushFrontCallsCount: Int {
        get {
            if Thread.isMainThread {
                return pushFrontUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = pushFrontUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pushFrontUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    pushFrontUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var pushFrontCalled: Bool {
        return pushFrontCallsCount > 0
    }

    var pushFrontUnderlyingReturnValue: TimelineItem?
    open var pushFrontReturnValue: TimelineItem? {
        get {
            if Thread.isMainThread {
                return pushFrontUnderlyingReturnValue
            } else {
                var returnValue: TimelineItem?? = nil
                DispatchQueue.main.sync {
                    returnValue = pushFrontUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                pushFrontUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    pushFrontUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var pushFrontClosure: (() -> TimelineItem?)?

    open override func pushFront() -> TimelineItem? {
        pushFrontCallsCount += 1
        if let pushFrontClosure = pushFrontClosure {
            return pushFrontClosure()
        } else {
            return pushFrontReturnValue
        }
    }

    //MARK: - remove

    var removeUnderlyingCallsCount = 0
    open var removeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return removeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = removeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    removeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var removeCalled: Bool {
        return removeCallsCount > 0
    }

    var removeUnderlyingReturnValue: UInt32?
    open var removeReturnValue: UInt32? {
        get {
            if Thread.isMainThread {
                return removeUnderlyingReturnValue
            } else {
                var returnValue: UInt32?? = nil
                DispatchQueue.main.sync {
                    returnValue = removeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                removeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    removeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var removeClosure: (() -> UInt32?)?

    open override func remove() -> UInt32? {
        removeCallsCount += 1
        if let removeClosure = removeClosure {
            return removeClosure()
        } else {
            return removeReturnValue
        }
    }

    //MARK: - reset

    var resetUnderlyingCallsCount = 0
    open var resetCallsCount: Int {
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
    open var resetCalled: Bool {
        return resetCallsCount > 0
    }

    var resetUnderlyingReturnValue: [TimelineItem]?
    open var resetReturnValue: [TimelineItem]? {
        get {
            if Thread.isMainThread {
                return resetUnderlyingReturnValue
            } else {
                var returnValue: [TimelineItem]?? = nil
                DispatchQueue.main.sync {
                    returnValue = resetUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                resetUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    resetUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var resetClosure: (() -> [TimelineItem]?)?

    open override func reset() -> [TimelineItem]? {
        resetCallsCount += 1
        if let resetClosure = resetClosure {
            return resetClosure()
        } else {
            return resetReturnValue
        }
    }

    //MARK: - set

    var setUnderlyingCallsCount = 0
    open var setCallsCount: Int {
        get {
            if Thread.isMainThread {
                return setUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = setUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    setUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var setCalled: Bool {
        return setCallsCount > 0
    }

    var setUnderlyingReturnValue: SetData?
    open var setReturnValue: SetData? {
        get {
            if Thread.isMainThread {
                return setUnderlyingReturnValue
            } else {
                var returnValue: SetData?? = nil
                DispatchQueue.main.sync {
                    returnValue = setUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                setUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    setUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var setClosure: (() -> SetData?)?

    open override func set() -> SetData? {
        setCallsCount += 1
        if let setClosure = setClosure {
            return setClosure()
        } else {
            return setReturnValue
        }
    }

    //MARK: - truncate

    var truncateUnderlyingCallsCount = 0
    open var truncateCallsCount: Int {
        get {
            if Thread.isMainThread {
                return truncateUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = truncateUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                truncateUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    truncateUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var truncateCalled: Bool {
        return truncateCallsCount > 0
    }

    var truncateUnderlyingReturnValue: UInt32?
    open var truncateReturnValue: UInt32? {
        get {
            if Thread.isMainThread {
                return truncateUnderlyingReturnValue
            } else {
                var returnValue: UInt32?? = nil
                DispatchQueue.main.sync {
                    returnValue = truncateUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                truncateUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    truncateUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var truncateClosure: (() -> UInt32?)?

    open override func truncate() -> UInt32? {
        truncateCallsCount += 1
        if let truncateClosure = truncateClosure {
            return truncateClosure()
        } else {
            return truncateReturnValue
        }
    }
}
open class TimelineEventSDKMock: MatrixRustSDK.TimelineEvent {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - eventId

    var eventIdUnderlyingCallsCount = 0
    open var eventIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return eventIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = eventIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                eventIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    eventIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var eventIdCalled: Bool {
        return eventIdCallsCount > 0
    }

    var eventIdUnderlyingReturnValue: String!
    open var eventIdReturnValue: String! {
        get {
            if Thread.isMainThread {
                return eventIdUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = eventIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                eventIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    eventIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var eventIdClosure: (() -> String)?

    open override func eventId() -> String {
        eventIdCallsCount += 1
        if let eventIdClosure = eventIdClosure {
            return eventIdClosure()
        } else {
            return eventIdReturnValue
        }
    }

    //MARK: - eventType

    open var eventTypeThrowableError: Error?
    var eventTypeUnderlyingCallsCount = 0
    open var eventTypeCallsCount: Int {
        get {
            if Thread.isMainThread {
                return eventTypeUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = eventTypeUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                eventTypeUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    eventTypeUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var eventTypeCalled: Bool {
        return eventTypeCallsCount > 0
    }

    var eventTypeUnderlyingReturnValue: TimelineEventType!
    open var eventTypeReturnValue: TimelineEventType! {
        get {
            if Thread.isMainThread {
                return eventTypeUnderlyingReturnValue
            } else {
                var returnValue: TimelineEventType? = nil
                DispatchQueue.main.sync {
                    returnValue = eventTypeUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                eventTypeUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    eventTypeUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var eventTypeClosure: (() throws -> TimelineEventType)?

    open override func eventType() throws -> TimelineEventType {
        if let error = eventTypeThrowableError {
            throw error
        }
        eventTypeCallsCount += 1
        if let eventTypeClosure = eventTypeClosure {
            return try eventTypeClosure()
        } else {
            return eventTypeReturnValue
        }
    }

    //MARK: - senderId

    var senderIdUnderlyingCallsCount = 0
    open var senderIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return senderIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = senderIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                senderIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    senderIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var senderIdCalled: Bool {
        return senderIdCallsCount > 0
    }

    var senderIdUnderlyingReturnValue: String!
    open var senderIdReturnValue: String! {
        get {
            if Thread.isMainThread {
                return senderIdUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = senderIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                senderIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    senderIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var senderIdClosure: (() -> String)?

    open override func senderId() -> String {
        senderIdCallsCount += 1
        if let senderIdClosure = senderIdClosure {
            return senderIdClosure()
        } else {
            return senderIdReturnValue
        }
    }

    //MARK: - timestamp

    var timestampUnderlyingCallsCount = 0
    open var timestampCallsCount: Int {
        get {
            if Thread.isMainThread {
                return timestampUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = timestampUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                timestampUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    timestampUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var timestampCalled: Bool {
        return timestampCallsCount > 0
    }

    var timestampUnderlyingReturnValue: UInt64!
    open var timestampReturnValue: UInt64! {
        get {
            if Thread.isMainThread {
                return timestampUnderlyingReturnValue
            } else {
                var returnValue: UInt64? = nil
                DispatchQueue.main.sync {
                    returnValue = timestampUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                timestampUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    timestampUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var timestampClosure: (() -> UInt64)?

    open override func timestamp() -> UInt64 {
        timestampCallsCount += 1
        if let timestampClosure = timestampClosure {
            return timestampClosure()
        } else {
            return timestampReturnValue
        }
    }
}
open class TimelineEventTypeFilterSDKMock: MatrixRustSDK.TimelineEventTypeFilter {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!
    static func reset()
    {
    }
}
open class TimelineItemSDKMock: MatrixRustSDK.TimelineItem {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - asEvent

    var asEventUnderlyingCallsCount = 0
    open var asEventCallsCount: Int {
        get {
            if Thread.isMainThread {
                return asEventUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = asEventUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                asEventUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    asEventUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var asEventCalled: Bool {
        return asEventCallsCount > 0
    }

    var asEventUnderlyingReturnValue: EventTimelineItem?
    open var asEventReturnValue: EventTimelineItem? {
        get {
            if Thread.isMainThread {
                return asEventUnderlyingReturnValue
            } else {
                var returnValue: EventTimelineItem?? = nil
                DispatchQueue.main.sync {
                    returnValue = asEventUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                asEventUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    asEventUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var asEventClosure: (() -> EventTimelineItem?)?

    open override func asEvent() -> EventTimelineItem? {
        asEventCallsCount += 1
        if let asEventClosure = asEventClosure {
            return asEventClosure()
        } else {
            return asEventReturnValue
        }
    }

    //MARK: - asVirtual

    var asVirtualUnderlyingCallsCount = 0
    open var asVirtualCallsCount: Int {
        get {
            if Thread.isMainThread {
                return asVirtualUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = asVirtualUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                asVirtualUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    asVirtualUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var asVirtualCalled: Bool {
        return asVirtualCallsCount > 0
    }

    var asVirtualUnderlyingReturnValue: VirtualTimelineItem?
    open var asVirtualReturnValue: VirtualTimelineItem? {
        get {
            if Thread.isMainThread {
                return asVirtualUnderlyingReturnValue
            } else {
                var returnValue: VirtualTimelineItem?? = nil
                DispatchQueue.main.sync {
                    returnValue = asVirtualUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                asVirtualUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    asVirtualUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var asVirtualClosure: (() -> VirtualTimelineItem?)?

    open override func asVirtual() -> VirtualTimelineItem? {
        asVirtualCallsCount += 1
        if let asVirtualClosure = asVirtualClosure {
            return asVirtualClosure()
        } else {
            return asVirtualReturnValue
        }
    }

    //MARK: - fmtDebug

    var fmtDebugUnderlyingCallsCount = 0
    open var fmtDebugCallsCount: Int {
        get {
            if Thread.isMainThread {
                return fmtDebugUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = fmtDebugUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                fmtDebugUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    fmtDebugUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var fmtDebugCalled: Bool {
        return fmtDebugCallsCount > 0
    }

    var fmtDebugUnderlyingReturnValue: String!
    open var fmtDebugReturnValue: String! {
        get {
            if Thread.isMainThread {
                return fmtDebugUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = fmtDebugUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                fmtDebugUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    fmtDebugUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var fmtDebugClosure: (() -> String)?

    open override func fmtDebug() -> String {
        fmtDebugCallsCount += 1
        if let fmtDebugClosure = fmtDebugClosure {
            return fmtDebugClosure()
        } else {
            return fmtDebugReturnValue
        }
    }

    //MARK: - uniqueId

    var uniqueIdUnderlyingCallsCount = 0
    open var uniqueIdCallsCount: Int {
        get {
            if Thread.isMainThread {
                return uniqueIdUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = uniqueIdUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                uniqueIdUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    uniqueIdUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var uniqueIdCalled: Bool {
        return uniqueIdCallsCount > 0
    }

    var uniqueIdUnderlyingReturnValue: String!
    open var uniqueIdReturnValue: String! {
        get {
            if Thread.isMainThread {
                return uniqueIdUnderlyingReturnValue
            } else {
                var returnValue: String? = nil
                DispatchQueue.main.sync {
                    returnValue = uniqueIdUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                uniqueIdUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    uniqueIdUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var uniqueIdClosure: (() -> String)?

    open override func uniqueId() -> String {
        uniqueIdCallsCount += 1
        if let uniqueIdClosure = uniqueIdClosure {
            return uniqueIdClosure()
        } else {
            return uniqueIdReturnValue
        }
    }
}
open class TimelineItemContentSDKMock: MatrixRustSDK.TimelineItemContent {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - asMessage

    var asMessageUnderlyingCallsCount = 0
    open var asMessageCallsCount: Int {
        get {
            if Thread.isMainThread {
                return asMessageUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = asMessageUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                asMessageUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    asMessageUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var asMessageCalled: Bool {
        return asMessageCallsCount > 0
    }

    var asMessageUnderlyingReturnValue: Message?
    open var asMessageReturnValue: Message? {
        get {
            if Thread.isMainThread {
                return asMessageUnderlyingReturnValue
            } else {
                var returnValue: Message?? = nil
                DispatchQueue.main.sync {
                    returnValue = asMessageUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                asMessageUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    asMessageUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var asMessageClosure: (() -> Message?)?

    open override func asMessage() -> Message? {
        asMessageCallsCount += 1
        if let asMessageClosure = asMessageClosure {
            return asMessageClosure()
        } else {
            return asMessageReturnValue
        }
    }

    //MARK: - kind

    var kindUnderlyingCallsCount = 0
    open var kindCallsCount: Int {
        get {
            if Thread.isMainThread {
                return kindUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = kindUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                kindUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    kindUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var kindCalled: Bool {
        return kindCallsCount > 0
    }

    var kindUnderlyingReturnValue: TimelineItemContentKind!
    open var kindReturnValue: TimelineItemContentKind! {
        get {
            if Thread.isMainThread {
                return kindUnderlyingReturnValue
            } else {
                var returnValue: TimelineItemContentKind? = nil
                DispatchQueue.main.sync {
                    returnValue = kindUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                kindUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    kindUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var kindClosure: (() -> TimelineItemContentKind)?

    open override func kind() -> TimelineItemContentKind {
        kindCallsCount += 1
        if let kindClosure = kindClosure {
            return kindClosure()
        } else {
            return kindReturnValue
        }
    }
}
open class UnreadNotificationsCountSDKMock: MatrixRustSDK.UnreadNotificationsCount {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - hasNotifications

    var hasNotificationsUnderlyingCallsCount = 0
    open var hasNotificationsCallsCount: Int {
        get {
            if Thread.isMainThread {
                return hasNotificationsUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = hasNotificationsUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                hasNotificationsUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    hasNotificationsUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var hasNotificationsCalled: Bool {
        return hasNotificationsCallsCount > 0
    }

    var hasNotificationsUnderlyingReturnValue: Bool!
    open var hasNotificationsReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return hasNotificationsUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = hasNotificationsUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                hasNotificationsUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    hasNotificationsUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var hasNotificationsClosure: (() -> Bool)?

    open override func hasNotifications() -> Bool {
        hasNotificationsCallsCount += 1
        if let hasNotificationsClosure = hasNotificationsClosure {
            return hasNotificationsClosure()
        } else {
            return hasNotificationsReturnValue
        }
    }

    //MARK: - highlightCount

    var highlightCountUnderlyingCallsCount = 0
    open var highlightCountCallsCount: Int {
        get {
            if Thread.isMainThread {
                return highlightCountUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = highlightCountUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                highlightCountUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    highlightCountUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var highlightCountCalled: Bool {
        return highlightCountCallsCount > 0
    }

    var highlightCountUnderlyingReturnValue: UInt32!
    open var highlightCountReturnValue: UInt32! {
        get {
            if Thread.isMainThread {
                return highlightCountUnderlyingReturnValue
            } else {
                var returnValue: UInt32? = nil
                DispatchQueue.main.sync {
                    returnValue = highlightCountUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                highlightCountUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    highlightCountUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var highlightCountClosure: (() -> UInt32)?

    open override func highlightCount() -> UInt32 {
        highlightCountCallsCount += 1
        if let highlightCountClosure = highlightCountClosure {
            return highlightCountClosure()
        } else {
            return highlightCountReturnValue
        }
    }

    //MARK: - notificationCount

    var notificationCountUnderlyingCallsCount = 0
    open var notificationCountCallsCount: Int {
        get {
            if Thread.isMainThread {
                return notificationCountUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = notificationCountUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                notificationCountUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    notificationCountUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var notificationCountCalled: Bool {
        return notificationCountCallsCount > 0
    }

    var notificationCountUnderlyingReturnValue: UInt32!
    open var notificationCountReturnValue: UInt32! {
        get {
            if Thread.isMainThread {
                return notificationCountUnderlyingReturnValue
            } else {
                var returnValue: UInt32? = nil
                DispatchQueue.main.sync {
                    returnValue = notificationCountUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                notificationCountUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    notificationCountUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var notificationCountClosure: (() -> UInt32)?

    open override func notificationCount() -> UInt32 {
        notificationCountCallsCount += 1
        if let notificationCountClosure = notificationCountClosure {
            return notificationCountClosure()
        } else {
            return notificationCountReturnValue
        }
    }
}
open class WidgetDriverSDKMock: MatrixRustSDK.WidgetDriver {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - run

    var runRoomCapabilitiesProviderUnderlyingCallsCount = 0
    open var runRoomCapabilitiesProviderCallsCount: Int {
        get {
            if Thread.isMainThread {
                return runRoomCapabilitiesProviderUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = runRoomCapabilitiesProviderUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                runRoomCapabilitiesProviderUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    runRoomCapabilitiesProviderUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var runRoomCapabilitiesProviderCalled: Bool {
        return runRoomCapabilitiesProviderCallsCount > 0
    }
    open var runRoomCapabilitiesProviderReceivedArguments: (room: Room, capabilitiesProvider: WidgetCapabilitiesProvider)?
    open var runRoomCapabilitiesProviderReceivedInvocations: [(room: Room, capabilitiesProvider: WidgetCapabilitiesProvider)] = []
    open var runRoomCapabilitiesProviderClosure: ((Room, WidgetCapabilitiesProvider) async -> Void)?

    open override func run(room: Room, capabilitiesProvider: WidgetCapabilitiesProvider) async {
        runRoomCapabilitiesProviderCallsCount += 1
        runRoomCapabilitiesProviderReceivedArguments = (room: room, capabilitiesProvider: capabilitiesProvider)
        DispatchQueue.main.async {
            self.runRoomCapabilitiesProviderReceivedInvocations.append((room: room, capabilitiesProvider: capabilitiesProvider))
        }
        await runRoomCapabilitiesProviderClosure?(room, capabilitiesProvider)
    }
}
open class WidgetDriverHandleSDKMock: MatrixRustSDK.WidgetDriverHandle {
    init() {
        super.init(noPointer: .init())
    }

    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    fileprivate var pointer: UnsafeMutableRawPointer!

    //MARK: - recv

    var recvUnderlyingCallsCount = 0
    open var recvCallsCount: Int {
        get {
            if Thread.isMainThread {
                return recvUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = recvUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recvUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    recvUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var recvCalled: Bool {
        return recvCallsCount > 0
    }

    var recvUnderlyingReturnValue: String?
    open var recvReturnValue: String? {
        get {
            if Thread.isMainThread {
                return recvUnderlyingReturnValue
            } else {
                var returnValue: String?? = nil
                DispatchQueue.main.sync {
                    returnValue = recvUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                recvUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    recvUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var recvClosure: (() async -> String?)?

    open override func recv() async -> String? {
        recvCallsCount += 1
        if let recvClosure = recvClosure {
            return await recvClosure()
        } else {
            return recvReturnValue
        }
    }

    //MARK: - send

    var sendMsgUnderlyingCallsCount = 0
    open var sendMsgCallsCount: Int {
        get {
            if Thread.isMainThread {
                return sendMsgUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = sendMsgUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendMsgUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    sendMsgUnderlyingCallsCount = newValue
                }
            }
        }
    }
    open var sendMsgCalled: Bool {
        return sendMsgCallsCount > 0
    }
    open var sendMsgReceivedMsg: String?
    open var sendMsgReceivedInvocations: [String] = []

    var sendMsgUnderlyingReturnValue: Bool!
    open var sendMsgReturnValue: Bool! {
        get {
            if Thread.isMainThread {
                return sendMsgUnderlyingReturnValue
            } else {
                var returnValue: Bool? = nil
                DispatchQueue.main.sync {
                    returnValue = sendMsgUnderlyingReturnValue
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                sendMsgUnderlyingReturnValue = newValue
            } else {
                DispatchQueue.main.sync {
                    sendMsgUnderlyingReturnValue = newValue
                }
            }
        }
    }
    open var sendMsgClosure: ((String) async -> Bool)?

    open override func send(msg: String) async -> Bool {
        sendMsgCallsCount += 1
        sendMsgReceivedMsg = msg
        DispatchQueue.main.async {
            self.sendMsgReceivedInvocations.append(msg)
        }
        if let sendMsgClosure = sendMsgClosure {
            return await sendMsgClosure(msg)
        } else {
            return sendMsgReturnValue
        }
    }
}
// swiftlint:enable all
