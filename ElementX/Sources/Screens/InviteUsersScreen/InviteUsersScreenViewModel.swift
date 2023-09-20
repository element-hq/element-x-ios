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
import MatrixRustSDK
import SwiftUI

typealias InviteUsersScreenViewModelType = StateStoreViewModel<InviteUsersScreenViewState, InviteUsersScreenViewAction>

class InviteUsersScreenViewModel: InviteUsersScreenViewModelType, InviteUsersScreenViewModelProtocol {
    private let roomType: InviteUsersScreenRoomType
    private let mediaProvider: MediaProviderProtocol
    private let userDiscoveryService: UserDiscoveryServiceProtocol
    private let appSettings: AppSettings
    private weak var userIndicatorController: UserIndicatorControllerProtocol?
    
    private let actionsSubject: PassthroughSubject<InviteUsersScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<InviteUsersScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>,
         roomType: InviteUsersScreenRoomType,
         mediaProvider: MediaProviderProtocol,
         userDiscoveryService: UserDiscoveryServiceProtocol,
         appSettings: AppSettings,
         userIndicatorController: UserIndicatorControllerProtocol?) {
        self.roomType = roomType
        self.mediaProvider = mediaProvider
        self.userDiscoveryService = userDiscoveryService
        self.appSettings = appSettings
        self.userIndicatorController = userIndicatorController
        super.init(initialViewState: InviteUsersScreenViewState(selectedUsers: selectedUsers.value, isCreatingRoom: roomType.isCreatingRoom), imageProvider: mediaProvider)
                
        setupSubscriptions(selectedUsers: selectedUsers)
        fetchMembersIfNeeded()
    }
    
    // MARK: - Public
    
    override func process(viewAction: InviteUsersScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.cancel)
        case .proceed:
            switch roomType {
            case .draft:
                actionsSubject.send(.proceed)
            case .room:
                actionsSubject.send(.invite(users: state.selectedUsers.map(\.userID)))
            }
        case .toggleUser(let user):
            let willSelectUser = !state.selectedUsers.contains(user)
            state.scrollToLastID = willSelectUser ? user.userID : nil
            actionsSubject.send(.toggleUser(user))
        }
    }

    // MARK: - Private
    
    private func buildMembershipStateIfNeeded(members: [RoomMemberProxyProtocol]) {
        showLoader()
        
        Task.detached { [members] in
            // accessing RoomMember's properties is very slow. We need to do it in a background thread.
            let membershipState = members
                .reduce(into: [String: MembershipState]()) { partialResult, member in
                    partialResult[member.userID] = member.membership
                }
            
            Task { @MainActor in
                self.state.membershipState = membershipState
                self.hideLoader()
            }
        }
    }
    
    @CancellableTask
    private var fetchUsersTask: Task<Void, Never>?
    
    private func setupSubscriptions(selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>) {
        context.$viewState
            .map(\.bindings.searchQuery)
            .debounceAndRemoveDuplicates()
            .sink { [weak self] _ in
                self?.fetchUsers()
            }
            .store(in: &cancellables)
        
        selectedUsers
            .sink { [weak self] users in
                self?.state.selectedUsers = users
            }
            .store(in: &cancellables)
    }
    
    private func fetchMembersIfNeeded() {
        guard case let .room(roomProxy) = roomType else {
            return
        }
        
        Task {
            showLoader()
            await roomProxy.updateMembers()
            hideLoader()
        }
        
        roomProxy.members
            .filter { !$0.isEmpty }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] members in
                self?.buildMembershipStateIfNeeded(members: members)
            }
            .store(in: &cancellables)
    }
    
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
    
    private var searchQuery: String {
        context.searchQuery
    }
    
    private let userIndicatorID = UUID().uuidString
    
    private func showLoader() {
        userIndicatorController?.submitIndicator(UserIndicator(id: userIndicatorID, type: .modal, title: L10n.commonLoading, persistent: true), delay: .milliseconds(200))
    }
    
    private func hideLoader() {
        userIndicatorController?.retractIndicatorWithId(userIndicatorID)
    }
}

private extension InviteUsersScreenRoomType {
    var isCreatingRoom: Bool {
        switch self {
        case .draft:
            return true
        case .room:
            return false
        }
    }
}
