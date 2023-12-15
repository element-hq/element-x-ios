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
    let accountUserID: String
    let roomProxy: RoomProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let notificationSettings: NotificationSettingsProxyProtocol
    let attributedStringBuilder: AttributedStringBuilderProtocol
}

enum RoomDetailsScreenCoordinatorAction {
    case leftRoom
    case presentRoomMembersList
    case presentRoomDetailsEditScreen(accountOwner: RoomMemberProxyProtocol)
    case presentNotificationSettingsScreen
    case presentInviteUsersScreen
}

final class RoomDetailsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomDetailsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<RoomDetailsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
        
    var actions: AnyPublisher<RoomDetailsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
        
    init(parameters: RoomDetailsScreenCoordinatorParameters) {
        viewModel = RoomDetailsScreenViewModel(accountUserID: parameters.accountUserID,
                                               roomProxy: parameters.roomProxy,
                                               mediaProvider: parameters.mediaProvider,
                                               userIndicatorController: parameters.userIndicatorController,
                                               notificationSettingsProxy: parameters.notificationSettings,
                                               attributedStringBuilder: parameters.attributedStringBuilder)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .requestMemberDetailsPresentation:
                    actionsSubject.send(.presentRoomMembersList)
                case .requestInvitePeoplePresentation:
                    actionsSubject.send(.presentInviteUsersScreen)
                case .leftRoom:
                    actionsSubject.send(.leftRoom)
                case .requestEditDetailsPresentation(let accountOwner):
                    actionsSubject.send(.presentRoomDetailsEditScreen(accountOwner: accountOwner))
                case .requestNotificationSettingsPresentation:
                    actionsSubject.send(.presentNotificationSettingsScreen)
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomDetailsScreen(context: viewModel.context))
    }
}
