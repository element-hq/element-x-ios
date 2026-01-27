//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import QuickLook
import SwiftUI

extension View {
    /// Preview a media file using a QuickLook Preview Controller. The preview is interactive with
    /// the dismiss gesture working as expected if it was presented from UIKit.
    func timelineMediaPreview(viewModel: Binding<TimelineMediaPreviewViewModel?>) -> some View {
        modifier(TimelineMediaPreviewModifier(viewModel: viewModel))
    }
}

private struct TimelineMediaPreviewModifier: ViewModifier {
    @Binding var viewModel: TimelineMediaPreviewViewModel?
    
    @State private var dismissalPublisher = PassthroughSubject<Void, Never>()
    
    func body(content: Content) -> some View {
        content.background {
            if let viewModel {
                MediaPreviewViewController(viewModel: viewModel,
                                           dismissalPublisher: dismissalPublisher) { self.viewModel = nil }
                    .id(viewModel.instanceID) // Fixes a bug where opening a second preview too quickly can break presentation.
            } else {
                // Work around QLPreviewController dismissal issues, see below.
                let _ = dismissalPublisher.send(())
            }
        }
    }
}

private struct MediaPreviewViewController: UIViewControllerRepresentable {
    let viewModel: TimelineMediaPreviewViewModel
    let dismissalPublisher: PassthroughSubject<Void, Never>
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> PreviewHostingController {
        PreviewHostingController(viewModel: viewModel,
                                 dismissalPublisher: dismissalPublisher,
                                 onDismiss: onDismiss)
    }

    func updateUIViewController(_ uiViewController: PreviewHostingController, context: Context) { }
    
    /// A view controller that hosts the QuickLook preview.
    ///
    /// This wrapper somehow allows the preview controller to do presentation/dismissal
    /// animations and interactions which don't work if you represent it directly to SwiftUI 🤷‍♂️
    class PreviewHostingController: UIViewController, QLPreviewControllerDelegate {
        let onDismiss: () -> Void
        let sourceView = UIView()
        
        private let previewController: TimelineMediaPreviewController
        private var hasBeenPresented = false
        
        private var dismissalObserver: AnyCancellable?
        private var cancellables: Set<AnyCancellable> = []
        
        init(viewModel: TimelineMediaPreviewViewModel,
             dismissalPublisher: PassthroughSubject<Void, Never>,
             onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
            previewController = TimelineMediaPreviewController(context: viewModel.context)

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
                sourceView.widthAnchor.constraint(equalToConstant: 100),
                sourceView.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
        
        /// Don't use viewWillAppear due to the following warning:
        /// Presenting view controller <QLPreviewController> from detached view controller <HostingController> is not supported,
        /// and may result in incorrect safe area insets and a corrupt root presentation. Make sure <HostingController> is in
        /// the view controller hierarchy before presenting from it. Will become a hard exception in a future release.
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            guard !hasBeenPresented else { return }
            
            previewController.delegate = self
            
            present(previewController, animated: true)
            
            hasBeenPresented = true
        }
        
        // MARK: QLPreviewControllerDelegate
        
        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
            .disabled
        }
        
        func previewController(_ controller: QLPreviewController, transitionViewFor item: any QLPreviewItem) -> UIView? {
            sourceView
        }
        
        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            onDismiss()
        }
    }
}

// MARK: - Previews

struct TimelineMediaPreviewModifier_Previews: PreviewProvider {
    static let viewModel = makeViewModel()
    static let downloadingViewModel = makeViewModel(isDownloading: true)
    static let downloadErrorViewModel = makeViewModel(isDownloadError: true)
    
    static var previews: some View {
        MediaPreviewViewController(viewModel: viewModel, dismissalPublisher: .init()) { }
            .previewDisplayName("Normal")
        MediaPreviewViewController(viewModel: downloadingViewModel, dismissalPublisher: .init()) { }
            .previewDisplayName("Downloading")
        MediaPreviewViewController(viewModel: downloadErrorViewModel, dismissalPublisher: .init()) { }
            .previewDisplayName("Download Error")
    }
    
    static func makeViewModel(isDownloading: Bool = false, isDownloadError: Bool = false) -> TimelineMediaPreviewViewModel {
        let item = FileRoomTimelineItem(id: .randomEvent,
                                        timestamp: .mock,
                                        isOutgoing: false,
                                        isEditable: false,
                                        canBeRepliedTo: true,
                                        sender: .init(id: "", displayName: "Sally Sanderson"),
                                        content: .init(filename: "Important document.pdf",
                                                       caption: "A caption goes right here.",
                                                       source: try? .init(url: .mockMXCFile, mimeType: nil),
                                                       fileSize: 3 * 1024 * 1024,
                                                       thumbnailSource: nil,
                                                       contentType: .pdf))
        
        let timelineController = MockTimelineController(timelineKind: .media(.mediaFilesScreen))
        timelineController.timelineItems = [item]
        
        let mediaProvider = MediaProviderMock(configuration: .init())
        
        if isDownloading {
            mediaProvider.loadFileFromSourceFilenameClosure = { _, _ in
                try? await Task.sleep(for: .seconds(3600))
                return .failure(.failedRetrievingFile)
            }
        } else if isDownloadError {
            mediaProvider.loadFileFromSourceFilenameClosure = { _, _ in .failure(.failedRetrievingFile) }
        }
        
        return TimelineMediaPreviewViewModel(initialItem: item,
                                             timelineViewModel: TimelineViewModel.mock(timelineKind: timelineController.timelineKind,
                                                                                       timelineController: timelineController),
                                             mediaProvider: mediaProvider,
                                             photoLibraryManager: PhotoLibraryManagerMock(.init()),
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             appMediator: AppMediatorMock())
    }
}
