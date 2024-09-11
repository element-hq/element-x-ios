//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomDetailsScreen: View {
    @ObservedObject var context: RoomDetailsScreenViewModel.Context
    
    @State private var isTopicExpanded = false
    
    var body: some View {
        Form {
            if let recipient = context.viewState.dmRecipient,
               let accountOwner = context.viewState.accountOwner {
                dmHeaderSection(accountOwner: accountOwner,
                                recipient: recipient)
            } else {
                normalRoomHeaderSection
            }

            topicSection
            
            configurationSection

            aboutSection

            securitySection

            if let recipient = context.viewState.dmRecipient {
                ignoreUserSection(user: recipient)
            }
            
            leaveRoomSection
        }
        .compoundList()
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
        .navigationTitle(L10n.screenRoomDetailsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .track(screen: .RoomDetails)
        .interactiveQuickLook(item: $context.mediaPreviewItem, allowEditing: false)
    }
    
    // MARK: - Private
    
    private var normalRoomHeaderSection: some View {
        AvatarHeaderView(room: context.viewState.details,
                         avatarSize: .room(on: .details),
                         mediaProvider: context.mediaProvider) {
            context.send(viewAction: .displayAvatar)
        } footer: {
            if !context.viewState.shortcuts.isEmpty {
                headerSectionShortcuts
            }
        }
        .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.avatar)
    }
    
    private func dmHeaderSection(accountOwner: RoomMemberDetails, recipient: RoomMemberDetails) -> some View {
        AvatarHeaderView(accountOwner: accountOwner,
                         dmRecipient: recipient,
                         mediaProvider: context.mediaProvider) {
            context.send(viewAction: .displayAvatar)
        } footer: {
            if !context.viewState.shortcuts.isEmpty {
                headerSectionShortcuts
            }
        }
        .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.dmAvatar)
    }
    
    @ViewBuilder
    private var headerSectionShortcuts: some View {
        HStack(spacing: 8) {
            ForEach(context.viewState.shortcuts, id: \.self) { shortcut in
                switch shortcut {
                case .mute:
                    toggleMuteButton
                case .share(let permalink):
                    ShareLink(item: permalink) {
                        CompoundIcon(\.shareIos)
                    }
                    .buttonStyle(FormActionButtonStyle(title: L10n.actionShare))
                case .call:
                    Button {
                        context.send(viewAction: .processTapCall)
                    } label: {
                        CompoundIcon(\.videoCall)
                    }
                    .buttonStyle(FormActionButtonStyle(title: L10n.actionCall))
                case .invite:
                    Button {
                        context.send(viewAction: .processTapInvite)
                    } label: {
                        CompoundIcon(\.userAdd)
                    }
                    .buttonStyle(FormActionButtonStyle(title: L10n.actionInvite))
                }
            }
        }
        .padding(.top, 32)
    }
    
    @ViewBuilder
    private var topicSection: some View {
        if context.viewState.hasTopicSection {
            Section {
                if let topic = context.viewState.topic, !topic.characters.isEmpty, let topicSummary = context.viewState.topicSummary {
                    ListRow(kind: .custom {
                        Text(isTopicExpanded ? topic : topicSummary)
                            .font(.compound.bodySM)
                            .foregroundColor(.compound.textSecondary)
                            .lineLimit(isTopicExpanded ? nil : 3)
                            .accentColor(.compound.textLinkExternal)
                            .padding(ListRowPadding.insets)
                            .textSelection(.enabled)
                    })
                    .onTapGesture {
                        isTopicExpanded.toggle()
                    }
                } else {
                    ListRow(label: .plain(title: L10n.screenRoomDetailsAddTopicTitle),
                            kind: .button { context.send(viewAction: .processTapAddTopic) })
                        .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.addTopic)
                }
            } header: {
                Text(L10n.commonTopic)
                    .compoundListSectionHeader()
            }
        }
    }

    private var aboutSection: some View {
        Section {
            if context.viewState.dmRecipient == nil {
                ListRow(label: .default(title: L10n.commonPeople,
                                        icon: \.user),
                        details: .title(String(context.viewState.joinedMembersCount)),
                        kind: .navigationLink {
                            context.send(viewAction: .processTapPeople)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.people)
            }
            ListRow(label: .default(title: L10n.screenPollsHistoryTitle,
                                    icon: \.polls),
                    kind: .navigationLink {
                        context.send(viewAction: .processTapPolls)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.pollsHistory)
        }
    }
    
    private var configurationSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenRoomDetailsNotificationTitle,
                                    icon: \.notifications),
                    details: context.viewState.notificationSettingsState.isLoading ? .isWaiting(true)
                        : context.viewState.notificationSettingsState.isError ? .systemIcon(.exclamationmarkCircle)
                        : .title(context.viewState.notificationSettingsState.label),
                    kind: .navigationLink {
                        context.send(viewAction: .processTapNotifications)
                    })
                    .disabled(context.viewState.notificationSettingsState.isLoading)
                    .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.notifications)
            
            ListRow(label: .default(title: L10n.commonFavourite, icon: \.favourite),
                    kind: .toggle($context.isFavourite))
                .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.favourite)
                .onChange(of: context.isFavourite) { newValue in
                    context.send(viewAction: .toggleFavourite(isFavourite: newValue))
                }
            
            if context.viewState.isPinningEnabled {
                ListRow(label: .default(title: L10n.screenRoomDetailsPinnedEventsRowTitle,
                                        icon: \.pin),
                        details: context.viewState.pinnedEventsActionState.isLoading ? .isWaiting(true) : .title(context.viewState.pinnedEventsActionState.count),
                        kind: context.viewState.pinnedEventsActionState.isLoading ? .label : .navigationLink(action: {
                            context.send(viewAction: .processTapPinnedEvents)
                        }))
                        .disabled(context.viewState.pinnedEventsActionState.isLoading)
            }
            
            if context.viewState.canEditRolesOrPermissions, context.viewState.dmRecipient == nil {
                ListRow(label: .default(title: L10n.screenRoomDetailsRolesAndPermissions,
                                        icon: \.admin),
                        kind: .navigationLink {
                            context.send(viewAction: .processTapRolesAndPermissions)
                        })
            }
        }
        .disabled(context.viewState.notificationSettingsState.isLoading)
    }
    
    private var toggleMuteButton: some View {
        Button {
            context.send(viewAction: .processToggleMuteNotifications)
        } label: {
            if context.viewState.isProcessingMuteToggleAction {
                ProgressView()
            } else {
                CompoundIcon(context.viewState.notificationShortcutButtonIcon)
            }
        }
        .buttonStyle(FormActionButtonStyle(title: context.viewState.notificationShortcutButtonTitle))
        .disabled(context.viewState.isProcessingMuteToggleAction)
    }
    
    @ViewBuilder
    private var securitySection: some View {
        if context.viewState.isEncrypted {
            Section {
                ListRow(label: .default(title: L10n.screenRoomDetailsEncryptionEnabledTitle,
                                        description: L10n.screenRoomDetailsEncryptionEnabledSubtitle,
                                        icon: \.lock,
                                        iconAlignment: .top),
                        kind: .label)
            } header: {
                Text(L10n.commonSecurity)
                    .compoundListSectionHeader()
            }
        }
    }
    
    private var leaveRoomTitle: String {
        context.viewState.dmRecipient == nil ? L10n.screenRoomDetailsLeaveRoomTitle : L10n.screenRoomDetailsLeaveConversationTitle
    }

    private var leaveRoomSection: some View {
        Section {
            ListRow(label: .action(title: leaveRoomTitle,
                                   icon: \.leave,
                                   role: .destructive),
                    kind: .button { context.send(viewAction: .processTapLeave) })
        }
    }
    
    private func ignoreUserSection(user: RoomMemberDetails) -> some View {
        Section {
            ListRow(label: .default(title: user.isIgnored ? L10n.screenDmDetailsUnblockUser : L10n.screenDmDetailsBlockUser,
                                    icon: \.block,
                                    role: user.isIgnored ? nil : .destructive),
                    details: .isWaiting(context.viewState.isProcessingIgnoreRequest),
                    kind: .button {
                        context.send(viewAction: user.isIgnored ? .processTapUnignore : .processTapIgnore)
                    })
                    .disabled(context.viewState.isProcessingIgnoreRequest)
        }
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

struct RoomDetailsScreen_Previews: PreviewProvider, TestablePreview {
    static let genericRoomViewModel = {
        let members: [RoomMemberProxyMock] = [
            .mockMeAdmin,
            .mockAlice,
            .mockBob,
            .mockCharlie
        ]
        let roomProxy = JoinedRoomProxyMock(.init(id: "room_a_id",
                                                  name: "Room A",
                                                  topic: """
                                                  Discussions about Element X iOS | https://github.com/vector-im/element-x-ios
                                                  
                                                  Feature Status: https://github.com/vector-im/element-x-ios/issues/1225
                                                  
                                                  App Store: https://apple.co/3r6LJHZ
                                                  TestFlight: https://testflight.apple.com/join/uZbeZCOi
                                                  """,
                                                  isDirect: false,
                                                  isEncrypted: true,
                                                  canonicalAlias: "#alias:domain.com",
                                                  members: members))
        
        var notificationSettingsProxyMockConfiguration = NotificationSettingsProxyMockConfiguration()
        notificationSettingsProxyMockConfiguration.roomMode.isDefault = false
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: notificationSettingsProxyMockConfiguration)
        let appSettings = AppSettings()
        appSettings.pinningEnabled = true
        
        return RoomDetailsScreenViewModel(roomProxy: roomProxy,
                                          clientProxy: ClientProxyMock(.init()),
                                          mediaProvider: MockMediaProvider(),
                                          analyticsService: ServiceLocator.shared.analytics,
                                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                          notificationSettingsProxy: notificationSettingsProxy,
                                          attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                          appMediator: AppMediatorMock.default,
                                          appSettings: appSettings)
    }()
    
    static let dmRoomViewModel = {
        let members: [RoomMemberProxyMock] = [
            .mockMe,
            .mockDan
        ]
        
        let roomProxy = JoinedRoomProxyMock(.init(id: "dm_room_id",
                                                  name: "DM Room",
                                                  topic: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                                                  isDirect: true,
                                                  isEncrypted: true,
                                                  canonicalAlias: "#alias:domain.com",
                                                  members: members))
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        let appSettings = AppSettings()
        appSettings.pinningEnabled = true
        
        return RoomDetailsScreenViewModel(roomProxy: roomProxy,
                                          clientProxy: ClientProxyMock(.init()),
                                          mediaProvider: MockMediaProvider(),
                                          analyticsService: ServiceLocator.shared.analytics,
                                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                          notificationSettingsProxy: notificationSettingsProxy,
                                          attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                          appMediator: AppMediatorMock.default,
                                          appSettings: appSettings)
    }()
    
    static let simpleRoomViewModel = {
        let members: [RoomMemberProxyMock] = [
            .mockMeAdmin,
            .mockAlice,
            .mockBob,
            .mockCharlie
        ]
        let roomProxy = JoinedRoomProxyMock(.init(id: "simple_room_id",
                                                  name: "Room A",
                                                  isDirect: false,
                                                  isEncrypted: false,
                                                  members: members))
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        let appSettings = AppSettings()
        appSettings.pinningEnabled = true
        
        return RoomDetailsScreenViewModel(roomProxy: roomProxy,
                                          clientProxy: ClientProxyMock(.init()),
                                          mediaProvider: MockMediaProvider(),
                                          analyticsService: ServiceLocator.shared.analytics,
                                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                          notificationSettingsProxy: notificationSettingsProxy,
                                          attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                          appMediator: AppMediatorMock.default,
                                          appSettings: appSettings)
    }()
    
    static var previews: some View {
        RoomDetailsScreen(context: simpleRoomViewModel.context)
            .previewDisplayName("Simple Room")
            .snapshotPreferences(delay: 2)
        RoomDetailsScreen(context: dmRoomViewModel.context)
            .previewDisplayName("DM Room")
            .snapshotPreferences(delay: 0.25)
        RoomDetailsScreen(context: genericRoomViewModel.context)
            .previewDisplayName("Generic Room")
            .snapshotPreferences(delay: 0.25)
    }
}
