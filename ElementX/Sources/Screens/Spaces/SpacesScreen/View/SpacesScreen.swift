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
            .toolbarRole(Compound.supportsGlass ? .editor : .automatic)
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .toolbarBloom(hasSearchBar: false)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if context.viewState.topLevelSpaces.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    header
                    home // Tchap: Space default action is now conversation filtering (add home row)
                    spaces
                }
            }
        }
    }
    
    private var emptyState: some View {
        FullscreenDialog(horizontalPadding: 24) {
            // :tchap: Add empty space description
//            TitleAndIcon(title: L10n.screenSpaceListEmptyStateTitle,
//                        icon: \.spaceSolid,
//                        iconStyle: .defaultSolid)
            VStack(spacing: 24) {
                TitleAndIcon(title: L10n.screenSpaceListEmptyStateTitle,
                             icon: \.spaceSolid,
                             iconStyle: .defaultSolid)
                
                Text(TchapL10n.screenSpacesEmptyViewDescription)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center) // :tchap:end
            }
        } bottomContent: {
//            Button(L10n.actionCreateSpace) {
//                context.send(viewAction: .createSpace)
//            }
//            .buttonStyle(.compound(.primary))
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.spaceSolid)
            
            VStack(spacing: 8) {
                Text(L10n.screenSpaceListTitle)
                    .font(.compound.headingMDBold)
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

    // Tchap: Space default action is now conversation filtering (add home row)
    private var home: some View {
        Button {
            context.send(viewAction: .selectFilter(nil))
        } label: {
            HStack(spacing: 16) {
                CompoundIcon(\.home, size: .custom(52 - 20), relativeTo: .compound.bodyLG)
                    .foregroundStyle(.compound.iconPrimary)
                    .padding(10)
                    .background(.compound.bgSubtleSecondary, in: RoundedRectangle(cornerRadius: 52 / 4))
                    .overlay {
                        RoundedRectangle(cornerRadius: 52 / 4)
                            .stroke(.compound.iconQuaternaryAlpha, lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(TchapL10n.screenSpacesHomeTitle)
                        .font(.compound.bodyLGSemibold)
                        .foregroundColor(.compound.textPrimary)
                        .lineLimit(1)

                    Text(TchapL10n.screenSpacesHomeDescription)
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.compound.borderDisabled)
                    .frame(height: 1 / UIScreen.main.scale)
            }
        }
        .buttonStyle(SpaceRoomCellButtonStyle(isHighlighted: false))
    }

    private var spaces: some View {
        ForEach(context.viewState.topLevelSpaces, id: \.id) { spaceServiceRoom in
            // Tchap: Space default action is now conversation filtering (+ add OnInfo: action)
            SpaceRoomCell(spaceServiceRoom: spaceServiceRoom,
                          isSelected: spaceServiceRoom.id == context.viewState.selectedSpaceID,
                          mediaProvider: context.mediaProvider,
                          onInfo: { room in
                              context.send(viewAction: .spaceAction(.select(room)))
                          }) { _ in
                context.send(viewAction: .selectFilter(spaceServiceRoom))
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        // Use the title placement on iOS 26 to match the chats tab and fix a weird animation.
        ToolbarItem(placement: Compound.supportsGlass ? .title : .navigationBarLeading) {
            Button {
                context.send(viewAction: .showSettings)
            } label: {
                AvatarSettingsButtonLabel(userProfile: context.viewState.userProfile,
                                          mediaProvider: context.mediaProvider)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(L10n.commonSettings)
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
        }
        .backportSharedBackgroundVisibility(.hidden)
        
        // No need to hide the title on iOS 26, as we use the .title placement for the settings
        // button to workaround a weird liquid glass transition.
        if #unavailable(iOS 26) {
            ToolbarItem(placement: .principal) {
                // Hides the navigationTitle (which is set for the navigation stack label).
                Text("").accessibilityHidden(true)
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            // :tchap: Remove create space action
//            Button {
//                context.send(viewAction: .createSpace)
//            } label: {
//                CompoundIcon(\.plus)
//                    .accessibilityHidden(true)
//            }
//            .accessibilityLabel(L10n.actionCreateSpace) :tchap:end
        }
    }
}

// MARK: - Previews

struct SpacesScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let emptyViewModel = makeViewModel(isEmpty: true)
    
    static var previews: some View {
        ElementNavigationStack {
            SpacesScreen(context: viewModel.context)
        }
        
        ElementNavigationStack {
            SpacesScreen(context: emptyViewModel.context)
        }
        .previewDisplayName("Empty")
    }
    
    static func makeViewModel(isEmpty: Bool = false) -> SpacesScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.spaceService = SpaceServiceProxyMock(.init(topLevelSpaces: isEmpty ? [] : .mockJoinedSpaces))
        
        return SpacesScreenViewModel(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                     selectedSpacePublisher: .init(nil),
                                     userIndicatorController: UserIndicatorControllerMock())
    }
}
