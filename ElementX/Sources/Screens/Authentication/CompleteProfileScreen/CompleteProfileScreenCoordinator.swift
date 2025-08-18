//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct CompleteProfileScreenParameters {
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    let orientationManager: OrientationManagerProtocol
    let appSettings: AppSettings
    weak var navigationCoordinator: NavigationStackCoordinator?
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
        viewModel = CompleteProfileScreenViewModel(clientProxy: parameters.clientProxy,
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
                    self.presentMediaUploadPickerWithMode(.init(source: .camera, selectionType: .single))
                case .displayMediaPicker:
                    self.presentMediaUploadPickerWithMode(.init(source: .photoLibrary, selectionType: .single))
                case .profileUpdated:
                    actionsSubject.send(.profileUpdated)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(CompleteProfileScreen(context: viewModel.context))
    }
    
    // MARK: Private
    
    private func presentMediaUploadPickerWithMode(_ mode: MediaPickerScreenMode) {
        let stackCoordinator = NavigationStackCoordinator()
        
        let mediaPickerCoordinator = MediaPickerScreenCoordinator(mode: mode,
                                                                  appSettings: parameters.appSettings,
                                                                  userIndicatorController: parameters.userIndicatorController,
                                                                  orientationManager: parameters.orientationManager) { [weak self] action in
            guard let self else {
                return
            }
            switch action {
            case .cancel:
                parameters.navigationCoordinator?.setSheetCoordinator(nil)
            case .selectedMediaAtURLs(let urls):
                if let url = urls.first {
                    parameters.navigationCoordinator?.setSheetCoordinator(nil)
                    viewModel.didSelectMediaURL(url: url)
                }
            }
        }
        stackCoordinator.setRootCoordinator(mediaPickerCoordinator)
        parameters.navigationCoordinator?.setSheetCoordinator(stackCoordinator)
    }
}
