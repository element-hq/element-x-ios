//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import PhotosUI
import SwiftUI

enum PhotoLibraryPickerAction {
    case selectedMediaAtURLs([URL])
    case cancel
    case error(PhotoLibraryPickerError)
}

enum PhotoLibraryPickerError: Error {
    case failedLoadingFileRepresentation(Error?)
    case failedCopyingFile
}

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    private let selectionType: MediaPickerScreenSelectionType
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let callback: (PhotoLibraryPickerAction) -> Void
    
    init(selectionType: MediaPickerScreenSelectionType,
         userIndicatorController: UserIndicatorControllerProtocol,
         callback: @escaping (PhotoLibraryPickerAction) -> Void) {
        self.selectionType = selectionType
        self.userIndicatorController = userIndicatorController
        self.callback = callback
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selection = .ordered
        configuration.selectionLimit = switch selectionType {
        case .single:
            1
        case .multiple:
            10
        }
        
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = context.coordinator
        
        return pickerViewController
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Override the app wide tint color (currently set to `.compound.texActionPrimary
        // as it's not legible enough in dark mode
        uiViewController.view.tintColor = .compound.textActionAccent
    }
    
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
            guard !results.isEmpty else {
                photoLibraryPicker.callback(.cancel)
                return
            }
            
            picker.delegate = nil
            
            photoLibraryPicker.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                                                     type: .modal,
                                                                                     title: L10n.commonLoading))
            defer {
                photoLibraryPicker.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
            }
            
            Task {
                let selectedURLs = await withTaskGroup { taskGroup in
                    for (index, result) in results.enumerated() {
                        taskGroup.addTask {
                            let url = await self.processResult(result)
                            return (index, url)
                        }
                    }
                    
                    var selectedURLs = [URL?](repeating: nil, count: results.count)
                    for await (index, url) in taskGroup {
                        if let url {
                            selectedURLs[index] = url
                        }
                    }
                    
                    return selectedURLs.compactMap { $0 }
                }
                
                photoLibraryPicker.callback(.selectedMediaAtURLs(selectedURLs))
            }
        }
        
        // MARK: - Private
        
        func processResult(_ result: PHPickerResult) async -> URL? {
            let provider = result.itemProvider
            
            guard let contentType = provider.preferredContentType else {
                return nil
            }
            
            return await withCheckedContinuation { continuation in
                provider.loadFileRepresentation(forTypeIdentifier: contentType.type.identifier) { [weak self] url, error in
                    guard let url else {
                        Task { @MainActor in
                            self?.photoLibraryPicker.callback(.error(.failedLoadingFileRepresentation(error)))
                        }
                        
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    do {
                        _ = url.startAccessingSecurityScopedResource()
                        let newURL = try FileManager.default.copyFileToTemporaryDirectory(file: url)
                        url.stopAccessingSecurityScopedResource()
                        
                        Task { @MainActor in
                            continuation.resume(returning: newURL)
                        }
                    } catch {
                        Task { @MainActor in
                            self?.photoLibraryPicker.callback(.error(.failedCopyingFile))
                            continuation.resume(returning: nil)
                        }
                    }
                }
            }
        }
    }
}
