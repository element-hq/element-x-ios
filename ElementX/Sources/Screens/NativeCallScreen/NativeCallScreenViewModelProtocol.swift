//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol NativeCallScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<NativeCallScreenViewModelAction, Never> { get }
    var context: NativeCallScreenViewModel.Context { get }
}
