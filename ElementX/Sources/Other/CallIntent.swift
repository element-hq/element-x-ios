//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

nonisolated enum CallIntent: String, Codable, CaseIterable {
    case video, audio
}

nonisolated extension CallIntent {
    init(rustCallIntent: MatrixRustSDK.RtcCallIntent) {
        switch rustCallIntent {
        case .audio: self = .audio
        case .video: self = .video
        }
    }
    
    // periphery:ignore - might be useful to have
    var rustCallIntent: MatrixRustSDK.RtcCallIntent {
        switch self {
        case .audio: .audio
        case .video: .video
        }
    }
}
