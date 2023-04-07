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

class UsersProvider: UsersProviderProtocol {
    var clientProxy: ClientProxyProtocol
    
    init(clientProxy: ClientProxyProtocol) {
        self.clientProxy = clientProxy
    }
    
    func fetchSuggestions() -> [UserProfile] {
        [.mockAlice, .mockBob, .mockCharlie]
    }
    
    func searchProfiles(with searchQuery: String) async -> [UserProfile] {
        let queriedProfile = await getProfileIfPossible(with: searchQuery)
        let searchedUsers = await clientProxy.searchUsers(searchTerm: searchQuery, limit: 5)
        let searchResults = try? searchedUsers.get()
        
        let localProfile = queriedProfile ?? UserProfile(searchQuery: searchQuery)
        let allResults = merge(localProfile: localProfile, searchResults: searchResults?.results)
        
        return allResults
    }
    
    private func merge(localProfile: UserProfile?, searchResults: [UserProfile]?) -> [UserProfile] {
        guard let localProfile else {
            return searchResults ?? []
        }
        
        let filteredSearchResult = searchResults?.filter {
            $0.userID != localProfile.userID
        } ?? []

        return [localProfile] + filteredSearchResult
    }
    
    private func getProfileIfPossible(with searchQuery: String) async -> UserProfile? {
        guard searchQuery.isMatrixIdentifier else {
            return nil
        }
        
        return try? await clientProxy.getProfile(for: searchQuery).get()
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
