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
import UIKit

final class PillAttachmentViewProvider: NSTextAttachmentViewProvider {
    private var isXcodePreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    private weak var messageTextView: MessageTextView?
    
    // MARK: - Override
    
    override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)

        // Keep a reference to the parent text view for size adjustments and pills flushing.
        messageTextView = parentView?.superview as? MessageTextView
        tracksTextAttachmentViewBounds = true
    }
    
    override func loadView() {
        super.loadView()

        guard let textAttachmentData = (textAttachment as? PillTextAttachment)?.pillData else {
            MXLog.failure("[PillAttachmentViewProvider]: attachment is missing data or not of expected class")
            return
        }
        
        let imageProvider = MockMediaProvider()
        let viewModel: PillViewModel
        if isXcodePreview {
            viewModel = PillViewModel.mockViewModel(type: .user)
        } else if let clientProxy = Self.currentSession?.clientProxy {
            viewModel = PillViewModel(clientProxy: clientProxy, data: textAttachmentData)
        } else {
            MXLog.failure("[PillAttachmentViewProvider]: client proxy is missing")
            return
        }
        var view = PillView(imageProvider: imageProvider, viewModel: viewModel) { [weak self] in
            self?.messageTextView?.invalidateTextAttachmentsDisplay()
        }
        let controller = UIHostingController(rootView: view)
        self.view = controller.view
    }
}

extension PillAttachmentViewProvider {
    // This is a bit of an hack, since the Provider is instantiated by the system we have no way to pass the current session it, so we need to inject it globally.
    static var currentSession: UserSessionProtocol?
}
