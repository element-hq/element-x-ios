//
// Copyright 2023 New Vector Ltd
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
    private weak var userIndicatorController: UserIndicatorControllerProtocol?
    private let callback: (CameraPickerAction) -> Void
    
    init(userIndicatorController: UserIndicatorControllerProtocol?, callback: @escaping (CameraPickerAction) -> Void) {
        self.userIndicatorController = userIndicatorController
        self.callback = callback
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
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
        
        private static let loadingIndicatorIdentifier = "CameraPickerLoadingIndicator"
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.delegate = nil
            
            cameraPicker.userIndicatorController?.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading))
            defer {
                cameraPicker.userIndicatorController?.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
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
