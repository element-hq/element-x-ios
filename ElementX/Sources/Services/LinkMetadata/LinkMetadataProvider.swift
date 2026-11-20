//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ImageIO
import LinkPresentation

enum LinkMetadataProviderError: Error {
    case previouslyFailed
}

class LinkMetadataProvider: LinkMetadataProviderProtocol {
    private let userSession: UserSessionProtocol
    private(set) var metadataItems = [URL: LinkMetadataProviderItem]()
    private(set) var failedURLs = Set<URL>()
    
    init(userSession: UserSessionProtocol) {
        self.userSession = userSession
    }
    
    func fetchMetadataFor(url: URL, mode: LinkPreviewMode) async -> Result<LinkMetadataProviderItem, Error> {
        if let item = metadataItems[url] {
            return .success(item)
        }
        
        if failedURLs.contains(url) {
            return .failure(LinkMetadataProviderError.previouslyFailed)
        }
        
        do {
            let metadata = if mode == .homeserver {
                try await homeserverMetadata(for: url, userSession: userSession)
            } else {
                try await LPMetadataProvider().startFetchingMetadata(for: url)
            }
            // A cancelled fetch can still return, for example without the image it was downloading.
            try Task.checkCancellation()
            let item = LinkMetadataProviderItem(metadata: metadata)
            metadataItems[url] = item
            return .success(item)
        } catch {
            // Cancelled fetches are retried when the message is shown again.
            if !Task.isCancelled {
                failedURLs.insert(url)
            }
            return .failure(error)
        }
    }
    
    // MARK: - Private
    
    private func homeserverMetadata(for url: URL, userSession: UserSessionProtocol) async throws -> LPLinkMetadata {
        let preview = try await userSession.clientProxy.urlPreview(for: url).get()
        
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        metadata.title = preview.title
        
        if let imageURL = preview.imageURL,
           let source = try? MediaSourceProxy(url: imageURL, mimeType: nil),
           case let .success(data) = await userSession.mediaProvider.loadImageDataFromSource(source),
           let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
           let typeIdentifier = CGImageSourceGetType(imageSource) as String? {
            // LinkPresentation silently drops images registered under a generic type such as public.image.
            metadata.imageProvider = NSItemProvider(item: data as NSData, typeIdentifier: typeIdentifier)
            return try await preloaded(metadata)
        }
        
        return metadata
    }
    
    /// Loads the image in a hidden link view and returns the resulting metadata, which link views render synchronously.
    ///
    /// LinkPresentation drops an image load whenever any other link view is given metadata in the meantime,
    /// leaving that preview spinning forever. Metadata with an already loaded image never takes that path.
    private func preloaded(_ metadata: LPLinkMetadata) async throws -> LPLinkMetadata {
        // Unloaded metadata only references its image provider, loaded metadata archives the image itself.
        let unloadedSize = metadata.archiveSize
        let loader = LPLinkView(metadata: metadata)
        
        // Polls for up to 2 seconds, falling back to no image for huge or undecodable ones.
        for attempt in 1...20 {
            try await Task.sleep(for: .milliseconds(100))
            
            let loadedMetadata = loader.metadata
            if loadedMetadata.archiveSize > unloadedSize {
                return loadedMetadata
            }
            
            // The loader can lose the same race, so restart its load every now and then.
            if attempt.isMultiple(of: 5) {
                loader.metadata = metadata
            }
        }
        
        // Unloaded metadata would take the racy path and spin forever, a preview without an image always renders.
        MXLog.error("Failed preloading the link preview image")
        metadata.imageProvider = nil
        return metadata
    }
}

private extension LPLinkMetadata {
    var archiveSize: Int {
        (try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true).count) ?? 0
    }
}
