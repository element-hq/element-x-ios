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
    func timelineMediaQuickLook(viewModel: Binding<TimelineMediaPreviewViewModel?>) -> some View {
        modifier(TimelineMediaQuickLookModifier(viewModel: viewModel))
    }
}

private struct TimelineMediaQuickLookModifier: ViewModifier {
    @Binding var viewModel: TimelineMediaPreviewViewModel?
    
    @State private var dismissalPublisher = PassthroughSubject<Void, Never>()
    
    func body(content: Content) -> some View {
        content.background {
            if let viewModel {
                EmbeddedQuickLookPresenter(viewModel: viewModel, dismissalPublisher: dismissalPublisher) {
                    self.viewModel = nil
                }
            } else {
                // Work around QLPreviewController dismissal issues, see below.
                let _ = dismissalPublisher.send(())
            }
        }
    }
}

/// When this view is put in the background of a SwiftUI view hierarchy,
/// it will present a QLPreviewController on top of the entire app.
private struct EmbeddedQuickLookPresenter: UIViewControllerRepresentable {
    let viewModel: TimelineMediaPreviewViewModel
    let dismissalPublisher: PassthroughSubject<Void, Never>
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> PresentingController {
        PresentingController(viewModel: viewModel, dismissalPublisher: dismissalPublisher, onDismiss: onDismiss)
    }

    func updateUIViewController(_ uiViewController: PresentingController, context: Context) { }
    
    /// A view controller that hosts the QuickLook preview.
    ///
    /// This wrapper somehow allows the preview controller to do presentation/dismissal
    /// animations and interactions which don't work if you represent it directly to SwiftUI 🤷‍♂️
    class PresentingController: UIViewController, QLPreviewControllerDelegate {
        private let previewController: QLPreviewController
        private let sourceView = UIView()
        
        private var hasPresented = false
        private let onDismiss: () -> Void
        private var dismissalObserver: AnyCancellable?

        init(viewModel: TimelineMediaPreviewViewModel,
             dismissalPublisher: PassthroughSubject<Void, Never>,
             onDismiss: @escaping () -> Void) {
            previewController = TimelineMediaPreviewController(viewModel: viewModel)
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
            
            guard !hasPresented else { return }
            
            previewController.delegate = self
            present(previewController, animated: true)
            hasPresented = true
        }
        
        // MARK: QLPreviewControllerDelegate
        
        func previewController(_ controller: QLPreviewController, transitionViewFor item: any QLPreviewItem) -> UIView? {
            sourceView
        }
        
        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            onDismiss()
        }
    }
}

// MARK: - Previews

struct TimelineMediaQuickLook_Previews: PreviewProvider {
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        EmbeddedQuickLookPresenter(viewModel: viewModel, dismissalPublisher: .init()) { }
    }
    
    static func makeViewModel() -> TimelineMediaPreviewViewModel {
        let item = FileRoomTimelineItem(id: .randomEvent,
                                        timestamp: .mock,
                                        isOutgoing: false,
                                        isEditable: false,
                                        canBeRepliedTo: true,
                                        isThreaded: false,
                                        sender: .init(id: "", displayName: "Sally Sanderson"),
                                        content: .init(filename: "Important document.pdf",
                                                       caption: "A caption goes right here.",
                                                       source: try? .init(url: .mockMXCFile, mimeType: nil),
                                                       fileSize: 3 * 1024 * 1024,
                                                       thumbnailSource: nil,
                                                       contentType: .pdf))
        
        return TimelineMediaPreviewViewModel(initialItem: item,
                                             isFromRoomScreen: false,
                                             timelineViewModel: TimelineViewModel.mock,
                                             mediaProvider: MediaProviderMock(configuration: .init()),
                                             userIndicatorController: UserIndicatorControllerMock())
    }
}
