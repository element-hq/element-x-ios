//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum StickerPackServiceError: Error {
    case invalidURL
    case downloadFailed
    case decodingFailed
    case storageError
}

protocol StickerPackServiceProtocol {
    /// Get all currently available sticker packs
    var availablePacks: [StickerPack] { get }

    /// Load sticker packs from storage
    func loadStickerPacks() async throws -> [StickerPack]

    /// Add a sticker pack from a URL
    func addStickerPack(from url: URL) async throws -> StickerPack

    /// Add a sticker pack from JSON data
    func addStickerPack(from data: Data) throws -> StickerPack

    /// Remove a sticker pack by ID
    func removeStickerPack(id: String) throws

    /// Resolve MXC URL to HTTPS URL for media display
    func resolveMediaURL(mxcURL: String, homeserverURL: URL) -> URL?
}
