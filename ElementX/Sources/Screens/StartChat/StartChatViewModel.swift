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
    private let actionsSubject: PassthroughSubject<StartChatViewModelAction, Never> = .init()
    private let userDiscoveryService: UserDiscoveryServiceProtocol
    
    var actions: AnyPublisher<StartChatViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    weak var userIndicatorController: UserIndicatorControllerProtocol?
    
    init(userSession: UserSessionProtocol, userIndicatorController: UserIndicatorControllerProtocol?, userDiscoveryService: UserDiscoveryServiceProtocol) {
        self.userSession = userSession
        self.userIndicatorController = userIndicatorController
        self.userDiscoveryService = userDiscoveryService
        super.init(initialViewState: StartChatViewState(), imageProvider: userSession.mediaProvider)
        
        setupBindings()
    }
    
    // MARK: - Public
    
    override func process(viewAction: StartChatViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .createRoom:
            actionsSubject.send(.createRoom)
        case .inviteFriends:
            break
        case .selectUser(let user):
            showLoadingIndicator()
            Task {
                let currentDirectRoom = await clientProxy.directRoomForUserID(user.userID)
                switch currentDirectRoom {
                case .success(.some(let roomId)):
                    self.hideLoadingIndicator()
                    self.actionsSubject.send(.openRoom(withIdentifier: roomId))
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
            state.bindings.alertInfo = AlertInfo(id: .failedRetrievingDirectRoom,
                                                 title: L10n.commonError,
                                                 message: L10n.screenStartChatErrorStartingChat)
        case .failedCreatingRoom:
            state.bindings.alertInfo = AlertInfo(id: .failedCreatingRoom,
                                                 title: L10n.commonError,
                                                 message: L10n.screenStartChatErrorStartingChat)
        case .failedSearchingUsers:
            state.bindings.alertInfo = AlertInfo(id: .failedSearchingUsers)
        default:
            break
        }
    }
    
    private func setupBindings() {
        context.$viewState
            .map(\.bindings.searchQuery)
            .debounceAndRemoveDuplicates()
            .sink { [weak self] _ in
                self?.fetchUsers()
            }
            .store(in: &cancellables)
    }
    
    @CancellableTask
    private var searchTask: Task<Void, Never>?
    
    private func fetchUsers() {
        guard searchQuery.count >= 3 else {
            fetchSuggestions()
            return
        }
        suggestionTask = nil
        searchTask = Task {
            let result = await userDiscoveryService.searchProfiles(with: searchQuery)
            guard !Task.isCancelled else { return }
            handleResult(for: .searchResult, result: result)
        }
    }
    
    @CancellableTask
    private var suggestionTask: Task<Void, Never>?
    
    private func fetchSuggestions() {
        guard ServiceLocator.shared.settings.startChatUserSuggestionsEnabled else {
            state.usersSection = .init(type: .suggestions, users: [])
            return
        }
        searchTask = nil
        suggestionTask = Task {
            let result = await userDiscoveryService.fetchSuggestions()
            guard !Task.isCancelled else { return }
            handleResult(for: .suggestions, result: result)
        }
    }
    
    private func handleResult(for sectionType: SearchUserSectionType, result: Result<[UserProfile], UserDiscoveryErrorType>) {
        switch result {
        case .success(let users):
            state.usersSection = .init(type: sectionType, users: users)
        case .failure:
            break
        }
    }
    
    private func createDirectRoom(with user: UserProfile) async {
        showLoadingIndicator()
        let result = await clientProxy.createDirectRoom(with: user.userID)
        hideLoadingIndicator()
        switch result {
        case .success(let roomId):
            actionsSubject.send(.openRoom(withIdentifier: roomId))
        case .failure(let failure):
            displayError(failure)
        }
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
