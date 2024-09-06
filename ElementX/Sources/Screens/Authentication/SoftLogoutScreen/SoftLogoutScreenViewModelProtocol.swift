//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

protocol SoftLogoutScreenViewModelProtocol {
    var actions: AnyPublisher<SoftLogoutScreenViewModelAction, Never> { get }
    var context: SoftLogoutScreenViewModelType.Context { get }
    
    /// Display an error to the user.
    @MainActor func displayError(_ type: SoftLogoutScreenErrorType)
}
