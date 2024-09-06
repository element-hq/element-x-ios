//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

@MainActor
protocol ServerSelectionScreenViewModelProtocol {
    var actions: AnyPublisher<ServerSelectionScreenViewModelAction, Never> { get }
    var context: ServerSelectionScreenViewModelType.Context { get }
    
    /// Displays an error to the user.
    func displayError(_ type: ServerSelectionScreenErrorType)
}
