//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

class ImagePackProvider: ImagePackProviderProtocol {
    private let room: Room
    private let spaceService: SpaceService
    
    init(room: Room, spaceService: SpaceService) {
        self.room = room
        self.spaceService = spaceService
    }
    
    func imagePacks() async -> Result<[ImagePack], ImagePackProviderError> {
        do {
            return try await .success(room.imagePacks(spaceService: spaceService).map(ImagePack.init))
        } catch {
            MXLog.error("Failed loading image packs with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func roomImagePacks() async -> Result<[ImagePack], ImagePackProviderError> {
        do {
            let roomID = room.id()
            return try await .success(room.imagePacks(spaceService: spaceService).filter { $0.roomId == roomID }.map(ImagePack.init))
        } catch {
            MXLog.error("Failed loading the room's image packs with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
