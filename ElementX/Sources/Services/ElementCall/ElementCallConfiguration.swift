//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Information about how a call should be configured.
struct ElementCallConfiguration {
    let roomProxy: JoinedRoomProxyProtocol
    let clientProxy: ClientProxyProtocol
    let clientID: String
    let elementCallBaseURL: URL
    let elementCallBaseURLOverride: URL?
    let voiceOnly: Bool
    let colorScheme: ColorScheme
    
    /// A string representing the call being configured.
    var callRoomID: String {
        roomProxy.id
    }
}
