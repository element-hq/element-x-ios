//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

enum RoomProxyMockError: Error {
    case generic
}

@MainActor
struct JoinedRoomProxyMockConfiguration {
    var id = UUID().uuidString
    var name: String?
    var topic: String?
    var avatarURL: URL?
    var isDirect = false
    var isSpace = false
    var isEncrypted = true
    var hasOngoingCall = true
    var canonicalAlias: String?
    var alternativeAliases: [String] = []
    var pinnedEventIDs: Set<String> = []
    var historyVisibility: RoomHistoryVisibility = .shared
    
    var timelineStartReached = false
    
    var members: [RoomMemberProxyMock] = .allMembers
    var heroes: [RoomMemberProxyMock] = []
    var knockRequestsState: KnockRequestsState = .loaded([])
    var ownUserID = RoomMemberProxyMock.mockMe.userID
    var inviter: RoomMemberProxyProtocol?
    
    var shouldUseAutoUpdatingTimeline = false
    
    var joinRule: JoinRule? = .invite
    var membership: Membership = .joined
    
    var isVisibleInPublicDirectory = false
    var predecessor: PredecessorRoom?
    var successor: SuccessorRoom?
    
    var powerLevelsConfiguration = RoomPowerLevelsProxyMockConfiguration()
}

extension JoinedRoomProxyMock {
    @MainActor
    convenience init(_ configuration: JoinedRoomProxyMockConfiguration) {
        self.init()

        id = configuration.id

        timeline = TimelineProxyMock(.init(isAutoUpdating: configuration.shouldUseAutoUpdatingTimeline,
                                           timelineStartReached: configuration.timelineStartReached))
        
        pinnedEventsTimelineReturnValue = .failure(.failedCreatingPinnedTimeline)

        ownUserID = configuration.ownUserID
        
        membersPublisher = CurrentValueSubject(configuration.members).asCurrentValuePublisher()
        knockRequestsStatePublisher = CurrentValueSubject(configuration.knockRequestsState).asCurrentValuePublisher()
        typingMembersPublisher = CurrentValueSubject([]).asCurrentValuePublisher()
        identityStatusChangesPublisher = CurrentValueSubject([]).asCurrentValuePublisher()

        updateMembersClosure = { }
        setNameClosure = { _ in .success(()) }
        setTopicClosure = { _ in .success(()) }
        getMemberUserIDClosure = { [weak self] userID in
            guard let member = self?.membersPublisher.value.first(where: { $0.userID == userID }) else {
                return .failure(.sdkError(RoomProxyMockError.generic))
            }
            return .success(member)
        }
        
        ignoreDeviceTrustAndResendDevicesSendHandleReturnValue = .success(())
        withdrawVerificationAndResendUserIDsSendHandleReturnValue = .success(())

        flagAsUnreadReturnValue = .success(())
        markAsReadReceiptTypeReturnValue = .success(())
        flagAsFavouriteReturnValue = .success(())
        
        applyPowerLevelChangesReturnValue = .success(())
        resetPowerLevelsReturnValue = .success(())
        suggestedRoleForClosure = { [weak self] userID in
            guard case .success(let member) = await self?.getMember(userID: userID) else {
                return .failure(.sdkError(RoomProxyMockError.generic))
            }
            return .success(member.role.rustRole)
        }
        updatePowerLevelsForUsersReturnValue = .success(())
        
        let powerLevelsProxyMock = RoomPowerLevelsProxyMock(configuration: configuration.powerLevelsConfiguration)
        
        powerLevelsProxyMock.canUserUserIDSendStateEventClosure = { [weak self] userID, _ in
            .success(self?.membersPublisher.value.first { $0.userID == userID }?.role ?? .user != .user)
        }
        powerLevelsProxyMock.canOwnUserSendStateEventClosure = { [weak self] _ in
            self?.membersPublisher.value.first { $0.userID == configuration.ownUserID }?.role ?? .user != .user
        }
        
        powerLevelsProxyMock.canUserKickUserIDClosure = { [weak self] userID in
            .success(self?.membersPublisher.value.first { $0.userID == userID }?.role ?? .user != .user)
        }
        powerLevelsProxyMock.canOwnUserKickClosure = { [weak self] in
            self?.membersPublisher.value.first { $0.userID == configuration.ownUserID }?.role ?? .user != .user
        }
        
        powerLevelsProxyMock.canUserBanUserIDClosure = { [weak self] userID in
            .success(self?.membersPublisher.value.first { $0.userID == userID }?.role ?? .user != .user)
        }
        powerLevelsProxyMock.canOwnUserBanClosure = { [weak self] in
            self?.membersPublisher.value.first { $0.userID == configuration.ownUserID }?.role ?? .user != .user
        }
        
        powerLevelsProxyMock.canOwnUserEditRolesAndPermissionsClosure = { [weak self] in
            self?.membersPublisher.value.first { $0.userID == configuration.ownUserID }?.role.isAdminOrHigher ?? false
        }
        
        powerLevelsReturnValue = .success(powerLevelsProxyMock)
        
        inviteUserIDReturnValue = .success(())
        kickUserReasonReturnValue = .success(())
        banUserReasonReturnValue = .success(())
        unbanUserReturnValue = .success(())
        
        let widgetDriver = ElementCallWidgetDriverMock()
        widgetDriver.underlyingMessagePublisher = .init()
        widgetDriver.underlyingActions = PassthroughSubject().eraseToAnyPublisher()
        
        guard let url = URL(string: "https://call.element.io/\(UUID().uuidString)#?appPrompt=false") else {
            fatalError()
        }
        
        widgetDriver.startBaseURLClientIDColorSchemeRageshakeURLAnalyticsConfigurationReturnValue = .success(url)
        
        elementCallWidgetDriverDeviceIDReturnValue = widgetDriver
        
        matrixToPermalinkReturnValue = .success(.homeDirectory)
        matrixToEventPermalinkReturnValue = .success(.homeDirectory)
        loadDraftThreadRootEventIDReturnValue = .success(nil)
        clearDraftThreadRootEventIDReturnValue = .success(())
        sendTypingNotificationIsTypingReturnValue = .success(())
        isVisibleInRoomDirectoryReturnValue = .success(configuration.isVisibleInPublicDirectory)
        
        predecessorRoom = configuration.predecessor

        let roomInfoProxyMock = RoomInfoProxyMock(configuration)
        roomInfoProxyMock.powerLevels = powerLevelsProxyMock
        
        infoPublisher = CurrentValueSubject(roomInfoProxyMock).asCurrentValuePublisher()
    }
}

extension RoomInfoProxyMock {
    @MainActor convenience init(_ configuration: JoinedRoomProxyMockConfiguration) {
        self.init()
        
        id = configuration.id
        isEncrypted = configuration.isEncrypted
        creators = []
        displayName = configuration.name
        rawName = configuration.name
        topic = configuration.topic
        avatarURL = configuration.avatarURL
        isDirect = configuration.isDirect
        isSpace = configuration.isSpace
        successor = configuration.successor
        isFavourite = false
        canonicalAlias = configuration.canonicalAlias
        alternativeAliases = configuration.alternativeAliases
        membership = configuration.membership
        inviter = configuration.inviter
        heroes = configuration.heroes.map(RoomHero.init)
        activeMembersCount = configuration.members.filter { $0.membership == .join || $0.membership == .invite }.count
        invitedMembersCount = configuration.members.filter { $0.membership == .invite }.count
        joinedMembersCount = configuration.members.filter { $0.membership == .join }.count
        highlightCount = 0
        notificationCount = 0
        cachedUserDefinedNotificationMode = .allMessages
        hasRoomCall = configuration.hasOngoingCall
        activeRoomCallParticipants = []
        isMarkedUnread = false
        unreadMessagesCount = 0
        unreadNotificationsCount = 0
        unreadMentionsCount = 0
        pinnedEventIDs = configuration.pinnedEventIDs
        joinRule = configuration.joinRule
        historyVisibility = configuration.historyVisibility
        
        powerLevels = RoomPowerLevelsProxyMock(configuration: configuration.powerLevelsConfiguration)
    }
}

private extension RoomHero {
    init(from memberProxy: RoomMemberProxyMock) {
        self.init(userId: memberProxy.userID,
                  displayName: memberProxy.displayName,
                  avatarUrl: memberProxy.avatarURL?.absoluteString)
    }
}

@MainActor
extension Array where Element == JoinedRoomProxyProtocol {
    static var mockRooms: [JoinedRoomProxyProtocol] {
        [
            JoinedRoomProxyMock(.init(id: "1", name: "Room Name", canonicalAlias: "#room-name:example.com")),
            JoinedRoomProxyMock(.init(id: "2", name: "Room Name", canonicalAlias: "#room-name:example.com")),
            JoinedRoomProxyMock(.init(id: "3", name: "Room Name", canonicalAlias: "#room-name:example.com"))
        ]
    }
}
