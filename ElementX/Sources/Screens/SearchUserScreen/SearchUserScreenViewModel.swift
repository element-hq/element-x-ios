//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias SearchUserScreenViewModelType = StateStoreViewModel<SearchUserScreenViewState, SearchUserScreenViewAction>

class SearchUserScreenViewModel: SearchUserScreenViewModelType, SearchUserScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let userDiscoveryService: UserDiscoveryServiceProtocol
    private let appSettings: AppSettings
    
    private var suggestedUsers = [UserProfileProxy]()
    
    private let actionsSubject: PassthroughSubject<SearchUserScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SearchUserScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         userDiscoveryService: UserDiscoveryServiceProtocol,
         appSettings: AppSettings) {
        self.clientProxy = userSession.clientProxy
        self.userDiscoveryService = userDiscoveryService
        self.appSettings = appSettings
        
        super.init(initialViewState: SearchUserScreenViewState(), mediaProvider: userSession.mediaProvider)
        
        setupBindings()
        
        Task {
            suggestedUsers = await clientProxy.recentConversationCounterparts()
            
            if state.usersSection.type == .suggestions {
                state.usersSection = .init(type: .suggestions, users: suggestedUsers)
            }
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: SearchUserScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .selectUser(let user):
            actionsSubject.send(.selectUser(user))
        }
    }
    
    private func setupBindings() {
        context.$viewState
            .map(\.bindings.searchQuery)
            .debounceTextQueriesAndRemoveDuplicates()
            .sink { [weak self] _ in
                self?.fetchUsers()
            }
            .store(in: &cancellables)
    }
    
    // periphery:ignore - auto cancels when reassigned
    @CancellableTask
    private var fetchUsersTask: Task<Void, Never>?
    
    private func fetchUsers() {
        guard context.searchQuery.count >= 2 else {
            state.usersSection = .init(type: .suggestions, users: suggestedUsers)
            return
        }
        
        fetchUsersTask = Task {
            let result = await userDiscoveryService.searchProfiles(with: context.searchQuery)
            
            guard !Task.isCancelled else { return }
            
            switch result {
            case .success(let users):
                state.usersSection = .init(type: .searchResult, users: users)
            case .failure:
                break
            }
        }
    }
}
