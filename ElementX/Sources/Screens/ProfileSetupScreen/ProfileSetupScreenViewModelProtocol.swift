//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Combine

@MainActor
protocol ProfileSetupScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<ProfileSetupScreenViewModelAction, Never> { get }
    var context: ProfileSetupScreenViewModelType.Context { get }
}
