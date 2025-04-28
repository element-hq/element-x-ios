//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Kingfisher
import SwiftUI

struct TimelineLinkPreviewView: View {
    let preview: ZLinkPreview
    
    var body: some View {
        HStack(spacing: 8) {
            if let thumbnailURL = preview.thumbnailURL {
                KFAnimatedImage(thumbnailURL)
                    .placeholder {
                        Image(systemName: "link")
                    }
                    .frame(width: 36, height: 36)
                    .cornerRadius(4, corners: .allCorners)
            } else {
                Image(systemName: "link")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(4, corners: .allCorners)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if let title = preview.title {
                    Text(title)
                        .font(.zero.bodySMSemibold)
                        .foregroundColor(.compound.textPrimary)
                        .lineLimit(1)
                }
                
                Text(preview.url)
                    .font(.zero.bodyMD)
                    .foregroundColor(.compound.textSecondary)
                    .tint(.compound.textLinkExternal)
                    .lineLimit(1)
            }
            .padding(.leading, preview.thumbnail == nil ? 8 : 0)
            .padding(.trailing, 8)
        }
    }
}
