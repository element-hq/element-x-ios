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
import MatrixRustSDK
import SwiftUI

typealias MediaUploadPreviewScreenViewModelType = StateStoreViewModel<MediaUploadPreviewScreenViewState, MediaUploadPreviewScreenViewAction>

class MediaUploadPreviewScreenViewModel: MediaUploadPreviewScreenViewModelType, MediaUploadPreviewScreenViewModelProtocol {
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let roomProxy: JoinedRoomProxyProtocol
    private let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    private let url: URL
    private var requestHandle: SendAttachmentJoinHandleProtocol? {
        didSet {
            state.shouldDisableInteraction = requestHandle != nil
        }
    }
    
    private var actionsSubject: PassthroughSubject<MediaUploadPreviewScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<MediaUploadPreviewScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userIndicatorController: UserIndicatorControllerProtocol,
         roomProxy: JoinedRoomProxyProtocol,
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
                let progressSubject = CurrentValueSubject<Double, Never>(0.0)
                
                startLoading(progressPublisher: progressSubject.asCurrentValuePublisher())
                
                switch await mediaUploadingPreprocessor.processMedia(at: url) {
                case .success(let mediaInfo):
                    switch await sendAttachment(mediaInfo: mediaInfo, progressSubject: progressSubject) {
                    case .success:
                        actionsSubject.send(.dismiss)
                    case .failure(let error):
                        MXLog.error("Failed sending attachment with error: \(error)")
                        showError(label: L10n.screenMediaUploadPreviewErrorFailedSending)
                    }
                    
                    stopLoading()
                case .failure(let error):
                    MXLog.error("Failed processing media to upload with error: \(error)")
                    showError(label: L10n.screenMediaUploadPreviewErrorFailedProcessing)
                    stopLoading()
                }
            }
            
        case .cancel:
            requestHandle?.cancel()
            actionsSubject.send(.dismiss)
        }
    }
    
    // MARK: - Private
    
    private func sendAttachment(mediaInfo: MediaInfo, progressSubject: CurrentValueSubject<Double, Never>) async -> Result<Void, TimelineProxyError> {
        let requestHandle: ((SendAttachmentJoinHandleProtocol) -> Void) = { [weak self] handle in
            self?.requestHandle?.cancel()
            self?.requestHandle = handle
        }
        
        switch mediaInfo {
        case let .image(imageURL, thumbnailURL, imageInfo):
            return await roomProxy.timeline.sendImage(url: imageURL, thumbnailURL: thumbnailURL, imageInfo: imageInfo, progressSubject: progressSubject, requestHandle: requestHandle)
        case let .video(videoURL, thumbnailURL, videoInfo):
            return await roomProxy.timeline.sendVideo(url: videoURL, thumbnailURL: thumbnailURL, videoInfo: videoInfo, progressSubject: progressSubject, requestHandle: requestHandle)
        case let .audio(audioURL, audioInfo):
            return await roomProxy.timeline.sendAudio(url: audioURL, audioInfo: audioInfo, progressSubject: progressSubject, requestHandle: requestHandle)
        case let .file(fileURL, fileInfo):
            return await roomProxy.timeline.sendFile(url: fileURL, fileInfo: fileInfo, progressSubject: progressSubject, requestHandle: requestHandle)
        }
    }
    
    private static let loadingIndicatorIdentifier = "\(MediaUploadPreviewScreenViewModel.self)-Loading"
    
    private func startLoading(progressPublisher: CurrentValuePublisher<Double, Never>) {
        userIndicatorController.submitIndicator(
            UserIndicator(id: Self.loadingIndicatorIdentifier,
                          type: .modal(progress: .published(progressPublisher), interactiveDismissDisabled: false, allowsInteraction: true),
                          title: L10n.commonSending,
                          persistent: true)
        )
    }
    
    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
        requestHandle = nil
    }
    
    private func showError(label: String) {
        userIndicatorController.submitIndicator(UserIndicator(title: label))
    }
}
