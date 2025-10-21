//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol StartChatScreenViewModelProtocol {
    var actions: AnyPublisher<StartChatScreenViewModelAction, Never> { get }
    var context: StartChatScreenViewModelType.Context { get }
}
