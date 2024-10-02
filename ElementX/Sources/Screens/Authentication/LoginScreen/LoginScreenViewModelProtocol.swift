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
    
    /// Update the view to reflect that a new homeserver is being loaded.
    /// - Parameter isLoading: Whether or not the homeserver is being loaded.
    func update(isLoading: Bool)
    
    /// Update the view with new homeserver information.
    /// - Parameter homeserver: The view data for the homeserver. This can be generated using `AuthenticationService.Homeserver.viewData`.
    func update(homeserver: LoginHomeserver)
    
    /// Display an error to the user.
    /// - Parameter type: The type of error to be displayed.
    func displayError(_ type: LoginScreenErrorType)
}
