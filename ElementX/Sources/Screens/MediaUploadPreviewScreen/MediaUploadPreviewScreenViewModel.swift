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

typealias MediaUploadPreviewScreenViewModelType = StateStoreViewModel<MediaUploadPreviewScreenViewState, MediaUploadPreviewScreenViewAction>

class MediaUploadPreviewScreenViewModel: MediaUploadPreviewScreenViewModelType, MediaUploadPreviewScreenViewModelProtocol {
    private weak var userIndicatorController: UserIndicatorControllerProtocol?
    private let roomProxy: RoomProxyProtocol
    private let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    private let url: URL
    
    var callback: ((MediaUploadPreviewScreenViewModelAction) -> Void)?

    init(userIndicatorController: UserIndicatorControllerProtocol?,
         roomProxy: RoomProxyProtocol,
         mediaUploadingPreprocessor: MediaUploadingPreprocessor,
         title: String?,
         url: URL) {
        self.userIndicatorController = userIndicatorController
        self.roomProxy = roomProxy
        self.mediaUploadingPreprocessor = mediaUploadingPreprocessor
        self.url = url
        
        super.init(initialViewState: MediaUploadPreviewScreenViewState(url: url, title: title))
    }
    
    override func process(viewAction: MediaUploadPreviewScreenViewAction) {
        switch viewAction {
        case .send:
            Task {
                startLoading()
                defer {
                    stopLoading()
                }
                
                switch await mediaUploadingPreprocessor.processMedia(at: url) {
                case .success(let mediaInfo):
                    switch await sendAttachment(mediaInfo: mediaInfo) {
                    case .success:
                        callback?(.dismiss)
                    case .failure(let error):
                        MXLog.error("Failed sending attachment with error: \(error)")
                        showError(label: L10n.screenMediaUploadPreviewErrorFailedSending)
                    }
                    
                case .failure(let error):
                    MXLog.error("Failed processing media to upload with error: \(error)")
                    showError(label: L10n.screenMediaUploadPreviewErrorFailedProcessing)
                }
            }
            
        case .cancel:
            callback?(.dismiss)
        }
    }
    
    // MARK: - Private
    
    private func sendAttachment(mediaInfo: MediaInfo) async -> Result<Void, RoomProxyError> {
        switch mediaInfo {
        case let .image(imageURL, thumbnailURL, imageInfo):
            return await roomProxy.sendImage(url: imageURL, thumbnailURL: thumbnailURL, imageInfo: imageInfo)
        case let .video(videoURL, thumbnailURL, videoInfo):
            return await roomProxy.sendVideo(url: videoURL, thumbnailURL: thumbnailURL, videoInfo: videoInfo)
        case let .audio(audioURL, audioInfo):
            return await roomProxy.sendAudio(url: audioURL, audioInfo: audioInfo)
        case let .file(fileURL, fileInfo):
            return await roomProxy.sendFile(url: fileURL, fileInfo: fileInfo)
        }
    }
    
    private static let loadingIndicatorIdentifier = "MediaUploadPreviewLoading"
    
    private func startLoading() {
        userIndicatorController?.submitIndicator(
            UserIndicator(id: Self.loadingIndicatorIdentifier,
                          type: .modal,
                          title: L10n.commonLoading,
                          persistent: true)
        )
    }
    
    private func stopLoading() {
        userIndicatorController?.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    private func showError(label: String) {
        userIndicatorController?.submitIndicator(UserIndicator(title: label))
    }
}
