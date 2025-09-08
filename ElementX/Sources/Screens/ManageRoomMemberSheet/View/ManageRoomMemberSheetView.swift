//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
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
                                 mediaProvider: context.mediaProvider) {
                    EmptyView()
                }
            case .loadingMemberDetails(let sender):
                AvatarHeaderView(sender: sender,
                                 avatarSize: .user(on: .memberDetails),
                                 mediaProvider: context.mediaProvider) {
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
            }
            
            Section {
                if context.viewState.permissions.canKick {
                    ListRow(label: .default(title: L10n.screenBottomSheetManageRoomMemberRemove,
                                            icon: \.close,
                                            role: .destructive),
                            kind: .button {
                                context.send(viewAction: .kick)
                            })
                            .disabled(context.viewState.isKickDisabled)
                }
                
                if context.viewState.permissions.canBan {
                    let title = context.viewState.isMemberBanned ? L10n.screenBottomSheetManageRoomMemberUnban : L10n.screenBottomSheetManageRoomMemberBan
                    let icon: KeyPath<CompoundIcons, Image> = context.viewState.isMemberBanned ? \.restart : \.block
                    let action: ManageRoomMemberSheetViewAction = context.viewState.isMemberBanned ? .unban : .ban
                    
                    ListRow(label: .default(title: title,
                                            icon: icon,
                                            role: .destructive),
                            kind: .button {
                                context.send(viewAction: action)
                            })
                            .disabled(context.viewState.isBanUnbanDisabled)
                }
            }
        }
        .compoundList()
        .scrollBounceBehavior(.basedOnSize)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large, .fraction(0.67)]) // Maybe find a way to use the ideal height somehow?
        .alert(item: $context.alertInfo)
    }
}

struct ManageRoomMemberSheetView_Previews: PreviewProvider, TestablePreview {
    static let allActionsViewModel = ManageRoomMemberSheetViewModel.mock()
    
    static let allActionsDisabledViewModel = ManageRoomMemberSheetViewModel.mock(powerLevel: .init(value: 0))
    
    static let kickOnlyViewModel = ManageRoomMemberSheetViewModel.mock(canBan: false)
    
    static let banOnlyViewModel = ManageRoomMemberSheetViewModel.mock(canKick: false)
    
    static let unbanOnlyViewModel = ManageRoomMemberSheetViewModel.mock(canKick: false, memberIsBanned: true)
    
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
    }
}

private extension ManageRoomMemberSheetViewModel {
    static func mock(canKick: Bool = true,
                     canBan: Bool = true,
                     memberIsBanned: Bool = false,
                     powerLevel: RoomPowerLevel = .init(value: 100)) -> ManageRoomMemberSheetViewModel {
        let member = if memberIsBanned {
            RoomMemberDetails(withProxy: RoomMemberProxyMock.mockBanned[0])
        } else {
            RoomMemberDetails(withProxy: RoomMemberProxyMock.mockDan)
        }
        return ManageRoomMemberSheetViewModel(memberDetails: .memberDetails(roomMember: member),
                                              permissions: .init(canKick: canKick,
                                                                 canBan: canBan,
                                                                 ownPowerLevel: powerLevel),
                                              roomProxy: JoinedRoomProxyMock(.init()),
                                              userIndicatorController: UserIndicatorControllerMock(),
                                              analyticsService: ServiceLocator.shared.analytics,
                                              mediaProvider: MediaProviderMock(configuration: .init()))
    }
}
