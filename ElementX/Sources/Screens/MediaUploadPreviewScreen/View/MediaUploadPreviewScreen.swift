//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import QuickLook
import SwiftUI

struct MediaUploadPreviewScreen: View {
    @ObservedObject var context: MediaUploadPreviewScreenViewModel.Context
    
    var title: String {
        ProcessInfo.processInfo.isiOSAppOnMac ? context.viewState.title ?? "" : ""
    }
    
    var body: some View {
        mainContent
            .environment(\.colorScheme, .dark)
            .id(context.viewState.url)
            .ignoresSafeArea(edges: [.horizontal])
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composer
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .background() // Don't use compound so we match the QLPreviewController.
                    .environment(\.colorScheme, .dark)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .disabled(context.viewState.shouldDisableInteraction)
            .interactiveDismissDisabled()
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            Text(title)
                .font(.compound.headingMD)
                .foregroundColor(.compound.textSecondary)
        } else {
            PreviewView(fileURL: context.viewState.url,
                        title: context.viewState.title)
        }
    }
    
    private var composer: some View {
        HStack(spacing: 12) {
            MessageComposerTextField(placeholder: L10n.richTextEditorComposerCaptionPlaceholder,
                                     text: $context.caption,
                                     presendCallback: $context.presendCallback,
                                     maxHeight: ComposerConstant.maxHeight,
                                     keyHandler: { _ in },
                                     pasteHandler: { _ in })
                .messageComposerStyle()
            
            SendButton {
                context.send(viewAction: .send)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { context.send(viewAction: .cancel) } label: {
                Text(L10n.actionCancel)
            }
        }
    }
}

private struct PreviewView: UIViewControllerRepresentable {
    let fileURL: URL
    let title: String?

    func makeUIViewController(context: Context) -> UIViewController {
        let previewController = PreviewViewController()
        previewController.dataSource = context.coordinator
        previewController.delegate = context.coordinator
        
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return previewController
        } else {
            return UINavigationController(rootViewController: previewController)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let view: PreviewView

        init(view: PreviewView) {
            self.view = view
        }
        
        // MARK: - QLPreviewControllerDataSource
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            PreviewItem(previewItemURL: view.fileURL, previewItemTitle: view.title)
        }
        
        // MARK: - QLPreviewControllerDelegate
        
        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
            .disabled
        }
    }
}

private class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?

    init(previewItemURL: URL?, previewItemTitle: String?) {
        self.previewItemURL = previewItemURL
        self.previewItemTitle = previewItemTitle
    }
}

private class PreviewViewController: QLPreviewController {
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Remove top file details bar
        navigationController?.navigationBar.isHidden = true
                
        // Hide toolbar share button
        toolbarItems?.first?.isHidden = true
    }
}

// MARK: - Previews

struct MediaUploadPreviewScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = MediaUploadPreviewScreenViewModel(userIndicatorController: UserIndicatorControllerMock.default,
                                                             roomProxy: JoinedRoomProxyMock(),
                                                             mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: ServiceLocator.shared.settings),
                                                             title: "some random file name",
                                                             url: Bundle.main.url(forResource: "AppIcon60x60@2x", withExtension: "png") ?? .picturesDirectory)
    static var previews: some View {
        Text("Hello")
            .sheet(isPresented: .constant(true)) {
                NavigationStack {
                    MediaUploadPreviewScreen(context: viewModel.context)
                }
            }
    }
}
