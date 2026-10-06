//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ModerationAndSafetySettingsScreen: View {
    @Bindable var context: ModerationAndSafetySettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            sharePresenceSection
            invitesSection
            timelineMediaSection
            blockedUsersSection
        }
        .compoundList()
        .navigationTitle(L10n.commonModerationAndSafety)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var sharePresenceSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenAdvancedSettingsSharePresence,
                                  description: L10n.screenAdvancedSettingsSharePresenceDescription),
                    kind: .toggle($context.sharePresence))
        } header: {
            Text(L10n.screenModerationAndSafetySharePresenceHeading)
                .compoundListSectionHeader()
        }
    }
    
    @ViewBuilder
    private var invitesSection: some View {
        let binding = Binding(get: {
            context.viewState.hideInviteAvatars
        }, set: { newValue in
            context.send(viewAction: .updateHideInviteAvatars(newValue))
        })
        
        Section {
            ListRow(label: .plain(title: L10n.screenAdvancedSettingsHideInviteAvatarsToggleTitle),
                    details: context.viewState.isWaitingHideInviteAvatars ? .isWaiting(true) : nil,
                    kind: .toggle(binding))
                .disabled(context.viewState.isWaitingHideInviteAvatars)
        } header: {
            Text(L10n.screenModerationAndSafetyInvitesHeading)
                .compoundListSectionHeader()
        }
    }
    
    @ViewBuilder
    private var timelineMediaSection: some View {
        let binding = Binding(get: {
            context.viewState.timelineMediaVisibility
        }, set: { newValue in
            context.send(viewAction: .updateTimelineMediaVisibility(newValue))
        })
        
        Section {
            ListRow(label: .plain(title: L10n.screenAdvancedSettingsShowMediaTimelineTitle),
                    details: .isWaiting(context.viewState.isWaitingTimelineMediaVisibility),
                    kind: .inlinePicker(selection: binding,
                                        items: TimelineMediaVisibility.items))
                .disabled(context.viewState.isWaitingTimelineMediaVisibility)
        } header: {
            Text(L10n.screenAdvancedSettingsShowMediaTimelineTitle)
                .compoundListSectionHeader()
        } footer: {
            Text(L10n.screenAdvancedSettingsShowMediaTimelineSubtitle)
                .compoundListSectionFooter()
        }
    }
    
    @ViewBuilder
    private var blockedUsersSection: some View {
        if context.viewState.showBlockedUsers {
            Section {
                ListRow(label: .default(title: L10n.commonBlockedUsers,
                                        icon: \.block),
                        kind: .navigationLink {
                            context.send(viewAction: .blockedUsers)
                        })
            }
        }
    }
}

// MARK: - Previews

struct ModerationAndSafetySettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = ModerationAndSafetySettingsScreenViewModel(userSession: UserSessionMock(.init()),
                                                                      userIndicatorController: UserIndicatorControllerMock())
    
    static var previews: some View {
        ElementNavigationStack {
            ModerationAndSafetySettingsScreen(context: viewModel.context)
        }
        .snapshotPreferences(expect: viewModel.context.observe(\.viewState.showBlockedUsers))
    }
}

private extension TimelineMediaVisibility {
    static var items: [(title: String, tag: TimelineMediaVisibility)] {
        [(title: L10n.screenAdvancedSettingsShowMediaTimelineAlwaysHide, tag: .never),
         (title: L10n.screenAdvancedSettingsShowMediaTimelinePrivateRooms, tag: .privateOnly),
         (title: L10n.screenAdvancedSettingsShowMediaTimelineAlwaysShow, tag: .always)]
    }
}
