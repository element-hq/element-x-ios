//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

extension AnalyticsService {
    static func mock(_ clientOverride: AnalyticsClientProtocol? = nil, settings: AppSettings? = nil) -> AnalyticsService {
        let client: AnalyticsClientProtocol
        if let clientOverride {
            client = clientOverride
        } else {
            let mockClient = AnalyticsClientMock()
            mockClient.isRunning = false
            client = mockClient
        }
        
        return .init(client: client, appSettings: settings ?? AppSettings())
    }
}
