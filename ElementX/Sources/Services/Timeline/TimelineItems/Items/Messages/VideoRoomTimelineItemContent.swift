//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UniformTypeIdentifiers

struct VideoRoomTimelineItemContent: Hashable {
    let body: String
    let duration: TimeInterval
    let source: MediaSourceProxy?
    let thumbnailSource: MediaSourceProxy?
    var width: CGFloat?
    var height: CGFloat?
    var aspectRatio: CGFloat?
    var blurhash: String?
    var contentType: UTType?
}
