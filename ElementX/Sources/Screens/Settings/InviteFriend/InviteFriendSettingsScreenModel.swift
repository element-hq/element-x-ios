import Foundation
import UIKit

struct InviteFriendSettingsScreenViewState: BindableState {
    var bindings: InviteFriendSettingsScreenViewStateBindings
}

struct InviteFriendSettingsScreenViewStateBindings {
    var messengerInvite = ZeroMessengerInvite.empty()
    var inviteCopied = false
}

enum InviteFriendSettingsScreenViewAction {
    case inviteCopied
}
