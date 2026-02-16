//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct CreateRoomScreenCoordinatorParameters {
    let isSpace: Bool
    let spaceSelectionMode: CreateRoomScreenSpaceSelectionMode
    let shouldShowCancelButton: Bool
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let appSettings: AppSettings
    let analytics: AnalyticsService
}

enum CreateRoomScreenCoordinatorAction {
    case createdRoom(JoinedRoomProxyProtocol, SpaceRoomListProxyProtocol?)
    case displayMediaPickerWithMode(MediaPickerScreenMode)
    case dismiss
}

final class CreateRoomScreenCoordinator: CoordinatorProtocol {
    private var viewModel: CreateRoomScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<CreateRoomScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<CreateRoomScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: CreateRoomScreenCoordinatorParameters) {
        viewModel = CreateRoomScreenViewModel(isSpace: parameters.isSpace,
                                              spaceSelectionMode: parameters.spaceSelectionMode,
                                              shouldShowCancelButton: parameters.shouldShowCancelButton,
                                              userSession: parameters.userSession,
                                              analytics: parameters.analytics,
                                              userIndicatorController: parameters.userIndicatorController,
                                              appSettings: parameters.appSettings)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .createdRoom(let roomProxy, let spaceRoomListProxy):
                actionsSubject.send(.createdRoom(roomProxy, spaceRoomListProxy))
            case .displayCameraPicker:
                actionsSubject.send(.displayMediaPickerWithMode(.init(source: .camera, selectionType: .single)))
            case .displayMediaPicker:
                actionsSubject.send(.displayMediaPickerWithMode(.init(source: .photoLibrary, selectionType: .single)))
            case .dismiss:
                actionsSubject.send(.dismiss)
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
