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
    enum Kind {
        case roomCall(roomProxy: JoinedRoomProxyProtocol,
                      clientProxy: ClientProxyProtocol,
                      clientID: String,
                      voiceOnly: Bool,
                      elementCallBaseURL: URL,
                      elementCallBaseURLOverride: URL?,
                      colorScheme: ColorScheme)
    }
    
    /// The type of call being configured i.e. whether it's an external URL or an internal room call.
    let kind: Kind
    
    /// Creates a configuration for an internal room call.
    init(roomProxy: JoinedRoomProxyProtocol,
         clientProxy: ClientProxyProtocol,
         clientID: String,
         elementCallBaseURL: URL,
         elementCallBaseURLOverride: URL?,
         voiceOnly: Bool,
         colorScheme: ColorScheme) {
        kind = .roomCall(roomProxy: roomProxy,
                         clientProxy: clientProxy,
                         clientID: clientID,
                         voiceOnly: voiceOnly,
                         elementCallBaseURL: elementCallBaseURL,
                         elementCallBaseURLOverride: elementCallBaseURLOverride,
                         colorScheme: colorScheme)
    }
    
    /// A string representing the call being configured.
    var callRoomID: String {
        switch kind {
        case .roomCall(let roomProxy, _, _, _, _, _, _):
            roomProxy.id
        }
    }
}
