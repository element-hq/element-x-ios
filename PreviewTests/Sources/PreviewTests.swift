// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
// swiftformat:disable all

import XCTest
import SwiftUI
@testable import ElementX
@testable import SnapshotTesting
#if canImport(AccessibilitySnapshot)
    import AccessibilitySnapshot
#endif

class PreviewTests: XCTestCase {
    private let deviceConfig: ViewImageConfig = .iPhoneX
    private var simulatorDevice: String? = "iPhone14,6" // iPhone SE 3rd Generation
    private var requiredOSVersion = (major: 17, minor: 5)
    private let snapshotDevices = ["iPhone 15", "iPad"]

    override func setUp() {
        super.setUp()

        checkEnvironments()
        UIView.setAnimationsEnabled(false)
    }

    // MARK: - PreviewProvider

    func test_advancedSettingsScreen() {
        for preview in AdvancedSettingsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_analyticsPromptScreenCheckmarkItem() {
        for preview in AnalyticsPromptScreenCheckmarkItem_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_analyticsPromptScreen() {
        for preview in AnalyticsPromptScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_analyticsSettingsScreen() {
        for preview in AnalyticsSettingsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_appLockScreen() {
        for preview in AppLockScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_appLockSetupBiometricsScreen() {
        for preview in AppLockSetupBiometricsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_appLockSetupPINScreen() {
        for preview in AppLockSetupPINScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_appLockSetupSettingsScreen() {
        for preview in AppLockSetupSettingsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_audioRoomTimelineView() {
        for preview in AudioRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_authenticationStartScreen() {
        for preview in AuthenticationStartScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_avatarHeaderView() {
        for preview in AvatarHeaderView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_badgeLabel() {
        for preview in BadgeLabel_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_blockedUsersScreen() {
        for preview in BlockedUsersScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_bugReport() {
        for preview in BugReport_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_callInviteRoomTimelineView() {
        for preview in CallInviteRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_callNotificationRoomTimelineView() {
        for preview in CallNotificationRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_collapsibleRoomTimelineView() {
        for preview in CollapsibleRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_completionSuggestion() {
        for preview in CompletionSuggestion_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_composerToolbar() {
        for preview in ComposerToolbar_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_createRoom() {
        for preview in CreateRoom_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_deactivateAccountScreen() {
        for preview in DeactivateAccountScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_emojiPickerScreenHeaderView() {
        for preview in EmojiPickerScreenHeaderView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_emojiPickerScreen() {
        for preview in EmojiPickerScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_emoteRoomTimelineView() {
        for preview in EmoteRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_encryptedRoomTimelineView() {
        for preview in EncryptedRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_encryptionResetPasswordScreen() {
        for preview in EncryptionResetPasswordScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_encryptionResetScreen() {
        for preview in EncryptionResetScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_estimatedWaveformView() {
        for preview in EstimatedWaveformView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_fileRoomTimelineView() {
        for preview in FileRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_formButtonStyles() {
        for preview in FormButtonStyles_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_formattedBodyText() {
        for preview in FormattedBodyText_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_formattingToolbar() {
        for preview in FormattingToolbar_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_fullscreenDialog() {
        for preview in FullscreenDialog_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_globalSearchScreenListRow() {
        for preview in GlobalSearchScreenListRow_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_globalSearchScreen() {
        for preview in GlobalSearchScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_heroImage() {
        for preview in HeroImage_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_highlightedTimelineItemModifier() {
        for preview in HighlightedTimelineItemModifier_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_homeScreenEmptyStateView() {
        for preview in HomeScreenEmptyStateView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_homeScreenInviteCell() {
        for preview in HomeScreenInviteCell_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_homeScreenRecoveryKeyConfirmationBanner() {
        for preview in HomeScreenRecoveryKeyConfirmationBanner_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_homeScreenRoomCell() {
        for preview in HomeScreenRoomCell_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_homeScreenSlidingSyncMigrationBanner() {
        for preview in HomeScreenSlidingSyncMigrationBanner_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_homeScreen() {
        for preview in HomeScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_identityConfirmationScreen() {
        for preview in IdentityConfirmationScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_identityConfirmedScreen() {
        for preview in IdentityConfirmedScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_imageRoomTimelineView() {
        for preview in ImageRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_inviteUsersScreenSelectedItem() {
        for preview in InviteUsersScreenSelectedItem_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_inviteUsersScreen() {
        for preview in InviteUsersScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_joinRoomScreen() {
        for preview in JoinRoomScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_legalInformationScreen() {
        for preview in LegalInformationScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_locationMarkerView() {
        for preview in LocationMarkerView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_locationRoomTimelineView() {
        for preview in LocationRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_loginScreen() {
        for preview in LoginScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_longPressWithFeedback() {
        for preview in LongPressWithFeedback_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_mapLibreStaticMapView() {
        for preview in MapLibreStaticMapView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_matrixUserPermalink() {
        for preview in MatrixUserPermalink_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_mediaUploadPreviewScreen() {
        for preview in MediaUploadPreviewScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_mentionSuggestionItemView() {
        for preview in MentionSuggestionItemView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_messageComposerTextField() {
        for preview in MessageComposerTextField_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_messageComposer() {
        for preview in MessageComposer_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_messageForwardingScreen() {
        for preview in MessageForwardingScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_messageText() {
        for preview in MessageText_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_noticeRoomTimelineView() {
        for preview in NoticeRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_notificationPermissionsScreen() {
        for preview in NotificationPermissionsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_notificationSettingsEditScreenRoomCell() {
        for preview in NotificationSettingsEditScreenRoomCell_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_notificationSettingsEditScreen() {
        for preview in NotificationSettingsEditScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_notificationSettingsScreen() {
        for preview in NotificationSettingsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_pINTextField() {
        for preview in PINTextField_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_paginationIndicatorRoomTimelineView() {
        for preview in PaginationIndicatorRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_pillView() {
        for preview in PillView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_pinnedEventsTimelineScreen() {
        for preview in PinnedEventsTimelineScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_pinnedItemsBannerView() {
        for preview in PinnedItemsBannerView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_pinnedItemsIndicatorView() {
        for preview in PinnedItemsIndicatorView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_placeholderAvatarImage() {
        for preview in PlaceholderAvatarImage_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_placeholderScreen() {
        for preview in PlaceholderScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_pollFormScreen() {
        for preview in PollFormScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_pollOptionView() {
        for preview in PollOptionView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_pollRoomTimelineView() {
        for preview in PollRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_pollView() {
        for preview in PollView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_qRCodeLoginScreen() {
        for preview in QRCodeLoginScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_reactionsSummaryView() {
        for preview in ReactionsSummaryView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_readMarkerRoomTimelineView() {
        for preview in ReadMarkerRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_readReceiptCell() {
        for preview in ReadReceiptCell_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_readReceiptsSummaryView() {
        for preview in ReadReceiptsSummaryView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_redactedRoomTimelineView() {
        for preview in RedactedRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_reportContentScreen() {
        for preview in ReportContentScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_resolveVerifiedUserSendFailureScreen() {
        for preview in ResolveVerifiedUserSendFailureScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomAttachmentPicker() {
        for preview in RoomAttachmentPicker_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomAvatarImage() {
        for preview in RoomAvatarImage_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomChangePermissionsScreen() {
        for preview in RoomChangePermissionsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomChangeRolesScreenRow() {
        for preview in RoomChangeRolesScreenRow_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomChangeRolesScreenSelectedItem() {
        for preview in RoomChangeRolesScreenSelectedItem_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomChangeRolesScreen() {
        for preview in RoomChangeRolesScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomDetailsEditScreen() {
        for preview in RoomDetailsEditScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomDetailsScreen() {
        for preview in RoomDetailsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomDirectorySearchCell() {
        for preview in RoomDirectorySearchCell_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomDirectorySearchScreen() {
        for preview in RoomDirectorySearchScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomDirectorySearchView() {
        for preview in RoomDirectorySearchView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomHeaderView() {
        for preview in RoomHeaderView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomInviterLabel() {
        for preview in RoomInviterLabel_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomListFilterView() {
        for preview in RoomListFilterView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomListFiltersEmptyStateView() {
        for preview in RoomListFiltersEmptyStateView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomListFiltersView() {
        for preview in RoomListFiltersView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomMemberDetailsScreen() {
        for preview in RoomMemberDetailsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomMembersListManageMemberSheet() {
        for preview in RoomMembersListManageMemberSheet_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomMembersListMemberCell() {
        for preview in RoomMembersListMemberCell_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomMembersListScreen() {
        for preview in RoomMembersListScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomNotificationSettingsCustomSectionView() {
        for preview in RoomNotificationSettingsCustomSectionView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomNotificationSettingsScreen() {
        for preview in RoomNotificationSettingsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomNotificationSettingsUserDefinedScreen() {
        for preview in RoomNotificationSettingsUserDefinedScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomPollsHistoryScreen() {
        for preview in RoomPollsHistoryScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomRolesAndPermissionsScreen() {
        for preview in RoomRolesAndPermissionsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_roomScreen() {
        for preview in RoomScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_sFNumberedListView() {
        for preview in SFNumberedListView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_secureBackupKeyBackupScreen() {
        for preview in SecureBackupKeyBackupScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_secureBackupLogoutConfirmationScreen() {
        for preview in SecureBackupLogoutConfirmationScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_secureBackupRecoveryKeyScreen() {
        for preview in SecureBackupRecoveryKeyScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_secureBackupScreen() {
        for preview in SecureBackupScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_separatorRoomTimelineView() {
        for preview in SeparatorRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_serverConfirmationScreen() {
        for preview in ServerConfirmationScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_serverSelection() {
        for preview in ServerSelection_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_sessionVerification() {
        for preview in SessionVerification_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_settingsScreen() {
        for preview in SettingsScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_shimmerOverlay() {
        for preview in ShimmerOverlay_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_softLogoutScreen() {
        for preview in SoftLogoutScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_splashScreen() {
        for preview in SplashScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_startChatScreen() {
        for preview in StartChatScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_stateRoomTimelineView() {
        for preview in StateRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_staticLocationScreenViewer() {
        for preview in StaticLocationScreenViewer_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_stickerRoomTimelineView() {
        for preview in StickerRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_swipeRightAction() {
        for preview in SwipeRightAction_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_swipeToReplyView() {
        for preview in SwipeToReplyView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_textRoomTimelineView() {
        for preview in TextRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_threadDecorator() {
        for preview in ThreadDecorator_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_timelineDeliveryStatusView() {
        for preview in TimelineDeliveryStatusView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_timelineItemBubbledStylerView() {
        for preview in TimelineItemBubbledStylerView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_timelineItemDebugView() {
        for preview in TimelineItemDebugView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_timelineItemMenu() {
        for preview in TimelineItemMenu_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_timelineItemSendInfoLabel() {
        for preview in TimelineItemSendInfoLabel_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_timelineItemStyler() {
        for preview in TimelineItemStyler_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_timelineReactionView() {
        for preview in TimelineReactionView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_timelineReadReceiptsView() {
        for preview in TimelineReadReceiptsView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_timelineReplyView() {
        for preview in TimelineReplyView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_timelineStartRoomTimelineView() {
        for preview in TimelineStartRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_timelineView() {
        for preview in TimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_typingIndicatorView() {
        for preview in TypingIndicatorView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_unsupportedRoomTimelineView() {
        for preview in UnsupportedRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_userDetailsEditScreen() {
        for preview in UserDetailsEditScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_userIndicatorModalView() {
        for preview in UserIndicatorModalView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_userIndicatorToastView() {
        for preview in UserIndicatorToastView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_userProfileCell() {
        for preview in UserProfileCell_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_userProfileScreen() {
        for preview in UserProfileScreen_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_videoRoomTimelineView() {
        for preview in VideoRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_voiceMessageButton() {
        for preview in VoiceMessageButton_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_voiceMessagePreviewComposer() {
        for preview in VoiceMessagePreviewComposer_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_voiceMessageRecordingButton() {
        for preview in VoiceMessageRecordingButton_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_voiceMessageRecordingComposer() {
        for preview in VoiceMessageRecordingComposer_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_voiceMessageRecordingView() {
        for preview in VoiceMessageRecordingView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_voiceMessageRoomPlaybackView() {
        for preview in VoiceMessageRoomPlaybackView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_voiceMessageRoomTimelineView() {
        for preview in VoiceMessageRoomTimelineView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    func test_waveformCursorView() {
        for preview in WaveformCursorView_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }
    // MARK: Private

    private func assertSnapshots(matching preview: _Preview, testName: String = #function) {
        guard !snapshotDevices.isEmpty else {
            if let failure = assertSnapshots(matching: AnyView(preview.content),
                                             name: preview.displayName,
                                             isScreen: preview.layout == .device,
                                             device: preview.device?.snapshotDevice() ?? deviceConfig,
                                             testName: testName) {
                XCTFail(failure)
            }
            return
        }
        for deviceName in snapshotDevices {
            guard var device = PreviewDevice(rawValue: deviceName).snapshotDevice() else {
                fatalError("Unknown device name: \(deviceName)")
            }
            // Ignore specific device safe area (using the workaround value to fix rendering issues).
            device.safeArea = .one
            // Ignore specific device display scale
            let traits = UITraitCollection(displayScale: 2.0)
            if let failure = assertSnapshots(matching: AnyView(preview.content),
                                            name: preview.displayName,
                                            isScreen: preview.layout == .device,
                                            device: device,
                                            testName: testName + deviceName + "-" + localeCode,
                                            traits: traits) {
                XCTFail(failure)
            }
        }
    }
    private var localeCode: String {
        if UserDefaults.standard.bool(forKey: "NSDoubleLocalizedStrings") {
            return "pseudo"
        }
        return languageCode + "-" + regionCode
    }

    private var languageCode: String {
        Locale.current.language.languageCode?.identifier ?? ""
    }

    private var regionCode: String {
        Locale.current.language.region?.identifier ?? ""
    }

    private func assertSnapshots(matching view: AnyView,
                                 name: String?, isScreen: Bool,
                                 device: ViewImageConfig,
                                 testName: String = #function,
                                 traits: UITraitCollection = .init()) -> String? {
        var delay: TimeInterval = 0
        var precision: Float = 1
        var perceptualPrecision: Float = 1

        let view = view
            .onPreferenceChange(SnapshotDelayPreferenceKey.self) { delay = $0 }
            .onPreferenceChange(SnapshotPrecisionPreferenceKey.self) { precision = $0 }
            .onPreferenceChange(SnapshotPerceptualPrecisionPreferenceKey.self) { perceptualPrecision = $0 }

        let matchingView = isScreen ? AnyView(view) : AnyView(view
            .frame(width: device.size?.width)
            .fixedSize(horizontal: false, vertical: true)
        )

        let failure = verifySnapshot(
            of: matchingView,
            as: .prefireImage(precision: { precision },
                              perceptualPrecision: { perceptualPrecision },
                              duration: { delay },
                              layout: isScreen ? .device(config: device) : .sizeThatFits,
                              traits: traits),
            named: name,
            testName: testName
        )

        #if canImport(AccessibilitySnapshot)
            let vc = UIHostingController(rootView: matchingView)
            vc.view.frame = UIScreen.main.bounds
            assertSnapshot(
                matching: vc,
                as: .wait(for: delay, on: .accessibilityImage(showActivationPoints: .always)),
                named: name.flatMap { $0 + ".accessibility" },
                testName: testName
            )
        #endif
        return failure
    }

    /// Check environments to avoid problems with snapshots on different devices or OS.
    private func checkEnvironments() {
        if let simulatorDevice {
            let deviceModel = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]
            guard deviceModel?.contains(simulatorDevice) ?? false else {
                fatalError("\(deviceModel ?? "Unknown") is the wrong one. Switch to using \(simulatorDevice) for these tests.")
            }
        }

        let osVersion = ProcessInfo().operatingSystemVersion
        guard osVersion.majorVersion == requiredOSVersion.major, osVersion.minorVersion == requiredOSVersion.minor else {
            fatalError("Switch to iOS \(requiredOSVersion) for these tests.")
        }
    }
}

// MARK: - SnapshotTesting + Extensions

private extension PreviewDevice {
    func snapshotDevice() -> ViewImageConfig? {
        switch rawValue {
        case "iPhone 15", "iPhone 14", "iPhone 13", "iPhone 12", "iPhone 11", "iPhone 10":
            return .iPhoneX
        case "iPhone 6", "iPhone 6s", "iPhone 7", "iPhone 8":
            return .iPhone8
        case "iPhone 6 Plus", "iPhone 6s Plus", "iPhone 8 Plus":
            return .iPhone8Plus
        case "iPhone SE (1st generation)", "iPhone SE (2nd generation)":
            return .iPhoneSe
        case "iPad":
            return .iPad10_2
        case "iPad Mini":
            return .iPadMini
        case "iPad Pro 11":
            return .iPadPro11
        case "iPad Pro 12.9":
            return .iPadPro12_9
        default: return nil
        }
    }
}

private extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    static func prefireImage(
        drawHierarchyInKeyWindow: Bool = false,
        precision: @escaping () -> Float,
        perceptualPrecision: @escaping () -> Float,
        duration: @escaping () -> TimeInterval,
        layout: SwiftUISnapshotLayout = .sizeThatFits,
        traits: UITraitCollection = .init()
    ) -> Snapshotting {
        let config: ViewImageConfig

        switch layout {
        #if os(iOS) || os(tvOS)
        case let .device(config: deviceConfig):
            config = deviceConfig
        #endif
        case .sizeThatFits:
            // Make sure to use the workaround safe area insets.
            config = .init(safeArea: .one, size: nil, traits: traits)
        case let .fixed(width: width, height: height):
            let size = CGSize(width: width, height: height)
            // Make sure to use the workaround safe area insets.
            config = .init(safeArea: .one, size: size, traits: traits)
        }

        return SimplySnapshotting<UIImage>(pathExtension: "png", diffing: .prefireImage(precision: precision, perceptualPrecision: perceptualPrecision, scale: traits.displayScale))
            .asyncPullback { view in
                var config = config

                let controller: UIViewController

                if config.size != nil {
                    controller = UIHostingController(rootView: view)
                } else {
                    let hostingController = UIHostingController(rootView: view)

                    let maxSize = CGSize.zero
                    config.size = hostingController.sizeThatFits(in: maxSize)

                    controller = hostingController
                }

                return Async<UIImage> { callback in
                    let strategy = snapshotView(
                        config: config,
                        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                        traits: traits,
                        view: controller.view,
                        viewController: controller
                    )

                    let duration = duration()
                    if duration != .zero {
                        let expectation = XCTestExpectation(description: "Wait")
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            expectation.fulfill()
                        }
                        _ = XCTWaiter.wait(for: [expectation], timeout: duration + 1)
                    }
                    strategy.run(callback)
                }
            }
    }
}

private extension Diffing where Value == UIImage {
    static func prefireImage(precision: @escaping () -> Float, perceptualPrecision: @escaping () -> Float, scale: CGFloat?) -> Diffing {
        lazy var originalDiffing = Diffing.image(precision: precision(), perceptualPrecision: 0.98, scale: scale)
        return Diffing(
            toData: { originalDiffing.toData($0) },
            fromData: { originalDiffing.fromData($0) },
            diff: { originalDiffing.diff($0, $1) }
        )
    }
}

private extension UIEdgeInsets {
    /// A custom inset that prevents the snapshotting library from rendering the
    /// origin at (10000, 10000) which breaks some of our views such as MessageText.
    static var one: UIEdgeInsets { UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1) }
}

// swiftlint:enable all
// swiftformat:enable all
