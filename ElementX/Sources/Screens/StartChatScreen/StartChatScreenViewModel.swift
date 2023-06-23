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

typealias StartChatScreenViewModelType = StateStoreViewModel<StartChatScreenViewState, StartChatScreenViewAction>

class StartChatScreenViewModel: StartChatScreenViewModelType, StartChatScreenViewModelProtocol {
    private let userSession: UserSessionProtocol
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private weak var userIndicatorController: UserIndicatorControllerProtocol?
    private let userDiscoveryService: UserDiscoveryServiceProtocol
    
    private let actionsSubject: PassthroughSubject<StartChatScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<StartChatScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol?,
         userDiscoveryService: UserDiscoveryServiceProtocol) {
        self.userSession = userSession
        self.appSettings = appSettings
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        self.userDiscoveryService = userDiscoveryService
        
        super.init(initialViewState: StartChatScreenViewState(userID: userSession.userID), imageProvider: userSession.mediaProvider)
        
        setupBindings()
    }
    
    // MARK: - Public
    
    override func process(viewAction: StartChatScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .createRoom:
            actionsSubject.send(.createRoom)
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
        case .failedCreatingRoom, .failedRetrievingDirectRoom:
            state.bindings.alertInfo = AlertInfo(id: .failedCreatingRoom,
                                                 title: L10n.commonError,
                                                 message: L10n.screenStartChatErrorStartingChat)
        case .failedSearchingUsers:
            state.bindings.alertInfo = AlertInfo(id: .unknown)
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
        guard appSettings.userSuggestionsEnabled else {
            state.usersSection = .init(type: .suggestions, users: [])
            return
        }
        fetchUsersTask = Task {
            let result = await userDiscoveryService.fetchSuggestions()
            guard !Task.isCancelled else { return }
            handleResult(for: .suggestions, result: result)
        }
    }
    
    private func handleResult(for sectionType: UserDiscoverySectionType, result: Result<[UserProfileProxy], UserDiscoveryErrorType>) {
        switch result {
        case .success(let users):
            state.usersSection = .init(type: sectionType, users: users)
        case .failure:
            break
        }
    }
    
    private func createDirectRoom(with user: UserProfileProxy) async {
        defer {
            hideLoadingIndicator()
        }
        showLoadingIndicator()
        switch await clientProxy.createDirectRoom(with: user.userID, expectedRoomName: user.displayName) {
        case .success(let roomId):
            analytics.trackCreatedRoom(isDM: true)
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
    
    private static let loadingIndicatorIdentifier = "StartChatLoading"
    
    private func showLoadingIndicator() {
        userIndicatorController?.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                               type: .modal(progress: .indeterminate, interactiveDismissDisabled: true),
                                                               title: L10n.commonLoading,
                                                               persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController?.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
