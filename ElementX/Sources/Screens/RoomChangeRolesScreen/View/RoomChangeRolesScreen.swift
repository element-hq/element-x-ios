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

struct RoomChangeRolesScreen: View {
    @ObservedObject var context: RoomChangeRolesScreenViewModel.Context
    
    var showTopSection: Bool { !context.viewState.membersWithRole.isEmpty }
    
    var body: some View {
        mainContent
            .compoundList()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(context.viewState.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(context.viewState.hasChanges)
            .toolbar { toolbar }
            .searchController(query: $context.searchQuery,
                              placeholder: L10n.commonSearchForSomeone,
                              showsCancelButton: false,
                              disablesInteractiveDismiss: true)
            .compoundSearchField()
            .alert(item: $context.alertInfo)
    }
    
    // MARK: - Private
    
    private var mainContent: some View {
        GeometryReader { proxy in
            Form {
                if showTopSection {
                    // this is a fix for having the carousel not clipped, and inside the form, so when the search is dismissed, it wont break the design
                    Section {
                        EmptyView()
                    } header: {
                        membersWithRoleSection
                            .textCase(.none)
                            .frame(width: proxy.size.width)
                    }
                }
                
                RoomChangeRolesScreenSection(members: context.viewState.visibleAdministrators,
                                             title: L10n.screenRoomChangeRoleSectionAdministrators,
                                             isAdministratorsSection: true,
                                             context: context)
                RoomChangeRolesScreenSection(members: context.viewState.visibleModerators,
                                             title: L10n.screenRoomChangeRoleSectionModerators,
                                             context: context)
                RoomChangeRolesScreenSection(members: context.viewState.visibleUsers,
                                             title: L10n.screenRoomChangeRoleSectionUsers,
                                             context: context)
            }
        }
    }
    
    @ScaledMetric private var cellWidth: CGFloat = 72
    private var membersWithRoleSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scrollView in
                HStack(spacing: 16) {
                    ForEach(context.viewState.membersWithRole, id: \.id) { member in
                        RoomChangeRolesScreenSelectedItem(member: member,
                                                          imageProvider: context.dependencies?.imageProvider,
                                                          networkMonitor: context.dependencies?.networkMonitor) {
                            context.send(viewAction: .demoteMember(member))
                        }
                        .frame(width: cellWidth)
                    }
                }
                .onChange(of: context.viewState.lastPromotedMember) { member in
                    guard let member else { return }
                    withElementAnimation(.easeInOut) {
                        scrollView.scrollTo(member.id)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
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

struct RoomChangeRolesScreen_Previews: PreviewProvider, TestablePreview {
    static let administratorViewModel = makeViewModel(mode: .administrator)
    static let moderatorViewModel = makeViewModel(mode: .moderator)
    
    static var previews: some View {
        NavigationStack {
            RoomChangeRolesScreen(context: administratorViewModel.context)
        }
        .previewDisplayName("Administrators")
        
        NavigationStack {
            RoomChangeRolesScreen(context: moderatorViewModel.context)
        }
        .previewDisplayName("Moderators")
    }
    
    static func makeViewModel(mode: RoomMemberDetails.Role) -> RoomChangeRolesScreenViewModel {
        RoomChangeRolesScreenViewModel(mode: mode,
                                       roomProxy: RoomProxyMock(.init(members: .allMembersAsAdmin)),
                                       mediaProvider: MockMediaProvider(),
                                       networkMonitor: NetworkMonitorMock.default,
                                       userIndicatorController: UserIndicatorControllerMock(),
                                       analytics: ServiceLocator.shared.analytics)
    }
}
