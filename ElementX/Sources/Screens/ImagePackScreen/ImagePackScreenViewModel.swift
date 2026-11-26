//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias ImagePackScreenViewModelType = StateStoreViewModelV2<ImagePackScreenViewState, Never>

class ImagePackScreenViewModel: ImagePackScreenViewModelType, ImagePackScreenViewModelProtocol {
    init(pack: ImagePack, mediaProvider: MediaProviderProtocol) {
        super.init(initialViewState: .init(pack: pack), mediaProvider: mediaProvider)
    }
}
