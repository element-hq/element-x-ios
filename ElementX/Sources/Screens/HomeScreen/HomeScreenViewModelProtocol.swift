//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

@MainActor
protocol HomeScreenViewModelProtocol {
    var actions: AnyPublisher<HomeScreenViewModelAction, Never> { get }
    
    var context: HomeScreenViewModelType.Context { get }
    
    // periphery: ignore - used in release mode
    func presentCrashedLastRunAlert()
}
