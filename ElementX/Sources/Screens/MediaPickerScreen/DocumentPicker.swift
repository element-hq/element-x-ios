//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum DocumentPickerAction {
    case selectedMediaAtURLs([URL])
    case cancel
    case error(Error)
}

struct DocumentPicker: UIViewControllerRepresentable {
    private let selectionType: MediaPickerScreenSelectionType
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let callback: (DocumentPickerAction) -> Void
    
    init(selectionType: MediaPickerScreenSelectionType,
         userIndicatorController: UserIndicatorControllerProtocol,
         callback: @escaping (DocumentPickerAction) -> Void) {
        self.selectionType = selectionType
        self.userIndicatorController = userIndicatorController
        self.callback = callback
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        documentPicker.delegate = context.coordinator
        
        documentPicker.allowsMultipleSelection = switch selectionType {
        case .single:
            false
        case .multiple:
            true
        }
        
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // Override the app wide tint color (currently set to `.compound.texActionPrimary
        // as it's not legible enough in dark mode
        uiViewController.view.tintColor = .compound.textActionAccent
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private var documentPicker: DocumentPicker
        
        init(_ documentPicker: DocumentPicker) {
            self.documentPicker = documentPicker
        }
        
        // MARK: UIDocumentPickerDelegate
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            documentPicker.callback(.cancel)
        }
        
        private static let loadingIndicatorIdentifier = "\(DocumentPicker.self)-Loading"
        
        func documentPicker(_ picker: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            picker.delegate = nil
            
            documentPicker.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading))
            defer {
                documentPicker.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
            }
            
            var selectedURLs = [URL]()
            for url in urls.prefix(10) {
                do {
                    _ = url.startAccessingSecurityScopedResource()
                    let newURL = try FileManager.default.copyFileToTemporaryDirectory(file: url)
                    url.stopAccessingSecurityScopedResource()
                    selectedURLs.append(newURL)
                } catch {
                    documentPicker.callback(.error(error))
                }
            }
            
            documentPicker.callback(.selectedMediaAtURLs(selectedURLs))
        }
    }
}
