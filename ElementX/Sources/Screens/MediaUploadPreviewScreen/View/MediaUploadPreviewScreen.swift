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

struct MediaUploadPreviewScreen: View {
    @ObservedObject var context: MediaUploadPreviewScreenViewModel.Context
    
    var title: String {
        ProcessInfo.processInfo.isiOSAppOnMac ? context.viewState.title ?? "" : ""
    }
    
    var body: some View {
        mainContent
            .id(UUID())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .disabled(context.viewState.shouldDisableInteraction)
            .ignoresSafeArea(edges: [.horizontal, .bottom])
            .toolbar { toolbar }
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
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { context.send(viewAction: .cancel) } label: {
                Text(L10n.actionCancel)
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button { context.send(viewAction: .send) } label: {
                Text(L10n.actionSend)
            }
            .disabled(context.viewState.shouldDisableInteraction)
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

// MARK: - Previews

struct MediaUploadPreviewScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = MediaUploadPreviewScreenViewModel(userIndicatorController: UserIndicatorControllerMock.default,
                                                             roomProxy: RoomProxyMock(),
                                                             mediaUploadingPreprocessor: MediaUploadingPreprocessor(),
                                                             title: "some random file name",
                                                             url: URL.picturesDirectory)
    static var previews: some View {
        NavigationStack {
            MediaUploadPreviewScreen(context: viewModel.context)
        }
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
