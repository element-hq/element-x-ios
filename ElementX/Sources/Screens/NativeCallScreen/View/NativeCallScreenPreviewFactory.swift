//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@MainActor
enum NativeCallScreenPreviewFactory {
    static func makeViewModel(connection: NativeCallConnection) -> NativeCallScreenViewModel {
        let roomProxy = JoinedRoomProxyMock(.init(name: "Product | Lobby"))
        return NativeCallScreenViewModel(controller: .preview(connection: connection), roomProxy: roomProxy, mediaProvider: MediaProviderMock(.init()))
    }
}
