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
    let bugReportService: BugReportServiceProtocol
    let navigationController: NavigationController
}

enum HomeScreenCoordinatorAction {
    case presentRoomScreen(roomIdentifier: String)
    case presentSettingsScreen
    case presentFeedbackScreen
    case presentSessionVerificationScreen
    case signOut
}

final class HomeScreenCoordinator: CoordinatorProtocol {
    private let parameters: HomeScreenCoordinatorParameters
    private var viewModel: HomeScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    var callback: ((HomeScreenCoordinatorAction) -> Void)?
    
    init(parameters: HomeScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = HomeScreenViewModel(userSession: parameters.userSession,
                                        attributedStringBuilder: parameters.attributedStringBuilder)
        
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .selectRoom(let roomIdentifier):
                self.callback?(.presentRoomScreen(roomIdentifier: roomIdentifier))
            case .userMenu(let action):
                self.processUserMenuAction(action)
            case .verifySession:
                self.callback?(.presentSessionVerificationScreen)
            }
        }
    }
    
    // MARK: - Public
    
    func start() {
        if parameters.bugReportService.crashedLastRun {
            viewModel.presentAlert(
                AlertInfo(id: UUID(),
                          title: ElementL10n.sendBugReportAppCrashed,
                          primaryButton: .init(title: ElementL10n.no, action: nil),
                          secondaryButton: .init(title: ElementL10n.yes) { [weak self] in
                              self?.callback?(.presentFeedbackScreen)
                          }))
        }
    }
    
    func toPresentable() -> AnyView {
        AnyView(HomeScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func processUserMenuAction(_ action: HomeScreenViewUserMenuAction) {
        switch action {
        case .settings:
            callback?(.presentSettingsScreen)
        case .inviteFriends:
            presentInviteFriends()
        case .feedback:
            callback?(.presentFeedbackScreen)
        case .signOut:
            callback?(.signOut)
        }
    }

    private func presentInviteFriends() {
        parameters.navigationController.presentSheet(InviteFriendsCoordinator(userId: parameters.userSession.userID))
    }
}
