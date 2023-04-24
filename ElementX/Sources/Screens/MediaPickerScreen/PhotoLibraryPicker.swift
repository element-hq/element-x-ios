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

import PhotosUI
import SwiftUI

enum PhotoLibraryPickerAction {
    case selectFile(URL)
    case cancel
    case error(Error?)
}

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    private let callback: (PhotoLibraryPickerAction) -> Void
    
    init(callback: @escaping (PhotoLibraryPickerAction) -> Void) {
        self.callback = callback
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = context.coordinator
        
        return pickerViewController
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private var photoLibraryPicker: PhotoLibraryPicker
        
        init(_ photoLibraryPicker: PhotoLibraryPicker) {
            self.photoLibraryPicker = photoLibraryPicker
        }
        
        // MARK: PHPickerViewControllerDelegate
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                photoLibraryPicker.callback(.cancel)
                return
            }
            
            provider.loadFileRepresentation(forTypeIdentifier: "public.item") { [weak self] url, error in
                guard let url else {
                    self?.photoLibraryPicker.callback(.error(error))
                    return
                }
                
                do {
                    let _ = url.startAccessingSecurityScopedResource()
                    let newURL = try FileManager.default.copyFileToTemporaryDirectory(file: url)
                    url.stopAccessingSecurityScopedResource()
                    
                    Task { @MainActor in
                        self?.photoLibraryPicker.callback(.selectFile(newURL))
                    }
                } catch {
                    self?.photoLibraryPicker.callback(.error(error))
                }
            }
        }
    }
}
