//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

// periphery:ignore:all - this is just a knockRequestsList remove this comment once generating the final file

import Combine
import SwiftUI

struct KnockRequestsListScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum KnockRequestsListScreenCoordinatorAction { }

final class KnockRequestsListScreenCoordinator: CoordinatorProtocol {
    private let viewModel: KnockRequestsListScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<KnockRequestsListScreenCoordinatorAction, Never> = .init()
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
