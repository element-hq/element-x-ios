//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomImagePacksScreenCoordinatorParameters {
    let packs: [ImagePack]
    let mediaProvider: MediaProviderProtocol
}

enum RoomImagePacksScreenCoordinatorAction {
    case selectPack(ImagePack)
}

final class RoomImagePacksScreenCoordinator: CoordinatorProtocol {
    private let viewModel: RoomImagePacksScreenViewModelProtocol
    
    var actionsPublisher: AnyPublisher<RoomImagePacksScreenCoordinatorAction, Never> {
        viewModel.actionsPublisher
            .map { action in
                switch action {
                case .selectPack(let pack): .selectPack(pack)
                }
            }
            .eraseToAnyPublisher()
    }
    
    init(parameters: RoomImagePacksScreenCoordinatorParameters) {
        viewModel = RoomImagePacksScreenViewModel(packs: parameters.packs, mediaProvider: parameters.mediaProvider)
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomImagePacksScreen(context: viewModel.context))
    }
}
