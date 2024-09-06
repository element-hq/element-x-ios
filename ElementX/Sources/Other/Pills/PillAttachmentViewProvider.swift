//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI
import SwiftUIIntrospect
import UIKit

import WysiwygComposer

protocol PillAttachmentViewProviderDelegate: AnyObject {
    var timelineContext: TimelineViewModel.Context? { get }
    
    func registerPillView(_ pillView: UIView)
    func invalidateTextAttachmentsDisplay()
}

final class PillAttachmentViewProvider: NSTextAttachmentViewProvider, NSSecureCoding {
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

        guard let textAttachment = textAttachment as? PillTextAttachment,
              let pillData = textAttachment.pillData else {
            MXLog.failure("[PillAttachmentViewProvider]: attachment is missing data or not of expected class")
            return
        }
        
        let context: PillContext
        let mediaProvider: MediaProviderProtocol?
        if ProcessInfo.isXcodePreview || ProcessInfo.isRunningTests {
            // The mock viewModel simulates the loading logic for testing purposes
            context = PillContext.mock(type: .loadUser(isOwn: false))
            mediaProvider = MockMediaProvider()
        } else if let timelineContext = delegate?.timelineContext {
            context = PillContext(timelineContext: timelineContext, data: pillData)
            mediaProvider = timelineContext.mediaProvider
        } else {
            MXLog.failure("[PillAttachmentViewProvider]: missing room context")
            return
        }
        
        let view = PillView(mediaProvider: mediaProvider, context: context) { [weak self] in
            self?.delegate?.invalidateTextAttachmentsDisplay()
        }
        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        // This allows the text view to handle it as a link
        controller.view.isUserInteractionEnabled = false
        self.view = controller.view
        delegate?.registerPillView(controller.view)
    }
    
    // MARK: - NSSecureCoding
    
    // Fixes crashes when inserting mention pills in the composer on Mac
    // https://github.com/element-hq/element-x-ios/issues/2070
    
    // periphery:ignore - read comment above
    static var supportsSecureCoding = false
    
    // periphery:ignore - read comment above
    func encode(with coder: NSCoder) { }
    
    // periphery:ignore - read comment above
    init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

final class ComposerMentionDisplayHelper: MentionDisplayHelper {
    weak var timelineContext: TimelineViewModel.Context?

    init(timelineContext: TimelineViewModel.Context) {
        self.timelineContext = timelineContext
    }
    
    @MainActor
    static var mock: Self {
        Self(timelineContext: TimelineViewModel.mock.context)
    }
}

extension WysiwygTextView: PillAttachmentViewProviderDelegate {
    var timelineContext: TimelineViewModel.Context? {
        (mentionDisplayHelper as? ComposerMentionDisplayHelper)?.timelineContext
    }
    
    func invalidateTextAttachmentsDisplay() { }
}
