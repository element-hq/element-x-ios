//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol TemplateScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<TemplateScreenViewModelAction, Never> { get }
    var context: TemplateScreenViewModelType.Context { get }
}
