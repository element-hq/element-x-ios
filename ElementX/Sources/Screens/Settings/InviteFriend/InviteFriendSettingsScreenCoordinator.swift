import Combine
import SwiftUI

struct InviteFriendSettingsScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
}

final class InviteFriendSettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: InviteFriendSettingsScreenViewModelProtocol
    
    init(parameters: InviteFriendSettingsScreenCoordinatorParameters) {
        viewModel = InviteFriendSettingsScreenViewModel(userSession: parameters.userSession)
    }
            
    func toPresentable() -> AnyView {
//        AnyView(InviteFriendSettingsScreen(context: viewModel.context))
        AnyView(ReferAFriendSettingsScreen(context: viewModel.context))
    }
}
