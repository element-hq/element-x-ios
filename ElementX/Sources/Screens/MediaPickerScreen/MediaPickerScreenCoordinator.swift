//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

enum MediaPickerScreenSource {
    case camera
    case photoLibrary
    case documents
}

enum MediaPickerScreenCoordinatorAction {
    case selectMediaAtURL(URL)
    case cancel
}

class MediaPickerScreenCoordinator: CoordinatorProtocol {
    private let orientationManager: OrientationManagerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let source: MediaPickerScreenSource
    private let callback: (MediaPickerScreenCoordinatorAction) -> Void
    
    init(userIndicatorController: UserIndicatorControllerProtocol,
         source: MediaPickerScreenSource,
         orientationManager: OrientationManagerProtocol,
         callback: @escaping (MediaPickerScreenCoordinatorAction) -> Void) {
        self.userIndicatorController = userIndicatorController
        self.source = source
        self.orientationManager = orientationManager
        self.callback = callback
    }
    
    func toPresentable() -> AnyView {
        AnyView(mediaPicker)
    }
    
    func start() {
        guard source == .camera else {
            return
        }
        
        orientationManager.setOrientation(.portrait)
        orientationManager.lockOrientation(.portrait)
    }
    
    func stop() {
        guard source == .camera else {
            return
        }
        
        orientationManager.lockOrientation(.all)
    }
    
    @ViewBuilder
    private var mediaPicker: some View {
        switch source {
        case .camera:
            cameraPicker
        case .photoLibrary:
            PhotoLibraryPicker(userIndicatorController: userIndicatorController) { [weak self] action in
                switch action {
                case .cancel:
                    self?.callback(.cancel)
                case .error(let error):
                    MXLog.error("Failed selecting media from the photo library with error: \(error)")
                    self?.showError()
                case .selectFile(let url):
                    self?.callback(.selectMediaAtURL(url))
                }
            }
        case .documents:
            // The document picker automatically dismisses everything on selection
            // Strongly retain self in the callback to forward actions correctly
            DocumentPicker(userIndicatorController: userIndicatorController) { action in
                switch action {
                case .cancel:
                    self.callback(.cancel)
                case .error(let error):
                    MXLog.error("Failed selecting media from the document picker with error: \(error)")
                    self.showError()
                case .selectFile(let url):
                    self.callback(.selectMediaAtURL(url))
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
                self?.callback(.selectMediaAtURL(url))
            }
        }
        .background(.black, ignoresSafeAreaEdges: .bottom)
    }
    
    private func showError() {
        userIndicatorController.submitIndicator(UserIndicator(title: L10n.screenMediaPickerErrorFailedSelection))
    }
}
