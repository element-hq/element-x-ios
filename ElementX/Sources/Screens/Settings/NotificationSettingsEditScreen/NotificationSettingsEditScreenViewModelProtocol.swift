//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

@MainActor
protocol NotificationSettingsEditScreenViewModelProtocol {
    var actions: AnyPublisher<NotificationSettingsEditScreenViewModelAction, Never> { get }
    var context: NotificationSettingsEditScreenViewModelType.Context { get }
    
    func fetchInitialContent()
}
