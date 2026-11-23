//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol RemoteLogoutScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<RemoteLogoutScreenViewModelAction, Never> { get }
    var context: RemoteLogoutScreenViewModelType.Context { get }
}
