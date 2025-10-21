//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import LinkPresentation

struct LinkMetadataProviderItem {
    let url: URL
    let metadata: LPLinkMetadata?
}

protocol LinkMetadataProviderProtocol {
    var metadataItems: [URL: LinkMetadataProviderItem] { get }
    
    func fetchMetadataFor(url: URL) async -> Result<LinkMetadataProviderItem, Error>
}
