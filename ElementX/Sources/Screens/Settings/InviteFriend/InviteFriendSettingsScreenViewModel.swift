import Combine
import SwiftUI

typealias InviteFriendSettingsScreenViewModelType = StateStoreViewModel<InviteFriendSettingsScreenViewState, InviteFriendSettingsScreenViewAction>

class InviteFriendSettingsScreenViewModel:
    InviteFriendSettingsScreenViewModelType,
    InviteFriendSettingsScreenViewModelProtocol {
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
    
    override func process(viewAction: InviteFriendSettingsScreenViewAction) {
        switch viewAction {
        case .inviteCopied:
            onInviteCopied()
        }
    }
    
    private func onInviteCopied() {
        UIPasteboard.general.string = inviteCodeMessage(inviteSlug: state.inviteSlug)
        state.bindings.inviteCopied = true
        Task {
            try await Task.sleep(for: .seconds(2))
            state.bindings.inviteCopied = false
        }
    }
    
    private func inviteCodeMessage(inviteSlug: String) -> String {
        """
        Use this code to join me on ZERO Messenger: \(inviteSlug)
        https://zos.zero.tech/get-access
        """
    }
}
