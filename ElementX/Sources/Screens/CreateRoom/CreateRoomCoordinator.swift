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

struct CreateRoomCoordinatorParameters {
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let createRoomParameters: CurrentValuePublisher<CreateRoomFlowParameters, Never>
    let selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>
}

enum CreateRoomCoordinatorAction {
    case openRoom(withIdentifier: String)
    case deselectUser(UserProfileProxy)
    case updateDetails(CreateRoomFlowParameters)
    case displayMediaPickerWithSource(MediaPickerScreenSource)
    case removeImage
}

final class CreateRoomCoordinator: CoordinatorProtocol {
    private var viewModel: CreateRoomViewModelProtocol
    private let actionsSubject: PassthroughSubject<CreateRoomCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<CreateRoomCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: CreateRoomCoordinatorParameters) {
        viewModel = CreateRoomViewModel(userSession: parameters.userSession,
                                        createRoomParameters: parameters.createRoomParameters,
                                        selectedUsers: parameters.selectedUsers,
                                        analytics: ServiceLocator.shared.analytics,
                                        userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .deselectUser(let user):
                actionsSubject.send(.deselectUser(user))
            case .openRoom(let identifier):
                actionsSubject.send(.openRoom(withIdentifier: identifier))
            case .updateDetails(let details):
                actionsSubject.send(.updateDetails(details))
            case .displayCameraPicker:
                actionsSubject.send(.displayMediaPickerWithSource(.camera))
            case .displayMediaPicker:
                actionsSubject.send(.displayMediaPickerWithSource(.photoLibrary))
            case .removeImage:
                actionsSubject.send(.removeImage)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(CreateRoomScreen(context: viewModel.context))
    }
}
