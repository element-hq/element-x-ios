//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomChangePermissionsScreen: View {
    @Bindable var context: RoomChangePermissionsScreenViewModel.Context
    
    var body: some View {
        Form {
            ForEach(RoomChangePermissionsScreenGroup.allCases, id: \.self) { group in
                section(for: group)
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenRoomChangePermissionsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(context.viewState.hasChanges)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
    }
    
    @ViewBuilder
    private func section(for group: RoomChangePermissionsScreenGroup) -> some View {
        if let settings = Binding($context.settings[group]) {
            Section {
                ForEach(settings) { $setting in
                    ListRow(label: .plain(title: setting.title),
                            kind: .picker(selection: $setting.roleValue,
                                          items: setting.availableValues))
                        .disabled(setting.isDisabled)
                }
            } header: {
                Text(group.name)
                    .compoundListSectionHeader()
            }
        }
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
    static let roomViewModel = makeViewModel(isSpace: false)
    static let roomAsUserViewModel = makeViewModel(isSpace: false, ownPowerLevel: RoomRole.user.powerLevel)
    static let spaceViewModel = makeViewModel(isSpace: true)
    
    static var previews: some View {
        NavigationStack {
            RoomChangePermissionsScreen(context: roomViewModel.context)
        }
        .previewDisplayName("Room")
        
        NavigationStack {
            RoomChangePermissionsScreen(context: roomAsUserViewModel.context)
        }
        .previewDisplayName("Room as User")
        
        NavigationStack {
            RoomChangePermissionsScreen(context: spaceViewModel.context)
        }
        .previewDisplayName("Space")
    }
    
    static func makeViewModel(isSpace: Bool, ownPowerLevel: RoomPowerLevel = RoomRole.creator.powerLevel) -> RoomChangePermissionsScreenViewModel {
        RoomChangePermissionsScreenViewModel(currentPermissions: .init(powerLevels: .mock),
                                             ownPowerLevel: ownPowerLevel,
                                             roomProxy: JoinedRoomProxyMock(.init(isSpace: isSpace)),
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             analytics: ServiceLocator.shared.analytics)
    }
}
