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
import SwiftUI

typealias StartChatViewModelType = StateStoreViewModel<StartChatViewState, StartChatViewAction>

class StartChatViewModel: StartChatViewModelType, StartChatViewModelProtocol {
    private let userSession: UserSessionProtocol
    
    var callback: ((StartChatViewModelAction) -> Void)?
    weak var userIndicatorController: UserIndicatorControllerProtocol?
    
    init(userSession: UserSessionProtocol, userIndicatorController: UserIndicatorControllerProtocol?) {
        self.userSession = userSession
        self.userIndicatorController = userIndicatorController
        super.init(initialViewState: StartChatViewState(), imageProvider: userSession.mediaProvider)
        
        setupBindings()
        fetchSuggestions()
    }
    
    // MARK: - Public
    
    override func process(viewAction: StartChatViewAction) async {
        switch viewAction {
        case .close:
            callback?(.close)
        case .createRoom:
            callback?(.createRoom)
        case .inviteFriends:
            break
        case .selectUser(let user):
            showLoadingIndicator()
            Task {
                let currentDirectRoom = await clientProxy.directRoomForUserID(user.userID)
                switch currentDirectRoom {
                case .success(.some(let roomId)):
                    self.hideLoadingIndicator()
                    self.callback?(.openRoom(withIdentifier: roomId))
                case .success(nil):
                    await self.createDirectRoom(with: user)
                case .failure(let failure):
                    self.hideLoadingIndicator()
                    self.displayError(failure)
                }
            }
        }
    }
    
    // MARK: - Private
    
    private func displayError(_ type: ClientProxyError) {
        switch type {
        case .failedRetrievingDirectRoom:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonError,
                                                 message: L10n.screenStartChatErrorStartingChat)
        case .failedCreatingRoom:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonError,
                                                 message: L10n.screenStartChatErrorStartingChat)
        default:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
    
    private func setupBindings() {
        context.$viewState
            .map(\.bindings.searchQuery)
            .map { query in
                // debounce search queries but make sure clearing the search updates immediately
                let milliseconds = query.isEmpty ? 0 : 500
                return Just(query).delay(for: .milliseconds(milliseconds), scheduler: DispatchQueue.main)
            }
            .switchToLatest()
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.fetchData()
            }
            .store(in: &cancellables)
    }
    
    private func fetchData() {
        if searchQuery.isValidSearchQuery {
            Task {
                await searchProfiles()
            }
        } else {
            fetchSuggestions()
        }
    }
    
    private func searchProfiles() async {
        // copies the current query to check later if fetched data must be shown or not
        let committedQuery = searchQuery
        
        async let queriedProfile = getProfileIfNeeded()
        async let searchedUsers = clientProxy.searchUsers(searchTerm: committedQuery, limit: 5)
        
        await updateState(committedQuery: committedQuery,
                          queriedProfile: queriedProfile,
                          searchResults: try? searchedUsers.get())
    }
    
    private func updateState(committedQuery: String, queriedProfile: UserProfile?, searchResults: SearchUsersResults?) {
        guard committedQuery == searchQuery else {
            return
        }
        
        let localProfile = queriedProfile ?? UserProfile(searchQuery: searchQuery)
        let allResults = merge(localProfile: localProfile, searchResults: searchResults?.results)
        
        state.usersSection = .init(type: .searchResult, users: allResults)
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
    
    private func fetchSuggestions() {
        state.usersSection = .init(type: .suggestions, users: [.mockAlice, .mockBob, .mockCharlie])
    }
    
    private func createDirectRoom(with user: UserProfile) async {
        showLoadingIndicator()
        let result = await clientProxy.createDirectRoom(with: user.userID)
        hideLoadingIndicator()
        switch result {
        case .success(let roomId):
            callback?(.openRoom(withIdentifier: roomId))
        case .failure(let failure):
            displayError(failure)
        }
    }
    
    private func getProfileIfNeeded() async -> UserProfile? {
        guard searchQuery.isMatrixIdentifier else {
            return nil
        }
        
        return try? await clientProxy.getProfile(for: searchQuery).get()
    }
    
    private var clientProxy: ClientProxyProtocol {
        userSession.clientProxy
    }
    
    private var searchQuery: String {
        context.searchQuery
    }
    
    // MARK: Loading indicator
    
    static let loadingIndicatorIdentifier = "StartChatLoading"
    
    private func showLoadingIndicator() {
        userIndicatorController?.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                               type: .modal,
                                                               title: L10n.commonLoading,
                                                               persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController?.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}

private extension String {
    var isValidSearchQuery: Bool {
        count >= 3
    }
    
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
