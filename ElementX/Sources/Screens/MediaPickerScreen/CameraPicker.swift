//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum CameraPickerAction {
    case selectFile(URL)
    case cancel
    case error(CameraPickerError)
}

enum CameraPickerError: Error {
    case invalidJpegData
    case invalidOriginalImage
    case failedWritingToTemporaryDirectory
}

struct CameraPicker: UIViewControllerRepresentable {
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let callback: (CameraPickerAction) -> Void
    
    init(userIndicatorController: UserIndicatorControllerProtocol, callback: @escaping (CameraPickerAction) -> Void) {
        self.userIndicatorController = userIndicatorController
        self.callback = callback
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        imagePicker.delegate = context.coordinator
        
        if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
            imagePicker.mediaTypes = mediaTypes
        }
        
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private var cameraPicker: CameraPicker
        
        init(_ cameraPicker: CameraPicker) {
            self.cameraPicker = cameraPicker
        }
        
        private static let loadingIndicatorIdentifier = "\(CameraPicker.self)-Loading"
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.delegate = nil
            
            cameraPicker.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading))
            defer {
                cameraPicker.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
            }
            
            if let videoURL = info[.mediaURL] as? URL {
                cameraPicker.callback(.selectFile(videoURL))
            } else if let image = info[.originalImage] as? UIImage {
                guard let jpegData = image.jpegData(compressionQuality: 1.0) else {
                    cameraPicker.callback(.error(.invalidJpegData))
                    return
                }
                
                let fileName = "\(Date.now.formatted(.iso8601.dateSeparator(.omitted).timeSeparator(.omitted))).jpg"
                
                do {
                    let url = try FileManager.default.writeDataToTemporaryDirectory(data: jpegData, fileName: fileName)
                    cameraPicker.callback(.selectFile(url))
                } catch {
                    cameraPicker.callback(.error(.failedWritingToTemporaryDirectory))
                }
            } else {
                cameraPicker.callback(.error(.invalidOriginalImage))
            }
        }
    }
}
