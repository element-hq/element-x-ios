//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol ManageRoomMemberSheetViewModelProtocol {
    var actions: AnyPublisher<ManageRoomMemberSheetViewModelAction, Never> { get }
    var context: ManageRoomMemberSheetViewModelType.Context { get }
}
