//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomChangeRolesScreen: View {
    @Bindable var context: RoomChangeRolesScreenViewModel.Context
    
    var showTopSection: Bool {
        !context.viewState.membersWithRole.isEmpty
    }
    
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
                
                RoomChangeRolesScreenSection(members: context.viewState.visibleOwners,
                                             role: .owner,
                                             context: context)
                
                RoomChangeRolesScreenSection(members: context.viewState.visibleAdministrators,
                                             role: .administrator,
                                             context: context)
                RoomChangeRolesScreenSection(members: context.viewState.visibleModerators,
                                             role: .moderator,
                                             context: context)
                RoomChangeRolesScreenSection(members: context.viewState.visibleUsers,
                                             role: .user,
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
                        let dismissAction = context.viewState.isMemberDisabled(member) ? nil : {
                            context.send(viewAction: .demoteMember(member))
                        }
                        RoomChangeRolesScreenSelectedItem(member: member, mediaProvider: context.mediaProvider,
                                                          dismissAction: dismissAction)
                            .frame(width: cellWidth)
                    }
                }
                .onChange(of: context.viewState.lastPromotedMember) { _, newValue in
                    guard let member = newValue else { return }
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
            ToolbarButton(role: .save) {
                context.send(viewAction: .save)
            }
            .disabled(!context.viewState.hasChanges)
        }
        
        if context.viewState.mode == .owner || context.viewState.hasChanges {
            ToolbarItem(placement: .cancellationAction) {
                ToolbarButton(role: .cancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
    }
}

// MARK: - Previews

struct RoomChangeRolesScreen_Previews: PreviewProvider, TestablePreview {
    static let ownerViewModel = makeViewModel(mode: .owner, ownRole: .creator)
    static let administratorOrOwnerViewModel = makeViewModel(mode: .administrator, ownRole: .creator)
    static let administratorViewModel = makeViewModel(mode: .administrator, ownRole: .administrator)
    static let moderatorViewModel = makeViewModel(mode: .moderator, ownRole: .administrator)
    
    static var previews: some View {
        NavigationStack {
            RoomChangeRolesScreen(context: ownerViewModel.context)
        }
        .previewDisplayName("Owners")
        
        NavigationStack {
            RoomChangeRolesScreen(context: administratorOrOwnerViewModel.context)
        }
        .previewDisplayName("Administrator or Owners")
        
        NavigationStack {
            RoomChangeRolesScreen(context: administratorViewModel.context)
        }
        .previewDisplayName("Administrators")
        
        NavigationStack {
            RoomChangeRolesScreen(context: moderatorViewModel.context)
        }
        .previewDisplayName("Moderators")
    }
    
    static func makeViewModel(mode: RoomRole, ownRole: RoomRole) -> RoomChangeRolesScreenViewModel {
        let members: [RoomMemberProxyMock] = switch ownRole {
        case .creator:
            .allMembersAsCreator
        default:
            .allMembersAsAdminV2
        }
        
        return RoomChangeRolesScreenViewModel(mode: mode,
                                              roomProxy: JoinedRoomProxyMock(.init(members: members)),
                                              mediaProvider: MediaProviderMock(configuration: .init()),
                                              userIndicatorController: UserIndicatorControllerMock(),
                                              analytics: ServiceLocator.shared.analytics)
    }
}
