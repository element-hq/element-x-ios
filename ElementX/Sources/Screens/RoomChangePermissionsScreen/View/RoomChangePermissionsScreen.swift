//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
                                             roomProxy: RoomProxyMock(.init()),
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             analytics: ServiceLocator.shared.analytics)
    }
}
