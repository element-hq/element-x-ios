//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CallKit

/// Mirrors `CXProviderProtocol`: a seam for tests, where there's no CallKit daemon to answer a
/// transaction and the real controller only fails after a long timeout.
///
/// Only the completion form, even though callers want to await: `CXTransaction` isn't `Sendable`,
/// so an `async` requirement can't be served by a generated mock. `ElementCallService` bridges it.
// sourcery: AutoMockable
protocol CXCallControllerProtocol {
    func request(_ transaction: CXTransaction, completion: @escaping @Sendable (Error?) -> Void)
}

extension CXCallController: CXCallControllerProtocol { }
