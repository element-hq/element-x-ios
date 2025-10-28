// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
// swiftformat:disable all

import XCTest
@testable import ElementX

extension PreviewTests {

    // MARK: - PreviewProvider

    func testAdvancedSettingsScreen() async throws {
        for (index, preview) in AdvancedSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testAnalyticsPromptScreen() async throws {
        for (index, preview) in AnalyticsPromptScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testAnalyticsSettingsScreen() async throws {
        for (index, preview) in AnalyticsSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testAppLockScreen() async throws {
        for (index, preview) in AppLockScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testAppLockSetupBiometricsScreen() async throws {
        for (index, preview) in AppLockSetupBiometricsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testAppLockSetupPINScreen() async throws {
        for (index, preview) in AppLockSetupPINScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testAppLockSetupSettingsScreen() async throws {
        for (index, preview) in AppLockSetupSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testAudioMediaEventsTimelineView() async throws {
        for (index, preview) in AudioMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testAudioRoomTimelineView() async throws {
        for (index, preview) in AudioRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testAuthenticationStartScreen() async throws {
        for (index, preview) in AuthenticationStartScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testAvatarHeaderView() async throws {
        for (index, preview) in AvatarHeaderView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testBadgeLabel() async throws {
        for (index, preview) in BadgeLabel_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testBigIcon() async throws {
        for (index, preview) in BigIcon_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testBlockedUsersScreen() async throws {
        for (index, preview) in BlockedUsersScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testBloomModifier() async throws {
        for (index, preview) in BloomModifier_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testBugReportScreen() async throws {
        for (index, preview) in BugReportScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testCallInviteRoomTimelineView() async throws {
        for (index, preview) in CallInviteRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testCallNotificationRoomTimelineView() async throws {
        for (index, preview) in CallNotificationRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testCollapsibleRoomTimelineView() async throws {
        for (index, preview) in CollapsibleRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testCompletionSuggestion() async throws {
        for (index, preview) in CompletionSuggestion_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testComposerToolbar() async throws {
        for (index, preview) in ComposerToolbar_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testCreateRoom() async throws {
        for (index, preview) in CreateRoom_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testDeactivateAccountScreen() async throws {
        for (index, preview) in DeactivateAccountScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testDeclineAndBlockScreen() async throws {
        for (index, preview) in DeclineAndBlockScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testEditRoomAddressScreen() async throws {
        for (index, preview) in EditRoomAddressScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testElementTextFieldStyle() async throws {
        for (index, preview) in ElementTextFieldStyle_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testEmojiPickerScreenHeaderView() async throws {
        for (index, preview) in EmojiPickerScreenHeaderView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testEmojiPickerScreen() async throws {
        for (index, preview) in EmojiPickerScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testEmoteRoomTimelineView() async throws {
        for (index, preview) in EmoteRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testEncryptedRoomTimelineView() async throws {
        for (index, preview) in EncryptedRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testEncryptionResetPasswordScreen() async throws {
        for (index, preview) in EncryptionResetPasswordScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testEncryptionResetScreen() async throws {
        for (index, preview) in EncryptionResetScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testEstimatedWaveformView() async throws {
        for (index, preview) in EstimatedWaveformView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testFileMediaEventsTimelineView() async throws {
        for (index, preview) in FileMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testFileRoomTimelineView() async throws {
        for (index, preview) in FileRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testFormButtonStyles() async throws {
        for (index, preview) in FormButtonStyles_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testFormattedBodyText() async throws {
        for (index, preview) in FormattedBodyText_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testFormattingToolbar() async throws {
        for (index, preview) in FormattingToolbar_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testFullscreenDialog() async throws {
        for (index, preview) in FullscreenDialog_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testGlobalSearchScreenListRow() async throws {
        for (index, preview) in GlobalSearchScreenListRow_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testGlobalSearchScreen() async throws {
        for (index, preview) in GlobalSearchScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testHighlightedTimelineItemModifier() async throws {
        for (index, preview) in HighlightedTimelineItemModifier_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testHomeScreenEmptyStateView() async throws {
        for (index, preview) in HomeScreenEmptyStateView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testHomeScreenInviteCell() async throws {
        for (index, preview) in HomeScreenInviteCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testHomeScreenKnockedCell() async throws {
        for (index, preview) in HomeScreenKnockedCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testHomeScreenNewSoundBanner() async throws {
        for (index, preview) in HomeScreenNewSoundBanner_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testHomeScreenRecoveryKeyConfirmationBanner() async throws {
        for (index, preview) in HomeScreenRecoveryKeyConfirmationBanner_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testHomeScreenRoomCell() async throws {
        for (index, preview) in HomeScreenRoomCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testHomeScreen() async throws {
        for (index, preview) in HomeScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testIdentityConfirmationScreen() async throws {
        for (index, preview) in IdentityConfirmationScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testIdentityConfirmedScreen() async throws {
        for (index, preview) in IdentityConfirmedScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testImageMediaEventsTimelineView() async throws {
        for (index, preview) in ImageMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testImageRoomTimelineView() async throws {
        for (index, preview) in ImageRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testInviteUsersScreenSelectedItem() async throws {
        for (index, preview) in InviteUsersScreenSelectedItem_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testInviteUsersScreen() async throws {
        for (index, preview) in InviteUsersScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testJoinRoomByAddressView() async throws {
        for (index, preview) in JoinRoomByAddressView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testJoinRoomScreenSpace() async throws {
        for (index, preview) in JoinRoomScreenSpace_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testJoinRoomScreen() async throws {
        for (index, preview) in JoinRoomScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testJoinedMembersBadgeView() async throws {
        for (index, preview) in JoinedMembersBadgeView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testKnockRequestCell() async throws {
        for (index, preview) in KnockRequestCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testKnockRequestsBannerView() async throws {
        for (index, preview) in KnockRequestsBannerView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testKnockRequestsListEmptyStateView() async throws {
        for (index, preview) in KnockRequestsListEmptyStateView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testKnockRequestsListScreen() async throws {
        for (index, preview) in KnockRequestsListScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testLabsScreen() async throws {
        for (index, preview) in LabsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testLeaveSpaceRoomDetailsCell() async throws {
        for (index, preview) in LeaveSpaceRoomDetailsCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testLeaveSpaceView() async throws {
        for (index, preview) in LeaveSpaceView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testLegalInformationScreen() async throws {
        for (index, preview) in LegalInformationScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testLoadableImage() async throws {
        for (index, preview) in LoadableImage_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testLocationMarkerView() async throws {
        for (index, preview) in LocationMarkerView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testLocationRoomTimelineView() async throws {
        for (index, preview) in LocationRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testLoginScreen() async throws {
        for (index, preview) in LoginScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testLongPressWithFeedback() async throws {
        for (index, preview) in LongPressWithFeedback_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testManageRoomMemberSheetView() async throws {
        for (index, preview) in ManageRoomMemberSheetView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testMapLibreStaticMapView() async throws {
        for (index, preview) in MapLibreStaticMapView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testMatrixUserPermalink() async throws {
        for (index, preview) in MatrixUserPermalink_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testMediaEventsTimelineScreen() async throws {
        for (index, preview) in MediaEventsTimelineScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testMediaUploadPreviewScreen() async throws {
        for (index, preview) in MediaUploadPreviewScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testMentionSuggestionItemView() async throws {
        for (index, preview) in MentionSuggestionItemView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testMessageComposerTextField() async throws {
        for (index, preview) in MessageComposerTextField_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testMessageComposer() async throws {
        for (index, preview) in MessageComposer_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testMessageForwardingScreen() async throws {
        for (index, preview) in MessageForwardingScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testMessageText() async throws {
        for (index, preview) in MessageText_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testNoticeRoomTimelineView() async throws {
        for (index, preview) in NoticeRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testNotificationPermissionsScreen() async throws {
        for (index, preview) in NotificationPermissionsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testNotificationSettingsEditScreenRoomCell() async throws {
        for (index, preview) in NotificationSettingsEditScreenRoomCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testNotificationSettingsEditScreen() async throws {
        for (index, preview) in NotificationSettingsEditScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testNotificationSettingsScreen() async throws {
        for (index, preview) in NotificationSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPINTextField() async throws {
        for (index, preview) in PINTextField_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPaginationIndicatorRoomTimelineView() async throws {
        for (index, preview) in PaginationIndicatorRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPillViewOnBubble() async throws {
        for (index, preview) in PillViewOnBubble_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPillView() async throws {
        for (index, preview) in PillView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPinnedEventsTimelineScreen() async throws {
        for (index, preview) in PinnedEventsTimelineScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPinnedItemsBannerView() async throws {
        for (index, preview) in PinnedItemsBannerView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPinnedItemsIndicatorView() async throws {
        for (index, preview) in PinnedItemsIndicatorView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPlaceholderAvatarImage() async throws {
        for (index, preview) in PlaceholderAvatarImage_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPlaceholderScreen() async throws {
        for (index, preview) in PlaceholderScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPollFormScreen() async throws {
        for (index, preview) in PollFormScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPollOptionView() async throws {
        for (index, preview) in PollOptionView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPollRoomTimelineView() async throws {
        for (index, preview) in PollRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testPollView() async throws {
        for (index, preview) in PollView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testQRCodeLoginScreen() async throws {
        for (index, preview) in QRCodeLoginScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testReactionsSummaryView() async throws {
        for (index, preview) in ReactionsSummaryView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testReadMarkerRoomTimelineView() async throws {
        for (index, preview) in ReadMarkerRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testReadReceiptCell() async throws {
        for (index, preview) in ReadReceiptCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testReadReceiptsSummaryView() async throws {
        for (index, preview) in ReadReceiptsSummaryView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRedactedRoomTimelineView() async throws {
        for (index, preview) in RedactedRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testReportContentScreen() async throws {
        for (index, preview) in ReportContentScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testReportRoomScreen() async throws {
        for (index, preview) in ReportRoomScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testResolveVerifiedUserSendFailureScreen() async throws {
        for (index, preview) in ResolveVerifiedUserSendFailureScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomAttachmentPicker() async throws {
        for (index, preview) in RoomAttachmentPicker_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomAvatarImage() async throws {
        for (index, preview) in RoomAvatarImage_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomChangePermissionsScreen() async throws {
        for (index, preview) in RoomChangePermissionsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomChangeRolesScreenRow() async throws {
        for (index, preview) in RoomChangeRolesScreenRow_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomChangeRolesScreenSelectedItem() async throws {
        for (index, preview) in RoomChangeRolesScreenSelectedItem_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomChangeRolesScreen() async throws {
        for (index, preview) in RoomChangeRolesScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomDetailsEditScreen() async throws {
        for (index, preview) in RoomDetailsEditScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomDetailsScreen() async throws {
        for (index, preview) in RoomDetailsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomDirectorySearchCell() async throws {
        for (index, preview) in RoomDirectorySearchCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomDirectorySearchScreen() async throws {
        for (index, preview) in RoomDirectorySearchScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomHeaderView() async throws {
        for (index, preview) in RoomHeaderView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomInviterLabel() async throws {
        for (index, preview) in RoomInviterLabel_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomListFilterView() async throws {
        for (index, preview) in RoomListFilterView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomListFiltersEmptyStateView() async throws {
        for (index, preview) in RoomListFiltersEmptyStateView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomListFiltersView() async throws {
        for (index, preview) in RoomListFiltersView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomMemberDetailsScreen() async throws {
        for (index, preview) in RoomMemberDetailsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomMembersListMemberCell() async throws {
        for (index, preview) in RoomMembersListMemberCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomMembersListScreen() async throws {
        for (index, preview) in RoomMembersListScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomNotificationSettingsCustomSectionView() async throws {
        for (index, preview) in RoomNotificationSettingsCustomSectionView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomNotificationSettingsScreen() async throws {
        for (index, preview) in RoomNotificationSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomNotificationSettingsUserDefinedScreen() async throws {
        for (index, preview) in RoomNotificationSettingsUserDefinedScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomPollsHistoryScreen() async throws {
        for (index, preview) in RoomPollsHistoryScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomRolesAndPermissionsScreen() async throws {
        for (index, preview) in RoomRolesAndPermissionsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomScreenFooterView() async throws {
        for (index, preview) in RoomScreenFooterView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomScreen() async throws {
        for (index, preview) in RoomScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testRoomSelectionScreen() async throws {
        for (index, preview) in RoomSelectionScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSFNumberedListView() async throws {
        for (index, preview) in SFNumberedListView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSecureBackupKeyBackupScreen() async throws {
        for (index, preview) in SecureBackupKeyBackupScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSecureBackupLogoutConfirmationScreen() async throws {
        for (index, preview) in SecureBackupLogoutConfirmationScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSecureBackupRecoveryKeyScreen() async throws {
        for (index, preview) in SecureBackupRecoveryKeyScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSecureBackupScreen() async throws {
        for (index, preview) in SecureBackupScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSecurityAndPrivacyScreen() async throws {
        for (index, preview) in SecurityAndPrivacyScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSendInviteConfirmationView() async throws {
        for (index, preview) in SendInviteConfirmationView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSeparatorMediaEventsTimelineView() async throws {
        for (index, preview) in SeparatorMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSeparatorRoomTimelineView() async throws {
        for (index, preview) in SeparatorRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testServerConfirmationScreen() async throws {
        for (index, preview) in ServerConfirmationScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testServerSelection() async throws {
        for (index, preview) in ServerSelection_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSessionVerificationRequestDetailsView() async throws {
        for (index, preview) in SessionVerificationRequestDetailsView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSessionVerification() async throws {
        for (index, preview) in SessionVerification_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSettingsScreen() async throws {
        for (index, preview) in SettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testShimmerOverlay() async throws {
        for (index, preview) in ShimmerOverlay_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSoftLogoutScreen() async throws {
        for (index, preview) in SoftLogoutScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSpaceHeaderTopicSheetView() async throws {
        for (index, preview) in SpaceHeaderTopicSheetView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSpaceHeaderView() async throws {
        for (index, preview) in SpaceHeaderView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSpaceListScreen() async throws {
        for (index, preview) in SpaceListScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSpaceRoomCell() async throws {
        for (index, preview) in SpaceRoomCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSpaceScreen() async throws {
        for (index, preview) in SpaceScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSpaceSettingsScreen() async throws {
        for (index, preview) in SpaceSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSpacesAnnouncementSheetView() async throws {
        for (index, preview) in SpacesAnnouncementSheetView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSplashScreen() async throws {
        for (index, preview) in SplashScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testStackedAvatarsView() async throws {
        for (index, preview) in StackedAvatarsView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testStartChatScreen() async throws {
        for (index, preview) in StartChatScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testStateRoomTimelineView() async throws {
        for (index, preview) in StateRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testStaticLocationScreenViewer() async throws {
        for (index, preview) in StaticLocationScreenViewer_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testStickerRoomTimelineView() async throws {
        for (index, preview) in StickerRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSwipeRightAction() async throws {
        for (index, preview) in SwipeRightAction_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSwipeToReplyView() async throws {
        for (index, preview) in SwipeToReplyView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTextRoomTimelineView() async throws {
        for (index, preview) in TextRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testThreadDecorator() async throws {
        for (index, preview) in ThreadDecorator_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineDeliveryStatusView() async throws {
        for (index, preview) in TimelineDeliveryStatusView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineItemBubbledStylerView() async throws {
        for (index, preview) in TimelineItemBubbledStylerView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineItemDebugView() async throws {
        for (index, preview) in TimelineItemDebugView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineItemMenu() async throws {
        for (index, preview) in TimelineItemMenu_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineItemSendInfoLabel() async throws {
        for (index, preview) in TimelineItemSendInfoLabel_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineItemStyler() async throws {
        for (index, preview) in TimelineItemStyler_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineMediaPreviewDetailsView() async throws {
        for (index, preview) in TimelineMediaPreviewDetailsView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineMediaPreviewRedactConfirmationView() async throws {
        for (index, preview) in TimelineMediaPreviewRedactConfirmationView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineReactionView() async throws {
        for (index, preview) in TimelineReactionView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineReadReceiptsView() async throws {
        for (index, preview) in TimelineReadReceiptsView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineReplyView() async throws {
        for (index, preview) in TimelineReplyView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineStartRoomTimelineView() async throws {
        for (index, preview) in TimelineStartRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineThreadSummaryView() async throws {
        for (index, preview) in TimelineThreadSummaryView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTimelineView() async throws {
        for (index, preview) in TimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTombstonedAvatarImage() async throws {
        for (index, preview) in TombstonedAvatarImage_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTypingIndicatorView() async throws {
        for (index, preview) in TypingIndicatorView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testUnsupportedRoomTimelineView() async throws {
        for (index, preview) in UnsupportedRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testUserDetailsEditScreen() async throws {
        for (index, preview) in UserDetailsEditScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testUserIndicatorModalView() async throws {
        for (index, preview) in UserIndicatorModalView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testUserIndicatorToastView() async throws {
        for (index, preview) in UserIndicatorToastView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testUserProfileCell() async throws {
        for (index, preview) in UserProfileCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testUserProfileScreen() async throws {
        for (index, preview) in UserProfileScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVerificationBadge() async throws {
        for (index, preview) in VerificationBadge_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVideoMediaEventsTimelineView() async throws {
        for (index, preview) in VideoMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVideoRoomTimelineView() async throws {
        for (index, preview) in VideoRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVisualListItem() async throws {
        for (index, preview) in VisualListItem_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVoiceMessageButton() async throws {
        for (index, preview) in VoiceMessageButton_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVoiceMessageMediaEventsTimelineView() async throws {
        for (index, preview) in VoiceMessageMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVoiceMessagePreviewComposer() async throws {
        for (index, preview) in VoiceMessagePreviewComposer_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVoiceMessageRecordingButton() async throws {
        for (index, preview) in VoiceMessageRecordingButton_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVoiceMessageRecordingComposer() async throws {
        for (index, preview) in VoiceMessageRecordingComposer_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVoiceMessageRecordingView() async throws {
        for (index, preview) in VoiceMessageRecordingView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVoiceMessageRoomPlaybackView() async throws {
        for (index, preview) in VoiceMessageRoomPlaybackView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testVoiceMessageRoomTimelineView() async throws {
        for (index, preview) in VoiceMessageRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testWaveformCursorView() async throws {
        for (index, preview) in WaveformCursorView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }
}

// swiftlint:enable all
// swiftformat:enable all
