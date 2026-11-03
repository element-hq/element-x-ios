//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ImageIO
import MatrixRustSDK
import SwiftUI
import UniformTypeIdentifiers

typealias MediaUploadPreviewScreenViewModelType = StateStoreViewModelV2<MediaUploadPreviewScreenViewState, MediaUploadPreviewScreenViewAction>

class MediaUploadPreviewScreenViewModel: MediaUploadPreviewScreenViewModelType, MediaUploadPreviewScreenViewModelProtocol {
    private let timelineController: TimelineControllerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    private var mediaURLs: [URL]
    
    private var processingTask: Task<Result<[MediaInfo], MediaUploadingPreprocessorError>, Never>
    private var lateDrawingTimeoutTask: Task<Void, Never>?
    private var requestHandle: SendAttachmentJoinHandleProtocol?
    private let clientProxy: ClientProxyProtocol
    private let galleryEnabled: Bool
    
    private var actionsSubject: PassthroughSubject<MediaUploadPreviewScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<MediaUploadPreviewScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(mediaURLs: [URL],
         caption: NSAttributedString?,
         title: String?,
         shouldShowCaptionWarning: Bool,
         galleryEnabled: Bool,
         imageDrawingEnabled: Bool,
         mediaUploadingPreprocessor: MediaUploadingPreprocessor,
         timelineController: TimelineControllerProtocol,
         clientProxy: ClientProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.mediaURLs = mediaURLs
        self.mediaUploadingPreprocessor = mediaUploadingPreprocessor
        self.timelineController = timelineController
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        self.galleryEnabled = galleryEnabled
        
        // Start processing the media whilst the user is reviewing it/adding a caption.
        processingTask = Self.processMedia(at: mediaURLs, preprocessor: mediaUploadingPreprocessor, clientProxy: clientProxy)
        
        let drawableMediaIndices = imageDrawingEnabled ? Set(mediaURLs.indices.filter { Self.canDraw(onMediaAt: mediaURLs[$0]) }) : []
        
        super.init(initialViewState: MediaUploadPreviewScreenViewState(mediaURLs: mediaURLs,
                                                                       title: title,
                                                                       shouldShowCaptionWarning: shouldShowCaptionWarning,
                                                                       drawableMediaIndices: drawableMediaIndices,
                                                                       bindings: .init(caption: caption ?? NSAttributedString())))
    }
    
    override func process(viewAction: MediaUploadPreviewScreenViewAction) {
        // Get the current caption before all the processing starts.
        let caption = state.bindings.caption.nonBlankString
        
        switch viewAction {
        case .send:
            guard !state.shouldDisableInteraction else { return }
            
            startLoading()
            
            Task {
                defer { stopLoading() }
                
                // A drawing saved meanwhile restarts the processing, so wait for the latest one.
                var processingTask = processingTask
                var result = await processingTask.value
                while processingTask != self.processingTask {
                    processingTask = self.processingTask
                    result = await processingTask.value
                }
                guard !processingTask.isCancelled else { return }
                switch result {
                case .success(let mediaInfos):
                    if galleryEnabled, mediaInfos.count > 1 {
                        switch await sendGallery(mediaInfos: mediaInfos, caption: caption) {
                        case .success:
                            break
                        case .failure(let error):
                            MXLog.error("Failed sending gallery with error: \(error)")
                            showError(label: L10n.screenMediaUploadPreviewErrorFailedSending)
                        }
                    } else {
                        var perItemCaption = caption
                        for mediaInfo in mediaInfos {
                            switch await sendAttachment(mediaInfo: mediaInfo, caption: perItemCaption) {
                            case .success:
                                perItemCaption = nil // Set the caption only on the first uploaded file.
                            case .failure(let error):
                                MXLog.error("Failed sending media with error: \(error)")
                                showError(label: L10n.screenMediaUploadPreviewErrorFailedSending)
                            }
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
        case .editedMedia(let image, let index):
            guard mediaURLs.indices.contains(index),
                  let data = image.jpegData(compressionQuality: 1.0) else {
                return
            }
            
            do {
                try data.write(to: mediaURLs[index], options: .atomic)
                reloadEditedMedia()
            } catch {
                MXLog.error("Failed writing cropped image with error: \(error)")
            }
        case .drewOnMedia(let index):
            guard mediaURLs.indices.contains(index) else { return }
            reloadEditedMedia()
            stopWaitingForLateDrawing()
        case .savingDrawing:
            waitForLateDrawing()
        }
    }
    
    private func sendGallery(mediaInfos: [MediaInfo], caption: String?) async -> Result<Void, TimelineControllerError> {
        let itemInfos: [GalleryItemInfo] = mediaInfos.map { mediaInfo in
            switch mediaInfo {
            case let .image(imageURL, thumbnailURL, imageInfo):
                .image(imageInfo: imageInfo,
                       source: .file(filename: imageURL.path(percentEncoded: false)),
                       caption: nil,
                       formattedCaption: nil,
                       thumbnailSource: .file(filename: thumbnailURL.path(percentEncoded: false)))
            case let .video(videoURL, thumbnailURL, videoInfo):
                .video(videoInfo: videoInfo,
                       source: .file(filename: videoURL.path(percentEncoded: false)),
                       caption: nil,
                       formattedCaption: nil,
                       thumbnailSource: .file(filename: thumbnailURL.path(percentEncoded: false)))
            case let .audio(audioURL, audioInfo):
                .audio(audioInfo: audioInfo,
                       source: .file(filename: audioURL.path(percentEncoded: false)),
                       caption: nil,
                       formattedCaption: nil)
            case let .file(fileURL, fileInfo):
                .file(fileInfo: fileInfo,
                      source: .file(filename: fileURL.path(percentEncoded: false)),
                      caption: nil,
                      formattedCaption: nil)
            }
        }
        
        return await timelineController.sendGallery(itemInfos: itemInfos,
                                                    caption: caption,
                                                    inReplyToEventID: nil)
    }
    
    func stopProcessing() {
        lateDrawingTimeoutTask?.cancel()
        processingTask.cancel()
    }
    
    // MARK: - Private
    
    /// Reloads the preview and prepares the media again after a picture was changed on disk.
    private func reloadEditedMedia() {
        state.mediaEditVersion += 1
        
        processingTask.cancel()
        processingTask = Self.processMedia(at: mediaURLs, preprocessor: mediaUploadingPreprocessor, clientProxy: clientProxy)
    }
    
    /// Saving while still in Markup writes the drawing a moment after the editor is gone, so block the screen until it lands.
    private func waitForLateDrawing() {
        state.shouldDisableInteraction = true
        lateDrawingTimeoutTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            stopWaitingForLateDrawing()
        }
    }
    
    private func stopWaitingForLateDrawing() {
        guard let lateDrawingTimeoutTask else { return }
        lateDrawingTimeoutTask.cancel()
        self.lateDrawingTimeoutTask = nil
        state.shouldDisableInteraction = false
    }
    
    /// Only still pictures: Markup would flatten an animated image to a single frame.
    private static func canDraw(onMediaAt url: URL) -> Bool {
        guard UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) == true,
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return false
        }
        return CGImageSourceGetCount(source) == 1
    }
    
    private static func processMedia(at urls: [URL],
                                     preprocessor: MediaUploadingPreprocessor,
                                     clientProxy: ClientProxyProtocol) -> Task<Result<[MediaInfo], MediaUploadingPreprocessorError>, Never> {
        Task {
            guard case let .success(maxUploadSize) = await clientProxy.maxMediaUploadSize else { return .failure(.maxUploadSizeUnknown) }
            return await preprocessor.processMedia(at: urls, maxUploadSize: maxUploadSize)
        }
    }
    
    private func sendAttachment(mediaInfo: MediaInfo, caption: String?) async -> Result<Void, TimelineControllerError> {
        let requestHandle: (@MainActor @Sendable (SendAttachmentJoinHandleProtocol) -> Void) = { [weak self] handle in
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
