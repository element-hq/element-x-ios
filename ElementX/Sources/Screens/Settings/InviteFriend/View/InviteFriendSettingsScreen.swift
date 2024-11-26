import Compound
import SwiftUI

struct InviteFriendSettingsScreen: View {
    @ObservedObject var context: InviteFriendSettingsScreenViewModel.Context
    
    var body: some View {
        VStack {
            Text("Welcome to Messenger Invite Screen")
            
            Spacer()
            
            Image(asset: Asset.Images.inviteImage)
        }
    }
}
