//
// Copyright 2024 New Vector Ltd
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
    let roomID: String
    let name: String?
    let topic: String?
    let avatarURL: URL?
    let canBeJoined: Bool
    
    var id: String {
        roomID
    }
}
