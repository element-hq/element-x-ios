//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
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
    var isPublic = false
    var isEncrypted = true
    var hasOngoingCall = true
    var canonicalAlias: String?
    var alternativeAliases: [String] = []
    var pinnedEventIDs: Set<String> = []
    
    var timelineStartReached = false
    
    var members: [RoomMemberProxyMock] = .allMembers
    var heroes: [RoomMemberProxyMock] = []
    var knockRequestsState: KnockRequestsState = .loaded([])
    var ownUserID = RoomMemberProxyMock.mockMe.userID
    var inviter: RoomMemberProxyProtocol?
    
    var shouldUseAutoUpdatingTimeline = false
    
    var joinRule: JoinRule?
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
        
        infoPublisher = CurrentValueSubject(.init(roomInfo: .init(configuration))).asCurrentValuePublisher()
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
            return .success(member.role)
        }
        updatePowerLevelsForUsersReturnValue = .success(())
        
        let powerLevelsProxyMock = RoomPowerLevelsProxyMock(configuration: configuration.powerLevelsConfiguration)
        
        powerLevelsProxyMock.canUserUserIDSendStateEventClosure = { [weak self] userID, _ in
            .success(self?.membersPublisher.value.first { $0.userID == userID }?.role ?? .user != .user)
        }
        powerLevelsProxyMock.canUserKickUserIDClosure = { [weak self] userID in
            .success(self?.membersPublisher.value.first { $0.userID == userID }?.role ?? .user != .user)
        }
        powerLevelsProxyMock.canUserBanUserIDClosure = { [weak self] userID in
            .success(self?.membersPublisher.value.first { $0.userID == userID }?.role ?? .user != .user)
        }
        
        powerLevelsReturnValue = .success(powerLevelsProxyMock)
        
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
        sendCallNotificationIfNeededReturnValue = .success(())
        
        matrixToPermalinkReturnValue = .success(.homeDirectory)
        matrixToEventPermalinkReturnValue = .success(.homeDirectory)
        loadDraftThreadRootEventIDReturnValue = .success(nil)
        clearDraftThreadRootEventIDReturnValue = .success(())
        sendTypingNotificationIsTypingReturnValue = .success(())
        isVisibleInRoomDirectoryReturnValue = .success(configuration.isVisibleInPublicDirectory)
        
        predecessorRoom = configuration.predecessor
    }
}

extension RoomInfo {
    @MainActor init(_ configuration: JoinedRoomProxyMockConfiguration) {
        self.init(id: configuration.id,
                  encryptionState: configuration.isEncrypted ? .encrypted : .notEncrypted,
                  creator: nil,
                  displayName: configuration.name,
                  rawName: configuration.name,
                  topic: configuration.topic,
                  avatarUrl: configuration.avatarURL?.absoluteString,
                  isDirect: configuration.isDirect,
                  isPublic: configuration.isPublic,
                  isSpace: configuration.isSpace,
                  successorRoom: configuration.successor,
                  isFavourite: false,
                  canonicalAlias: configuration.canonicalAlias,
                  alternativeAliases: configuration.alternativeAliases,
                  membership: configuration.membership,
                  inviter: configuration.inviter.map { RoomMember(userId: $0.userID,
                                                                  displayName: $0.displayName,
                                                                  avatarUrl: $0.avatarURL?.absoluteString,
                                                                  membership: $0.membership,
                                                                  isNameAmbiguous: false,
                                                                  powerLevel: Int64($0.powerLevel),
                                                                  normalizedPowerLevel: Int64($0.powerLevel),
                                                                  isIgnored: $0.isIgnored,
                                                                  suggestedRoleForPowerLevel: $0.role,
                                                                  membershipChangeReason: $0.membershipChangeReason) },
                  heroes: configuration.heroes.map(RoomHero.init),
                  activeMembersCount: UInt64(configuration.members.filter { $0.membership == .join || $0.membership == .invite }.count),
                  invitedMembersCount: UInt64(configuration.members.filter { $0.membership == .invite }.count),
                  joinedMembersCount: UInt64(configuration.members.filter { $0.membership == .join }.count),
                  userPowerLevels: [:],
                  highlightCount: 0,
                  notificationCount: 0,
                  cachedUserDefinedNotificationMode: .allMessages,
                  hasRoomCall: configuration.hasOngoingCall,
                  activeRoomCallParticipants: [],
                  isMarkedUnread: false,
                  numUnreadMessages: 0,
                  numUnreadNotifications: 0,
                  numUnreadMentions: 0,
                  pinnedEventIds: Array(configuration.pinnedEventIDs),
                  joinRule: configuration.joinRule,
                  historyVisibility: .shared)
    }
}

private extension RoomHero {
    init(from memberProxy: RoomMemberProxyMock) {
        self.init(userId: memberProxy.userID,
                  displayName: memberProxy.displayName,
                  avatarUrl: memberProxy.avatarURL?.absoluteString)
    }
}
