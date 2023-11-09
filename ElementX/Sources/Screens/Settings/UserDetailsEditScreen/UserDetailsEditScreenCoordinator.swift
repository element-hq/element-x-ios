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

struct UserDetailsEditScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum UserDetailsEditScreenCoordinatorAction { }

final class UserDetailsEditScreenCoordinator: CoordinatorProtocol {
    private let parameters: UserDetailsEditScreenCoordinatorParameters
    private var viewModel: UserDetailsEditScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<UserDetailsEditScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<UserDetailsEditScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
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
        
        let mediaPickerCoordinator = MediaPickerScreenCoordinator(userIndicatorController: parameters.userIndicatorController, source: source) { [weak self] action in
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
