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
import UIKit

struct FilePreviewScreen: View {
    @ObservedObject var context: FilePreviewViewModel.Context
    
    var body: some View {
        PreviewView(context: context,
                    fileURL: context.viewState.fileURL,
                    title: context.viewState.title)
            .ignoresSafeArea()
    }
}

private struct PreviewView: UIViewControllerRepresentable {
    let context: FilePreviewViewModel.Context
    let fileURL: URL
    let title: String?

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: .done,
                                         target: context.coordinator,
                                         action: #selector(Coordinator.done))
        controller.navigationItem.rightBarButtonItem = doneButton

        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let view: PreviewView

        init(view: PreviewView) {
            self.view = view
        }

        @objc func done() {
            Task { await view.context.send(viewAction: .cancel) }
        }
        
        // MARK: - QLPreviewControllerDataSource
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            PreviewItem(previewItemURL: view.fileURL, previewItemTitle: view.title)
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

struct FilePreview_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let upgradeViewModel = FilePreviewViewModel(fileURL: URL(staticString: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"))
            FilePreviewScreen(context: upgradeViewModel.context)
        }
        .tint(.element.accent)
    }
}
