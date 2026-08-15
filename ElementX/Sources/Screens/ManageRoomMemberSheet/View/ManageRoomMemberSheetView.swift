//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ManageRoomMemberSheetView: View {
    @Bindable var context: ManageRoomMemberSheetViewModelType.Context
    
    var body: some View {
        Form {
            switch context.viewState.memberDetails {
            case .memberDetails(let member):
                AvatarHeaderView(member: member,
                                 avatarSize: .user(on: .memberDetails),
                                 mediaProvider: context.mediaProvider) { url in
                    context.send(viewAction: .displayAvatar(url))
                } footer: {
                    EmptyView()
                }
            case .loadingMemberDetails(let sender):
                AvatarHeaderView(sender: sender,
                                 avatarSize: .user(on: .memberDetails),
                                 mediaProvider: context.mediaProvider) { url in
                    context.send(viewAction: .displayAvatar(url))
                } footer: {
                    EmptyView()
                }
            }
            
            Section {
                ListRow(label: .default(title: L10n.screenBottomSheetManageRoomMemberMemberUserInfo,
                                        icon: \.userProfileSolid),
                        kind: .navigationLink {
                            context.send(viewAction: .displayDetails)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.manageRoomMemberSheet.viewProfile)

                if context.viewState.isRoleVisible {
                    if context.viewState.isRoleEditable {
                        if context.viewState.isOwnUser, let role = context.viewState.memberRole {
                            // You can only demote yourself, so offer the Roles & permissions
                            // screen's Change my role dialog rather than a picker.
                            // The chevrons match the picker rows so the row reads as tappable.
                            ListRow(label: .default(title: L10n.commonRole,
                                                    icon: \.admin),
                                    details: .label(title: role.localizedTitle, systemIcon: .chevronUpChevronDown),
                                    kind: .button {
                                        context.send(viewAction: .changeOwnRole)
                                    })
                        } else {
                            ListRow(label: .default(title: L10n.commonRole,
                                                    icon: \.admin),
                                    kind: .picker(selection: $context.selectedRole,
                                                  items: context.viewState.availableRoles.map { (title: $0.localizedTitle, tag: $0) }))
                                .onChange(of: context.selectedRole) { _, newRole in
                                    context.send(viewAction: .updateRole(newRole))
                                }
                        }
                    } else if let role = context.viewState.memberRole {
                        ListRow(label: .default(title: L10n.commonRole,
                                                icon: \.admin),
                                details: .title(role.localizedTitle),
                                kind: .label)
                    }
                }
            }
            
            Section {
                if context.viewState.permissions.canKick, !context.viewState.isMemberBanned {
                    ListRow(label: .default(title: L10n.screenBottomSheetManageRoomMemberRemove,
                                            icon: \.close,
                                            role: .destructive),
                            kind: .button {
                                context.send(viewAction: .kick)
                            })
                            .disabled(context.viewState.isKickDisabled)
                }
                
                if context.viewState.permissions.canBan {
                    if !context.viewState.isMemberBanned {
                        ListRow(label: .default(title: L10n.screenBottomSheetManageRoomMemberBan,
                                                icon: \.block,
                                                role: .destructive),
                                kind: .button {
                                    context.send(viewAction: .ban)
                                })
                                .disabled(context.viewState.isBanUnbanDisabled)
                        // Kick permission is also needed to unban
                    } else if context.viewState.permissions.canKick {
                        ListRow(label: .default(title: L10n.screenBottomSheetManageRoomMemberUnban,
                                                icon: \.restart,
                                                role: .destructive),
                                kind: .button {
                                    context.send(viewAction: .unban)
                                })
                                .disabled(context.viewState.isBanUnbanDisabled)
                    }
                }
            }
        }
        .compoundList()
        .scrollBounceBehavior(.basedOnSize)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large, .fraction(0.67)]) // Maybe find a way to use the ideal height somehow?
        .alert(item: $context.alertInfo)
        .interactiveQuickLook(item: $context.mediaPreviewItem, allowEditing: false)
    }
}

struct ManageRoomMemberSheetView_Previews: PreviewProvider, TestablePreview {
    static let allActionsViewModel = ManageRoomMemberSheetViewModel.mock()
    
    static let allActionsDisabledViewModel = ManageRoomMemberSheetViewModel.mock(powerLevel: .init(value: 0))
    
    static let kickOnlyViewModel = ManageRoomMemberSheetViewModel.mock(canBan: false)
    
    static let banOnlyViewModel = ManageRoomMemberSheetViewModel.mock(canKick: false)
    
    static let unbanOnlyViewModel = ManageRoomMemberSheetViewModel.mock(canKick: true, memberIsBanned: true)

    static let editableRoleViewModel = ManageRoomMemberSheetViewModel.mock(canEditRoles: true, memberPowerLevel: .init(value: 50))

    static let readOnlyRoleViewModel = ManageRoomMemberSheetViewModel.mock(memberPowerLevel: .init(value: 100))

    static let ownUserViewModel = ManageRoomMemberSheetViewModel(memberDetails: .memberDetails(roomMember: .init(withProxy: RoomMemberProxyMock.mockMeAdmin)),
                                                                 permissions: .init(canKick: true,
                                                                                    canBan: true,
                                                                                    canEditRoles: true,
                                                                                    ownPowerLevel: .init(value: 100)),
                                                                 roomProxy: JoinedRoomProxyMock(.init()),
                                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                                 analyticsService: AnalyticsServiceMock(.init()),
                                                                 mediaProvider: MediaProviderMock(.init()))

    static var previews: some View {
        ManageRoomMemberSheetView(context: allActionsViewModel.context)
            .previewDisplayName("All Actions")
        ManageRoomMemberSheetView(context: allActionsDisabledViewModel.context)
            .previewDisplayName("All Actions Disabled")
        ManageRoomMemberSheetView(context: kickOnlyViewModel.context)
            .previewDisplayName("Kick Only")
        ManageRoomMemberSheetView(context: banOnlyViewModel.context)
            .previewDisplayName("Ban Only")
        ManageRoomMemberSheetView(context: unbanOnlyViewModel.context)
            .previewDisplayName("Unban Only")
        ManageRoomMemberSheetView(context: editableRoleViewModel.context)
            .previewDisplayName("Editable Role")
        ManageRoomMemberSheetView(context: readOnlyRoleViewModel.context)
            .previewDisplayName("Read Only Role")
        ManageRoomMemberSheetView(context: ownUserViewModel.context)
            .previewDisplayName("Own User")
    }
}

private extension ManageRoomMemberSheetViewModel {
    static func mock(canKick: Bool = true,
                     canBan: Bool = true,
                     canEditRoles: Bool = false,
                     memberIsBanned: Bool = false,
                     memberPowerLevel: RoomPowerLevel = .init(value: 0),
                     powerLevel: RoomPowerLevel = .init(value: 100)) -> ManageRoomMemberSheetViewModel {
        let member = if memberIsBanned {
            RoomMemberDetails(withProxy: RoomMemberProxyMock.mockBanned[0])
        } else {
            RoomMemberDetails(withProxy: RoomMemberProxyMock(with: .init(userID: "@dan:matrix.org",
                                                                         displayName: "Dan",
                                                                         avatarURL: .mockMXCUserAvatar,
                                                                         membership: .join,
                                                                         powerLevel: memberPowerLevel)))
        }
        return ManageRoomMemberSheetViewModel(memberDetails: .memberDetails(roomMember: member),
                                              permissions: .init(canKick: canKick,
                                                                 canBan: canBan,
                                                                 canEditRoles: canEditRoles,
                                                                 ownPowerLevel: powerLevel),
                                              roomProxy: JoinedRoomProxyMock(.init()),
                                              userIndicatorController: UserIndicatorControllerMock(),
                                              analyticsService: AnalyticsServiceMock(.init()),
                                              mediaProvider: MediaProviderMock(.init()))
    }
}
