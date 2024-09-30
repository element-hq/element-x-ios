//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension MapTilerStyleBuilder {
    init(appSettings: AppSettings) {
        self.init(baseURL: appSettings.mapTilerBaseURL, key: appSettings.mapTilerApiKey)
    }
}
