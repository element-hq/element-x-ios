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

struct RoomDetailsEditScreenCoordinatorParameters {
    let accountOwner: RoomMemberProxyProtocol
    let roomProxy: RoomProxyProtocol
}

enum RoomDetailsEditScreenCoordinatorAction {
    case cancel
}

final class RoomDetailsEditScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomDetailsEditScreenCoordinatorParameters
    private var viewModel: RoomDetailsEditScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<RoomDetailsEditScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<RoomDetailsEditScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomDetailsEditScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomDetailsEditScreenViewModel(accountOwner: parameters.accountOwner, roomProxy: parameters.roomProxy)
    }
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                switch action {
                case .cancel:
                    self?.actionsSubject.send(.cancel)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomDetailsEditScreen(context: viewModel.context))
    }
}
