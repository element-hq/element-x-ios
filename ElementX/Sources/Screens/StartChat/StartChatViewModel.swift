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
    
    var actions: AnyPublisher<StartChatViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    private let usersProvider: UsersProviderProtocol
    
    weak var userIndicatorController: UserIndicatorControllerProtocol?
    
    init(userSession: UserSessionProtocol, userIndicatorController: UserIndicatorControllerProtocol?, usersProvider: UsersProviderProtocol) {
        self.userSession = userSession
        self.userIndicatorController = userIndicatorController
        self.usersProvider = usersProvider
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
            state.usersSection = .init(type: .empty, users: [])
            return
        }
        Task {
            let result = await usersProvider.fetchSuggestions()
            parseResultForSection(.suggestions, result: result)
        }
    }
    
    private func parseResultForSection(_ type: StartChatUserSectionType, result: Result<[UserProfile], ClientProxyError>) {
        switch result {
        case .success(let users):
            state.usersSection = .init(type: type, users: users)
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
