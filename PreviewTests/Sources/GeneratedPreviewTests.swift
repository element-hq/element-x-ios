// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
// swiftformat:disable all

import Testing
@testable import ElementX

extension PreviewTests {

    // MARK: - PreviewProvider

    @Test
    func advancedSettingsScreen() async throws {
        for (index, preview) in AdvancedSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func analyticsPromptScreen() async throws {
        for (index, preview) in AnalyticsPromptScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func analyticsSettingsScreen() async throws {
        for (index, preview) in AnalyticsSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func appLockScreen() async throws {
        for (index, preview) in AppLockScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func appLockSetupBiometricsScreen() async throws {
        for (index, preview) in AppLockSetupBiometricsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func appLockSetupPINScreen() async throws {
        for (index, preview) in AppLockSetupPINScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func appLockSetupSettingsScreen() async throws {
        for (index, preview) in AppLockSetupSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func audioMediaEventsTimelineView() async throws {
        for (index, preview) in AudioMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func audioRoomTimelineView() async throws {
        for (index, preview) in AudioRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func authenticationClassicAppBackupInstructionsView() async throws {
        for (index, preview) in AuthenticationClassicAppBackupInstructionsView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func authenticationStartScreen() async throws {
        for (index, preview) in AuthenticationStartScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func avatarHeaderView() async throws {
        for (index, preview) in AvatarHeaderView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func badgeLabel() async throws {
        for (index, preview) in BadgeLabel_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func blockedUsersScreen() async throws {
        for (index, preview) in BlockedUsersScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func bloomModifier() async throws {
        for (index, preview) in BloomModifier_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func bugReportScreen() async throws {
        for (index, preview) in BugReportScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func callInviteRoomTimelineView() async throws {
        for (index, preview) in CallInviteRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func callNotificationRoomTimelineView() async throws {
        for (index, preview) in CallNotificationRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func chatsSpaceFilterCell() async throws {
        for (index, preview) in ChatsSpaceFilterCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func chatsSpaceFiltersScreen() async throws {
        for (index, preview) in ChatsSpaceFiltersScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func collapsibleRoomTimelineView() async throws {
        for (index, preview) in CollapsibleRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func completionSuggestion() async throws {
        for (index, preview) in CompletionSuggestion_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func composerToolbar() async throws {
        for (index, preview) in ComposerToolbar_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func copyTextButton() async throws {
        for (index, preview) in CopyTextButton_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func createRoomSpaceSelectionSheet() async throws {
        for (index, preview) in CreateRoomSpaceSelectionSheet_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func createRoom() async throws {
        for (index, preview) in CreateRoom_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func deactivateAccountScreen() async throws {
        for (index, preview) in DeactivateAccountScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func declineAndBlockScreen() async throws {
        for (index, preview) in DeclineAndBlockScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func editRoomAddressScreen() async throws {
        for (index, preview) in EditRoomAddressScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func elementTextFieldStyle() async throws {
        for (index, preview) in ElementTextFieldStyle_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func emojiPickerScreenHeaderView() async throws {
        for (index, preview) in EmojiPickerScreenHeaderView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func emojiPickerScreen() async throws {
        for (index, preview) in EmojiPickerScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func emoteRoomTimelineView() async throws {
        for (index, preview) in EmoteRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func encryptedRoomTimelineView() async throws {
        for (index, preview) in EncryptedRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func encryptionResetPasswordScreen() async throws {
        for (index, preview) in EncryptionResetPasswordScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func encryptionResetScreen() async throws {
        for (index, preview) in EncryptionResetScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func estimatedWaveformView() async throws {
        for (index, preview) in EstimatedWaveformView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func fileMediaEventsTimelineView() async throws {
        for (index, preview) in FileMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func fileRoomTimelineView() async throws {
        for (index, preview) in FileRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func floatingDateBadge() async throws {
        for (index, preview) in FloatingDateBadge_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func formButtonStyles() async throws {
        for (index, preview) in FormButtonStyles_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func formattedBodyText() async throws {
        for (index, preview) in FormattedBodyText_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func formattingToolbar() async throws {
        for (index, preview) in FormattingToolbar_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func fullscreenDialog() async throws {
        for (index, preview) in FullscreenDialog_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func globalSearchScreenListRow() async throws {
        for (index, preview) in GlobalSearchScreenListRow_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func globalSearchScreen() async throws {
        for (index, preview) in GlobalSearchScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func highlightedTimelineItemModifier() async throws {
        for (index, preview) in HighlightedTimelineItemModifier_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func homeScreenEmptyStateView() async throws {
        for (index, preview) in HomeScreenEmptyStateView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func homeScreenInviteCell() async throws {
        for (index, preview) in HomeScreenInviteCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func homeScreenKnockedCell() async throws {
        for (index, preview) in HomeScreenKnockedCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func homeScreenNewSoundBanner() async throws {
        for (index, preview) in HomeScreenNewSoundBanner_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func homeScreenRecoveryKeyConfirmationBanner() async throws {
        for (index, preview) in HomeScreenRecoveryKeyConfirmationBanner_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func homeScreenRoomCell() async throws {
        for (index, preview) in HomeScreenRoomCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func homeScreen() async throws {
        for (index, preview) in HomeScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func identityConfirmationScreen() async throws {
        for (index, preview) in IdentityConfirmationScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func identityConfirmedScreen() async throws {
        for (index, preview) in IdentityConfirmedScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func imageMediaEventsTimelineView() async throws {
        for (index, preview) in ImageMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func imageRoomTimelineView() async throws {
        for (index, preview) in ImageRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func inviteUsersConfirmationSheetView() async throws {
        for (index, preview) in InviteUsersConfirmationSheetView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func inviteUsersScreenSelectedItem() async throws {
        for (index, preview) in InviteUsersScreenSelectedItem_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func inviteUsersScreen() async throws {
        for (index, preview) in InviteUsersScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func joinRoomByAddressView() async throws {
        for (index, preview) in JoinRoomByAddressView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func joinRoomScreenSpace() async throws {
        for (index, preview) in JoinRoomScreenSpace_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func joinRoomScreen() async throws {
        for (index, preview) in JoinRoomScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func joinedMembersBadgeView() async throws {
        for (index, preview) in JoinedMembersBadgeView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func knockRequestCell() async throws {
        for (index, preview) in KnockRequestCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func knockRequestsBannerView() async throws {
        for (index, preview) in KnockRequestsBannerView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func knockRequestsListEmptyStateView() async throws {
        for (index, preview) in KnockRequestsListEmptyStateView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func knockRequestsListScreen() async throws {
        for (index, preview) in KnockRequestsListScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func labsScreen() async throws {
        for (index, preview) in LabsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func leaveSpaceRoomDetailsCell() async throws {
        for (index, preview) in LeaveSpaceRoomDetailsCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func leaveSpaceView() async throws {
        for (index, preview) in LeaveSpaceView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func legalInformationScreen() async throws {
        for (index, preview) in LegalInformationScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func linkNewDeviceScreen() async throws {
        for (index, preview) in LinkNewDeviceScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func liveLocationRoomTimelineView() async throws {
        for (index, preview) in LiveLocationRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func liveLocationSharingBannerView() async throws {
        for (index, preview) in LiveLocationSharingBannerView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func liveLocationSheet() async throws {
        for (index, preview) in LiveLocationSheet_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func loadableImage() async throws {
        for (index, preview) in LoadableImage_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func locationMarkerView() async throws {
        for (index, preview) in LocationMarkerView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func locationPickerSheet() async throws {
        for (index, preview) in LocationPickerSheet_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func locationRoomTimelineView() async throws {
        for (index, preview) in LocationRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func locationSharingScreen() async throws {
        for (index, preview) in LocationSharingScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func loginScreen() async throws {
        for (index, preview) in LoginScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func longPressWithFeedback() async throws {
        for (index, preview) in LongPressWithFeedback_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func manageAuthorizedSpacesScreen() async throws {
        for (index, preview) in ManageAuthorizedSpacesScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func manageRoomMemberSheetView() async throws {
        for (index, preview) in ManageRoomMemberSheetView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func mapLibreStaticMapView() async throws {
        for (index, preview) in MapLibreStaticMapView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func matrixUserPermalink() async throws {
        for (index, preview) in MatrixUserPermalink_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func mediaEventsTimelineScreen() async throws {
        for (index, preview) in MediaEventsTimelineScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func mediaUploadPreviewScreen() async throws {
        for (index, preview) in MediaUploadPreviewScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func mentionSuggestionItemView() async throws {
        for (index, preview) in MentionSuggestionItemView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func messageComposerTextField() async throws {
        for (index, preview) in MessageComposerTextField_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func messageComposer() async throws {
        for (index, preview) in MessageComposer_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func messageForwardingScreen() async throws {
        for (index, preview) in MessageForwardingScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func messageText() async throws {
        for (index, preview) in MessageText_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func noticeRoomTimelineView() async throws {
        for (index, preview) in NoticeRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func notificationPermissionsScreen() async throws {
        for (index, preview) in NotificationPermissionsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func notificationSettingsEditScreenRoomCell() async throws {
        for (index, preview) in NotificationSettingsEditScreenRoomCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func notificationSettingsEditScreen() async throws {
        for (index, preview) in NotificationSettingsEditScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func notificationSettingsScreen() async throws {
        for (index, preview) in NotificationSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func pINTextField() async throws {
        for (index, preview) in PINTextField_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func paginationIndicatorRoomTimelineView() async throws {
        for (index, preview) in PaginationIndicatorRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func pillViewOnBubble() async throws {
        for (index, preview) in PillViewOnBubble_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func pillView() async throws {
        for (index, preview) in PillView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func pinnedEventsTimelineScreen() async throws {
        for (index, preview) in PinnedEventsTimelineScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func pinnedItemsBannerView() async throws {
        for (index, preview) in PinnedItemsBannerView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func pinnedItemsIndicatorView() async throws {
        for (index, preview) in PinnedItemsIndicatorView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func placeholderAvatarImage() async throws {
        for (index, preview) in PlaceholderAvatarImage_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func placeholderScreen() async throws {
        for (index, preview) in PlaceholderScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func playbackSpeedButton() async throws {
        for (index, preview) in PlaybackSpeedButton_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func pollFormScreen() async throws {
        for (index, preview) in PollFormScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func pollOptionView() async throws {
        for (index, preview) in PollOptionView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func pollRoomTimelineView() async throws {
        for (index, preview) in PollRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func pollView() async throws {
        for (index, preview) in PollView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func qRCodeErrorView() async throws {
        for (index, preview) in QRCodeErrorView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func qRCodeLoginScreen() async throws {
        for (index, preview) in QRCodeLoginScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func reactionsSummaryView() async throws {
        for (index, preview) in ReactionsSummaryView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func readMarkerRoomTimelineView() async throws {
        for (index, preview) in ReadMarkerRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func readReceiptCell() async throws {
        for (index, preview) in ReadReceiptCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func readReceiptsSummaryView() async throws {
        for (index, preview) in ReadReceiptsSummaryView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func redactedRoomTimelineView() async throws {
        for (index, preview) in RedactedRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func reportContentScreen() async throws {
        for (index, preview) in ReportContentScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func reportRoomScreen() async throws {
        for (index, preview) in ReportRoomScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func resolveVerifiedUserSendFailureScreen() async throws {
        for (index, preview) in ResolveVerifiedUserSendFailureScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomAttachmentPicker() async throws {
        for (index, preview) in RoomAttachmentPicker_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomAvatarImage() async throws {
        for (index, preview) in RoomAvatarImage_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomChangePermissionsScreen() async throws {
        for (index, preview) in RoomChangePermissionsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomChangeRolesScreenRow() async throws {
        for (index, preview) in RoomChangeRolesScreenRow_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomChangeRolesScreenSelectedItem() async throws {
        for (index, preview) in RoomChangeRolesScreenSelectedItem_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomChangeRolesScreen() async throws {
        for (index, preview) in RoomChangeRolesScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomDetailsEditScreen() async throws {
        for (index, preview) in RoomDetailsEditScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomDetailsScreen() async throws {
        for (index, preview) in RoomDetailsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomDirectorySearchCell() async throws {
        for (index, preview) in RoomDirectorySearchCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomDirectorySearchScreen() async throws {
        for (index, preview) in RoomDirectorySearchScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomHeaderView() async throws {
        for (index, preview) in RoomHeaderView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomInviterLabel() async throws {
        for (index, preview) in RoomInviterLabel_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomListFilterView() async throws {
        for (index, preview) in RoomListFilterView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomListFiltersEmptyStateView() async throws {
        for (index, preview) in RoomListFiltersEmptyStateView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomListFiltersView() async throws {
        for (index, preview) in RoomListFiltersView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomMemberDetailsScreen() async throws {
        for (index, preview) in RoomMemberDetailsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomMembersListMemberCell() async throws {
        for (index, preview) in RoomMembersListMemberCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomMembersListScreen() async throws {
        for (index, preview) in RoomMembersListScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomNotificationSettingsCustomSectionView() async throws {
        for (index, preview) in RoomNotificationSettingsCustomSectionView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomNotificationSettingsScreen() async throws {
        for (index, preview) in RoomNotificationSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomNotificationSettingsUserDefinedScreen() async throws {
        for (index, preview) in RoomNotificationSettingsUserDefinedScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomPollsHistoryScreen() async throws {
        for (index, preview) in RoomPollsHistoryScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomRolesAndPermissionsScreen() async throws {
        for (index, preview) in RoomRolesAndPermissionsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomScreenFooterView() async throws {
        for (index, preview) in RoomScreenFooterView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomScreen() async throws {
        for (index, preview) in RoomScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomSelectionScreen() async throws {
        for (index, preview) in RoomSelectionScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func roomThreadListScreen() async throws {
        for (index, preview) in RoomThreadListScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func sFNumberedListView() async throws {
        for (index, preview) in SFNumberedListView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func secureBackupKeyBackupScreen() async throws {
        for (index, preview) in SecureBackupKeyBackupScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func secureBackupLogoutConfirmationScreen() async throws {
        for (index, preview) in SecureBackupLogoutConfirmationScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func secureBackupRecoveryKeyScreen() async throws {
        for (index, preview) in SecureBackupRecoveryKeyScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func secureBackupScreen() async throws {
        for (index, preview) in SecureBackupScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func securityAndPrivacyScreen() async throws {
        for (index, preview) in SecurityAndPrivacyScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func sendInviteConfirmationView() async throws {
        for (index, preview) in SendInviteConfirmationView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func separatorMediaEventsTimelineView() async throws {
        for (index, preview) in SeparatorMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func separatorRoomTimelineView() async throws {
        for (index, preview) in SeparatorRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func serverConfirmationScreen() async throws {
        for (index, preview) in ServerConfirmationScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func serverSelection() async throws {
        for (index, preview) in ServerSelection_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func sessionVerificationRequestDetailsView() async throws {
        for (index, preview) in SessionVerificationRequestDetailsView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func sessionVerification() async throws {
        for (index, preview) in SessionVerification_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func settingsScreen() async throws {
        for (index, preview) in SettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func shimmerOverlay() async throws {
        for (index, preview) in ShimmerOverlay_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func softLogoutScreen() async throws {
        for (index, preview) in SoftLogoutScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func spaceAddRoomsScreenSelectedItem() async throws {
        for (index, preview) in SpaceAddRoomsScreenSelectedItem_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func spaceAddRoomsScreen() async throws {
        for (index, preview) in SpaceAddRoomsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func spaceHeaderTopicSheetView() async throws {
        for (index, preview) in SpaceHeaderTopicSheetView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func spaceHeaderView() async throws {
        for (index, preview) in SpaceHeaderView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func spaceRemoveChildrenConfirmationView() async throws {
        for (index, preview) in SpaceRemoveChildrenConfirmationView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func spaceRoomCell() async throws {
        for (index, preview) in SpaceRoomCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func spaceScreen() async throws {
        for (index, preview) in SpaceScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func spaceSettingsScreen() async throws {
        for (index, preview) in SpaceSettingsScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func spacesScreen() async throws {
        for (index, preview) in SpacesScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func splashScreen() async throws {
        for (index, preview) in SplashScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func stackedAvatarsView() async throws {
        for (index, preview) in StackedAvatarsView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func startChatScreen() async throws {
        for (index, preview) in StartChatScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func stateRoomTimelineView() async throws {
        for (index, preview) in StateRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func staticLocationSheet() async throws {
        for (index, preview) in StaticLocationSheet_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func stickerRoomTimelineView() async throws {
        for (index, preview) in StickerRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func swipeRightAction() async throws {
        for (index, preview) in SwipeRightAction_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func swipeToReplyView() async throws {
        for (index, preview) in SwipeToReplyView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func textRoomTimelineView() async throws {
        for (index, preview) in TextRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func threadDecorator() async throws {
        for (index, preview) in ThreadDecorator_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineDeliveryStatusView() async throws {
        for (index, preview) in TimelineDeliveryStatusView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineItemBubbledStylerView() async throws {
        for (index, preview) in TimelineItemBubbledStylerView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineItemDebugView() async throws {
        for (index, preview) in TimelineItemDebugView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineItemMenu() async throws {
        for (index, preview) in TimelineItemMenu_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineItemSendInfoLabel() async throws {
        for (index, preview) in TimelineItemSendInfoLabel_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineItemStyler() async throws {
        for (index, preview) in TimelineItemStyler_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineMediaPreviewDetailsView() async throws {
        for (index, preview) in TimelineMediaPreviewDetailsView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineMediaPreviewRedactConfirmationView() async throws {
        for (index, preview) in TimelineMediaPreviewRedactConfirmationView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineReactionView() async throws {
        for (index, preview) in TimelineReactionView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineReadReceiptsView() async throws {
        for (index, preview) in TimelineReadReceiptsView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineReplyView() async throws {
        for (index, preview) in TimelineReplyView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineScrollButton() async throws {
        for (index, preview) in TimelineScrollButton_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineStartRoomTimelineView() async throws {
        for (index, preview) in TimelineStartRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func timelineThreadSummaryView() async throws {
        for (index, preview) in TimelineThreadSummaryView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func tombstonedAvatarImage() async throws {
        for (index, preview) in TombstonedAvatarImage_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func toolbarButton() async throws {
        for (index, preview) in ToolbarButton_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func typingIndicatorView() async throws {
        for (index, preview) in TypingIndicatorView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func unsupportedRoomTimelineView() async throws {
        for (index, preview) in UnsupportedRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func userDetailsEditScreen() async throws {
        for (index, preview) in UserDetailsEditScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func userIndicatorModalView() async throws {
        for (index, preview) in UserIndicatorModalView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func userIndicatorToastView() async throws {
        for (index, preview) in UserIndicatorToastView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func userLocationCell() async throws {
        for (index, preview) in UserLocationCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func userProfileCell() async throws {
        for (index, preview) in UserProfileCell_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func userProfileScreen() async throws {
        for (index, preview) in UserProfileScreen_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func verificationBadge() async throws {
        for (index, preview) in VerificationBadge_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func videoMediaEventsTimelineView() async throws {
        for (index, preview) in VideoMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func videoRoomTimelineView() async throws {
        for (index, preview) in VideoRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func visualListItem() async throws {
        for (index, preview) in VisualListItem_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func voiceMessageButton() async throws {
        for (index, preview) in VoiceMessageButton_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func voiceMessageMediaEventsTimelineView() async throws {
        for (index, preview) in VoiceMessageMediaEventsTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func voiceMessagePreviewComposer() async throws {
        for (index, preview) in VoiceMessagePreviewComposer_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func voiceMessageRecordingButton() async throws {
        for (index, preview) in VoiceMessageRecordingButton_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func voiceMessageRecordingComposer() async throws {
        for (index, preview) in VoiceMessageRecordingComposer_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func voiceMessageRecordingView() async throws {
        for (index, preview) in VoiceMessageRecordingView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func voiceMessageRoomPlaybackView() async throws {
        for (index, preview) in VoiceMessageRoomPlaybackView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func voiceMessageRoomTimelineView() async throws {
        for (index, preview) in VoiceMessageRoomTimelineView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func voiceMessageTrashButton() async throws {
        for (index, preview) in VoiceMessageTrashButton_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test
    func waveformCursorView() async throws {
        for (index, preview) in WaveformCursorView_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }
}

// swiftlint:enable all
// swiftformat:enable all
