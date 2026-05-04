//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

struct Dependencies: DependenciesProtocol {
    let userIndicatorController: any UserIndicatorControllerProtocol
    let settings: AppSettings
    let analytics: AnalyticsService
}

extension Dependencies {
    /// Mocks for use in previews.
    @MainActor
    static let previewMocks: Dependencies = {
        let appSettings = AppSettings()
        return Dependencies(userIndicatorController: UserIndicatorControllerMock.default,
                            settings: appSettings,
                            analytics: AnalyticsService(client: AnalyticsClientMock(), appSettings: appSettings))
    }()
}
