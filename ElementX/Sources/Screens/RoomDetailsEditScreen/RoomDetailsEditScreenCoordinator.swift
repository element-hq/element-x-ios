//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomDetailsEditScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let userSession: UserSessionProtocol
    let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let userIndicatorController: UserIndicatorControllerProtocol
    let orientationManager: OrientationManagerProtocol
    let appSettings: AppSettings
}

enum RoomDetailsEditScreenCoordinatorAction {
    case dismiss
}

final class RoomDetailsEditScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomDetailsEditScreenCoordinatorParameters
    private var viewModel: RoomDetailsEditScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<RoomDetailsEditScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<RoomDetailsEditScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomDetailsEditScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomDetailsEditScreenViewModel(roomProxy: parameters.roomProxy,
                                                   userSession: parameters.userSession,
                                                   mediaUploadingPreprocessor: parameters.mediaUploadingPreprocessor,
                                                   userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                switch action {
                case .cancel, .saveFinished:
                    self?.actionsSubject.send(.dismiss)
                case .displayCameraPicker:
                    self?.displayMediaPickerWithMode(.init(source: .camera, selectionType: .single))
                case .displayMediaPicker:
                    self?.displayMediaPickerWithMode(.init(source: .photoLibrary, selectionType: .single))
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomDetailsEditScreen(context: viewModel.context))
    }
    
    // MARK: Private
    
    private func displayMediaPickerWithMode(_ mode: MediaPickerScreenMode) {
        let stackCoordinator = NavigationStackCoordinator()
        
        let mediaPickerCoordinator = MediaPickerScreenCoordinator(mode: mode,
                                                                  userIndicatorController: parameters.userIndicatorController,
                                                                  orientationManager: parameters.orientationManager) { [weak self] action in
            guard let self else { return }
            switch action {
            case .cancel:
                parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
            case .selectedMediaAtURLs(let urls):
                guard urls.count == 1,
                      let url = urls.first else {
                    fatalError("Received an invalid number of URLs")
                }
                
                parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
                viewModel.didSelectMediaUrl(url: url)
            }
        }
        
        stackCoordinator.setRootCoordinator(mediaPickerCoordinator)
        parameters.navigationStackCoordinator?.setSheetCoordinator(stackCoordinator)
    }
}
