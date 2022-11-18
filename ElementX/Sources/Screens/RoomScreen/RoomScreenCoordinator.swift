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
    let navigationStackCoordinator: NavigationStackCoordinator
    let timelineController: RoomTimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let roomName: String?
    let roomAvatarUrl: String?
    let emojiProvider: EmojiProviderProtocol
}

final class RoomScreenCoordinator: CoordinatorProtocol {
    private var parameters: RoomScreenCoordinatorParameters?

    private var viewModel: RoomScreenViewModelProtocol?
    private var navigationStackCoordinator: NavigationStackCoordinator {
        guard let parameters else {
            fatalError()
        }
        
        return parameters.navigationStackCoordinator
    }
    
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
        viewModel?.callback = { [weak self] result in
            guard let self else { return }
            MXLog.debug("RoomScreenViewModel did complete with result: \(result).")
            switch result {
            case .displayVideo(let videoURL):
                self.displayVideo(for: videoURL)
            case .displayFile(let fileURL, let title):
                self.displayFile(for: fileURL, with: title)
            case .displayEmojiPicker(let itemId):
                self.displayEmojiPickerScreen(for: itemId)
            }
        }
    }
    
    func stop() {
        viewModel?.stop()
        viewModel = nil
        parameters = nil
    }
    
    func toPresentable() -> AnyView {
        guard let context = viewModel?.context else {
            fatalError()
        }
        
        return AnyView(RoomScreen(context: context))
    }

    // MARK: - Private

    private func displayVideo(for videoURL: URL) {
        let params = VideoPlayerCoordinatorParameters(videoURL: videoURL, isModallyPresented: false)
        let coordinator = VideoPlayerCoordinator(parameters: params)

        if params.isModallyPresented {
            coordinator.callback = { [weak self] _ in
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }

            let controller = NavigationStackCoordinator()
            controller.setRootCoordinator(coordinator)

            navigationStackCoordinator.setSheetCoordinator(controller)
        } else {
            coordinator.callback = { [weak self] _ in
                self?.navigationStackCoordinator.pop()
            }

            navigationStackCoordinator.push(coordinator)
        }
    }

    private func displayFile(for fileURL: URL, with title: String?) {
        let params = FilePreviewCoordinatorParameters(fileURL: fileURL, title: title)
        let coordinator = FilePreviewCoordinator(parameters: params)
        coordinator.callback = { [weak self] _ in
            self?.navigationStackCoordinator.pop()
        }
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func displayEmojiPickerScreen(for itemId: String) {
        guard let emojiProvider = parameters?.emojiProvider,
              let timelineController = parameters?.timelineController else {
            fatalError()
        }
        let params = EmojiPickerScreenCoordinatorParameters(emojiProvider: emojiProvider,
                                                            itemId: itemId)
        let coordinator = EmojiPickerScreenCoordinator(parameters: params)
        coordinator.callback = { [weak self] action in
            switch action {
            case let .emojiSelected(emoji: emoji, itemId: itemId):
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
                MXLog.debug("Save \(emoji) for \(itemId)")
                Task {
                    await timelineController.sendReaction(emoji, for: itemId)
                }
            }
        }
        
        navigationStackCoordinator.setSheetCoordinator(coordinator)
    }
}
