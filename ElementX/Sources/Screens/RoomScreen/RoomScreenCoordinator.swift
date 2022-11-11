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

import SwiftUI

struct RoomScreenCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let timelineController: RoomTimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let roomName: String?
    let roomAvatarUrl: String?
}

final class RoomScreenCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: RoomScreenCoordinatorParameters
    private let roomScreenHostingController: UIViewController
    private var roomScreenViewModel: RoomScreenViewModelProtocol
    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(parameters: RoomScreenCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = RoomScreenViewModel(timelineController: parameters.timelineController,
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            mediaProvider: parameters.mediaProvider,
                                            roomName: parameters.roomName,
                                            roomAvatarUrl: parameters.roomAvatarUrl)
        
        let view = RoomScreen(context: viewModel.context)
        roomScreenViewModel = viewModel
        roomScreenHostingController = UIHostingController(rootView: view)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("Did start.")
        roomScreenViewModel.callback = { [weak self] result in
            guard let self else { return }
            MXLog.debug("RoomScreenViewModel did complete with result: \(result).")
            switch result {
            case .displayMedia(let mediaURL):
                self.displayMedia(for: mediaURL)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        roomScreenHostingController
    }

    func stop() {
        roomScreenViewModel.stop()
    }

    // MARK: - Private

    private func displayMedia(for mediaURL: URL) {
        let params = MediaPlayerCoordinatorParameters(mediaURL: mediaURL)
        let coordinator = MediaPlayerCoordinator(parameters: params)
        coordinator.callback = { [weak self, weak coordinator] _ in
            guard let self, let coordinator = coordinator else { return }
            self.navigationRouter.popModule(animated: true)
            self.remove(childCoordinator: coordinator)
        }

        add(childCoordinator: coordinator)
        coordinator.start()
        navigationRouter.push(coordinator) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
}
