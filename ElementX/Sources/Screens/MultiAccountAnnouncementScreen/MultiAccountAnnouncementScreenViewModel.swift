//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias MultiAccountAnnouncementScreenViewModelType = StateStoreViewModelV2<MultiAccountAnnouncementScreenViewState, MultiAccountAnnouncementScreenViewAction>

class MultiAccountAnnouncementScreenViewModel: MultiAccountAnnouncementScreenViewModelType, MultiAccountAnnouncementScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<MultiAccountAnnouncementScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MultiAccountAnnouncementScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init() {
        super.init(initialViewState: .init())
    }
    
    // MARK: - Public
    
    override func process(viewAction: MultiAccountAnnouncementScreenViewAction) {
        switch viewAction {
        case .addAccount:
            actionsSubject.send(.addAccount)
        case .close:
            actionsSubject.send(.dismiss)
        }
    }
}
