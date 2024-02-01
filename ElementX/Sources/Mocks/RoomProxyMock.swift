//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation

struct RoomProxyMockConfiguration {
    var id = UUID().uuidString
    var name: String?
    let displayName: String?
    var topic: String?
    var avatarURL: URL?
    var isDirect = Bool.random()
    var isSpace = Bool.random()
    var isPublic = Bool.random()
    var isEncrypted = true
    var hasOngoingCall = true
    var canonicalAlias: String?
    var hasUnreadNotifications = Bool.random()
    
    var timeline = {
        let mock = TimelineProxyMock()
        mock.underlyingActions = Empty(completeImmediately: false).eraseToAnyPublisher()
        mock.timelineStartReached = false
        return mock
    }()
    
    var members: [RoomMemberProxyProtocol]?
    var memberForID: RoomMemberProxyMock = .mockMe
    var ownUserID = "@alice:somewhere.org"

    var canUserTriggerRoomNotification = false
    var canUserJoinCall = true
    
    var joinedMembersCount = 50
    var activeMembersCount = 25
}

extension RoomProxyMock {
    convenience init(with configuration: RoomProxyMockConfiguration) {
        self.init()

        id = configuration.id
        name = configuration.name
        displayName = configuration.displayName
        topic = configuration.topic
        avatarURL = configuration.avatarURL
        isDirect = configuration.isDirect
        isSpace = configuration.isSpace
        isPublic = configuration.isPublic
        isEncrypted = configuration.isEncrypted
        hasOngoingCall = configuration.hasOngoingCall
        canonicalAlias = configuration.canonicalAlias
        hasUnreadNotifications = configuration.hasUnreadNotifications
        
        timeline = configuration.timeline
        
        joinedMembersCount = configuration.joinedMembersCount
        activeMembersCount = configuration.activeMembersCount
        ownUserID = configuration.ownUserID

        if let configuredMembers = configuration.members {
            members = CurrentValueSubject(configuredMembers).asCurrentValuePublisher()
        } else {
            members = CurrentValueSubject([]).asCurrentValuePublisher()
        }

        updateMembersClosure = { }
        acceptInvitationClosure = { .success(()) }
        underlyingActions = Empty(completeImmediately: false).eraseToAnyPublisher()
        setNameClosure = { _ in .success(()) }
        setTopicClosure = { _ in .success(()) }
        getMemberUserIDReturnValue = .success(configuration.memberForID)
        canUserRedactOtherUserIDReturnValue = .success(false)
        canUserTriggerRoomNotificationUserIDReturnValue = .success(configuration.canUserTriggerRoomNotification)
        canUserJoinCallUserIDReturnValue = .success(configuration.canUserJoinCall)
        
        let widgetDriver = ElementCallWidgetDriverMock()
        widgetDriver.underlyingMessagePublisher = .init()
        widgetDriver.underlyingActions = PassthroughSubject().eraseToAnyPublisher()
        
        guard let url = URL(string: "https://call.element.dev/\(UUID().uuidString)#?appPrompt=false") else {
            fatalError()
        }
        
        widgetDriver.startBaseURLClientIDReturnValue = .success(url)
        
        elementCallWidgetDriverReturnValue = widgetDriver
    }
}
