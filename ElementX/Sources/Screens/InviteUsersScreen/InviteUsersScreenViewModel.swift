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

typealias InviteUsersScreenViewModelType = StateStoreViewModel<InviteUsersScreenViewState, InviteUsersScreenViewAction>

class InviteUsersScreenViewModel: InviteUsersScreenViewModelType, InviteUsersScreenViewModelProtocol {
    private let mediaProvider: MediaProviderProtocol
    private let userDiscoveryService: UserDiscoveryServiceProtocol
    private let roomContext: InviteUsersScreenRoomContext
    private let actionsSubject: PassthroughSubject<InviteUsersScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<InviteUsersScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(selectedUsers: CurrentValuePublisher<[UserProfile], Never>, userSession: UserSessionProtocol, userDiscoveryService: UserDiscoveryServiceProtocol) {
        self.userSession = userSession
    init(mediaProvider: MediaProviderProtocol, userDiscoveryService: UserDiscoveryServiceProtocol) {
        self.mediaProvider = mediaProvider
        self.userDiscoveryService = userDiscoveryService
        super.init(initialViewState: InviteUsersScreenViewState(selectedUsers: selectedUsers.value), imageProvider: userSession.mediaProvider)
        
        selectedUsers
            .sink { [weak self] users in
                self?.state.selectedUsers = users
            }
            .store(in: &cancellables)
        
        setupSubscriptions()
    }
    
    // MARK: - Public
    
    override func process(viewAction: InviteUsersScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .proceed:
            actionsSubject.send(.proceed)
        case .toggleUser(let user):
            actionsSubject.send(.toggleUser(user))
        }
    }

    // MARK: - Private
    
    private func setupSubscriptions() {
        context.$viewState
            .map(\.bindings.searchQuery)
            .debounceAndRemoveDuplicates()
            .sink { [weak self] _ in
                self?.fetchUsers()
            }
            .store(in: &cancellables)
    }
    
    @CancellableTask
    private var fetchUsersTask: Task<Void, Never>?
    
    private func fetchUsers() {
        guard searchQuery.count >= 3 else {
            fetchSuggestions()
            return
        }
        fetchUsersTask = Task {
            let result = await userDiscoveryService.searchProfiles(with: searchQuery)
            guard !Task.isCancelled else { return }
            handleResult(for: .searchResult, result: result)
        }
    }
    
    private func fetchSuggestions() {
        guard ServiceLocator.shared.settings.startChatUserSuggestionsEnabled else {
            state.usersSection = .init(type: .suggestions, users: [])
            return
        }
        fetchUsersTask = Task {
            let result = await userDiscoveryService.fetchSuggestions()
            guard !Task.isCancelled else { return }
            handleResult(for: .suggestions, result: result)
        }
    }
    
    private func handleResult(for sectionType: UserDiscoverySectionType, result: Result<[UserProfile], UserDiscoveryErrorType>) {
        switch result {
        case .success(let users):
            state.usersSection = .init(type: sectionType, users: users)
        case .failure:
            break
        }
    }
    
    private var searchQuery: String {
        context.searchQuery
    }
}

private extension InviteUsersScreenRoomContext {
    var isCreatingRoom: Bool {
        switch self {
        case .draftRoom:
            return true
        case .room:
            return false
        }
    }
}
