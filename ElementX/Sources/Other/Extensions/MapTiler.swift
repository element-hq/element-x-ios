//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension MapTilerStyleBuilder {
    init(appSettings: AppSettings) {
        self.init(baseURL: appSettings.mapTilerBaseURL, key: appSettings.mapTilerApiKey)
    }
}
