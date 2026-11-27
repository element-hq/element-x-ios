//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomImagePacksScreenViewModelType = StateStoreViewModelV2<RoomImagePacksScreenViewState, RoomImagePacksScreenViewAction>

class RoomImagePacksScreenViewModel: RoomImagePacksScreenViewModelType, RoomImagePacksScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<RoomImagePacksScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomImagePacksScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(packs: [ImagePack], mediaProvider: MediaProviderProtocol) {
        super.init(initialViewState: .init(packs: packs), mediaProvider: mediaProvider)
    }
    
    override func process(viewAction: RoomImagePacksScreenViewAction) {
        switch viewAction {
        case .selectPack(let pack):
            actionsSubject.send(.selectPack(pack))
        }
    }
}
