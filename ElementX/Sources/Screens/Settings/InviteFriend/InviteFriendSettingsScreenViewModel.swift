import Combine
import SwiftUI

typealias InviteFriendSettingsScreenViewModelType = StateStoreViewModel<
    InviteFriendSettingsScreenViewState, InviteFriendSettingsScreenViewAction
>

class InviteFriendSettingsScreenViewModel:
    InviteFriendSettingsScreenViewModelType,
    InviteFriendSettingsScreenViewModelProtocol
{

    init(userSession: UserSessionProtocol) {
        super.init(
            initialViewState: .init(
                bindings: .init(messengerInvite: ZeroMessengerInvite.empty())
            )
        )
        
        userSession.clientProxy.messengerInvitePublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.bindings.messengerInvite, on: self)
            .store(in: &cancellables)
        
        Task {
            await userSession.clientProxy.loadZeroMessengerInvite()
        }
    }
}
