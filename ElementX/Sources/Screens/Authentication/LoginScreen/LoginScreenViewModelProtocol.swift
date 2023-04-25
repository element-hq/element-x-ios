//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

@MainActor
protocol LoginScreenViewModelProtocol {
    var callback: (@MainActor (LoginScreenViewModelAction) -> Void)? { get set }
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
