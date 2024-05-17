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

struct CallScreenCoordinatorParameters {
    let elementCallService: ElementCallServiceProtocol
    let roomProxy: RoomProxyProtocol
    let callBaseURL: URL
    let clientID: String
}

enum CallScreenCoordinatorAction {
    case dismiss
}

final class CallScreenCoordinator: CoordinatorProtocol {
    private var viewModel: CallScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<CallScreenCoordinatorAction, Never> = .init()
    
    private var cancellables: Set<AnyCancellable> = .init()
    var actions: AnyPublisher<CallScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: CallScreenCoordinatorParameters) {
        viewModel = CallScreenViewModel(elementCallService: parameters.elementCallService,
                                        roomProxy: parameters.roomProxy,
                                        callBaseURL: parameters.callBaseURL,
                                        clientID: parameters.clientID)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(CallScreen(context: viewModel.context))
    }
}
