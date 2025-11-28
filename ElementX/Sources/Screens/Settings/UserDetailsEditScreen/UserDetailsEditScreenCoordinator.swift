//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct UserDetailsEditScreenCoordinatorParameters {
    let orientationManager: OrientationManagerProtocol
    let userSession: UserSessionProtocol
    let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let userIndicatorController: UserIndicatorControllerProtocol
    let appSettings: AppSettings
}

enum UserDetailsEditScreenCoordinatorAction {
    case dismiss
}

final class UserDetailsEditScreenCoordinator: CoordinatorProtocol {
    private let parameters: UserDetailsEditScreenCoordinatorParameters
    private var viewModel: UserDetailsEditScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RoomDetailsEditScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<RoomDetailsEditScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: UserDetailsEditScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = UserDetailsEditScreenViewModel(userSession: parameters.userSession,
                                                   mediaUploadingPreprocessor: parameters.mediaUploadingPreprocessor,
                                                   userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    actionsSubject.send(.dismiss)
                case .displayCameraPicker:
                    displayMediaPickerWithMode(.init(source: .camera, selectionType: .single))
                case .displayMediaPicker:
                    displayMediaPickerWithMode(.init(source: .photoLibrary, selectionType: .single))
                case .displayFilePicker:
                    displayMediaPickerWithMode(.init(source: .documents, selectionType: .single))
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(UserDetailsEditScreen(context: viewModel.context))
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
                viewModel.didSelectMediaURL(url: url)
            }
        }
        
        stackCoordinator.setRootCoordinator(mediaPickerCoordinator)
        parameters.navigationStackCoordinator?.setSheetCoordinator(stackCoordinator)
    }
}
