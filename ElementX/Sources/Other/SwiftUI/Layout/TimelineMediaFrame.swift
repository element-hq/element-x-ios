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

extension View {
    /// Constrains the max height of a media item in the timeline, whilst preserving its aspect ratio.
    @ViewBuilder
    func timelineMediaFrame(height contentHeight: CGFloat?, aspectRatio contentAspectRatio: CGFloat?) -> some View {
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
            } else { // Otherwise let the image load and use its native aspect ratio with a max height
                frame(maxHeight: maxMediaHeight)
            }
        }
    }
}
