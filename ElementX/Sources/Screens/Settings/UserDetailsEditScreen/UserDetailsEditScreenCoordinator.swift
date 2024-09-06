//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct UserDetailsEditScreenCoordinatorParameters {
    let orientationManager: OrientationManagerProtocol
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let userIndicatorController: UserIndicatorControllerProtocol
}

final class UserDetailsEditScreenCoordinator: CoordinatorProtocol {
    private let parameters: UserDetailsEditScreenCoordinatorParameters
    private var viewModel: UserDetailsEditScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: UserDetailsEditScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = UserDetailsEditScreenViewModel(clientProxy: parameters.clientProxy,
                                                   mediaProvider: parameters.mediaProvider,
                                                   userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                switch action {
                case .displayCameraPicker:
                    self?.displayMediaPickerWithSource(.camera)
                case .displayMediaPicker:
                    self?.displayMediaPickerWithSource(.photoLibrary)
                case .displayFilePicker:
                    self?.displayMediaPickerWithSource(.documents)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(UserDetailsEditScreen(context: viewModel.context))
    }
    
    // MARK: Private
    
    private func displayMediaPickerWithSource(_ source: MediaPickerScreenSource) {
        let stackCoordinator = NavigationStackCoordinator()
        
        let mediaPickerCoordinator = MediaPickerScreenCoordinator(userIndicatorController: parameters.userIndicatorController, source: source, orientationManager: parameters.orientationManager) { [weak self] action in
            guard let self else { return }
            switch action {
            case .cancel:
                parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
            case .selectMediaAtURL(let url):
                parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
                viewModel.didSelectMediaURL(url: url)
            }
        }
        
        stackCoordinator.setRootCoordinator(mediaPickerCoordinator)
        parameters.navigationStackCoordinator?.setSheetCoordinator(stackCoordinator)
    }
}
