//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct ImagePackScreenCoordinatorParameters {
    let pack: ImagePack
    let mediaProvider: MediaProviderProtocol
}

final class ImagePackScreenCoordinator: CoordinatorProtocol {
    private let viewModel: ImagePackScreenViewModelProtocol
    
    init(parameters: ImagePackScreenCoordinatorParameters) {
        viewModel = ImagePackScreenViewModel(pack: parameters.pack, mediaProvider: parameters.mediaProvider)
    }
    
    func toPresentable() -> AnyView {
        AnyView(ImagePackScreen(context: viewModel.context))
    }
}
