//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol DeactivateAccountScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<DeactivateAccountScreenViewModelAction, Never> { get }
    var context: DeactivateAccountScreenViewModelType.Context { get }
}
