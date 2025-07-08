//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import StoreKitPlus

enum ZeroSubscriptions: String, CaseIterable, ProductRepresentable {
    case zeroProMonthly = "com.zero.ios.messenger.subscription.zero.pro.monthly"

    var id: String { rawValue }
}
