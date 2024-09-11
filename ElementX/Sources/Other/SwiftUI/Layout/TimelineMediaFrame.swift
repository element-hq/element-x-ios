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
    func timelineMediaFrame(height contentHeight: CGFloat?, aspectRatio contentAspectRatio: CGFloat?) -> some View {
        let defaultMediaSize = 100.0
        let minMediaHeight = 100.0
        let maxMediaHeight = 300.0
        
        if let contentHeight, contentHeight < minMediaHeight { // Special case very small images
            aspectRatio(contentAspectRatio, contentMode: .fit)
                .frame(minHeight: minMediaHeight, maxHeight: minMediaHeight)
        } else {
            if let contentAspectRatio {
                aspectRatio(contentAspectRatio, contentMode: .fit)
                    .frame(maxHeight: min(maxMediaHeight, max(minMediaHeight, contentHeight ?? .infinity)))
                    // Required to prevent the reply details to get higher priority in rendering the width of the view.
                    .aspectRatio(contentAspectRatio, contentMode: .fit)
            } else { // Otherwise force the image to be `defaultMediaSize` x `defaultMediaSize`
                frame(width: defaultMediaSize, height: defaultMediaSize)
            }
        }
    }
}
