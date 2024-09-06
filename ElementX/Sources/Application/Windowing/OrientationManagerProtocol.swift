//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

// sourcery: AutoMockable
protocol OrientationManagerProtocol {
    /// Forces the current orientation for the main window, works only on iOS
    func setOrientation(_ orientation: UIInterfaceOrientationMask)
    
    /// Locks the current orientation for the main window, works only on iOS
    func lockOrientation(_ orientation: UIInterfaceOrientationMask)
}
