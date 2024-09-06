//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
                        RoomChangeRolesScreenSelectedItem(member: member, mediaProvider: context.mediaProvider) {
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
                                       roomProxy: JoinedRoomProxyMock(.init(members: .allMembersAsAdmin)),
                                       mediaProvider: MockMediaProvider(),
                                       userIndicatorController: UserIndicatorControllerMock(),
                                       analytics: ServiceLocator.shared.analytics)
    }
}
