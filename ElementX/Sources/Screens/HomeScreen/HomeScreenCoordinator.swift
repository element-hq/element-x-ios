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
    let navigationStackCoordinator: NavigationStackCoordinator
}

enum HomeScreenCoordinatorAction {
    case presentRoom(roomIdentifier: String)
    case presentSettingsScreen
    case presentFeedbackScreen
    case presentSessionVerificationScreen
    case presentStartChatScreen
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
            case .presentRoom(let roomIdentifier):
                self.callback?(.presentRoom(roomIdentifier: roomIdentifier))
            case .presentFeedbackScreen:
                self.callback?(.presentFeedbackScreen)
            case .presentSettingsScreen:
                self.callback?(.presentSettingsScreen)
            case .presentInviteFriendsScreen:
                self.presentInviteFriends()
            case .presentSessionVerificationScreen:
                self.callback?(.presentSessionVerificationScreen)
            case .signOut:
                self.callback?(.signOut)
            case .presentStartChatScreen:
                self.callback?(.presentStartChatScreen)
            }
        }
    }
    
    // MARK: - Public
    
    func start() {
        #if !DEBUG
        if parameters.bugReportService.crashedLastRun {
            genericRoomViewModel.presentCrashedLastRunAlert()
        }
        #endif
    }
    
    func toPresentable() -> AnyView {
        AnyView(HomeScreen(context: viewModel.context))
    }
    
    // MARK: - Private

    private func presentInviteFriends() {
        parameters.navigationStackCoordinator.setSheetCoordinator(InviteFriendsCoordinator(userId: parameters.userSession.userID))
    }
}
