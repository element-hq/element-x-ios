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

import SwiftUI

struct RoomDetailsScreen: View {
    @ObservedObject var context: RoomDetailsScreenViewModel.Context
    
    @State private var isTopicExpanded = false
    
    var body: some View {
        Form {
            if let recipient = context.viewState.dmRecipient {
                dmHeaderSection(recipient: recipient)
            } else {
                normalRoomHeaderSection
            }

            topicSection
            
            if context.viewState.showNotificationSettings {
                notificationSection
            }

            if context.viewState.dmRecipient == nil {
                aboutSection
            }

            securitySection

            if let recipient = context.viewState.dmRecipient {
                ignoreUserSection(user: recipient)
            }
            
            leaveRoomSection
        }
        .compoundForm()
        .alert(item: $context.alertInfo)
        .alert(item: $context.leaveRoomAlertItem,
               actions: leaveRoomAlertActions,
               message: leaveRoomAlertMessage)
        .alert(item: $context.ignoreUserRoomAlertItem,
               actions: blockUserAlertActions,
               message: blockUserAlertMessage)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if context.viewState.canEdit {
                    Button(L10n.actionEdit) {
                        context.send(viewAction: .processTapEdit)
                    }
                }
            }
        }
        .track(screen: .roomDetails)
    }
    
    // MARK: - Private
    
    private var normalRoomHeaderSection: some View {
        AvatarHeaderView(avatarUrl: context.viewState.avatarURL,
                         name: context.viewState.title,
                         id: context.viewState.roomId,
                         avatarSize: .room(on: .details),
                         imageProvider: context.imageProvider,
                         subtitle: context.viewState.canonicalAlias) {
            if !context.viewState.shortcuts.isEmpty {
                headerSectionShortcuts
            }
        }
        .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.avatar)
    }
    
    private func dmHeaderSection(recipient: RoomMemberDetails) -> some View {
        AvatarHeaderView(avatarUrl: recipient.avatarURL,
                         name: recipient.name,
                         id: recipient.id,
                         avatarSize: .user(on: .memberDetails),
                         imageProvider: context.imageProvider,
                         subtitle: recipient.id) {
            if !context.viewState.shortcuts.isEmpty {
                headerSectionShortcuts
            }
        }
        .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.dmAvatar)
    }
    
    @ViewBuilder
    private var headerSectionShortcuts: some View {
        HStack(spacing: 32) {
            ForEach(context.viewState.shortcuts, id: \.self) { shortcut in
                switch shortcut {
                case .mute:
                    toggleMuteButton
                case .share(let permalink):
                    ShareLink(item: permalink) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(FormActionButtonStyle(title: L10n.actionShare))
                }
            }
        }
        .padding(.top, 32)
    }
    
    @ViewBuilder
    private var topicSection: some View {
        if context.viewState.hasTopicSection {
            Section {
                if let topic = context.viewState.topic, !topic.isEmpty {
                    Text(topic)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodyMD)
                        .lineLimit(isTopicExpanded ? nil : 3)
                        .onTapGesture { isTopicExpanded.toggle() }
                } else {
                    Button {
                        context.send(viewAction: .processTapAddTopic)
                    } label: {
                        Text(L10n.screenRoomDetailsAddTopicTitle)
                    }
                    .buttonStyle(.compoundForm())
                    .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.addTopic)
                }
            } header: {
                Text(L10n.commonTopic)
                    .compoundFormSectionHeader()
            }
            .compoundFormSection()
        }
    }

    private var aboutSection: some View {
        Section {
            Button {
                context.send(viewAction: .processTapPeople)
            } label: {
                LabeledContent {
                    Text(String(context.viewState.joinedMembersCount))
                } label: {
                    Label(L10n.commonPeople, systemImage: "person")
                }
            }
            .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.people)
            
            if context.viewState.canInviteUsers {
                Button {
                    context.send(viewAction: .processTapInvite)
                } label: {
                    Label(L10n.screenRoomDetailsInvitePeopleTitle, systemImage: "person.badge.plus")
                }
                .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.invite)
            }
        }
        .buttonStyle(.compoundForm(accessory: .navigationLink))
        .compoundFormSection()
    }
    
    @ViewBuilder
    private var notificationSection: some View {
        Section {
            Button {
                context.send(viewAction: .processTapNotifications)
            } label: {
                LabeledContent {
                    if context.viewState.notificationSettingsState.isLoading {
                        ProgressView()
                    } else if context.viewState.notificationSettingsState.isError {
                        Image(systemName: "exclamationmark.circle")
                    } else {
                        Text(context.viewState.notificationSettingsState.label)
                    }
                } label: {
                    Label(L10n.screenRoomDetailsNotificationTitle, systemImage: "bell")
                }
            }
            .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.notifications)
        }
        .buttonStyle(.compoundForm(accessory: context.viewState.notificationSettingsState.isLoaded ? .navigationLink : nil))
        .disabled(context.viewState.notificationSettingsState.isLoading)
    }
    
    @ViewBuilder
    private var toggleMuteButton: some View {
        Button {
            context.send(viewAction: .processToogleMuteNotifications)
        } label: {
            if context.viewState.isProcessingMuteToggleAction {
                ProgressView()
            } else {
                context.viewState.notificationShortcutButtonImage
            }
        }
        .buttonStyle(FormActionButtonStyle(title: context.viewState.notificationShortcutButtonTitle))
        .disabled(context.viewState.isProcessingMuteToggleAction)
    }

    @ViewBuilder
    private var securitySection: some View {
        if context.viewState.isEncrypted {
            Section {
                Label {
                    Text(L10n.screenRoomDetailsEncryptionEnabledTitle)
                } icon: {
                    Image(systemName: "lock.shield")
                }
                .labelStyle(.compoundFormRow(secondaryText: L10n.screenRoomDetailsEncryptionEnabledSubtitle,
                                             alignment: .top))
            } header: {
                Text(L10n.commonSecurity)
                    .compoundFormSectionHeader()
            }
            .compoundFormSection()
        }
    }

    private var leaveRoomSection: some View {
        Section {
            Button(role: .destructive) {
                context.send(viewAction: .processTapLeave)
            } label: {
                Label(L10n.actionLeaveRoom, systemImage: "door.right.hand.open")
            }
            .buttonStyle(.compoundForm())
        }
        .compoundFormSection()
    }
    
    private func ignoreUserSection(user: RoomMemberDetails) -> some View {
        Section {
            Button(role: user.isIgnored ? nil : .destructive) {
                context.send(viewAction: user.isIgnored ? .processTapUnignore : .processTapIgnore)
            } label: {
                LabeledContent {
                    if context.viewState.isProcessingIgnoreRequest {
                        ProgressView()
                    }
                } label: {
                    Label(user.isIgnored ? L10n.screenDmDetailsUnblockUser : L10n.screenDmDetailsBlockUser,
                          systemImage: "slash.circle")
                }
            }
            .buttonStyle(.compoundForm())
            .disabled(context.viewState.isProcessingIgnoreRequest)
        }
        .compoundFormSection()
    }

    @ViewBuilder
    private func leaveRoomAlertActions(_ item: LeaveRoomAlertItem) -> some View {
        Button(item.cancelTitle, role: .cancel) { }
        Button(item.confirmationTitle, role: .destructive) {
            context.send(viewAction: .confirmLeave)
        }
    }

    private func leaveRoomAlertMessage(_ item: LeaveRoomAlertItem) -> some View {
        Text(item.subtitle)
    }

    @ViewBuilder
    private func blockUserAlertActions(_ item: RoomDetailsScreenViewStateBindings.IgnoreUserAlertItem) -> some View {
        Button(item.cancelTitle, role: .cancel) { }
        Button(item.confirmationTitle,
               role: item.action == .ignore ? .destructive : nil) {
            context.send(viewAction: item.viewAction)
        }
    }

    private func blockUserAlertMessage(_ item: RoomDetailsScreenViewStateBindings.IgnoreUserAlertItem) -> some View {
        Text(item.description)
    }
}

// MARK: - Previews

struct RoomDetailsScreen_Previews: PreviewProvider {
    static let genericRoomViewModel = {
        let members: [RoomMemberProxyMock] = [
            .mockAlice,
            .mockBob,
            .mockCharlie
        ]
        let roomProxy = RoomProxyMock(with: .init(displayName: "Room A",
                                                  topic: "Bacon ipsum dolor amet short ribs buffalo pork loin cupim frankfurter. Burgdoggen pig shankle biltong flank ham jowl sirloin bacon cow. T-bone alcatra boudin beef spare ribs pig fatback jerky swine short ribs shankle chislic frankfurter pork loin. Chicken tri-tip bresaola t-bone pastrami brisket.", // swiftlint:disable:this line_length
                                                  isDirect: false,
                                                  isEncrypted: true,
                                                  canonicalAlias: "#alias:domain.com",
                                                  members: members))
        
        var notificationSettingsProxyMockConfiguration = NotificationSettingsProxyMockConfiguration()
        notificationSettingsProxyMockConfiguration.roomMode.isDefault = false
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: notificationSettingsProxyMockConfiguration)
        let appSettings = AppSettings()
        appSettings.notificationSettingsEnabled = true
        
        return RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                          roomProxy: roomProxy,
                                          mediaProvider: MockMediaProvider(),
                                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                          notificationSettingsProxy: notificationSettingsProxy,
                                          appSettings: appSettings)
    }()
    
    static let dmRoomViewModel = {
        let members: [RoomMemberProxyMock] = [
            .mockMe,
            .mockDan
        ]
        
        let roomProxy = RoomProxyMock(with: .init(displayName: "DM Room",
                                                  topic: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                                                  isDirect: true,
                                                  isEncrypted: true,
                                                  canonicalAlias: "#alias:domain.com",
                                                  members: members,
                                                  activeMembersCount: 2))
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        let appSettings = AppSettings()
        
        return RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                          roomProxy: roomProxy,
                                          mediaProvider: MockMediaProvider(),
                                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                          notificationSettingsProxy: notificationSettingsProxy,
                                          appSettings: appSettings)
    }()
    
    static let simpleRoomViewModel = {
        let members: [RoomMemberProxyMock] = [
            .mockAlice,
            .mockBob,
            .mockCharlie
        ]
        let roomProxy = RoomProxyMock(with: .init(displayName: "Room A",
                                                  isDirect: false,
                                                  isEncrypted: false,
                                                  members: members))
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        let appSettings = AppSettings()
        
        return RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                          roomProxy: roomProxy,
                                          mediaProvider: MockMediaProvider(),
                                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                          notificationSettingsProxy: notificationSettingsProxy,
                                          appSettings: appSettings)
    }()
    
    static var previews: some View {
        RoomDetailsScreen(context: genericRoomViewModel.context)
            .previewDisplayName("Generic Room")
        RoomDetailsScreen(context: dmRoomViewModel.context)
            .previewDisplayName("DM Room")
        RoomDetailsScreen(context: simpleRoomViewModel.context)
            .previewDisplayName("Simple Room")
    }
}
