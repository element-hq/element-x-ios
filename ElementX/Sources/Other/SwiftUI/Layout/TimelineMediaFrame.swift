//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension View {
    /// Constrains the max height of a media item in the timeline, whilst preserving its aspect ratio.
    @ViewBuilder
    func timelineMediaFrame(imageInfo: ImageInfoProxy?) -> some View {
        let defaultMediaSize = 100.0
        let minMediaHeight = 100.0
        let maxMediaHeight = 300.0
        
        if let contentHeight = imageInfo?.size?.height, contentHeight < minMediaHeight { // Special case very small images
            aspectRatio(imageInfo?.aspectRatio, contentMode: .fit)
                .frame(minHeight: minMediaHeight, maxHeight: minMediaHeight)
        } else {
            if let contentAspectRatio = imageInfo?.aspectRatio {
                aspectRatio(contentAspectRatio, contentMode: .fit)
                    .frame(maxHeight: min(maxMediaHeight, max(minMediaHeight, imageInfo?.size?.height ?? .infinity)))
                    // Required to prevent the reply details to get higher priority in rendering the width of the view.
                    .aspectRatio(contentAspectRatio, contentMode: .fit)
            } else { // Otherwise force the image to be `defaultMediaSize` x `defaultMediaSize`
                frame(width: defaultMediaSize, height: defaultMediaSize)
            }
        }
    }
    
    @ViewBuilder
    func mediaGalleryTimelineAspectRatio(imageInfo: ImageInfoProxy?) -> some View {
        aspectRatio(imageInfo?.aspectRatio, contentMode: .fill)
    }
}
