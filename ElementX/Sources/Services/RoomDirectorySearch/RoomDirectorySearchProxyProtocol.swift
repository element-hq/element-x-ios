//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

// sourcery: AutoMockable
protocol RoomDirectorySearchProxyProtocol {
    var resultsPublisher: CurrentValuePublisher<[RoomDirectorySearchResult], Never> { get }
    
    func search(query: String?) async -> Result<Void, RoomDirectorySearchError>
    func nextPage() async -> Result<Void, RoomDirectorySearchError>
}

enum RoomDirectorySearchError: Error {
    case searchFailed
    case nextPageQueryFailed
}

struct RoomDirectorySearchResult: Identifiable {
    let id: String
    let alias: String?
    let name: String?
    let topic: String?
    let avatar: RoomAvatar
    let canBeJoined: Bool
}
