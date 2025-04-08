//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ManageRoomMemberSheetView: View {
    @ObservedObject var context: ManageRoomMemberSheetViewModelType.Context
    
    var body: some View {
        Form {
            AvatarHeaderView(member: context.viewState.member,
                             avatarSize: .user(on: .memberDetails),
                             mediaProvider: context.mediaProvider) {
                EmptyView()
            }
            
            Section {
                ListRow(label: .default(title: L10n.screenBottomSheetManageRoomMemberMemberUserInfo,
                                        icon: \.userProfileSolid),
                        kind: .navigationLink {
                            context.send(viewAction: .displayDetails)
                        })
            }
            
            Section {
                if context.viewState.canKick {
                    ListRow(label: .default(title: L10n.screenBottomSheetManageRoomMemberRemove,
                                            icon: \.close,
                                            role: .destructive),
                            kind: .button {
                                context.send(viewAction: .kick)
                            })
                }
                
                if context.viewState.canBan {
                    ListRow(label: .default(title: L10n.screenBottomSheetManageRoomMemberBan,
                                            icon: \.block,
                                            role: .destructive),
                            kind: .button {
                                context.send(viewAction: .ban)
                            })
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
    
    static let kickOnlyViewModel = ManageRoomMemberSheetViewModel.mock(canBan: false)
    
    static let banOnlyViewModel = ManageRoomMemberSheetViewModel.mock(canKick: false)
    
    static var previews: some View {
        ManageRoomMemberSheetView(context: allActionsViewModel.context)
            .previewDisplayName("All Actions")
        ManageRoomMemberSheetView(context: kickOnlyViewModel.context)
            .previewDisplayName("Kick Only")
        ManageRoomMemberSheetView(context: banOnlyViewModel.context)
            .previewDisplayName("Ban Only")
    }
}

private extension ManageRoomMemberSheetViewModel {
    static func mock(canKick: Bool = true,
                     canBan: Bool = true) -> ManageRoomMemberSheetViewModel {
        let member = RoomMemberDetails(withProxy: RoomMemberProxyMock.mockDan)
        return ManageRoomMemberSheetViewModel(member: member,
                                              canKick: canKick,
                                              canBan: canBan,
                                              roomProxy: JoinedRoomProxyMock(.init()),
                                              userIndicatorController: UserIndicatorControllerMock(),
                                              analyticsService: ServiceLocator.shared.analytics,
                                              mediaProvider: MediaProviderMock(configuration: .init()))
    }
}
