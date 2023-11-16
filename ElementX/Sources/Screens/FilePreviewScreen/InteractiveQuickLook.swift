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

import Combine
import QuickLook
import SwiftUI

extension View {
    /// Preview a media file using a QuickLook Preview Controller. The preview is interactive with
    /// the dismiss gesture working as expected if it was presented from UIKit.
    func interactiveQuickLook(item: Binding<MediaPreviewItem?>, shouldHideControls: Bool = false) -> some View {
        modifier(InteractiveQuickLookModifier(item: item, shouldHideControls: shouldHideControls))
    }
}

private struct InteractiveQuickLookModifier: ViewModifier {
    @Binding var item: MediaPreviewItem?
    let shouldHideControls: Bool
    
    @State private var dismissalPublisher = PassthroughSubject<Void, Never>()
    
    func body(content: Content) -> some View {
        content.background {
            if let item {
                MediaPreviewViewController(previewItem: item,
                                           shouldHideControls: shouldHideControls,
                                           dismissalPublisher: dismissalPublisher) { self.item = nil }
            } else {
                // Work around QLPreviewController dismissal issues, see below.
                let _ = dismissalPublisher.send(())
            }
        }
    }
}

private struct MediaPreviewViewController: UIViewControllerRepresentable {
    let previewItem: MediaPreviewItem
    let shouldHideControls: Bool
    let dismissalPublisher: PassthroughSubject<Void, Never>
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> PreviewHostingController {
        PreviewHostingController(previewItem: previewItem,
                                 shouldHideControls: shouldHideControls,
                                 dismissalPublisher: dismissalPublisher,
                                 onDismiss: onDismiss)
    }

    func updateUIViewController(_ uiViewController: PreviewHostingController, context: Context) { }
    
    /// A view controller that hosts the QuickLook preview.
    ///
    /// This wrapper somehow allows the preview controller to do presentation/dismissal
    /// animations and interactions which don't work if you represent it directly to SwiftUI 🤷‍♂️
    class PreviewHostingController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let previewItem: MediaPreviewItem
        let shouldHideControls: Bool
        let dismissalPublisher: PassthroughSubject<Void, Never>
        let onDismiss: () -> Void
        
        private var dismissalObserver: AnyCancellable?
        
        var previewController: QLPreviewController?

        init(previewItem: MediaPreviewItem,
             shouldHideControls: Bool,
             dismissalPublisher: PassthroughSubject<Void, Never>,
             onDismiss: @escaping () -> Void) {
            self.previewItem = previewItem
            self.shouldHideControls = shouldHideControls
            self.dismissalPublisher = dismissalPublisher
            self.onDismiss = onDismiss

            super.init(nibName: nil, bundle: nil)
            
            // The QLPreviewController will not automatically dismiss itself when the underlying view is removed
            // (e.g. switching rooms from a notification) and it continues to hold on to the whole hierarcy.
            // Manually tell it to dismiss itself here.
            dismissalObserver = dismissalPublisher.sink { _ in
                self.dismiss(animated: true)
            }
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
            
            let previewController = (shouldHideControls ? NoControlsPreviewController() : QLPreviewController())
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

private class NoControlsPreviewController: QLPreviewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let navigationController = children.first as? UINavigationController else {
            return
        }
        
        // Remove top file details bar
        navigationController.navigationBar.isHidden = true
        
        // Remove the toolbars and their buttons
        navigationController.view.subviews.compactMap { $0 as? UIToolbar }.forEach { toolbar in
            toolbar.subviews.forEach { item in
                item.isHidden = true
            }
            
            toolbar.isHidden = true
        }
    }
}

// MARK: - Previews

struct PreviewView_Previews: PreviewProvider {
    static let previewURL: URL = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
    static let previewItem = MediaPreviewItem(file: .unmanaged(url: previewURL),
                                              title: "Important Document")
    
    static var previews: some View {
        MediaPreviewViewController(previewItem: previewItem,
                                   shouldHideControls: false,
                                   dismissalPublisher: .init()) { }
    }
}
