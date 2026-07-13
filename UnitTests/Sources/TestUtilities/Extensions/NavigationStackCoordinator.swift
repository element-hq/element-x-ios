//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation

// Sendable projections of the stack coordinator's non-Sendable coordinator references,
// allowing the tests to `observe` them and wait for navigation with `deferFulfillment`.
extension NavigationStackCoordinator {
    var rootCoordinatorID: ObjectIdentifier? {
        rootCoordinator.map { ObjectIdentifier($0) }
    }
    
    /// The identity of the topmost coordinator on the stack.
    var topCoordinatorID: ObjectIdentifier? {
        stackCoordinators.last.map { ObjectIdentifier($0) }
    }
    
    var sheetCoordinatorID: ObjectIdentifier? {
        sheetCoordinator.map { ObjectIdentifier($0) }
    }
}
