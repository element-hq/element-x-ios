//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

struct ResolveVerifiedUserSendFailureScreenCoordinatorParameters {
    let failure: TimelineItemSendFailure.VerifiedUser
    let itemID: TimelineItemIdentifier
    let roomProxy: JoinedRoomProxyProtocol
}

enum ResolveVerifiedUserSendFailureScreenCoordinatorAction {
    case dismiss
}

final class ResolveVerifiedUserSendFailureScreenCoordinator: CoordinatorProtocol {
    private let parameters: ResolveVerifiedUserSendFailureScreenCoordinatorParameters
    private let viewModel: ResolveVerifiedUserSendFailureScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<ResolveVerifiedUserSendFailureScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ResolveVerifiedUserSendFailureScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ResolveVerifiedUserSendFailureScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ResolveVerifiedUserSendFailureScreenViewModel(failure: parameters.failure,
                                                                  itemID: parameters.itemID,
                                                                  roomProxy: parameters.roomProxy)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(ResolveVerifiedUserSendFailureScreen(context: viewModel.context))
    }
}
