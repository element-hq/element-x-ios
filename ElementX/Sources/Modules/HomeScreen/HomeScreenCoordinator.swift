//
// Copyright 2021 New Vector Ltd
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

struct HomeScreenCoordinatorParameters {
    let userSession: UserSession
}

final class HomeScreenCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: HomeScreenCoordinatorParameters
    private let homeScreenHostingController: UIViewController
    private var homeScreenViewModel: HomeScreenViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((HomeScreenViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: HomeScreenCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = HomeScreenViewModel(username: self.parameters.userSession.displayName ?? "💥")
        let view = HomeScreen(context: viewModel.context)
        homeScreenViewModel = viewModel
        homeScreenHostingController = UIHostingController(rootView: view)
        
        homeScreenViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            self.completion?(result)
        }
    }
    
    // MARK: - Public
    func start() {
        
    }
    
    func toPresentable() -> UIViewController {
        return self.homeScreenHostingController
    }
}
