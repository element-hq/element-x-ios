import Foundation
import UIKit

struct InviteFriendSettingsScreenViewState: BindableState {
    var bindings: InviteFriendSettingsScreenViewStateBindings
}

struct InviteFriendSettingsScreenViewStateBindings {
    var messengerInvite: ZeroMessengerInvite = ZeroMessengerInvite.empty()
}

enum InviteFriendSettingsScreenViewAction {
    
}
