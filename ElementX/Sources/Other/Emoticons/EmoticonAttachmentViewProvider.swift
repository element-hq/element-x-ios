//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import UIKit

final class EmoticonAttachmentViewProvider: NSTextAttachmentViewProvider {
    private weak var delegate: TextAttachmentViewProviderDelegate?
    
    override nonisolated init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)
        
        // TextKit isn't annotated but creates the view providers on the main thread,
        // the assumeIsolated below would trap otherwise.
        nonisolated(unsafe) let provider = self
        MainActor.assumeIsolated {
            provider.delegate = parentView?.superview as? TextAttachmentViewProviderDelegate
        }
        tracksTextAttachmentViewBounds = true
    }
    
    override nonisolated func loadView() {
        super.loadView()
        
        // TextKit isn't annotated but loads the view on the main thread,
        // the assumeIsolated below would trap otherwise.
        nonisolated(unsafe) let provider = self
        MainActor.assumeIsolated {
            // Emoticons carry no mimetype, so always hint `image/gif` to take LoadableImage's animated path.
            // Kingfisher sniffs the actual format, so static images still render (full size, no thumbnail).
            guard let url = (provider.textAttachment as? EmoticonTextAttachment)?.url,
                  let mediaSource = try? MediaSourceProxy(url: url, mimeType: "image/gif") else {
                MXLog.failure("Attachment is missing its URL or not of expected class")
                return
            }
            
            let mediaProvider: MediaProviderProtocol? = if ProcessInfo.isXcodePreview || ProcessInfo.isRunningTests {
                MediaProviderMock(.init())
            } else {
                provider.delegate?.timelineContext?.mediaProvider
            }
            
            let view = LoadableImage(mediaSource: mediaSource,
                                     mediaProvider: mediaProvider,
                                     transformer: { [weak provider] in
                                         $0
                                             .scaledToFit()
                                             // TextKit only shows attachment views when drawing them, so this redraw
                                             // stops an image that loads after the text was drawn from staying hidden.
                                             .onAppear { provider?.delegate?.invalidateTextAttachmentsDisplay() }
                                     },
                                     placeholder: { Color.clear })
            let controller = UIHostingController(rootView: view)
            controller.view.backgroundColor = .clear
            controller.view.isUserInteractionEnabled = false
            provider.view = controller.view
        }
    }
}
