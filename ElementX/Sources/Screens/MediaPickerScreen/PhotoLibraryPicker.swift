//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import PhotosUI
import SwiftUI

enum PhotoLibraryPickerAction {
    case selectFile(URL)
    case cancel
    case error(PhotoLibraryPickerError)
}

enum PhotoLibraryPickerError: Error {
    case failedLoadingFileRepresentation(Error?)
    case failedCopyingFile
}

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let callback: (PhotoLibraryPickerAction) -> Void
    
    init(userIndicatorController: UserIndicatorControllerProtocol, callback: @escaping (PhotoLibraryPickerAction) -> Void) {
        self.userIndicatorController = userIndicatorController
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
        
        private static let loadingIndicatorIdentifier = "\(PhotoLibraryPicker.self)-Loading"
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  let contentType = provider.preferredContentType else {
                photoLibraryPicker.callback(.cancel)
                return
            }
            
            picker.delegate = nil
            
            photoLibraryPicker.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading))
            defer {
                photoLibraryPicker.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
            }
            
            provider.loadFileRepresentation(forTypeIdentifier: contentType.identifier) { [weak self] url, error in
                guard let url else {
                    Task { @MainActor in
                        self?.photoLibraryPicker.callback(.error(.failedLoadingFileRepresentation(error)))
                    }
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
                    Task { @MainActor in
                        self?.photoLibraryPicker.callback(.error(.failedCopyingFile))
                    }
                }
            }
        }
    }
}
