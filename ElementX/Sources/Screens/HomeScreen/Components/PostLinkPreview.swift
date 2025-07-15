//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Kingfisher
import SwiftUI

struct PostLinkPreview: View {
    let linkPreview: ZLinkPreview
    
    var body: some View {
        VStack(spacing: 0) {
            if let thumbnail = linkPreview.thumbnail,
               let thumbnailURL = linkPreview.thumbnailURL {
                ZStack {
                    KFAnimatedImage(thumbnailURL)
                        .placeholder {
                            Image(systemName: "link")
                        }
                        .fade(duration: 0.3)
                        .aspectRatio(thumbnail.aspectRatio, contentMode: .fit)
                        .cornerRadius(4, corners: .allCorners)
                    
                    if linkPreview.isAYoutubeVideo {
                        Image(systemName: "play")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                            .background(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .aspectRatio(contentMode: .fit)
                    }
                }
            }
            
            HStack(alignment: .center) {
                if linkPreview.thumbnail == nil {
                    Image(systemName: "link")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(4, corners: .allCorners)
                }
                VStack(alignment: .leading) {
                    if let title = linkPreview.title {
                        Text(title)
                            .font(.zero.bodyMDSemibold)
                            .foregroundColor(.compound.textPrimary)
                            .lineLimit(1)
                    }
                    
                    let description = linkPreview.isAYoutubeVideo ? linkPreview.youtubeVideoDescription : linkPreview.url
                    Text(description)
                        .font(.zero.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
