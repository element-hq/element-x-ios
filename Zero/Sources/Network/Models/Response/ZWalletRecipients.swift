//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZWalletRecipients: Codable {
    let recipients: [WalletRecipient]
}

struct WalletRecipient: Codable, Identifiable {
    let userId: String
    let matrixId: String
    let publicAddress: String
    let name: String?
    let profileImage: String?
    let primaryZid: String?

    var id: String { userId } // For Identifiable conformance
    
    static func placeholder(_ index: Int) -> Self {
        .init(
            userId: "placeholder_id_\(index)",
            matrixId: "@placeholder_id:example.com",
            publicAddress: "0x00000aaaaa",
            name: "placeholder_name",
            profileImage: URL.dummayURL.absoluteString,
            primaryZid: "0://placeholder_id"
        )
    }
}

extension WalletRecipient {
    var displayName: String {
        return "\(String(describing: name ?? ""))(\(String(describing: primaryZid ?? ""))".trim()
    }
}
