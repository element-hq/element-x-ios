//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct KnockRequestsListScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

// periphery:ignore - required for the architecture
enum KnockRequestsListScreenCoordinatorAction { }

final class KnockRequestsListScreenCoordinator: CoordinatorProtocol {
    private let viewModel: KnockRequestsListScreenViewModelProtocol
    
    // periphery:ignore - required for the architecture
    private var cancellables = Set<AnyCancellable>()
    
    // periphery:ignore - required for the architecture
    private let actionsSubject: PassthroughSubject<KnockRequestsListScreenCoordinatorAction, Never> = .init()
    // periphery:ignore - required for the architecture
    var actionsPublisher: AnyPublisher<KnockRequestsListScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: KnockRequestsListScreenCoordinatorParameters) {
        viewModel = KnockRequestsListScreenViewModel(roomProxy: parameters.roomProxy,
                                                     mediaProvider: parameters.mediaProvider,
                                                     userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() { }
    
    func toPresentable() -> AnyView {
        AnyView(KnockRequestsListScreen(context: viewModel.context))
    }
}
