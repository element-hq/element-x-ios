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
    var searchTask: Task<Void, Error>? {
        didSet { oldValue?.cancel() }
    }
    
    init(userSession: UserSessionProtocol, userIndicatorController: UserIndicatorControllerProtocol?) {
        self.userSession = userSession
        self.userIndicatorController = userIndicatorController
        super.init(initialViewState: StartChatViewState(), imageProvider: userSession.mediaProvider)
        
        setupBindings()
        fetchSuggestion()
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
                let currentDirectRoom = await userSession.clientProxy.directRoomForUserID(user.userID)
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
    
    func displayError(_ type: ClientProxyError) {
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
    
    // MARK: - Private
    
    private func setupBindings() {
        context.$viewState
            .map(\.bindings.searchQuery)
            .removeDuplicates()
            .map { query in
                let milliseconds = query.isEmpty ? 0 : 500
                return Just(query).delay(for: .milliseconds(milliseconds), scheduler: DispatchQueue.main)
            }
            .switchToLatest()
            .sink { [weak self] query in
                self?.updateState(searchQuery: query)
            }
            .store(in: &cancellables)
    }
    
    private func updateState(searchQuery: String) {
        if searchQuery.count < 3 {
            fetchSuggestion()
        } else if MatrixEntityRegex.isMatrixUserIdentifier(searchQuery) {
            state.usersSection = .init(type: .searchResult, users: [UserProfileProxy(userID: searchQuery)])
        } else {
            searchUsers(serachTerm: searchQuery)
        }
    }
    
    private func fetchSuggestion() {
        state.usersSection = .init(type: .suggestions, users: [.mockAlice, .mockBob, .mockCharlie])
    }
    
    private func createDirectRoom(with user: UserProfileProxy) async {
        showLoadingIndicator()
        let result = await userSession.clientProxy.createDirectRoom(with: user.userID)
        hideLoadingIndicator()
        switch result {
        case .success(let roomId):
            callback?(.openRoom(withIdentifier: roomId))
        case .failure(let failure):
            displayError(failure)
        }
    }
    
    private func searchUsers(serachTerm: String) {
        searchTask = Task {
            let result = try await userSession.clientProxy.searchUsers(searchTerm: serachTerm, limit: 5)
            
            guard !Task.isCancelled else {
                return
            }
            
            await MainActor.run {
                state.usersSection = .init(type: .searchResult, users: result.results)
            }
        }
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
