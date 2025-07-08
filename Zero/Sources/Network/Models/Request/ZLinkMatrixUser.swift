//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

public struct ZLinkMatrixUser: Encodable {
    let matrixId: String
    let matrixAccessToken: String
    
    init(matrixUserId: String) {
        self.matrixId = matrixUserId
        self.matrixAccessToken = "not-used"
    }
}
