//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class StickerPackService: StickerPackServiceProtocol {
    private var packs: [StickerPack] = []
    private let storageKey = "com.element.stickerpacks"
    private let urlSession: URLSession

    var availablePacks: [StickerPack] {
        packs
    }

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    // MARK: - Public Methods

    func loadStickerPacks() async throws -> [StickerPack] {
        // Load from UserDefaults for now
        // In production, you might want to use a more robust storage solution
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                packs = try JSONDecoder().decode([StickerPack].self, from: data)
            } catch {
                MXLog.error("Failed to decode sticker packs: \(error)")
                throw StickerPackServiceError.decodingFailed
            }
        }

        // Load default emotes pack if no packs are available
        if packs.isEmpty {
            try await loadDefaultEmotesPack()
        }

        return packs
    }

    func addStickerPack(from url: URL) async throws -> StickerPack {
        MXLog.info("Adding sticker pack from URL: \(url)")

        do {
            let (data, _) = try await urlSession.data(from: url)
            let pack = try addStickerPack(from: data)
            try savePacks()
            return pack
        } catch let error as StickerPackServiceError {
            throw error
        } catch {
            MXLog.error("Failed to download sticker pack: \(error)")
            throw StickerPackServiceError.downloadFailed
        }
    }

    func addStickerPack(from data: Data) throws -> StickerPack {
        do {
            let pack = try JSONDecoder().decode(StickerPack.self, from: data)

            // Check if pack already exists
            if let existingIndex = packs.firstIndex(where: { $0.id == pack.id }) {
                packs[existingIndex] = pack
                MXLog.info("Updated existing sticker pack: \(pack.id)")
            } else {
                packs.append(pack)
                MXLog.info("Added new sticker pack: \(pack.id)")
            }

            return pack
        } catch {
            MXLog.error("Failed to decode sticker pack: \(error)")
            throw StickerPackServiceError.decodingFailed
        }
    }

    func removeStickerPack(id: String) throws {
        packs.removeAll { $0.id == id }
        try savePacks()
    }

    func resolveMediaURL(mxcURL: String, homeserverURL: URL) -> URL? {
        // Parse MXC URL format: mxc://server.name/mediaId
        guard mxcURL.starts(with: "mxc://") else {
            return nil
        }

        let mxcContent = String(mxcURL.dropFirst(6)) // Remove "mxc://"
        let components = mxcContent.split(separator: "/", maxSplits: 1)

        guard components.count == 2 else {
            return nil
        }

        let serverName = String(components[0])
        let mediaId = String(components[1])

        // Construct HTTPS URL: https://homeserver/_matrix/media/v3/download/server.name/mediaId
        var urlString = homeserverURL.absoluteString
        if urlString.hasSuffix("/") {
            urlString.removeLast()
        }

        return URL(string: "\(urlString)/_matrix/media/v3/download/\(serverName)/\(mediaId)")
    }

    // MARK: - Private Methods

    private func savePacks() throws {
        do {
            let data = try JSONEncoder().encode(packs)
            UserDefaults.standard.set(data, forKey: storageKey)
            MXLog.info("Saved \(packs.count) sticker packs")
        } catch {
            MXLog.error("Failed to save sticker packs: \(error)")
            throw StickerPackServiceError.storageError
        }
    }

    private func loadDefaultEmotesPack() async throws {
        // Load the default emotes pack from the user's GitHub repo
        let urlString = "https://raw.githubusercontent.com/evan1ee/stickerpicker/master/emotes/pack.json"
        guard let url = URL(string: urlString) else {
            throw StickerPackServiceError.invalidURL
        }

        _ = try await addStickerPack(from: url)
        try savePacks()
    }
}
