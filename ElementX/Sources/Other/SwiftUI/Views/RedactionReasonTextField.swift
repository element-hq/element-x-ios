//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The optional reason sent alongside a redaction. Shared by the message and the media removal
/// confirmations so that both offer the same field.
struct RedactionReasonTextField: View {
    @Binding var reason: String
    
    var body: some View {
        TextField(L10n.screenRoomConfirmRemovalReasonPlaceholder, text: $reason)
            .textFieldStyle(.compound(labelText: L10n.screenRoomConfirmRemovalReasonLabel))
    }
}
