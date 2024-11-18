import Combine
import SwiftUI

struct UserRewardsSettingsScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
}

final class UserRewardsSettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: UserRewardsSettingsScreenViewModelProtocol
    
    init(parameters: UserRewardsSettingsScreenCoordinatorParameters) {
        viewModel = UserRewardsSettingsScreenViewModel(userSession: parameters.userSession)
    }
            
    func toPresentable() -> AnyView {
        AnyView(UserRewardsSettingsScreen(context: viewModel.context))
    }
}
