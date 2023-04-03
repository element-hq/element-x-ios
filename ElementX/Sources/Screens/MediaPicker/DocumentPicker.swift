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

enum DocumentPickerAction {
    case selectFile(URL)
    case cancel
    case error(DocumentPickerError)
}

enum DocumentPickerError: Error {
    case unknown
}

struct DocumentPicker: UIViewControllerRepresentable {
    private let callback: (DocumentPickerAction) -> Void
    
    init(callback: @escaping (DocumentPickerAction) -> Void) {
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
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                documentPicker.callback(.error(.unknown))
                return
            }
            
            documentPicker.callback(.selectFile(url))
        }
    }
}
