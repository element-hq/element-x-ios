//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
import Foundation

// sourcery: AutoMockable
protocol LiveLocationManagerProtocol: AnyObject {
    /// Publishes the current "Always" location authorization status.
    var authorizationStatus: CurrentValuePublisher<CLAuthorizationStatus, Never> { get }

    /// Requests "Always" location authorization from the user if the system allows it.
    ///
    /// - Returns: `true` if the request was forwarded to the system and a prompt will be shown;
    ///            `false` if the request was already made before and iOS would silently ignore it.
    @discardableResult
    func requestAlwaysAuthorizationIfPossible() -> Bool
}
