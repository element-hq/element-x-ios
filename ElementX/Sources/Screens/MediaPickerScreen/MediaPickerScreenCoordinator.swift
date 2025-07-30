//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct MediaPickerScreenMode: Hashable {
    let source: MediaPickerScreenSource
    let selectionType: MediaPickerScreenSelectionType
}

enum MediaPickerScreenSource {
    case camera
    case photoLibrary
    case documents
}

enum MediaPickerScreenSelectionType {
    case single
    case multiple
}

enum MediaPickerScreenCoordinatorAction {
    case selectedMediaAtURLs([URL])
    case cancel
}

class MediaPickerScreenCoordinator: CoordinatorProtocol {
    private let orientationManager: OrientationManagerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let mode: MediaPickerScreenMode
    private let callback: (MediaPickerScreenCoordinatorAction) -> Void
    
    init(mode: MediaPickerScreenMode,
         appSettings: AppSettings,
         userIndicatorController: UserIndicatorControllerProtocol,
         orientationManager: OrientationManagerProtocol,
         callback: @escaping (MediaPickerScreenCoordinatorAction) -> Void) {
        self.userIndicatorController = userIndicatorController
        self.orientationManager = orientationManager
        self.callback = callback
        
        // The users of the media picker chose their ideal selection type leaving
        // the feature flag to only be checked and enforced on this level.
        self.mode = appSettings.multipleAttachmentUploadEnabled ? mode : .init(source: mode.source, selectionType: .single)
    }
    
    func toPresentable() -> AnyView {
        AnyView(mediaPicker)
    }
    
    func start() {
        if mode.source == .camera {
            orientationManager.setOrientation(.portrait)
            orientationManager.lockOrientation(.portrait)
        }
    }
    
    func stop() {
        if mode.source == .camera {
            orientationManager.lockOrientation(.all)
        }
    }
    
    @ViewBuilder
    private var mediaPicker: some View {
        switch mode.source {
        case .camera:
            cameraPicker
        case .photoLibrary:
            PhotoLibraryPicker(selectionType: mode.selectionType, userIndicatorController: userIndicatorController) { [weak self] action in
                switch action {
                case .cancel:
                    self?.callback(.cancel)
                case .error(let error):
                    MXLog.error("Failed selecting media from the photo library with error: \(error)")
                    self?.showError()
                case .selectedMediaAtURLs(let urls):
                    self?.callback(.selectedMediaAtURLs(urls))
                }
            }
        case .documents:
            // The document picker automatically dismisses everything on selection
            // Strongly retain self in the callback to forward actions correctly
            DocumentPicker(selectionType: mode.selectionType, userIndicatorController: userIndicatorController) { action in
                switch action {
                case .cancel:
                    self.callback(.cancel)
                case .error(let error):
                    MXLog.error("Failed selecting media from the document picker with error: \(error)")
                    self.showError()
                case .selectedMediaAtURLs(let urls):
                    self.callback(.selectedMediaAtURLs(urls))
                }
            }
        }
    }
    
    private var cameraPicker: some View {
        CameraPicker(userIndicatorController: userIndicatorController) { [weak self] action in
            switch action {
            case .cancel:
                self?.callback(.cancel)
            case .error(let error):
                MXLog.error("Failed selecting media from the camera picker with error: \(error)")
                self?.showError()
            case .selectFile(let url):
                self?.callback(.selectedMediaAtURLs([url]))
            }
        }
        .background(.black, ignoresSafeAreaEdges: .bottom)
    }
    
    private func showError() {
        userIndicatorController.submitIndicator(UserIndicator(title: L10n.screenMediaPickerErrorFailedSelection))
    }
}
