//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol VoiceMessageMediaManagerProtocol {
    func loadVoiceMessageFromSource(_ source: MediaSourceProxy, body: String?) async throws -> URL
}

// sourcery: AutoMockable
extension VoiceMessageMediaManagerProtocol { }
