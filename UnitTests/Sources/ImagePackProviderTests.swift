//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

@MainActor
struct ImagePackProviderTests {
    @Test("The room's image packs are mapped, skipping images with an invalid URL")
    func imagePacks() async throws {
        // Given a room with a pack containing a valid and an invalid image.
        let room = RoomSDKMock()
        room.imagePacksSpaceServiceReturnValue = [
            MatrixRustSDK.ImagePack(roomId: "!room:example.org", stateKey: "emoticons", displayName: "Emoticons", avatarUrl: nil,
                                    isEmoticonPack: true, isStickerPack: false, isEnabledGlobally: false, attribution: nil,
                                    images: [ImagePackImage(shortcode: "wave", url: "mxc://example.org/wave", body: "Waving hand", info: nil),
                                             ImagePackImage(shortcode: "broken", url: "", body: "broken", info: nil)])
        ]
        let provider = ImagePackProvider(room: room, spaceService: SpaceServiceSDKMock())
        
        // When loading the image packs.
        let packs = try await provider.imagePacks().get()
        
        // Then the pack should only contain the valid image.
        let pack = try #require(packs.first)
        #expect(packs.count == 1)
        #expect(pack.id == "!room:example.org-emoticons")
        #expect(pack.displayName == "Emoticons")
        #expect(pack.isEmoticonPack)
        #expect(pack.images.map(\.shortcode) == ["wave"])
        #expect(pack.images.first?.body == "Waving hand")
        #expect(pack.images.first?.mediaSource.url.absoluteString == "mxc://example.org/wave")
    }
}
