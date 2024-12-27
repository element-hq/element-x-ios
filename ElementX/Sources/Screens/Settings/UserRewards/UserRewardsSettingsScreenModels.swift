import Foundation
import UIKit

struct UserRewardsSettingsScreenViewState: BindableState {
    var bindings: UserRewardsSettingsScreenViewStateBindings
}

struct UserRewardsSettingsScreenViewStateBindings {
    var userRewards = ZeroRewards.empty()
}

enum UserRewardsSettingsScreenViewAction { }
