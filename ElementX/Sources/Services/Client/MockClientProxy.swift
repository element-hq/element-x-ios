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

import Combine
import Foundation
import MatrixRustSDK

class MockClientProxy: ClientProxyProtocol {
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    let userID: String
    let deviceId: String? = nil
    let homeserver = ""
    let restorationToken: RestorationToken? = nil
    
    var visibleRoomsSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()
    
    var allRoomsSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()
    
    var invitesSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()

    var avatarURLPublisher: AnyPublisher<URL?, Never> { Empty().eraseToAnyPublisher() }
    
    internal init(userID: String, roomSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()) {
        self.userID = userID
        visibleRoomsSummaryProvider = roomSummaryProvider
    }

    func loadUserAvatarURL() async { }
    
    func startSync() { }
    
    func stopSync() { }
    
    func directRoomForUserID(_ userID: String) async -> Result<String?, ClientProxyError> {
        .failure(.failedRetrievingDirectRoom)
    }
    
    func createDirectRoom(with userID: String) async -> Result<String, ClientProxyError> {
        .failure(.failedCreatingRoom)
    }
    
    var roomInviter: RoomMemberProxyMock?
    @MainActor
    func roomForIdentifier(_ identifier: String) async -> RoomProxyProtocol? {
        guard let room = visibleRoomsSummaryProvider?.roomListPublisher.value.first(where: { $0.id == identifier }) else {
            return nil
        }
    
        switch room {
        case .empty:
            return RoomProxyMock(with: .init(displayName: "Empty room"))
        case .filled(let details), .invalidated(let details):
            let room = RoomProxyMock(with: .init(displayName: details.name))
            room.acceptInvitationReturnValue = .success(())
            room.inviterReturnValue = roomInviter
            return room
        }
    }
    
    func loadUserDisplayName() async -> Result<String, ClientProxyError> {
        .success("User display name")
    }
    
    func accountDataEvent<Content>(type: String) async -> Result<Content?, ClientProxyError> where Content: Decodable {
        .failure(.failedRetrievingAccountData)
    }
    
    func setAccountData<Content>(content: Content, type: String) async -> Result<Void, ClientProxyError> where Content: Encodable {
        .failure(.failedSettingAccountData)
    }
    
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        throw ClientProxyError.failedLoadingMedia
    }
    
    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        throw ClientProxyError.failedLoadingMedia
    }
    
    func loadMediaFileForSource(_ source: MediaSourceProxy) async throws -> MediaFileHandleProxy {
        throw ClientProxyError.failedLoadingMedia
    }
    
    var sessionVerificationControllerProxyResult: Result<SessionVerificationControllerProxyProtocol, ClientProxyError>?
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        if let sessionVerificationControllerProxyResult {
            return sessionVerificationControllerProxyResult
        } else {
            return .failure(.failedRetrievingSessionVerificationController)
        }
    }
    
    func logout() async {
        // no-op
    }
    
    var setPusherErrorToThrow: Error?
    var setPusherArgument: PusherConfiguration?
    var setPusherCalled = false

    func setPusher(with configuration: PusherConfiguration) async throws {
        if let setPusherErrorToThrow { throw setPusherErrorToThrow }
        setPusherCalled = true
        setPusherArgument = configuration
    }
    
    var searchUsersResult: Result<SearchUsersResults, ClientProxyError> = .success(.init(results: [], limited: false))
    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResults, ClientProxyError> {
        searchUsersResult
    }
    
    var getProfileResult: Result<UserProfile, ClientProxyError> = .success(.init(userID: "@a:b.com", displayName: "Some user"))
    private(set) var getProfileCalled = false
    func profile(for userID: String) async -> Result<UserProfile, ClientProxyError> {
        getProfileCalled = true
        return getProfileResult
    }
}
