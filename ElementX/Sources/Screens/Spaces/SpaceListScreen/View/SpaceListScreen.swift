//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SpaceListScreen: View {
    @Bindable var context: SpaceListScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                header
                spaces
            }
        }
        .navigationTitle(L10n.screenSpaceListTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .bloom()
    }
    
    var header: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.spaceSolid)
            
            VStack(spacing: 8) {
                Text(L10n.screenSpaceListTitle)
                    .font(.compound.headingLGBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(context.viewState.subtitle)
                    .font(.compound.bodyLG)
                    .foregroundStyle(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Text(L10n.screenSpaceListDescription)
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.compound.borderDisabled)
                .frame(height: 1 / UIScreen.main.scale)
        }
    }
    
    var spaces: some View {
        ForEach(context.viewState.joinedSpaces, id: \.id) { spaceRoom in
            SpaceRoomCell(spaceRoom: spaceRoom,
                          isSelected: false,
                          mediaProvider: context.mediaProvider) { action in
                context.send(viewAction: .spaceAction(action))
            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                context.send(viewAction: .showSettings)
            } label: {
                LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                    name: context.viewState.userDisplayName,
                                    contentID: context.viewState.userID,
                                    avatarSize: .user(on: .spaces),
                                    mediaProvider: context.mediaProvider)
                    .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
                    .compositingGroup()
            }
            .accessibilityLabel(L10n.commonSettings)
        }
        
        ToolbarItem(placement: .principal) {
            // Hides the navigationTitle (which is set for the navigation stack label).
            Text("").accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

struct SpaceListScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        NavigationStack {
            SpaceListScreen(context: viewModel.context)
        }
    }
    
    static func makeViewModel(counterValue: Int = 0) -> SpaceListScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        let spaceService = SpaceServiceProxyMock(
            .init(
                joinedSpaces: [
                    SpaceRoomProxyMock(.init(id: "space1",
                                             name: "The Foundation",
                                             isSpace: true,
                                             childrenCount: 1,
                                             joinedMembersCount: 500,
                                             state: .joined)),
                    SpaceRoomProxyMock(.init(id: "space2",
                                             name: "The Second Foundation",
                                             isSpace: true,
                                             childrenCount: 1,
                                             joinedMembersCount: 100,
                                             state: .joined)),
                    SpaceRoomProxyMock(.init(id: "space3",
                                             name: "The Galactic Empire",
                                             isSpace: true,
                                             childrenCount: 25000,
                                             joinedMembersCount: 1_000_000_000,
                                             state: .joined)),
                    SpaceRoomProxyMock(.init(id: "space4",
                                             name: "The Korellians",
                                             isSpace: true,
                                             childrenCount: 27,
                                             joinedMembersCount: 2_000_000,
                                             state: .joined)),
                    SpaceRoomProxyMock(.init(id: "space5",
                                             name: "The Luminists",
                                             isSpace: true,
                                             childrenCount: 1,
                                             joinedMembersCount: 100_000,
                                             state: .joined)),
                    SpaceRoomProxyMock(.init(id: "space6",
                                             name: "The Anacreons",
                                             isSpace: true,
                                             childrenCount: 25,
                                             joinedMembersCount: 400_000,
                                             state: .joined)),
                    SpaceRoomProxyMock(.init(id: "space7",
                                             name: "The Thespians",
                                             isSpace: true,
                                             childrenCount: 15,
                                             joinedMembersCount: 300_000,
                                             state: .joined))
                ]
            )
        )
        let viewModel = SpaceListScreenViewModel(userSession: userSession,
                                                 spaceServiceProxy: spaceService)
        
        return viewModel
    }
}
