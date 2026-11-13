//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ImageIO
import LinkPresentation

class LinkMetadataProvider: LinkMetadataProviderProtocol {
    /// The session to fetch homeserver previews with, `nil` in previews and UI tests which only fetch on device.
    private let userSession: UserSessionProtocol?
    private(set) var metadataItems = [URL: LinkMetadataProviderItem]()
    
    init(userSession: UserSessionProtocol? = nil) {
        self.userSession = userSession
    }
    
    func fetchMetadataFor(url: URL) async -> Result<LinkMetadataProviderItem, Error> {
        if let item = metadataItems[url] {
            return .success(item)
        }
        
        do {
            let metadata = if let userSession, userSession.userSettings.app.linkPreviewsMode == .homeserver {
                try await homeserverMetadata(for: url, userSession: userSession)
            } else {
                try await LPMetadataProvider().startFetchingMetadata(for: url)
            }
            let item = LinkMetadataProviderItem(metadata: metadata)
            metadataItems[url] = item
            return .success(item)
        } catch {
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
            return await preloaded(metadata, imageSize: data.count)
        }
        
        return metadata
    }
    
    /// Loads the image in a hidden link view and returns the resulting metadata, which link views render synchronously.
    ///
    /// LinkPresentation drops an image load whenever any other link view is given metadata in the meantime,
    /// leaving that preview spinning forever. Metadata with an already loaded image never takes that path.
    private func preloaded(_ metadata: LPLinkMetadata, imageSize: Int) async -> LPLinkMetadata {
        let loader = LPLinkView(metadata: metadata)
        
        // Polls for up to 2 seconds, falling back to the unloaded metadata for huge or undecodable images.
        for attempt in 1...20 {
            try? await Task.sleep(for: .milliseconds(100))
            
            // Loaded metadata archives the image itself, unloaded metadata only references its provider.
            let loadedMetadata = loader.metadata
            if let archive = try? NSKeyedArchiver.archivedData(withRootObject: loadedMetadata, requiringSecureCoding: true),
               archive.count >= imageSize {
                return loadedMetadata
            }
            
            // The loader can lose the same race, so restart its load every now and then.
            if attempt.isMultiple(of: 5) {
                loader.metadata = metadata
            }
        }
        
        MXLog.error("Failed preloading the link preview image")
        return metadata
    }
}
