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
    private let mediaProvider: MediaProviderProtocol
    private let userDiscoveryService: UserDiscoveryServiceProtocol
    private let roomType: InviteUsersScreenRoomType
    private let actionsSubject: PassthroughSubject<InviteUsersScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<InviteUsersScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>,
         roomType: InviteUsersScreenRoomType,
         mediaProvider: MediaProviderProtocol,
         userDiscoveryService: UserDiscoveryServiceProtocol) {
        self.roomType = roomType
        self.mediaProvider = mediaProvider
        self.userDiscoveryService = userDiscoveryService
        super.init(initialViewState: InviteUsersScreenViewState(selectedUsers: selectedUsers.value, isCreatingRoom: roomType.isCreatingRoom), imageProvider: mediaProvider)
                
        buildMembershipStateIfNeeded()
        setupSubscriptions(selectedUsers: selectedUsers)
    }
    
    // MARK: - Public
    
    override func process(viewAction: InviteUsersScreenViewAction) {
        switch viewAction {
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
    
    private func buildMembershipStateIfNeeded() {
        guard case let .room(members, userIndicatorController) = roomType else {
            return
        }
        let indicatorID = UUID().uuidString
        userIndicatorController.submitIndicator(UserIndicator(id: indicatorID, type: .modal, title: L10n.commonLoading, persistent: true))
        
        Task.detached { [members] in
            // accessing RoomMember's properties is very slow. We need to do it in a background thread.
            let membershipState = members
                .reduce(into: [String: MembershipState]()) { partialResult, member in
                    partialResult[member.userID] = member.membership
                }
            
            Task { @MainActor in
                self.state.membershipState = membershipState
                userIndicatorController.retractIndicatorWithId(indicatorID)
            }
        }
    }

    // MARK: - Private
    
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
        guard ServiceLocator.shared.settings.userSuggestionsEnabled else {
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
