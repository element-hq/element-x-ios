//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

enum DocumentPickerAction {
    case selectFile(URL)
    case cancel
    case error(Error)
}

enum DocumentPickerError: Error {
    case unknown
}

struct DocumentPicker: UIViewControllerRepresentable {
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let callback: (DocumentPickerAction) -> Void
    
    init(userIndicatorController: UserIndicatorControllerProtocol, callback: @escaping (DocumentPickerAction) -> Void) {
        self.userIndicatorController = userIndicatorController
        self.callback = callback
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = context.coordinator
        
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) { }
    
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
            guard let url = urls.first else {
                documentPicker.callback(.error(DocumentPickerError.unknown))
                return
            }
            
            picker.delegate = nil
            
            documentPicker.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading))
            defer {
                documentPicker.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
            }
            
            do {
                let _ = url.startAccessingSecurityScopedResource()
                let newURL = try FileManager.default.copyFileToTemporaryDirectory(file: url)
                url.stopAccessingSecurityScopedResource()
                documentPicker.callback(.selectFile(newURL))
            } catch {
                documentPicker.callback(.error(error))
            }
        }
    }
}
