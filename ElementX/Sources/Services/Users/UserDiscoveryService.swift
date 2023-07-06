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

    func fetchSuggestions() async -> Result<[UserProfileProxy], UserDiscoveryErrorType> {
        .success(filterAccountOwner([.mockAlice, .mockBob, .mockCharlie]))
    }

    func searchProfiles(with searchQuery: String) async -> Result<[UserProfileProxy], UserDiscoveryErrorType> {
        async let queriedProfile = profileIfPossible(with: searchQuery)

        do {
            async let searchedUsers = clientProxy.searchUsers(searchTerm: searchQuery, limit: 10).get()
            let users = try await merge(queriedProfile: queriedProfile, searchResults: searchedUsers)
            return .success(filterAccountOwner(users))
        } catch {
            // we want to show the profile (if any) even if the search fails
            if let queriedProfile = await queriedProfile {
                return .success(filterAccountOwner([queriedProfile]))
            } else {
                return .failure(.failedSearchingUsers)
            }
        }
    }

    private func merge(queriedProfile: UserProfileProxy?, searchResults: SearchUsersResultsProxy) -> [UserProfileProxy] {
        let searchResults = searchResults.results
        
        guard let queriedProfile else {
            return searchResults
        }

        let filteredSearchResult = searchResults.filter {
            $0.userID != queriedProfile.userID
        }

        return [queriedProfile] + filteredSearchResult
    }
    
    private func profileIfPossible(with searchQuery: String) async -> UserProfileProxy? {
        guard searchQuery.isMatrixIdentifier else {
            return nil
        }
        
        let getProfileResult = try? await clientProxy.profile(for: searchQuery).get()
        
        // fallback to a "local profile" if the profile api fails
        return getProfileResult ?? .init(userID: searchQuery)
    }

    private func filterAccountOwner(_ profiles: [UserProfileProxy]) -> [UserProfileProxy] {
        let accountOwnerID = clientProxy.userID
        return profiles.filter { $0.userID != accountOwnerID }
    }
}

private extension String {
    var isMatrixIdentifier: Bool {
        MatrixEntityRegex.isMatrixUserIdentifier(self)
    }
}
