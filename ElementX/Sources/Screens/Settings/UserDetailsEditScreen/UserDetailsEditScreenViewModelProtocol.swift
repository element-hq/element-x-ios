//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

@MainActor
protocol UserDetailsEditScreenViewModelProtocol {
    var actions: AnyPublisher<UserDetailsEditScreenViewModelAction, Never> { get }
    var context: UserDetailsEditScreenViewModelType.Context { get }
    
    func didSelectMediaURL(url: URL)
}
