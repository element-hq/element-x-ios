//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct CreateRoomCoordinatorParameters {
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let createRoomParameters: CurrentValuePublisher<CreateRoomFlowParameters, Never>
    let selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>
    let appSettings: AppSettings
    let analytics: AnalyticsService
}

enum CreateRoomCoordinatorAction {
    case openRoom(withIdentifier: String)
    case deselectUser(UserProfileProxy)
    case updateDetails(CreateRoomFlowParameters)
    case displayMediaPickerWithMode(MediaPickerScreenMode)
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
                                        analytics: parameters.analytics,
                                        userIndicatorController: parameters.userIndicatorController,
                                        appSettings: parameters.appSettings)
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
                actionsSubject.send(.displayMediaPickerWithMode(.init(source: .camera, selectionType: .single)))
            case .displayMediaPicker:
                actionsSubject.send(.displayMediaPickerWithMode(.init(source: .photoLibrary, selectionType: .single)))
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
