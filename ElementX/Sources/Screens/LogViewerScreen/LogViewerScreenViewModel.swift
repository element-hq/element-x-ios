//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias LogViewerScreenViewModelType = StateStoreViewModel<LogViewerScreenViewState, LogViewerScreenViewAction>

class LogViewerScreenViewModel: LogViewerScreenViewModelType, LogViewerScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<LogViewerScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<LogViewerScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init() {
        super.init(initialViewState: LogViewerScreenViewState(urls: RustTracing.logFiles))
    }
    
    // MARK: - Public
    
    override func process(viewAction: LogViewerScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .done:
            actionsSubject.send(.done)
        }
    }
}
