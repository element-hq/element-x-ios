//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import SwiftUI

/// Returns additional Security rows for the rooms `providesAdditionalSecurityRows` accepts.
@MainActor final class RoomDetailsScreenHookMock: RoomDetailsScreenHookProtocol {
    private let providesAdditionalSecurityRows: (JoinedRoomProxyProtocol) -> Bool
    
    init(providesAdditionalSecurityRows: @escaping (JoinedRoomProxyProtocol) -> Bool = { _ in true }) {
        self.providesAdditionalSecurityRows = providesAdditionalSecurityRows
    }
    
    func update(_ viewState: RoomDetailsScreenViewState) -> RoomDetailsScreenViewState {
        viewState
    }
    
    func additionalSecurityRows(roomProxy: JoinedRoomProxyProtocol) -> AnyView? {
        guard providesAdditionalSecurityRows(roomProxy) else { return nil }
        return AnyView(Text("Row"))
    }
}
