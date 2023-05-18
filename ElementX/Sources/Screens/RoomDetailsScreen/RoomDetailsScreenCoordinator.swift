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

struct RoomDetailsScreenCoordinatorParameters {
    let navigationStackCoordinator: NavigationStackCoordinator
    let roomProxy: RoomProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userDiscoveryService: UserDiscoveryServiceProtocol
}

enum RoomDetailsScreenCoordinatorAction {
    case cancel
    case leftRoom
}

final class RoomDetailsScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomDetailsScreenCoordinatorParameters
    private var viewModel: RoomDetailsScreenViewModelProtocol
    private var cancellables: Set<AnyCancellable> = .init()
    private let selectedUsers: CurrentValueSubject<[UserProfile], Never> = .init([])
    private var navigationStackCoordinator: NavigationStackCoordinator {
        parameters.navigationStackCoordinator
    }
    
    var callback: ((RoomDetailsScreenCoordinatorAction) -> Void)?
    
    init(parameters: RoomDetailsScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomDetailsScreenViewModel(roomProxy: parameters.roomProxy,
                                               mediaProvider: parameters.mediaProvider)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .requestMemberDetailsPresentation(let members):
                self.presentRoomMembersList(members)
            case .requestInvitePeoplePresentation(let members):
                self.presentInviteUsersScreen(members: members)
            case .cancel:
                self.callback?(.cancel)
            case .leftRoom:
                self.callback?(.leftRoom)
            }
        }
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomDetailsScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func presentRoomMembersList(_ members: [RoomMemberProxyProtocol]) {
        let params = RoomMembersListScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                                mediaProvider: parameters.mediaProvider,
                                                                members: members)
        let coordinator = RoomMembersListScreenCoordinator(parameters: params)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentInviteUsersScreen(members: [RoomMemberProxyProtocol]) {
        let inviteParameters = InviteUsersScreenCoordinatorParameters(selectedUsers: .init(selectedUsers),
                                                                      roomType: .room(members: members),
                                                                      mediaProvider: parameters.mediaProvider,
                                                                      userDiscoveryService: parameters.userDiscoveryService)
        let coordinator = InviteUsersScreenCoordinator(parameters: inviteParameters)
        let navigationStackCoordinator = NavigationStackCoordinator()
        navigationStackCoordinator.setRootCoordinator(coordinator)
        
        coordinator.actions.sink { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .proceed:
                break
            case .invite(let users):
                self.inviteUsers(users, in: parameters.roomProxy)
            case .toggleUser(let user):
                self.toggleUser(user)
            }
        }
        .store(in: &cancellables)
        
        parameters.navigationStackCoordinator.setSheetCoordinator(navigationStackCoordinator)
    }
    
    private func toggleUser(_ user: UserProfile) {
        var selectedUsers = selectedUsers.value
        if let index = selectedUsers.firstIndex(where: { $0.userID == user.userID }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
        self.selectedUsers.send(selectedUsers)
    }
    
    private func inviteUsers(_ users: [String], in room: RoomProxyProtocol) {
        navigationStackCoordinator.setSheetCoordinator(nil)
        
        Task {
            let result: Result<Void, RoomProxyError> = await withTaskGroup(of: Result<Void, RoomProxyError>.self) { group in
                for user in users {
                    group.addTask {
                        await room.invite(userID: user)
                    }
                }
                
                return await group.first { inviteResult in
                    inviteResult.isFailure
                } ?? .success(())
            }
            
            guard case .failure = result else {
                return
            }
            
            ServiceLocator.shared.userIndicatorController.alertInfo = .init(id: .init(),
                                                                            title: L10n.commonUnableToInviteTitle,
                                                                            message: L10n.commonUnableToInviteMessage)
        }
    }
}

private extension Result {
    var isFailure: Bool {
        switch self {
        case .success:
            return false
        case .failure:
            return true
        }
    }
}
