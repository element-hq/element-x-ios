//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol AnalyticsPromptScreenViewModelProtocol {
    var actions: AnyPublisher<AnalyticsPromptScreenViewModelAction, Never> { get }
    var context: AnalyticsPromptScreenViewModelType.Context { get }
}
