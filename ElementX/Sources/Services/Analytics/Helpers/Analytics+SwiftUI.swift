//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var analyticsService: AnalyticsService = ServiceLocator.shared.analytics
}
