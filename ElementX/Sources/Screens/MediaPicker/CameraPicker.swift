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
import UIKit

enum CameraPickerAction {
    case selectFile(URL)
    case cancel
    case error(Error?)
}

struct CameraPicker: UIViewControllerRepresentable {
    private let callback: (CameraPickerAction) -> Void
    
    init(callback: @escaping (CameraPickerAction) -> Void) {
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
        private var parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.callback(.selectFile(videoURL))
            } else if let image = info[.originalImage] as? UIImage {
                guard let jpegData = image.jpegData(compressionQuality: 1.0) else {
                    parent.callback(.error(nil))
                    return
                }
                
                let fileName = "\(UUID().uuidString).jpg"
                
                do {
                    let url = try FileManager.default.writeDataToTemporaryLocation(data: jpegData, fileName: fileName)
                    parent.callback(.selectFile(url))
                } catch {
                    parent.callback(.error(error))
                }
            } else {
                parent.callback(.error(nil))
            }
        }
    }
}
