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
        .alert(item: $context.alertInfo)
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var mainContent: some View {
        VStack(spacing: 16) {
            LoadableAvatarImage(url: context.viewState.roomDetails?.avatarURL,
                                name: context.viewState.title,
                                contentID: context.viewState.roomID,
                                avatarSize: .room(on: .joinRoom),
                                imageProvider: context.imageProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
            
            VStack(spacing: 8) {
                Text(context.viewState.title)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                if let alias = context.viewState.roomDetails?.canonicalAlias {
                    Text(alias)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                }
                
                if let memberCount = context.viewState.roomDetails?.memberCount {
                    Label("\(memberCount)", icon: \.userProfile, iconSize: .small, relativeTo: .compound.bodySMSemibold)
                        .font(.compound.bodySMSemibold)
                        .foregroundStyle(.compound.textSecondary)
                        .padding(4)
                        .background(Capsule().fill(.compound.bgSubtleSecondary))
                        .labelStyle(.custom(spacing: 4))
                }
                
                if let topic = context.viewState.roomDetails?.topic {
                    Text(topic)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            
            Image(asset: Asset.Images.joinRoomGraphic)
                .padding(.top, 40)
        }
    }
    
    @ViewBuilder
    var buttons: some View {
        switch context.viewState.mode {
        case .unknown:
            EmptyView()
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
        Button(L10n.actionDecline) { context.send(viewAction: .declineInvite) }
            .buttonStyle(.compound(.secondary))
        Button(L10n.actionAccept) { context.send(viewAction: .acceptInvite) }
            .buttonStyle(.compound(.primary))
    }
}

// MARK: - Previews

struct JoinRoomScreen_Previews: PreviewProvider, TestablePreview {
    static let unknownViewModel = makeViewModel(mode: .unknown)
    static let knockViewModel = makeViewModel(mode: .knock)
    static let joinViewModel = makeViewModel(mode: .join)
    static let inviteViewModel = makeViewModel(mode: .invited)
    
    static var previews: some View {
        NavigationStack {
            JoinRoomScreen(context: unknownViewModel.context)
        }
        .previewDisplayName("Unknown")
        .snapshot(delay: 0.25)
        
//        NavigationStack {
//            JoinRoomScreen(context: knockViewModel.context)
//        }
//        .previewDisplayName("Knock")
//        .snapshot(delay: 0.25)
        
        NavigationStack {
            JoinRoomScreen(context: joinViewModel.context)
        }
        .previewDisplayName("Join")
        .snapshot(delay: 0.25)
        
        NavigationStack {
            JoinRoomScreen(context: inviteViewModel.context)
        }
        .previewDisplayName("Invite")
        .snapshot(delay: 0.25)
    }
    
    static func makeViewModel(mode: JoinRoomScreenInteractionMode) -> JoinRoomScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        
        // swiftlint:disable:next large_tuple
        let membership: (isJoined: Bool, isInvited: Bool, isPublic: Bool, canKnock: Bool) = switch mode {
        case .unknown:
            (false, false, false, false)
        case .invited:
            (false, true, false, false)
        case .join:
            (false, false, true, false)
        case .knock:
            (false, false, false, true)
        }
        
        if mode == .unknown {
            clientProxy.roomPreviewForIdentifierReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        } else {
            clientProxy.roomPreviewForIdentifierReturnValue = .success(.init(roomID: "1",
                                                                             name: "The Three-Body Problem - 三体",
                                                                             canonicalAlias: "#3🌞problem:matrix.org",
                                                                             // swiftlint:disable:next line_length
                                                                             topic: "“Science and technology were the only keys to opening the door to the future, and people approached science with the faith and sincerity of elementary school students.”",
                                                                             avatarURL: URL.homeDirectory,
                                                                             memberCount: UInt(100),
                                                                             isHistoryWorldReadable: false,
                                                                             isJoined: membership.isJoined,
                                                                             isInvited: membership.isInvited,
                                                                             isPublic: membership.isPublic,
                                                                             canKnock: membership.canKnock))
        }
        
        return JoinRoomScreenViewModel(roomID: "1",
                                       clientProxy: clientProxy,
                                       mediaProvider: MockMediaProvider(),
                                       userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
