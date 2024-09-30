//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

extension UIDevice {
    /// Returns if the device is a Phone
    var isPhone: Bool {
        userInterfaceIdiom == .phone
    }

    var initialDeviceName: String {
        L10n.loginInitialDeviceNameIos(InfoPlistReader.main.bundleDisplayName)
    }
}
