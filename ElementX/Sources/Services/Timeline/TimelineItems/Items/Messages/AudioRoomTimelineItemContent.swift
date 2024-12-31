//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import UniformTypeIdentifiers

struct AudioRoomTimelineItemContent: Hashable {
    let filename: String
    var caption: String?
    var formattedCaption: AttributedString?
    /// The original textual representation of the formatted caption directly from the event (usually HTML code)
    var formattedCaptionHTMLString: String?
    let duration: TimeInterval
    let waveform: EstimatedWaveform?
    let source: MediaSourceProxy?
    let fileSize: UInt?
    let contentType: UTType?
}
