//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomRolesAndPermissionsScreen: View {
    @Bindable var context: RoomRolesAndPermissionsScreenViewModel.Context
    
    var body: some View {
        Form {
            rolesSection
            permissionsSection
            
            resetSection
        }
        .compoundList()
        .navigationTitle(L10n.screenRoomRolesAndPermissionsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
    }
    
    private var rolesSection: some View {
        Section {
            if context.viewState.ownPowerLevel.role == .creator {
                ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsAdminsAndOwners,
                                        icon: \.admin),
                        details: administratorOrOwnersDetails,
                        kind: .navigationLink {
                            context.send(viewAction: .editRoles(.administrators))
                        })
                        .accessibilityIdentifier(A11yIdentifiers.roomRolesAndPermissionsScreen.administrators)
            } else {
                ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsAdmins,
                                        icon: \.admin),
                        details: administratorDetails,
                        kind: .navigationLink {
                            context.send(viewAction: .editRoles(.administrators))
                        })
                        .accessibilityIdentifier(A11yIdentifiers.roomRolesAndPermissionsScreen.administrators)
            }
            
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsModerators,
                                    icon: \.chatProblem),
                    details: moderatorDetails,
                    kind: .navigationLink {
                        context.send(viewAction: .editRoles(.moderators))
                    })
                    .accessibilityIdentifier(A11yIdentifiers.roomRolesAndPermissionsScreen.moderators)
            
            if context.viewState.ownPowerLevel.role != .creator {
                ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsChangeMyRole,
                                        icon: \.edit),
                        kind: .button {
                            context.send(viewAction: .editOwnUserRole)
                        })
            }
        } header: {
            Text(L10n.screenRoomRolesAndPermissionsRolesHeader)
                .compoundListSectionHeader()
        }
    }
    
    private var administratorOrOwnersDetails: ListRowDetails<Image> {
        if let administratorCount = context.viewState.administratorsAndOwnersCount {
            .title("\(administratorCount)")
        } else {
            .isWaiting(true)
        }
    }
    
    private var administratorDetails: ListRowDetails<Image> {
        if let administratorCount = context.viewState.administratorCount {
            .title("\(administratorCount)")
        } else {
            .isWaiting(true)
        }
    }
    
    private var moderatorDetails: ListRowDetails<Image> {
        if let moderatorCount = context.viewState.moderatorCount {
            .title("\(moderatorCount)")
        } else {
            .isWaiting(true)
        }
    }
    
    private var permissionsSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsPermissionsHeader,
                                    icon: \.settings),
                    details: .isWaiting(context.viewState.permissions == nil),
                    kind: .navigationLink {
                        context.send(viewAction: .editPermissions)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.roomRolesAndPermissionsScreen.permissions)
                    .disabled(context.viewState.permissions == nil)
        }
    }
    
    private var resetSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsReset,
                                    icon: \.delete,
                                    role: .destructive),
                    kind: .button {
                        context.send(viewAction: .reset)
                    })
        }
    }
}

// MARK: - Previews

struct RoomRolesAndPermissionsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomRolesAndPermissionsScreenViewModel(initialPermissions: RoomPermissions(powerLevels: .mock),
                                                                  roomProxy: JoinedRoomProxyMock(.init(members: .allMembersAsAdmin)),
                                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                                  analytics: ServiceLocator.shared.analytics)
    
    static let creatorViewModel = RoomRolesAndPermissionsScreenViewModel(initialPermissions: RoomPermissions(powerLevels: .mock),
                                                                         roomProxy: JoinedRoomProxyMock(.init(members: .allMembersAsCreator)),
                                                                         userIndicatorController: UserIndicatorControllerMock(),
                                                                         analytics: ServiceLocator.shared.analytics)
    static var previews: some View {
        NavigationStack {
            RoomRolesAndPermissionsScreen(context: viewModel.context)
        }
        .previewDisplayName("Admin")
        
        NavigationStack {
            RoomRolesAndPermissionsScreen(context: creatorViewModel.context)
        }
        .previewDisplayName("Creator")
    }
}
