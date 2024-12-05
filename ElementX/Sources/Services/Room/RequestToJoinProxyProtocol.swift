//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum RequestToJoinProxyError: Error {
    case sdkError(Error)
}

// sourcery: AutoMockable
protocol RequestToJoinProxyProtocol {
    var eventID: String { get }
    var userID: String { get }
    var displayName: String? { get }
    var avatarURL: URL? { get }
    var reason: String? { get }
    var formattedTimestamp: String? { get }
    var isSeen: Bool { get }
    
    func accept() async -> Result<Void, RequestToJoinProxyError>
    func decline() async -> Result<Void, RequestToJoinProxyError>
    func ban() async -> Result<Void, RequestToJoinProxyError>
    func markAsSeen() async -> Result<Void, RequestToJoinProxyError>
}
