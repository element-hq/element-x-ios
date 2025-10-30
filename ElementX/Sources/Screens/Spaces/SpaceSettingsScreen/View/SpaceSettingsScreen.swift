//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SpaceSettingsScreen: View {
    @Bindable var context: SpaceSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            editSection
            if context.viewState.canEditRolesOrPermissions {
                securitySection
            }
            peopleSection
            leaveSpaceSection
        }
        .compoundList()
        .navigationTitle(L10n.commonSettings)
    }
    
    private var editSection: some View {
        Section {
            if context.viewState.canEditBaseInfo {
                ListRow(kind: .custom {
                    Button {
                        context.send(viewAction: .processTapEdit)
                    } label: {
                        editSectionContent
                    }
                })
            } else {
                ListRow(kind: .custom {
                    editSectionContent
                })
            }
        }
    }
    
    private var editSectionContent: some View {
        HStack(spacing: 12) {
            RoomAvatarImage(avatar: context.viewState.details.avatar,
                            avatarSize: .room(on: .spaceSettings),
                            mediaProvider: context.mediaProvider)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(context.viewState.details.name ?? context.viewState.details.id)
                    .lineLimit(1)
                    .font(.compound.headingMD)
                    .foregroundStyle(.compound.textPrimary)
                if let alias = context.viewState.details.canonicalAlias {
                    Text(alias)
                        .lineLimit(1)
                        .font(.compound.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if context.viewState.canEditBaseInfo {
                ListRowAccessory.navigationLink
            }
        }
        .padding(.horizontal, ListRowPadding.horizontal)
        .padding(.vertical, 16)
    }
    
    private var securitySection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenSpaceSettingsSecurityAndPrivacy, icon: \.lock),
                    kind: .navigationLink {
                        context.send(viewAction: .processTapSecurity)
                    })
        }
    }
    
    private var peopleSection: some View {
        Section {
            if context.viewState.hasMemberIdentityVerificationStateViolations {
                ListRow(label: .default(title: L10n.commonPeople, icon: \.user),
                        details: .icon(CompoundIcon(\.infoSolid).foregroundStyle(.compound.iconCriticalPrimary)),
                        kind: .navigationLink {
                            context.send(viewAction: .processTapPeople)
                        })
            } else {
                ListRow(label: .default(title: L10n.commonPeople, icon: \.user),
                        details: .title(String(context.viewState.joinedMembersCount)),
                        kind: .navigationLink {
                            context.send(viewAction: .processTapPeople)
                        })
            }
            
            if context.viewState.canEditRolesOrPermissions {
                ListRow(label: .default(title: L10n.screenSpaceSettingsRolesAndPermissions, icon: \.admin),
                        kind: .navigationLink {
                            context.send(viewAction: .processTapRolesAndPermissions)
                        })
            }
        }
    }
    
    private var leaveSpaceSection: some View {
        ListRow(label: .action(title: L10n.screenSpaceSettingsLeaveSpace,
                               icon: \.leave,
                               role: .destructive),
                kind: .button { context.send(viewAction: .processTapLeave) })
    }
}

// MARK: - Previews

struct SpaceSettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let ownerViewModel = SpaceSettingsScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "Space",
                                                                                                  avatarURL: .mockMXCAvatar,
                                                                                                  isSpace: true,
                                                                                                  canonicalAlias: "#space:matrix.org",
                                                                                                  members: .allMembersAsCreator)),
                                                             userSession: UserSessionMock(.init()))
    
    static let userViewModel = SpaceSettingsScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "Space",
                                                                                                 avatarURL: .mockMXCAvatar,
                                                                                                 isSpace: true,
                                                                                                 canonicalAlias: "#space:matrix.org",
                                                                                                 members: .allMembers)),
                                                            userSession: UserSessionMock(.init()))
    
    static var previews: some View {
        NavigationStack {
            SpaceSettingsScreen(context: ownerViewModel.context)
        }
        .previewDisplayName("Owner")
        
        NavigationStack {
            SpaceSettingsScreen(context: userViewModel.context)
        }
        .previewDisplayName("User")
    }
}
