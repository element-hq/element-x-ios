//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias BookmarksScreenViewModelType = StateStoreViewModelV2<BookmarksScreenViewState, BookmarksScreenViewAction>

class BookmarksScreenViewModel: BookmarksScreenViewModelType, BookmarksScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    
    private let actionsSubject: PassthroughSubject<BookmarksScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<BookmarksScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(clientProxy: ClientProxyProtocol) {
        self.clientProxy = clientProxy
        
        super.init(initialViewState: .init())
    }
    
    // MARK: - Public
    
    override func process(viewAction: BookmarksScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }
}
