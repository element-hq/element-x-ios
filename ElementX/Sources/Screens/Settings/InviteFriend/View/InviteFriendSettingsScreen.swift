import Compound
import SwiftUI

struct InviteFriendSettingsScreen: View {
    @ObservedObject var context: InviteFriendSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            ZeroListRow(kind: .custom {
                ZStack {
                    VStack {
                        Image(asset: Asset.Images.inviteImage)
                        
                        Text("Invite a friend.")
                            .font(.compound.headingMDBold)
                            .foregroundColor(.compound.textPrimary)
                            .padding(.top, 24)
                        
                        Text("Earn rewards.")
                            .font(.compound.headingMDBold)
                            .foregroundColor(.compound.textPrimary)
                            .padding(.bottom, 24)
                        
                        if context.viewState.bindings.messengerInvite.remainingInvites > 0 {
                            Button {
                                UIPasteboard.general.string = inviteCodeMessage(inviteSlug: context.viewState.bindings.messengerInvite.slug)
                                context.send(viewAction: .inviteCopied)
                            } label: {
                                Image(asset: Asset.Images.btnCopyInviteCode)
                            }
                            .padding(.vertical, 16)
                            
                            Text("\(context.viewState.bindings.messengerInvite.remainingInvites) Remaining")
                                .font(.zero.bodyLG)
                                .foregroundColor(.compound.textSecondary)
                                .padding(.bottom, 16)
                        } else {
                            Text("Thank you! You’ve used all of your available invites. We’ll let you know when you can invite more people.")
                                .font(.zero.bodyLG)
                                .foregroundColor(.compound.textSecondary)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 24)
                        }
                    }
                    
                    if context.viewState.bindings.inviteCopied {
                        inviteCopiedView
                    }
                }
            })
        }
        .zeroList()
    }
    
    var inviteCopiedView: some View {
        VStack {
            Image(asset: Asset.Images.checkIcon)
                .resizable()
                .frame(width: 48, height: 48)
            
            Text("Invite Copied")
                .font(.compound.bodyLGSemibold)
                .foregroundStyle(.compound.textPrimary)
        }
        .padding(.all, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.compound.bgCanvasDefaultLevel1)
        )
    }
    
    private func inviteCodeMessage(inviteSlug: String) -> String {
        """
        Here's your invite code to ZERO Messenger:
        \(inviteSlug)

        Join early, earn more:
        https://zos.zero.tech/get-access
        """
    }
}

// MARK: - Previews

struct InviteFriendSettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let userSession = UserSessionMock(
            .init(
                clientProxy: ClientProxyMock(
                    .init(userID: "@userid:example.com",
                          deviceID: "AAAAAAAAAAA"))))
        return InviteFriendSettingsScreenViewModel(userSession: userSession)
    }()

    static var previews: some View {
        InviteFriendSettingsScreen(context: viewModel.context)
    }
}
