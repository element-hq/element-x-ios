//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct RoomImagePacksScreenViewModelTests {
    @Test("Selecting a pack asks for it to be presented")
    func selectPack() async throws {
        let pack = ImagePack(id: "pack", displayName: "Pack", isEmoticonPack: true, isStickerPack: false, images: [.mock(shortcode: "wave")])
        let viewModel = RoomImagePacksScreenViewModel(packs: [pack], mediaProvider: MediaProviderMock(.init()))
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            guard case .selectPack(let selectedPack) = action else { return false }
            return selectedPack == pack
        }
        viewModel.context.send(viewAction: .selectPack(pack))
        try await deferred.fulfill()
    }
}
