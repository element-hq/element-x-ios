//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CallKit

// sourcery: AutoMockable
protocol CXCallControllerProtocol {
    func request(_ transaction: CXTransaction, completion: @escaping @Sendable (Error?) -> Void)
}

extension CXCallController: CXCallControllerProtocol { }
