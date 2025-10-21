//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias MediaUploadPreviewScreenViewModelType = StateStoreViewModelV2<MediaUploadPreviewScreenViewState, MediaUploadPreviewScreenViewAction>

class MediaUploadPreviewScreenViewModel: MediaUploadPreviewScreenViewModelType, MediaUploadPreviewScreenViewModelProtocol {
    private let timelineController: TimelineControllerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    private var mediaURLs: [URL]
    
    private var processingTask: Task<Result<[MediaInfo], MediaUploadingPreprocessorError>, Never>
    private var requestHandle: SendAttachmentJoinHandleProtocol?
    private let clientProxy: ClientProxyProtocol
    
    private var actionsSubject: PassthroughSubject<MediaUploadPreviewScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<MediaUploadPreviewScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(mediaURLs: [URL],
         title: String?,
         isRoomEncrypted: Bool,
         shouldShowCaptionWarning: Bool,
         mediaUploadingPreprocessor: MediaUploadingPreprocessor,
         timelineController: TimelineControllerProtocol,
         clientProxy: ClientProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.mediaURLs = mediaURLs
        self.mediaUploadingPreprocessor = mediaUploadingPreprocessor
        self.timelineController = timelineController
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        // Start processing the media whilst the user is reviewing it/adding a caption.
        processingTask = Self.processMedia(at: mediaURLs, preprocessor: mediaUploadingPreprocessor, clientProxy: clientProxy)
        
        super.init(initialViewState: MediaUploadPreviewScreenViewState(mediaURLs: mediaURLs,
                                                                       title: title,
                                                                       shouldShowCaptionWarning: shouldShowCaptionWarning,
                                                                       isRoomEncrypted: isRoomEncrypted))
    }
    
    override func process(viewAction: MediaUploadPreviewScreenViewAction) {
        // Get the current caption before all the processing starts.
        var caption = state.bindings.caption.nonBlankString
        
        switch viewAction {
        case .send:
            startLoading()
            
            Task {
                defer { stopLoading() }
                
                switch await processingTask.value {
                case .success(let mediaInfos):
                    for mediaInfo in mediaInfos {
                        switch await sendAttachment(mediaInfo: mediaInfo, caption: caption) {
                        case .success:
                            caption = nil // Set the caption only on the first uploaded file.
                        case .failure(let error):
                            MXLog.error("Failed sending media with error: \(error)")
                            showError(label: L10n.screenMediaUploadPreviewErrorFailedSending)
                        }
                    }
                    
                    actionsSubject.send(.dismiss)
                case .failure(.maxUploadSizeUnknown):
                    showAlert(.maxUploadSizeUnknown)
                case .failure(.maxUploadSizeExceeded(let limit)):
                    showAlert(.maxUploadSizeExceeded(limit: limit))
                case .failure(let error):
                    MXLog.error("Failed processing media to upload with error: \(error)")
                    showError(label: L10n.screenMediaUploadPreviewErrorFailedProcessing)
                }
            }
        case .cancel:
            requestHandle?.cancel()
            actionsSubject.send(.dismiss)
        }
    }
    
    func stopProcessing() {
        processingTask.cancel()
    }
    
    // MARK: - Private
    
    private static func processMedia(at urls: [URL],
                                     preprocessor: MediaUploadingPreprocessor,
                                     clientProxy: ClientProxyProtocol) -> Task<Result<[MediaInfo], MediaUploadingPreprocessorError>, Never> {
        Task {
            guard case let .success(maxUploadSize) = await clientProxy.maxMediaUploadSize else { return .failure(.maxUploadSizeUnknown) }
            return await preprocessor.processMedia(at: urls, maxUploadSize: maxUploadSize)
        }
    }
    
    private func sendAttachment(mediaInfo: MediaInfo, caption: String?) async -> Result<Void, TimelineControllerError> {
        let requestHandle: ((SendAttachmentJoinHandleProtocol) -> Void) = { [weak self] handle in
            self?.requestHandle = handle
        }
        
        switch mediaInfo {
        case let .image(imageURL, thumbnailURL, imageInfo):
            return await timelineController.sendImage(url: imageURL,
                                                      thumbnailURL: thumbnailURL,
                                                      imageInfo: imageInfo,
                                                      caption: caption,
                                                      requestHandle: requestHandle)
        case let .video(videoURL, thumbnailURL, videoInfo):
            return await timelineController.sendVideo(url: videoURL,
                                                      thumbnailURL: thumbnailURL,
                                                      videoInfo: videoInfo,
                                                      caption: caption,
                                                      requestHandle: requestHandle)
        case let .audio(audioURL, audioInfo):
            return await timelineController.sendAudio(url: audioURL,
                                                      audioInfo: audioInfo,
                                                      caption: caption,
                                                      requestHandle: requestHandle)
        case let .file(fileURL, fileInfo):
            return await timelineController.sendFile(url: fileURL,
                                                     fileInfo: fileInfo,
                                                     caption: caption,
                                                     requestHandle: requestHandle)
        }
    }
    
    private static let loadingIndicatorIdentifier = "\(MediaUploadPreviewScreenViewModel.self)-Loading"
    
    private func startLoading() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: false, allowsInteraction: true),
                                                              title: L10n.commonPreparing,
                                                              persistent: true),
                                                delay: .milliseconds(100))
        
        state.shouldDisableInteraction = true
    }
    
    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
        state.shouldDisableInteraction = false
        requestHandle = nil
    }
    
    private func showError(label: String) {
        userIndicatorController.submitIndicator(UserIndicator(title: label))
    }
    
    private func showAlert(_ alertType: MediaUploadPreviewAlertType) {
        switch alertType {
        case .maxUploadSizeUnknown:
            state.bindings.alertInfo = .init(id: alertType,
                                             title: L10n.commonSomethingWentWrong,
                                             message: L10n.screenMediaUploadPreviewErrorCouldNotBeUploaded,
                                             primaryButton: .init(title: L10n.actionTryAgain) { [weak self] in
                                                 guard let self else { return }
                                                 processingTask = Self.processMedia(at: mediaURLs, preprocessor: mediaUploadingPreprocessor, clientProxy: clientProxy)
                                                 process(viewAction: .send)
                                             },
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel) { })
        case .maxUploadSizeExceeded(let limit):
            state.bindings.alertInfo = .init(id: alertType,
                                             title: L10n.screenMediaUploadPreviewErrorTooLargeTitle,
                                             message: L10n.screenMediaUploadPreviewErrorTooLargeMessage(limit.formatted(.byteCount(style: .file))),
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel) { })
        }
    }
}

extension NSAttributedString {
    var nonBlankString: String? {
        guard !string.isBlank else { return nil }
        return string
    }
}
