//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import LinkPresentation

class LinkMetadataProvider: LinkMetadataProviderProtocol {
    private(set) var metadataItems = [URL: LinkMetadataProviderItem]()
    
    func fetchMetadataFor(url: URL) async -> Result<LinkMetadataProviderItem, Error> {
        if let item = metadataItems[url] {
            return .success(item)
        }
        
        do {
            let metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)
            let item = LinkMetadataProviderItem(url: url, metadata: metadata)
            metadataItems[url] = item
            return .success(item)
        } catch {
            return .failure(error)
        }
    }
}
