//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit
import UniformTypeIdentifiers

struct AudioRoomTimelineItemContent: Hashable {
    let body: String
    let duration: TimeInterval
    let waveform: EstimatedWaveform?
    let source: MediaSourceProxy?
    let contentType: UTType?
}
