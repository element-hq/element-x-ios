//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias MultiAccountAnnouncementViewModelType = StateStoreViewModelV2<MultiAccountAnnouncementViewState, MultiAccountAnnouncementViewAction>

class MultiAccountAnnouncementViewModel: MultiAccountAnnouncementViewModelType, Identifiable {
    private let actionsSubject: PassthroughSubject<MultiAccountAnnouncementViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MultiAccountAnnouncementViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    let id = UUID()
    
    init() {
        super.init(initialViewState: .init())
    }
    
    // MARK: - Public
    
    override func process(viewAction: MultiAccountAnnouncementViewAction) {
        switch viewAction {
        case .addAccount:
            actionsSubject.send(.addAccount)
        case .close:
            actionsSubject.send(.dismiss)
        }
    }
}
