//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias InviteUsersScreenViewModelType = StateStoreViewModel<InviteUsersScreenViewState, InviteUsersScreenViewAction>

class InviteUsersScreenViewModel: InviteUsersScreenViewModelType, InviteUsersScreenViewModelProtocol {
    private let roomType: InviteUsersScreenRoomType
    private let userDiscoveryService: UserDiscoveryServiceProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var suggestedUsers = [UserProfileProxy]()
    
    private let actionsSubject: PassthroughSubject<InviteUsersScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<InviteUsersScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(clientProxy: ClientProxyProtocol,
         selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>,
         roomType: InviteUsersScreenRoomType,
         mediaProvider: MediaProviderProtocol,
         userDiscoveryService: UserDiscoveryServiceProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomType = roomType
        self.userDiscoveryService = userDiscoveryService
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: InviteUsersScreenViewState(selectedUsers: selectedUsers.value, isCreatingRoom: roomType.isCreatingRoom), mediaProvider: mediaProvider)
                
        setupSubscriptions(selectedUsers: selectedUsers)
        fetchMembersIfNeeded()
        
        Task {
            suggestedUsers = await clientProxy.recentConversationCounterparts()
            
            if state.usersSection.type == .suggestions {
                state.usersSection = .init(type: .suggestions, users: suggestedUsers)
            }
        }
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
    
    // periphery:ignore - automatically cancelled when set to nil
    @CancellableTask
    private var fetchUsersTask: Task<Void, Never>?
    
    private func setupSubscriptions(selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>) {
        context.$viewState
            .map(\.bindings.searchQuery)
            .debounceTextQueriesAndRemoveDuplicates()
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
        
        roomProxy.membersPublisher
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
            state.usersSection = .init(type: .suggestions, users: suggestedUsers)
            return
        }
        
        state.isSearching = true
        
        fetchUsersTask = Task {
            let result = await userDiscoveryService.searchProfiles(with: searchQuery)
            
            guard !Task.isCancelled else { return }
            
            state.isSearching = false
            
            switch result {
            case .success(let users):
                state.usersSection = .init(type: .searchResult, users: users)
            case .failure:
                break
            }
        }
    }
        
    private var searchQuery: String {
        context.searchQuery
    }
    
    private let userIndicatorID = UUID().uuidString
    
    private func showLoader() {
        userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID, type: .modal, title: L10n.commonLoading, persistent: true), delay: .milliseconds(200))
    }
    
    private func hideLoader() {
        userIndicatorController.retractIndicatorWithId(userIndicatorID)
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
