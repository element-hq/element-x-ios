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
import SwiftUIIntrospect
import UIKit

import WysiwygComposer

final class PillAttachmentViewProvider: NSTextAttachmentViewProvider {
    private weak var textView: UIView?
    
    // MARK: - Override
    
    override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)

        // Keep a reference to the parent text view for size adjustments and pills flushing.
        textView = parentView?.superview
        tracksTextAttachmentViewBounds = true
    }
    
    @MainActor
    override func loadView() {
        super.loadView()

        guard let textAttachmentData = (textAttachment as? PillTextAttachment)?.pillData else {
            MXLog.failure("[PillAttachmentViewProvider]: attachment is missing data or not of expected class")
            return
        }
        
        let context: PillContext
        let imageProvider: ImageProviderProtocol?
        if ProcessInfo.isXcodePreview || ProcessInfo.isRunningTests {
            // The mock viewModel simulates the loading logic for testing purposes
            context = PillContext.mock(type: .loadUser(isOwn: false))
            imageProvider = MockMediaProvider()
        } else if let roomContext = (textView as? MessageTextView)?.roomContext {
            context = PillContext(roomContext: roomContext, data: textAttachmentData)
            imageProvider = roomContext.imageProvider
        } else if let wysiwigTextView = (textView as? WysiwygTextView),
                  let roomContext = (wysiwigTextView.mentionDisplayHelper as? ComposerMentionDisplayHelper)?.roomContext {
            context = PillContext(roomContext: roomContext, data: textAttachmentData)
            imageProvider = roomContext.imageProvider
        } else {
            MXLog.failure("[PillAttachmentViewProvider]: missing room context")
            return
        }
        
        let view = PillView(imageProvider: imageProvider, context: context) { [weak self] in
            guard let messageTextView = self?.textView as? MessageTextView else {
                return
            }
            messageTextView.invalidateTextAttachmentsDisplay(update: true)
        }
        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        // This allows the text view to handle it as a link
        controller.view.isUserInteractionEnabled = false
        self.view = controller.view
        if let wysywygView = textView as? WysiwygTextView {
            wysywygView.registerPillView(controller.view)
        }
    }
}
