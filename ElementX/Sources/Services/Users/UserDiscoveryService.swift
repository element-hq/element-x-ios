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

final class UserDiscoveryService: UserDiscoveryServiceProtocol {
    private let clientProxy: ClientProxyProtocol
    
    init(clientProxy: ClientProxyProtocol) {
        self.clientProxy = clientProxy
    }
    
    func fetchSuggestions() async -> Result<[UserProfile], ClientProxyError> {
        .success([.mockAlice, .mockBob, .mockCharlie])
    }
    
    func searchProfiles(with searchQuery: String) async -> Result<[UserProfile], ClientProxyError> {
        do {
            async let queriedProfile = try? profileIfPossible(with: searchQuery).get()
            async let searchedUsers = clientProxy.searchUsers(searchTerm: searchQuery, limit: 5)
            let users = try await merge(searchQuery: searchQuery, queriedProfile: queriedProfile, searchResults: searchedUsers.get())
            return .success(users)
        } catch {
            return .failure(.failedSearchingUsers)
        }
    }
    
    private func merge(searchQuery: String, queriedProfile: UserProfile?, searchResults: SearchUsersResults) -> [UserProfile] {
        let localProfile = queriedProfile ?? UserProfile(searchQuery: searchQuery)
        let searchResults = searchResults.results
        guard let localProfile else {
            return searchResults
        }
        
        let filteredSearchResult = searchResults.filter {
            $0.userID != localProfile.userID
        }

        return [localProfile] + filteredSearchResult
    }
    
    private func profileIfPossible(with searchQuery: String) async -> Result<UserProfile?, ClientProxyError> {
        guard searchQuery.isMatrixIdentifier else {
            return .success(nil)
        }
        
        return await clientProxy.profile(for: searchQuery).map { $0 }
    }
}

private extension String {
    var isMatrixIdentifier: Bool {
        MatrixEntityRegex.isMatrixUserIdentifier(self)
    }
}

private extension UserProfile {
    init?(searchQuery: String) {
        guard searchQuery.isMatrixIdentifier else {
            return nil
        }
        self.init(userID: searchQuery)
    }
}
