//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct UserDetailsEditScreenCoordinatorParameters {
    let orientationManager: OrientationManagerProtocol
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let userIndicatorController: UserIndicatorControllerProtocol
    let appSettings: AppSettings
}

final class UserDetailsEditScreenCoordinator: CoordinatorProtocol {
    private let parameters: UserDetailsEditScreenCoordinatorParameters
    private var viewModel: UserDetailsEditScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: UserDetailsEditScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = UserDetailsEditScreenViewModel(clientProxy: parameters.clientProxy,
                                                   mediaProvider: parameters.mediaProvider,
                                                   mediaUploadingPreprocessor: parameters.mediaUploadingPreprocessor,
                                                   userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                switch action {
                case .displayCameraPicker:
                    self?.displayMediaPickerWithMode(.init(source: .camera, selectionType: .single))
                case .displayMediaPicker:
                    self?.displayMediaPickerWithMode(.init(source: .photoLibrary, selectionType: .single))
                case .displayFilePicker:
                    self?.displayMediaPickerWithMode(.init(source: .documents, selectionType: .single))
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
                                                                  appSettings: parameters.appSettings,
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
