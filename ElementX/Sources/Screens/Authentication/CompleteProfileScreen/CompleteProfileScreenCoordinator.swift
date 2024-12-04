//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct CompleteProfileScreenParameters {
    let authenticationService: AuthenticationServiceProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    let orientationManager: OrientationManagerProtocol
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let inviteCode: String
}

final class CompleteProfileScreenCoordinator: CoordinatorProtocol {
    private let parameters: CompleteProfileScreenParameters
    private var viewModel: CompleteProfileScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<CompleteProfileScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<CompleteProfileScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: CompleteProfileScreenParameters) {
        self.parameters = parameters
        viewModel = CompleteProfileScreenViewModel(authenticationService: parameters.authenticationService,
                                                   userIndicatorController: parameters.userIndicatorController,
                                                   mediaUploadingPreprocessor: parameters.mediaUploadingPreprocessor,
                                                   inviteCode: parameters.inviteCode)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .displayCameraPicker:
                    self.displayMediaPickerWithSource(.camera)
                case .displayMediaPicker:
                    self.displayMediaPickerWithSource(.photoLibrary)
                case .signedIn(let userSession):
                    actionsSubject.send(.signedIn(userSession))
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(CompleteProfileScreen(context: viewModel.context))
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
