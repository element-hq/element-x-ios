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

struct HomeScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let attributedStringBuilder: AttributedStringBuilderProtocol
}

enum HomeScreenCoordinatorAction {
    case presentRoom(roomIdentifier: String)
    case presentSettings
    case presentBugReport
    case verifySession
    case signOut
}

final class HomeScreenCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: HomeScreenCoordinatorParameters
    private let hostingController: UIViewController
    private var viewModel: HomeScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((HomeScreenCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: HomeScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = HomeScreenViewModel(userSession: parameters.userSession,
                                        attributedStringBuilder: parameters.attributedStringBuilder)
        
        let view = HomeScreen(context: viewModel.context)
        hostingController = UIHostingController(rootView: view)
        
        viewModel.callback = { [weak self] action in
            guard let self = self else { return }
            
            switch action {
            case .selectRoom(let roomIdentifier):
                self.callback?(.presentRoom(roomIdentifier: roomIdentifier))
            case .userMenu(let action):
                self.processUserMenuAction(action)
            case .verifySession:
                self.callback?(.verifySession)
            }
        }
    }
    
    // MARK: - Public
    
    func start() { }
    
    func toPresentable() -> UIViewController {
        hostingController
    }

    func stop() { }
    
    // MARK: - Private
    
    private func processUserMenuAction(_ action: HomeScreenViewUserMenuAction) {
        switch action {
        case .settings:
            callback?(.presentSettings)
        case .inviteFriends:
            presentInviteFriends()
        case .feedback:
            callback?(.presentBugReport)
        case .signOut:
            callback?(.signOut)
        }
    }

    private func presentInviteFriends() {
        guard let permalink = try? PermalinkBuilder.permalinkTo(userIdentifier: parameters.userSession.userID).absoluteString else {
            return
        }
        let shareText = ElementL10n.inviteFriendsText(ElementInfoPlist.cfBundleName, permalink)
        let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        hostingController.present(vc, animated: true)
    }
}
