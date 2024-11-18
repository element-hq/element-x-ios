import Foundation
import UIKit

struct UserRewardsSettingsScreenViewState: BindableState {
    var bindings: UserRewardsSettingsScreenViewStateBindings
}

struct UserRewardsSettingsScreenViewStateBindings {
    var userRewards: ZeroRewards = ZeroRewards.empty()
}

enum UserRewardsSettingsScreenViewAction {
    
}
