//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

@MainActor
protocol LoginScreenViewModelProtocol {
    var actions: AnyPublisher<LoginScreenViewModelAction, Never> { get }
    var context: LoginScreenViewModelType.Context { get }
    
    /// Update the view to reflect that loaded has finished.
    func stopLoading()
}
