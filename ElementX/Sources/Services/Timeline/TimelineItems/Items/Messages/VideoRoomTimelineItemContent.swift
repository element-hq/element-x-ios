//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UniformTypeIdentifiers

struct VideoRoomTimelineItemContent: Hashable {
    let filename: String
    var caption: String?
    var formattedCaption: AttributedString?
    /// The original textual representation of the formatted caption directly from the event (usually HTML code)
    var formattedCaptionHTMLString: String?
    let duration: TimeInterval
    
    let source: MediaSourceProxy?
    var size: CGSize?
    var aspectRatio: CGFloat?
    
    let thumbnailSource: MediaSourceProxy?
    var thumbnailSize: CGSize?
    var thumbnailAspectRatio: CGFloat?
    
    var blurhash: String?
    var contentType: UTType?
}
