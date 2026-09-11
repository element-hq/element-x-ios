//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCallAll

/// Serves the call package's room port from a room proxy.
///
/// Deliberately not in the package, even though the underlying data is all in the SDK. The proxy is
/// an asset rather than a wrapper: it keeps a cached current value for room info and members,
/// refreshed off the SDK's own subscription, and reads members from disk before the network. A
/// version built on the raw SDK would re-derive all of that and lose the caching.
final class NativeCallRoomContextAdapter: ElementCallRoomContext {
    private let roomProxy: JoinedRoomProxyProtocol
    
    init(roomProxy: JoinedRoomProxyProtocol) {
        self.roomProxy = roomProxy
        Task { await roomProxy.updateMembers() }
    }
    
    var roomID: String {
        roomProxy.id
    }
    
    var displayName: String {
        roomProxy.infoPublisher.value.displayNameOrID
    }
    
    var displayNamePublisher: AnyPublisher<String, Never> {
        roomProxy.infoPublisher
            .map(\.displayNameOrID)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    var isDirect: Bool {
        roomProxy.infoPublisher.value.isDirect
    }
    
    var isDirectPublisher: AnyPublisher<Bool, Never> {
        roomProxy.infoPublisher.map(\.isDirect).removeDuplicates().eraseToAnyPublisher()
    }
    
    var memberProfiles: [String: ElementCallMemberProfile] {
        Self.profiles(from: roomProxy.membersPublisher.value)
    }
    
    var memberProfilesPublisher: AnyPublisher<[String: ElementCallMemberProfile], Never> {
        roomProxy.membersPublisher.map(Self.profiles).eraseToAnyPublisher()
    }
    
    private static func profiles(from members: [RoomMemberProxyProtocol]) -> [String: ElementCallMemberProfile] {
        Dictionary(members.map { ($0.userID, ElementCallMemberProfile(userID: $0.userID,
                                                                      displayName: $0.displayName,
                                                                      avatarURL: $0.avatarURL)) }) { first, _ in first }
    }
}
