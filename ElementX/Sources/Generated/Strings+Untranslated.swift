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
  /// Match
  public static let actionMatch = ElementL10n.tr("Untranslated", "action_match")
  /// Please describe the bug. What did you do? What did you expect to happen? What actually happened. Please go into as much detail as you can.
  public static let bugReportScreenDescription = ElementL10n.tr("Untranslated", "bug_report_screen_description")
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
  /// About
  public static let roomDetailsAboutSectionTitle = ElementL10n.tr("Untranslated", "room_details_about_section_title")
  /// Copy Link
  public static let roomDetailsCopyLink = ElementL10n.tr("Untranslated", "room_details_copy_link")
  /// Info
  public static let roomDetailsTitle = ElementL10n.tr("Untranslated", "room_details_title")
  /// Failed loading messages
  public static let roomTimelineBackpaginationFailure = ElementL10n.tr("Untranslated", "room_timeline_backpagination_failure")
  /// Retry decryption
  public static let roomTimelineContextMenuRetryDecryption = ElementL10n.tr("Untranslated", "room_timeline_context_menu_retry_decryption")
  /// Editing
  public static let roomTimelineEditing = ElementL10n.tr("Untranslated", "room_timeline_editing")
  /// Unsupported event
  public static let roomTimelineItemUnsupported = ElementL10n.tr("Untranslated", "room_timeline_item_unsupported")
  /// Failed creating the permalink
  public static let roomTimelinePermalinkCreationFailure = ElementL10n.tr("Untranslated", "room_timeline_permalink_creation_failure")
  /// Replying to %@
  public static func roomTimelineReplyingTo(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "room_timeline_replying_to", String(describing: p1))
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
  /// You can only connect to an existing server
  public static let serverSelectionServerFooter = ElementL10n.tr("Untranslated", "server_selection_server_footer")
  /// Looks like you’re using a new device. Verify it’s you to access your encrypted messages.
  public static let sessionVerificationBannerMessage = ElementL10n.tr("Untranslated", "session_verification_banner_message")
  /// Access your message history
  public static let sessionVerificationBannerTitle = ElementL10n.tr("Untranslated", "session_verification_banner_title")
  /// Start
  public static let sessionVerificationStart = ElementL10n.tr("Untranslated", "session_verification_start")
  /// Appearance
  public static let settingsAppearance = ElementL10n.tr("Untranslated", "settings_appearance")
  /// Complete verification
  public static let settingsSessionVerification = ElementL10n.tr("Untranslated", "settings_session_verification")
  /// Message layout
  public static let settingsTimelineStyle = ElementL10n.tr("Untranslated", "settings_timeline_style")
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
