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

import SwiftUI

struct RoomDetailsCoordinatorParameters {
    let navigationController: NavigationController
    let roomProxy: RoomProxyProtocol
}

enum RoomDetailsCoordinatorAction {
    case cancel
}

final class RoomDetailsCoordinator: CoordinatorProtocol {
    private let parameters: RoomDetailsCoordinatorParameters
    private var viewModel: RoomDetailsViewModelProtocol
    
    var callback: ((RoomDetailsCoordinatorAction) -> Void)?
    
    init(parameters: RoomDetailsCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomDetailsViewModel(roomProxy: parameters.roomProxy)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            MXLog.debug("RoomDetailsViewModel did complete with result: \(action).")
            switch action {
            case .cancel:
                self.callback?(.cancel)
            }
        }
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomDetailsScreen(context: viewModel.context))
    }
}
