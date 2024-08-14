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

struct BlockedUsersScreenCoordinatorParameters {
    let hideProfiles: Bool
    let clientProxy: ClientProxyProtocol
    let imageProvider: ImageProviderProtocol
    let networkMonitor: NetworkMonitorProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

final class BlockedUsersScreenCoordinator: CoordinatorProtocol {
    private let viewModel: BlockedUsersScreenViewModelProtocol
    
    init(parameters: BlockedUsersScreenCoordinatorParameters) {
        viewModel = BlockedUsersScreenViewModel(hideProfiles: parameters.hideProfiles,
                                                clientProxy: parameters.clientProxy,
                                                imageProvider: parameters.imageProvider,
                                                networkMonitor: parameters.networkMonitor,
                                                userIndicatorController: parameters.userIndicatorController)
    }
    
    func stop() {
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        AnyView(BlockedUsersScreen(context: viewModel.context))
    }
}
