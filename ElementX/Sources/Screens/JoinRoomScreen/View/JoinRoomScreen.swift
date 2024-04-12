//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Compound
import SwiftUI

struct JoinRoomScreen: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @ObservedObject var context: JoinRoomScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: 80, background: .bloom) {
            mainContent
        } bottomContent: {
            buttons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
    }
    
    var mainContent: some View {
        VStack(spacing: 16) {
            LoadableAvatarImage(url: context.viewState.avatarURL,
                                name: context.viewState.roomName,
                                contentID: context.viewState.roomID,
                                avatarSize: .room(on: .joinRoom),
                                imageProvider: context.imageProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
            
            VStack(spacing: 8) {
                Text(context.viewState.title)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(context.viewState.subtitle)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Image(asset: Asset.Images.joinRoomGraphic)
                .padding(.top, 40)
        }
    }
    
    @ViewBuilder
    var buttons: some View {
        switch context.viewState.interaction {
        case .knock:
            Button(L10n.screenJoinRoomKnockAction) { context.send(viewAction: .knock) }
                .buttonStyle(.compound(.primary))
        case .join:
            Button(L10n.screenJoinRoomJoinAction) { context.send(viewAction: .join) }
                .buttonStyle(.compound(.super))
        case .invited:
            ViewThatFits {
                HStack(spacing: 8) { inviteButtons }
                VStack(spacing: 16) { inviteButtons }
            }
        }
    }
    
    @ViewBuilder
    var inviteButtons: some View {
        Button(L10n.actionDecline) { context.send(viewAction: .acceptInvite) }
            .buttonStyle(.compound(.secondary))
        Button(L10n.actionAccept) { context.send(viewAction: .declineInvite) }
            .buttonStyle(.compound(.primary))
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            RoomHeaderView(roomID: context.viewState.roomID,
                           roomName: context.viewState.roomName,
                           avatarURL: context.viewState.avatarURL,
                           imageProvider: context.imageProvider)
        }
    }
}

// MARK: - Previews

struct JoinRoomScreen_Previews: PreviewProvider, TestablePreview {
    static let knockViewModel = makeViewModel(interaction: .knock)
    static let joinViewModel = makeViewModel(interaction: .join)
    static let inviteViewModel = makeViewModel(interaction: .invited)
    
    static var previews: some View {
        NavigationStack {
            JoinRoomScreen(context: knockViewModel.context)
        }
        .previewDisplayName("Knock")
        
        NavigationStack {
            JoinRoomScreen(context: joinViewModel.context)
        }
        .previewDisplayName("Join")
        
        NavigationStack {
            JoinRoomScreen(context: inviteViewModel.context)
        }
        .previewDisplayName("Invite")
    }
    
    static func makeViewModel(interaction: JoinRoomScreenInteraction) -> JoinRoomScreenViewModel {
        JoinRoomScreenViewModel(roomID: "6",
                                roomName: "Room Name",
                                avatarURL: nil,
                                interaction: interaction,
                                clientProxy: ClientProxyMock(.init()))
    }
}
