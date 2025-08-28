//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol BookmarksScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<BookmarksScreenViewModelAction, Never> { get }
    var context: BookmarksScreenViewModelType.Context { get }
}
