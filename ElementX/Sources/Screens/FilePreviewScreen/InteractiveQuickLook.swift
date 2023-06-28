//
// Copyright 2022 New Vector Ltd
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

import QuickLook
import SwiftUI

extension View {
    /// Preview a media file using a QuickLook Preview Controller. The preview is interactive with
    /// the dismiss gesture working as expected if it was presented from UIKit.
    func interactiveQuickLook(item: Binding<MediaPreviewItem?>) -> some View {
        modifier(InteractiveQuickLookModifier(item: item))
    }
}

private struct InteractiveQuickLookModifier: ViewModifier {
    @Binding var item: MediaPreviewItem?
    
    func body(content: Content) -> some View {
        content.background {
            if let item {
                MediaPreviewViewController(previewItem: item) { self.item = nil }
            }
        }
    }
}

private struct MediaPreviewViewController: UIViewControllerRepresentable {
    let previewItem: MediaPreviewItem
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> PreviewHostingController {
        PreviewHostingController(previewItem: previewItem, onDismiss: onDismiss)
    }

    func updateUIViewController(_ uiViewController: PreviewHostingController, context: Context) { }
    
    /// A view controller that hosts the QuickLook preview.
    ///
    /// This wrapper somehow allows the preview controller to do presentation/dismissal
    /// animations and interactions which don't work if you represent it directly to SwiftUI 🤷‍♂️
    class PreviewHostingController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let previewItem: MediaPreviewItem
        let onDismiss: () -> Void
        
        var previewController: QLPreviewController?

        init(previewItem: MediaPreviewItem, onDismiss: @escaping () -> Void) {
            self.previewItem = previewItem
            self.onDismiss = onDismiss
            
            super.init(nibName: nil, bundle: nil)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            view.backgroundColor = .clear
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            guard self.previewController == nil else { return }
            
            let previewController = QLPreviewController()
            previewController.dataSource = self
            previewController.delegate = self
            present(previewController, animated: true)
            
            self.previewController = previewController
        }
        
        // MARK: QLPreviewControllerDataSource
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            previewItem
        }
        
        // MARK: QLPreviewControllerDelegate
        
        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            onDismiss()
        }
    }
}

/// Wraps a media file and title to be previewed with QuickLook.
class MediaPreviewItem: NSObject, QLPreviewItem {
    let file: MediaFileHandleProxy
    
    var previewItemURL: URL? { file.url }
    let previewItemTitle: String?

    init(file: MediaFileHandleProxy, title: String?) {
        self.file = file
        previewItemTitle = title
    }
}

// MARK: - Previews

struct PreviewView_Previews: PreviewProvider {
    static let previewURL = URL(staticString: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")
    static let previewItem = MediaPreviewItem(file: .unmanaged(url: previewURL),
                                              title: "Important Document")
    
    static var previews: some View {
        MediaPreviewViewController(previewItem: previewItem) { }
    }
}
