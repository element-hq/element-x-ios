//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol WebRegistrationScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<WebRegistrationScreenViewModelAction, Never> { get }
    var context: WebRegistrationScreenViewModelType.Context { get }
}
