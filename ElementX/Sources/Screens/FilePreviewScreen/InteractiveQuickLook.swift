//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import QuickLook
import SwiftUI

extension View {
    /// Preview a media file using a QuickLook Preview Controller. The preview is interactive with
    /// the dismiss gesture working as expected if it was presented from UIKit.
    func interactiveQuickLook(item: Binding<MediaPreviewItem?>, allowEditing: Bool = true) -> some View {
        modifier(InteractiveQuickLookModifier(item: item, allowEditing: allowEditing))
    }
}

private struct InteractiveQuickLookModifier: ViewModifier {
    @Binding var item: MediaPreviewItem?
    let allowEditing: Bool
    
    @State private var dismissalPublisher = PassthroughSubject<Void, Never>()
    
    func body(content: Content) -> some View {
        content.background {
            if let item {
                MediaPreviewViewController(previewItem: item,
                                           allowEditing: allowEditing,
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
    let allowEditing: Bool
    let dismissalPublisher: PassthroughSubject<Void, Never>
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> PreviewHostingController {
        PreviewHostingController(previewItem: previewItem,
                                 allowEditing: allowEditing,
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
        let allowEditing: Bool
        let onDismiss: () -> Void
        let sourceView = UIView()
        
        private var dismissalObserver: AnyCancellable?
        
        var previewController: QLPreviewController?

        init(previewItem: MediaPreviewItem,
             allowEditing: Bool,
             dismissalPublisher: PassthroughSubject<Void, Never>,
             onDismiss: @escaping () -> Void) {
            self.previewItem = previewItem
            self.allowEditing = allowEditing
            self.onDismiss = onDismiss

            super.init(nibName: nil, bundle: nil)
            
            // The QLPreviewController will not automatically dismiss itself when the underlying view is removed
            // (e.g. switching rooms from a notification) and it continues to hold on to the whole hierarcy.
            // Manually tell it to dismiss itself here.
            dismissalObserver = dismissalPublisher.sink { [weak self] _ in
                // Dispatching on main.async with weak self we avoid doing an extra dismiss if the view is presented on top of another modal
                DispatchQueue.main.async { [weak self] in
                    self?.dismiss(animated: true)
                }
            }
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            view.backgroundColor = .clear
            view.addSubview(sourceView)
            
            sourceView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                sourceView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                sourceView.centerYAnchor.constraint(equalTo: view.bottomAnchor),
                sourceView.widthAnchor.constraint(equalToConstant: 200),
                sourceView.heightAnchor.constraint(equalToConstant: 200)
            ])
        }
        
        // Don't use viewWillAppear due to the following warning:
        // Presenting view controller <QLPreviewController> from detached view controller <HostingController> is not supported,
        // and may result in incorrect safe area insets and a corrupt root presentation. Make sure <HostingController> is in
        // the view controller hierarchy before presenting from it. Will become a hard exception in a future release.
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
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
        
        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
            allowEditing ? .createCopy : .disabled
        }
        
        func previewController(_ controller: QLPreviewController, transitionViewFor item: any QLPreviewItem) -> UIView? {
            sourceView
        }
        
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
    static let previewURL: URL = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
    static let previewItem = MediaPreviewItem(file: .unmanaged(url: previewURL),
                                              title: "Important Document")
    
    static var previews: some View {
        MediaPreviewViewController(previewItem: previewItem,
                                   allowEditing: false,
                                   dismissalPublisher: .init()) { }
    }
}
