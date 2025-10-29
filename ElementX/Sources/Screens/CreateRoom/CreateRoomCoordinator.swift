//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct CreateRoomCoordinatorParameters {
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let appSettings: AppSettings
    let analytics: AnalyticsService
}

enum CreateRoomCoordinatorAction {
    case createdRoom(JoinedRoomProxyProtocol)
    case displayMediaPickerWithMode(MediaPickerScreenMode)
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
                                        analytics: parameters.analytics,
                                        userIndicatorController: parameters.userIndicatorController,
                                        appSettings: parameters.appSettings)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .createdRoom(let roomProxy):
                actionsSubject.send(.createdRoom(roomProxy))
            case .displayCameraPicker:
                actionsSubject.send(.displayMediaPickerWithMode(.init(source: .camera, selectionType: .single)))
            case .displayMediaPicker:
                actionsSubject.send(.displayMediaPickerWithMode(.init(source: .photoLibrary, selectionType: .single)))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(CreateRoomScreen(context: viewModel.context))
    }
    
    func updateAvatar(fileURL: URL) {
        viewModel.updateAvatar(fileURL: fileURL)
    }
}
