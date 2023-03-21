// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
extension ElementL10n {
  /// User menu
  public static let a11yAllChatsUserAvatarMenu = ElementL10n.tr("Untranslated", "a11y_all_chats_user_avatar_menu")
  /// Confirm
  public static let actionConfirm = ElementL10n.tr("Untranslated", "action_confirm")
  /// Copy Link
  public static let actionCopyLink = ElementL10n.tr("Untranslated", "action_copy_link")
  /// Match
  public static let actionMatch = ElementL10n.tr("Untranslated", "action_match")
  /// Share Link
  public static let actionShareLink = ElementL10n.tr("Untranslated", "action_share_link")
  /// Help us identify issues and improve %@ by sharing anonymous usage data. To understand how people use multiple devices, we’ll generate a random identifier, shared by your devices.
  /// 
  /// You can read all our terms %@.
  public static func analyticsOptInContent(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Untranslated", "analytics_opt_in_content", String(describing: p1), String(describing: p2))
  }
  /// here
  public static let analyticsOptInContentLink = ElementL10n.tr("Untranslated", "analytics_opt_in_content_link")
  /// We <b>don't</b> record or profile any account data
  public static let analyticsOptInListItem1 = ElementL10n.tr("Untranslated", "analytics_opt_in_list_item_1")
  /// We <b>don't</b> share information with third parties
  public static let analyticsOptInListItem2 = ElementL10n.tr("Untranslated", "analytics_opt_in_list_item_2")
  /// You can turn this off anytime in settings
  public static let analyticsOptInListItem3 = ElementL10n.tr("Untranslated", "analytics_opt_in_list_item_3")
  /// Help improve %@
  public static func analyticsOptInTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "analytics_opt_in_title", String(describing: p1))
  }
  /// Attach Screenshot
  public static let bugReportScreenAttachScreenshot = ElementL10n.tr("Untranslated", "bug_report_screen_attach_screenshot")
  /// Please describe the bug. What did you do? What did you expect to happen? What actually happened. Please go into as much detail as you can.
  public static let bugReportScreenDescription = ElementL10n.tr("Untranslated", "bug_report_screen_description")
  /// Edit Screenshot
  public static let bugReportScreenEditScreenshot = ElementL10n.tr("Untranslated", "bug_report_screen_edit_screenshot")
  /// Describe the bug…
  public static let bugReportScreenEditorPlaceholder = ElementL10n.tr("Untranslated", "bug_report_screen_editor_placeholder")
  /// Send logs to help
  public static let bugReportScreenIncludeLogs = ElementL10n.tr("Untranslated", "bug_report_screen_include_logs")
  /// To check things work as intended, logs will be sent with your message. These will be private. To just send your message, turn off this setting.
  public static let bugReportScreenLogsDescription = ElementL10n.tr("Untranslated", "bug_report_screen_logs_description")
  /// Report a bug
  public static let bugReportScreenTitle = ElementL10n.tr("Untranslated", "bug_report_screen_title")
  /// %@ iOS
  public static func defaultSessionDisplayName(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "default_session_display_name", String(describing: p1))
  }
  /// Welcome to the %@ Beta. Supercharged, for speed and simplicity.
  public static func ftueAuthCarouselWelcomeBody(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "ftue_auth_carousel_welcome_body", String(describing: p1))
  }
  /// Be in your Element
  public static let ftueAuthCarouselWelcomeTitle = ElementL10n.tr("Untranslated", "ftue_auth_carousel_welcome_title")
  /// Enter your details
  public static let ftueAuthSignInEnterDetails = ElementL10n.tr("Untranslated", "ftue_auth_sign_in_enter_details")
  /// No
  public static let iosNo = ElementL10n.tr("Untranslated", "ios_no")
  /// Yes
  public static let iosYes = ElementL10n.tr("Untranslated", "ios_yes")
  /// Mobile
  public static let loginMobileDevice = ElementL10n.tr("Untranslated", "login_mobile_device")
  /// Tablet
  public static let loginTabletDevice = ElementL10n.tr("Untranslated", "login_tablet_device")
  /// Message
  public static let message = ElementL10n.tr("Untranslated", "message")
  /// %1$@ accepted the invite
  public static func noticeRoomInviteAccepted(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "noticeRoomInviteAccepted", String(describing: p1))
  }
  /// You accepted the invite
  public static let noticeRoomInviteAcceptedByYou = ElementL10n.tr("Untranslated", "noticeRoomInviteAcceptedByYou")
  /// %1$@ requested to join
  public static func noticeRoomKnock(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "noticeRoomKnock", String(describing: p1))
  }
  /// %1$@ allowed %2$@ to join
  public static func noticeRoomKnockAccepted(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Untranslated", "noticeRoomKnockAccepted", String(describing: p1), String(describing: p2))
  }
  /// %1$@ allowed you to join
  public static func noticeRoomKnockAcceptedByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "noticeRoomKnockAcceptedByYou", String(describing: p1))
  }
  /// You requested to join
  public static let noticeRoomKnockByYou = ElementL10n.tr("Untranslated", "noticeRoomKnockByYou")
  /// %1$@ rejected %2$@'s request to join
  public static func noticeRoomKnockDenied(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Untranslated", "noticeRoomKnockDenied", String(describing: p1), String(describing: p2))
  }
  /// You rejected %1$@'s request to join
  public static func noticeRoomKnockDeniedByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "noticeRoomKnockDeniedByYou", String(describing: p1))
  }
  /// %1$@ rejected your request to join
  public static func noticeRoomKnockDeniedYou(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "noticeRoomKnockDeniedYou", String(describing: p1))
  }
  /// %1$@ is no longer interested in joining
  public static func noticeRoomKnockRetracted(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "noticeRoomKnockRetracted", String(describing: p1))
  }
  /// You cancelled your request to join
  public static let noticeRoomKnockRetractedByYou = ElementL10n.tr("Untranslated", "noticeRoomKnockRetractedByYou")
  /// %1$@ made an unknown change to their membership
  public static func noticeRoomUnknownMembershipChange(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "noticeRoomUnknownMembershipChange", String(describing: p1))
  }
  /// Notification
  public static let notification = ElementL10n.tr("Untranslated", "Notification")
  /// Reporting this message will send it’s unique ‘event ID’ to the administrator of your homeserver. If messages in this room are encrypted, your homeserver administrator will not be able to read the message text or view any files or images.
  public static let reportContentInfo = ElementL10n.tr("Untranslated", "report_content_info")
  /// Report Submitted
  public static let reportContentSubmitted = ElementL10n.tr("Untranslated", "report_content_submitted")
  /// An error occurred when trying to start a chat
  public static let retrievingDirectRoomError = ElementL10n.tr("Untranslated", "retrieving_direct_room_error")
  /// About
  public static let roomDetailsAboutSectionTitle = ElementL10n.tr("Untranslated", "room_details_about_section_title")
  /// Are you sure that you want to leave this room? You are the only person here. If you leave, no one will be able to join in the future, including you.
  public static let roomDetailsLeaveEmptyRoomAlertSubtitle = ElementL10n.tr("Untranslated", "room_details_leave_empty_room_alert_subtitle")
  /// Are you sure that you want to leave this room? This room is not public and you will not be able to rejoin without an invite.
  public static let roomDetailsLeavePrivateRoomAlertSubtitle = ElementL10n.tr("Untranslated", "room_details_leave_private_room_alert_subtitle")
  /// Are you sure that you want to leave the room?
  public static let roomDetailsLeaveRoomAlertSubtitle = ElementL10n.tr("Untranslated", "room_details_leave_room_alert_subtitle")
  /// Room left
  public static let roomDetailsRoomLeftToast = ElementL10n.tr("Untranslated", "room_details_room_left_toast")
  /// Info
  public static let roomDetailsTitle = ElementL10n.tr("Untranslated", "room_details_title")
  /// Block
  public static let roomMemberDetailsBlockAlertAction = ElementL10n.tr("Untranslated", "room_member_details_block_alert_action")
  /// Blocked users will not be able to send you messages and all message by them will be hidden. You can reverse this action anytime.
  public static let roomMemberDetailsBlockAlertDescription = ElementL10n.tr("Untranslated", "room_member_details_block_alert_description")
  /// Block user
  public static let roomMemberDetailsBlockUser = ElementL10n.tr("Untranslated", "room_member_details_block_user")
  /// Unblock
  public static let roomMemberDetailsUnblockAlertAction = ElementL10n.tr("Untranslated", "room_member_details_unblock_alert_action")
  /// On unblocking the user, you will be able to see all messages by them again.
  public static let roomMemberDetailsUnblockAlertDescription = ElementL10n.tr("Untranslated", "room_member_details_unblock_alert_description")
  /// Unblock user
  public static let roomMemberDetailsUnblockUser = ElementL10n.tr("Untranslated", "room_member_details_unblock_user")
  /// Failed loading messages
  public static let roomTimelineBackpaginationFailure = ElementL10n.tr("Untranslated", "room_timeline_backpagination_failure")
  /// Retry decryption
  public static let roomTimelineContextMenuRetryDecryption = ElementL10n.tr("Untranslated", "room_timeline_context_menu_retry_decryption")
  /// Editing
  public static let roomTimelineEditing = ElementL10n.tr("Untranslated", "room_timeline_editing")
  /// GIF
  public static let roomTimelineImageGif = ElementL10n.tr("Untranslated", "room_timeline_image_gif")
  /// Unsupported event
  public static let roomTimelineItemUnsupported = ElementL10n.tr("Untranslated", "room_timeline_item_unsupported")
  /// Failed creating the permalink
  public static let roomTimelinePermalinkCreationFailure = ElementL10n.tr("Untranslated", "room_timeline_permalink_creation_failure")
  /// New
  public static let roomTimelineReadMarkerTitle = ElementL10n.tr("Untranslated", "room_timeline_read_marker_title")
  /// Replying to %@
  public static func roomTimelineReplyingTo(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "room_timeline_replying_to", String(describing: p1))
  }
  /// %d room changes
  public static func roomTimelineStateChanges(_ p1: Int) -> String {
    return ElementL10n.tr("Untranslated", "room_timeline_state_changes", p1)
  }
  /// Bubbles
  public static let roomTimelineStyleBubbledLongDescription = ElementL10n.tr("Untranslated", "room_timeline_style_bubbled_long_description")
  /// Modern
  public static let roomTimelineStylePlainLongDescription = ElementL10n.tr("Untranslated", "room_timeline_style_plain_long_description")
  /// Syncing
  public static let roomTimelineSyncing = ElementL10n.tr("Untranslated", "room_timeline_syncing")
  /// Unable to decrypt
  public static let roomTimelineUnableToDecrypt = ElementL10n.tr("Untranslated", "room_timeline_unable_to_decrypt")
  /// Would you like to submit a bug report?
  public static let screenshotDetectedMessage = ElementL10n.tr("Untranslated", "screenshot_detected_message")
  /// You took a screenshot
  public static let screenshotDetectedTitle = ElementL10n.tr("Untranslated", "screenshot_detected_title")
  /// Sending...
  public static let sending = ElementL10n.tr("Untranslated", "sending")
  /// You can only connect to an existing server that supports sliding sync. Your homeserver admin will need to configure it. %@
  public static func serverSelectionServerFooter(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "server_selection_server_footer", String(describing: p1))
  }
  /// This server currently doesn’t support sliding sync.
  public static let serverSelectionSlidingSyncAlertMessage = ElementL10n.tr("Untranslated", "server_selection_sliding_sync_alert_message")
  /// Server not supported
  public static let serverSelectionSlidingSyncAlertTitle = ElementL10n.tr("Untranslated", "server_selection_sliding_sync_alert_title")
  /// Looks like you’re using a new device. Verify it’s you to access your encrypted messages.
  public static let sessionVerificationBannerMessage = ElementL10n.tr("Untranslated", "session_verification_banner_message")
  /// Access your message history
  public static let sessionVerificationBannerTitle = ElementL10n.tr("Untranslated", "session_verification_banner_title")
  /// Start
  public static let sessionVerificationStart = ElementL10n.tr("Untranslated", "session_verification_start")
  /// Appearance
  public static let settingsAppearance = ElementL10n.tr("Untranslated", "settings_appearance")
  /// Developer options
  public static let settingsDeveloperOptions = ElementL10n.tr("Untranslated", "settings_developer_options")
  /// Complete verification
  public static let settingsSessionVerification = ElementL10n.tr("Untranslated", "settings_session_verification")
  /// Message layout
  public static let settingsTimelineStyle = ElementL10n.tr("Untranslated", "settings_timeline_style")
  /// Clear all data currently stored on this device?
  /// Sign in again to access your account data and messages.
  public static let softLogoutClearDataDialogContent = ElementL10n.tr("Untranslated", "soft_logout_clear_data_dialog_content")
  /// Clear data
  public static let softLogoutClearDataDialogTitle = ElementL10n.tr("Untranslated", "soft_logout_clear_data_dialog_title")
  /// Warning: Your personal data (including encryption keys) is still stored on this device.
  /// 
  /// Clear it if you’re finished using this device, or want to sign in to another account.
  public static let softLogoutClearDataNotice = ElementL10n.tr("Untranslated", "soft_logout_clear_data_notice")
  /// Clear all data
  public static let softLogoutClearDataSubmit = ElementL10n.tr("Untranslated", "soft_logout_clear_data_submit")
  /// Clear personal data
  public static let softLogoutClearDataTitle = ElementL10n.tr("Untranslated", "soft_logout_clear_data_title")
  /// Sign in to recover encryption keys stored exclusively on this device. You need them to read all of your secure messages on any device.
  public static let softLogoutSigninE2eWarningNotice = ElementL10n.tr("Untranslated", "soft_logout_signin_e2e_warning_notice")
  /// Your homeserver (%1$s) admin has signed you out of your account %2$s (%3$s).
  public static func softLogoutSigninNotice(_ p1: UnsafePointer<CChar>, _ p2: UnsafePointer<CChar>, _ p3: UnsafePointer<CChar>) -> String {
    return ElementL10n.tr("Untranslated", "soft_logout_signin_notice", p1, p2, p3)
  }
  /// Sign in
  public static let softLogoutSigninTitle = ElementL10n.tr("Untranslated", "soft_logout_signin_title")
  /// Untranslated
  public static let untranslated = ElementL10n.tr("Untranslated", "untranslated")
  /// Plural format key: "%#@VARIABLE@"
  public static func untranslatedPlural(_ p1: Int) -> String {
    return ElementL10n.tr("Untranslated", "untranslated_plural", p1)
  }
  /// Confirm that the emojis below match those shown on your other session.
  public static let verificationCompareEmojisDetail = ElementL10n.tr("Untranslated", "verification_compare_emojis_detail")
  /// Compare emojis
  public static let verificationCompareEmojisTitle = ElementL10n.tr("Untranslated", "verification_compare_emojis_title")
  /// Verification complete
  public static let verificationConclusionOkSelfNoticeTitle = ElementL10n.tr("Untranslated", "verification_conclusion_ok_self_notice_title")
  /// Prove it’s you in order to access your encrypted message history.
  public static let verificationOpenOtherToVerifyDetail = ElementL10n.tr("Untranslated", "verification_open_other_to_verify_detail")
  /// Open an existing session
  public static let verificationOpenOtherToVerifyTitle = ElementL10n.tr("Untranslated", "verification_open_other_to_verify_title")
  /// Something doesn’t seem right. Either the request timed out or the request was denied.
  public static let verificationRequestCancelledDetail = ElementL10n.tr("Untranslated", "verification_request_cancelled_detail")
  /// Verification cancelled
  public static let verificationRequestCancelledTitle = ElementL10n.tr("Untranslated", "verification_request_cancelled_title")
  /// Accept the request to start the verification process in your other session to continue.
  public static let verificationRequestWaitingAcceptRequestDetail = ElementL10n.tr("Untranslated", "verification_request_waiting_accept_request_detail")
  /// Waiting to accept request
  public static let verificationRequestWaitingAcceptRequestTitle = ElementL10n.tr("Untranslated", "verification_request_waiting_accept_request_title")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces
