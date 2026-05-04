//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

protocol DependenciesProtocol {
    var userIndicatorController: UserIndicatorControllerProtocol { get }
    var settings: AppSettings { get }
    var analytics: AnalyticsService { get }
}
