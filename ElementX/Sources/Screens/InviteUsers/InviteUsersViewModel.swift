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

typealias InviteUsersViewModelType = StateStoreViewModel<InviteUsersViewState, InviteUsersViewAction>

class InviteUsersViewModel: InviteUsersViewModelType, InviteUsersViewModelProtocol {
    private let userSession: UserSessionProtocol
    private let actionsSubject: PassthroughSubject<InviteUsersViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<InviteUsersViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private let usersProvider: UsersProviderProtocol
    
    init(userSession: UserSessionProtocol, usersProvider: UsersProviderProtocol) {
        self.usersProvider = usersProvider
        self.userSession = userSession
        super.init(initialViewState: InviteUsersViewState(), imageProvider: userSession.mediaProvider)
        
        setupBindings()
    }
    
    // MARK: - Public
    
    override func process(viewAction: InviteUsersViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .proceed:
            break
        case .tapUser(let user):
            if state.isUserSelected(user) {
                deselect(user)
            } else {
                select(user)
            }
        case .deselectUser(let user):
            deselect(user)
        }
    }
    
    private func select(_ user: UserProfile) {
        state.selectedUsers.append(user)
        state.scrollToLastID = user.userID
    }
    
    private func deselect(_ user: UserProfile) {
        state.selectedUsers.removeAll(where: { $0.userID == user.userID })
        state.scrollToLastID = nil
    }

    // MARK: - Private
    
    private func setupBindings() {
        context.$viewState
            .map(\.bindings.searchQuery)
            .searchQuery()
            .sink { [weak self] _ in
                self?.fetchData()
            }
            .store(in: &cancellables)
    }
    
    private func fetchData() {
        guard searchQuery.count >= 3 else {
            fetchSuggestions()
            return
        }
        
        Task {
            let result = await usersProvider.searchProfiles(with: searchQuery)
            parseResultForSection(.searchResult, result: result)
        }
    }
    
    private func fetchSuggestions() {
        guard ServiceLocator.shared.settings.startChatUserSuggestionsEnabled else {
            state.usersSection = .init(type: .suggestions, users: [])
            return
        }
        Task {
            let result = await usersProvider.fetchSuggestions()
            parseResultForSection(.suggestions, result: result)
        }
    }
    
    private func parseResultForSection(_ type: SearchUserSectionType, result: Result<[UserProfile], ClientProxyError>) {
        switch result {
        case .success(let users):
            state.usersSection = .init(type: type, users: users)
        case .failure:
            break
        }
    }
    
    private var searchQuery: String {
        context.searchQuery
    }
}
