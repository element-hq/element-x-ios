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

// periphery:ignore:all - this is just a roomDirectorySearchScreen remove this comment once generating the final file

import Combine
import SwiftUI

struct RoomDirectorySearchScreenCoordinatorParameters {
    let roomDirectorySearchProxy: RoomDirectorySearchProxyProtocol
    let imageProvider: ImageProviderProtocol
}

enum RoomDirectorySearchScreenCoordinatorAction {
    case dismiss
}

final class RoomDirectorySearchScreenCoordinator: CoordinatorProtocol {
    private let viewModel: RoomDirectorySearchScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<RoomDirectorySearchScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomDirectorySearchScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomDirectorySearchScreenCoordinatorParameters) {
        viewModel = RoomDirectorySearchScreenViewModel(roomDirectorySearch: parameters.roomDirectorySearchProxy, imageProvider: parameters.imageProvider)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss:
                self.actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomDirectorySearchScreen(context: viewModel.context))
    }
}
