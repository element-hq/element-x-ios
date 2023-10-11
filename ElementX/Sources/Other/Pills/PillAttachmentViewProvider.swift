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

protocol PillAttachmentViewProviderDelegate: AnyObject {
    var roomContext: RoomScreenViewModel.Context? { get }
    
    func registerPillView(_ pillView: UIView)
    func invalidateTextAttachmentsDisplay(update: Bool)
}

final class PillAttachmentViewProvider: NSTextAttachmentViewProvider {
    private weak var delegate: PillAttachmentViewProviderDelegate?
    
    // MARK: - Override
    
    override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)

        // Keep a reference to the parent text view for size adjustments and pills flushing.
        delegate = parentView?.superview as? PillAttachmentViewProviderDelegate
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
        } else if let roomContext = delegate?.roomContext {
            context = PillContext(roomContext: roomContext, data: textAttachmentData)
            imageProvider = roomContext.imageProvider
        } else {
            MXLog.failure("[PillAttachmentViewProvider]: missing room context")
            return
        }
        
        let view = PillView(imageProvider: imageProvider, context: context) { [weak self] in
            self?.delegate?.invalidateTextAttachmentsDisplay(update: true)
        }
        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        // This allows the text view to handle it as a link
        controller.view.isUserInteractionEnabled = false
        self.view = controller.view
        delegate?.registerPillView(controller.view)
    }
}

final class ComposerMentionDisplayHelper: MentionDisplayHelper {
    weak var roomContext: RoomScreenViewModel.Context?

    init(roomContext: RoomScreenViewModel.Context) {
        self.roomContext = roomContext
    }
    
    @MainActor
    static var mock: Self {
        Self(roomContext: RoomScreenViewModel.mock.context)
    }
}

extension WysiwygTextView: PillAttachmentViewProviderDelegate {
    var roomContext: RoomScreenViewModel.Context? {
        (mentionDisplayHelper as? ComposerMentionDisplayHelper)?.roomContext
    }
    
    func invalidateTextAttachmentsDisplay(update: Bool) { }
}
