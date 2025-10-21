//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
        .toolbarBloom(hasSearchBar: false)
        .onAppear { context.send(viewAction: .screenAppeared) }
        .sheet(isPresented: $context.isPresentingFeatureAnnouncement) {
            SpacesAnnouncementSheetView(context: context)
        }
    }
    
    var header: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.spaceSolid)
            
            VStack(spacing: 8) {
                Text(L10n.screenSpaceListTitle)
                    .font(.compound.headingLGBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(L10n.commonSpaces(context.viewState.joinedSpaces.count))
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
        ForEach(context.viewState.joinedSpaces, id: \.id) { spaceRoomProxy in
            SpaceRoomCell(spaceRoomProxy: spaceRoomProxy,
                          isSelected: spaceRoomProxy.id == context.viewState.selectedSpaceID,
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
        .backportSharedBackgroundVisibility(.hidden)
        
        ToolbarItem(placement: .principal) {
            // Hides the navigationTitle (which is set for the navigation stack label).
            Text("").accessibilityHidden(true)
        }
        .backportSharedBackgroundVisibility(.hidden)
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
    
    static func makeViewModel() -> SpaceListScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.spaceService = SpaceServiceProxyMock(.init(joinedSpaces: .mockJoinedSpaces))
        
        let viewModel = SpaceListScreenViewModel(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                 selectedSpacePublisher: .init(nil),
                                                 appSettings: ServiceLocator.shared.settings,
                                                 userIndicatorController: UserIndicatorControllerMock())
        
        return viewModel
    }
}
