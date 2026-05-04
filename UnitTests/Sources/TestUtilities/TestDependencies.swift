//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX

/// For testing only - allows being more selective in what dependencies are created and provided.
/// Saves on resources during testing to avoid creating unnecessary dependencies
struct TestDependencies: DependenciesProtocol {
    private var _analytics: AnalyticsService!
    var analytics: AnalyticsService {
        _analytics
    }

    private var _userIndicatorController: (any UserIndicatorControllerProtocol)!
    var userIndicatorController: any UserIndicatorControllerProtocol {
        _userIndicatorController
    }

    private var _settings: AppSettings!
    var settings: AppSettings {
        _settings
    }

    init(userIndicatorController: (any UserIndicatorControllerProtocol)? = nil, settings: AppSettings? = nil, analytics: AnalyticsService? = nil) {
        _analytics = analytics
        _userIndicatorController = userIndicatorController
        _settings = settings
    }

    init(userIndicatorController: UserIndicatorControllerProtocol? = nil, settings: AppSettings, analytics: AnalyticsClientProtocol) {
        self.init(userIndicatorController: userIndicatorController,
                  settings: settings,
                  analytics: AnalyticsService(client: analytics, appSettings: settings))
    }
}
