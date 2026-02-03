//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import MatrixRustSDK
import SwiftUI

struct RoomDetailsScreen: View {
    @Bindable var context: RoomDetailsScreenViewModel.Context
    
    @State private var isTopicExpanded = false
    
    var body: some View {
        Form {
            roomHeaderSection

            topicSection
            
            configurationSection
            
            if context.viewState.dmRecipientInfo == nil {
                peopleSection
            }

            aboutSection

            securitySection

            if let recipient = context.viewState.dmRecipientInfo?.member {
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
                if context.viewState.canEditBaseInfo {
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
    
    private var roomHeaderSection: some View {
        AvatarHeaderView(room: context.viewState.details,
                         avatarSize: .room(on: .details),
                         mediaProvider: context.mediaProvider) { url in
            context.send(viewAction: .displayAvatar(url))
        } footer: {
            if !context.viewState.shortcuts.isEmpty {
                headerSectionShortcuts
            }
        }
        .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.avatar)
    }
    
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
            ListRow(label: .default(title: L10n.screenRoomDetailsPinnedEventsRowTitle, icon: \.pin),
                    details: context.viewState.pinnedEventsActionState.isLoading ? .isWaiting(true) : .title(context.viewState.pinnedEventsActionState.count),
                    kind: context.viewState.pinnedEventsActionState.isLoading ? .label : .navigationLink {
                        context.send(viewAction: .processTapPinnedEvents)
                    })
                    .disabled(context.viewState.pinnedEventsActionState.isLoading)
            
            ListRow(label: .default(title: L10n.screenPollsHistoryTitle, icon: \.polls),
                    kind: .navigationLink {
                        context.send(viewAction: .processTapPolls)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.pollsHistory)
            
            ListRow(label: .default(title: L10n.screenMediaBrowserTitle, icon: \.image),
                    kind: .navigationLink {
                        context.send(viewAction: .processTapMediaEvents)
                    })
        }
    }
    
    private var configurationSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenRoomDetailsNotificationTitle, icon: \.notifications),
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
                .onChange(of: context.isFavourite) { _, newValue in
                    context.send(viewAction: .toggleFavourite(isFavourite: newValue))
                }
            
            if context.viewState.canSeeSecurityAndPrivacy {
                ListRow(label: .default(title: L10n.screenRoomDetailsSecurityAndPrivacyTitle, icon: \.lock),
                        kind: .navigationLink {
                            context.send(viewAction: .processTapSecurityAndPrivacy)
                        })
            }
            
            if context.viewState.dmRecipientInfo != nil {
                switch context.viewState.dmRecipientInfo?.verificationState {
                case .verified:
                    ListRow(label: .default(title: L10n.screenRoomDetailsProfileRowTitle, icon: \.userProfile),
                            details: .icon(CompoundIcon(\.verified).foregroundStyle(.compound.iconSuccessPrimary)),
                            kind: .navigationLink {
                                context.send(viewAction: .processTapRecipientProfile)
                            })
                case .verificationViolation:
                    ListRow(label: .default(title: L10n.screenRoomDetailsProfileRowTitle, icon: \.userProfile),
                            details: .icon(CompoundIcon(\.infoSolid).foregroundStyle(.compound.iconCriticalPrimary)),
                            kind: .navigationLink {
                                context.send(viewAction: .processTapRecipientProfile)
                            })
                default:
                    ListRow(label: .default(title: L10n.screenRoomDetailsProfileRowTitle, icon: \.userProfile),
                            kind: .navigationLink {
                                context.send(viewAction: .processTapRecipientProfile)
                            })
                }
            }
        }
    }
    
    private var peopleSection: some View {
        Section {
            if context.viewState.hasMemberIdentityVerificationStateViolations {
                ListRow(label: .default(title: L10n.commonPeople, icon: \.user),
                        details: .icon(CompoundIcon(\.infoSolid).foregroundStyle(.compound.iconCriticalPrimary)),
                        kind: .navigationLink {
                            context.send(viewAction: .processTapPeople)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.people)
                
            } else {
                ListRow(label: .default(title: L10n.commonPeople, icon: \.user),
                        details: .title(String(context.viewState.joinedMembersCount)),
                        kind: .navigationLink {
                            context.send(viewAction: .processTapPeople)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.people)
            }
        
            if context.viewState.canSeeKnockingRequests {
                ListRow(label: .default(title: L10n.screenRoomDetailsRequestsToJoinTitle, icon: \.askToJoin),
                        details: context.viewState.knockRequestsCount > 0 ? .counter(context.viewState.knockRequestsCount) : nil,
                        kind: .navigationLink {
                            context.send(viewAction: .processTapRequestsToJoin)
                        })
            }
            
            if context.viewState.canEditRolesOrPermissions, context.viewState.dmRecipientInfo == nil {
                ListRow(label: .default(title: L10n.screenRoomDetailsRolesAndPermissions, icon: \.admin),
                        kind: .navigationLink {
                            context.send(viewAction: .processTapRolesAndPermissions)
                        })
            }
        }
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
                                        icon: \.lock),
                        kind: .label)
                    .accessibilityAddTraits(.isHeader)
            } header: {
                Text(L10n.commonSecurity)
                    .compoundListSectionHeader()
            }
        }
    }
    
    private var leaveRoomSection: some View {
        Section {
            if context.viewState.reportRoomEnabled {
                ListRow(label: .action(title: L10n.actionReportRoom,
                                       icon: \.chatProblem,
                                       role: .destructive),
                        kind: .button { context.send(viewAction: .processTapReport) })
            }
            ListRow(label: .action(title: L10n.screenRoomDetailsLeaveRoomTitle,
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
    static let genericRoomViewModel = makeGenericRoomViewModel()
    static let simpleRoomViewModel = makeSimpleRoomViewModel()
    static let dmRoomViewModel = makeDMViewModel(verificationState: .notVerified)
    static let dmRoomVerifiedViewModel = makeDMViewModel(verificationState: .verified)
    static let dmRoomVerificationViolationViewModel = makeDMViewModel(verificationState: .verificationViolation)
    static let historySharingJoined = makeHistorySharingViewModel(historyVisibility: .joined)
    static let historySharingShared = makeHistorySharingViewModel(historyVisibility: .shared)
    static let historySharingWorldReadable = makeHistorySharingViewModel(historyVisibility: .worldReadable)
    
    static var previews: some View {
        RoomDetailsScreen(context: genericRoomViewModel.context)
            .snapshotPreferences(expect: genericRoomViewModel.context.observe(\.viewState.permalink).map { $0 != nil })
            .previewDisplayName("Generic Room")
        
        RoomDetailsScreen(context: simpleRoomViewModel.context)
            .snapshotPreferences(expect: simpleRoomViewModel.context.observe(\.viewState.permalink).map { $0 != nil })
            .previewDisplayName("Simple Room")
        
        RoomDetailsScreen(context: dmRoomViewModel.context)
            .snapshotPreferences(expect: dmRoomViewModel.context.observe(\.viewState.accountOwner).map { $0 != nil })
            .previewDisplayName("DM Room")
        
        RoomDetailsScreen(context: dmRoomVerifiedViewModel.context)
            .snapshotPreferences(expect: dmRoomVerifiedViewModel.context.observe(\.viewState.dmRecipientInfo?.verificationState).map { $0 == .verified })
            .previewDisplayName("DM Room Verified")
        
        RoomDetailsScreen(context: dmRoomVerificationViolationViewModel.context)
            .snapshotPreferences(expect: dmRoomVerificationViolationViewModel.context.observe(\.viewState.accountOwner).map { $0 != nil })
            .previewDisplayName("DM Room Verification Violation")
        
        RoomDetailsScreen(context: historySharingJoined.context)
            .previewDisplayName("History Sharing - Joined")
        
        RoomDetailsScreen(context: historySharingShared.context)
            .previewDisplayName("History Sharing - Shared")
        
        RoomDetailsScreen(context: historySharingWorldReadable.context)
            .previewDisplayName("History Sharing - World Readable")
    }
    
    private static func makeGenericRoomViewModel() -> RoomDetailsScreenViewModel {
        ServiceLocator.shared.settings.knockingEnabled = true
        let knockRequests: [KnockRequestProxyMock] = [.init()]
        
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
                                                  members: members,
                                                  knockRequestsState: .loaded(knockRequests),
                                                  joinRule: .knock))
        
        let notificationSettingsProxyMockConfiguration = NotificationSettingsProxyMockConfiguration()
        notificationSettingsProxyMockConfiguration.roomMode.isDefault = false
        
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: notificationSettingsProxyMockConfiguration)
        
        return .init(roomProxy: roomProxy,
                     userSession: UserSessionMock(.init()),
                     analyticsService: ServiceLocator.shared.analytics,
                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                     notificationSettingsProxy: notificationSettingsProxy,
                     attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                     appSettings: ServiceLocator.shared.settings)
    }
    
    private static func makeSimpleRoomViewModel() -> RoomDetailsScreenViewModel {
        ServiceLocator.shared.settings.knockingEnabled = true
        let knockRequests: [KnockRequestProxyMock] = [.init()]
        
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
                                                  members: members,
                                                  knockRequestsState: .loaded(knockRequests),
                                                  joinRule: .knock))
        
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        
        return .init(roomProxy: roomProxy,
                     userSession: UserSessionMock(.init()),
                     analyticsService: ServiceLocator.shared.analytics,
                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                     notificationSettingsProxy: notificationSettingsProxy,
                     attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                     appSettings: ServiceLocator.shared.settings)
    }
    
    private static func makeDMViewModel(verificationState: UserIdentityVerificationState) -> RoomDetailsScreenViewModel {
        ServiceLocator.shared.settings.enableKeyShareOnInvite = false
        
        let members: [RoomMemberProxyMock] = [
            .mockMe,
            .mockDan
        ]
        
        let roomProxy = JoinedRoomProxyMock(.init(id: "dm_room_id",
                                                  name: "Dan",
                                                  topic: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                                                  isDirect: true,
                                                  isEncrypted: true,
                                                  members: members,
                                                  heroes: [.mockDan]))
        
        let clientProxyMock = ClientProxyMock(.init())
        
        clientProxyMock.userIdentityForFallBackToServerClosure = { userID, _ in
            let identity = switch userID {
            case RoomMemberProxyMock.mockDan.userID:
                UserIdentityProxyMock(configuration: .init(verificationState: verificationState))
            default:
                UserIdentityProxyMock(configuration: .init())
            }
            
            return .success(identity)
        }
        
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        
        return .init(roomProxy: roomProxy,
                     userSession: UserSessionMock(.init(clientProxy: clientProxyMock)),
                     analyticsService: ServiceLocator.shared.analytics,
                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                     notificationSettingsProxy: notificationSettingsProxy,
                     attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                     appSettings: ServiceLocator.shared.settings)
    }
    
    private static func makeHistorySharingViewModel(historyVisibility: RoomHistoryVisibility) -> RoomDetailsScreenViewModel {
        ServiceLocator.shared.settings.enableKeyShareOnInvite = true
        
        let members: [RoomMemberProxyMock] = [
            .mockMe,
            .mockDan
        ]
        
        let roomProxy = JoinedRoomProxyMock(.init(id: "dm_room_id",
                                                  name: "Dan",
                                                  topic: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                                                  isDirect: true,
                                                  isEncrypted: true,
                                                  historyVisibility: historyVisibility,
                                                  members: members,
                                                  heroes: [.mockDan]))
        
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        
        return .init(roomProxy: roomProxy,
                     userSession: UserSessionMock(.init()),
                     analyticsService: ServiceLocator.shared.analytics,
                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                     notificationSettingsProxy: notificationSettingsProxy,
                     attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                     appSettings: ServiceLocator.shared.settings)
    }
}
