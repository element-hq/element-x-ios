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
    let navigationController: NavigationController
    let timelineController: RoomTimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let roomName: String?
    let roomAvatarUrl: String?
}

final class RoomScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomScreenCoordinatorParameters

    private var viewModel: RoomScreenViewModelProtocol
    private var navigationController: NavigationController { parameters.navigationController }
    
    init(parameters: RoomScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomScreenViewModel(timelineController: parameters.timelineController,
                                        timelineViewFactory: RoomTimelineViewFactory(),
                                        mediaProvider: parameters.mediaProvider,
                                        roomName: parameters.roomName,
                                        roomAvatarUrl: parameters.roomAvatarUrl)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] result in
            guard let self else { return }
            MXLog.debug("RoomScreenViewModel did complete with result: \(result).")
            switch result {
            case .displayImage(let image):
                self.displayImage(image)
            case .displayVideo(let videoURL):
                self.displayVideo(for: videoURL)
            case .displayFile(let fileURL, let title):
                self.displayFile(for: fileURL, with: title)
            }
        }
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomScreen(context: viewModel.context))
    }

    // MARK: - Private

    private func displayVideo(for videoURL: URL) {
        let params = VideoPlayerCoordinatorParameters(videoURL: videoURL, isModallyPresented: false)
        let coordinator = VideoPlayerCoordinator(parameters: params)

        if params.isModallyPresented {
            coordinator.callback = { [weak self] _ in
                self?.navigationController.dismissSheet()
            }

            let controller = NavigationController()
            controller.setRootCoordinator(coordinator)

            navigationController.presentSheet(controller)
        } else {
            coordinator.callback = { [weak self] _ in
                self?.navigationController.pop()
            }

            navigationController.push(coordinator)
        }
    }

    private func displayImage(_ image: UIImage) {
        let params = ImageViewerCoordinatorParameters(navigationController: navigationController,
                                                      image: image,
                                                      isModallyPresented: false)
        let coordinator = ImageViewerCoordinator(parameters: params)

        if params.isModallyPresented {
            coordinator.callback = { [weak self] _ in
                self?.navigationController.dismissSheet()
            }

            let controller = NavigationController()
            controller.setRootCoordinator(coordinator)

            navigationController.presentSheet(controller)
        } else {
            coordinator.callback = { [weak self] _ in
                self?.navigationController.pop()
            }

            navigationController.push(coordinator)
        }
    }

    private func displayFile(for fileURL: URL, with title: String?) {
        let params = FilePreviewCoordinatorParameters(fileURL: fileURL, title: title)
        let coordinator = FilePreviewCoordinator(parameters: params)
        coordinator.callback = { [weak self] _ in
            self?.navigationController.pop()
        }
        
        navigationController.push(coordinator)
    }
}
