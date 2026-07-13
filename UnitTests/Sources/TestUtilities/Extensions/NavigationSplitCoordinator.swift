//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation

// Sendable projections of the split coordinator's non-Sendable coordinator references,
// allowing the tests to `observe` them and wait for navigation with `deferFulfillment`.
extension NavigationSplitCoordinator {
    var detailCoordinatorID: ObjectIdentifier? {
        detailCoordinator.map { ObjectIdentifier($0) }
    }
    
    /// The root coordinator inside the detail navigation stack.
    var detailRootCoordinator: (any CoordinatorProtocol)? {
        (detailCoordinator as? NavigationStackCoordinator)?.rootCoordinator
    }
    
    /// The identity of the root coordinator inside the detail navigation stack.
    var detailRootCoordinatorID: ObjectIdentifier? {
        detailRootCoordinator.map { ObjectIdentifier($0) }
    }
    
    var sheetCoordinatorID: ObjectIdentifier? {
        sheetCoordinator.map { ObjectIdentifier($0) }
    }
}
