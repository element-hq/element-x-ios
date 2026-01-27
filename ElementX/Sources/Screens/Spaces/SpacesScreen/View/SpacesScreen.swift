//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SpacesScreen: View {
    @Bindable var context: SpacesScreenViewModel.Context
    
    var body: some View {
        mainContent
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
    
    @ViewBuilder
    private var mainContent: some View {
        if context.viewState.isCreateSpaceEnabled, context.viewState.topLevelSpaces.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    header
                    spaces
                }
            }
        }
    }
    
    private var emptyState: some View {
        FullscreenDialog(horizontalPadding: 24) {
            TitleAndIcon(title: L10n.screenSpaceListEmptyStateTitle,
                         icon: \.spaceSolid,
                         iconStyle: .defaultSolid)
        } bottomContent: {
            Button(L10n.actionCreateSpace) {
                context.send(viewAction: .createSpace)
            }
            .buttonStyle(.compound(.primary))
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.spaceSolid)
            
            VStack(spacing: 8) {
                Text(L10n.screenSpaceListTitle)
                    .font(.compound.headingLGBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(L10n.commonSpaces(context.viewState.topLevelSpaces.count))
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
    
    private var spaces: some View {
        ForEach(context.viewState.topLevelSpaces, id: \.id) { spaceServiceRoom in
            SpaceRoomCell(spaceServiceRoom: spaceServiceRoom,
                          isSelected: spaceServiceRoom.id == context.viewState.selectedSpaceID,
                          mediaProvider: context.mediaProvider) { action in
                context.send(viewAction: .spaceAction(action))
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
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
            .buttonStyle(.borderless)
            .accessibilityLabel(L10n.commonSettings)
        }
        
        ToolbarItem(placement: .principal) {
            // Hides the navigationTitle (which is set for the navigation stack label).
            Text("").accessibilityHidden(true)
        }
        .backportSharedBackgroundVisibility(.hidden)
        
        if context.viewState.isCreateSpaceEnabled {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    context.send(viewAction: .createSpace)
                } label: {
                    CompoundIcon(\.plus)
                        .accessibilityHidden(true)
                }
                .accessibilityLabel(L10n.actionCreateSpace)
            }
        }
    }
}

// MARK: - Previews

struct SpacesScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let emptyViewModel = makeViewModel(isEmpty: true)
    
    static var previews: some View {
        NavigationStack {
            SpacesScreen(context: viewModel.context)
        }
        
        NavigationStack {
            SpacesScreen(context: emptyViewModel.context)
        }
        .previewDisplayName("Empty")
    }
    
    static func makeViewModel(isEmpty: Bool = false) -> SpacesScreenViewModel {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.createSpaceEnabled = true
        appSettings.hasSeenSpacesAnnouncement = true
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.spaceService = SpaceServiceProxyMock(.init(topLevelSpaces: isEmpty ? [] : .mockJoinedSpaces))
        
        return SpacesScreenViewModel(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                     selectedSpacePublisher: .init(nil),
                                     appSettings: appSettings,
                                     userIndicatorController: UserIndicatorControllerMock())
    }
}
