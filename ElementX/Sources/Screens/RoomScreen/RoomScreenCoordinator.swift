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
    let roomProxy: RoomProxyProtocol
    let timelineController: RoomTimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let emojiProvider: EmojiProviderProtocol
}

enum RoomScreenCoordinatorAction {
    case leftRoom
}

final class RoomScreenCoordinator: CoordinatorProtocol {
    private var parameters: RoomScreenCoordinatorParameters

    private var viewModel: RoomScreenViewModelProtocol
    private var navigationStackCoordinator: NavigationStackCoordinator {
        parameters.navigationStackCoordinator
    }

    var callback: ((RoomScreenCoordinatorAction) -> Void)?
    
    init(parameters: RoomScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomScreenViewModel(timelineController: parameters.timelineController,
                                        mediaProvider: parameters.mediaProvider,
                                        roomName: parameters.roomProxy.displayName ?? parameters.roomProxy.name,
                                        roomAvatarUrl: parameters.roomProxy.avatarURL)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .displayRoomDetails:
                self.displayRoomDetails()
            case .displayMediaFile(let file, let title):
                self.displayFilePreview(for: file, with: title)
            case .displayEmojiPicker(let itemID):
                self.displayEmojiPickerScreen(for: itemID)
            case .displayReportContent(let itemID, let senderID):
                self.displayReportContent(for: itemID, from: senderID)
            case .displayCameraPicker:
                self.displayMediaPickerWithSource(.camera)
            case .displayMediaPicker:
                self.displayMediaPickerWithSource(.photoLibrary)
            case .displayDocumentPicker:
                self.displayMediaPickerWithSource(.documents)
            }
        }
    }
    
    func stop() {
        parameters.roomProxy.removeTimelineListener()
        viewModel.context.send(viewAction: .markRoomAsRead)
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func displayMediaPickerWithSource(_ source: MediaPickerScreenSource) {
        let mediaPickerCoordinator = MediaPickerScreenCoordinator(source: source) { [weak self] action in
            switch action {
            case .cancel:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            case .error:
                break
            case .selectMediaAtURL(let url):
                let mediaPickerPreviewScreenCoordinator = MediaPickerPreviewScreenCoordinator(parameters: .init(url: url, title: url.lastPathComponent)) { action in
                    switch action {
                    case .send:
                        Task {
                            let preprocessor = MediaUploadingPreprocessor()
                            switch await preprocessor.processMedia(at: url) {
                            case .success(let mediaInfo):
                                MXLog.info(mediaInfo)
                                
                                switch mediaInfo {
                                case let .image(imageURL, thumbnailURL, imageInfo):
                                    let _ = await self?.parameters.roomProxy.sendImage(url: imageURL, thumbnailURL: thumbnailURL, imageInfo: imageInfo)
                                default:
                                    break
                                }
                            case .failure(let error):
                                MXLog.error("Failed processing media to upload with error: \(error)")
                            }
                            
                            self?.navigationStackCoordinator.setSheetCoordinator(nil)
                        }
                    case .cancel:
                        self?.navigationStackCoordinator.setSheetCoordinator(nil)
                    }
                }
                
                self?.navigationStackCoordinator.setSheetCoordinator(mediaPickerPreviewScreenCoordinator)
            }
        }
        
        navigationStackCoordinator.setSheetCoordinator(mediaPickerCoordinator)
    }

    private func displayFilePreview(for file: MediaFileHandleProxy, with title: String?) {
        let params = FilePreviewCoordinatorScreenParameters(mediaFile: file, title: title)
        let coordinator = FilePreviewScreenCoordinator(parameters: params)
        coordinator.callback = { [weak self] _ in
            self?.navigationStackCoordinator.pop()
        }
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func displayEmojiPickerScreen(for itemId: String) {
        let emojiPickerNavigationStackCoordinator = NavigationStackCoordinator()
        
        let params = EmojiPickerScreenCoordinatorParameters(emojiProvider: parameters.emojiProvider,
                                                            itemId: itemId)
        let coordinator = EmojiPickerScreenCoordinator(parameters: params)
        coordinator.callback = { [weak self] action in
            switch action {
            case let .emojiSelected(emoji: emoji, itemId: itemId):
                MXLog.debug("Selected \(emoji) for \(itemId)")
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
                Task {
                    await self?.parameters.timelineController.sendReaction(emoji, to: itemId)
                }
            case .dismiss:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        
        emojiPickerNavigationStackCoordinator.setRootCoordinator(coordinator)
        emojiPickerNavigationStackCoordinator.presentationDetents = [.medium, .large]
        
        navigationStackCoordinator.setSheetCoordinator(emojiPickerNavigationStackCoordinator)
    }
    
    private func displayRoomDetails() {
        let params = RoomDetailsCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                      roomProxy: parameters.roomProxy,
                                                      mediaProvider: parameters.mediaProvider)
        let coordinator = RoomDetailsCoordinator(parameters: params)
        coordinator.callback = { [weak self] action in
            switch action {
            case .cancel:
                self?.navigationStackCoordinator.pop()
            case .leftRoom:
                self?.callback?(.leftRoom)
            }
        }

        navigationStackCoordinator.push(coordinator)
    }

    private func displayReportContent(for itemID: String, from senderID: String) {
        let navigationCoordinator = NavigationStackCoordinator()
        let userIndicatorController = UserIndicatorController(rootCoordinator: navigationCoordinator)
        let parameters = ReportContentCoordinatorParameters(itemID: itemID,
                                                            senderID: senderID,
                                                            roomProxy: parameters.roomProxy,
                                                            userIndicatorController: userIndicatorController)
        let coordinator = ReportContentCoordinator(parameters: parameters)
        coordinator.callback = { [weak self] completion in
            self?.navigationStackCoordinator.setSheetCoordinator(nil)
            switch completion {
            case .cancel: break
            case .finish:
                self?.showSuccess(label: L10n.commonReportSubmitted)
            }
        }
        navigationCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(userIndicatorController)
    }

    private func showSuccess(label: String) {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(title: label, iconName: "checkmark"))
    }
}
