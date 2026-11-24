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
            
            let hidesImage = provider.delegate?.timelineContext?.viewState.hideTimelineMedia ?? false
            let view = EmoticonView(mediaSource: mediaSource, mediaProvider: mediaProvider, hidesImage: hidesImage) { [weak provider] in
                // TextKit only shows attachment views when drawing them, so this redraw stops
                // an image or placeholder that appears after the text was drawn from staying hidden.
                provider?.delegate?.invalidateTextAttachmentsDisplay()
            }
            let controller = UIHostingController(rootView: view)
            controller.view.backgroundColor = .clear
            // Only interactive while hidden, for the tap to reveal.
            controller.view.isUserInteractionEnabled = hidesImage
            provider.view = controller.view
        }
    }
}

/// An emoticon's image, hidden behind a tap to reveal when the timeline hides its media.
private struct EmoticonView: View {
    let mediaSource: MediaSourceProxy
    let mediaProvider: MediaProviderProtocol?
    let hidesImage: Bool
    let onViewAppear: () -> Void
    
    var body: some View {
        LoadableImage(mediaSource: mediaSource,
                      mediaProvider: mediaProvider,
                      transformer: { $0.scaledToFit().onAppear(perform: onViewAppear) },
                      placeholder: { Color.clear.onAppear(perform: onViewAppear) })
            .environment(\.shouldAutomaticallyLoadImages, !hidesImage)
            .environment(\.showsIconForHiddenImages, true)
    }
}
