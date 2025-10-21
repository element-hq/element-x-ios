//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import LinkPresentation
import SwiftUI

struct LinkPreviewView: UIViewRepresentable {
    let url: URL
    let metadata: LPLinkMetadata?
    
    func makeUIView(context: Context) -> LPLinkView {
        let preview = LPLinkView(url: url)
        
        if let metadata {
            preview.metadata = metadata
        }
        
        return preview
    }
    
    func updateUIView(_ uiView: LPLinkView, context: Context) {
        if let metadata {
            uiView.metadata = metadata
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: LPLinkView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.intrinsicContentSize.width
        let bestFit = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        
        return CGSize(width: width, height: bestFit.height)
    }
}

struct LinkPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        if let url = URL(string: "https://www.lunch.club") {
            LinkPreviewView(url: url, metadata: appleMetadata)
                .previewLayout(.sizeThatFits)
        }
    }
    
    private static var appleMetadata: LPLinkMetadata {
        let metadata = LPLinkMetadata()
        metadata.title = "Lunch club"
        
        if let url = Bundle.main.url(forResource: "preview_avatar_room", withExtension: "jpg") {
            metadata.url = url
            metadata.imageProvider = NSItemProvider(contentsOf: url)
        }
        
        return metadata
    }
}
