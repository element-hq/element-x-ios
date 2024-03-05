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

import Foundation
import MatrixRustSDK

final class RoomMemberProxy: RoomMemberProxyProtocol {
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private let member: RoomMemberProtocol

    private let backgroundAccountDataTaskName = "SendAccountDataEvent"
    private var sendAccountDataEventBackgroundTask: BackgroundTaskProtocol?

    private let userInitiatedDispatchQueue = DispatchQueue(label: "io.element.elementx.roommemberproxy.userinitiated", qos: .userInitiated)

    init(member: RoomMemberProtocol, backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.backgroundTaskService = backgroundTaskService
        self.member = member
    }

    lazy var userID = member.userId()

    lazy var displayName = member.displayName()

    lazy var avatarURL = member.avatarUrl().flatMap(URL.init(string:))

    lazy var membership = member.membership()

    lazy var isAccountOwner = member.isAccountUser()

    lazy var isIgnored = member.isIgnored()
    
    lazy var powerLevel = Int(member.powerLevel())
    lazy var role = member.suggestedRoleForPowerLevel()
    lazy var canInviteUsers = member.canInvite()
    lazy var canKickUsers = member.canKick()
    lazy var canBanUsers = member.canBan()
    
    func canSendStateEvent(type: StateEventType) -> Bool {
        member.canSendState(stateEvent: type)
    }

    func ignoreUser() async -> Result<Void, RoomMemberProxyError> {
        sendAccountDataEventBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundAccountDataTaskName, isReusable: true)
        defer {
            sendAccountDataEventBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.member.ignore()
                return .success(())
            } catch {
                return .failure(.ignoreUserFailed)
            }
        }
    }

    func unignoreUser() async -> Result<Void, RoomMemberProxyError> {
        sendAccountDataEventBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundAccountDataTaskName, isReusable: true)
        defer {
            sendAccountDataEventBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.member.unignore()
                return .success(())
            } catch {
                return .failure(.unignoreUserFailed)
            }
        }
    }
}
