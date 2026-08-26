//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum TimelineMediaFrame {
    /// The maximum height of a media item in the timeline.
    static let maxMediaHeight = 300.0
    /// The minimum height of a media item in the timeline.
    static let minMediaHeight = 100.0
    /// The size of a media item with an unknown aspect ratio.
    static let defaultMediaSize = 100.0
    /// The maximum width of a timeline link preview
    static let maxLinkPreviewWidth = 300.0
}

extension View {
    /// Constrains the max height of a media item in the timeline, whilst preserving its aspect ratio.
    @ViewBuilder
    func timelineMediaFrame(imageInfo: ImageInfoProxy?) -> some View {
        if let contentHeight = imageInfo?.size?.height, contentHeight < TimelineMediaFrame.minMediaHeight { // Special case very small images
            aspectRatio(imageInfo?.aspectRatio, contentMode: .fit)
                .frame(minHeight: TimelineMediaFrame.minMediaHeight, maxHeight: TimelineMediaFrame.minMediaHeight)
        } else {
            if let contentAspectRatio = imageInfo?.aspectRatio {
                aspectRatio(contentAspectRatio, contentMode: .fit)
                    .frame(maxHeight: min(TimelineMediaFrame.maxMediaHeight, max(TimelineMediaFrame.minMediaHeight, imageInfo?.size?.height ?? .infinity)))
                    // Required to prevent the reply details to get higher priority in rendering the width of the view.
                    .aspectRatio(contentAspectRatio, contentMode: .fit)
            } else { // Otherwise force the image to be `defaultSize` x `defaultSize`
                frame(width: TimelineMediaFrame.defaultMediaSize, height: TimelineMediaFrame.defaultMediaSize)
            }
        }
    }
    
    func mediaGalleryTimelineAspectRatio(imageInfo: ImageInfoProxy?) -> some View {
        aspectRatio(imageInfo?.aspectRatio, contentMode: .fill)
    }
}
