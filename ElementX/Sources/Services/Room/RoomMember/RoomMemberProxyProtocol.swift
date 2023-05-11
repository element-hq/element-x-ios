//
// Copyright 2022 New Vector Ltd
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

enum RoomMemberProxyError: Error {
    case ignoreUserFailed
    case unignoreUserFailed
}

// sourcery: AutoMockable
protocol RoomMemberProxyProtocol {
    var userID: String { get }
    var displayName: String? { get }
    var avatarURL: URL? { get }
    var membership: MembershipState { get }
    var isNameAmbiguous: Bool { get }
    var powerLevel: Int { get }
    var normalizedPowerLevel: Int { get }
    var isAccountOwner: Bool { get }
    var isIgnored: Bool { get }

    func ignoreUser() async -> Result<Void, RoomMemberProxyError>
    func unignoreUser() async -> Result<Void, RoomMemberProxyError>
}

extension RoomMemberProxyProtocol {
    var permalink: URL? {
        try? PermalinkBuilder.permalinkTo(userIdentifier: userID)
    }
}
