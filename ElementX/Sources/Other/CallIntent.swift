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
    // periphery:ignore - Unused, but added to detect new cases when updating the SDK.
    init(rustCallIntent: MatrixRustSDK.RtcCallIntent) {
        switch rustCallIntent {
        case .audio: self = .audio
        case .video: self = .video
        }
    }
    
    var rustCallIntent: MatrixRustSDK.RtcCallIntent {
        switch self {
        case .audio: .audio
        case .video: .video
        }
    }
}
