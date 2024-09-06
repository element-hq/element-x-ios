//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomChangePermissionsScreen: View {
    @ObservedObject var context: RoomChangePermissionsScreenViewModel.Context
    
    var body: some View {
        Form {
            ForEach($context.settings) { $setting in
                Section {
                    ListRow(label: .plain(title: setting.title),
                            kind: .inlinePicker(selection: $setting.value, items: setting.allValues))
                } header: {
                    Text(setting.title)
                        .compoundListSectionHeader()
                }
            }
        }
        .compoundList()
        .navigationTitle(context.viewState.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(context.viewState.hasChanges)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionSave) {
                context.send(viewAction: .save)
            }
            .disabled(!context.viewState.hasChanges)
        }
        
        if context.viewState.hasChanges {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
    }
}

// MARK: - Previews

struct RoomChangePermissionsScreen_Previews: PreviewProvider, TestablePreview {
    static let detailsViewModel = makeViewModel(group: .roomDetails)
    static let messagesViewModel = makeViewModel(group: .messagesAndContent)
    static let membersViewModel = makeViewModel(group: .memberModeration)
    
    static var previews: some View {
        NavigationStack {
            RoomChangePermissionsScreen(context: detailsViewModel.context)
        }
        .previewDisplayName("Room details")
        
        NavigationStack {
            RoomChangePermissionsScreen(context: messagesViewModel.context)
        }
        .previewDisplayName("Messages and Content")
        
        NavigationStack {
            RoomChangePermissionsScreen(context: membersViewModel.context)
        }
        .previewDisplayName("Member moderation")
    }
    
    static func makeViewModel(group: RoomRolesAndPermissionsScreenPermissionsGroup) -> RoomChangePermissionsScreenViewModel {
        RoomChangePermissionsScreenViewModel(currentPermissions: .init(powerLevels: .mock),
                                             group: group,
                                             roomProxy: JoinedRoomProxyMock(.init()),
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             analytics: ServiceLocator.shared.analytics)
    }
}
