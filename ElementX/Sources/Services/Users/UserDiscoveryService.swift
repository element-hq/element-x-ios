//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

final class UserDiscoveryService: UserDiscoveryServiceProtocol {
    private let clientProxy: ClientProxyProtocol
    
    init(clientProxy: ClientProxyProtocol) {
        self.clientProxy = clientProxy
    }
    
    func searchProfiles(with searchQuery: String) async -> Result<[UserProfile], UserDiscoveryErrorType> {
        async let queriedProfile = profileIfPossible(with: searchQuery)
        
        do {
            let searchedUsers = try await clientProxy.searchUsers(searchTerm: searchQuery, limit: 10).get()
            let users = await merge(queriedProfile: queriedProfile, searchResults: searchedUsers)
            return .success(filterAccountOwner(users))
        } catch {
            // we want to show the profile (if any) even if the search fails
            if let queriedProfile = await queriedProfile {
                return .success([queriedProfile])
            } else {
                return .failure(.failedSearchingUsers)
            }
        }
    }
    
    private func merge(queriedProfile: UserProfile?, searchResults: SearchUsersResultsProxy) -> [UserProfile] {
        let searchResults = searchResults.results
        
        guard let queriedProfile else {
            return searchResults
        }
        
        let filteredSearchResult = searchResults.filter {
            $0.id != queriedProfile.id
        }
        
        return [queriedProfile] + filteredSearchResult
    }
    
    private func profileIfPossible(with searchQuery: String) async -> UserProfile? {
        guard searchQuery.isMatrixIdentifier, searchQuery != clientProxy.userID else {
            return nil
        }
        
        let getProfileResult = try? await clientProxy.profile(for: searchQuery).get()
        
        // fallback to a "local profile" if the profile api fails
        return getProfileResult ?? .init(userID: searchQuery)
    }
    
    private func filterAccountOwner(_ profiles: [UserProfile]) -> [UserProfile] {
        let accountOwnerID = clientProxy.userID
        return profiles.filter { $0.id != accountOwnerID }
    }
}

private extension String {
    var isMatrixIdentifier: Bool {
        MatrixEntityRegex.isMatrixUserIdentifier(self)
    }
}
