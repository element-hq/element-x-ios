//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

enum SpaceSettingsFlowCoordinatorAction { }

final class SpaceSettingsFlowCoordinator: FlowCoordinatorProtocol {
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<SpaceSettingsFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SpaceSettingsFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init() { }
    
    func start() {
        fatalError("Unavailable")
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError("Unavailable")
    }
    
    func clearRoute(animated: Bool) {
        fatalError("Unavailable")
    }
}
