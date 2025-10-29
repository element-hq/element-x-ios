//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

@MainActor
protocol CreateRoomViewModelProtocol {
    var actions: AnyPublisher<CreateRoomViewModelAction, Never> { get }
    var context: CreateRoomViewModelType.Context { get }
    
    func updateAvatar(fileURL: URL)
}
