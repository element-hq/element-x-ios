import Foundation
import UIKit

struct InviteFriendSettingsScreenViewState: BindableState {
    var bindings: InviteFriendSettingsScreenViewStateBindings
    
    var hasRemaniningInvites: Bool {
        bindings.messengerInvite.remainingInvites > 0
    }
    
    var inviteSlug: String {
        bindings.messengerInvite.slug
    }
    
    var totalInvited: String {
        bindings.messengerInvite.invitesUsed.description
    }
}

struct InviteFriendSettingsScreenViewStateBindings {
    var messengerInvite = ZeroMessengerInvite.empty()
    var inviteCopied = false
}

enum InviteFriendSettingsScreenViewAction {
    case inviteCopied
}
