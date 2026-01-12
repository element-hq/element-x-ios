//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ManageAuthorizedSpacesScreen: View {
    @Bindable var context: ManageAuthorizedSpacesScreenViewModel.Context
    
    var body: some View {
        Form {
            header
            
            if !context.viewState.authorizedSpacesSelection.joinedSpaces.isEmpty {
                joinedSpacesSection
            }
            
            if !context.viewState.authorizedSpacesSelection.unknownSpacesIDs.isEmpty {
                unknownSpacesSection
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenManageAuthorizedSpacesTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
    }
    
    private var header: some View {
        Section {
            EmptyView()
        } header: {
            VStack(spacing: 16) {
                BigIcon(icon: \.spaceSolid, style: .default)
                    .accessibilityHidden(true)
                Text(L10n.screenManageAuthorizedSpacesHeader)
                    .multilineTextAlignment(.center)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var joinedSpacesSection: some View {
        Section {
            ForEach(context.viewState.authorizedSpacesSelection.joinedSpaces, id: \.id) { space in
                ListRow(label: .avatar(title: space.name,
                                       description: space.canonicalAlias,
                                       icon: avatar(space: space)),
                        kind: .multiSelection(isSelected: context.viewState.selectedIDs.contains(space.id)) {
                            context.send(viewAction: .toggle(spaceID: space.id))
                        })
            }
        } header: {
            Text(L10n.screenManageAuthorizedSpacesYourSpacesSectionTitle)
                .compoundListSectionHeader()
        }
    }
    
    private var unknownSpacesSection: some View {
        Section {
            ForEach(context.viewState.authorizedSpacesSelection.unknownSpacesIDs, id: \.self) { id in
                ListRow(label: .plain(title: L10n.screenManageAuthorizedSpacesUnknownSpace,
                                      description: id),
                        kind: .multiSelection(isSelected: context.viewState.selectedIDs.contains(id)) {
                            context.send(viewAction: .toggle(spaceID: id))
                        })
            }
        } header: {
            Text(L10n.screenManageAuthorizedSpacesUnknownSpacesSectionTitle)
                .compoundListSectionHeader()
        }
    }
    
    private func avatar(space: SpaceServiceRoomProtocol) -> some View {
        RoomAvatarImage(avatar: space.avatar,
                        avatarSize: .room(on: .authorizedSpaces),
                        mediaProvider: context.mediaProvider)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            ToolbarButton(role: .done) {
                context.send(viewAction: .done)
            }
            .disabled(context.viewState.isDoneButtonDisabled)
        }
        ToolbarItem(placement: .cancellationAction) {
            ToolbarButton(role: .cancel) {
                context.send(viewAction: .cancel)
            }
        }
    }
}

// MARK: - Previews

struct ManageAuthorizedSpacesScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = ManageAuthorizedSpacesScreenViewModel(authorizedSpacesSelection: .init(joinedSpaces: .mockJoinedSpaces2,
                                                                                                  unknownSpacesIDs: ["!unknown-space-id-1",
                                                                                                                     "!unknown-space-id-2",
                                                                                                                     "!unknown-space-id-3"],
                                                                                                  initialSelectedIDs: ["space1",
                                                                                                                       "space3",
                                                                                                                       "!unknown-space-id-2"]),
                                                                 mediaProvider: MediaProviderMock(configuration: .init()))
    
    static var previews: some View {
        NavigationStack {
            ManageAuthorizedSpacesScreen(context: viewModel.context)
        }
    }
}
