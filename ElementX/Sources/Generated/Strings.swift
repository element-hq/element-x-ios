// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum ElementL10n {
  /// Continue
  public static var `continue`: String { return ElementL10n.tr("Localizable", "_continue") }
  /// %1$@, %2$@, %3$@
  public static func a11yAudioMessageItem(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "a11y_audio_message_item", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// %1$d minutes %2$d seconds
  public static func a11yAudioPlaybackDuration(_ p1: Int, _ p2: Int) -> String {
    return ElementL10n.tr("Localizable", "a11y_audio_playback_duration", p1, p2)
  }
  /// Change avatar
  public static var a11yChangeAvatar: String { return ElementL10n.tr("Localizable", "a11y_change_avatar") }
  /// Checked
  public static var a11yChecked: String { return ElementL10n.tr("Localizable", "a11y_checked") }
  /// Close Emoji picker
  public static var a11yCloseEmojiPicker: String { return ElementL10n.tr("Localizable", "a11y_close_emoji_picker") }
  /// Close keys backup banner
  public static var a11yCloseKeysBackupBanner: String { return ElementL10n.tr("Localizable", "a11y_close_keys_backup_banner") }
  /// Collapse %@ children
  public static func a11yCollapseSpaceChildren(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "a11y_collapse_space_children", String(describing: p1))
  }
  /// Create a new direct conversation
  public static var a11yCreateDirectMessage: String { return ElementL10n.tr("Localizable", "a11y_create_direct_message") }
  /// Close the create room menu…
  public static var a11yCreateMenuClose: String { return ElementL10n.tr("Localizable", "a11y_create_menu_close") }
  /// Open the create room menu
  public static var a11yCreateMenuOpen: String { return ElementL10n.tr("Localizable", "a11y_create_menu_open") }
  /// Create a new conversation or room
  public static var a11yCreateMessage: String { return ElementL10n.tr("Localizable", "a11y_create_message") }
  /// Create a new room
  public static var a11yCreateRoom: String { return ElementL10n.tr("Localizable", "a11y_create_room") }
  /// Delete avatar
  public static var a11yDeleteAvatar: String { return ElementL10n.tr("Localizable", "a11y_delete_avatar") }
  /// Delete recording
  public static var a11yDeleteRecordedVoiceMessage: String { return ElementL10n.tr("Localizable", "a11y_delete_recorded_voice_message") }
  /// Desktop
  public static var a11yDeviceManagerDeviceTypeDesktop: String { return ElementL10n.tr("Localizable", "a11y_device_manager_device_type_desktop") }
  /// Mobile
  public static var a11yDeviceManagerDeviceTypeMobile: String { return ElementL10n.tr("Localizable", "a11y_device_manager_device_type_mobile") }
  /// Unknown device type
  public static var a11yDeviceManagerDeviceTypeUnknown: String { return ElementL10n.tr("Localizable", "a11y_device_manager_device_type_unknown") }
  /// Web
  public static var a11yDeviceManagerDeviceTypeWeb: String { return ElementL10n.tr("Localizable", "a11y_device_manager_device_type_web") }
  /// Message not sent due to error
  public static var a11yErrorMessageNotSent: String { return ElementL10n.tr("Localizable", "a11y_error_message_not_sent") }
  /// Some messages have not been sent
  public static var a11yErrorSomeMessageNotSent: String { return ElementL10n.tr("Localizable", "a11y_error_some_message_not_sent") }
  /// Expand %@ children
  public static func a11yExpandSpaceChildren(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "a11y_expand_space_children", String(describing: p1))
  }
  /// Image
  public static var a11yImage: String { return ElementL10n.tr("Localizable", "a11y_image") }
  /// Import key from file
  public static var a11yImportKeyFromFile: String { return ElementL10n.tr("Localizable", "a11y_import_key_from_file") }
  /// Jump to bottom
  public static var a11yJumpToBottom: String { return ElementL10n.tr("Localizable", "a11y_jump_to_bottom") }
  /// Zoom to current location
  public static var a11yLocationShareLocateButton: String { return ElementL10n.tr("Localizable", "a11y_location_share_locate_button") }
  /// Share this location
  public static var a11yLocationShareOptionPinnedIcon: String { return ElementL10n.tr("Localizable", "a11y_location_share_option_pinned_icon") }
  /// Share my current location
  public static var a11yLocationShareOptionUserCurrentIcon: String { return ElementL10n.tr("Localizable", "a11y_location_share_option_user_current_icon") }
  /// Share live location
  public static var a11yLocationShareOptionUserLiveIcon: String { return ElementL10n.tr("Localizable", "a11y_location_share_option_user_live_icon") }
  /// Pin of selected location on map
  public static var a11yLocationSharePinOnMap: String { return ElementL10n.tr("Localizable", "a11y_location_share_pin_on_map") }
  /// Mute the microphone
  public static var a11yMuteMicrophone: String { return ElementL10n.tr("Localizable", "a11y_mute_microphone") }
  /// Open chat
  public static var a11yOpenChat: String { return ElementL10n.tr("Localizable", "a11y_open_chat") }
  /// Open the navigation drawer
  public static var a11yOpenDrawer: String { return ElementL10n.tr("Localizable", "a11y_open_drawer") }
  /// Open Emoji picker
  public static var a11yOpenEmojiPicker: String { return ElementL10n.tr("Localizable", "a11y_open_emoji_picker") }
  /// Open settings
  public static var a11yOpenSettings: String { return ElementL10n.tr("Localizable", "a11y_open_settings") }
  /// Open spaces list
  public static var a11yOpenSpaces: String { return ElementL10n.tr("Localizable", "a11y_open_spaces") }
  /// Open widgets
  public static var a11yOpenWidget: String { return ElementL10n.tr("Localizable", "a11y_open_widget") }
  /// Pause %1$@
  public static func a11yPauseAudioMessage(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "a11y_pause_audio_message", String(describing: p1))
  }
  /// Pause Voice Message
  public static var a11yPauseVoiceMessage: String { return ElementL10n.tr("Localizable", "a11y_pause_voice_message") }
  /// Play %1$@
  public static func a11yPlayAudioMessage(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "a11y_play_audio_message", String(describing: p1))
  }
  /// Play Voice Message
  public static var a11yPlayVoiceMessage: String { return ElementL10n.tr("Localizable", "a11y_play_voice_message") }
  /// winner option
  public static var a11yPollWinnerOption: String { return ElementL10n.tr("Localizable", "a11y_poll_winner_option") }
  /// Busy
  public static var a11yPresenceBusy: String { return ElementL10n.tr("Localizable", "a11y_presence_busy") }
  /// Offline
  public static var a11yPresenceOffline: String { return ElementL10n.tr("Localizable", "a11y_presence_offline") }
  /// Online
  public static var a11yPresenceOnline: String { return ElementL10n.tr("Localizable", "a11y_presence_online") }
  /// Away
  public static var a11yPresenceUnavailable: String { return ElementL10n.tr("Localizable", "a11y_presence_unavailable") }
  /// Public room
  public static var a11yPublicRoom: String { return ElementL10n.tr("Localizable", "a11y_public_room") }
  /// QR code
  public static var a11yQrCodeForVerification: String { return ElementL10n.tr("Localizable", "a11y_qr_code_for_verification") }
  /// Recording voice message
  public static var a11yRecordingVoiceMessage: String { return ElementL10n.tr("Localizable", "a11y_recording_voice_message") }
  /// Notify with sound
  public static var a11yRuleNotifyNoisy: String { return ElementL10n.tr("Localizable", "a11y_rule_notify_noisy") }
  /// Do not notify
  public static var a11yRuleNotifyOff: String { return ElementL10n.tr("Localizable", "a11y_rule_notify_off") }
  /// Notify without sound
  public static var a11yRuleNotifySilent: String { return ElementL10n.tr("Localizable", "a11y_rule_notify_silent") }
  /// Screenshot
  public static var a11yScreenshot: String { return ElementL10n.tr("Localizable", "a11y_screenshot") }
  /// Selected
  public static var a11ySelected: String { return ElementL10n.tr("Localizable", "a11y_selected") }
  /// Start the camera
  public static var a11yStartCamera: String { return ElementL10n.tr("Localizable", "a11y_start_camera") }
  /// Record Voice Message
  public static var a11yStartVoiceMessage: String { return ElementL10n.tr("Localizable", "a11y_start_voice_message") }
  /// Map
  public static var a11yStaticMapImage: String { return ElementL10n.tr("Localizable", "a11y_static_map_image") }
  /// Stop the camera
  public static var a11yStopCamera: String { return ElementL10n.tr("Localizable", "a11y_stop_camera") }
  /// Stop Recording
  public static var a11yStopVoiceMessage: String { return ElementL10n.tr("Localizable", "a11y_stop_voice_message") }
  /// Default trust level
  public static var a11yTrustLevelDefault: String { return ElementL10n.tr("Localizable", "a11y_trust_level_default") }
  /// Trusted trust level
  public static var a11yTrustLevelTrusted: String { return ElementL10n.tr("Localizable", "a11y_trust_level_trusted") }
  /// Warning trust level
  public static var a11yTrustLevelWarning: String { return ElementL10n.tr("Localizable", "a11y_trust_level_warning") }
  /// Unchecked
  public static var a11yUnchecked: String { return ElementL10n.tr("Localizable", "a11y_unchecked") }
  /// Unmute the microphone
  public static var a11yUnmuteMicrophone: String { return ElementL10n.tr("Localizable", "a11y_unmute_microphone") }
  /// has unsent draft
  public static var a11yUnsentDraft: String { return ElementL10n.tr("Localizable", "a11y_unsent_draft") }
  /// Video
  public static var a11yVideo: String { return ElementL10n.tr("Localizable", "a11y_video") }
  /// View read receipts
  public static var a11yViewReadReceipts: String { return ElementL10n.tr("Localizable", "a11y_view_read_receipts") }
  /// This email address is already in use.
  public static var accountEmailAlreadyUsedError: String { return ElementL10n.tr("Localizable", "account_email_already_used_error") }
  /// Please check your email and click on the link it contains. Once this is done, click continue.
  public static var accountEmailValidationMessage: String { return ElementL10n.tr("Localizable", "account_email_validation_message") }
  /// This phone number is already in use.
  public static var accountPhoneNumberAlreadyUsedError: String { return ElementL10n.tr("Localizable", "account_phone_number_already_used_error") }
  /// Accept
  public static var actionAccept: String { return ElementL10n.tr("Localizable", "action_accept") }
  /// Add
  public static var actionAdd: String { return ElementL10n.tr("Localizable", "action_add") }
  /// Agree
  public static var actionAgree: String { return ElementL10n.tr("Localizable", "action_agree") }
  /// Cancel
  public static var actionCancel: String { return ElementL10n.tr("Localizable", "action_cancel") }
  /// Change
  public static var actionChange: String { return ElementL10n.tr("Localizable", "action_change") }
  /// Close
  public static var actionClose: String { return ElementL10n.tr("Localizable", "action_close") }
  /// Copy
  public static var actionCopy: String { return ElementL10n.tr("Localizable", "action_copy") }
  /// Decline
  public static var actionDecline: String { return ElementL10n.tr("Localizable", "action_decline") }
  /// Delete
  public static var actionDelete: String { return ElementL10n.tr("Localizable", "action_delete") }
  /// Disable
  public static var actionDisable: String { return ElementL10n.tr("Localizable", "action_disable") }
  /// Disconnect
  public static var actionDisconnect: String { return ElementL10n.tr("Localizable", "action_disconnect") }
  /// Dismiss
  public static var actionDismiss: String { return ElementL10n.tr("Localizable", "action_dismiss") }
  /// Download
  public static var actionDownload: String { return ElementL10n.tr("Localizable", "action_download") }
  /// Enable
  public static var actionEnable: String { return ElementL10n.tr("Localizable", "action_enable") }
  /// Ignore
  public static var actionIgnore: String { return ElementL10n.tr("Localizable", "action_ignore") }
  /// Invite
  public static var actionInvite: String { return ElementL10n.tr("Localizable", "action_invite") }
  /// Join
  public static var actionJoin: String { return ElementL10n.tr("Localizable", "action_join") }
  /// Learn more
  public static var actionLearnMore: String { return ElementL10n.tr("Localizable", "action_learn_more") }
  /// Leave
  public static var actionLeave: String { return ElementL10n.tr("Localizable", "action_leave") }
  /// Mark all as read
  public static var actionMarkAllAsRead: String { return ElementL10n.tr("Localizable", "action_mark_all_as_read") }
  /// Mark as read
  public static var actionMarkRoomRead: String { return ElementL10n.tr("Localizable", "action_mark_room_read") }
  /// Next
  public static var actionNext: String { return ElementL10n.tr("Localizable", "action_next") }
  /// Not now
  public static var actionNotNow: String { return ElementL10n.tr("Localizable", "action_not_now") }
  /// Open
  public static var actionOpen: String { return ElementL10n.tr("Localizable", "action_open") }
  /// Play
  public static var actionPlay: String { return ElementL10n.tr("Localizable", "action_play") }
  /// Quick reply
  public static var actionQuickReply: String { return ElementL10n.tr("Localizable", "action_quick_reply") }
  /// Quote
  public static var actionQuote: String { return ElementL10n.tr("Localizable", "action_quote") }
  /// Reject
  public static var actionReject: String { return ElementL10n.tr("Localizable", "action_reject") }
  /// Remove
  public static var actionRemove: String { return ElementL10n.tr("Localizable", "action_remove") }
  /// Rename
  public static var actionRename: String { return ElementL10n.tr("Localizable", "action_rename") }
  /// Reset
  public static var actionReset: String { return ElementL10n.tr("Localizable", "action_reset") }
  /// Revoke
  public static var actionRevoke: String { return ElementL10n.tr("Localizable", "action_revoke") }
  /// Save
  public static var actionSave: String { return ElementL10n.tr("Localizable", "action_save") }
  /// Send
  public static var actionSend: String { return ElementL10n.tr("Localizable", "action_send") }
  /// Share
  public static var actionShare: String { return ElementL10n.tr("Localizable", "action_share") }
  /// Sign out
  public static var actionSignOut: String { return ElementL10n.tr("Localizable", "action_sign_out") }
  /// Are you sure you want to sign out?
  public static var actionSignOutConfirmationSimple: String { return ElementL10n.tr("Localizable", "action_sign_out_confirmation_simple") }
  /// Skip
  public static var actionSkip: String { return ElementL10n.tr("Localizable", "action_skip") }
  /// Switch
  public static var actionSwitch: String { return ElementL10n.tr("Localizable", "action_switch") }
  /// Copy link to thread
  public static var actionThreadCopyLinkToThread: String { return ElementL10n.tr("Localizable", "action_thread_copy_link_to_thread") }
  /// View in room
  public static var actionThreadViewInRoom: String { return ElementL10n.tr("Localizable", "action_thread_view_in_room") }
  /// Try it out
  public static var actionTryItOut: String { return ElementL10n.tr("Localizable", "action_try_it_out") }
  /// Unpublish
  public static var actionUnpublish: String { return ElementL10n.tr("Localizable", "action_unpublish") }
  /// Video Call
  public static var actionVideoCall: String { return ElementL10n.tr("Localizable", "action_video_call") }
  /// View Threads
  public static var actionViewThreads: String { return ElementL10n.tr("Localizable", "action_view_threads") }
  /// Voice Call
  public static var actionVoiceCall: String { return ElementL10n.tr("Localizable", "action_voice_call") }
  /// VIEW
  public static var activeWidgetViewAction: String { return ElementL10n.tr("Localizable", "active_widget_view_action") }
  /// Plural format key: "%#@VARIABLE@"
  public static func activeWidgets(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "active_widgets", p1)
  }
  /// Active widgets
  public static var activeWidgetsTitle: String { return ElementL10n.tr("Localizable", "active_widgets_title") }
  /// Create a space
  public static var activityCreateSpaceTitle: String { return ElementL10n.tr("Localizable", "activity_create_space_title") }
  /// Add a topic
  public static var addATopicLinkText: String { return ElementL10n.tr("Localizable", "add_a_topic_link_text") }
  /// Add by QR code
  public static var addByQrCode: String { return ElementL10n.tr("Localizable", "add_by_qr_code") }
  /// Configure identity server
  public static var addIdentityServer: String { return ElementL10n.tr("Localizable", "add_identity_server") }
  /// Add members
  public static var addMembersToRoom: String { return ElementL10n.tr("Localizable", "add_members_to_room") }
  /// Add people
  public static var addPeople: String { return ElementL10n.tr("Localizable", "add_people") }
  /// Add space
  public static var addSpace: String { return ElementL10n.tr("Localizable", "add_space") }
  /// Review your settings to enable push notifications
  public static var alertPushAreDisabledDescription: String { return ElementL10n.tr("Localizable", "alert_push_are_disabled_description") }
  /// Push notifications are disabled
  public static var alertPushAreDisabledTitle: String { return ElementL10n.tr("Localizable", "alert_push_are_disabled_title") }
  /// All Chats
  public static var allChats: String { return ElementL10n.tr("Localizable", "all_chats") }
  /// All rooms you’re in will be shown in Home.
  public static var allRoomsYoureInWillBeShownInHome: String { return ElementL10n.tr("Localizable", "all_rooms_youre_in_will_be_shown_in_home") }
  /// Allow space members to find and access.
  public static var allowSpaceMemberToFindAndAccess: String { return ElementL10n.tr("Localizable", "allow_space_member_to_find_and_access") }
  /// Help us identify issues and improve %@ by sharing anonymous usage data. To understand how people use multiple devices, we’ll generate a random identifier, shared by your devices.
  /// 
  /// You can read all our terms %@.
  public static func analyticsOptInContent(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "analytics_opt_in_content", String(describing: p1), String(describing: p2))
  }
  /// here
  public static var analyticsOptInContentLink: String { return ElementL10n.tr("Localizable", "analytics_opt_in_content_link") }
  /// We <b>don't</b> record or profile any account data
  public static var analyticsOptInListItem1: String { return ElementL10n.tr("Localizable", "analytics_opt_in_list_item_1") }
  /// We <b>don't</b> share information with third parties
  public static var analyticsOptInListItem2: String { return ElementL10n.tr("Localizable", "analytics_opt_in_list_item_2") }
  /// You can turn this off anytime in settings
  public static var analyticsOptInListItem3: String { return ElementL10n.tr("Localizable", "analytics_opt_in_list_item_3") }
  /// Help improve %@
  public static func analyticsOptInTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "analytics_opt_in_title", String(describing: p1))
  }
  /// %@ Web
  /// %@ Desktop
  public static func appDesktopWeb(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "app_desktop_web", String(describing: p1), String(describing: p2))
  }
  /// %@ iOS
  /// %@ Android
  public static func appIosAndroid(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "app_ios_android", String(describing: p1), String(describing: p2))
  }
  /// Are you sure?
  public static var areYouSure: String { return ElementL10n.tr("Localizable", "are_you_sure") }
  /// Camera
  public static var attachmentTypeCamera: String { return ElementL10n.tr("Localizable", "attachment_type_camera") }
  /// Contact
  public static var attachmentTypeContact: String { return ElementL10n.tr("Localizable", "attachment_type_contact") }
  /// Add image from
  public static var attachmentTypeDialogTitle: String { return ElementL10n.tr("Localizable", "attachment_type_dialog_title") }
  /// File
  public static var attachmentTypeFile: String { return ElementL10n.tr("Localizable", "attachment_type_file") }
  /// Gallery
  public static var attachmentTypeGallery: String { return ElementL10n.tr("Localizable", "attachment_type_gallery") }
  /// Location
  public static var attachmentTypeLocation: String { return ElementL10n.tr("Localizable", "attachment_type_location") }
  /// Poll
  public static var attachmentTypePoll: String { return ElementL10n.tr("Localizable", "attachment_type_poll") }
  /// Sticker
  public static var attachmentTypeSticker: String { return ElementL10n.tr("Localizable", "attachment_type_sticker") }
  /// %1$d of %2$d
  public static func attachmentViewerItemXOfY(_ p1: Int, _ p2: Int) -> String {
    return ElementL10n.tr("Localizable", "attachment_viewer_item_x_of_y", p1, p2)
  }
  /// Audio call with %@
  public static func audioCallWithParticipant(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "audio_call_with_participant", String(describing: p1))
  }
  /// Start audio meeting
  public static var audioMeeting: String { return ElementL10n.tr("Localizable", "audio_meeting") }
  /// (%1$@)
  public static func audioMessageFileSize(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "audio_message_file_size", String(describing: p1))
  }
  /// %1$@ (%2$@)
  public static func audioMessageReplyContent(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "audio_message_reply_content", String(describing: p1), String(describing: p2))
  }
  /// Meetings use Jitsi security and permission policies. All people currently in the room will see an invite to join while your meeting is happening.
  public static var audioVideoMeetingDescription: String { return ElementL10n.tr("Localizable", "audio_video_meeting_description") }
  /// Please review and accept the policies of this homeserver:
  public static var authAcceptPolicies: String { return ElementL10n.tr("Localizable", "auth_accept_policies") }
  /// Biometric authentication was disabled because a new biometric authentication method was recently added. You can enable it again in Settings.
  public static var authBiometricKeyInvalidatedMessage: String { return ElementL10n.tr("Localizable", "auth_biometric_key_invalidated_message") }
  /// This email address is already defined.
  public static var authEmailAlreadyDefined: String { return ElementL10n.tr("Localizable", "auth_email_already_defined") }
  /// Forgot password?
  public static var authForgotPassword: String { return ElementL10n.tr("Localizable", "auth_forgot_password") }
  /// This doesn’t look like a valid email address
  public static var authInvalidEmail: String { return ElementL10n.tr("Localizable", "auth_invalid_email") }
  /// This account has been deactivated.
  public static var authInvalidLoginDeactivatedAccount: String { return ElementL10n.tr("Localizable", "auth_invalid_login_deactivated_account") }
  /// Incorrect username and/or password
  public static var authInvalidLoginParam: String { return ElementL10n.tr("Localizable", "auth_invalid_login_param") }
  /// Incorrect username and/or password. The entered password starts or ends with spaces, please check it.
  public static var authInvalidLoginParamSpaceInPassword: String { return ElementL10n.tr("Localizable", "auth_invalid_login_param_space_in_password") }
  /// Log in
  public static var authLogin: String { return ElementL10n.tr("Localizable", "auth_login") }
  /// Sign in with single sign-on
  public static var authLoginSso: String { return ElementL10n.tr("Localizable", "auth_login_sso") }
  /// This phone number is already defined.
  public static var authMsisdnAlreadyDefined: String { return ElementL10n.tr("Localizable", "auth_msisdn_already_defined") }
  /// Forgot PIN?
  public static var authPinForgot: String { return ElementL10n.tr("Localizable", "auth_pin_forgot") }
  /// New PIN
  public static var authPinNewPinAction: String { return ElementL10n.tr("Localizable", "auth_pin_new_pin_action") }
  /// To reset your PIN, you'll need to re-login and create a new one.
  public static var authPinResetContent: String { return ElementL10n.tr("Localizable", "auth_pin_reset_content") }
  /// Reset PIN
  public static var authPinResetTitle: String { return ElementL10n.tr("Localizable", "auth_pin_reset_title") }
  /// Enter your PIN
  public static var authPinTitle: String { return ElementL10n.tr("Localizable", "auth_pin_title") }
  /// This homeserver would like to make sure you are not a robot
  public static var authRecaptchaMessage: String { return ElementL10n.tr("Localizable", "auth_recaptcha_message") }
  /// Failed to verify email address: make sure you clicked the link in the email
  public static var authResetPasswordErrorUnauthorized: String { return ElementL10n.tr("Localizable", "auth_reset_password_error_unauthorized") }
  /// Email not verified, check your inbox
  public static var authResetPasswordErrorUnverified: String { return ElementL10n.tr("Localizable", "auth_reset_password_error_unverified") }
  /// Submit
  public static var authSubmit: String { return ElementL10n.tr("Localizable", "auth_submit") }
  /// Failed to authenticate
  public static var authenticationError: String { return ElementL10n.tr("Localizable", "authentication_error") }
  /// Showing only the first results, type more letters…
  public static var autocompleteLimitedResults: String { return ElementL10n.tr("Localizable", "autocomplete_limited_results") }
  /// Unable to find a valid homeserver. Please check your identifier
  public static var autodiscoverWellKnownError: String { return ElementL10n.tr("Localizable", "autodiscover_well_known_error") }
  /// Avatar
  public static var avatar: String { return ElementL10n.tr("Localizable", "avatar") }
  /// Back up
  public static var backup: String { return ElementL10n.tr("Localizable", "backup") }
  /// Forgot or lost all recovery options? Reset everything
  public static var badPassphraseKeyResetAllAction: String { return ElementL10n.tr("Localizable", "bad_passphrase_key_reset_all_action") }
  /// BETA
  public static var beta: String { return ElementL10n.tr("Localizable", "beta") }
  /// BETA
  public static var betaTitleBottomSheetAction: String { return ElementL10n.tr("Localizable", "beta_title_bottom_sheet_action") }
  /// Black Theme
  public static var blackTheme: String { return ElementL10n.tr("Localizable", "black_theme") }
  /// IGNORE USER
  public static var blockUser: String { return ElementL10n.tr("Localizable", "block_user") }
  /// If you cancel now, you may lose encrypted messages & data if you lose access to your logins.
  /// 
  /// You can also set up Secure Backup & manage your keys in Settings.
  public static var bootstrapCancelText: String { return ElementL10n.tr("Localizable", "bootstrap_cancel_text") }
  /// Your %2$@ & %1$@ are now set.
  /// 
  /// Keep them safe! You’ll need them to unlock encrypted messages and secure information if you lose all of your active sessions.
  public static func bootstrapCrossSigningSuccess(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "bootstrap_cross_signing_success", String(describing: p1), String(describing: p2))
  }
  /// Print it and store it somewhere safe
  public static var bootstrapCrosssigningPrintIt: String { return ElementL10n.tr("Localizable", "bootstrap_crosssigning_print_it") }
  /// Defining SSSS default Key
  public static var bootstrapCrosssigningProgressDefaultKey: String { return ElementL10n.tr("Localizable", "bootstrap_crosssigning_progress_default_key") }
  /// Publishing created identity keys
  public static var bootstrapCrosssigningProgressInitializing: String { return ElementL10n.tr("Localizable", "bootstrap_crosssigning_progress_initializing") }
  /// Setting Up Key Backup
  public static var bootstrapCrosssigningProgressKeyBackup: String { return ElementL10n.tr("Localizable", "bootstrap_crosssigning_progress_key_backup") }
  /// Generating secure key from passphrase
  public static var bootstrapCrosssigningProgressPbkdf2: String { return ElementL10n.tr("Localizable", "bootstrap_crosssigning_progress_pbkdf2") }
  /// Synchronizing Master key
  public static var bootstrapCrosssigningProgressSaveMsk: String { return ElementL10n.tr("Localizable", "bootstrap_crosssigning_progress_save_msk") }
  /// Synchronizing Self Signing key
  public static var bootstrapCrosssigningProgressSaveSsk: String { return ElementL10n.tr("Localizable", "bootstrap_crosssigning_progress_save_ssk") }
  /// Synchronizing User key
  public static var bootstrapCrosssigningProgressSaveUsk: String { return ElementL10n.tr("Localizable", "bootstrap_crosssigning_progress_save_usk") }
  /// Copy it to your personal cloud storage
  public static var bootstrapCrosssigningSaveCloud: String { return ElementL10n.tr("Localizable", "bootstrap_crosssigning_save_cloud") }
  /// Save it on a USB key or backup drive
  public static var bootstrapCrosssigningSaveUsb: String { return ElementL10n.tr("Localizable", "bootstrap_crosssigning_save_usb") }
  /// Don’t use your account password.
  public static var bootstrapDontReusePwd: String { return ElementL10n.tr("Localizable", "bootstrap_dont_reuse_pwd") }
  /// Enter your %@ to continue
  public static func bootstrapEnterRecovery(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "bootstrap_enter_recovery", String(describing: p1))
  }
  /// You're done!
  public static var bootstrapFinishTitle: String { return ElementL10n.tr("Localizable", "bootstrap_finish_title") }
  /// Enter a security phrase only you know, used to secure secrets on your server.
  public static var bootstrapInfoText2: String { return ElementL10n.tr("Localizable", "bootstrap_info_text_2") }
  /// It's not a valid recovery key
  public static var bootstrapInvalidRecoveryKey: String { return ElementL10n.tr("Localizable", "bootstrap_invalid_recovery_key") }
  /// This might take several seconds, please be patient.
  public static var bootstrapLoadingText: String { return ElementL10n.tr("Localizable", "bootstrap_loading_text") }
  /// Setting up recovery.
  public static var bootstrapLoadingTitle: String { return ElementL10n.tr("Localizable", "bootstrap_loading_title") }
  /// Key Backup recovery key
  public static var bootstrapMigrationBackupRecoveryKey: String { return ElementL10n.tr("Localizable", "bootstrap_migration_backup_recovery_key") }
  /// Enter your Key Backup Passphrase to continue.
  public static var bootstrapMigrationEnterBackupPassword: String { return ElementL10n.tr("Localizable", "bootstrap_migration_enter_backup_password") }
  /// use your Key Backup recovery key
  public static var bootstrapMigrationUseRecoveryKey: String { return ElementL10n.tr("Localizable", "bootstrap_migration_use_recovery_key") }
  /// Don’t know your Key Backup Passphrase, you can %@.
  public static func bootstrapMigrationWithPassphraseHelperWithLink(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "bootstrap_migration_with_passphrase_helper_with_link", String(describing: p1))
  }
  /// Checking backup Key
  public static var bootstrapProgressCheckingBackup: String { return ElementL10n.tr("Localizable", "bootstrap_progress_checking_backup") }
  /// Checking backup Key (%@)
  public static func bootstrapProgressCheckingBackupWithInfo(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "bootstrap_progress_checking_backup_with_info", String(describing: p1))
  }
  /// Getting curve key
  public static var bootstrapProgressComputeCurveKey: String { return ElementL10n.tr("Localizable", "bootstrap_progress_compute_curve_key") }
  /// Generating SSSS key from passphrase
  public static var bootstrapProgressGeneratingSsss: String { return ElementL10n.tr("Localizable", "bootstrap_progress_generating_ssss") }
  /// Generating SSSS key from recovery key
  public static var bootstrapProgressGeneratingSsssRecovery: String { return ElementL10n.tr("Localizable", "bootstrap_progress_generating_ssss_recovery") }
  /// Generating SSSS key from passphrase (%@)
  public static func bootstrapProgressGeneratingSsssWithInfo(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "bootstrap_progress_generating_ssss_with_info", String(describing: p1))
  }
  /// Storing keybackup secret in SSSS
  public static var bootstrapProgressStoringInSss: String { return ElementL10n.tr("Localizable", "bootstrap_progress_storing_in_sss") }
  /// Favourites
  public static var bottomActionFavourites: String { return ElementL10n.tr("Localizable", "bottom_action_favourites") }
  /// Notifications
  public static var bottomActionNotification: String { return ElementL10n.tr("Localizable", "bottom_action_notification") }
  /// People
  public static var bottomActionPeople: String { return ElementL10n.tr("Localizable", "bottom_action_people") }
  /// Direct Messages
  public static var bottomActionPeopleX: String { return ElementL10n.tr("Localizable", "bottom_action_people_x") }
  /// Rooms
  public static var bottomActionRooms: String { return ElementL10n.tr("Localizable", "bottom_action_rooms") }
  /// Store your Security Key somewhere safe, like a password manager or a safe.
  public static var bottomSheetSaveYourRecoveryKeyContent: String { return ElementL10n.tr("Localizable", "bottom_sheet_save_your_recovery_key_content") }
  /// Save your Security Key
  public static var bottomSheetSaveYourRecoveryKeyTitle: String { return ElementL10n.tr("Localizable", "bottom_sheet_save_your_recovery_key_title") }
  /// Generate a security key to store somewhere safe like a password manager or a safe.
  public static var bottomSheetSetupSecureBackupSecurityKeySubtitle: String { return ElementL10n.tr("Localizable", "bottom_sheet_setup_secure_backup_security_key_subtitle") }
  /// Use a Security Key
  public static var bottomSheetSetupSecureBackupSecurityKeyTitle: String { return ElementL10n.tr("Localizable", "bottom_sheet_setup_secure_backup_security_key_title") }
  /// Enter a secret phrase only you know, and generate a key for backup.
  public static var bottomSheetSetupSecureBackupSecurityPhraseSubtitle: String { return ElementL10n.tr("Localizable", "bottom_sheet_setup_secure_backup_security_phrase_subtitle") }
  /// Use a Security Phrase
  public static var bottomSheetSetupSecureBackupSecurityPhraseTitle: String { return ElementL10n.tr("Localizable", "bottom_sheet_setup_secure_backup_security_phrase_title") }
  /// Set up
  public static var bottomSheetSetupSecureBackupSubmit: String { return ElementL10n.tr("Localizable", "bottom_sheet_setup_secure_backup_submit") }
  /// Safeguard against losing access to encrypted messages & data by backing up encryption keys on your server.
  public static var bottomSheetSetupSecureBackupSubtitle: String { return ElementL10n.tr("Localizable", "bottom_sheet_setup_secure_backup_subtitle") }
  /// Secure backup
  public static var bottomSheetSetupSecureBackupTitle: String { return ElementL10n.tr("Localizable", "bottom_sheet_setup_secure_backup_title") }
  /// The description is too short
  public static var bugReportErrorTooShort: String { return ElementL10n.tr("Localizable", "bug_report_error_too_short") }
  /// Call
  public static var call: String { return ElementL10n.tr("Localizable", "call") }
  /// Plural format key: "%#@VARIABLE@"
  public static func callActiveStatus(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "call_active_status", p1)
  }
  /// Back
  public static var callCameraBack: String { return ElementL10n.tr("Localizable", "call_camera_back") }
  /// Front
  public static var callCameraFront: String { return ElementL10n.tr("Localizable", "call_camera_front") }
  /// Call connecting…
  public static var callConnecting: String { return ElementL10n.tr("Localizable", "call_connecting") }
  /// There was an error looking up the phone number
  public static var callDialPadLookupError: String { return ElementL10n.tr("Localizable", "call_dial_pad_lookup_error") }
  /// Dial pad
  public static var callDialPadTitle: String { return ElementL10n.tr("Localizable", "call_dial_pad_title") }
  /// Call ended
  public static var callEnded: String { return ElementL10n.tr("Localizable", "call_ended") }
  /// No answer
  public static var callEndedInviteTimeoutTitle: String { return ElementL10n.tr("Localizable", "call_ended_invite_timeout_title") }
  /// The user you called is busy.
  public static var callEndedUserBusyDescription: String { return ElementL10n.tr("Localizable", "call_ended_user_busy_description") }
  /// User busy
  public static var callEndedUserBusyTitle: String { return ElementL10n.tr("Localizable", "call_ended_user_busy_title") }
  /// The remote side failed to pick up.
  public static var callErrorUserNotResponding: String { return ElementL10n.tr("Localizable", "call_error_user_not_responding") }
  /// %@ Call Failed
  public static func callFailedNoConnection(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "call_failed_no_connection", String(describing: p1))
  }
  /// Failed to establish real time connection.
  /// Please ask the administrator of your homeserver to configure a TURN server in order for calls to work reliably.
  public static var callFailedNoConnectionDescription: String { return ElementL10n.tr("Localizable", "call_failed_no_connection_description") }
  /// Turn HD off
  public static var callFormatTurnHdOff: String { return ElementL10n.tr("Localizable", "call_format_turn_hd_off") }
  /// Turn HD on
  public static var callFormatTurnHdOn: String { return ElementL10n.tr("Localizable", "call_format_turn_hd_on") }
  /// %@ held the call
  public static func callHeldByUser(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "call_held_by_user", String(describing: p1))
  }
  /// You held the call
  public static var callHeldByYou: String { return ElementL10n.tr("Localizable", "call_held_by_you") }
  /// Hold
  public static var callHoldAction: String { return ElementL10n.tr("Localizable", "call_hold_action") }
  /// Call In Progress…
  public static var callInProgress: String { return ElementL10n.tr("Localizable", "call_in_progress") }
  /// Accept
  public static var callNotificationAnswer: String { return ElementL10n.tr("Localizable", "call_notification_answer") }
  /// Hang Up
  public static var callNotificationHangup: String { return ElementL10n.tr("Localizable", "call_notification_hangup") }
  /// Decline
  public static var callNotificationReject: String { return ElementL10n.tr("Localizable", "call_notification_reject") }
  /// Active call (%1$@) ·
  public static func callOneActive(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "call_one_active", String(describing: p1))
  }
  /// Active call (%1$@)
  public static func callOnlyActive(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "call_only_active", String(describing: p1))
  }
  /// Ending call…
  public static var callRemoveJitsiWidgetProgress: String { return ElementL10n.tr("Localizable", "call_remove_jitsi_widget_progress") }
  /// Resume
  public static var callResumeAction: String { return ElementL10n.tr("Localizable", "call_resume_action") }
  /// Call ringing…
  public static var callRinging: String { return ElementL10n.tr("Localizable", "call_ringing") }
  /// Select Sound Device
  public static var callSelectSoundDevice: String { return ElementL10n.tr("Localizable", "call_select_sound_device") }
  /// Slide to end the call
  public static var callSlideToEndConference: String { return ElementL10n.tr("Localizable", "call_slide_to_end_conference") }
  /// Share screen
  public static var callStartScreenSharing: String { return ElementL10n.tr("Localizable", "call_start_screen_sharing") }
  /// Stop screen sharing
  public static var callStopScreenSharing: String { return ElementL10n.tr("Localizable", "call_stop_screen_sharing") }
  /// Switch Camera
  public static var callSwitchCamera: String { return ElementL10n.tr("Localizable", "call_switch_camera") }
  /// %1$@ Tap to return
  public static func callTapToReturn(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "call_tap_to_return", String(describing: p1))
  }
  /// Call back
  public static var callTileCallBack: String { return ElementL10n.tr("Localizable", "call_tile_call_back") }
  /// This call has ended
  public static var callTileEnded: String { return ElementL10n.tr("Localizable", "call_tile_ended") }
  /// No answer
  public static var callTileNoAnswer: String { return ElementL10n.tr("Localizable", "call_tile_no_answer") }
  /// %1$@ declined this call
  public static func callTileOtherDeclined(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "call_tile_other_declined", String(describing: p1))
  }
  /// Active video call
  public static var callTileVideoActive: String { return ElementL10n.tr("Localizable", "call_tile_video_active") }
  /// Video call ended • %1$@
  public static func callTileVideoCallHasEnded(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "call_tile_video_call_has_ended", String(describing: p1))
  }
  /// Video call declined
  public static var callTileVideoDeclined: String { return ElementL10n.tr("Localizable", "call_tile_video_declined") }
  /// Incoming video call
  public static var callTileVideoIncoming: String { return ElementL10n.tr("Localizable", "call_tile_video_incoming") }
  /// Missed video call
  public static var callTileVideoMissed: String { return ElementL10n.tr("Localizable", "call_tile_video_missed") }
  /// Active voice call
  public static var callTileVoiceActive: String { return ElementL10n.tr("Localizable", "call_tile_voice_active") }
  /// Voice call ended • %1$@
  public static func callTileVoiceCallHasEnded(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "call_tile_voice_call_has_ended", String(describing: p1))
  }
  /// Voice call declined
  public static var callTileVoiceDeclined: String { return ElementL10n.tr("Localizable", "call_tile_voice_declined") }
  /// Incoming voice call
  public static var callTileVoiceIncoming: String { return ElementL10n.tr("Localizable", "call_tile_voice_incoming") }
  /// Missed voice call
  public static var callTileVoiceMissed: String { return ElementL10n.tr("Localizable", "call_tile_voice_missed") }
  /// You declined this call
  public static var callTileYouDeclinedThisCall: String { return ElementL10n.tr("Localizable", "call_tile_you_declined_this_call") }
  /// Connect
  public static var callTransferConnectAction: String { return ElementL10n.tr("Localizable", "call_transfer_connect_action") }
  /// Consult first
  public static var callTransferConsultFirst: String { return ElementL10n.tr("Localizable", "call_transfer_consult_first") }
  /// Consulting with %1$@
  public static func callTransferConsultingWith(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "call_transfer_consulting_with", String(describing: p1))
  }
  /// An error occurred while transferring call
  public static var callTransferFailure: String { return ElementL10n.tr("Localizable", "call_transfer_failure") }
  /// Transfer
  public static var callTransferTitle: String { return ElementL10n.tr("Localizable", "call_transfer_title") }
  /// Transfer to %1$@
  public static func callTransferTransferToTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "call_transfer_transfer_to_title", String(describing: p1))
  }
  /// Unknown person
  public static var callTransferUnknownPerson: String { return ElementL10n.tr("Localizable", "call_transfer_unknown_person") }
  /// Users
  public static var callTransferUsersTabTitle: String { return ElementL10n.tr("Localizable", "call_transfer_users_tab_title") }
  /// You cannot place a call with yourself
  public static var cannotCallYourself: String { return ElementL10n.tr("Localizable", "cannot_call_yourself") }
  /// You cannot place a call with yourself, wait for participants to accept invitation
  public static var cannotCallYourselfWithInvite: String { return ElementL10n.tr("Localizable", "cannot_call_yourself_with_invite") }
  /// Cannot DM yourself!
  public static var cannotDmSelf: String { return ElementL10n.tr("Localizable", "cannot_dm_self") }
  /// Change identity server
  public static var changeIdentityServer: String { return ElementL10n.tr("Localizable", "change_identity_server") }
  /// Set a new account password…
  public static var changePasswordSummary: String { return ElementL10n.tr("Localizable", "change_password_summary") }
  /// Change network
  public static var changeRoomDirectoryNetwork: String { return ElementL10n.tr("Localizable", "change_room_directory_network") }
  /// Change Space
  public static var changeSpace: String { return ElementL10n.tr("Localizable", "change_space") }
  /// Current language
  public static var chooseLocaleCurrentLocaleTitle: String { return ElementL10n.tr("Localizable", "choose_locale_current_locale_title") }
  /// Loading available languages…
  public static var chooseLocaleLoadingLocales: String { return ElementL10n.tr("Localizable", "choose_locale_loading_locales") }
  /// Other available languages
  public static var chooseLocaleOtherLocalesTitle: String { return ElementL10n.tr("Localizable", "choose_locale_other_locales_title") }
  /// Results are only revealed when you end the poll
  public static var closedPollOptionDescription: String { return ElementL10n.tr("Localizable", "closed_poll_option_description") }
  /// Closed poll
  public static var closedPollOptionTitle: String { return ElementL10n.tr("Localizable", "closed_poll_option_title") }
  /// Sends the given message with confetti
  public static var commandConfetti: String { return ElementL10n.tr("Localizable", "command_confetti") }
  /// Add to the given Space
  public static var commandDescriptionAddToSpace: String { return ElementL10n.tr("Localizable", "command_description_add_to_space") }
  /// Changes your avatar in this current room only
  public static var commandDescriptionAvatarForRoom: String { return ElementL10n.tr("Localizable", "command_description_avatar_for_room") }
  /// Bans user with given id
  public static var commandDescriptionBanUser: String { return ElementL10n.tr("Localizable", "command_description_ban_user") }
  /// To fix Matrix Apps management
  public static var commandDescriptionClearScalarToken: String { return ElementL10n.tr("Localizable", "command_description_clear_scalar_token") }
  /// Create a Space
  public static var commandDescriptionCreateSpace: String { return ElementL10n.tr("Localizable", "command_description_create_space") }
  /// Deops user with given id
  public static var commandDescriptionDeopUser: String { return ElementL10n.tr("Localizable", "command_description_deop_user") }
  /// Forces the current outbound group session in an encrypted room to be discarded
  public static var commandDescriptionDiscardSession: String { return ElementL10n.tr("Localizable", "command_description_discard_session") }
  /// Only supported in encrypted rooms
  public static var commandDescriptionDiscardSessionNotHandled: String { return ElementL10n.tr("Localizable", "command_description_discard_session_not_handled") }
  /// Displays action
  public static var commandDescriptionEmote: String { return ElementL10n.tr("Localizable", "command_description_emote") }
  /// Ignores a user, hiding their messages from you
  public static var commandDescriptionIgnoreUser: String { return ElementL10n.tr("Localizable", "command_description_ignore_user") }
  /// Invites user with given id to current room
  public static var commandDescriptionInviteUser: String { return ElementL10n.tr("Localizable", "command_description_invite_user") }
  /// Joins room with given address
  public static var commandDescriptionJoinRoom: String { return ElementL10n.tr("Localizable", "command_description_join_room") }
  /// Join the Space with the given id
  public static var commandDescriptionJoinSpace: String { return ElementL10n.tr("Localizable", "command_description_join_space") }
  /// Leave room with given id (or current room if null)
  public static var commandDescriptionLeaveRoom: String { return ElementL10n.tr("Localizable", "command_description_leave_room") }
  /// Prepends ( ͡° ͜ʖ ͡°) to a plain-text message
  public static var commandDescriptionLenny: String { return ElementL10n.tr("Localizable", "command_description_lenny") }
  /// On/Off markdown
  public static var commandDescriptionMarkdown: String { return ElementL10n.tr("Localizable", "command_description_markdown") }
  /// Changes your display nickname
  public static var commandDescriptionNick: String { return ElementL10n.tr("Localizable", "command_description_nick") }
  /// Changes your display nickname in the current room only
  public static var commandDescriptionNickForRoom: String { return ElementL10n.tr("Localizable", "command_description_nick_for_room") }
  /// Define the power level of a user
  public static var commandDescriptionOpUser: String { return ElementL10n.tr("Localizable", "command_description_op_user") }
  /// Leave room
  public static var commandDescriptionPartRoom: String { return ElementL10n.tr("Localizable", "command_description_part_room") }
  /// Sends a message as plain text, without interpreting it as markdown
  public static var commandDescriptionPlain: String { return ElementL10n.tr("Localizable", "command_description_plain") }
  /// Sends the given message colored as a rainbow
  public static var commandDescriptionRainbow: String { return ElementL10n.tr("Localizable", "command_description_rainbow") }
  /// Sends the given emote colored as a rainbow
  public static var commandDescriptionRainbowEmote: String { return ElementL10n.tr("Localizable", "command_description_rainbow_emote") }
  /// Removes user with given id from this room
  public static var commandDescriptionRemoveUser: String { return ElementL10n.tr("Localizable", "command_description_remove_user") }
  /// Changes the avatar of the current room
  public static var commandDescriptionRoomAvatar: String { return ElementL10n.tr("Localizable", "command_description_room_avatar") }
  /// Sets the room name
  public static var commandDescriptionRoomName: String { return ElementL10n.tr("Localizable", "command_description_room_name") }
  /// Prepends ¯\_(ツ)_/¯ to a plain-text message
  public static var commandDescriptionShrug: String { return ElementL10n.tr("Localizable", "command_description_shrug") }
  /// Sends the given message as a spoiler
  public static var commandDescriptionSpoiler: String { return ElementL10n.tr("Localizable", "command_description_spoiler") }
  /// Set the room topic
  public static var commandDescriptionTopic: String { return ElementL10n.tr("Localizable", "command_description_topic") }
  /// Unbans user with given id
  public static var commandDescriptionUnbanUser: String { return ElementL10n.tr("Localizable", "command_description_unban_user") }
  /// Stops ignoring a user, showing their messages going forward
  public static var commandDescriptionUnignoreUser: String { return ElementL10n.tr("Localizable", "command_description_unignore_user") }
  /// Upgrades a room to a new version
  public static var commandDescriptionUpgradeRoom: String { return ElementL10n.tr("Localizable", "command_description_upgrade_room") }
  /// Displays information about a user
  public static var commandDescriptionWhois: String { return ElementL10n.tr("Localizable", "command_description_whois") }
  /// Command error
  public static var commandError: String { return ElementL10n.tr("Localizable", "command_error") }
  /// The command "%@" is recognized but not supported in threads.
  public static func commandNotSupportedInThreads(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "command_not_supported_in_threads", String(describing: p1))
  }
  /// The command "%@" needs more parameters, or some parameters are incorrect.
  public static func commandProblemWithParameters(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "command_problem_with_parameters", String(describing: p1))
  }
  /// Sends the given message with snowfall
  public static var commandSnow: String { return ElementL10n.tr("Localizable", "command_snow") }
  /// Choose
  public static var compressionOptListChoose: String { return ElementL10n.tr("Localizable", "compression_opt_list_choose") }
  /// Large
  public static var compressionOptListLarge: String { return ElementL10n.tr("Localizable", "compression_opt_list_large") }
  /// Medium
  public static var compressionOptListMedium: String { return ElementL10n.tr("Localizable", "compression_opt_list_medium") }
  /// Original
  public static var compressionOptListOriginal: String { return ElementL10n.tr("Localizable", "compression_opt_list_original") }
  /// Small
  public static var compressionOptListSmall: String { return ElementL10n.tr("Localizable", "compression_opt_list_small") }
  /// Confirm your identity by verifying this login from one of your other sessions, granting it access to encrypted messages.
  public static var confirmYourIdentity: String { return ElementL10n.tr("Localizable", "confirm_your_identity") }
  /// Confirm your identity by verifying this login, granting it access to encrypted messages.
  public static var confirmYourIdentityQuadS: String { return ElementL10n.tr("Localizable", "confirm_your_identity_quad_s") }
  /// Please contact an admin to restore encryption to a valid state.
  public static var contactAdminToRestoreEncryption: String { return ElementL10n.tr("Localizable", "contact_admin_to_restore_encryption") }
  /// Contacts book
  public static var contactsBookTitle: String { return ElementL10n.tr("Localizable", "contacts_book_title") }
  /// This content was reported as inappropriate.
  /// 
  /// If you don't want to see any more content from this user, you can ignore them to hide their messages.
  public static var contentReportedAsInappropriateContent: String { return ElementL10n.tr("Localizable", "content_reported_as_inappropriate_content") }
  /// Reported as inappropriate
  public static var contentReportedAsInappropriateTitle: String { return ElementL10n.tr("Localizable", "content_reported_as_inappropriate_title") }
  /// This content was reported as spam.
  /// 
  /// If you don't want to see any more content from this user, you can ignore them to hide their messages.
  public static var contentReportedAsSpamContent: String { return ElementL10n.tr("Localizable", "content_reported_as_spam_content") }
  /// Reported as spam
  public static var contentReportedAsSpamTitle: String { return ElementL10n.tr("Localizable", "content_reported_as_spam_title") }
  /// This content was reported.
  /// 
  /// If you don't want to see any more content from this user, you can ignore them to hide their messages.
  public static var contentReportedContent: String { return ElementL10n.tr("Localizable", "content_reported_content") }
  /// Content reported
  public static var contentReportedTitle: String { return ElementL10n.tr("Localizable", "content_reported_title") }
  /// Copied to clipboard
  public static var copiedToClipboard: String { return ElementL10n.tr("Localizable", "copied_to_clipboard") }
  /// Create
  public static var create: String { return ElementL10n.tr("Localizable", "create") }
  /// Create New Room
  public static var createNewRoom: String { return ElementL10n.tr("Localizable", "create_new_room") }
  /// Create New Space
  public static var createNewSpace: String { return ElementL10n.tr("Localizable", "create_new_space") }
  /// Failed to validate PIN, please tap a new one.
  public static var createPinConfirmFailure: String { return ElementL10n.tr("Localizable", "create_pin_confirm_failure") }
  /// Confirm PIN
  public static var createPinConfirmTitle: String { return ElementL10n.tr("Localizable", "create_pin_confirm_title") }
  /// Choose a PIN for security
  public static var createPinTitle: String { return ElementL10n.tr("Localizable", "create_pin_title") }
  /// ADD OPTION
  public static var createPollAddOption: String { return ElementL10n.tr("Localizable", "create_poll_add_option") }
  /// CREATE POLL
  public static var createPollButton: String { return ElementL10n.tr("Localizable", "create_poll_button") }
  /// Question cannot be empty
  public static var createPollEmptyQuestionError: String { return ElementL10n.tr("Localizable", "create_poll_empty_question_error") }
  /// Plural format key: "%#@VARIABLE@"
  public static func createPollNotEnoughOptionsError(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "create_poll_not_enough_options_error", p1)
  }
  /// Option %1$d
  public static func createPollOptionsHint(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "create_poll_options_hint", p1)
  }
  /// Create options
  public static var createPollOptionsTitle: String { return ElementL10n.tr("Localizable", "create_poll_options_title") }
  /// Question or topic
  public static var createPollQuestionHint: String { return ElementL10n.tr("Localizable", "create_poll_question_hint") }
  /// Poll question or topic
  public static var createPollQuestionTitle: String { return ElementL10n.tr("Localizable", "create_poll_question_title") }
  /// Create Poll
  public static var createPollTitle: String { return ElementL10n.tr("Localizable", "create_poll_title") }
  /// Create Room
  public static var createRoom: String { return ElementL10n.tr("Localizable", "create_room") }
  /// CREATE
  public static var createRoomActionCreate: String { return ElementL10n.tr("Localizable", "create_room_action_create") }
  /// Go
  public static var createRoomActionGo: String { return ElementL10n.tr("Localizable", "create_room_action_go") }
  /// This address is already in use
  public static var createRoomAliasAlreadyInUse: String { return ElementL10n.tr("Localizable", "create_room_alias_already_in_use") }
  /// Please provide a room address
  public static var createRoomAliasEmpty: String { return ElementL10n.tr("Localizable", "create_room_alias_empty") }
  /// Some characters are not allowed
  public static var createRoomAliasInvalid: String { return ElementL10n.tr("Localizable", "create_room_alias_invalid") }
  /// You might enable this if the room will only be used for collaborating with internal teams on your homeserver. This cannot be changed later.
  public static var createRoomDisableFederationDescription: String { return ElementL10n.tr("Localizable", "create_room_disable_federation_description") }
  /// Block anyone not part of %@ from ever joining this room
  public static func createRoomDisableFederationTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "create_room_disable_federation_title", String(describing: p1))
  }
  /// We couldn't create your DM. Please check the users you want to invite and try again.
  public static var createRoomDmFailure: String { return ElementL10n.tr("Localizable", "create_room_dm_failure") }
  /// Once enabled, encryption cannot be disabled.
  public static var createRoomEncryptionDescription: String { return ElementL10n.tr("Localizable", "create_room_encryption_description") }
  /// Enable encryption
  public static var createRoomEncryptionTitle: String { return ElementL10n.tr("Localizable", "create_room_encryption_title") }
  /// The room has been created, but some invitations have not been sent for the following reason:
  /// 
  /// %@
  public static func createRoomFederationError(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "create_room_federation_error", String(describing: p1))
  }
  /// Creating room…
  public static var createRoomInProgress: String { return ElementL10n.tr("Localizable", "create_room_in_progress") }
  /// Name
  public static var createRoomNameHint: String { return ElementL10n.tr("Localizable", "create_room_name_hint") }
  /// Room name
  public static var createRoomNameSection: String { return ElementL10n.tr("Localizable", "create_room_name_section") }
  /// Anyone will be able to join this room
  public static var createRoomPublicDescription: String { return ElementL10n.tr("Localizable", "create_room_public_description") }
  /// Public
  public static var createRoomPublicTitle: String { return ElementL10n.tr("Localizable", "create_room_public_title") }
  /// Room settings
  public static var createRoomSettingsSection: String { return ElementL10n.tr("Localizable", "create_room_settings_section") }
  /// Topic
  public static var createRoomTopicHint: String { return ElementL10n.tr("Localizable", "create_room_topic_hint") }
  /// Room topic (optional)
  public static var createRoomTopicSection: String { return ElementL10n.tr("Localizable", "create_room_topic_section") }
  /// Create space
  public static var createSpace: String { return ElementL10n.tr("Localizable", "create_space") }
  /// Space address
  public static var createSpaceAliasHint: String { return ElementL10n.tr("Localizable", "create_space_alias_hint") }
  /// Give it a name to continue.
  public static var createSpaceErrorEmptyFieldSpaceName: String { return ElementL10n.tr("Localizable", "create_space_error_empty_field_space_name") }
  /// You are not currently using an identity server. In order to invite teammates and be discoverable by them, configure one below.
  public static var createSpaceIdentityServerInfoNone: String { return ElementL10n.tr("Localizable", "create_space_identity_server_info_none") }
  /// Creating space…
  public static var createSpaceInProgress: String { return ElementL10n.tr("Localizable", "create_space_in_progress") }
  /// Description
  public static var createSpaceTopicHint: String { return ElementL10n.tr("Localizable", "create_space_topic_hint") }
  /// What type of space do you want to create?
  public static var createSpacesChooseTypeLabel: String { return ElementL10n.tr("Localizable", "create_spaces_choose_type_label") }
  /// Random
  public static var createSpacesDefaultPublicRandomRoomName: String { return ElementL10n.tr("Localizable", "create_spaces_default_public_random_room_name") }
  /// General
  public static var createSpacesDefaultPublicRoomName: String { return ElementL10n.tr("Localizable", "create_spaces_default_public_room_name") }
  /// Add some details to help people identify it. You can change these at any point.
  public static var createSpacesDetailsPrivateHeader: String { return ElementL10n.tr("Localizable", "create_spaces_details_private_header") }
  /// Add some details to help it stand out. You can change these at any point.
  public static var createSpacesDetailsPublicHeader: String { return ElementL10n.tr("Localizable", "create_spaces_details_public_header") }
  /// Who are your teammates?
  public static var createSpacesInvitePublicHeader: String { return ElementL10n.tr("Localizable", "create_spaces_invite_public_header") }
  /// Ensure the right people have access to %@ company. You can invite more later.
  public static func createSpacesInvitePublicHeaderDesc(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "create_spaces_invite_public_header_desc", String(describing: p1))
  }
  /// To join an existing space, you need an invite.
  public static var createSpacesJoinInfoHelp: String { return ElementL10n.tr("Localizable", "create_spaces_join_info_help") }
  /// Just me
  public static var createSpacesJustMe: String { return ElementL10n.tr("Localizable", "create_spaces_just_me") }
  /// Creating Space…
  public static var createSpacesLoadingMessage: String { return ElementL10n.tr("Localizable", "create_spaces_loading_message") }
  /// Make sure the right people have access to %@.
  public static func createSpacesMakeSureAccess(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "create_spaces_make_sure_access", String(describing: p1))
  }
  /// Me and teammates
  public static var createSpacesMeAndTeammates: String { return ElementL10n.tr("Localizable", "create_spaces_me_and_teammates") }
  /// A private space to organise your rooms
  public static var createSpacesOrganiseRooms: String { return ElementL10n.tr("Localizable", "create_spaces_organise_rooms") }
  /// A private space for you & your teammates
  public static var createSpacesPrivateTeammates: String { return ElementL10n.tr("Localizable", "create_spaces_private_teammates") }
  /// What things are you working on?
  public static var createSpacesRoomPrivateHeader: String { return ElementL10n.tr("Localizable", "create_spaces_room_private_header") }
  /// Let’s create a room for each of them. You can add more later too, including already existing ones.
  public static var createSpacesRoomPrivateHeaderDesc: String { return ElementL10n.tr("Localizable", "create_spaces_room_private_header_desc") }
  /// What are some discussions you want to have in %@?
  public static func createSpacesRoomPublicHeader(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "create_spaces_room_public_header", String(describing: p1))
  }
  /// We’ll create rooms for them. You can add more later too.
  public static var createSpacesRoomPublicHeaderDesc: String { return ElementL10n.tr("Localizable", "create_spaces_room_public_header_desc") }
  /// Who are you working with?
  public static var createSpacesWhoAreYouWorkingWith: String { return ElementL10n.tr("Localizable", "create_spaces_who_are_you_working_with") }
  /// You can change this later
  public static var createSpacesYouCanChangeLater: String { return ElementL10n.tr("Localizable", "create_spaces_you_can_change_later") }
  /// Creating room…
  public static var creatingDirectRoom: String { return ElementL10n.tr("Localizable", "creating_direct_room") }
  /// Interactively Verify by Emoji
  public static var crossSigningVerifyByEmoji: String { return ElementL10n.tr("Localizable", "cross_signing_verify_by_emoji") }
  /// Manually Verify by Text
  public static var crossSigningVerifyByText: String { return ElementL10n.tr("Localizable", "cross_signing_verify_by_text") }
  /// Unable to verify this device
  public static var crosssigningCannotVerifyThisSession: String { return ElementL10n.tr("Localizable", "crosssigning_cannot_verify_this_session") }
  /// You won’t be able to access encrypted message history. Reset your Secure Message Backup and verification keys to start fresh.
  public static var crosssigningCannotVerifyThisSessionDesc: String { return ElementL10n.tr("Localizable", "crosssigning_cannot_verify_this_session_desc") }
  /// Verify login
  public static var crosssigningVerifySession: String { return ElementL10n.tr("Localizable", "crosssigning_verify_session") }
  /// Verify this device
  public static var crosssigningVerifyThisSession: String { return ElementL10n.tr("Localizable", "crosssigning_verify_this_session") }
  /// You cannot access this message because you have been blocked by the sender
  public static var cryptoErrorWithheldBlacklisted: String { return ElementL10n.tr("Localizable", "crypto_error_withheld_blacklisted") }
  /// You cannot access this message because the sender purposely did not send the keys
  public static var cryptoErrorWithheldGeneric: String { return ElementL10n.tr("Localizable", "crypto_error_withheld_generic") }
  /// You cannot access this message because your session is not trusted by the sender
  public static var cryptoErrorWithheldUnverified: String { return ElementL10n.tr("Localizable", "crypto_error_withheld_unverified") }
  /// Dark Theme
  public static var darkTheme: String { return ElementL10n.tr("Localizable", "dark_theme") }
  /// This will make your account permanently unusable. You will not be able to log in, and no one will be able to re-register the same user ID. This will cause your account to leave all rooms it is participating in, and it will remove your account details from your identity server. <b>This action is irreversible</b>.
  /// 
  /// Deactivating your account <b>does not by default cause us to forget messages you have sent</b>. If you would like us to forget your messages, please tick the box below.
  /// 
  /// Message visibility in Matrix is similar to email. Our forgetting your messages means that messages you have sent will not be shared with any new or unregistered users, but registered users who already have access to these messages will still have access to their copy.
  public static var deactivateAccountContent: String { return ElementL10n.tr("Localizable", "deactivate_account_content") }
  /// Please forget all messages I have sent when my account is deactivated (Warning: this will cause future users to see an incomplete view of conversations)
  public static var deactivateAccountDeleteCheckbox: String { return ElementL10n.tr("Localizable", "deactivate_account_delete_checkbox") }
  /// Deactivate Account
  public static var deactivateAccountSubmit: String { return ElementL10n.tr("Localizable", "deactivate_account_submit") }
  /// Deactivate Account
  public static var deactivateAccountTitle: String { return ElementL10n.tr("Localizable", "deactivate_account_title") }
  /// Decide which spaces can access this room. If a space is selected its members will be able to find and join Room name.
  public static var decideWhichSpacesCanAccess: String { return ElementL10n.tr("Localizable", "decide_which_spaces_can_access") }
  /// Decide who can find and join this room.
  public static var decideWhoCanFindAndJoin: String { return ElementL10n.tr("Localizable", "decide_who_can_find_and_join") }
  /// sends confetti 🎉
  public static var defaultMessageEmoteConfetti: String { return ElementL10n.tr("Localizable", "default_message_emote_confetti") }
  /// sends snowfall ❄️
  public static var defaultMessageEmoteSnow: String { return ElementL10n.tr("Localizable", "default_message_emote_snow") }
  /// Delete the account data of type %1$@?
  /// 
  /// Use with caution, it may lead to unexpected behavior.
  public static func deleteAccountDataWarning(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "delete_account_data_warning", String(describing: p1))
  }
  /// Are you sure you wish to remove (delete) this event? Note that if you delete a room name or topic change, it could undo the change.
  public static var deleteEventDialogContent: String { return ElementL10n.tr("Localizable", "delete_event_dialog_content") }
  /// Include a reason
  public static var deleteEventDialogReasonCheckbox: String { return ElementL10n.tr("Localizable", "delete_event_dialog_reason_checkbox") }
  /// Reason for redacting
  public static var deleteEventDialogReasonHint: String { return ElementL10n.tr("Localizable", "delete_event_dialog_reason_hint") }
  /// Confirm Removal
  public static var deleteEventDialogTitle: String { return ElementL10n.tr("Localizable", "delete_event_dialog_title") }
  /// Are you sure you want to remove this poll? You won't be able to recover it once removed.
  public static var deletePollDialogContent: String { return ElementL10n.tr("Localizable", "delete_poll_dialog_content") }
  /// Remove poll
  public static var deletePollDialogTitle: String { return ElementL10n.tr("Localizable", "delete_poll_dialog_title") }
  /// To perform this action, please grant the Camera permission from the system settings.
  public static var deniedPermissionCamera: String { return ElementL10n.tr("Localizable", "denied_permission_camera") }
  /// Some permissions are missing to perform this action, please grant the permissions from the system settings.
  public static var deniedPermissionGeneric: String { return ElementL10n.tr("Localizable", "denied_permission_generic") }
  /// To send voice messages, please grant the Microphone permission.
  public static var deniedPermissionVoiceMessage: String { return ElementL10n.tr("Localizable", "denied_permission_voice_message") }
  /// Edit Content
  public static var devToolsEditContent: String { return ElementL10n.tr("Localizable", "dev_tools_edit_content") }
  /// Malformed event
  public static var devToolsErrorMalformedEvent: String { return ElementL10n.tr("Localizable", "dev_tools_error_malformed_event") }
  /// No content
  public static var devToolsErrorNoContent: String { return ElementL10n.tr("Localizable", "dev_tools_error_no_content") }
  /// Missing message type
  public static var devToolsErrorNoMessageType: String { return ElementL10n.tr("Localizable", "dev_tools_error_no_message_type") }
  /// Event content
  public static var devToolsEventContentHint: String { return ElementL10n.tr("Localizable", "dev_tools_event_content_hint") }
  /// Explore Room State
  public static var devToolsExploreRoomState: String { return ElementL10n.tr("Localizable", "dev_tools_explore_room_state") }
  /// Event Content
  public static var devToolsFormHintEventContent: String { return ElementL10n.tr("Localizable", "dev_tools_form_hint_event_content") }
  /// State Key
  public static var devToolsFormHintStateKey: String { return ElementL10n.tr("Localizable", "dev_tools_form_hint_state_key") }
  /// Type
  public static var devToolsFormHintType: String { return ElementL10n.tr("Localizable", "dev_tools_form_hint_type") }
  /// Dev Tools
  public static var devToolsMenuName: String { return ElementL10n.tr("Localizable", "dev_tools_menu_name") }
  /// Send Custom Event
  public static var devToolsSendCustomEvent: String { return ElementL10n.tr("Localizable", "dev_tools_send_custom_event") }
  /// Send Custom State Event
  public static var devToolsSendCustomStateEvent: String { return ElementL10n.tr("Localizable", "dev_tools_send_custom_state_event") }
  /// Send State Event
  public static var devToolsSendStateEvent: String { return ElementL10n.tr("Localizable", "dev_tools_send_state_event") }
  /// State Events
  public static var devToolsStateEvent: String { return ElementL10n.tr("Localizable", "dev_tools_state_event") }
  /// Event sent!
  public static var devToolsSuccessEvent: String { return ElementL10n.tr("Localizable", "dev_tools_success_event") }
  /// State event sent!
  public static var devToolsSuccessStateEvent: String { return ElementL10n.tr("Localizable", "dev_tools_success_state_event") }
  /// Current Session
  public static var deviceManagerCurrentSessionTitle: String { return ElementL10n.tr("Localizable", "device_manager_current_session_title") }
  /// Device
  public static var deviceManagerDeviceTitle: String { return ElementL10n.tr("Localizable", "device_manager_device_title") }
  /// Current Session
  public static var deviceManagerHeaderSectionCurrentSession: String { return ElementL10n.tr("Localizable", "device_manager_header_section_current_session") }
  /// Improve your account security by following these recommendations.
  public static var deviceManagerHeaderSectionSecurityRecommendationsDescription: String { return ElementL10n.tr("Localizable", "device_manager_header_section_security_recommendations_description") }
  /// Security recommendations
  public static var deviceManagerHeaderSectionSecurityRecommendationsTitle: String { return ElementL10n.tr("Localizable", "device_manager_header_section_security_recommendations_title") }
  /// Plural format key: "%#@VARIABLE@"
  public static func deviceManagerInactiveSessionsDescription(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "device_manager_inactive_sessions_description", p1)
  }
  /// Inactive sessions
  public static var deviceManagerInactiveSessionsTitle: String { return ElementL10n.tr("Localizable", "device_manager_inactive_sessions_title") }
  /// Plural format key: "%#@VARIABLE@"
  public static func deviceManagerOtherSessionsDescriptionInactive(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "device_manager_other_sessions_description_inactive", p1)
  }
  /// Unverified · Last activity %1$@
  public static func deviceManagerOtherSessionsDescriptionUnverified(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "device_manager_other_sessions_description_unverified", String(describing: p1))
  }
  /// Verified · Last activity %1$@
  public static func deviceManagerOtherSessionsDescriptionVerified(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "device_manager_other_sessions_description_verified", String(describing: p1))
  }
  /// View All (%1$d)
  public static func deviceManagerOtherSessionsViewAll(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "device_manager_other_sessions_view_all", p1)
  }
  /// Application, device, and activity information.
  public static var deviceManagerSessionDetailsDescription: String { return ElementL10n.tr("Localizable", "device_manager_session_details_description") }
  /// IP address
  public static var deviceManagerSessionDetailsDeviceIpAddress: String { return ElementL10n.tr("Localizable", "device_manager_session_details_device_ip_address") }
  /// Session ID
  public static var deviceManagerSessionDetailsSessionId: String { return ElementL10n.tr("Localizable", "device_manager_session_details_session_id") }
  /// Last activity
  public static var deviceManagerSessionDetailsSessionLastActivity: String { return ElementL10n.tr("Localizable", "device_manager_session_details_session_last_activity") }
  /// Session name
  public static var deviceManagerSessionDetailsSessionName: String { return ElementL10n.tr("Localizable", "device_manager_session_details_session_name") }
  /// Session details
  public static var deviceManagerSessionDetailsTitle: String { return ElementL10n.tr("Localizable", "device_manager_session_details_title") }
  /// Last activity %1$@
  public static func deviceManagerSessionLastActivity(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "device_manager_session_last_activity", String(describing: p1))
  }
  /// Session
  public static var deviceManagerSessionTitle: String { return ElementL10n.tr("Localizable", "device_manager_session_title") }
  /// Show All Sessions (V2, WIP)
  public static var deviceManagerSettingsActiveSessionsShowAll: String { return ElementL10n.tr("Localizable", "device_manager_settings_active_sessions_show_all") }
  /// Verify or sign out from unverified sessions.
  public static var deviceManagerUnverifiedSessionsDescription: String { return ElementL10n.tr("Localizable", "device_manager_unverified_sessions_description") }
  /// Unverified sessions
  public static var deviceManagerUnverifiedSessionsTitle: String { return ElementL10n.tr("Localizable", "device_manager_unverified_sessions_title") }
  /// Verify your current session for enhanced secure messaging.
  public static var deviceManagerVerificationStatusDetailCurrentSessionUnverified: String { return ElementL10n.tr("Localizable", "device_manager_verification_status_detail_current_session_unverified") }
  /// Your current session is ready for secure messaging.
  public static var deviceManagerVerificationStatusDetailCurrentSessionVerified: String { return ElementL10n.tr("Localizable", "device_manager_verification_status_detail_current_session_verified") }
  /// Verify or sign out from this session for best security and reliability.
  public static var deviceManagerVerificationStatusDetailOtherSessionUnverified: String { return ElementL10n.tr("Localizable", "device_manager_verification_status_detail_other_session_unverified") }
  /// This session is ready for secure messaging.
  public static var deviceManagerVerificationStatusDetailOtherSessionVerified: String { return ElementL10n.tr("Localizable", "device_manager_verification_status_detail_other_session_verified") }
  /// Verify your current session for enhanced secure messaging.
  public static var deviceManagerVerificationStatusDetailUnverified: String { return ElementL10n.tr("Localizable", "device_manager_verification_status_detail_unverified") }
  /// Your current session is ready for secure messaging.
  public static var deviceManagerVerificationStatusDetailVerified: String { return ElementL10n.tr("Localizable", "device_manager_verification_status_detail_verified") }
  /// Unverified session
  public static var deviceManagerVerificationStatusUnverified: String { return ElementL10n.tr("Localizable", "device_manager_verification_status_unverified") }
  /// Verified session
  public static var deviceManagerVerificationStatusVerified: String { return ElementL10n.tr("Localizable", "device_manager_verification_status_verified") }
  /// Verify Session
  public static var deviceManagerVerifySession: String { return ElementL10n.tr("Localizable", "device_manager_verify_session") }
  /// View Details
  public static var deviceManagerViewDetails: String { return ElementL10n.tr("Localizable", "device_manager_view_details") }
  /// Current session
  public static var devicesCurrentDevice: String { return ElementL10n.tr("Localizable", "devices_current_device") }
  /// Authentication
  public static var devicesDeleteDialogTitle: String { return ElementL10n.tr("Localizable", "devices_delete_dialog_title") }
  /// Update Public Name
  public static var devicesDetailsDeviceName: String { return ElementL10n.tr("Localizable", "devices_details_device_name") }
  /// ID
  public static var devicesDetailsIdTitle: String { return ElementL10n.tr("Localizable", "devices_details_id_title") }
  /// %1$@ @ %2$@
  public static func devicesDetailsLastSeenFormat(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "devices_details_last_seen_format", String(describing: p1), String(describing: p2))
  }
  /// Last seen
  public static var devicesDetailsLastSeenTitle: String { return ElementL10n.tr("Localizable", "devices_details_last_seen_title") }
  /// Public Name
  public static var devicesDetailsNameTitle: String { return ElementL10n.tr("Localizable", "devices_details_name_title") }
  /// Other sessions
  public static var devicesOtherDevices: String { return ElementL10n.tr("Localizable", "devices_other_devices") }
  /// New value
  public static var dialogEditHint: String { return ElementL10n.tr("Localizable", "dialog_edit_hint") }
  /// Confirmation
  public static var dialogTitleConfirmation: String { return ElementL10n.tr("Localizable", "dialog_title_confirmation") }
  /// Error
  public static var dialogTitleError: String { return ElementL10n.tr("Localizable", "dialog_title_error") }
  /// Success
  public static var dialogTitleSuccess: String { return ElementL10n.tr("Localizable", "dialog_title_success") }
  /// Warning
  public static var dialogTitleWarning: String { return ElementL10n.tr("Localizable", "dialog_title_warning") }
  /// To continue using the %1$@ homeserver you must review and agree to the terms and conditions.
  public static func dialogUserConsentContent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "dialog_user_consent_content", String(describing: p1))
  }
  /// Review now
  public static var dialogUserConsentSubmit: String { return ElementL10n.tr("Localizable", "dialog_user_consent_submit") }
  /// Conversations
  public static var directChatsHeader: String { return ElementL10n.tr("Localizable", "direct_chats_header") }
  /// %@ joined.
  public static func directRoomCreatedSummaryItem(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "direct_room_created_summary_item", String(describing: p1))
  }
  /// You joined.
  public static var directRoomCreatedSummaryItemByYou: String { return ElementL10n.tr("Localizable", "direct_room_created_summary_item_by_you") }
  /// Messages in this chat are end-to-end encrypted.
  public static var directRoomEncryptionEnabledTileDescription: String { return ElementL10n.tr("Localizable", "direct_room_encryption_enabled_tile_description") }
  /// Messages in this chat will be end-to-end encrypted.
  public static var directRoomEncryptionEnabledTileDescriptionFuture: String { return ElementL10n.tr("Localizable", "direct_room_encryption_enabled_tile_description_future") }
  /// %1$@ made this invite only.
  public static func directRoomJoinRulesInvite(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "direct_room_join_rules_invite", String(describing: p1))
  }
  /// You made this invite only.
  public static var directRoomJoinRulesInviteByYou: String { return ElementL10n.tr("Localizable", "direct_room_join_rules_invite_by_you") }
  /// Messages here are end-to-end encrypted.
  /// 
  /// Your messages are secured with locks and only you and the recipient have the unique keys to unlock them.
  public static var directRoomProfileEncryptedSubtitle: String { return ElementL10n.tr("Localizable", "direct_room_profile_encrypted_subtitle") }
  /// Messages here are not end-to-end encrypted.
  public static var directRoomProfileNotEncryptedSubtitle: String { return ElementL10n.tr("Localizable", "direct_room_profile_not_encrypted_subtitle") }
  /// Leave
  public static var directRoomProfileSectionMoreLeave: String { return ElementL10n.tr("Localizable", "direct_room_profile_section_more_leave") }
  /// Settings
  public static var directRoomProfileSectionMoreSettings: String { return ElementL10n.tr("Localizable", "direct_room_profile_section_more_settings") }
  /// Known Users
  public static var directRoomUserListKnownTitle: String { return ElementL10n.tr("Localizable", "direct_room_user_list_known_title") }
  /// Suggestions
  public static var directRoomUserListSuggestionsTitle: String { return ElementL10n.tr("Localizable", "direct_room_user_list_suggestions_title") }
  /// Add a new server
  public static var directoryAddANewServer: String { return ElementL10n.tr("Localizable", "directory_add_a_new_server") }
  /// Can't find this server or its room list
  public static var directoryAddANewServerError: String { return ElementL10n.tr("Localizable", "directory_add_a_new_server_error") }
  /// This server is already present in the list
  public static var directoryAddANewServerErrorAlreadyAdded: String { return ElementL10n.tr("Localizable", "directory_add_a_new_server_error_already_added") }
  /// Enter the name of a new server you want to explore.
  public static var directoryAddANewServerPrompt: String { return ElementL10n.tr("Localizable", "directory_add_a_new_server_prompt") }
  /// All rooms on %@ server
  public static func directoryServerAllRoomsOnServer(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "directory_server_all_rooms_on_server", String(describing: p1))
  }
  /// All native %@ rooms
  public static func directoryServerNativeRooms(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "directory_server_native_rooms", String(describing: p1))
  }
  /// Server name
  public static var directoryServerPlaceholder: String { return ElementL10n.tr("Localizable", "directory_server_placeholder") }
  /// Your server
  public static var directoryYourServer: String { return ElementL10n.tr("Localizable", "directory_your_server") }
  /// Enable 'Allow integrations' in Settings to do this.
  public static var disabledIntegrationDialogContent: String { return ElementL10n.tr("Localizable", "disabled_integration_dialog_content") }
  /// Integrations are disabled
  public static var disabledIntegrationDialogTitle: String { return ElementL10n.tr("Localizable", "disabled_integration_dialog_title") }
  /// We’re excited to announce we’ve changed name! Your app is up to date and you’re signed in to your account.
  public static var disclaimerContent: String { return ElementL10n.tr("Localizable", "disclaimer_content") }
  /// GOT IT
  public static var disclaimerNegativeButton: String { return ElementL10n.tr("Localizable", "disclaimer_negative_button") }
  /// LEARN MORE
  public static var disclaimerPositiveButton: String { return ElementL10n.tr("Localizable", "disclaimer_positive_button") }
  /// Riot is now Element!
  public static var disclaimerTitle: String { return ElementL10n.tr("Localizable", "disclaimer_title") }
  /// Disconnect identity server
  public static var disconnectIdentityServer: String { return ElementL10n.tr("Localizable", "disconnect_identity_server") }
  /// Disconnect from the identity server %@?
  public static func disconnectIdentityServerDialogContent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "disconnect_identity_server_dialog_content", String(describing: p1))
  }
  /// Invite by email, find contacts and more…
  public static var discoveryInvite: String { return ElementL10n.tr("Localizable", "discovery_invite") }
  /// Discovery (%@)
  public static func discoverySection(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "discovery_section", String(describing: p1))
  }
  /// Doesn't look like a valid email address
  public static var doesNotLookLikeValidEmail: String { return ElementL10n.tr("Localizable", "does_not_look_like_valid_email") }
  /// Done
  public static var done: String { return ElementL10n.tr("Localizable", "done") }
  /// File %1$@ has been downloaded!
  public static func downloadedFile(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "downloaded_file", String(describing: p1))
  }
  /// Re-request encryption keys from your other sessions.
  public static var e2eReRequestEncryptionKey: String { return ElementL10n.tr("Localizable", "e2e_re_request_encryption_key") }
  /// Please launch %@ on another device that can decrypt the message so it can send the keys to this session.
  public static func e2eReRequestEncryptionKeyDialogContent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "e2e_re_request_encryption_key_dialog_content", String(describing: p1))
  }
  /// Unlock encrypted messages history
  public static var e2eUseKeybackup: String { return ElementL10n.tr("Localizable", "e2e_use_keybackup") }
  /// Edit
  public static var edit: String { return ElementL10n.tr("Localizable", "edit") }
  /// Edit poll
  public static var editPollTitle: String { return ElementL10n.tr("Localizable", "edit_poll_title") }
  /// (edited)
  public static var editedSuffix: String { return ElementL10n.tr("Localizable", "edited_suffix") }
  /// Activities
  public static var emojiPickerActivityCategory: String { return ElementL10n.tr("Localizable", "emoji_picker_activity_category") }
  /// Flags
  public static var emojiPickerFlagsCategory: String { return ElementL10n.tr("Localizable", "emoji_picker_flags_category") }
  /// Food & Drink
  public static var emojiPickerFoodsCategory: String { return ElementL10n.tr("Localizable", "emoji_picker_foods_category") }
  /// Animals & Nature
  public static var emojiPickerNatureCategory: String { return ElementL10n.tr("Localizable", "emoji_picker_nature_category") }
  /// Objects
  public static var emojiPickerObjectsCategory: String { return ElementL10n.tr("Localizable", "emoji_picker_objects_category") }
  /// Smileys & People
  public static var emojiPickerPeopleCategory: String { return ElementL10n.tr("Localizable", "emoji_picker_people_category") }
  /// Travel & Places
  public static var emojiPickerPlacesCategory: String { return ElementL10n.tr("Localizable", "emoji_picker_places_category") }
  /// Symbols
  public static var emojiPickerSymbolsCategory: String { return ElementL10n.tr("Localizable", "emoji_picker_symbols_category") }
  /// Your contact book is empty
  public static var emptyContactBook: String { return ElementL10n.tr("Localizable", "empty_contact_book") }
  /// Encrypted message
  public static var encryptedMessage: String { return ElementL10n.tr("Localizable", "encrypted_message") }
  /// Encrypted by an unverified device
  public static var encryptedUnverified: String { return ElementL10n.tr("Localizable", "encrypted_unverified") }
  /// Encryption enabled
  public static var encryptionEnabled: String { return ElementL10n.tr("Localizable", "encryption_enabled") }
  /// Messages in this room are end-to-end encrypted. Learn more & verify users in their profile.
  public static var encryptionEnabledTileDescription: String { return ElementL10n.tr("Localizable", "encryption_enabled_tile_description") }
  /// Export E2E room keys
  public static var encryptionExportE2eRoomKeys: String { return ElementL10n.tr("Localizable", "encryption_export_e2e_room_keys") }
  /// Export
  public static var encryptionExportExport: String { return ElementL10n.tr("Localizable", "encryption_export_export") }
  /// Please create a passphrase to encrypt the exported keys. You will need to enter the same passphrase to be able to import the keys.
  public static var encryptionExportNotice: String { return ElementL10n.tr("Localizable", "encryption_export_notice") }
  /// Export room keys
  public static var encryptionExportRoomKeys: String { return ElementL10n.tr("Localizable", "encryption_export_room_keys") }
  /// Export the keys to a local file
  public static var encryptionExportRoomKeysSummary: String { return ElementL10n.tr("Localizable", "encryption_export_room_keys_summary") }
  /// Keys successfully exported
  public static var encryptionExportedSuccessfully: String { return ElementL10n.tr("Localizable", "encryption_exported_successfully") }
  /// Encryption has been misconfigured.
  public static var encryptionHasBeenMisconfigured: String { return ElementL10n.tr("Localizable", "encryption_has_been_misconfigured") }
  /// Import E2E room keys
  public static var encryptionImportE2eRoomKeys: String { return ElementL10n.tr("Localizable", "encryption_import_e2e_room_keys") }
  /// Import
  public static var encryptionImportImport: String { return ElementL10n.tr("Localizable", "encryption_import_import") }
  /// Import room keys
  public static var encryptionImportRoomKeys: String { return ElementL10n.tr("Localizable", "encryption_import_room_keys") }
  /// Plural format key: "%#@VARIABLE@"
  public static func encryptionImportRoomKeysSuccess(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "encryption_import_room_keys_success", p1)
  }
  /// Import the keys from a local file
  public static var encryptionImportRoomKeysSummary: String { return ElementL10n.tr("Localizable", "encryption_import_room_keys_summary") }
  /// Cross-Signing
  public static var encryptionInformationCrossSigningState: String { return ElementL10n.tr("Localizable", "encryption_information_cross_signing_state") }
  /// Decryption error
  public static var encryptionInformationDecryptionError: String { return ElementL10n.tr("Localizable", "encryption_information_decryption_error") }
  /// Session key
  public static var encryptionInformationDeviceKey: String { return ElementL10n.tr("Localizable", "encryption_information_device_key") }
  /// Public name
  public static var encryptionInformationDeviceName: String { return ElementL10n.tr("Localizable", "encryption_information_device_name") }
  /// Cross-Signing is enabled
  /// Private Keys on device.
  public static var encryptionInformationDgXsigningComplete: String { return ElementL10n.tr("Localizable", "encryption_information_dg_xsigning_complete") }
  /// Cross-Signing is not enabled
  public static var encryptionInformationDgXsigningDisabled: String { return ElementL10n.tr("Localizable", "encryption_information_dg_xsigning_disabled") }
  /// Cross-Signing is enabled.
  /// Keys are not trusted
  public static var encryptionInformationDgXsigningNotTrusted: String { return ElementL10n.tr("Localizable", "encryption_information_dg_xsigning_not_trusted") }
  /// Cross-Signing is enabled
  /// Keys are trusted.
  /// Private keys are not known
  public static var encryptionInformationDgXsigningTrusted: String { return ElementL10n.tr("Localizable", "encryption_information_dg_xsigning_trusted") }
  /// Not Verified
  public static var encryptionInformationNotVerified: String { return ElementL10n.tr("Localizable", "encryption_information_not_verified") }
  /// unknown ip
  public static var encryptionInformationUnknownIp: String { return ElementL10n.tr("Localizable", "encryption_information_unknown_ip") }
  /// Verified
  public static var encryptionInformationVerified: String { return ElementL10n.tr("Localizable", "encryption_information_verified") }
  /// Verify
  public static var encryptionInformationVerify: String { return ElementL10n.tr("Localizable", "encryption_information_verify") }
  /// Confirm by comparing the following with the User Settings in your other session:
  public static var encryptionInformationVerifyDeviceWarning: String { return ElementL10n.tr("Localizable", "encryption_information_verify_device_warning") }
  /// If they don't match, the security of your communication may be compromised.
  public static var encryptionInformationVerifyDeviceWarning2: String { return ElementL10n.tr("Localizable", "encryption_information_verify_device_warning2") }
  /// Encrypted Messages Recovery
  public static var encryptionMessageRecovery: String { return ElementL10n.tr("Localizable", "encryption_message_recovery") }
  /// Encryption is misconfigured
  public static var encryptionMisconfigured: String { return ElementL10n.tr("Localizable", "encryption_misconfigured") }
  /// Never send encrypted messages to unverified sessions from this session.
  public static var encryptionNeverSendToUnverifiedDevicesSummary: String { return ElementL10n.tr("Localizable", "encryption_never_send_to_unverified_devices_summary") }
  /// Encrypt to verified sessions only
  public static var encryptionNeverSendToUnverifiedDevicesTitle: String { return ElementL10n.tr("Localizable", "encryption_never_send_to_unverified_devices_title") }
  /// Encryption not enabled
  public static var encryptionNotEnabled: String { return ElementL10n.tr("Localizable", "encryption_not_enabled") }
  /// Manage Key Backup
  public static var encryptionSettingsManageMessageRecoverySummary: String { return ElementL10n.tr("Localizable", "encryption_settings_manage_message_recovery_summary") }
  /// The encryption used by this room is not supported
  public static var encryptionUnknownAlgorithmTileDescription: String { return ElementL10n.tr("Localizable", "encryption_unknown_algorithm_tile_description") }
  /// End poll
  public static var endPollConfirmationApproveButton: String { return ElementL10n.tr("Localizable", "end_poll_confirmation_approve_button") }
  /// This will stop people from being able to vote and will display the final results of the poll.
  public static var endPollConfirmationDescription: String { return ElementL10n.tr("Localizable", "end_poll_confirmation_description") }
  /// End this poll?
  public static var endPollConfirmationTitle: String { return ElementL10n.tr("Localizable", "end_poll_confirmation_title") }
  /// Enter your %@ to continue.
  public static func enterAccountPassword(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "enter_account_password", String(describing: p1))
  }
  /// Select your Recovery Key, or input it manually by typing it or pasting from your clipboard
  public static var enterSecretStorageInputKey: String { return ElementL10n.tr("Localizable", "enter_secret_storage_input_key") }
  /// Cannot find secrets in storage
  public static var enterSecretStorageInvalid: String { return ElementL10n.tr("Localizable", "enter_secret_storage_invalid") }
  /// Use your %1$@ or use your %2$@ to continue.
  public static func enterSecretStoragePassphraseOrKey(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "enter_secret_storage_passphrase_or_key", String(describing: p1), String(describing: p2))
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func entries(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "entries", p1)
  }
  /// Unable to play %1$@
  public static func errorAudioMessageUnableToPlay(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "error_audio_message_unable_to_play", String(describing: p1))
  }
  /// Please choose a password.
  public static var errorEmptyFieldChoosePassword: String { return ElementL10n.tr("Localizable", "error_empty_field_choose_password") }
  /// Please choose a username.
  public static var errorEmptyFieldChooseUserName: String { return ElementL10n.tr("Localizable", "error_empty_field_choose_user_name") }
  /// Please enter a username.
  public static var errorEmptyFieldEnterUserName: String { return ElementL10n.tr("Localizable", "error_empty_field_enter_user_name") }
  /// Please enter your password.
  public static var errorEmptyFieldYourPassword: String { return ElementL10n.tr("Localizable", "error_empty_field_your_password") }
  /// Failed to import keys
  public static var errorFailedToImportKeys: String { return ElementL10n.tr("Localizable", "error_failed_to_import_keys") }
  /// Sorry, an error occurred while trying to join: %@
  public static func errorFailedToJoinRoom(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "error_failed_to_join_room", String(describing: p1))
  }
  /// The file is too large to upload.
  public static var errorFileTooBigSimple: String { return ElementL10n.tr("Localizable", "error_file_too_big_simple") }
  /// The homeserver does not accept username with only digits.
  public static var errorForbiddenDigitsOnlyUsername: String { return ElementL10n.tr("Localizable", "error_forbidden_digits_only_username") }
  /// Couldn't handle share data
  public static var errorHandlingIncomingShare: String { return ElementL10n.tr("Localizable", "error_handling_incoming_share") }
  /// Sorry, an error occurred while trying to join the conference
  public static var errorJitsiJoinConf: String { return ElementL10n.tr("Localizable", "error_jitsi_join_conf") }
  /// Sorry, conference calls with Jitsi are not supported on old devices (devices with Android OS below 6.0)
  public static var errorJitsiNotSupportedOnOldDevice: String { return ElementL10n.tr("Localizable", "error_jitsi_not_supported_on_old_device") }
  /// Looks like the server is taking too long to respond, this can be caused by either poor connectivity or an error with the server. Please try again in a while.
  public static var errorNetworkTimeout: String { return ElementL10n.tr("Localizable", "error_network_timeout") }
  /// Sorry, no external application has been found to complete this action.
  public static var errorNoExternalApplicationFound: String { return ElementL10n.tr("Localizable", "error_no_external_application_found") }
  /// No network. Please check your Internet connection.
  public static var errorNoNetwork: String { return ElementL10n.tr("Localizable", "error_no_network") }
  /// Can't open a room where you are banned from.
  public static var errorOpeningBannedRoom: String { return ElementL10n.tr("Localizable", "error_opening_banned_room") }
  /// Could not save media file
  public static var errorSavingMediaFile: String { return ElementL10n.tr("Localizable", "error_saving_media_file") }
  /// Please retry once you have accepted the terms and conditions of your homeserver.
  public static var errorTermsNotAccepted: String { return ElementL10n.tr("Localizable", "error_terms_not_accepted") }
  /// Ensure that you have clicked on the link in the email we have sent to you.
  public static var errorThreepidAuthFailed: String { return ElementL10n.tr("Localizable", "error_threepid_auth_failed") }
  /// Unauthorized, missing valid authentication credentials
  public static var errorUnauthorized: String { return ElementL10n.tr("Localizable", "error_unauthorized") }
  /// It looks like you’re trying to connect to another homeserver. Do you want to sign out?
  public static var errorUserAlreadyLoggedIn: String { return ElementL10n.tr("Localizable", "error_user_already_logged_in") }
  /// Cannot reply or edit while voice message is active
  public static var errorVoiceMessageCannotReplyOrEdit: String { return ElementL10n.tr("Localizable", "error_voice_message_cannot_reply_or_edit") }
  /// Cannot play this voice message
  public static var errorVoiceMessageUnableToPlay: String { return ElementL10n.tr("Localizable", "error_voice_message_unable_to_play") }
  /// Cannot record a voice message
  public static var errorVoiceMessageUnableToRecord: String { return ElementL10n.tr("Localizable", "error_voice_message_unable_to_record") }
  /// Message removed
  public static var eventRedacted: String { return ElementL10n.tr("Localizable", "event_redacted") }
  /// Event moderated by room admin
  public static var eventRedactedByAdminReason: String { return ElementL10n.tr("Localizable", "event_redacted_by_admin_reason") }
  /// Event moderated by room admin, reason: %1$@
  public static func eventRedactedByAdminReasonWithReason(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "event_redacted_by_admin_reason_with_reason", String(describing: p1))
  }
  /// Event deleted by user
  public static var eventRedactedByUserReason: String { return ElementL10n.tr("Localizable", "event_redacted_by_user_reason") }
  /// Event deleted by user, reason: %1$@
  public static func eventRedactedByUserReasonWithReason(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "event_redacted_by_user_reason_with_reason", String(describing: p1))
  }
  /// Delete all failed messages
  public static var eventStatusA11yDeleteAll: String { return ElementL10n.tr("Localizable", "event_status_a11y_delete_all") }
  /// Failed
  public static var eventStatusA11yFailed: String { return ElementL10n.tr("Localizable", "event_status_a11y_failed") }
  /// Sending
  public static var eventStatusA11ySending: String { return ElementL10n.tr("Localizable", "event_status_a11y_sending") }
  /// Sent
  public static var eventStatusA11ySent: String { return ElementL10n.tr("Localizable", "event_status_a11y_sent") }
  /// Do you want to cancel sending message?
  public static var eventStatusCancelSendingDialogMessage: String { return ElementL10n.tr("Localizable", "event_status_cancel_sending_dialog_message") }
  /// Are you sure you want to delete all unsent messages in this room?
  public static var eventStatusDeleteAllFailedDialogMessage: String { return ElementL10n.tr("Localizable", "event_status_delete_all_failed_dialog_message") }
  /// Delete unsent messages
  public static var eventStatusDeleteAllFailedDialogTitle: String { return ElementL10n.tr("Localizable", "event_status_delete_all_failed_dialog_title") }
  /// Messages failed to send
  public static var eventStatusFailedMessagesWarning: String { return ElementL10n.tr("Localizable", "event_status_failed_messages_warning") }
  /// Sending message…
  public static var eventStatusSendingMessage: String { return ElementL10n.tr("Localizable", "event_status_sending_message") }
  /// Message sent
  public static var eventStatusSentMessage: String { return ElementL10n.tr("Localizable", "event_status_sent_message") }
  /// Explore Rooms
  public static var exploreRooms: String { return ElementL10n.tr("Localizable", "explore_rooms") }
  /// The link %1$@ is taking you to another site: %2$@.
  /// 
  /// Are you sure you want to continue?
  public static func externalLinkConfirmationMessage(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "external_link_confirmation_message", String(describing: p1), String(describing: p2))
  }
  /// Double-check this link
  public static var externalLinkConfirmationTitle: String { return ElementL10n.tr("Localizable", "external_link_confirmation_title") }
  /// Direct Messages
  public static var fabMenuCreateChat: String { return ElementL10n.tr("Localizable", "fab_menu_create_chat") }
  /// Rooms
  public static var fabMenuCreateRoom: String { return ElementL10n.tr("Localizable", "fab_menu_create_room") }
  /// Failed to access secure storage
  public static var failedToAccessSecureStorage: String { return ElementL10n.tr("Localizable", "failed_to_access_secure_storage") }
  /// Failed to add widget
  public static var failedToAddWidget: String { return ElementL10n.tr("Localizable", "failed_to_add_widget") }
  /// Failed to set up Cross Signing
  public static var failedToInitializeCrossSigning: String { return ElementL10n.tr("Localizable", "failed_to_initialize_cross_signing") }
  /// Failed to remove widget
  public static var failedToRemoveWidget: String { return ElementL10n.tr("Localizable", "failed_to_remove_widget") }
  /// Failed to UnBan user
  public static var failedToUnban: String { return ElementL10n.tr("Localizable", "failed_to_unban") }
  /// Plural format key: "%#@VARIABLE@"
  public static func fallbackUsersRead(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "fallback_users_read", p1)
  }
  /// Feedback
  public static var feedback: String { return ElementL10n.tr("Localizable", "feedback") }
  /// The feedback failed to be sent (%@)
  public static func feedbackFailed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "feedback_failed", String(describing: p1))
  }
  /// Thanks, your feedback has been successfully sent
  public static var feedbackSent: String { return ElementL10n.tr("Localizable", "feedback_sent") }
  /// Finish
  public static var finish: String { return ElementL10n.tr("Localizable", "finish") }
  /// Finish setting up discovery.
  public static var finishSettingUpDiscovery: String { return ElementL10n.tr("Localizable", "finish_setting_up_discovery") }
  /// Finish setup
  public static var finishSetup: String { return ElementL10n.tr("Localizable", "finish_setup") }
  /// Font size
  public static var fontSize: String { return ElementL10n.tr("Localizable", "font_size") }
  /// Set automatically
  public static var fontSizeSectionAuto: String { return ElementL10n.tr("Localizable", "font_size_section_auto") }
  /// Choose manually
  public static var fontSizeSectionManually: String { return ElementL10n.tr("Localizable", "font_size_section_manually") }
  /// Choose font size
  public static var fontSizeTitle: String { return ElementL10n.tr("Localizable", "font_size_title") }
  /// Use system default
  public static var fontSizeUseSystem: String { return ElementL10n.tr("Localizable", "font_size_use_system") }
  /// Congratulations!
  public static var ftueAccountCreatedCongratulationsTitle: String { return ElementL10n.tr("Localizable", "ftue_account_created_congratulations_title") }
  /// Personalize profile
  public static var ftueAccountCreatedPersonalize: String { return ElementL10n.tr("Localizable", "ftue_account_created_personalize") }
  /// Your account %@ has been created
  public static func ftueAccountCreatedSubtitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ftue_account_created_subtitle", String(describing: p1))
  }
  /// Take me home
  public static var ftueAccountCreatedTakeMeHome: String { return ElementL10n.tr("Localizable", "ftue_account_created_take_me_home") }
  /// Are you a human?
  public static var ftueAuthCaptchaTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_captcha_title") }
  /// Choose where your conversations are kept, giving you control and independence. Connected via Matrix.
  public static var ftueAuthCarouselControlBody: String { return ElementL10n.tr("Localizable", "ftue_auth_carousel_control_body") }
  /// You're in control.
  public static var ftueAuthCarouselControlTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_carousel_control_title") }
  /// End-to-end encrypted and no phone number required. No ads or datamining.
  public static var ftueAuthCarouselEncryptedBody: String { return ElementL10n.tr("Localizable", "ftue_auth_carousel_encrypted_body") }
  /// Secure messaging.
  public static var ftueAuthCarouselEncryptedTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_carousel_encrypted_title") }
  /// Secure and independent communication that gives you the same level of privacy as a face-to-face conversation in your own home.
  public static var ftueAuthCarouselSecureBody: String { return ElementL10n.tr("Localizable", "ftue_auth_carousel_secure_body") }
  /// Own your conversations.
  public static var ftueAuthCarouselSecureTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_carousel_secure_title") }
  /// %@ is also great for the workplace. It’s trusted by the world’s most secure organisations.
  public static func ftueAuthCarouselWorkplaceBody(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ftue_auth_carousel_workplace_body", String(describing: p1))
  }
  /// Messaging for your team.
  public static var ftueAuthCarouselWorkplaceTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_carousel_workplace_title") }
  /// Get in touch
  public static var ftueAuthChooseServerEmsCta: String { return ElementL10n.tr("Localizable", "ftue_auth_choose_server_ems_cta") }
  /// Element Matrix Services (EMS) is a robust and reliable hosting service for fast, secure and real time communication. Find out how on <a href=${ftue_ems_url}>element.io/ems</a>
  public static var ftueAuthChooseServerEmsSubtitle: String { return ElementL10n.tr("Localizable", "ftue_auth_choose_server_ems_subtitle") }
  /// Want to host your own server?
  public static var ftueAuthChooseServerEmsTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_choose_server_ems_title") }
  /// Server URL
  public static var ftueAuthChooseServerEntryHint: String { return ElementL10n.tr("Localizable", "ftue_auth_choose_server_entry_hint") }
  /// What is the address of your server?
  public static var ftueAuthChooseServerSignInSubtitle: String { return ElementL10n.tr("Localizable", "ftue_auth_choose_server_sign_in_subtitle") }
  /// What is the address of your server? This is like a home for all your data
  public static var ftueAuthChooseServerSubtitle: String { return ElementL10n.tr("Localizable", "ftue_auth_choose_server_subtitle") }
  /// Select your server
  public static var ftueAuthChooseServerTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_choose_server_title") }
  /// Where your conversations will live
  public static var ftueAuthCreateAccountChooseServerHeader: String { return ElementL10n.tr("Localizable", "ftue_auth_create_account_choose_server_header") }
  /// Edit
  public static var ftueAuthCreateAccountEditServerSelection: String { return ElementL10n.tr("Localizable", "ftue_auth_create_account_edit_server_selection") }
  /// Must be 8 characters or more
  public static var ftueAuthCreateAccountPasswordEntryFooter: String { return ElementL10n.tr("Localizable", "ftue_auth_create_account_password_entry_footer") }
  /// Or
  public static var ftueAuthCreateAccountSsoSectionHeader: String { return ElementL10n.tr("Localizable", "ftue_auth_create_account_sso_section_header") }
  /// Create your account
  public static var ftueAuthCreateAccountTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_create_account_title") }
  /// Others can discover you %@
  public static func ftueAuthCreateAccountUsernameEntryFooter(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ftue_auth_create_account_username_entry_footer", String(describing: p1))
  }
  /// Email
  public static var ftueAuthEmailEntryTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_email_entry_title") }
  /// Resend email
  public static var ftueAuthEmailResendEmail: String { return ElementL10n.tr("Localizable", "ftue_auth_email_resend_email") }
  /// %@ needs to verify your account
  public static func ftueAuthEmailSubtitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ftue_auth_email_subtitle", String(describing: p1))
  }
  /// Enter your email
  public static var ftueAuthEmailTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_email_title") }
  /// Did not receive an email?
  public static var ftueAuthEmailVerificationFooter: String { return ElementL10n.tr("Localizable", "ftue_auth_email_verification_footer") }
  /// Follow the instructions sent to %@
  public static func ftueAuthEmailVerificationSubtitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ftue_auth_email_verification_subtitle", String(describing: p1))
  }
  /// Verify your email
  public static var ftueAuthEmailVerificationTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_email_verification_title") }
  /// Forgot password
  public static var ftueAuthForgotPassword: String { return ElementL10n.tr("Localizable", "ftue_auth_forgot_password") }
  /// Username / Email / Phone
  public static var ftueAuthLoginUsernameEntry: String { return ElementL10n.tr("Localizable", "ftue_auth_login_username_entry") }
  /// New Password
  public static var ftueAuthNewPasswordEntryTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_new_password_entry_title") }
  /// Make sure it's 8 characters or more.
  public static var ftueAuthNewPasswordSubtitle: String { return ElementL10n.tr("Localizable", "ftue_auth_new_password_subtitle") }
  /// Choose a new password
  public static var ftueAuthNewPasswordTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_new_password_title") }
  /// Password reset
  public static var ftueAuthPasswordResetConfirmation: String { return ElementL10n.tr("Localizable", "ftue_auth_password_reset_confirmation") }
  /// Follow the instructions send to %@
  public static func ftueAuthPasswordResetEmailConfirmationSubtitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ftue_auth_password_reset_email_confirmation_subtitle", String(describing: p1))
  }
  /// Confirmation code
  public static var ftueAuthPhoneConfirmationEntryTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_phone_confirmation_entry_title") }
  /// Resend code
  public static var ftueAuthPhoneConfirmationResendCode: String { return ElementL10n.tr("Localizable", "ftue_auth_phone_confirmation_resend_code") }
  /// A code was sent to %@
  public static func ftueAuthPhoneConfirmationSubtitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ftue_auth_phone_confirmation_subtitle", String(describing: p1))
  }
  /// Confirm your phone number
  public static var ftueAuthPhoneConfirmationTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_phone_confirmation_title") }
  /// Phone Number
  public static var ftueAuthPhoneEntryTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_phone_entry_title") }
  /// %@ needs to verify your account
  public static func ftueAuthPhoneSubtitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ftue_auth_phone_subtitle", String(describing: p1))
  }
  /// Enter your phone number
  public static var ftueAuthPhoneTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_phone_title") }
  /// Reset password
  public static var ftueAuthResetPassword: String { return ElementL10n.tr("Localizable", "ftue_auth_reset_password") }
  /// Check your email.
  public static var ftueAuthResetPasswordBreakerTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_reset_password_breaker_title") }
  /// %@ will send you a verification link
  public static func ftueAuthResetPasswordEmailSubtitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ftue_auth_reset_password_email_subtitle", String(describing: p1))
  }
  /// Where your conversations live
  public static var ftueAuthSignInChooseServerHeader: String { return ElementL10n.tr("Localizable", "ftue_auth_sign_in_choose_server_header") }
  /// Sign out all devices
  public static var ftueAuthSignOutAllDevices: String { return ElementL10n.tr("Localizable", "ftue_auth_sign_out_all_devices") }
  /// Please read through %@'s terms and policies
  public static func ftueAuthTermsSubtitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ftue_auth_terms_subtitle", String(describing: p1))
  }
  /// Server policies
  public static var ftueAuthTermsTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_terms_title") }
  /// Connect to server
  public static var ftueAuthUseCaseConnectToServer: String { return ElementL10n.tr("Localizable", "ftue_auth_use_case_connect_to_server") }
  /// Looking to join an existing server?
  public static var ftueAuthUseCaseJoinExistingServer: String { return ElementL10n.tr("Localizable", "ftue_auth_use_case_join_existing_server") }
  /// Friends and family
  public static var ftueAuthUseCaseOptionOne: String { return ElementL10n.tr("Localizable", "ftue_auth_use_case_option_one") }
  /// Communities
  public static var ftueAuthUseCaseOptionThree: String { return ElementL10n.tr("Localizable", "ftue_auth_use_case_option_three") }
  /// Teams
  public static var ftueAuthUseCaseOptionTwo: String { return ElementL10n.tr("Localizable", "ftue_auth_use_case_option_two") }
  /// Not sure yet? %@
  public static func ftueAuthUseCaseSkip(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ftue_auth_use_case_skip", String(describing: p1))
  }
  /// Skip this question
  public static var ftueAuthUseCaseSkipPartial: String { return ElementL10n.tr("Localizable", "ftue_auth_use_case_skip_partial") }
  /// We'll help you get connected
  public static var ftueAuthUseCaseSubtitle: String { return ElementL10n.tr("Localizable", "ftue_auth_use_case_subtitle") }
  /// Who will you chat to the most?
  public static var ftueAuthUseCaseTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_use_case_title") }
  /// Welcome back!
  public static var ftueAuthWelcomeBackTitle: String { return ElementL10n.tr("Localizable", "ftue_auth_welcome_back_title") }
  /// You can change this later
  public static var ftueDisplayNameEntryFooter: String { return ElementL10n.tr("Localizable", "ftue_display_name_entry_footer") }
  /// Display Name
  public static var ftueDisplayNameEntryTitle: String { return ElementL10n.tr("Localizable", "ftue_display_name_entry_title") }
  /// Choose a display name
  public static var ftueDisplayNameTitle: String { return ElementL10n.tr("Localizable", "ftue_display_name_title") }
  /// Head to settings anytime to update your profile
  public static var ftuePersonalizeCompleteSubtitle: String { return ElementL10n.tr("Localizable", "ftue_personalize_complete_subtitle") }
  /// Looking good!
  public static var ftuePersonalizeCompleteTitle: String { return ElementL10n.tr("Localizable", "ftue_personalize_complete_title") }
  /// Let's go
  public static var ftuePersonalizeLetsGo: String { return ElementL10n.tr("Localizable", "ftue_personalize_lets_go") }
  /// Skip this step
  public static var ftuePersonalizeSkipThisStep: String { return ElementL10n.tr("Localizable", "ftue_personalize_skip_this_step") }
  /// Save and continue
  public static var ftuePersonalizeSubmit: String { return ElementL10n.tr("Localizable", "ftue_personalize_submit") }
  /// Time to put a face to the name
  public static var ftueProfilePictureSubtitle: String { return ElementL10n.tr("Localizable", "ftue_profile_picture_subtitle") }
  /// Add a profile picture
  public static var ftueProfilePictureTitle: String { return ElementL10n.tr("Localizable", "ftue_profile_picture_title") }
  /// %1$@: %2$@
  public static func genericLabelAndValue(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "generic_label_and_value", String(describing: p1), String(describing: p2))
  }
  /// Give Feedback
  public static var giveFeedback: String { return ElementL10n.tr("Localizable", "give_feedback") }
  /// Give Feedback
  public static var giveFeedbackThreads: String { return ElementL10n.tr("Localizable", "give_feedback_threads") }
  /// Retry
  public static var globalRetry: String { return ElementL10n.tr("Localizable", "global_retry") }
  /// Home
  public static var groupDetailsHome: String { return ElementL10n.tr("Localizable", "group_details_home") }
  /// You have been banned from %1$@ by %2$@
  public static func hasBeenBanned(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "has_been_banned", String(describing: p1), String(describing: p2))
  }
  /// You have been removed from %1$@ by %2$@
  public static func hasBeenRemoved(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "has_been_removed", String(describing: p1), String(describing: p2))
  }
  /// Long click on a room to see more options
  public static var helpLongClickOnRoomForMoreOptions: String { return ElementL10n.tr("Localizable", "help_long_click_on_room_for_more_options") }
  /// Hide advanced
  public static var hideAdvanced: String { return ElementL10n.tr("Localizable", "hide_advanced") }
  /// The all-in-one secure chat app for teams, friends and organisations. Create a chat, or join an existing room, to get started.
  public static var homeEmptyNoRoomsMessage: String { return ElementL10n.tr("Localizable", "home_empty_no_rooms_message") }
  /// Welcome to %@,
  /// %@.
  public static func homeEmptyNoRoomsTitle(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "home_empty_no_rooms_title", String(describing: p1), String(describing: p2))
  }
  /// This is where your unread messages will show up, when you have some.
  public static var homeEmptyNoUnreadsMessage: String { return ElementL10n.tr("Localizable", "home_empty_no_unreads_message") }
  /// Nothing to report.
  public static var homeEmptyNoUnreadsTitle: String { return ElementL10n.tr("Localizable", "home_empty_no_unreads_title") }
  /// Spaces are a new way to group rooms and people. Add an existing room, or create a new one, using the bottom-right button.
  public static var homeEmptySpaceNoRoomsMessage: String { return ElementL10n.tr("Localizable", "home_empty_space_no_rooms_message") }
  /// %@
  /// is looking a little empty.
  public static func homeEmptySpaceNoRoomsTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "home_empty_space_no_rooms_title", String(describing: p1))
  }
  /// Filter room names
  public static var homeFilterPlaceholderHome: String { return ElementL10n.tr("Localizable", "home_filter_placeholder_home") }
  /// Layout preferences
  public static var homeLayoutPreferences: String { return ElementL10n.tr("Localizable", "home_layout_preferences") }
  /// Show filters
  public static var homeLayoutPreferencesFilters: String { return ElementL10n.tr("Localizable", "home_layout_preferences_filters") }
  /// Show recents
  public static var homeLayoutPreferencesRecents: String { return ElementL10n.tr("Localizable", "home_layout_preferences_recents") }
  /// Activity
  public static var homeLayoutPreferencesSortActivity: String { return ElementL10n.tr("Localizable", "home_layout_preferences_sort_activity") }
  /// Sort by
  public static var homeLayoutPreferencesSortBy: String { return ElementL10n.tr("Localizable", "home_layout_preferences_sort_by") }
  /// A - Z
  public static var homeLayoutPreferencesSortName: String { return ElementL10n.tr("Localizable", "home_layout_preferences_sort_name") }
  /// Homeserver API URL
  public static var hsClientUrl: String { return ElementL10n.tr("Localizable", "hs_client_url") }
  /// Homeserver URL
  public static var hsUrl: String { return ElementL10n.tr("Localizable", "hs_url") }
  /// Huge
  public static var huge: String { return ElementL10n.tr("Localizable", "huge") }
  /// Identity server
  public static var identityServer: String { return ElementL10n.tr("Localizable", "identity_server") }
  /// To discover existing contacts, you need to send contact info (emails and phone numbers) to your identity server. We hash your data before sending for privacy.
  public static var identityServerConsentDialogContent3: String { return ElementL10n.tr("Localizable", "identity_server_consent_dialog_content_3") }
  /// Do you agree to send this info?
  public static var identityServerConsentDialogContentQuestion: String { return ElementL10n.tr("Localizable", "identity_server_consent_dialog_content_question") }
  /// Send emails and phone numbers to %@
  public static func identityServerConsentDialogTitle2(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "identity_server_consent_dialog_title_2", String(describing: p1))
  }
  /// The association has failed.
  public static var identityServerErrorBindingError: String { return ElementL10n.tr("Localizable", "identity_server_error_binding_error") }
  /// For your privacy, %@ only supports sending hashed user emails and phone number.
  public static func identityServerErrorBulkSha256NotSupported(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "identity_server_error_bulk_sha256_not_supported", String(describing: p1))
  }
  /// There is no current association with this identifier.
  public static var identityServerErrorNoCurrentBindingError: String { return ElementL10n.tr("Localizable", "identity_server_error_no_current_binding_error") }
  /// Please first configure an identity server.
  public static var identityServerErrorNoIdentityServerConfigured: String { return ElementL10n.tr("Localizable", "identity_server_error_no_identity_server_configured") }
  /// This operation is not possible. The homeserver is outdated.
  public static var identityServerErrorOutdatedHomeServer: String { return ElementL10n.tr("Localizable", "identity_server_error_outdated_home_server") }
  /// This identity server is outdated. %@ support only API V2.
  public static func identityServerErrorOutdatedIdentityServer(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "identity_server_error_outdated_identity_server", String(describing: p1))
  }
  /// Please first accepts the terms of the identity server in the settings.
  public static var identityServerErrorTermsNotSigned: String { return ElementL10n.tr("Localizable", "identity_server_error_terms_not_signed") }
  /// You are not using any identity server
  public static var identityServerNotDefined: String { return ElementL10n.tr("Localizable", "identity_server_not_defined") }
  /// Alternatively, you can enter any other identity server URL
  public static var identityServerSetAlternativeNotice: String { return ElementL10n.tr("Localizable", "identity_server_set_alternative_notice") }
  /// Enter the URL of an identity server
  public static var identityServerSetAlternativeNoticeNoDefault: String { return ElementL10n.tr("Localizable", "identity_server_set_alternative_notice_no_default") }
  /// Submit
  public static var identityServerSetAlternativeSubmit: String { return ElementL10n.tr("Localizable", "identity_server_set_alternative_submit") }
  /// Your homeserver (%1$@) proposes to use %2$@ for your identity server
  public static func identityServerSetDefaultNotice(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "identity_server_set_default_notice", String(describing: p1), String(describing: p2))
  }
  /// Use %1$@
  public static func identityServerSetDefaultSubmit(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "identity_server_set_default_submit", String(describing: p1))
  }
  /// The user consent has not been provided.
  public static var identityServerUserConsentNotProvided: String { return ElementL10n.tr("Localizable", "identity_server_user_consent_not_provided") }
  /// Ignore
  public static var ignoreRequestShortLabel: String { return ElementL10n.tr("Localizable", "ignore_request_short_label") }
  /// Import e2e keys from file "%1$@".
  public static func importE2eKeysFromFile(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "import_e2e_keys_from_file", String(describing: p1))
  }
  /// Incoming Video Call
  public static var incomingVideoCall: String { return ElementL10n.tr("Localizable", "incoming_video_call") }
  /// Incoming Voice Call
  public static var incomingVoiceCall: String { return ElementL10n.tr("Localizable", "incoming_voice_call") }
  /// %@ needs to perform a clear cache to be up to date, for the following reason:
  /// %@
  /// 
  /// Note that this action will restart the app and it may take some time.
  public static func initialSyncRequestContent(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "initial_sync_request_content", String(describing: p1), String(describing: p2))
  }
  /// - Some users have been unignored
  public static var initialSyncRequestReasonUnignoredUsers: String { return ElementL10n.tr("Localizable", "initial_sync_request_reason_unignored_users") }
  /// Initial sync request
  public static var initialSyncRequestTitle: String { return ElementL10n.tr("Localizable", "initial_sync_request_title") }
  /// Initial sync:
  /// Downloading data…
  public static var initialSyncStartDownloading: String { return ElementL10n.tr("Localizable", "initial_sync_start_downloading") }
  /// Initial sync:
  /// Importing account…
  public static var initialSyncStartImportingAccount: String { return ElementL10n.tr("Localizable", "initial_sync_start_importing_account") }
  /// Initial sync:
  /// Importing crypto
  public static var initialSyncStartImportingAccountCrypto: String { return ElementL10n.tr("Localizable", "initial_sync_start_importing_account_crypto") }
  /// Initial sync:
  /// Importing account data
  public static var initialSyncStartImportingAccountData: String { return ElementL10n.tr("Localizable", "initial_sync_start_importing_account_data") }
  /// Initial sync:
  /// Importing invited rooms
  public static var initialSyncStartImportingAccountInvitedRooms: String { return ElementL10n.tr("Localizable", "initial_sync_start_importing_account_invited_rooms") }
  /// Initial sync:
  /// Loading your conversations
  /// If you've joined lots of rooms, this might take a while
  public static var initialSyncStartImportingAccountJoinedRooms: String { return ElementL10n.tr("Localizable", "initial_sync_start_importing_account_joined_rooms") }
  /// Initial sync:
  /// Importing left rooms
  public static var initialSyncStartImportingAccountLeftRooms: String { return ElementL10n.tr("Localizable", "initial_sync_start_importing_account_left_rooms") }
  /// Initial sync:
  /// Importing rooms
  public static var initialSyncStartImportingAccountRooms: String { return ElementL10n.tr("Localizable", "initial_sync_start_importing_account_rooms") }
  /// Initial sync:
  /// Waiting for server response…
  public static var initialSyncStartServerComputing: String { return ElementL10n.tr("Localizable", "initial_sync_start_server_computing") }
  /// Initialize CrossSigning
  public static var initializeCrossSigning: String { return ElementL10n.tr("Localizable", "initialize_cross_signing") }
  /// Invalid QR code (Invalid URI)!
  public static var invalidQrCodeUri: String { return ElementL10n.tr("Localizable", "invalid_qr_code_uri") }
  /// Invitation sent to %1$@
  public static func invitationSentToOneUser(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "invitation_sent_to_one_user", String(describing: p1))
  }
  /// Invites
  public static var invitationsHeader: String { return ElementL10n.tr("Localizable", "invitations_header") }
  /// Plural format key: "%#@VARIABLE@"
  public static func invitationsSentToOneAndMoreUsers(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "invitations_sent_to_one_and_more_users", p1)
  }
  /// Invitations sent to %1$@ and %2$@
  public static func invitationsSentToTwoUsers(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "invitations_sent_to_two_users", String(describing: p1), String(describing: p2))
  }
  /// Invite by email
  public static var inviteByEmail: String { return ElementL10n.tr("Localizable", "invite_by_email") }
  /// Share link
  public static var inviteByLink: String { return ElementL10n.tr("Localizable", "invite_by_link") }
  /// Invite by username or mail
  public static var inviteByUsernameOrMail: String { return ElementL10n.tr("Localizable", "invite_by_username_or_mail") }
  /// Invite friends
  public static var inviteFriends: String { return ElementL10n.tr("Localizable", "invite_friends") }
  /// 🔐️ Join me on %@
  public static func inviteFriendsRichTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "invite_friends_rich_title", String(describing: p1))
  }
  /// Hey, talk to me on %@: %@
  public static func inviteFriendsText(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "invite_friends_text", String(describing: p1), String(describing: p2))
  }
  /// Just to this room
  public static var inviteJustToThisRoom: String { return ElementL10n.tr("Localizable", "invite_just_to_this_room") }
  /// They won’t be a part of %@
  public static func inviteJustToThisRoomDesc(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "invite_just_to_this_room_desc", String(describing: p1))
  }
  /// Invite people
  public static var invitePeopleMenu: String { return ElementL10n.tr("Localizable", "invite_people_menu") }
  /// Invite people to your space
  public static var invitePeopleToYourSpace: String { return ElementL10n.tr("Localizable", "invite_people_to_your_space") }
  /// It’s just you at the moment.  %@ will be even better with others.
  public static func invitePeopleToYourSpaceDesc(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "invite_people_to_your_space_desc", String(describing: p1))
  }
  /// Invite to %@
  public static func inviteToSpace(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "invite_to_space", String(describing: p1))
  }
  /// Invite to %@
  public static func inviteToSpaceWithName(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "invite_to_space_with_name", String(describing: p1))
  }
  /// They’ll be able to explore %@
  public static func inviteToSpaceWithNameDesc(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "invite_to_space_with_name_desc", String(describing: p1))
  }
  /// INVITE
  public static var inviteUsersToRoomActionInvite: String { return ElementL10n.tr("Localizable", "invite_users_to_room_action_invite") }
  /// We could not invite users. Please check the users you want to invite and try again.
  public static var inviteUsersToRoomFailure: String { return ElementL10n.tr("Localizable", "invite_users_to_room_failure") }
  /// Invite Users
  public static var inviteUsersToRoomTitle: String { return ElementL10n.tr("Localizable", "invite_users_to_room_title") }
  /// Invited
  public static var invited: String { return ElementL10n.tr("Localizable", "invited") }
  /// Invited by %@
  public static func invitedBy(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "invited_by", String(describing: p1))
  }
  /// This is where your new requests and invites will be.
  public static var invitesEmptyMessage: String { return ElementL10n.tr("Localizable", "invites_empty_message") }
  /// Nothing new.
  public static var invitesEmptyTitle: String { return ElementL10n.tr("Localizable", "invites_empty_title") }
  /// Invites
  public static var invitesTitle: String { return ElementL10n.tr("Localizable", "invites_title") }
  /// Inviting users…
  public static var invitingUsersToRoom: String { return ElementL10n.tr("Localizable", "inviting_users_to_room") }
  /// Please be patient, it may take some time.
  public static var itMayTakeSomeTime: String { return ElementL10n.tr("Localizable", "it_may_take_some_time") }
  /// Leave the current conference and switch to the other one?
  public static var jitsiLeaveConfToJoinAnotherOneContent: String { return ElementL10n.tr("Localizable", "jitsi_leave_conf_to_join_another_one_content") }
  /// Join Anyway
  public static var joinAnyway: String { return ElementL10n.tr("Localizable", "join_anyway") }
  /// Join Room
  public static var joinRoom: String { return ElementL10n.tr("Localizable", "join_room") }
  /// Join Space
  public static var joinSpace: String { return ElementL10n.tr("Localizable", "join_space") }
  /// Join replacement room
  public static var joiningReplacementRoom: String { return ElementL10n.tr("Localizable", "joining_replacement_room") }
  /// Keep it safe
  public static var keepItSafe: String { return ElementL10n.tr("Localizable", "keep_it_safe") }
  /// Key Share Request
  public static var keyShareRequest: String { return ElementL10n.tr("Localizable", "key_share_request") }
  /// Backing up your keys. This may take several minutes…
  public static var keysBackupBannerInProgress: String { return ElementL10n.tr("Localizable", "keys_backup_banner_in_progress") }
  /// Never lose encrypted messages
  public static var keysBackupBannerRecoverLine1: String { return ElementL10n.tr("Localizable", "keys_backup_banner_recover_line1") }
  /// Use Key Backup
  public static var keysBackupBannerRecoverLine2: String { return ElementL10n.tr("Localizable", "keys_backup_banner_recover_line2") }
  /// New secure message keys
  public static var keysBackupBannerUpdateLine1: String { return ElementL10n.tr("Localizable", "keys_backup_banner_update_line1") }
  /// Manage in Key Backup
  public static var keysBackupBannerUpdateLine2: String { return ElementL10n.tr("Localizable", "keys_backup_banner_update_line2") }
  /// Failed to get latest restore keys version (%@).
  public static func keysBackupGetVersionError(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_get_version_error", String(describing: p1))
  }
  /// All keys backed up
  public static var keysBackupInfoKeysAllBackupUp: String { return ElementL10n.tr("Localizable", "keys_backup_info_keys_all_backup_up") }
  /// Plural format key: "%#@VARIABLE@"
  public static func keysBackupInfoKeysBackingUp(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_info_keys_backing_up", p1)
  }
  /// Algorithm
  public static var keysBackupInfoTitleAlgorithm: String { return ElementL10n.tr("Localizable", "keys_backup_info_title_algorithm") }
  /// Signature
  public static var keysBackupInfoTitleSignature: String { return ElementL10n.tr("Localizable", "keys_backup_info_title_signature") }
  /// Version
  public static var keysBackupInfoTitleVersion: String { return ElementL10n.tr("Localizable", "keys_backup_info_title_version") }
  /// Backup could not be decrypted with this passphrase: please verify that you entered the correct recovery passphrase.
  public static var keysBackupPassphraseErrorDecrypt: String { return ElementL10n.tr("Localizable", "keys_backup_passphrase_error_decrypt") }
  /// Please delete the passphrase if you want %@ to generate a recovery key.
  public static func keysBackupPassphraseNotEmptyErrorMessage(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_passphrase_not_empty_error_message", String(describing: p1))
  }
  /// Please enter a recovery key
  public static var keysBackupRecoveryCodeEmptyErrorMessage: String { return ElementL10n.tr("Localizable", "keys_backup_recovery_code_empty_error_message") }
  /// Backup could not be decrypted with this recovery key: please verify that you entered the correct recovery key.
  public static var keysBackupRecoveryCodeErrorDecrypt: String { return ElementL10n.tr("Localizable", "keys_backup_recovery_code_error_decrypt") }
  /// Fetching backup version…
  public static var keysBackupRestoreIsGettingBackupVersion: String { return ElementL10n.tr("Localizable", "keys_backup_restore_is_getting_backup_version") }
  /// Enter Recovery Key
  public static var keysBackupRestoreKeyEnterHint: String { return ElementL10n.tr("Localizable", "keys_backup_restore_key_enter_hint") }
  /// Plural format key: "%#@VARIABLE@"
  public static func keysBackupRestoreSuccessDescriptionPart1(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_restore_success_description_part1", p1)
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func keysBackupRestoreSuccessDescriptionPart2(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_restore_success_description_part2", p1)
  }
  /// Backup Restored %@ !
  public static func keysBackupRestoreSuccessTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_restore_success_title", String(describing: p1))
  }
  /// Keys are already up to date!
  public static var keysBackupRestoreSuccessTitleAlreadyUpToDate: String { return ElementL10n.tr("Localizable", "keys_backup_restore_success_title_already_up_to_date") }
  /// use your recovery key
  public static var keysBackupRestoreUseRecoveryKey: String { return ElementL10n.tr("Localizable", "keys_backup_restore_use_recovery_key") }
  /// Lost your recovery key? You can set up a new one in settings.
  public static var keysBackupRestoreWithKeyHelper: String { return ElementL10n.tr("Localizable", "keys_backup_restore_with_key_helper") }
  /// Use your recovery passphrase to unlock your encrypted messages history
  public static var keysBackupRestoreWithPassphrase: String { return ElementL10n.tr("Localizable", "keys_backup_restore_with_passphrase") }
  /// Don’t know your recovery passphrase, you can %@.
  public static func keysBackupRestoreWithPassphraseHelperWithLink(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_restore_with_passphrase_helper_with_link", String(describing: p1))
  }
  /// Use your Recovery Key to unlock your encrypted messages history
  public static var keysBackupRestoreWithRecoveryKey: String { return ElementL10n.tr("Localizable", "keys_backup_restore_with_recovery_key") }
  /// Computing recovery key…
  public static var keysBackupRestoringComputingKeyWaitingMessage: String { return ElementL10n.tr("Localizable", "keys_backup_restoring_computing_key_waiting_message") }
  /// Downloading keys…
  public static var keysBackupRestoringDownloadingBackupWaitingMessage: String { return ElementL10n.tr("Localizable", "keys_backup_restoring_downloading_backup_waiting_message") }
  /// Importing keys…
  public static var keysBackupRestoringImportingKeysWaitingMessage: String { return ElementL10n.tr("Localizable", "keys_backup_restoring_importing_keys_waiting_message") }
  /// Restoring backup:
  public static var keysBackupRestoringWaitingMessage: String { return ElementL10n.tr("Localizable", "keys_backup_restoring_waiting_message") }
  /// Checking backup state
  public static var keysBackupSettingsCheckingBackupState: String { return ElementL10n.tr("Localizable", "keys_backup_settings_checking_backup_state") }
  /// Delete Backup
  public static var keysBackupSettingsDeleteBackupButton: String { return ElementL10n.tr("Localizable", "keys_backup_settings_delete_backup_button") }
  /// Delete your backed up encryption keys from the server? You will no longer be able to use your recovery key to read encrypted message history.
  public static var keysBackupSettingsDeleteConfirmMessage: String { return ElementL10n.tr("Localizable", "keys_backup_settings_delete_confirm_message") }
  /// Delete Backup
  public static var keysBackupSettingsDeleteConfirmTitle: String { return ElementL10n.tr("Localizable", "keys_backup_settings_delete_confirm_title") }
  /// Deleting backup…
  public static var keysBackupSettingsDeletingBackup: String { return ElementL10n.tr("Localizable", "keys_backup_settings_deleting_backup") }
  /// Backup has a invalid signature from unverified session %@
  public static func keysBackupSettingsInvalidSignatureFromUnverifiedDevice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_settings_invalid_signature_from_unverified_device", String(describing: p1))
  }
  /// Backup has a invalid signature from verified session %@
  public static func keysBackupSettingsInvalidSignatureFromVerifiedDevice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_settings_invalid_signature_from_verified_device", String(describing: p1))
  }
  /// Restore from Backup
  public static var keysBackupSettingsRestoreBackupButton: String { return ElementL10n.tr("Localizable", "keys_backup_settings_restore_backup_button") }
  /// Backup has a valid signature from this user.
  public static var keysBackupSettingsSignatureFromThisUser: String { return ElementL10n.tr("Localizable", "keys_backup_settings_signature_from_this_user") }
  /// Backup has a signature from unknown session with ID %@.
  public static func keysBackupSettingsSignatureFromUnknownDevice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_settings_signature_from_unknown_device", String(describing: p1))
  }
  /// Key Backup is not active on this session.
  public static var keysBackupSettingsStatusKo: String { return ElementL10n.tr("Localizable", "keys_backup_settings_status_ko") }
  /// Your keys are not being backed up from this session.
  public static var keysBackupSettingsStatusNotSetup: String { return ElementL10n.tr("Localizable", "keys_backup_settings_status_not_setup") }
  /// Key Backup has been correctly set up for this session.
  public static var keysBackupSettingsStatusOk: String { return ElementL10n.tr("Localizable", "keys_backup_settings_status_ok") }
  /// To use Key Backup on this session, restore with your passphrase or recovery key now.
  public static var keysBackupSettingsUntrustedBackup: String { return ElementL10n.tr("Localizable", "keys_backup_settings_untrusted_backup") }
  /// Backup has a valid signature from this session.
  public static var keysBackupSettingsValidSignatureFromThisDevice: String { return ElementL10n.tr("Localizable", "keys_backup_settings_valid_signature_from_this_device") }
  /// Backup has a valid signature from unverified session %@
  public static func keysBackupSettingsValidSignatureFromUnverifiedDevice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_settings_valid_signature_from_unverified_device", String(describing: p1))
  }
  /// Backup has a valid signature from verified session %@.
  public static func keysBackupSettingsValidSignatureFromVerifiedDevice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "keys_backup_settings_valid_signature_from_verified_device", String(describing: p1))
  }
  /// Start using Key Backup
  public static var keysBackupSetup: String { return ElementL10n.tr("Localizable", "keys_backup_setup") }
  /// Creating Backup
  public static var keysBackupSetupCreatingBackup: String { return ElementL10n.tr("Localizable", "keys_backup_setup_creating_backup") }
  /// It looks like you already have setup key backup from another session. Do you want to replace it with the one you’re creating?
  public static var keysBackupSetupOverrideBackupPromptDescription: String { return ElementL10n.tr("Localizable", "keys_backup_setup_override_backup_prompt_description") }
  /// A backup already exist on your homeserver
  public static var keysBackupSetupOverrideBackupPromptTile: String { return ElementL10n.tr("Localizable", "keys_backup_setup_override_backup_prompt_tile") }
  /// Replace
  public static var keysBackupSetupOverrideReplace: String { return ElementL10n.tr("Localizable", "keys_backup_setup_override_replace") }
  /// Stop
  public static var keysBackupSetupOverrideStop: String { return ElementL10n.tr("Localizable", "keys_backup_setup_override_stop") }
  /// You may lose access to your messages if you log out or lose this device.
  public static var keysBackupSetupSkipMsg: String { return ElementL10n.tr("Localizable", "keys_backup_setup_skip_msg") }
  /// Are you sure?
  public static var keysBackupSetupSkipTitle: String { return ElementL10n.tr("Localizable", "keys_backup_setup_skip_title") }
  /// (Advanced)
  public static var keysBackupSetupStep1Advanced: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step1_advanced") }
  /// Messages in encrypted rooms are secured with end-to-end encryption. Only you and the recipient(s) have the keys to read these messages.
  /// 
  /// Securely back up your keys to avoid losing them.
  public static var keysBackupSetupStep1Description: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step1_description") }
  /// Manually export keys
  public static var keysBackupSetupStep1ManualExport: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step1_manual_export") }
  /// Or, secure your backup with a Recovery Key, saving it somewhere safe.
  public static var keysBackupSetupStep1RecoveryKeyAlternative: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step1_recovery_key_alternative") }
  /// Never lose encrypted messages
  public static var keysBackupSetupStep1Title: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step1_title") }
  /// Set Passphrase
  public static var keysBackupSetupStep2ButtonTitle: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step2_button_title") }
  /// (Advanced) Set up with Recovery Key
  public static var keysBackupSetupStep2SkipButtonTitle: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step2_skip_button_title") }
  /// We’ll store an encrypted copy of your keys on your homeserver. Protect your backup with a passphrase to keep it secure.
  /// 
  /// For maximum security, this should be different from your account password.
  public static var keysBackupSetupStep2TextDescription: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step2_text_description") }
  /// Secure your backup with a Passphrase.
  public static var keysBackupSetupStep2TextTitle: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step2_text_title") }
  /// Done
  public static var keysBackupSetupStep3ButtonTitle: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_button_title") }
  /// I’ve made a copy
  public static var keysBackupSetupStep3ButtonTitleNoPassphrase: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_button_title_no_passphrase") }
  /// Save Recovery Key
  public static var keysBackupSetupStep3CopyButtonTitle: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_copy_button_title") }
  /// Generating Recovery Key using passphrase, this process can take several seconds.
  public static var keysBackupSetupStep3GeneratingKeyStatus: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_generating_key_status") }
  /// Please make a copy
  public static var keysBackupSetupStep3PleaseMakeCopy: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_please_make_copy") }
  /// Save as File
  public static var keysBackupSetupStep3SaveButtonTitle: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_save_button_title") }
  /// Share recovery key with…
  public static var keysBackupSetupStep3ShareIntentChooserTitle: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_share_intent_chooser_title") }
  /// Share
  public static var keysBackupSetupStep3ShareRecoveryFile: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_share_recovery_file") }
  /// Success !
  public static var keysBackupSetupStep3SuccessTitle: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_success_title") }
  /// Your keys are being backed up.
  public static var keysBackupSetupStep3TextLine1: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_text_line1") }
  /// Your recovery key is a safety net - you can use it to restore access to your encrypted messages if you forget your passphrase.
  /// Keep your recovery key somewhere very secure, like a password manager (or a safe)
  public static var keysBackupSetupStep3TextLine2: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_text_line2") }
  /// Keep your recovery key somewhere very secure, like a password manager (or a safe)
  public static var keysBackupSetupStep3TextLine2NoPassphrase: String { return ElementL10n.tr("Localizable", "keys_backup_setup_step3_text_line2_no_passphrase") }
  /// An error occurred getting keys backup data
  public static var keysBackupUnableToGetKeysBackupData: String { return ElementL10n.tr("Localizable", "keys_backup_unable_to_get_keys_backup_data") }
  /// An error occurred getting trust info
  public static var keysBackupUnableToGetTrustInfo: String { return ElementL10n.tr("Localizable", "keys_backup_unable_to_get_trust_info") }
  /// Unlock History
  public static var keysBackupUnlockButton: String { return ElementL10n.tr("Localizable", "keys_backup_unlock_button") }
  /// Enable verbose logs.
  public static var labsAllowExtendedLogging: String { return ElementL10n.tr("Localizable", "labs_allow_extended_logging") }
  /// Verbose logs will help developers by providing more logs when you send a RageShake. Even when enabled, the application does not log message contents or any other private data.
  public static var labsAllowExtendedLoggingSummary: String { return ElementL10n.tr("Localizable", "labs_allow_extended_logging_summary") }
  /// Auto Report Decryption Errors.
  public static var labsAutoReportUisi: String { return ElementL10n.tr("Localizable", "labs_auto_report_uisi") }
  /// Your system will automatically send logs when an unable to decrypt error occurs
  public static var labsAutoReportUisiDesc: String { return ElementL10n.tr("Localizable", "labs_auto_report_uisi_desc") }
  /// Enable Element Call permission shortcuts
  public static var labsEnableElementCallPermissionShortcuts: String { return ElementL10n.tr("Localizable", "labs_enable_element_call_permission_shortcuts") }
  /// Auto-approve Element Call widgets and grant camera / mic access
  public static var labsEnableElementCallPermissionShortcutsSummary: String { return ElementL10n.tr("Localizable", "labs_enable_element_call_permission_shortcuts_summary") }
  /// Enable LaTeX mathematics
  public static var labsEnableLatexMaths: String { return ElementL10n.tr("Localizable", "labs_enable_latex_maths") }
  /// Enable Live Location Sharing
  public static var labsEnableLiveLocation: String { return ElementL10n.tr("Localizable", "labs_enable_live_location") }
  /// Temporary implementation: locations persist in room history
  public static var labsEnableLiveLocationSummary: String { return ElementL10n.tr("Localizable", "labs_enable_live_location_summary") }
  /// MSC3061: Sharing room keys for past messages
  public static var labsEnableMsc3061ShareHistory: String { return ElementL10n.tr("Localizable", "labs_enable_msc3061_share_history") }
  /// When inviting in an encrypted room that is sharing history, encrypted history will be visible.
  public static var labsEnableMsc3061ShareHistoryDesc: String { return ElementL10n.tr("Localizable", "labs_enable_msc3061_share_history_desc") }
  /// A simplified Element with optional tabs
  public static var labsEnableNewAppLayoutSummary: String { return ElementL10n.tr("Localizable", "labs_enable_new_app_layout_summary") }
  /// Enable new layout
  public static var labsEnableNewAppLayoutTitle: String { return ElementL10n.tr("Localizable", "labs_enable_new_app_layout_title") }
  /// Enable Thread Messages
  public static var labsEnableThreadMessages: String { return ElementL10n.tr("Localizable", "labs_enable_thread_messages") }
  /// Note: app will be restarted
  public static var labsEnableThreadMessagesDesc: String { return ElementL10n.tr("Localizable", "labs_enable_thread_messages_desc") }
  /// Add a dedicated tab for unread notifications on main screen.
  public static var labsShowUnreadNotificationsAsTab: String { return ElementL10n.tr("Localizable", "labs_show_unread_notifications_as_tab") }
  /// Enable swipe to reply in timeline
  public static var labsSwipeToReplyInTimeline: String { return ElementL10n.tr("Localizable", "labs_swipe_to_reply_in_timeline") }
  /// Large
  public static var large: String { return ElementL10n.tr("Localizable", "large") }
  /// Larger
  public static var larger: String { return ElementL10n.tr("Localizable", "larger") }
  /// Largest
  public static var largest: String { return ElementL10n.tr("Localizable", "largest") }
  /// Later
  public static var later: String { return ElementL10n.tr("Localizable", "later") }
  /// Leave
  public static var leaveSpace: String { return ElementL10n.tr("Localizable", "leave_space") }
  /// %@ policy
  public static func legalsApplicationTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "legals_application_title", String(describing: p1))
  }
  /// Your homeserver policy
  public static var legalsHomeServerTitle: String { return ElementL10n.tr("Localizable", "legals_home_server_title") }
  /// Your identity server policy
  public static var legalsIdentityServerTitle: String { return ElementL10n.tr("Localizable", "legals_identity_server_title") }
  /// This server does not provide any policy.
  public static var legalsNoPolicyProvided: String { return ElementL10n.tr("Localizable", "legals_no_policy_provided") }
  /// Third party libraries
  public static var legalsThirdPartyNotices: String { return ElementL10n.tr("Localizable", "legals_third_party_notices") }
  /// Light Theme
  public static var lightTheme: String { return ElementL10n.tr("Localizable", "light_theme") }
  /// Link copied to clipboard
  public static var linkCopiedToClipboard: String { return ElementL10n.tr("Localizable", "link_copied_to_clipboard") }
  /// Link this email with your account
  public static var linkThisEmailSettingsLink: String { return ElementL10n.tr("Localizable", "link_this_email_settings_link") }
  /// %@ in Settings to receive invites directly in %@.
  public static func linkThisEmailWithYourAccount(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "link_this_email_with_your_account", String(describing: p1), String(describing: p2))
  }
  /// Members
  public static var listMembers: String { return ElementL10n.tr("Localizable", "list_members") }
  /// Updated %1$@ ago
  public static func liveLocationBottomSheetLastUpdatedAt(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "live_location_bottom_sheet_last_updated_at", String(describing: p1))
  }
  /// Live location
  public static var liveLocationDescription: String { return ElementL10n.tr("Localizable", "live_location_description") }
  /// Please note: this is a labs feature using a temporary implementation. This means you will not be able to delete your location history, and advanced users will be able to see your location history even after you stop sharing your live location with this room.
  public static var liveLocationLabsPromotionDescription: String { return ElementL10n.tr("Localizable", "live_location_labs_promotion_description") }
  /// Enable location sharing
  public static var liveLocationLabsPromotionSwitchTitle: String { return ElementL10n.tr("Localizable", "live_location_labs_promotion_switch_title") }
  /// Live location sharing
  public static var liveLocationLabsPromotionTitle: String { return ElementL10n.tr("Localizable", "live_location_labs_promotion_title") }
  /// You need to have the right permissions in order to share live location in this room.
  public static var liveLocationNotEnoughPermissionDialogDescription: String { return ElementL10n.tr("Localizable", "live_location_not_enough_permission_dialog_description") }
  /// You don’t have permission to share live location
  public static var liveLocationNotEnoughPermissionDialogTitle: String { return ElementL10n.tr("Localizable", "live_location_not_enough_permission_dialog_title") }
  /// Share location
  public static var liveLocationShareLocationItemShare: String { return ElementL10n.tr("Localizable", "live_location_share_location_item_share") }
  /// Location sharing is in progress
  public static var liveLocationSharingNotificationDescription: String { return ElementL10n.tr("Localizable", "live_location_sharing_notification_description") }
  /// %@ Live Location
  public static func liveLocationSharingNotificationTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "live_location_sharing_notification_title", String(describing: p1))
  }
  /// Loading…
  public static var loading: String { return ElementL10n.tr("Localizable", "loading") }
  /// Retrieving your contacts…
  public static var loadingContactBook: String { return ElementL10n.tr("Localizable", "loading_contact_book") }
  /// Location
  public static var locationActivityTitlePreview: String { return ElementL10n.tr("Localizable", "location_activity_title_preview") }
  /// Share location
  public static var locationActivityTitleStaticSharing: String { return ElementL10n.tr("Localizable", "location_activity_title_static_sharing") }
  /// %@ could not access your location. Please try again later.
  public static func locationNotAvailableDialogContent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "location_not_available_dialog_content", String(describing: p1))
  }
  /// %@ could not access your location
  public static func locationNotAvailableDialogTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "location_not_available_dialog_title", String(describing: p1))
  }
  /// Open with
  public static var locationShareExternal: String { return ElementL10n.tr("Localizable", "location_share_external") }
  /// Live location enabled
  public static var locationShareLiveEnabled: String { return ElementL10n.tr("Localizable", "location_share_live_enabled") }
  /// Live location ended
  public static var locationShareLiveEnded: String { return ElementL10n.tr("Localizable", "location_share_live_ended") }
  /// %1$@ left
  public static func locationShareLiveRemainingTime(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "location_share_live_remaining_time", String(describing: p1))
  }
  /// 15 minutes
  public static var locationShareLiveSelectDurationOption1: String { return ElementL10n.tr("Localizable", "location_share_live_select_duration_option_1") }
  /// 1 hour
  public static var locationShareLiveSelectDurationOption2: String { return ElementL10n.tr("Localizable", "location_share_live_select_duration_option_2") }
  /// 8 hours
  public static var locationShareLiveSelectDurationOption3: String { return ElementL10n.tr("Localizable", "location_share_live_select_duration_option_3") }
  /// Share your live location for
  public static var locationShareLiveSelectDurationTitle: String { return ElementL10n.tr("Localizable", "location_share_live_select_duration_title") }
  /// Loading live location…
  public static var locationShareLiveStarted: String { return ElementL10n.tr("Localizable", "location_share_live_started") }
  /// Stop
  public static var locationShareLiveStop: String { return ElementL10n.tr("Localizable", "location_share_live_stop") }
  /// Live until %1$@
  public static func locationShareLiveUntil(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "location_share_live_until", String(describing: p1))
  }
  /// View live location
  public static var locationShareLiveView: String { return ElementL10n.tr("Localizable", "location_share_live_view") }
  /// Unable to load map
  /// This home server may not be configured to display maps.
  public static var locationShareLoadingMapError: String { return ElementL10n.tr("Localizable", "location_share_loading_map_error") }
  /// Share this location
  public static var locationShareOptionPinned: String { return ElementL10n.tr("Localizable", "location_share_option_pinned") }
  /// Share my current location
  public static var locationShareOptionUserCurrent: String { return ElementL10n.tr("Localizable", "location_share_option_user_current") }
  /// Share live location
  public static var locationShareOptionUserLive: String { return ElementL10n.tr("Localizable", "location_share_option_user_live") }
  /// Failed to load map
  public static var locationTimelineFailedToLoadMap: String { return ElementL10n.tr("Localizable", "location_timeline_failed_to_load_map") }
  /// Please perform the captcha challenge
  public static var loginA11yCaptchaContainer: String { return ElementL10n.tr("Localizable", "login_a11y_captcha_container") }
  /// Select matrix.org
  public static var loginA11yChooseMatrixOrg: String { return ElementL10n.tr("Localizable", "login_a11y_choose_matrix_org") }
  /// Select Element Matrix Services
  public static var loginA11yChooseModular: String { return ElementL10n.tr("Localizable", "login_a11y_choose_modular") }
  /// Select a custom homeserver
  public static var loginA11yChooseOther: String { return ElementL10n.tr("Localizable", "login_a11y_choose_other") }
  /// Clear history
  public static var loginClearHomeserverHistory: String { return ElementL10n.tr("Localizable", "login_clear_homeserver_history") }
  /// Connect to %1$@
  public static func loginConnectTo(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_connect_to", String(describing: p1))
  }
  /// Connect to a custom server
  public static var loginConnectToACustomServer: String { return ElementL10n.tr("Localizable", "login_connect_to_a_custom_server") }
  /// Connect to Element Matrix Services
  public static var loginConnectToModular: String { return ElementL10n.tr("Localizable", "login_connect_to_modular") }
  /// Sign in with Matrix ID
  public static var loginConnectUsingMatrixIdSubmit: String { return ElementL10n.tr("Localizable", "login_connect_using_matrix_id_submit") }
  /// Continue
  public static var loginContinue: String { return ElementL10n.tr("Localizable", "login_continue") }
  /// %@ Android
  public static func loginDefaultSessionPublicName(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_default_session_public_name", String(describing: p1))
  }
  /// Malformed JSON
  public static var loginErrorBadJson: String { return ElementL10n.tr("Localizable", "login_error_bad_json") }
  /// Cannot reach a homeserver at the URL %@. Please check your link or choose a homeserver manually.
  public static func loginErrorHomeserverFromUrlNotFound(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_error_homeserver_from_url_not_found", String(describing: p1))
  }
  /// Choose homeserver
  public static var loginErrorHomeserverFromUrlNotFoundEnterManual: String { return ElementL10n.tr("Localizable", "login_error_homeserver_from_url_not_found_enter_manual") }
  /// Cannot reach a homeserver at this URL, please check it
  public static var loginErrorHomeserverNotFound: String { return ElementL10n.tr("Localizable", "login_error_homeserver_not_found") }
  /// Please enter a valid URL
  public static var loginErrorInvalidHomeServer: String { return ElementL10n.tr("Localizable", "login_error_invalid_home_server") }
  /// Too many requests have been sent
  public static var loginErrorLimitExceeded: String { return ElementL10n.tr("Localizable", "login_error_limit_exceeded") }
  /// Plural format key: "%#@VARIABLE@"
  public static func loginErrorLimitExceededRetryAfter(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "login_error_limit_exceeded_retry_after", p1)
  }
  /// This is not a valid Matrix server address
  public static var loginErrorNoHomeserverFound: String { return ElementL10n.tr("Localizable", "login_error_no_homeserver_found") }
  /// Did not contain valid JSON
  public static var loginErrorNotJson: String { return ElementL10n.tr("Localizable", "login_error_not_json") }
  /// Outdated homeserver
  public static var loginErrorOutdatedHomeserverTitle: String { return ElementL10n.tr("Localizable", "login_error_outdated_homeserver_title") }
  /// This homeserver is running an old version. Ask your homeserver admin to upgrade. You can continue, but some features may not work correctly.
  public static var loginErrorOutdatedHomeserverWarningContent: String { return ElementL10n.tr("Localizable", "login_error_outdated_homeserver_warning_content") }
  /// SSL Error.
  public static var loginErrorSslOther: String { return ElementL10n.tr("Localizable", "login_error_ssl_other") }
  /// SSL Error: the peer's identity has not been verified.
  public static var loginErrorSslPeerUnverified: String { return ElementL10n.tr("Localizable", "login_error_ssl_peer_unverified") }
  /// Your email domain is not authorized to register on this server
  public static var loginErrorThreepidDenied: String { return ElementL10n.tr("Localizable", "login_error_threepid_denied") }
  /// This email is not associated to any account.
  public static var loginLoginWithEmailError: String { return ElementL10n.tr("Localizable", "login_login_with_email_error") }
  /// The application is not able to signin to this homeserver. The homeserver supports the following signin type(s): %1$@.
  /// 
  /// Do you want to signin using a web client?
  public static func loginModeNotSupported(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_mode_not_supported", String(describing: p1))
  }
  /// Enter code
  public static var loginMsisdnConfirmHint: String { return ElementL10n.tr("Localizable", "login_msisdn_confirm_hint") }
  /// We just sent a code to %1$@. Enter it below to verify it’s you.
  public static func loginMsisdnConfirmNotice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_msisdn_confirm_notice", String(describing: p1))
  }
  /// Send again
  public static var loginMsisdnConfirmSendAgain: String { return ElementL10n.tr("Localizable", "login_msisdn_confirm_send_again") }
  /// Next
  public static var loginMsisdnConfirmSubmit: String { return ElementL10n.tr("Localizable", "login_msisdn_confirm_submit") }
  /// Confirm phone number
  public static var loginMsisdnConfirmTitle: String { return ElementL10n.tr("Localizable", "login_msisdn_confirm_title") }
  /// International phone numbers must start with '+'
  public static var loginMsisdnErrorNotInternational: String { return ElementL10n.tr("Localizable", "login_msisdn_error_not_international") }
  /// Phone number seems invalid. Please check it
  public static var loginMsisdnErrorOther: String { return ElementL10n.tr("Localizable", "login_msisdn_error_other") }
  /// Please use the international format (phone number must start with '+')
  public static var loginMsisdnNotice: String { return ElementL10n.tr("Localizable", "login_msisdn_notice") }
  /// Sorry, this server isn’t accepting new accounts.
  public static var loginRegistrationDisabled: String { return ElementL10n.tr("Localizable", "login_registration_disabled") }
  /// The application is not able to create an account on this homeserver.
  /// 
  /// Do you want to signup using a web client?
  public static var loginRegistrationNotSupported: String { return ElementL10n.tr("Localizable", "login_registration_not_supported") }
  /// Your password is not yet changed.
  /// 
  /// Stop the password change process?
  public static var loginResetPasswordCancelConfirmationContent: String { return ElementL10n.tr("Localizable", "login_reset_password_cancel_confirmation_content") }
  /// Warning
  public static var loginResetPasswordCancelConfirmationTitle: String { return ElementL10n.tr("Localizable", "login_reset_password_cancel_confirmation_title") }
  /// Email
  public static var loginResetPasswordEmailHint: String { return ElementL10n.tr("Localizable", "login_reset_password_email_hint") }
  /// This email is not linked to any account
  public static var loginResetPasswordErrorNotFound: String { return ElementL10n.tr("Localizable", "login_reset_password_error_not_found") }
  /// A verification email was sent to %1$@.
  public static func loginResetPasswordMailConfirmationNotice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_reset_password_mail_confirmation_notice", String(describing: p1))
  }
  /// Tap on the link to confirm your new password. Once you've followed the link it contains, click below.
  public static var loginResetPasswordMailConfirmationNotice2: String { return ElementL10n.tr("Localizable", "login_reset_password_mail_confirmation_notice_2") }
  /// I have verified my email address
  public static var loginResetPasswordMailConfirmationSubmit: String { return ElementL10n.tr("Localizable", "login_reset_password_mail_confirmation_submit") }
  /// Check your inbox
  public static var loginResetPasswordMailConfirmationTitle: String { return ElementL10n.tr("Localizable", "login_reset_password_mail_confirmation_title") }
  /// A verification email will be sent to your inbox to confirm setting your new password.
  public static var loginResetPasswordNotice: String { return ElementL10n.tr("Localizable", "login_reset_password_notice") }
  /// Reset password on %1$@
  public static func loginResetPasswordOn(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_reset_password_on", String(describing: p1))
  }
  /// New password
  public static var loginResetPasswordPasswordHint: String { return ElementL10n.tr("Localizable", "login_reset_password_password_hint") }
  /// Next
  public static var loginResetPasswordSubmit: String { return ElementL10n.tr("Localizable", "login_reset_password_submit") }
  /// Your password has been reset.
  public static var loginResetPasswordSuccessNotice: String { return ElementL10n.tr("Localizable", "login_reset_password_success_notice") }
  /// You have been logged out of all sessions and will no longer receive push notifications. To re-enable notifications, sign in again on each device.
  public static var loginResetPasswordSuccessNotice2: String { return ElementL10n.tr("Localizable", "login_reset_password_success_notice_2") }
  /// Back to Sign In
  public static var loginResetPasswordSuccessSubmit: String { return ElementL10n.tr("Localizable", "login_reset_password_success_submit") }
  /// Success!
  public static var loginResetPasswordSuccessTitle: String { return ElementL10n.tr("Localizable", "login_reset_password_success_title") }
  /// Changing your password will reset any end-to-end encryption keys on all of your sessions, making encrypted chat history unreadable. Set up Key Backup or export your room keys from another session before resetting your password.
  public static var loginResetPasswordWarningContent: String { return ElementL10n.tr("Localizable", "login_reset_password_warning_content") }
  /// Continue
  public static var loginResetPasswordWarningSubmit: String { return ElementL10n.tr("Localizable", "login_reset_password_warning_submit") }
  /// Warning!
  public static var loginResetPasswordWarningTitle: String { return ElementL10n.tr("Localizable", "login_reset_password_warning_title") }
  /// Join millions for free on the largest public server
  public static var loginServerMatrixOrgText: String { return ElementL10n.tr("Localizable", "login_server_matrix_org_text") }
  /// Learn more
  public static var loginServerModularLearnMore: String { return ElementL10n.tr("Localizable", "login_server_modular_learn_more") }
  /// Premium hosting for organisations
  public static var loginServerModularText: String { return ElementL10n.tr("Localizable", "login_server_modular_text") }
  /// Custom & advanced settings
  public static var loginServerOtherText: String { return ElementL10n.tr("Localizable", "login_server_other_text") }
  /// Other
  public static var loginServerOtherTitle: String { return ElementL10n.tr("Localizable", "login_server_other_title") }
  /// Just like email, accounts have one home, although you can talk to anyone
  public static var loginServerText: String { return ElementL10n.tr("Localizable", "login_server_text") }
  /// Select a server
  public static var loginServerTitle: String { return ElementL10n.tr("Localizable", "login_server_title") }
  /// Enter the address of the server you want to use
  public static var loginServerUrlFormCommonNotice: String { return ElementL10n.tr("Localizable", "login_server_url_form_common_notice") }
  /// Element Matrix Services Address
  public static var loginServerUrlFormModularHint: String { return ElementL10n.tr("Localizable", "login_server_url_form_modular_hint") }
  /// Enter the address of the Modular Element or Server you want to use
  public static var loginServerUrlFormModularNotice: String { return ElementL10n.tr("Localizable", "login_server_url_form_modular_notice") }
  /// Premium hosting for organisations
  public static var loginServerUrlFormModularText: String { return ElementL10n.tr("Localizable", "login_server_url_form_modular_text") }
  /// Address
  public static var loginServerUrlFormOtherHint: String { return ElementL10n.tr("Localizable", "login_server_url_form_other_hint") }
  /// Email
  public static var loginSetEmailMandatoryHint: String { return ElementL10n.tr("Localizable", "login_set_email_mandatory_hint") }
  /// Set an email to recover your account. Later, you can optionally allow people you know to discover you by your email.
  public static var loginSetEmailNotice: String { return ElementL10n.tr("Localizable", "login_set_email_notice") }
  /// Email (optional)
  public static var loginSetEmailOptionalHint: String { return ElementL10n.tr("Localizable", "login_set_email_optional_hint") }
  /// Next
  public static var loginSetEmailSubmit: String { return ElementL10n.tr("Localizable", "login_set_email_submit") }
  /// Set email address
  public static var loginSetEmailTitle: String { return ElementL10n.tr("Localizable", "login_set_email_title") }
  /// Phone number
  public static var loginSetMsisdnMandatoryHint: String { return ElementL10n.tr("Localizable", "login_set_msisdn_mandatory_hint") }
  /// Set a phone number to optionally allow people you know to discover you.
  public static var loginSetMsisdnNotice: String { return ElementL10n.tr("Localizable", "login_set_msisdn_notice") }
  /// Please use the international format.
  public static var loginSetMsisdnNotice2: String { return ElementL10n.tr("Localizable", "login_set_msisdn_notice2") }
  /// Phone number (optional)
  public static var loginSetMsisdnOptionalHint: String { return ElementL10n.tr("Localizable", "login_set_msisdn_optional_hint") }
  /// Next
  public static var loginSetMsisdnSubmit: String { return ElementL10n.tr("Localizable", "login_set_msisdn_submit") }
  /// Set phone number
  public static var loginSetMsisdnTitle: String { return ElementL10n.tr("Localizable", "login_set_msisdn_title") }
  /// Sign In
  public static var loginSignin: String { return ElementL10n.tr("Localizable", "login_signin") }
  /// This is not a valid user identifier. Expected format: '@user:homeserver.org'
  public static var loginSigninMatrixIdErrorInvalidMatrixId: String { return ElementL10n.tr("Localizable", "login_signin_matrix_id_error_invalid_matrix_id") }
  /// Matrix ID
  public static var loginSigninMatrixIdHint: String { return ElementL10n.tr("Localizable", "login_signin_matrix_id_hint") }
  /// If you set up an account on a homeserver, use your Matrix ID (e.g. @user:domain.com) and password below.
  public static var loginSigninMatrixIdNotice: String { return ElementL10n.tr("Localizable", "login_signin_matrix_id_notice") }
  /// If you don’t know your password, go back to reset it.
  public static var loginSigninMatrixIdPasswordNotice: String { return ElementL10n.tr("Localizable", "login_signin_matrix_id_password_notice") }
  /// Sign in with Matrix ID
  public static var loginSigninMatrixIdTitle: String { return ElementL10n.tr("Localizable", "login_signin_matrix_id_title") }
  /// Continue with SSO
  public static var loginSigninSso: String { return ElementL10n.tr("Localizable", "login_signin_sso") }
  /// Sign in to %1$@
  public static func loginSigninTo(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_signin_to", String(describing: p1))
  }
  /// Username or email
  public static var loginSigninUsernameHint: String { return ElementL10n.tr("Localizable", "login_signin_username_hint") }
  /// Sign Up
  public static var loginSignup: String { return ElementL10n.tr("Localizable", "login_signup") }
  /// Your account is not created yet. Stop the registration process?
  public static var loginSignupCancelConfirmationContent: String { return ElementL10n.tr("Localizable", "login_signup_cancel_confirmation_content") }
  /// Warning
  public static var loginSignupCancelConfirmationTitle: String { return ElementL10n.tr("Localizable", "login_signup_cancel_confirmation_title") }
  /// That username is taken
  public static var loginSignupErrorUserInUse: String { return ElementL10n.tr("Localizable", "login_signup_error_user_in_use") }
  /// Password
  public static var loginSignupPasswordHint: String { return ElementL10n.tr("Localizable", "login_signup_password_hint") }
  /// Next
  public static var loginSignupSubmit: String { return ElementL10n.tr("Localizable", "login_signup_submit") }
  /// Sign up to %1$@
  public static func loginSignupTo(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_signup_to", String(describing: p1))
  }
  /// Username
  public static var loginSignupUsernameHint: String { return ElementL10n.tr("Localizable", "login_signup_username_hint") }
  /// Or
  public static var loginSocialContinue: String { return ElementL10n.tr("Localizable", "login_social_continue") }
  /// Continue with %@
  public static func loginSocialContinueWith(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_social_continue_with", String(describing: p1))
  }
  /// Sign in with %@
  public static func loginSocialSigninWith(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_social_signin_with", String(describing: p1))
  }
  /// Sign up with %@
  public static func loginSocialSignupWith(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_social_signup_with", String(describing: p1))
  }
  /// single sign-on
  public static var loginSocialSso: String { return ElementL10n.tr("Localizable", "login_social_sso") }
  /// I already have an account
  public static var loginSplashAlreadyHaveAccount: String { return ElementL10n.tr("Localizable", "login_splash_already_have_account") }
  /// Create account
  public static var loginSplashCreateAccount: String { return ElementL10n.tr("Localizable", "login_splash_create_account") }
  /// Get started
  public static var loginSplashSubmit: String { return ElementL10n.tr("Localizable", "login_splash_submit") }
  /// Chat with people directly or in groups
  public static var loginSplashText1: String { return ElementL10n.tr("Localizable", "login_splash_text1") }
  /// Keep conversations private with encryption
  public static var loginSplashText2: String { return ElementL10n.tr("Localizable", "login_splash_text2") }
  /// Extend & customise your experience
  public static var loginSplashText3: String { return ElementL10n.tr("Localizable", "login_splash_text3") }
  /// It's your conversation. Own it.
  public static var loginSplashTitle: String { return ElementL10n.tr("Localizable", "login_splash_title") }
  /// An error occurred when loading the page: %1$@ (%2$d)
  public static func loginSsoErrorMessage(_ p1: Any, _ p2: Int) -> String {
    return ElementL10n.tr("Localizable", "login_sso_error_message", String(describing: p1), p2)
  }
  /// Accept terms to continue
  public static var loginTermsTitle: String { return ElementL10n.tr("Localizable", "login_terms_title") }
  /// The entered code is not correct. Please check.
  public static var loginValidationCodeIsNotCorrect: String { return ElementL10n.tr("Localizable", "login_validation_code_is_not_correct") }
  /// We just sent an email to %1$@.
  /// Please click on the link it contains to continue the account creation.
  public static func loginWaitForEmailNotice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "login_wait_for_email_notice", String(describing: p1))
  }
  /// Please check your email
  public static var loginWaitForEmailTitle: String { return ElementL10n.tr("Localizable", "login_wait_for_email_title") }
  /// Sign out
  public static var logout: String { return ElementL10n.tr("Localizable", "logout") }
  /// Looking for someone not in %@?
  public static func lookingForSomeoneNotInSpace(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "looking_for_someone_not_in_space", String(describing: p1))
  }
  /// Low priority
  public static var lowPriorityHeader: String { return ElementL10n.tr("Localizable", "low_priority_header") }
  /// Malformed event, cannot display
  public static var malformedMessage: String { return ElementL10n.tr("Localizable", "malformed_message") }
  /// Markdown has been disabled.
  public static var markdownHasBeenDisabled: String { return ElementL10n.tr("Localizable", "markdown_has_been_disabled") }
  /// Markdown has been enabled.
  public static var markdownHasBeenEnabled: String { return ElementL10n.tr("Localizable", "markdown_has_been_enabled") }
  /// Matrix error
  public static var matrixError: String { return ElementL10n.tr("Localizable", "matrix_error") }
  /// Matrix contacts only
  public static var matrixOnlyFilter: String { return ElementL10n.tr("Localizable", "matrix_only_filter") }
  /// 1 month
  public static var mediaSavingPeriod1Month: String { return ElementL10n.tr("Localizable", "media_saving_period_1_month") }
  /// 1 week
  public static var mediaSavingPeriod1Week: String { return ElementL10n.tr("Localizable", "media_saving_period_1_week") }
  /// 3 days
  public static var mediaSavingPeriod3Days: String { return ElementL10n.tr("Localizable", "media_saving_period_3_days") }
  /// Forever
  public static var mediaSavingPeriodForever: String { return ElementL10n.tr("Localizable", "media_saving_period_forever") }
  /// Choose
  public static var mediaSourceChoose: String { return ElementL10n.tr("Localizable", "media_source_choose") }
  /// Email address
  public static var mediumEmail: String { return ElementL10n.tr("Localizable", "medium_email") }
  /// Phone number
  public static var mediumPhoneNumber: String { return ElementL10n.tr("Localizable", "medium_phone_number") }
  /// Banned by %1$@
  public static func memberBannedBy(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "member_banned_by", String(describing: p1))
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func membershipChanges(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "membership_changes", p1)
  }
  /// collapse
  public static var mergedEventsCollapse: String { return ElementL10n.tr("Localizable", "merged_events_collapse") }
  /// expand
  public static var mergedEventsExpand: String { return ElementL10n.tr("Localizable", "merged_events_expand") }
  /// Remove…
  public static var messageActionItemRedact: String { return ElementL10n.tr("Localizable", "message_action_item_redact") }
  /// Add Reaction
  public static var messageAddReaction: String { return ElementL10n.tr("Localizable", "message_add_reaction") }
  /// Show Message bubbles
  public static var messageBubbles: String { return ElementL10n.tr("Localizable", "message_bubbles") }
  /// Message Edits
  public static var messageEdits: String { return ElementL10n.tr("Localizable", "message_edits") }
  /// Ignore user
  public static var messageIgnoreUser: String { return ElementL10n.tr("Localizable", "message_ignore_user") }
  /// Message Key
  public static var messageKey: String { return ElementL10n.tr("Localizable", "message_key") }
  /// Show less
  public static var messageReactionShowLess: String { return ElementL10n.tr("Localizable", "message_reaction_show_less") }
  /// Plural format key: "%#@VARIABLE@"
  public static func messageReactionShowMore(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "message_reaction_show_more", p1)
  }
  /// View Edit History
  public static var messageViewEditHistory: String { return ElementL10n.tr("Localizable", "message_view_edit_history") }
  /// View Reactions
  public static var messageViewReaction: String { return ElementL10n.tr("Localizable", "message_view_reaction") }
  /// Plural format key: "%#@VARIABLE@"
  public static func missedAudioCall(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "missed_audio_call", p1)
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func missedVideoCall(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "missed_video_call", p1)
  }
  /// Missing permissions
  public static var missingPermissionsTitle: String { return ElementL10n.tr("Localizable", "missing_permissions_title") }
  /// You are already viewing this room!
  public static var navigateToRoomWhenAlreadyInTheRoom: String { return ElementL10n.tr("Localizable", "navigate_to_room_when_already_in_the_room") }
  /// You are already viewing this thread!
  public static var navigateToThreadWhenAlreadyInTheThread: String { return ElementL10n.tr("Localizable", "navigate_to_thread_when_already_in_the_thread") }
  /// New login. Was this you?
  public static var newSession: String { return ElementL10n.tr("Localizable", "new_session") }
  /// NO
  public static var no: String { return ElementL10n.tr("Localizable", "no") }
  /// Connectivity to the server has been lost
  public static var noConnectivityToTheServerIndicator: String { return ElementL10n.tr("Localizable", "no_connectivity_to_the_server_indicator") }
  /// Airplane mode is on
  public static var noConnectivityToTheServerIndicatorAirplane: String { return ElementL10n.tr("Localizable", "no_connectivity_to_the_server_indicator_airplane") }
  /// You are not ignoring any users
  public static var noIgnoredUsers: String { return ElementL10n.tr("Localizable", "no_ignored_users") }
  /// No edits found
  public static var noMessageEditsFound: String { return ElementL10n.tr("Localizable", "no_message_edits_found") }
  /// No more results
  public static var noMoreResults: String { return ElementL10n.tr("Localizable", "no_more_results") }
  /// You do not have permission to start a conference call in this room
  public static var noPermissionsToStartConfCall: String { return ElementL10n.tr("Localizable", "no_permissions_to_start_conf_call") }
  /// You do not have permission to start a conference call
  public static var noPermissionsToStartConfCallInDirectRoom: String { return ElementL10n.tr("Localizable", "no_permissions_to_start_conf_call_in_direct_room") }
  /// You do not have permission to start a call in this room
  public static var noPermissionsToStartWebrtcCall: String { return ElementL10n.tr("Localizable", "no_permissions_to_start_webrtc_call") }
  /// You do not have permission to start a call
  public static var noPermissionsToStartWebrtcCallInDirectRoom: String { return ElementL10n.tr("Localizable", "no_permissions_to_start_webrtc_call_in_direct_room") }
  /// No results
  public static var noResultPlaceholder: String { return ElementL10n.tr("Localizable", "no_result_placeholder") }
  /// You don’t currently have any stickerpacks enabled.
  /// 
  /// Add some now?
  public static var noStickerApplicationDialogContent: String { return ElementL10n.tr("Localizable", "no_sticker_application_dialog_content") }
  /// No valid Google Play Services APK found. Notifications may not work properly.
  public static var noValidGooglePlayServicesApk: String { return ElementL10n.tr("Localizable", "no_valid_google_play_services_apk") }
  /// None
  public static var `none`: String { return ElementL10n.tr("Localizable", "none") }
  /// Normal
  public static var normal: String { return ElementL10n.tr("Localizable", "normal") }
  /// It's not a valid matrix QR code
  public static var notAValidQrCode: String { return ElementL10n.tr("Localizable", "not_a_valid_qr_code") }
  /// Not Trusted
  public static var notTrusted: String { return ElementL10n.tr("Localizable", "not_trusted") }
  /// %@ answered the call.
  public static func noticeAnsweredCall(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_answered_call", String(describing: p1))
  }
  /// You answered the call.
  public static var noticeAnsweredCallByYou: String { return ElementL10n.tr("Localizable", "notice_answered_call_by_you") }
  /// (avatar was changed too)
  public static var noticeAvatarChangedToo: String { return ElementL10n.tr("Localizable", "notice_avatar_changed_too") }
  /// %1$@ changed their avatar
  public static func noticeAvatarUrlChanged(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_avatar_url_changed", String(describing: p1))
  }
  /// You changed your avatar
  public static var noticeAvatarUrlChangedByYou: String { return ElementL10n.tr("Localizable", "notice_avatar_url_changed_by_you") }
  /// %@ sent data to setup the call.
  public static func noticeCallCandidates(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_call_candidates", String(describing: p1))
  }
  /// You sent data to setup the call.
  public static var noticeCallCandidatesByYou: String { return ElementL10n.tr("Localizable", "notice_call_candidates_by_you") }
  /// The sender's device has not sent us the keys for this message.
  public static var noticeCryptoErrorUnknownInboundSessionId: String { return ElementL10n.tr("Localizable", "notice_crypto_error_unknown_inbound_session_id") }
  /// ** Unable to decrypt: %@ **
  public static func noticeCryptoUnableToDecrypt(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_crypto_unable_to_decrypt", String(describing: p1))
  }
  /// You cannot access this message
  public static var noticeCryptoUnableToDecryptFinal: String { return ElementL10n.tr("Localizable", "notice_crypto_unable_to_decrypt_final") }
  /// Waiting for this message, this may take a while
  public static var noticeCryptoUnableToDecryptFriendly: String { return ElementL10n.tr("Localizable", "notice_crypto_unable_to_decrypt_friendly") }
  /// Due to end-to-end encryption, you might need to wait for someone's message to arrive because the encryption keys were not properly sent to you.
  public static var noticeCryptoUnableToDecryptFriendlyDesc: String { return ElementL10n.tr("Localizable", "notice_crypto_unable_to_decrypt_friendly_desc") }
  /// Waiting for encryption history
  public static var noticeCryptoUnableToDecryptMerged: String { return ElementL10n.tr("Localizable", "notice_crypto_unable_to_decrypt_merged") }
  /// %1$@ created the discussion
  public static func noticeDirectRoomCreated(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_created", String(describing: p1))
  }
  /// You created the discussion
  public static var noticeDirectRoomCreatedByYou: String { return ElementL10n.tr("Localizable", "notice_direct_room_created_by_you") }
  /// %1$@ has allowed guests to join here.
  public static func noticeDirectRoomGuestAccessCanJoin(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_guest_access_can_join", String(describing: p1))
  }
  /// You have allowed guests to join here.
  public static var noticeDirectRoomGuestAccessCanJoinByYou: String { return ElementL10n.tr("Localizable", "notice_direct_room_guest_access_can_join_by_you") }
  /// %1$@ has prevented guests from joining the room.
  public static func noticeDirectRoomGuestAccessForbidden(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_guest_access_forbidden", String(describing: p1))
  }
  /// You have prevented guests from joining the room.
  public static var noticeDirectRoomGuestAccessForbiddenByYou: String { return ElementL10n.tr("Localizable", "notice_direct_room_guest_access_forbidden_by_you") }
  /// %1$@ joined
  public static func noticeDirectRoomJoin(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_join", String(describing: p1))
  }
  /// You joined
  public static var noticeDirectRoomJoinByYou: String { return ElementL10n.tr("Localizable", "notice_direct_room_join_by_you") }
  /// %1$@ joined. Reason: %2$@
  public static func noticeDirectRoomJoinWithReason(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_join_with_reason", String(describing: p1), String(describing: p2))
  }
  /// You joined. Reason: %1$@
  public static func noticeDirectRoomJoinWithReasonByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_join_with_reason_by_you", String(describing: p1))
  }
  /// %1$@ left the room
  public static func noticeDirectRoomLeave(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_leave", String(describing: p1))
  }
  /// You left the room
  public static var noticeDirectRoomLeaveByYou: String { return ElementL10n.tr("Localizable", "notice_direct_room_leave_by_you") }
  /// %1$@ left. Reason: %2$@
  public static func noticeDirectRoomLeaveWithReason(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_leave_with_reason", String(describing: p1), String(describing: p2))
  }
  /// You left. Reason: %1$@
  public static func noticeDirectRoomLeaveWithReasonByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_leave_with_reason_by_you", String(describing: p1))
  }
  /// %1$@ invited %2$@
  public static func noticeDirectRoomThirdPartyInvite(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_third_party_invite", String(describing: p1), String(describing: p2))
  }
  /// You invited %1$@
  public static func noticeDirectRoomThirdPartyInviteByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_third_party_invite_by_you", String(describing: p1))
  }
  /// %1$@ revoked the invitation for %2$@
  public static func noticeDirectRoomThirdPartyRevokedInvite(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_third_party_revoked_invite", String(describing: p1), String(describing: p2))
  }
  /// You revoked the invitation for %1$@
  public static func noticeDirectRoomThirdPartyRevokedInviteByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_third_party_revoked_invite_by_you", String(describing: p1))
  }
  /// %@ upgraded here.
  public static func noticeDirectRoomUpdate(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_direct_room_update", String(describing: p1))
  }
  /// You upgraded here.
  public static var noticeDirectRoomUpdateByYou: String { return ElementL10n.tr("Localizable", "notice_direct_room_update_by_you") }
  /// %1$@ changed their display name from %2$@ to %3$@
  public static func noticeDisplayNameChangedFrom(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_display_name_changed_from", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// You changed your display name from %1$@ to %2$@
  public static func noticeDisplayNameChangedFromByYou(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_display_name_changed_from_by_you", String(describing: p1), String(describing: p2))
  }
  /// %1$@ removed their display name (it was %2$@)
  public static func noticeDisplayNameRemoved(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_display_name_removed", String(describing: p1), String(describing: p2))
  }
  /// You removed your display name (it was %1$@)
  public static func noticeDisplayNameRemovedByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_display_name_removed_by_you", String(describing: p1))
  }
  /// %1$@ set their display name to %2$@
  public static func noticeDisplayNameSet(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_display_name_set", String(describing: p1), String(describing: p2))
  }
  /// You set your display name to %1$@
  public static func noticeDisplayNameSetByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_display_name_set_by_you", String(describing: p1))
  }
  /// %1$@ turned on end-to-end encryption.
  public static func noticeEndToEndOk(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_end_to_end_ok", String(describing: p1))
  }
  /// You turned on end-to-end encryption.
  public static var noticeEndToEndOkByYou: String { return ElementL10n.tr("Localizable", "notice_end_to_end_ok_by_you") }
  /// %1$@ turned on end-to-end encryption (unrecognised algorithm %2$@).
  public static func noticeEndToEndUnknownAlgorithm(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_end_to_end_unknown_algorithm", String(describing: p1), String(describing: p2))
  }
  /// You turned on end-to-end encryption (unrecognised algorithm %1$@).
  public static func noticeEndToEndUnknownAlgorithmByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_end_to_end_unknown_algorithm_by_you", String(describing: p1))
  }
  /// %@ ended the call.
  public static func noticeEndedCall(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_ended_call", String(describing: p1))
  }
  /// You ended the call.
  public static var noticeEndedCallByYou: String { return ElementL10n.tr("Localizable", "notice_ended_call_by_you") }
  /// %1$@ made future messages visible to %2$@
  public static func noticeMadeFutureDirectRoomVisibility(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_made_future_direct_room_visibility", String(describing: p1), String(describing: p2))
  }
  /// You made future messages visible to %1$@
  public static func noticeMadeFutureDirectRoomVisibilityByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_made_future_direct_room_visibility_by_you", String(describing: p1))
  }
  /// %1$@ made future room history visible to %2$@
  public static func noticeMadeFutureRoomVisibility(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_made_future_room_visibility", String(describing: p1), String(describing: p2))
  }
  /// You made future room history visible to %1$@
  public static func noticeMadeFutureRoomVisibilityByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_made_future_room_visibility_by_you", String(describing: p1))
  }
  /// %1$@ made no changes
  public static func noticeMemberNoChanges(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_member_no_changes", String(describing: p1))
  }
  /// You made no changes
  public static var noticeMemberNoChangesByYou: String { return ElementL10n.tr("Localizable", "notice_member_no_changes_by_you") }
  /// %@ placed a video call.
  public static func noticePlacedVideoCall(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_placed_video_call", String(describing: p1))
  }
  /// You placed a video call.
  public static var noticePlacedVideoCallByYou: String { return ElementL10n.tr("Localizable", "notice_placed_video_call_by_you") }
  /// %@ placed a voice call.
  public static func noticePlacedVoiceCall(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_placed_voice_call", String(describing: p1))
  }
  /// You placed a voice call.
  public static var noticePlacedVoiceCallByYou: String { return ElementL10n.tr("Localizable", "notice_placed_voice_call_by_you") }
  /// %1$@ changed the power level of %2$@.
  public static func noticePowerLevelChanged(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_power_level_changed", String(describing: p1), String(describing: p2))
  }
  /// You changed the power level of %1$@.
  public static func noticePowerLevelChangedByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_power_level_changed_by_you", String(describing: p1))
  }
  /// %1$@ from %2$@ to %3$@
  public static func noticePowerLevelDiff(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_power_level_diff", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func noticeRoomAliasesAdded(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notice_room_aliases_added", p1)
  }
  /// %1$@ added %2$@ and removed %3$@ as addresses for this room.
  public static func noticeRoomAliasesAddedAndRemoved(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_aliases_added_and_removed", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// You added %1$@ and removed %2$@ as addresses for this room.
  public static func noticeRoomAliasesAddedAndRemovedByYou(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_aliases_added_and_removed_by_you", String(describing: p1), String(describing: p2))
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func noticeRoomAliasesAddedByYou(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notice_room_aliases_added_by_you", p1)
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func noticeRoomAliasesRemoved(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notice_room_aliases_removed", p1)
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func noticeRoomAliasesRemovedByYou(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notice_room_aliases_removed_by_you", p1)
  }
  /// %1$@ changed the room avatar
  public static func noticeRoomAvatarChanged(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_avatar_changed", String(describing: p1))
  }
  /// You changed the room avatar
  public static var noticeRoomAvatarChangedByYou: String { return ElementL10n.tr("Localizable", "notice_room_avatar_changed_by_you") }
  /// %1$@ removed the room avatar
  public static func noticeRoomAvatarRemoved(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_avatar_removed", String(describing: p1))
  }
  /// You removed the room avatar
  public static var noticeRoomAvatarRemovedByYou: String { return ElementL10n.tr("Localizable", "notice_room_avatar_removed_by_you") }
  /// %1$@ banned %2$@
  public static func noticeRoomBan(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_ban", String(describing: p1), String(describing: p2))
  }
  /// You banned %1$@
  public static func noticeRoomBanByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_ban_by_you", String(describing: p1))
  }
  /// %1$@ banned %2$@. Reason: %3$@
  public static func noticeRoomBanWithReason(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_ban_with_reason", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// You banned %1$@. Reason: %2$@
  public static func noticeRoomBanWithReasonByYou(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_ban_with_reason_by_you", String(describing: p1), String(describing: p2))
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func noticeRoomCanonicalAliasAlternativeAdded(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notice_room_canonical_alias_alternative_added", p1)
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func noticeRoomCanonicalAliasAlternativeAddedByYou(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notice_room_canonical_alias_alternative_added_by_you", p1)
  }
  /// %1$@ changed the alternative addresses for this room.
  public static func noticeRoomCanonicalAliasAlternativeChanged(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_canonical_alias_alternative_changed", String(describing: p1))
  }
  /// You changed the alternative addresses for this room.
  public static var noticeRoomCanonicalAliasAlternativeChangedByYou: String { return ElementL10n.tr("Localizable", "notice_room_canonical_alias_alternative_changed_by_you") }
  /// Plural format key: "%#@VARIABLE@"
  public static func noticeRoomCanonicalAliasAlternativeRemoved(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notice_room_canonical_alias_alternative_removed", p1)
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func noticeRoomCanonicalAliasAlternativeRemovedByYou(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notice_room_canonical_alias_alternative_removed_by_you", p1)
  }
  /// %1$@ changed the main and alternative addresses for this room.
  public static func noticeRoomCanonicalAliasMainAndAlternativeChanged(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_canonical_alias_main_and_alternative_changed", String(describing: p1))
  }
  /// You changed the main and alternative addresses for this room.
  public static var noticeRoomCanonicalAliasMainAndAlternativeChangedByYou: String { return ElementL10n.tr("Localizable", "notice_room_canonical_alias_main_and_alternative_changed_by_you") }
  /// %1$@ changed the addresses for this room.
  public static func noticeRoomCanonicalAliasNoChange(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_canonical_alias_no_change", String(describing: p1))
  }
  /// You changed the addresses for this room.
  public static var noticeRoomCanonicalAliasNoChangeByYou: String { return ElementL10n.tr("Localizable", "notice_room_canonical_alias_no_change_by_you") }
  /// %1$@ set the main address for this room to %2$@.
  public static func noticeRoomCanonicalAliasSet(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_canonical_alias_set", String(describing: p1), String(describing: p2))
  }
  /// You set the main address for this room to %1$@.
  public static func noticeRoomCanonicalAliasSetByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_canonical_alias_set_by_you", String(describing: p1))
  }
  /// %1$@ removed the main address for this room.
  public static func noticeRoomCanonicalAliasUnset(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_canonical_alias_unset", String(describing: p1))
  }
  /// You removed the main address for this room.
  public static var noticeRoomCanonicalAliasUnsetByYou: String { return ElementL10n.tr("Localizable", "notice_room_canonical_alias_unset_by_you") }
  /// %1$@ created the room
  public static func noticeRoomCreated(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_created", String(describing: p1))
  }
  /// You created the room
  public static var noticeRoomCreatedByYou: String { return ElementL10n.tr("Localizable", "notice_room_created_by_you") }
  /// %1$@ has allowed guests to join the room.
  public static func noticeRoomGuestAccessCanJoin(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_guest_access_can_join", String(describing: p1))
  }
  /// You have allowed guests to join the room.
  public static var noticeRoomGuestAccessCanJoinByYou: String { return ElementL10n.tr("Localizable", "notice_room_guest_access_can_join_by_you") }
  /// %1$@ has prevented guests from joining the room.
  public static func noticeRoomGuestAccessForbidden(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_guest_access_forbidden", String(describing: p1))
  }
  /// You have prevented guests from joining the room.
  public static var noticeRoomGuestAccessForbiddenByYou: String { return ElementL10n.tr("Localizable", "notice_room_guest_access_forbidden_by_you") }
  /// %1$@ invited %2$@
  public static func noticeRoomInvite(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_invite", String(describing: p1), String(describing: p2))
  }
  /// You invited %1$@
  public static func noticeRoomInviteByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_invite_by_you", String(describing: p1))
  }
  /// %@'s invitation
  public static func noticeRoomInviteNoInvitee(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_invite_no_invitee", String(describing: p1))
  }
  /// Your invitation
  public static var noticeRoomInviteNoInviteeByYou: String { return ElementL10n.tr("Localizable", "notice_room_invite_no_invitee_by_you") }
  /// %1$@'s invitation. Reason: %2$@
  public static func noticeRoomInviteNoInviteeWithReason(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_invite_no_invitee_with_reason", String(describing: p1), String(describing: p2))
  }
  /// Your invitation. Reason: %1$@
  public static func noticeRoomInviteNoInviteeWithReasonByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_invite_no_invitee_with_reason_by_you", String(describing: p1))
  }
  /// %1$@ invited %2$@. Reason: %3$@
  public static func noticeRoomInviteWithReason(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_invite_with_reason", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// You invited %1$@. Reason: %2$@
  public static func noticeRoomInviteWithReasonByYou(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_invite_with_reason_by_you", String(describing: p1), String(describing: p2))
  }
  /// %1$@ invited you
  public static func noticeRoomInviteYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_invite_you", String(describing: p1))
  }
  /// %1$@ invited you. Reason: %2$@
  public static func noticeRoomInviteYouWithReason(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_invite_you_with_reason", String(describing: p1), String(describing: p2))
  }
  /// %1$@ joined the room
  public static func noticeRoomJoin(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_join", String(describing: p1))
  }
  /// You joined the room
  public static var noticeRoomJoinByYou: String { return ElementL10n.tr("Localizable", "notice_room_join_by_you") }
  /// %1$@ joined the room. Reason: %2$@
  public static func noticeRoomJoinWithReason(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_join_with_reason", String(describing: p1), String(describing: p2))
  }
  /// You joined the room. Reason: %1$@
  public static func noticeRoomJoinWithReasonByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_join_with_reason_by_you", String(describing: p1))
  }
  /// %1$@ left the room
  public static func noticeRoomLeave(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_leave", String(describing: p1))
  }
  /// You left the room
  public static var noticeRoomLeaveByYou: String { return ElementL10n.tr("Localizable", "notice_room_leave_by_you") }
  /// %1$@ left the room. Reason: %2$@
  public static func noticeRoomLeaveWithReason(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_leave_with_reason", String(describing: p1), String(describing: p2))
  }
  /// You left the room. Reason: %1$@
  public static func noticeRoomLeaveWithReasonByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_leave_with_reason_by_you", String(describing: p1))
  }
  /// %1$@ changed the room name to: %2$@
  public static func noticeRoomNameChanged(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_name_changed", String(describing: p1), String(describing: p2))
  }
  /// You changed the room name to: %1$@
  public static func noticeRoomNameChangedByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_name_changed_by_you", String(describing: p1))
  }
  /// %1$@ removed the room name
  public static func noticeRoomNameRemoved(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_name_removed", String(describing: p1))
  }
  /// You removed the room name
  public static var noticeRoomNameRemovedByYou: String { return ElementL10n.tr("Localizable", "notice_room_name_removed_by_you") }
  /// %1$@ rejected the invitation
  public static func noticeRoomReject(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_reject", String(describing: p1))
  }
  /// You rejected the invitation
  public static var noticeRoomRejectByYou: String { return ElementL10n.tr("Localizable", "notice_room_reject_by_you") }
  /// %1$@ rejected the invitation. Reason: %2$@
  public static func noticeRoomRejectWithReason(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_reject_with_reason", String(describing: p1), String(describing: p2))
  }
  /// You rejected the invitation. Reason: %1$@
  public static func noticeRoomRejectWithReasonByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_reject_with_reason_by_you", String(describing: p1))
  }
  /// %1$@ removed %2$@
  public static func noticeRoomRemove(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_remove", String(describing: p1), String(describing: p2))
  }
  /// You removed %1$@
  public static func noticeRoomRemoveByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_remove_by_you", String(describing: p1))
  }
  /// %1$@ removed %2$@. Reason: %3$@
  public static func noticeRoomRemoveWithReason(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_remove_with_reason", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// You removed %1$@. Reason: %2$@
  public static func noticeRoomRemoveWithReasonByYou(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_remove_with_reason_by_you", String(describing: p1), String(describing: p2))
  }
  /// 🎉 All servers are banned from participating! This room can no longer be used.
  public static var noticeRoomServerAclAllowIsEmpty: String { return ElementL10n.tr("Localizable", "notice_room_server_acl_allow_is_empty") }
  /// Plural format key: "%#@VARIABLE@"
  public static func noticeRoomServerAclChanges(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notice_room_server_acl_changes", p1)
  }
  /// • Servers matching %@ are allowed.
  public static func noticeRoomServerAclSetAllowed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_server_acl_set_allowed", String(describing: p1))
  }
  /// • Servers matching %@ are banned.
  public static func noticeRoomServerAclSetBanned(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_server_acl_set_banned", String(describing: p1))
  }
  /// • Servers matching IP literals are allowed.
  public static var noticeRoomServerAclSetIpLiteralsAllowed: String { return ElementL10n.tr("Localizable", "notice_room_server_acl_set_ip_literals_allowed") }
  /// • Servers matching IP literals are banned.
  public static var noticeRoomServerAclSetIpLiteralsNotAllowed: String { return ElementL10n.tr("Localizable", "notice_room_server_acl_set_ip_literals_not_allowed") }
  /// %@ set the server ACLs for this room.
  public static func noticeRoomServerAclSetTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_server_acl_set_title", String(describing: p1))
  }
  /// You set the server ACLs for this room.
  public static var noticeRoomServerAclSetTitleByYou: String { return ElementL10n.tr("Localizable", "notice_room_server_acl_set_title_by_you") }
  /// • Servers matching %@ are now allowed.
  public static func noticeRoomServerAclUpdatedAllowed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_server_acl_updated_allowed", String(describing: p1))
  }
  /// • Servers matching %@ are now banned.
  public static func noticeRoomServerAclUpdatedBanned(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_server_acl_updated_banned", String(describing: p1))
  }
  /// • Servers matching IP literals are now allowed.
  public static var noticeRoomServerAclUpdatedIpLiteralsAllowed: String { return ElementL10n.tr("Localizable", "notice_room_server_acl_updated_ip_literals_allowed") }
  /// • Servers matching IP literals are now banned.
  public static var noticeRoomServerAclUpdatedIpLiteralsNotAllowed: String { return ElementL10n.tr("Localizable", "notice_room_server_acl_updated_ip_literals_not_allowed") }
  /// No change.
  public static var noticeRoomServerAclUpdatedNoChange: String { return ElementL10n.tr("Localizable", "notice_room_server_acl_updated_no_change") }
  /// %@ changed the server ACLs for this room.
  public static func noticeRoomServerAclUpdatedTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_server_acl_updated_title", String(describing: p1))
  }
  /// You changed the server ACLs for this room.
  public static var noticeRoomServerAclUpdatedTitleByYou: String { return ElementL10n.tr("Localizable", "notice_room_server_acl_updated_title_by_you") }
  /// • Servers matching %@ were removed from the allowed list.
  public static func noticeRoomServerAclUpdatedWasAllowed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_server_acl_updated_was_allowed", String(describing: p1))
  }
  /// • Servers matching %@ were removed from the ban list.
  public static func noticeRoomServerAclUpdatedWasBanned(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_server_acl_updated_was_banned", String(describing: p1))
  }
  /// %1$@ sent an invitation to %2$@ to join the room
  public static func noticeRoomThirdPartyInvite(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_third_party_invite", String(describing: p1), String(describing: p2))
  }
  /// You sent an invitation to %1$@ to join the room
  public static func noticeRoomThirdPartyInviteByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_third_party_invite_by_you", String(describing: p1))
  }
  /// %1$@ accepted the invitation for %2$@
  public static func noticeRoomThirdPartyRegisteredInvite(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_third_party_registered_invite", String(describing: p1), String(describing: p2))
  }
  /// You accepted the invitation for %1$@
  public static func noticeRoomThirdPartyRegisteredInviteByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_third_party_registered_invite_by_you", String(describing: p1))
  }
  /// %1$@ accepted the invitation for %2$@. Reason: %3$@
  public static func noticeRoomThirdPartyRegisteredInviteWithReason(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_third_party_registered_invite_with_reason", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// You accepted the invitation for %1$@. Reason: %2$@
  public static func noticeRoomThirdPartyRegisteredInviteWithReasonByYou(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_third_party_registered_invite_with_reason_by_you", String(describing: p1), String(describing: p2))
  }
  /// %1$@ revoked the invitation for %2$@ to join the room
  public static func noticeRoomThirdPartyRevokedInvite(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_third_party_revoked_invite", String(describing: p1), String(describing: p2))
  }
  /// You revoked the invitation for %1$@ to join the room
  public static func noticeRoomThirdPartyRevokedInviteByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_third_party_revoked_invite_by_you", String(describing: p1))
  }
  /// %1$@ changed the topic to: %2$@
  public static func noticeRoomTopicChanged(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_topic_changed", String(describing: p1), String(describing: p2))
  }
  /// You changed the topic to: %1$@
  public static func noticeRoomTopicChangedByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_topic_changed_by_you", String(describing: p1))
  }
  /// %1$@ removed the room topic
  public static func noticeRoomTopicRemoved(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_topic_removed", String(describing: p1))
  }
  /// You removed the room topic
  public static var noticeRoomTopicRemovedByYou: String { return ElementL10n.tr("Localizable", "notice_room_topic_removed_by_you") }
  /// %1$@ unbanned %2$@
  public static func noticeRoomUnban(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_unban", String(describing: p1), String(describing: p2))
  }
  /// You unbanned %1$@
  public static func noticeRoomUnbanByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_unban_by_you", String(describing: p1))
  }
  /// %1$@ unbanned %2$@. Reason: %3$@
  public static func noticeRoomUnbanWithReason(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_unban_with_reason", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// You unbanned %1$@. Reason: %2$@
  public static func noticeRoomUnbanWithReasonByYou(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_unban_with_reason_by_you", String(describing: p1), String(describing: p2))
  }
  /// %@ upgraded this room.
  public static func noticeRoomUpdate(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_update", String(describing: p1))
  }
  /// You upgraded this room.
  public static var noticeRoomUpdateByYou: String { return ElementL10n.tr("Localizable", "notice_room_update_by_you") }
  /// all room members, from the point they are invited.
  public static var noticeRoomVisibilityInvited: String { return ElementL10n.tr("Localizable", "notice_room_visibility_invited") }
  /// all room members, from the point they joined.
  public static var noticeRoomVisibilityJoined: String { return ElementL10n.tr("Localizable", "notice_room_visibility_joined") }
  /// all room members.
  public static var noticeRoomVisibilityShared: String { return ElementL10n.tr("Localizable", "notice_room_visibility_shared") }
  /// anyone.
  public static var noticeRoomVisibilityWorldReadable: String { return ElementL10n.tr("Localizable", "notice_room_visibility_world_readable") }
  /// %1$@ withdrew %2$@'s invitation
  public static func noticeRoomWithdraw(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_withdraw", String(describing: p1), String(describing: p2))
  }
  /// You withdrew %1$@'s invitation
  public static func noticeRoomWithdrawByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_withdraw_by_you", String(describing: p1))
  }
  /// %1$@ withdrew %2$@'s invitation. Reason: %3$@
  public static func noticeRoomWithdrawWithReason(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_withdraw_with_reason", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// You withdrew %1$@'s invitation. Reason: %2$@
  public static func noticeRoomWithdrawWithReasonByYou(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_room_withdraw_with_reason_by_you", String(describing: p1), String(describing: p2))
  }
  /// %1$@ added %2$@ widget
  public static func noticeWidgetAdded(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_widget_added", String(describing: p1), String(describing: p2))
  }
  /// You added %1$@ widget
  public static func noticeWidgetAddedByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_widget_added_by_you", String(describing: p1))
  }
  /// %1$@ modified %2$@ widget
  public static func noticeWidgetModified(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_widget_modified", String(describing: p1), String(describing: p2))
  }
  /// You modified %1$@ widget
  public static func noticeWidgetModifiedByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_widget_modified_by_you", String(describing: p1))
  }
  /// %1$@ removed %2$@ widget
  public static func noticeWidgetRemoved(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_widget_removed", String(describing: p1), String(describing: p2))
  }
  /// You removed %1$@ widget
  public static func noticeWidgetRemovedByYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "notice_widget_removed_by_you", String(describing: p1))
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func notificationCompatSummaryLineForRoom(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notification_compat_summary_line_for_room", p1)
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func notificationCompatSummaryTitle(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notification_compat_summary_title", p1)
  }
  /// Initial Sync…
  public static var notificationInitialSync: String { return ElementL10n.tr("Localizable", "notification_initial_sync") }
  /// ** Failed to send - please open room
  public static var notificationInlineReplyFailed: String { return ElementL10n.tr("Localizable", "notification_inline_reply_failed") }
  /// Plural format key: "%#@VARIABLE@"
  public static func notificationInvitations(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notification_invitations", p1)
  }
  /// Listening for events
  public static var notificationListeningForEvents: String { return ElementL10n.tr("Localizable", "notification_listening_for_events") }
  /// Listening for notifications
  public static var notificationListeningForNotifications: String { return ElementL10n.tr("Localizable", "notification_listening_for_notifications") }
  /// New Invitation
  public static var notificationNewInvitation: String { return ElementL10n.tr("Localizable", "notification_new_invitation") }
  /// New Messages
  public static var notificationNewMessages: String { return ElementL10n.tr("Localizable", "notification_new_messages") }
  /// Noisy
  public static var notificationNoisy: String { return ElementL10n.tr("Localizable", "notification_noisy") }
  /// Noisy notifications
  public static var notificationNoisyNotifications: String { return ElementL10n.tr("Localizable", "notification_noisy_notifications") }
  /// Off
  public static var notificationOff: String { return ElementL10n.tr("Localizable", "notification_off") }
  /// Me
  public static var notificationSenderMe: String { return ElementL10n.tr("Localizable", "notification_sender_me") }
  /// Silent
  public static var notificationSilent: String { return ElementL10n.tr("Localizable", "notification_silent") }
  /// Silent notifications
  public static var notificationSilentNotifications: String { return ElementL10n.tr("Localizable", "notification_silent_notifications") }
  /// %1$@: %2$@
  public static func notificationTickerTextDm(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notification_ticker_text_dm", String(describing: p1), String(describing: p2))
  }
  /// %1$@: %2$@ %3$@
  public static func notificationTickerTextGroup(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "notification_ticker_text_group", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// New Event
  public static var notificationUnknownNewEvent: String { return ElementL10n.tr("Localizable", "notification_unknown_new_event") }
  /// Room
  public static var notificationUnknownRoomName: String { return ElementL10n.tr("Localizable", "notification_unknown_room_name") }
  /// Plural format key: "%#@VARIABLE@"
  public static func notificationUnreadNotifiedMessages(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notification_unread_notified_messages", p1)
  }
  /// %1$@ and %2$@
  public static func notificationUnreadNotifiedMessagesAndInvitation(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notification_unread_notified_messages_and_invitation", String(describing: p1), String(describing: p2))
  }
  /// %1$@ in %2$@
  public static func notificationUnreadNotifiedMessagesInRoom(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "notification_unread_notified_messages_in_room", String(describing: p1), String(describing: p2))
  }
  /// %1$@ in %2$@ and %3$@
  public static func notificationUnreadNotifiedMessagesInRoomAndInvitation(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "notification_unread_notified_messages_in_room_and_invitation", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func notificationUnreadNotifiedMessagesInRoomRooms(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "notification_unread_notified_messages_in_room_rooms", p1)
  }
  /// OK
  public static var ok: String { return ElementL10n.tr("Localizable", "ok") }
  /// Try it out
  public static var onboardingNewAppLayoutButtonTry: String { return ElementL10n.tr("Localizable", "onboarding_new_app_layout_button_try") }
  /// Tap top right to see the option to feedback.
  public static var onboardingNewAppLayoutFeedbackMessage: String { return ElementL10n.tr("Localizable", "onboarding_new_app_layout_feedback_message") }
  /// Give Feedback
  public static var onboardingNewAppLayoutFeedbackTitle: String { return ElementL10n.tr("Localizable", "onboarding_new_app_layout_feedback_title") }
  /// Access your Spaces (bottom-right) faster and easier than ever before.
  public static var onboardingNewAppLayoutSpacesMessage: String { return ElementL10n.tr("Localizable", "onboarding_new_app_layout_spaces_message") }
  /// Access Spaces
  public static var onboardingNewAppLayoutSpacesTitle: String { return ElementL10n.tr("Localizable", "onboarding_new_app_layout_spaces_title") }
  /// To simplify your %@, tabs are now optional. Manage them using the top-right menu.
  public static func onboardingNewAppLayoutWelcomeMessage(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "onboarding_new_app_layout_welcome_message", String(describing: p1))
  }
  /// Welcome to a new view!
  public static var onboardingNewAppLayoutWelcomeTitle: String { return ElementL10n.tr("Localizable", "onboarding_new_app_layout_welcome_title") }
  /// %@ read
  public static func oneUserRead(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "one_user_read", String(describing: p1))
  }
  /// Open Discovery Settings
  public static var openDiscoverySettings: String { return ElementL10n.tr("Localizable", "open_discovery_settings") }
  /// Voters see results as soon as they have voted
  public static var openPollOptionDescription: String { return ElementL10n.tr("Localizable", "open_poll_option_description") }
  /// Open poll
  public static var openPollOptionTitle: String { return ElementL10n.tr("Localizable", "open_poll_option_title") }
  /// Open Settings
  public static var openSettings: String { return ElementL10n.tr("Localizable", "open_settings") }
  /// Open terms of %@
  public static func openTermsOf(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "open_terms_of", String(describing: p1))
  }
  /// Always ask
  public static var optionAlwaysAsk: String { return ElementL10n.tr("Localizable", "option_always_ask") }
  /// Send files
  public static var optionSendFiles: String { return ElementL10n.tr("Localizable", "option_send_files") }
  /// Send sticker
  public static var optionSendSticker: String { return ElementL10n.tr("Localizable", "option_send_sticker") }
  /// Send voice
  public static var optionSendVoice: String { return ElementL10n.tr("Localizable", "option_send_voice") }
  /// Take photo
  public static var optionTakePhoto: String { return ElementL10n.tr("Localizable", "option_take_photo") }
  /// Take photo or video
  public static var optionTakePhotoVideo: String { return ElementL10n.tr("Localizable", "option_take_photo_video") }
  /// Take video
  public static var optionTakeVideo: String { return ElementL10n.tr("Localizable", "option_take_video") }
  /// or
  public static var or: String { return ElementL10n.tr("Localizable", "or") }
  /// or another cross-signing capable Matrix client
  public static var orOtherMxCapableClient: String { return ElementL10n.tr("Localizable", "or_other_mx_capable_client") }
  /// Other spaces or rooms you might not know
  public static var otherSpacesOrRoomsYouMightNotKnow: String { return ElementL10n.tr("Localizable", "other_spaces_or_rooms_you_might_not_know") }
  /// Confirm passphrase
  public static var passphraseConfirmPassphrase: String { return ElementL10n.tr("Localizable", "passphrase_confirm_passphrase") }
  /// Create passphrase
  public static var passphraseCreatePassphrase: String { return ElementL10n.tr("Localizable", "passphrase_create_passphrase") }
  /// Please enter a passphrase
  public static var passphraseEmptyErrorMessage: String { return ElementL10n.tr("Localizable", "passphrase_empty_error_message") }
  /// Enter passphrase
  public static var passphraseEnterPassphrase: String { return ElementL10n.tr("Localizable", "passphrase_enter_passphrase") }
  /// Passphrase doesn’t match
  public static var passphrasePassphraseDoesNotMatch: String { return ElementL10n.tr("Localizable", "passphrase_passphrase_does_not_match") }
  /// Passphrase is too weak
  public static var passphrasePassphraseTooWeak: String { return ElementL10n.tr("Localizable", "passphrase_passphrase_too_weak") }
  /// Permalink
  public static var permalink: String { return ElementL10n.tr("Localizable", "permalink") }
  /// Your matrix.to link was malformed
  public static var permalinkMalformed: String { return ElementL10n.tr("Localizable", "permalink_malformed") }
  /// Cannot open this link: communities have been replaced by spaces
  public static var permalinkUnsupportedGroups: String { return ElementL10n.tr("Localizable", "permalink_unsupported_groups") }
  /// Allow permission to access your contacts.
  public static var permissionsDeniedAddContact: String { return ElementL10n.tr("Localizable", "permissions_denied_add_contact") }
  /// To scan a QR code, you need to allow camera access.
  public static var permissionsDeniedQrCode: String { return ElementL10n.tr("Localizable", "permissions_denied_qr_code") }
  /// %@ needs permission to access your camera and your microphone to perform video calls.
  /// 
  /// Please allow access on the next pop-ups to be able to make the call.
  public static func permissionsRationaleMsgCameraAndAudio(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "permissions_rationale_msg_camera_and_audio", String(describing: p1))
  }
  /// %@ needs permission to access your microphone to perform audio calls.
  public static func permissionsRationaleMsgRecordAudio(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "permissions_rationale_msg_record_audio", String(describing: p1))
  }
  /// Information
  public static var permissionsRationalePopupTitle: String { return ElementL10n.tr("Localizable", "permissions_rationale_popup_title") }
  /// Search for contacts on Matrix
  public static var phoneBookPerformLookup: String { return ElementL10n.tr("Localizable", "phone_book_perform_lookup") }
  /// Please wait…
  public static var pleaseWait: String { return ElementL10n.tr("Localizable", "please_wait") }
  /// End poll
  public static var pollEndAction: String { return ElementL10n.tr("Localizable", "poll_end_action") }
  /// Poll ended
  public static var pollEndRoomListPreview: String { return ElementL10n.tr("Localizable", "poll_end_room_list_preview") }
  /// No votes cast
  public static var pollNoVotesCast: String { return ElementL10n.tr("Localizable", "poll_no_votes_cast") }
  /// Plural format key: "%#@VARIABLE@"
  public static func pollOptionVoteCount(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "poll_option_vote_count", p1)
  }
  /// Vote cast
  public static var pollResponseRoomListPreview: String { return ElementL10n.tr("Localizable", "poll_response_room_list_preview") }
  /// Plural format key: "%#@VARIABLE@"
  public static func pollTotalVoteCountAfterEnded(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "poll_total_vote_count_after_ended", p1)
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func pollTotalVoteCountBeforeEndedAndNotVoted(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "poll_total_vote_count_before_ended_and_not_voted", p1)
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func pollTotalVoteCountBeforeEndedAndVoted(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "poll_total_vote_count_before_ended_and_voted", p1)
  }
  /// Poll type
  public static var pollTypeTitle: String { return ElementL10n.tr("Localizable", "poll_type_title") }
  /// Results will be visible when the poll is ended
  public static var pollUndisclosedNotEnded: String { return ElementL10n.tr("Localizable", "poll_undisclosed_not_ended") }
  /// Admin
  public static var powerLevelAdmin: String { return ElementL10n.tr("Localizable", "power_level_admin") }
  /// Custom (%1$d)
  public static func powerLevelCustom(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "power_level_custom", p1)
  }
  /// Custom
  public static var powerLevelCustomNoValue: String { return ElementL10n.tr("Localizable", "power_level_custom_no_value") }
  /// Default
  public static var powerLevelDefault: String { return ElementL10n.tr("Localizable", "power_level_default") }
  /// Set role
  public static var powerLevelEditTitle: String { return ElementL10n.tr("Localizable", "power_level_edit_title") }
  /// Moderator
  public static var powerLevelModerator: String { return ElementL10n.tr("Localizable", "power_level_moderator") }
  /// Role
  public static var powerLevelTitle: String { return ElementL10n.tr("Localizable", "power_level_title") }
  /// Help
  public static var preferenceHelp: String { return ElementL10n.tr("Localizable", "preference_help") }
  /// Get help with using %@
  public static func preferenceHelpSummary(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "preference_help_summary", String(describing: p1))
  }
  /// Help and support
  public static var preferenceHelpTitle: String { return ElementL10n.tr("Localizable", "preference_help_title") }
  /// Help & About
  public static var preferenceRootHelpAbout: String { return ElementL10n.tr("Localizable", "preference_root_help_about") }
  /// Legals
  public static var preferenceRootLegals: String { return ElementL10n.tr("Localizable", "preference_root_legals") }
  /// Show all rooms in Home
  public static var preferenceShowAllRoomsInHome: String { return ElementL10n.tr("Localizable", "preference_show_all_rooms_in_home") }
  /// System settings
  public static var preferenceSystemSettings: String { return ElementL10n.tr("Localizable", "preference_system_settings") }
  /// Versions
  public static var preferenceVersions: String { return ElementL10n.tr("Localizable", "preference_versions") }
  /// Voice & Video
  public static var preferenceVoiceAndVideo: String { return ElementL10n.tr("Localizable", "preference_voice_and_video") }
  /// Private space
  public static var privateSpace: String { return ElementL10n.tr("Localizable", "private_space") }
  /// Public space
  public static var publicSpace: String { return ElementL10n.tr("Localizable", "public_space") }
  /// app_display_name:
  public static var pushGatewayItemAppDisplayName: String { return ElementL10n.tr("Localizable", "push_gateway_item_app_display_name") }
  /// app_id:
  public static var pushGatewayItemAppId: String { return ElementL10n.tr("Localizable", "push_gateway_item_app_id") }
  /// session_name:
  public static var pushGatewayItemDeviceName: String { return ElementL10n.tr("Localizable", "push_gateway_item_device_name") }
  /// Format:
  public static var pushGatewayItemFormat: String { return ElementL10n.tr("Localizable", "push_gateway_item_format") }
  /// Profile tag:
  public static var pushGatewayItemProfileTag: String { return ElementL10n.tr("Localizable", "push_gateway_item_profile_tag") }
  /// push_key:
  public static var pushGatewayItemPushKey: String { return ElementL10n.tr("Localizable", "push_gateway_item_push_key") }
  /// Url:
  public static var pushGatewayItemUrl: String { return ElementL10n.tr("Localizable", "push_gateway_item_url") }
  /// QR code
  public static var qrCode: String { return ElementL10n.tr("Localizable", "qr_code") }
  /// QR code not scanned!
  public static var qrCodeNotScanned: String { return ElementL10n.tr("Localizable", "qr_code_not_scanned") }
  /// No
  public static var qrCodeScannedByOtherNo: String { return ElementL10n.tr("Localizable", "qr_code_scanned_by_other_no") }
  /// Almost there! Is %@ showing a tick?
  public static func qrCodeScannedByOtherNotice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "qr_code_scanned_by_other_notice", String(describing: p1))
  }
  /// Yes
  public static var qrCodeScannedByOtherYes: String { return ElementL10n.tr("Localizable", "qr_code_scanned_by_other_yes") }
  /// Almost there! Is the other device showing a tick?
  public static var qrCodeScannedSelfVerifNotice: String { return ElementL10n.tr("Localizable", "qr_code_scanned_self_verif_notice") }
  /// Waiting for %@…
  public static func qrCodeScannedVerifWaiting(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "qr_code_scanned_verif_waiting", String(describing: p1))
  }
  /// Almost there! Waiting for confirmation…
  public static var qrCodeScannedVerifWaitingNotice: String { return ElementL10n.tr("Localizable", "qr_code_scanned_verif_waiting_notice") }
  /// Shake detected!
  public static var rageshakeDetected: String { return ElementL10n.tr("Localizable", "rageshake_detected") }
  /// Re-Authentication Needed
  public static var reAuthenticationActivityTitle: String { return ElementL10n.tr("Localizable", "re_authentication_activity_title") }
  /// %@ requires you to enter your credentials to perform this action.
  public static func reAuthenticationDefaultConfirmText(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "re_authentication_default_confirm_text", String(describing: p1))
  }
  /// Type keywords to find a reaction.
  public static var reactionSearchTypeHint: String { return ElementL10n.tr("Localizable", "reaction_search_type_hint") }
  /// Reactions
  public static var reactions: String { return ElementL10n.tr("Localizable", "reactions") }
  /// Reason: %1$@
  public static func reasonColon(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "reason_colon", String(describing: p1))
  }
  /// Recovery Key
  public static var recoveryKey: String { return ElementL10n.tr("Localizable", "recovery_key") }
  /// Please enter a recovery key
  public static var recoveryKeyEmptyErrorMessage: String { return ElementL10n.tr("Localizable", "recovery_key_empty_error_message") }
  /// The recovery key has been saved.
  public static var recoveryKeyExportSaved: String { return ElementL10n.tr("Localizable", "recovery_key_export_saved") }
  /// Recovery Passphrase
  public static var recoveryPassphrase: String { return ElementL10n.tr("Localizable", "recovery_passphrase") }
  /// Refresh
  public static var refresh: String { return ElementL10n.tr("Localizable", "refresh") }
  /// %@ encountered an issue when rendering content of event with id '%1$@'
  public static func renderingEventErrorException(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "rendering_event_error_exception", String(describing: p1))
  }
  /// %@ does not handle events of type '%1$@'
  public static func renderingEventErrorTypeOfEventNotHandled(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "rendering_event_error_type_of_event_not_handled", String(describing: p1))
  }
  /// Reply
  public static var reply: String { return ElementL10n.tr("Localizable", "reply") }
  /// Reply in thread
  public static var replyInThread: String { return ElementL10n.tr("Localizable", "reply_in_thread") }
  /// Report Content
  public static var reportContent: String { return ElementL10n.tr("Localizable", "report_content") }
  /// Custom report…
  public static var reportContentCustom: String { return ElementL10n.tr("Localizable", "report_content_custom") }
  /// Reason for reporting this content
  public static var reportContentCustomHint: String { return ElementL10n.tr("Localizable", "report_content_custom_hint") }
  /// REPORT
  public static var reportContentCustomSubmit: String { return ElementL10n.tr("Localizable", "report_content_custom_submit") }
  /// Report this content
  public static var reportContentCustomTitle: String { return ElementL10n.tr("Localizable", "report_content_custom_title") }
  /// It's inappropriate
  public static var reportContentInappropriate: String { return ElementL10n.tr("Localizable", "report_content_inappropriate") }
  /// It's spam
  public static var reportContentSpam: String { return ElementL10n.tr("Localizable", "report_content_spam") }
  /// Reset Keys
  public static var resetCrossSigning: String { return ElementL10n.tr("Localizable", "reset_cross_signing") }
  /// Generate a new Security Key or set a new Security Phrase for your existing backup.
  public static var resetSecureBackupTitle: String { return ElementL10n.tr("Localizable", "reset_secure_backup_title") }
  /// This will replace your current Key or Phrase.
  public static var resetSecureBackupWarning: String { return ElementL10n.tr("Localizable", "reset_secure_backup_warning") }
  /// contact your service administrator
  public static var resourceLimitContactAdmin: String { return ElementL10n.tr("Localizable", "resource_limit_contact_admin") }
  /// Please %@ to continue using this service.
  public static func resourceLimitHardContact(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "resource_limit_hard_contact", String(describing: p1))
  }
  /// This homeserver has exceeded one of its resource limits.
  public static var resourceLimitHardDefault: String { return ElementL10n.tr("Localizable", "resource_limit_hard_default") }
  /// This homeserver has hit its Monthly Active User limit.
  public static var resourceLimitHardMau: String { return ElementL10n.tr("Localizable", "resource_limit_hard_mau") }
  /// Please %@ to get this limit increased.
  public static func resourceLimitSoftContact(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "resource_limit_soft_contact", String(describing: p1))
  }
  /// This homeserver has exceeded one of its resource limits so <b>some users will not be able to log in</b>.
  public static var resourceLimitSoftDefault: String { return ElementL10n.tr("Localizable", "resource_limit_soft_default") }
  /// This homeserver has hit its Monthly Active User limit so <b>some users will not be able to log in</b>.
  public static var resourceLimitSoftMau: String { return ElementL10n.tr("Localizable", "resource_limit_soft_mau") }
  /// Restart the application for the change to take effect.
  public static var restartTheApplicationToApplyChanges: String { return ElementL10n.tr("Localizable", "restart_the_application_to_apply_changes") }
  /// Review where you’re logged in
  public static var reviewLogins: String { return ElementL10n.tr("Localizable", "review_logins") }
  /// Add Matrix apps
  public static var roomAddMatrixApps: String { return ElementL10n.tr("Localizable", "room_add_matrix_apps") }
  /// Publish this address
  public static var roomAliasActionPublish: String { return ElementL10n.tr("Localizable", "room_alias_action_publish") }
  /// Unpublish this address
  public static var roomAliasActionUnpublish: String { return ElementL10n.tr("Localizable", "room_alias_action_unpublish") }
  /// No other published addresses yet.
  public static var roomAliasAddressEmpty: String { return ElementL10n.tr("Localizable", "room_alias_address_empty") }
  /// No other published addresses yet, add one below.
  public static var roomAliasAddressEmptyCanAdd: String { return ElementL10n.tr("Localizable", "room_alias_address_empty_can_add") }
  /// New published address (e.g. #alias:server)
  public static var roomAliasAddressHint: String { return ElementL10n.tr("Localizable", "room_alias_address_hint") }
  /// Delete the address "%1$@"?
  public static func roomAliasDeleteConfirmation(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_alias_delete_confirmation", String(describing: p1))
  }
  /// Add a local address
  public static var roomAliasLocalAddressAdd: String { return ElementL10n.tr("Localizable", "room_alias_local_address_add") }
  /// This room has no local addresses
  public static var roomAliasLocalAddressEmpty: String { return ElementL10n.tr("Localizable", "room_alias_local_address_empty") }
  /// Set addresses for this room so users can find this room through your homeserver (%1$@)
  public static func roomAliasLocalAddressSubtitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_alias_local_address_subtitle", String(describing: p1))
  }
  /// Local Addresses
  public static var roomAliasLocalAddressTitle: String { return ElementL10n.tr("Localizable", "room_alias_local_address_title") }
  /// This alias is not accessible at this time.
  /// Try again later, or ask a room admin to check if you have access.
  public static var roomAliasPreviewNotFound: String { return ElementL10n.tr("Localizable", "room_alias_preview_not_found") }
  /// Publish this room to the public in %1$@'s room directory?
  public static func roomAliasPublishToDirectory(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_alias_publish_to_directory", String(describing: p1))
  }
  /// Unable to retrieve the current room directory visibility (%1$@).
  public static func roomAliasPublishToDirectoryError(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_alias_publish_to_directory_error", String(describing: p1))
  }
  /// Publish a new address manually
  public static var roomAliasPublishedAliasAddManually: String { return ElementL10n.tr("Localizable", "room_alias_published_alias_add_manually") }
  /// Publish
  public static var roomAliasPublishedAliasAddManuallySubmit: String { return ElementL10n.tr("Localizable", "room_alias_published_alias_add_manually_submit") }
  /// This is the main address
  public static var roomAliasPublishedAliasMain: String { return ElementL10n.tr("Localizable", "room_alias_published_alias_main") }
  /// Published addresses can be used by anyone on any server to join your room. To publish an address, it needs to be set as a local address first.
  public static var roomAliasPublishedAliasSubtitle: String { return ElementL10n.tr("Localizable", "room_alias_published_alias_subtitle") }
  /// Published Addresses
  public static var roomAliasPublishedAliasTitle: String { return ElementL10n.tr("Localizable", "room_alias_published_alias_title") }
  /// Other published addresses:
  public static var roomAliasPublishedOther: String { return ElementL10n.tr("Localizable", "room_alias_published_other") }
  /// Unpublish the address "%1$@"?
  public static func roomAliasUnpublishConfirmation(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_alias_unpublish_confirmation", String(describing: p1))
  }
  /// Members of Space %@ can find, preview and join.
  public static func roomCreateMemberOfSpaceNameCanJoin(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_create_member_of_space_name_can_join", String(describing: p1))
  }
  /// %@ created and configured the room.
  public static func roomCreatedSummaryItem(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_created_summary_item", String(describing: p1))
  }
  /// You created and configured the room.
  public static var roomCreatedSummaryItemByYou: String { return ElementL10n.tr("Localizable", "room_created_summary_item_by_you") }
  /// %@ to let people know what this room is about.
  public static func roomCreatedSummaryNoTopicCreationText(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_created_summary_no_topic_creation_text", String(describing: p1))
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func roomDetailsSelected(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "room_details_selected", p1)
  }
  /// Name or ID (#example:matrix.org)
  public static var roomDirectorySearchHint: String { return ElementL10n.tr("Localizable", "room_directory_search_hint") }
  /// %1$@, %2$@ and %3$@
  public static func roomDisplayname3Members(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "room_displayname_3_members", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// %1$@, %2$@, %3$@ and %4$@
  public static func roomDisplayname4Members(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any) -> String {
    return ElementL10n.tr("Localizable", "room_displayname_4_members", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4))
  }
  /// Empty room
  public static var roomDisplaynameEmptyRoom: String { return ElementL10n.tr("Localizable", "room_displayname_empty_room") }
  /// Empty room (was %@)
  public static func roomDisplaynameEmptyRoomWas(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_displayname_empty_room_was", String(describing: p1))
  }
  /// Plural format key: "%#@VARIABLE@"
  public static func roomDisplaynameFourAndMoreMembers(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "room_displayname_four_and_more_members", p1)
  }
  /// Room Invite
  public static var roomDisplaynameRoomInvite: String { return ElementL10n.tr("Localizable", "room_displayname_room_invite") }
  /// %1$@ and %2$@
  public static func roomDisplaynameTwoMembers(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "room_displayname_two_members", String(describing: p1), String(describing: p2))
  }
  /// You do not have permission to post to this room.
  public static var roomDoNotHavePermissionToPost: String { return ElementL10n.tr("Localizable", "room_do_not_have_permission_to_post") }
  /// You are not allowed to join this room
  public static var roomErrorAccessUnauthorized: String { return ElementL10n.tr("Localizable", "room_error_access_unauthorized") }
  /// Can't find this room. Make sure it exists.
  public static var roomErrorNotFound: String { return ElementL10n.tr("Localizable", "room_error_not_found") }
  /// Filter conversations…
  public static var roomFilteringFilterHint: String { return ElementL10n.tr("Localizable", "room_filtering_filter_hint") }
  /// Send a new direct message
  public static var roomFilteringFooterCreateNewDirectMessage: String { return ElementL10n.tr("Localizable", "room_filtering_footer_create_new_direct_message") }
  /// Create a new room
  public static var roomFilteringFooterCreateNewRoom: String { return ElementL10n.tr("Localizable", "room_filtering_footer_create_new_room") }
  /// View the room directory
  public static var roomFilteringFooterOpenRoomDirectory: String { return ElementL10n.tr("Localizable", "room_filtering_footer_open_room_directory") }
  /// Can’t find what you’re looking for?
  public static var roomFilteringFooterTitle: String { return ElementL10n.tr("Localizable", "room_filtering_footer_title") }
  /// %1$@ made the room invite only.
  public static func roomJoinRulesInvite(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_join_rules_invite", String(describing: p1))
  }
  /// You made the room invite only.
  public static var roomJoinRulesInviteByYou: String { return ElementL10n.tr("Localizable", "room_join_rules_invite_by_you") }
  /// %1$@ made the room public to whoever knows the link.
  public static func roomJoinRulesPublic(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_join_rules_public", String(describing: p1))
  }
  /// You made the room public to whoever knows the link.
  public static var roomJoinRulesPublicByYou: String { return ElementL10n.tr("Localizable", "room_join_rules_public_by_you") }
  /// Jump to unread
  public static var roomJumpToFirstUnread: String { return ElementL10n.tr("Localizable", "room_jump_to_first_unread") }
  /// You have no more unread messages
  public static var roomListCatchupEmptyBody: String { return ElementL10n.tr("Localizable", "room_list_catchup_empty_body") }
  /// You’re all caught up!
  public static var roomListCatchupEmptyTitle: String { return ElementL10n.tr("Localizable", "room_list_catchup_empty_title") }
  /// All
  public static var roomListFilterAll: String { return ElementL10n.tr("Localizable", "room_list_filter_all") }
  /// Favourites
  public static var roomListFilterFavourites: String { return ElementL10n.tr("Localizable", "room_list_filter_favourites") }
  /// People
  public static var roomListFilterPeople: String { return ElementL10n.tr("Localizable", "room_list_filter_people") }
  /// Unreads
  public static var roomListFilterUnreads: String { return ElementL10n.tr("Localizable", "room_list_filter_unreads") }
  /// Your direct message conversations will be displayed here. Tap the + at the bottom right to start some.
  public static var roomListPeopleEmptyBody: String { return ElementL10n.tr("Localizable", "room_list_people_empty_body") }
  /// Conversations
  public static var roomListPeopleEmptyTitle: String { return ElementL10n.tr("Localizable", "room_list_people_empty_title") }
  /// Add to favorites
  public static var roomListQuickActionsFavoriteAdd: String { return ElementL10n.tr("Localizable", "room_list_quick_actions_favorite_add") }
  /// Remove from favorites
  public static var roomListQuickActionsFavoriteRemove: String { return ElementL10n.tr("Localizable", "room_list_quick_actions_favorite_remove") }
  /// Leave the room
  public static var roomListQuickActionsLeave: String { return ElementL10n.tr("Localizable", "room_list_quick_actions_leave") }
  /// Add to low priority
  public static var roomListQuickActionsLowPriorityAdd: String { return ElementL10n.tr("Localizable", "room_list_quick_actions_low_priority_add") }
  /// Remove from low priority
  public static var roomListQuickActionsLowPriorityRemove: String { return ElementL10n.tr("Localizable", "room_list_quick_actions_low_priority_remove") }
  /// All messages
  public static var roomListQuickActionsNotificationsAll: String { return ElementL10n.tr("Localizable", "room_list_quick_actions_notifications_all") }
  /// All messages (noisy)
  public static var roomListQuickActionsNotificationsAllNoisy: String { return ElementL10n.tr("Localizable", "room_list_quick_actions_notifications_all_noisy") }
  /// Mentions only
  public static var roomListQuickActionsNotificationsMentions: String { return ElementL10n.tr("Localizable", "room_list_quick_actions_notifications_mentions") }
  /// Mute
  public static var roomListQuickActionsNotificationsMute: String { return ElementL10n.tr("Localizable", "room_list_quick_actions_notifications_mute") }
  /// Room settings
  public static var roomListQuickActionsRoomSettings: String { return ElementL10n.tr("Localizable", "room_list_quick_actions_room_settings") }
  /// Settings
  public static var roomListQuickActionsSettings: String { return ElementL10n.tr("Localizable", "room_list_quick_actions_settings") }
  /// Your rooms will be displayed here. Tap the + at the bottom right to find existing ones or start some of your own.
  public static var roomListRoomsEmptyBody: String { return ElementL10n.tr("Localizable", "room_list_rooms_empty_body") }
  /// Rooms
  public static var roomListRoomsEmptyTitle: String { return ElementL10n.tr("Localizable", "room_list_rooms_empty_title") }
  /// Manage Integrations
  public static var roomManageIntegrations: String { return ElementL10n.tr("Localizable", "room_manage_integrations") }
  /// %1$@ & %2$@ & others are typing…
  public static func roomManyUsersAreTyping(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "room_many_users_are_typing", String(describing: p1), String(describing: p2))
  }
  /// Jump to read receipt
  public static var roomMemberJumpToReadReceipt: String { return ElementL10n.tr("Localizable", "room_member_jump_to_read_receipt") }
  /// Direct message
  public static var roomMemberOpenOrCreateDm: String { return ElementL10n.tr("Localizable", "room_member_open_or_create_dm") }
  /// Override display name color
  public static var roomMemberOverrideNickColor: String { return ElementL10n.tr("Localizable", "room_member_override_nick_color") }
  /// Admin in %1$@
  public static func roomMemberPowerLevelAdminIn(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_member_power_level_admin_in", String(describing: p1))
  }
  /// Admins
  public static var roomMemberPowerLevelAdmins: String { return ElementL10n.tr("Localizable", "room_member_power_level_admins") }
  /// Custom
  public static var roomMemberPowerLevelCustom: String { return ElementL10n.tr("Localizable", "room_member_power_level_custom") }
  /// Custom (%1$d) in %2$@
  public static func roomMemberPowerLevelCustomIn(_ p1: Int, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "room_member_power_level_custom_in", p1, String(describing: p2))
  }
  /// Default in %1$@
  public static func roomMemberPowerLevelDefaultIn(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_member_power_level_default_in", String(describing: p1))
  }
  /// Invites
  public static var roomMemberPowerLevelInvites: String { return ElementL10n.tr("Localizable", "room_member_power_level_invites") }
  /// Moderator in %1$@
  public static func roomMemberPowerLevelModeratorIn(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_member_power_level_moderator_in", String(describing: p1))
  }
  /// Moderators
  public static var roomMemberPowerLevelModerators: String { return ElementL10n.tr("Localizable", "room_member_power_level_moderators") }
  /// Users
  public static var roomMemberPowerLevelUsers: String { return ElementL10n.tr("Localizable", "room_member_power_level_users") }
  /// Failed to get sessions
  public static var roomMemberProfileFailedToGetDevices: String { return ElementL10n.tr("Localizable", "room_member_profile_failed_to_get_devices") }
  /// Sessions
  public static var roomMemberProfileSessionsSectionTitle: String { return ElementL10n.tr("Localizable", "room_member_profile_sessions_section_title") }
  /// Room notification
  public static var roomMessageAutocompleteNotification: String { return ElementL10n.tr("Localizable", "room_message_autocomplete_notification") }
  /// Users
  public static var roomMessageAutocompleteUsers: String { return ElementL10n.tr("Localizable", "room_message_autocomplete_users") }
  /// Notify the whole room
  public static var roomMessageNotifyEveryone: String { return ElementL10n.tr("Localizable", "room_message_notify_everyone") }
  /// Message…
  public static var roomMessagePlaceholder: String { return ElementL10n.tr("Localizable", "room_message_placeholder") }
  /// Plural format key: "%#@VARIABLE@"
  public static func roomNewMessagesNotification(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "room_new_messages_notification", p1)
  }
  /// No active widgets
  public static var roomNoActiveWidgets: String { return ElementL10n.tr("Localizable", "room_no_active_widgets") }
  /// %1$@, %2$@ and others
  public static func roomNotificationMoreThanTwoUsersAreTyping(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "room_notification_more_than_two_users_are_typing", String(describing: p1), String(describing: p2))
  }
  /// %1$@ and %2$@
  public static func roomNotificationTwoUsersAreTyping(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "room_notification_two_users_are_typing", String(describing: p1), String(describing: p2))
  }
  /// %@ is typing…
  public static func roomOneUserIsTyping(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_one_user_is_typing", String(describing: p1))
  }
  /// Ban
  public static var roomParticipantsActionBan: String { return ElementL10n.tr("Localizable", "room_participants_action_ban") }
  /// Cancel invite
  public static var roomParticipantsActionCancelInvite: String { return ElementL10n.tr("Localizable", "room_participants_action_cancel_invite") }
  /// Are you sure you want to cancel the invite for this user?
  public static var roomParticipantsActionCancelInvitePromptMsg: String { return ElementL10n.tr("Localizable", "room_participants_action_cancel_invite_prompt_msg") }
  /// Cancel invite
  public static var roomParticipantsActionCancelInviteTitle: String { return ElementL10n.tr("Localizable", "room_participants_action_cancel_invite_title") }
  /// Ignore
  public static var roomParticipantsActionIgnore: String { return ElementL10n.tr("Localizable", "room_participants_action_ignore") }
  /// Ignoring this user will remove their messages from rooms you share.
  /// 
  /// You can reverse this action at any time in the general settings.
  public static var roomParticipantsActionIgnorePromptMsg: String { return ElementL10n.tr("Localizable", "room_participants_action_ignore_prompt_msg") }
  /// Ignore user
  public static var roomParticipantsActionIgnoreTitle: String { return ElementL10n.tr("Localizable", "room_participants_action_ignore_title") }
  /// Invite
  public static var roomParticipantsActionInvite: String { return ElementL10n.tr("Localizable", "room_participants_action_invite") }
  /// Mention
  public static var roomParticipantsActionMention: String { return ElementL10n.tr("Localizable", "room_participants_action_mention") }
  /// Remove from chat
  public static var roomParticipantsActionRemove: String { return ElementL10n.tr("Localizable", "room_participants_action_remove") }
  /// Unban
  public static var roomParticipantsActionUnban: String { return ElementL10n.tr("Localizable", "room_participants_action_unban") }
  /// Unignore
  public static var roomParticipantsActionUnignore: String { return ElementL10n.tr("Localizable", "room_participants_action_unignore") }
  /// Unignoring this user will show all messages from them again.
  public static var roomParticipantsActionUnignorePromptMsg: String { return ElementL10n.tr("Localizable", "room_participants_action_unignore_prompt_msg") }
  /// Unignore user
  public static var roomParticipantsActionUnignoreTitle: String { return ElementL10n.tr("Localizable", "room_participants_action_unignore_title") }
  /// Banning user will remove them from this room and prevent them from joining again.
  public static var roomParticipantsBanPromptMsg: String { return ElementL10n.tr("Localizable", "room_participants_ban_prompt_msg") }
  /// Reason to ban
  public static var roomParticipantsBanReason: String { return ElementL10n.tr("Localizable", "room_participants_ban_reason") }
  /// Ban user
  public static var roomParticipantsBanTitle: String { return ElementL10n.tr("Localizable", "room_participants_ban_title") }
  /// Direct Messages
  public static var roomParticipantsHeaderDirectChats: String { return ElementL10n.tr("Localizable", "room_participants_header_direct_chats") }
  /// This room is not public. You will not be able to rejoin without an invite.
  public static var roomParticipantsLeavePrivateWarning: String { return ElementL10n.tr("Localizable", "room_participants_leave_private_warning") }
  /// Are you sure you want to leave the room?
  public static var roomParticipantsLeavePromptMsg: String { return ElementL10n.tr("Localizable", "room_participants_leave_prompt_msg") }
  /// Leave room
  public static var roomParticipantsLeavePromptTitle: String { return ElementL10n.tr("Localizable", "room_participants_leave_prompt_title") }
  /// Demote
  public static var roomParticipantsPowerLevelDemote: String { return ElementL10n.tr("Localizable", "room_participants_power_level_demote") }
  /// You will not be able to undo this change as you are demoting yourself, if you are the last privileged user in the room it will be impossible to regain privileges.
  public static var roomParticipantsPowerLevelDemoteWarningPrompt: String { return ElementL10n.tr("Localizable", "room_participants_power_level_demote_warning_prompt") }
  /// Demote yourself?
  public static var roomParticipantsPowerLevelDemoteWarningTitle: String { return ElementL10n.tr("Localizable", "room_participants_power_level_demote_warning_title") }
  /// You will not be able to undo this change as you are promoting the user to have the same power level as yourself.
  /// Are you sure?
  public static var roomParticipantsPowerLevelPrompt: String { return ElementL10n.tr("Localizable", "room_participants_power_level_prompt") }
  /// The user will be removed from this room.
  /// 
  /// To prevent them from joining again, you should ban them instead.
  public static var roomParticipantsRemovePromptMsg: String { return ElementL10n.tr("Localizable", "room_participants_remove_prompt_msg") }
  /// Reason to remove
  public static var roomParticipantsRemoveReason: String { return ElementL10n.tr("Localizable", "room_participants_remove_reason") }
  /// Remove user
  public static var roomParticipantsRemoveTitle: String { return ElementL10n.tr("Localizable", "room_participants_remove_title") }
  /// Unbanning user will allow them to join the room again.
  public static var roomParticipantsUnbanPromptMsg: String { return ElementL10n.tr("Localizable", "room_participants_unban_prompt_msg") }
  /// Unban user
  public static var roomParticipantsUnbanTitle: String { return ElementL10n.tr("Localizable", "room_participants_unban_title") }
  /// Ban users
  public static var roomPermissionsBanUsers: String { return ElementL10n.tr("Localizable", "room_permissions_ban_users") }
  /// Change history visibility
  public static var roomPermissionsChangeHistoryVisibility: String { return ElementL10n.tr("Localizable", "room_permissions_change_history_visibility") }
  /// Change main address for the room
  public static var roomPermissionsChangeMainAddressForTheRoom: String { return ElementL10n.tr("Localizable", "room_permissions_change_main_address_for_the_room") }
  /// Change main address for the space
  public static var roomPermissionsChangeMainAddressForTheSpace: String { return ElementL10n.tr("Localizable", "room_permissions_change_main_address_for_the_space") }
  /// Change permissions
  public static var roomPermissionsChangePermissions: String { return ElementL10n.tr("Localizable", "room_permissions_change_permissions") }
  /// Change room avatar
  public static var roomPermissionsChangeRoomAvatar: String { return ElementL10n.tr("Localizable", "room_permissions_change_room_avatar") }
  /// Change room name
  public static var roomPermissionsChangeRoomName: String { return ElementL10n.tr("Localizable", "room_permissions_change_room_name") }
  /// Change settings
  public static var roomPermissionsChangeSettings: String { return ElementL10n.tr("Localizable", "room_permissions_change_settings") }
  /// Change space avatar
  public static var roomPermissionsChangeSpaceAvatar: String { return ElementL10n.tr("Localizable", "room_permissions_change_space_avatar") }
  /// Change space name
  public static var roomPermissionsChangeSpaceName: String { return ElementL10n.tr("Localizable", "room_permissions_change_space_name") }
  /// Change topic
  public static var roomPermissionsChangeTopic: String { return ElementL10n.tr("Localizable", "room_permissions_change_topic") }
  /// Default role
  public static var roomPermissionsDefaultRole: String { return ElementL10n.tr("Localizable", "room_permissions_default_role") }
  /// Enable room encryption
  public static var roomPermissionsEnableRoomEncryption: String { return ElementL10n.tr("Localizable", "room_permissions_enable_room_encryption") }
  /// Enable space encryption
  public static var roomPermissionsEnableSpaceEncryption: String { return ElementL10n.tr("Localizable", "room_permissions_enable_space_encryption") }
  /// Invite users
  public static var roomPermissionsInviteUsers: String { return ElementL10n.tr("Localizable", "room_permissions_invite_users") }
  /// Modify widgets
  public static var roomPermissionsModifyWidgets: String { return ElementL10n.tr("Localizable", "room_permissions_modify_widgets") }
  /// Select the roles required to change various parts of the room
  public static var roomPermissionsNotice: String { return ElementL10n.tr("Localizable", "room_permissions_notice") }
  /// You don't have permission to update the roles required to change various parts of the room
  public static var roomPermissionsNoticeReadOnly: String { return ElementL10n.tr("Localizable", "room_permissions_notice_read_only") }
  /// Notify everyone
  public static var roomPermissionsNotifyEveryone: String { return ElementL10n.tr("Localizable", "room_permissions_notify_everyone") }
  /// Remove messages sent by others
  public static var roomPermissionsRemoveMessagesSentByOthers: String { return ElementL10n.tr("Localizable", "room_permissions_remove_messages_sent_by_others") }
  /// Remove users
  public static var roomPermissionsRemoveUsers: String { return ElementL10n.tr("Localizable", "room_permissions_remove_users") }
  /// Send m.room.server_acl events
  public static var roomPermissionsSendMRoomServerAclEvents: String { return ElementL10n.tr("Localizable", "room_permissions_send_m_room_server_acl_events") }
  /// Send messages
  public static var roomPermissionsSendMessages: String { return ElementL10n.tr("Localizable", "room_permissions_send_messages") }
  /// Permissions
  public static var roomPermissionsTitle: String { return ElementL10n.tr("Localizable", "room_permissions_title") }
  /// Upgrade the room
  public static var roomPermissionsUpgradeTheRoom: String { return ElementL10n.tr("Localizable", "room_permissions_upgrade_the_room") }
  /// Upgrade the space
  public static var roomPermissionsUpgradeTheSpace: String { return ElementL10n.tr("Localizable", "room_permissions_upgrade_the_space") }
  /// This room can't be previewed
  public static var roomPreviewNoPreview: String { return ElementL10n.tr("Localizable", "room_preview_no_preview") }
  /// This room can't be previewed. Do you want to join it?
  public static var roomPreviewNoPreviewJoin: String { return ElementL10n.tr("Localizable", "room_preview_no_preview_join") }
  /// This room is not accessible at this time.
  /// Try again later, or ask a room admin to check if you have access.
  public static var roomPreviewNotFound: String { return ElementL10n.tr("Localizable", "room_preview_not_found") }
  /// Messages in this room are end-to-end encrypted.
  /// 
  /// Your messages are secured with locks and only you and the recipient have the unique keys to unlock them.
  public static var roomProfileEncryptedSubtitle: String { return ElementL10n.tr("Localizable", "room_profile_encrypted_subtitle") }
  /// Leaving the room…
  public static var roomProfileLeavingRoom: String { return ElementL10n.tr("Localizable", "room_profile_leaving_room") }
  /// Messages in this room are not end-to-end encrypted.
  public static var roomProfileNotEncryptedSubtitle: String { return ElementL10n.tr("Localizable", "room_profile_not_encrypted_subtitle") }
  /// Admin Actions
  public static var roomProfileSectionAdmin: String { return ElementL10n.tr("Localizable", "room_profile_section_admin") }
  /// More
  public static var roomProfileSectionMore: String { return ElementL10n.tr("Localizable", "room_profile_section_more") }
  /// Leave Room
  public static var roomProfileSectionMoreLeave: String { return ElementL10n.tr("Localizable", "room_profile_section_more_leave") }
  /// Plural format key: "%#@VARIABLE@"
  public static func roomProfileSectionMoreMemberList(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "room_profile_section_more_member_list", p1)
  }
  /// Notifications
  public static var roomProfileSectionMoreNotifications: String { return ElementL10n.tr("Localizable", "room_profile_section_more_notifications") }
  /// Room settings
  public static var roomProfileSectionMoreSettings: String { return ElementL10n.tr("Localizable", "room_profile_section_more_settings") }
  /// Uploads
  public static var roomProfileSectionMoreUploads: String { return ElementL10n.tr("Localizable", "room_profile_section_more_uploads") }
  /// Restore Encryption
  public static var roomProfileSectionRestoreSecurity: String { return ElementL10n.tr("Localizable", "room_profile_section_restore_security") }
  /// Security
  public static var roomProfileSectionSecurity: String { return ElementL10n.tr("Localizable", "room_profile_section_security") }
  /// Learn more
  public static var roomProfileSectionSecurityLearnMore: String { return ElementL10n.tr("Localizable", "room_profile_section_security_learn_more") }
  /// Plural format key: "%#@VARIABLE@"
  public static func roomRemovedMessages(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "room_removed_messages", p1)
  }
  /// Who can access?
  public static var roomSettingsAccessRulesPrefDialogTitle: String { return ElementL10n.tr("Localizable", "room_settings_access_rules_pref_dialog_title") }
  /// Add to Home screen
  public static var roomSettingsAddHomescreenShortcut: String { return ElementL10n.tr("Localizable", "room_settings_add_homescreen_shortcut") }
  /// See and managed addresses of this room, and its visibility in the room directory.
  public static var roomSettingsAliasSubtitle: String { return ElementL10n.tr("Localizable", "room_settings_alias_subtitle") }
  /// Room addresses
  public static var roomSettingsAliasTitle: String { return ElementL10n.tr("Localizable", "room_settings_alias_title") }
  /// All messages
  public static var roomSettingsAllMessages: String { return ElementL10n.tr("Localizable", "room_settings_all_messages") }
  /// Plural format key: "%#@VARIABLE@"
  public static func roomSettingsBannedUsersCount(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "room_settings_banned_users_count", p1)
  }
  /// Banned users
  public static var roomSettingsBannedUsersTitle: String { return ElementL10n.tr("Localizable", "room_settings_banned_users_title") }
  /// Advanced
  public static var roomSettingsCategoryAdvancedTitle: String { return ElementL10n.tr("Localizable", "room_settings_category_advanced_title") }
  /// Enable end-to-end encryption…
  public static var roomSettingsEnableEncryption: String { return ElementL10n.tr("Localizable", "room_settings_enable_encryption") }
  /// Once enabled, encryption for a room cannot be disabled. Messages sent in an encrypted room cannot be seen by the server, only by the participants of the room. Enabling encryption may prevent many bots and bridges from working correctly.
  public static var roomSettingsEnableEncryptionDialogContent: String { return ElementL10n.tr("Localizable", "room_settings_enable_encryption_dialog_content") }
  /// Enable encryption
  public static var roomSettingsEnableEncryptionDialogSubmit: String { return ElementL10n.tr("Localizable", "room_settings_enable_encryption_dialog_submit") }
  /// Enable encryption?
  public static var roomSettingsEnableEncryptionDialogTitle: String { return ElementL10n.tr("Localizable", "room_settings_enable_encryption_dialog_title") }
  /// You don't have permission to enable encryption in this room.
  public static var roomSettingsEnableEncryptionNoPermission: String { return ElementL10n.tr("Localizable", "room_settings_enable_encryption_no_permission") }
  /// Allow guests to join
  public static var roomSettingsGuestAccessTitle: String { return ElementL10n.tr("Localizable", "room_settings_guest_access_title") }
  /// Labs
  public static var roomSettingsLabsPrefTitle: String { return ElementL10n.tr("Localizable", "room_settings_labs_pref_title") }
  /// These are experimental features that may break in unexpected ways. Use with caution.
  public static var roomSettingsLabsWarningMessage: String { return ElementL10n.tr("Localizable", "room_settings_labs_warning_message") }
  /// Mentions & Keywords only
  public static var roomSettingsMentionAndKeywordOnly: String { return ElementL10n.tr("Localizable", "room_settings_mention_and_keyword_only") }
  /// Room Name
  public static var roomSettingsNameHint: String { return ElementL10n.tr("Localizable", "room_settings_name_hint") }
  /// None
  public static var roomSettingsNone: String { return ElementL10n.tr("Localizable", "room_settings_none") }
  /// View and update the roles required to change various parts of the room.
  public static var roomSettingsPermissionsSubtitle: String { return ElementL10n.tr("Localizable", "room_settings_permissions_subtitle") }
  /// Room permissions
  public static var roomSettingsPermissionsTitle: String { return ElementL10n.tr("Localizable", "room_settings_permissions_title") }
  /// Anyone
  public static var roomSettingsReadHistoryEntryAnyone: String { return ElementL10n.tr("Localizable", "room_settings_read_history_entry_anyone") }
  /// Members only (since they were invited)
  public static var roomSettingsReadHistoryEntryMembersOnlyInvited: String { return ElementL10n.tr("Localizable", "room_settings_read_history_entry_members_only_invited") }
  /// Members only (since they joined)
  public static var roomSettingsReadHistoryEntryMembersOnlyJoined: String { return ElementL10n.tr("Localizable", "room_settings_read_history_entry_members_only_joined") }
  /// Members only (since the point in time of selecting this option)
  public static var roomSettingsReadHistoryEntryMembersOnlyOptionTimeShared: String { return ElementL10n.tr("Localizable", "room_settings_read_history_entry_members_only_option_time_shared") }
  /// Anyone can knock on the room, members can then accept or reject
  public static var roomSettingsRoomAccessEntryKnock: String { return ElementL10n.tr("Localizable", "room_settings_room_access_entry_knock") }
  /// Unknown access setting (%@)
  public static func roomSettingsRoomAccessEntryUnknown(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_settings_room_access_entry_unknown", String(describing: p1))
  }
  /// Only people invited can find and join
  public static var roomSettingsRoomAccessPrivateDescription: String { return ElementL10n.tr("Localizable", "room_settings_room_access_private_description") }
  /// Private (Invite Only)
  public static var roomSettingsRoomAccessPrivateInviteOnlyTitle: String { return ElementL10n.tr("Localizable", "room_settings_room_access_private_invite_only_title") }
  /// Private
  public static var roomSettingsRoomAccessPrivateTitle: String { return ElementL10n.tr("Localizable", "room_settings_room_access_private_title") }
  /// Anyone can find the room and join
  public static var roomSettingsRoomAccessPublicDescription: String { return ElementL10n.tr("Localizable", "room_settings_room_access_public_description") }
  /// Public
  public static var roomSettingsRoomAccessPublicTitle: String { return ElementL10n.tr("Localizable", "room_settings_room_access_public_title") }
  /// Anyone in a space with this room can find and join it. Only admins of this room can add it to a space.
  public static var roomSettingsRoomAccessRestrictedDescription: String { return ElementL10n.tr("Localizable", "room_settings_room_access_restricted_description") }
  /// Space members only
  public static var roomSettingsRoomAccessRestrictedTitle: String { return ElementL10n.tr("Localizable", "room_settings_room_access_restricted_title") }
  /// Room access
  public static var roomSettingsRoomAccessTitle: String { return ElementL10n.tr("Localizable", "room_settings_room_access_title") }
  /// This room’s internal ID
  public static var roomSettingsRoomInternalId: String { return ElementL10n.tr("Localizable", "room_settings_room_internal_id") }
  /// Account settings
  public static var roomSettingsRoomNotificationsAccountSettings: String { return ElementL10n.tr("Localizable", "room_settings_room_notifications_account_settings") }
  /// Please note that mentions & keyword notifications are not available in encrypted rooms on mobile.
  public static var roomSettingsRoomNotificationsEncryptionNotice: String { return ElementL10n.tr("Localizable", "room_settings_room_notifications_encryption_notice") }
  /// You can manage notifications in %1$@.
  public static func roomSettingsRoomNotificationsManageNotifications(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_settings_room_notifications_manage_notifications", String(describing: p1))
  }
  /// Notify me for
  public static var roomSettingsRoomNotificationsNotifyMe: String { return ElementL10n.tr("Localizable", "room_settings_room_notifications_notify_me") }
  /// Changes to who can read history will only apply to future messages in this room. The visibility of existing history will be unchanged.
  public static var roomSettingsRoomReadHistoryDialogSubtitle: String { return ElementL10n.tr("Localizable", "room_settings_room_read_history_dialog_subtitle") }
  /// Who can read history?
  public static var roomSettingsRoomReadHistoryRulesPrefDialogTitle: String { return ElementL10n.tr("Localizable", "room_settings_room_read_history_rules_pref_dialog_title") }
  /// Room History Readability
  public static var roomSettingsRoomReadHistoryRulesPrefTitle: String { return ElementL10n.tr("Localizable", "room_settings_room_read_history_rules_pref_title") }
  /// Room version
  public static var roomSettingsRoomVersionTitle: String { return ElementL10n.tr("Localizable", "room_settings_room_version_title") }
  /// You changed room settings successfully
  public static var roomSettingsSaveSuccess: String { return ElementL10n.tr("Localizable", "room_settings_save_success") }
  /// Set avatar
  public static var roomSettingsSetAvatar: String { return ElementL10n.tr("Localizable", "room_settings_set_avatar") }
  /// Set as main address
  public static var roomSettingsSetMainAddress: String { return ElementL10n.tr("Localizable", "room_settings_set_main_address") }
  /// Anyone can find the space and join
  public static var roomSettingsSpaceAccessPublicDescription: String { return ElementL10n.tr("Localizable", "room_settings_space_access_public_description") }
  /// Space access
  public static var roomSettingsSpaceAccessTitle: String { return ElementL10n.tr("Localizable", "room_settings_space_access_title") }
  /// Topic
  public static var roomSettingsTopic: String { return ElementL10n.tr("Localizable", "room_settings_topic") }
  /// Topic
  public static var roomSettingsTopicHint: String { return ElementL10n.tr("Localizable", "room_settings_topic_hint") }
  /// Unset as main address
  public static var roomSettingsUnsetMainAddress: String { return ElementL10n.tr("Localizable", "room_settings_unset_main_address") }
  /// Filter Threads in room
  public static var roomThreadsFilter: String { return ElementL10n.tr("Localizable", "room_threads_filter") }
  /// Plural format key: "%#@VARIABLE@"
  public static func roomTitleMembers(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "room_title_members", p1)
  }
  /// This room is a continuation of another conversation
  public static var roomTombstoneContinuationDescription: String { return ElementL10n.tr("Localizable", "room_tombstone_continuation_description") }
  /// The conversation continues here
  public static var roomTombstoneContinuationLink: String { return ElementL10n.tr("Localizable", "room_tombstone_continuation_link") }
  /// Click here to see older messages
  public static var roomTombstonePredecessorLink: String { return ElementL10n.tr("Localizable", "room_tombstone_predecessor_link") }
  /// This room has been replaced and is no longer active.
  public static var roomTombstoneVersionedDescription: String { return ElementL10n.tr("Localizable", "room_tombstone_versioned_description") }
  /// %1$@ & %2$@ are typing…
  public static func roomTwoUsersAreTyping(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "room_two_users_are_typing", String(describing: p1), String(describing: p2))
  }
  /// Encryption has been misconfigured so you can't send messages. Please contact an admin to restore encryption to a valid state.
  public static var roomUnsupportedE2eAlgorithm: String { return ElementL10n.tr("Localizable", "room_unsupported_e2e_algorithm") }
  /// Encryption has been misconfigured so you can't send messages. Click to open settings.
  public static var roomUnsupportedE2eAlgorithmAsAdmin: String { return ElementL10n.tr("Localizable", "room_unsupported_e2e_algorithm_as_admin") }
  /// Upgrade to the recommended room version
  public static var roomUpgradeToRecommendedVersion: String { return ElementL10n.tr("Localizable", "room_upgrade_to_recommended_version") }
  /// This room is running room version %@, which this homeserver has marked as unstable.
  public static func roomUsingUnstableRoomVersion(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_using_unstable_room_version", String(describing: p1))
  }
  /// Widget
  public static var roomWidgetActivityTitle: String { return ElementL10n.tr("Localizable", "room_widget_activity_title") }
  /// Failed to load widget.
  /// %@
  public static func roomWidgetFailedToLoad(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_widget_failed_to_load", String(describing: p1))
  }
  /// Open in browser
  public static var roomWidgetOpenInBrowser: String { return ElementL10n.tr("Localizable", "room_widget_open_in_browser") }
  /// This widget was added by:
  public static var roomWidgetPermissionAddedBy: String { return ElementL10n.tr("Localizable", "room_widget_permission_added_by") }
  /// Your avatar URL
  public static var roomWidgetPermissionAvatarUrl: String { return ElementL10n.tr("Localizable", "room_widget_permission_avatar_url") }
  /// Your display name
  public static var roomWidgetPermissionDisplayName: String { return ElementL10n.tr("Localizable", "room_widget_permission_display_name") }
  /// Room ID
  public static var roomWidgetPermissionRoomId: String { return ElementL10n.tr("Localizable", "room_widget_permission_room_id") }
  /// Using it may share data with %@:
  public static func roomWidgetPermissionSharedInfoTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_widget_permission_shared_info_title", String(describing: p1))
  }
  /// Your theme
  public static var roomWidgetPermissionTheme: String { return ElementL10n.tr("Localizable", "room_widget_permission_theme") }
  /// Load Widget
  public static var roomWidgetPermissionTitle: String { return ElementL10n.tr("Localizable", "room_widget_permission_title") }
  /// Your user ID
  public static var roomWidgetPermissionUserId: String { return ElementL10n.tr("Localizable", "room_widget_permission_user_id") }
  /// Using it may set cookies and share data with %@:
  public static func roomWidgetPermissionWebviewSharedInfoTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "room_widget_permission_webview_shared_info_title", String(describing: p1))
  }
  /// Widget ID
  public static var roomWidgetPermissionWidgetId: String { return ElementL10n.tr("Localizable", "room_widget_permission_widget_id") }
  /// Reload widget
  public static var roomWidgetReload: String { return ElementL10n.tr("Localizable", "room_widget_reload") }
  /// Block All
  public static var roomWidgetResourceDeclinePermission: String { return ElementL10n.tr("Localizable", "room_widget_resource_decline_permission") }
  /// Allow
  public static var roomWidgetResourceGrantPermission: String { return ElementL10n.tr("Localizable", "room_widget_resource_grant_permission") }
  /// This widget wants to use the following resources:
  public static var roomWidgetResourcePermissionTitle: String { return ElementL10n.tr("Localizable", "room_widget_resource_permission_title") }
  /// Revoke access for me
  public static var roomWidgetRevokeAccess: String { return ElementL10n.tr("Localizable", "room_widget_revoke_access") }
  /// Use the camera
  public static var roomWidgetWebviewAccessCamera: String { return ElementL10n.tr("Localizable", "room_widget_webview_access_camera") }
  /// Use the microphone
  public static var roomWidgetWebviewAccessMicrophone: String { return ElementL10n.tr("Localizable", "room_widget_webview_access_microphone") }
  /// Read DRM protected Media
  public static var roomWidgetWebviewReadProtectedMedia: String { return ElementL10n.tr("Localizable", "room_widget_webview_read_protected_media") }
  /// Rooms
  public static var rooms: String { return ElementL10n.tr("Localizable", "rooms") }
  /// Rooms
  public static var roomsHeader: String { return ElementL10n.tr("Localizable", "rooms_header") }
  /// Rotate and crop
  public static var rotateAndCropScreenTitle: String { return ElementL10n.tr("Localizable", "rotate_and_crop_screen_title") }
  /// Unknown Error
  public static var sasErrorUnknown: String { return ElementL10n.tr("Localizable", "sas_error_unknown") }
  /// Got it
  public static var sasGotIt: String { return ElementL10n.tr("Localizable", "sas_got_it") }
  /// %@ wants to verify your session
  public static func sasIncomingRequestNotifContent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "sas_incoming_request_notif_content", String(describing: p1))
  }
  /// Verification Request
  public static var sasIncomingRequestNotifTitle: String { return ElementL10n.tr("Localizable", "sas_incoming_request_notif_title") }
  /// Verified!
  public static var sasVerified: String { return ElementL10n.tr("Localizable", "sas_verified") }
  /// Save recovery key in
  public static var saveRecoveryKeyChooserHint: String { return ElementL10n.tr("Localizable", "save_recovery_key_chooser_hint") }
  /// Screen sharing is in progress
  public static var screenSharingNotificationDescription: String { return ElementL10n.tr("Localizable", "screen_sharing_notification_description") }
  /// %@ Screen Sharing
  public static func screenSharingNotificationTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "screen_sharing_notification_title", String(describing: p1))
  }
  /// Search
  public static var search: String { return ElementL10n.tr("Localizable", "search") }
  /// Filter banned users
  public static var searchBannedUserHint: String { return ElementL10n.tr("Localizable", "search_banned_user_hint") }
  /// Search
  public static var searchHint: String { return ElementL10n.tr("Localizable", "search_hint") }
  /// Search Name
  public static var searchHintRoomName: String { return ElementL10n.tr("Localizable", "search_hint_room_name") }
  /// Filter room members
  public static var searchMembersHint: String { return ElementL10n.tr("Localizable", "search_members_hint") }
  /// No results
  public static var searchNoResults: String { return ElementL10n.tr("Localizable", "search_no_results") }
  /// Plural format key: "%#@VARIABLE@"
  public static func searchSpaceMultipleParents(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "search_space_multiple_parents", p1)
  }
  /// %1$@ and %2$@
  public static func searchSpaceTwoParents(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "search_space_two_parents", String(describing: p1), String(describing: p2))
  }
  /// From a Thread
  public static var searchThreadFromAThread: String { return ElementL10n.tr("Localizable", "search_thread_from_a_thread") }
  /// Plural format key: "%#@VARIABLE@"
  public static func seconds(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "seconds", p1)
  }
  /// Secure Backup
  public static var secureBackupBannerSetupLine1: String { return ElementL10n.tr("Localizable", "secure_backup_banner_setup_line1") }
  /// Safeguard against losing access to encrypted messages & data
  public static var secureBackupBannerSetupLine2: String { return ElementL10n.tr("Localizable", "secure_backup_banner_setup_line2") }
  /// Reset everything
  public static var secureBackupResetAll: String { return ElementL10n.tr("Localizable", "secure_backup_reset_all") }
  /// Only do this if you have no other device you can verify this device with.
  public static var secureBackupResetAllNoOtherDevices: String { return ElementL10n.tr("Localizable", "secure_backup_reset_all_no_other_devices") }
  /// Plural format key: "%#@VARIABLE@"
  public static func secureBackupResetDevicesYouCanVerify(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "secure_backup_reset_devices_you_can_verify", p1)
  }
  /// If you reset everything
  public static var secureBackupResetIfYouResetAll: String { return ElementL10n.tr("Localizable", "secure_backup_reset_if_you_reset_all") }
  /// You will restart with no history, no messages, trusted devices or trusted users
  public static var secureBackupResetNoHistory: String { return ElementL10n.tr("Localizable", "secure_backup_reset_no_history") }
  /// Set Up Secure Backup
  public static var secureBackupSetup: String { return ElementL10n.tr("Localizable", "secure_backup_setup") }
  /// Verify yourself & others to keep your chats safe
  public static var securityPromptText: String { return ElementL10n.tr("Localizable", "security_prompt_text") }
  /// Seen by
  public static var seenBy: String { return ElementL10n.tr("Localizable", "seen_by") }
  /// Select a room directory
  public static var selectRoomDirectory: String { return ElementL10n.tr("Localizable", "select_room_directory") }
  /// Select spaces
  public static var selectSpaces: String { return ElementL10n.tr("Localizable", "select_spaces") }
  /// Sticker
  public static var sendASticker: String { return ElementL10n.tr("Localizable", "send_a_sticker") }
  /// Send attachment
  public static var sendAttachment: String { return ElementL10n.tr("Localizable", "send_attachment") }
  /// Report bug
  public static var sendBugReport: String { return ElementL10n.tr("Localizable", "send_bug_report") }
  /// You seem to be shaking the phone in frustration. Would you like to open the bug report screen?
  public static var sendBugReportAlertMessage: String { return ElementL10n.tr("Localizable", "send_bug_report_alert_message") }
  /// The application has crashed last time. Would you like to open the crash report screen?
  public static var sendBugReportAppCrashed: String { return ElementL10n.tr("Localizable", "send_bug_report_app_crashed") }
  /// Please describe the bug. What did you do? What did you expect to happen? What actually happened?
  public static var sendBugReportDescription: String { return ElementL10n.tr("Localizable", "send_bug_report_description") }
  /// If possible, please write the description in English.
  public static var sendBugReportDescriptionInEnglish: String { return ElementL10n.tr("Localizable", "send_bug_report_description_in_english") }
  /// The bug report failed to be sent (%@)
  public static func sendBugReportFailed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "send_bug_report_failed", String(describing: p1))
  }
  /// Send crash logs
  public static var sendBugReportIncludeCrashLogs: String { return ElementL10n.tr("Localizable", "send_bug_report_include_crash_logs") }
  /// Send key share requests history
  public static var sendBugReportIncludeKeyShareHistory: String { return ElementL10n.tr("Localizable", "send_bug_report_include_key_share_history") }
  /// Send logs
  public static var sendBugReportIncludeLogs: String { return ElementL10n.tr("Localizable", "send_bug_report_include_logs") }
  /// Send screenshot
  public static var sendBugReportIncludeScreenshot: String { return ElementL10n.tr("Localizable", "send_bug_report_include_screenshot") }
  /// In order to diagnose problems, logs from this client will be sent with this bug report. This bug report, including the logs and the screenshot, will not be publicly visible. If you would prefer to only send the text above, please untick:
  public static var sendBugReportLogsDescription: String { return ElementL10n.tr("Localizable", "send_bug_report_logs_description") }
  /// Describe your problem here
  public static var sendBugReportPlaceholder: String { return ElementL10n.tr("Localizable", "send_bug_report_placeholder") }
  /// Progress (%@%%)
  public static func sendBugReportProgress(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "send_bug_report_progress", String(describing: p1))
  }
  /// Rage shake to report bug
  public static var sendBugReportRageShake: String { return ElementL10n.tr("Localizable", "send_bug_report_rage_shake") }
  /// The bug report has been successfully sent
  public static var sendBugReportSent: String { return ElementL10n.tr("Localizable", "send_bug_report_sent") }
  /// You’re using a beta version of spaces. Your feedback will help inform the next versions. Your platform and username will be noted to help us use your feedback as much as we can.
  public static var sendFeedbackSpaceInfo: String { return ElementL10n.tr("Localizable", "send_feedback_space_info") }
  /// Spaces feedback
  public static var sendFeedbackSpaceTitle: String { return ElementL10n.tr("Localizable", "send_feedback_space_title") }
  /// Threads are a work in progress with new, exciting upcoming features, such as improved notifications. We’d love to hear your feedback!
  public static var sendFeedbackThreadsInfo: String { return ElementL10n.tr("Localizable", "send_feedback_threads_info") }
  /// Threads Beta feedback
  public static var sendFeedbackThreadsTitle: String { return ElementL10n.tr("Localizable", "send_feedback_threads_title") }
  /// Compressing image…
  public static var sendFileStepCompressingImage: String { return ElementL10n.tr("Localizable", "send_file_step_compressing_image") }
  /// Compressing video %d%%
  public static func sendFileStepCompressingVideo(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "send_file_step_compressing_video", p1)
  }
  /// Encrypting file…
  public static var sendFileStepEncryptingFile: String { return ElementL10n.tr("Localizable", "send_file_step_encrypting_file") }
  /// Encrypting thumbnail…
  public static var sendFileStepEncryptingThumbnail: String { return ElementL10n.tr("Localizable", "send_file_step_encrypting_thumbnail") }
  /// Waiting…
  public static var sendFileStepIdle: String { return ElementL10n.tr("Localizable", "send_file_step_idle") }
  /// Sending file (%1$@ / %2$@)
  public static func sendFileStepSendingFile(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "send_file_step_sending_file", String(describing: p1), String(describing: p2))
  }
  /// Sending thumbnail (%1$@ / %2$@)
  public static func sendFileStepSendingThumbnail(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "send_file_step_sending_thumbnail", String(describing: p1), String(describing: p2))
  }
  /// Send media with the original size
  public static var sendImagesAndVideoWithOriginalSize: String { return ElementL10n.tr("Localizable", "send_images_and_video_with_original_size") }
  /// Plural format key: "%#@VARIABLE@"
  public static func sendImagesWithOriginalSize(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "send_images_with_original_size", p1)
  }
  /// Make a suggestion
  public static var sendSuggestion: String { return ElementL10n.tr("Localizable", "send_suggestion") }
  /// Please write your suggestion below.
  public static var sendSuggestionContent: String { return ElementL10n.tr("Localizable", "send_suggestion_content") }
  /// The suggestion failed to be sent (%@)
  public static func sendSuggestionFailed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "send_suggestion_failed", String(describing: p1))
  }
  /// Describe your suggestion here
  public static var sendSuggestionReportPlaceholder: String { return ElementL10n.tr("Localizable", "send_suggestion_report_placeholder") }
  /// Thanks, the suggestion has been successfully sent
  public static var sendSuggestionSent: String { return ElementL10n.tr("Localizable", "send_suggestion_sent") }
  /// Plural format key: "%#@VARIABLE@"
  public static func sendVideosWithOriginalSize(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "send_videos_with_original_size", p1)
  }
  /// Sent you an invitation
  public static var sendYouInvite: String { return ElementL10n.tr("Localizable", "send_you_invite") }
  /// Send your first message to invite %@ to chat
  public static func sendYourFirstMsgToInvite(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "send_your_first_msg_to_invite", String(describing: p1))
  }
  /// File
  public static var sentAFile: String { return ElementL10n.tr("Localizable", "sent_a_file") }
  /// Poll
  public static var sentAPoll: String { return ElementL10n.tr("Localizable", "sent_a_poll") }
  /// Reacted with: %@
  public static func sentAReaction(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "sent_a_reaction", String(describing: p1))
  }
  /// Video.
  public static var sentAVideo: String { return ElementL10n.tr("Localizable", "sent_a_video") }
  /// Voice
  public static var sentAVoiceMessage: String { return ElementL10n.tr("Localizable", "sent_a_voice_message") }
  /// Audio
  public static var sentAnAudioFile: String { return ElementL10n.tr("Localizable", "sent_an_audio_file") }
  /// Image.
  public static var sentAnImage: String { return ElementL10n.tr("Localizable", "sent_an_image") }
  /// Shared their live location
  public static var sentLiveLocation: String { return ElementL10n.tr("Localizable", "sent_live_location") }
  /// Shared their location
  public static var sentLocation: String { return ElementL10n.tr("Localizable", "sent_location") }
  /// Verification Conclusion
  public static var sentVerificationConclusion: String { return ElementL10n.tr("Localizable", "sent_verification_conclusion") }
  /// Enter your Security Phrase again to confirm it.
  public static var setASecurityPhraseAgainNotice: String { return ElementL10n.tr("Localizable", "set_a_security_phrase_again_notice") }
  /// Security Phrase
  public static var setASecurityPhraseHint: String { return ElementL10n.tr("Localizable", "set_a_security_phrase_hint") }
  /// Enter a security phrase only you know, used to secure secrets on your server.
  public static var setASecurityPhraseNotice: String { return ElementL10n.tr("Localizable", "set_a_security_phrase_notice") }
  /// Set a Security Phrase
  public static var setASecurityPhraseTitle: String { return ElementL10n.tr("Localizable", "set_a_security_phrase_title") }
  /// Settings
  public static var settings: String { return ElementL10n.tr("Localizable", "settings") }
  /// Show timestamps in 12-hour format
  public static var settings1224Timestamps: String { return ElementL10n.tr("Localizable", "settings_12_24_timestamps") }
  /// Account Data
  public static var settingsAccountData: String { return ElementL10n.tr("Localizable", "settings_account_data") }
  /// Plural format key: "%#@VARIABLE@"
  public static func settingsActiveSessionsCount(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "settings_active_sessions_count", p1)
  }
  /// Active Sessions
  public static var settingsActiveSessionsList: String { return ElementL10n.tr("Localizable", "settings_active_sessions_list") }
  /// Manage Sessions
  public static var settingsActiveSessionsManage: String { return ElementL10n.tr("Localizable", "settings_active_sessions_manage") }
  /// Show All Sessions
  public static var settingsActiveSessionsShowAll: String { return ElementL10n.tr("Localizable", "settings_active_sessions_show_all") }
  /// Sign out of this session
  public static var settingsActiveSessionsSignoutDevice: String { return ElementL10n.tr("Localizable", "settings_active_sessions_signout_device") }
  /// Verify this session to mark it as trusted & grant it access to encrypted messages. If you didn’t sign in to this session your account may be compromised:
  public static var settingsActiveSessionsUnverifiedDeviceDesc: String { return ElementL10n.tr("Localizable", "settings_active_sessions_unverified_device_desc") }
  /// This session is trusted for secure messaging because you verified it:
  public static var settingsActiveSessionsVerifiedDeviceDesc: String { return ElementL10n.tr("Localizable", "settings_active_sessions_verified_device_desc") }
  /// Add email address
  public static var settingsAddEmailAddress: String { return ElementL10n.tr("Localizable", "settings_add_email_address") }
  /// Add phone number
  public static var settingsAddPhoneNumber: String { return ElementL10n.tr("Localizable", "settings_add_phone_number") }
  /// Advanced
  public static var settingsAdvanced: String { return ElementL10n.tr("Localizable", "settings_advanced") }
  /// Advanced settings
  public static var settingsAdvancedSettings: String { return ElementL10n.tr("Localizable", "settings_advanced_settings") }
  /// Agree to the identity server (%@) Terms of Service to allow yourself to be discoverable by email address or phone number.
  public static func settingsAgreeToTerms(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_agree_to_terms", String(describing: p1))
  }
  /// Show timestamps for all messages
  public static var settingsAlwaysShowTimestamps: String { return ElementL10n.tr("Localizable", "settings_always_show_timestamps") }
  /// Analytics
  public static var settingsAnalytics: String { return ElementL10n.tr("Localizable", "settings_analytics") }
  /// Show the application info in the system settings.
  public static var settingsAppInfoLinkSummary: String { return ElementL10n.tr("Localizable", "settings_app_info_link_summary") }
  /// Application info
  public static var settingsAppInfoLinkTitle: String { return ElementL10n.tr("Localizable", "settings_app_info_link_title") }
  /// Terms & conditions
  public static var settingsAppTermConditions: String { return ElementL10n.tr("Localizable", "settings_app_term_conditions") }
  /// Play animated images in the timeline as soon as they are visible
  public static var settingsAutoplayAnimatedImagesSummary: String { return ElementL10n.tr("Localizable", "settings_autoplay_animated_images_summary") }
  /// Autoplay animated images
  public static var settingsAutoplayAnimatedImagesTitle: String { return ElementL10n.tr("Localizable", "settings_autoplay_animated_images_title") }
  /// Background Sync Mode
  public static var settingsBackgroundFdroidSyncMode: String { return ElementL10n.tr("Localizable", "settings_background_fdroid_sync_mode") }
  /// Optimized for battery
  public static var settingsBackgroundFdroidSyncModeBattery: String { return ElementL10n.tr("Localizable", "settings_background_fdroid_sync_mode_battery") }
  /// %@ will sync in background in way that preserves the device’s limited resources (battery).
  /// Depending on your device resource state, the sync may be deferred by the operating system.
  public static func settingsBackgroundFdroidSyncModeBatteryDescription(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_background_fdroid_sync_mode_battery_description", String(describing: p1))
  }
  /// No background sync
  public static var settingsBackgroundFdroidSyncModeDisabled: String { return ElementL10n.tr("Localizable", "settings_background_fdroid_sync_mode_disabled") }
  /// You will not be notified of incoming messages when the app is in background.
  public static var settingsBackgroundFdroidSyncModeDisabledDescription: String { return ElementL10n.tr("Localizable", "settings_background_fdroid_sync_mode_disabled_description") }
  /// Optimized for real time
  public static var settingsBackgroundFdroidSyncModeRealTime: String { return ElementL10n.tr("Localizable", "settings_background_fdroid_sync_mode_real_time") }
  /// %@ will sync in background periodically at precise time (configurable).
  /// This will impact radio and battery usage, there will be a permanent notification displayed stating that %@ is listening for events.
  public static func settingsBackgroundFdroidSyncModeRealTimeDescription(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_background_fdroid_sync_mode_real_time_description", String(describing: p1), String(describing: p2))
  }
  /// Background synchronization
  public static var settingsBackgroundSync: String { return ElementL10n.tr("Localizable", "settings_background_sync") }
  /// Calls
  public static var settingsCallCategory: String { return ElementL10n.tr("Localizable", "settings_call_category") }
  /// Call invitations
  public static var settingsCallInvitations: String { return ElementL10n.tr("Localizable", "settings_call_invitations") }
  /// Configure Call Notifications
  public static var settingsCallNotificationsPreferences: String { return ElementL10n.tr("Localizable", "settings_call_notifications_preferences") }
  /// Select ringtone for calls:
  public static var settingsCallRingtoneDialogTitle: String { return ElementL10n.tr("Localizable", "settings_call_ringtone_dialog_title") }
  /// Incoming call ringtone
  public static var settingsCallRingtoneTitle: String { return ElementL10n.tr("Localizable", "settings_call_ringtone_title") }
  /// Use default %@ ringtone for incoming calls
  public static func settingsCallRingtoneUseAppRingtone(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_call_ringtone_use_app_ringtone", String(describing: p1))
  }
  /// Ask for confirmation before starting a call
  public static var settingsCallShowConfirmationDialogSummary: String { return ElementL10n.tr("Localizable", "settings_call_show_confirmation_dialog_summary") }
  /// Prevent accidental call
  public static var settingsCallShowConfirmationDialogTitle: String { return ElementL10n.tr("Localizable", "settings_call_show_confirmation_dialog_title") }
  /// Message editor
  public static var settingsCategoryComposer: String { return ElementL10n.tr("Localizable", "settings_category_composer") }
  /// Room directory
  public static var settingsCategoryRoomDirectory: String { return ElementL10n.tr("Localizable", "settings_category_room_directory") }
  /// Timeline
  public static var settingsCategoryTimeline: String { return ElementL10n.tr("Localizable", "settings_category_timeline") }
  /// Change password
  public static var settingsChangePassword: String { return ElementL10n.tr("Localizable", "settings_change_password") }
  /// Use /confetti command or send a message containing ❄️ or 🎉
  public static var settingsChatEffectsDescription: String { return ElementL10n.tr("Localizable", "settings_chat_effects_description") }
  /// Show chat effects
  public static var settingsChatEffectsTitle: String { return ElementL10n.tr("Localizable", "settings_chat_effects_title") }
  /// Clear cache
  public static var settingsClearCache: String { return ElementL10n.tr("Localizable", "settings_clear_cache") }
  /// Clear media cache
  public static var settingsClearMediaCache: String { return ElementL10n.tr("Localizable", "settings_clear_media_cache") }
  /// Local contacts
  public static var settingsContact: String { return ElementL10n.tr("Localizable", "settings_contact") }
  /// Contacts permission
  public static var settingsContactsAppPermission: String { return ElementL10n.tr("Localizable", "settings_contacts_app_permission") }
  /// Phonebook country
  public static var settingsContactsPhonebookCountry: String { return ElementL10n.tr("Localizable", "settings_contacts_phonebook_country") }
  /// Msgs containing my display name
  public static var settingsContainingMyDisplayName: String { return ElementL10n.tr("Localizable", "settings_containing_my_display_name") }
  /// Msgs containing my user name
  public static var settingsContainingMyUserName: String { return ElementL10n.tr("Localizable", "settings_containing_my_user_name") }
  /// Copyright
  public static var settingsCopyright: String { return ElementL10n.tr("Localizable", "settings_copyright") }
  /// Cryptography
  public static var settingsCryptography: String { return ElementL10n.tr("Localizable", "settings_cryptography") }
  /// Cryptography Keys Management
  public static var settingsCryptographyManageKeys: String { return ElementL10n.tr("Localizable", "settings_cryptography_manage_keys") }
  /// Deactivate account
  public static var settingsDeactivateAccountSection: String { return ElementL10n.tr("Localizable", "settings_deactivate_account_section") }
  /// Deactivate my account
  public static var settingsDeactivateMyAccount: String { return ElementL10n.tr("Localizable", "settings_deactivate_my_account") }
  /// Default compression
  public static var settingsDefaultCompression: String { return ElementL10n.tr("Localizable", "settings_default_compression") }
  /// Default media source
  public static var settingsDefaultMediaSource: String { return ElementL10n.tr("Localizable", "settings_default_media_source") }
  /// Dev Tools
  public static var settingsDevTools: String { return ElementL10n.tr("Localizable", "settings_dev_tools") }
  /// Developer mode
  public static var settingsDeveloperMode: String { return ElementL10n.tr("Localizable", "settings_developer_mode") }
  /// %@ may crash more often when an unexpected error occurs
  public static func settingsDeveloperModeFailFastSummary(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_developer_mode_fail_fast_summary", String(describing: p1))
  }
  /// Fail-fast
  public static var settingsDeveloperModeFailFastTitle: String { return ElementL10n.tr("Localizable", "settings_developer_mode_fail_fast_title") }
  /// Show some useful info to help debugging the application
  public static var settingsDeveloperModeShowInfoOnScreenSummary: String { return ElementL10n.tr("Localizable", "settings_developer_mode_show_info_on_screen_summary") }
  /// Show debug info on screen
  public static var settingsDeveloperModeShowInfoOnScreenTitle: String { return ElementL10n.tr("Localizable", "settings_developer_mode_show_info_on_screen_title") }
  /// The developer mode activates hidden features and may also make the application less stable. For developers only!
  public static var settingsDeveloperModeSummary: String { return ElementL10n.tr("Localizable", "settings_developer_mode_summary") }
  /// Could not connect to identity server
  public static var settingsDiscoveryBadIdentityServer: String { return ElementL10n.tr("Localizable", "settings_discovery_bad_identity_server") }
  /// Discovery
  public static var settingsDiscoveryCategory: String { return ElementL10n.tr("Localizable", "settings_discovery_category") }
  /// We sent you a confirm email to %@, check your email and click on the confirmation link
  public static func settingsDiscoveryConfirmMail(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_discovery_confirm_mail", String(describing: p1))
  }
  /// We sent you a confirm email to %@, please first check your email and click on the confirmation link
  public static func settingsDiscoveryConfirmMailNotClicked(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_discovery_confirm_mail_not_clicked", String(describing: p1))
  }
  /// Give consent
  public static var settingsDiscoveryConsentActionGiveConsent: String { return ElementL10n.tr("Localizable", "settings_discovery_consent_action_give_consent") }
  /// Revoke my consent
  public static var settingsDiscoveryConsentActionRevoke: String { return ElementL10n.tr("Localizable", "settings_discovery_consent_action_revoke") }
  /// Your contacts are private. To discover users from your contacts, we need your permission to send contact info to your identity server.
  public static var settingsDiscoveryConsentNoticeOff2: String { return ElementL10n.tr("Localizable", "settings_discovery_consent_notice_off_2") }
  /// You have given your consent to send emails and phone numbers to this identity server to discover other users from your contacts.
  public static var settingsDiscoveryConsentNoticeOn: String { return ElementL10n.tr("Localizable", "settings_discovery_consent_notice_on") }
  /// Send emails and phone numbers
  public static var settingsDiscoveryConsentTitle: String { return ElementL10n.tr("Localizable", "settings_discovery_consent_title") }
  /// Disconnecting from your identity server will mean you won’t be discoverable by other users and you won’t be able to invite others by email or phone.
  public static var settingsDiscoveryDisconnectIdentityServerInfo: String { return ElementL10n.tr("Localizable", "settings_discovery_disconnect_identity_server_info") }
  /// You are currently sharing email addresses or phone numbers on the identity server %1$@. You will need to reconnect to %2$@ to stop sharing them.
  public static func settingsDiscoveryDisconnectWithBoundPid(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_discovery_disconnect_with_bound_pid", String(describing: p1), String(describing: p2))
  }
  /// Discoverable email addresses
  public static var settingsDiscoveryEmailsTitle: String { return ElementL10n.tr("Localizable", "settings_discovery_emails_title") }
  /// Enter an identity server URL
  public static var settingsDiscoveryEnterIdentityServer: String { return ElementL10n.tr("Localizable", "settings_discovery_enter_identity_server") }
  /// Hide identity server policy
  public static var settingsDiscoveryHideIdentityServerPolicyTitle: String { return ElementL10n.tr("Localizable", "settings_discovery_hide_identity_server_policy_title") }
  /// You are currently using %1$@ to discover and be discoverable by existing contacts you know.
  public static func settingsDiscoveryIdentityServerInfo(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_discovery_identity_server_info", String(describing: p1))
  }
  /// You are not currently using an identity server. To discover and be discoverable by existing contacts you know, configure one below.
  public static var settingsDiscoveryIdentityServerInfoNone: String { return ElementL10n.tr("Localizable", "settings_discovery_identity_server_info_none") }
  /// Manage your discovery settings.
  public static var settingsDiscoveryManage: String { return ElementL10n.tr("Localizable", "settings_discovery_manage") }
  /// Discoverable phone numbers
  public static var settingsDiscoveryMsisdnTitle: String { return ElementL10n.tr("Localizable", "settings_discovery_msisdn_title") }
  /// Discovery options will appear once you have added an email.
  public static var settingsDiscoveryNoMails: String { return ElementL10n.tr("Localizable", "settings_discovery_no_mails") }
  /// Discovery options will appear once you have added a phone number.
  public static var settingsDiscoveryNoMsisdn: String { return ElementL10n.tr("Localizable", "settings_discovery_no_msisdn") }
  /// No policy provided by the identity server
  public static var settingsDiscoveryNoPolicyProvided: String { return ElementL10n.tr("Localizable", "settings_discovery_no_policy_provided") }
  /// The identity server you have chosen does not have any terms of services. Only continue if you trust the owner of the service
  public static var settingsDiscoveryNoTerms: String { return ElementL10n.tr("Localizable", "settings_discovery_no_terms") }
  /// Identity server has no terms of services
  public static var settingsDiscoveryNoTermsTitle: String { return ElementL10n.tr("Localizable", "settings_discovery_no_terms_title") }
  /// Please enter the identity server url
  public static var settingsDiscoveryPleaseEnterServer: String { return ElementL10n.tr("Localizable", "settings_discovery_please_enter_server") }
  /// Show identity server policy
  public static var settingsDiscoveryShowIdentityServerPolicyTitle: String { return ElementL10n.tr("Localizable", "settings_discovery_show_identity_server_policy_title") }
  /// Display Name
  public static var settingsDisplayName: String { return ElementL10n.tr("Localizable", "settings_display_name") }
  /// Email addresses
  public static var settingsEmails: String { return ElementL10n.tr("Localizable", "settings_emails") }
  /// Manage emails and phone numbers linked to your Matrix account
  public static var settingsEmailsAndPhoneNumbersSummary: String { return ElementL10n.tr("Localizable", "settings_emails_and_phone_numbers_summary") }
  /// Emails and phone numbers
  public static var settingsEmailsAndPhoneNumbersTitle: String { return ElementL10n.tr("Localizable", "settings_emails_and_phone_numbers_title") }
  /// No email has been added to your account
  public static var settingsEmailsEmpty: String { return ElementL10n.tr("Localizable", "settings_emails_empty") }
  /// Enable notifications for this account
  public static var settingsEnableAllNotif: String { return ElementL10n.tr("Localizable", "settings_enable_all_notif") }
  /// Enable notifications for this session
  public static var settingsEnableThisDevice: String { return ElementL10n.tr("Localizable", "settings_enable_this_device") }
  /// Encrypted direct messages
  public static var settingsEncryptedDirectMessages: String { return ElementL10n.tr("Localizable", "settings_encrypted_direct_messages") }
  /// Encrypted group messages
  public static var settingsEncryptedGroupMessages: String { return ElementL10n.tr("Localizable", "settings_encrypted_group_messages") }
  /// Export Audit
  public static var settingsExportTrail: String { return ElementL10n.tr("Localizable", "settings_export_trail") }
  /// Failed to update password
  public static var settingsFailToUpdatePassword: String { return ElementL10n.tr("Localizable", "settings_fail_to_update_password") }
  /// The password is not valid
  public static var settingsFailToUpdatePasswordInvalidCurrentPassword: String { return ElementL10n.tr("Localizable", "settings_fail_to_update_password_invalid_current_password") }
  /// No cryptographic information available
  public static var settingsFailedToGetCryptoDeviceInfo: String { return ElementL10n.tr("Localizable", "settings_failed_to_get_crypto_device_info") }
  /// General
  public static var settingsGeneralTitle: String { return ElementL10n.tr("Localizable", "settings_general_title") }
  /// Group messages
  public static var settingsGroupMessages: String { return ElementL10n.tr("Localizable", "settings_group_messages") }
  /// Home display
  public static var settingsHomeDisplay: String { return ElementL10n.tr("Localizable", "settings_home_display") }
  /// Homeserver
  public static var settingsHomeServer: String { return ElementL10n.tr("Localizable", "settings_home_server") }
  /// Your server admin has disabled end-to-end encryption by default in private rooms & Direct Messages.
  public static var settingsHsAdminE2eDisabled: String { return ElementL10n.tr("Localizable", "settings_hs_admin_e2e_disabled") }
  /// Identity server
  public static var settingsIdentityServer: String { return ElementL10n.tr("Localizable", "settings_identity_server") }
  /// Ignored users
  public static var settingsIgnoredUsers: String { return ElementL10n.tr("Localizable", "settings_ignored_users") }
  /// Inline URL preview
  public static var settingsInlineUrlPreview: String { return ElementL10n.tr("Localizable", "settings_inline_url_preview") }
  /// Preview links within the chat when your homeserver supports this feature.
  public static var settingsInlineUrlPreviewSummary: String { return ElementL10n.tr("Localizable", "settings_inline_url_preview_summary") }
  /// Allow integrations
  public static var settingsIntegrationAllow: String { return ElementL10n.tr("Localizable", "settings_integration_allow") }
  /// Integration manager
  public static var settingsIntegrationManager: String { return ElementL10n.tr("Localizable", "settings_integration_manager") }
  /// Integrations
  public static var settingsIntegrations: String { return ElementL10n.tr("Localizable", "settings_integrations") }
  /// Use an integration manager to manage bots, bridges, widgets and sticker packs.
  /// Integration managers receive configuration data, and can modify widgets, send room invites and set power levels on your behalf.
  public static var settingsIntegrationsSummary: String { return ElementL10n.tr("Localizable", "settings_integrations_summary") }
  /// Language
  public static var settingsInterfaceLanguage: String { return ElementL10n.tr("Localizable", "settings_interface_language") }
  /// When I’m invited to a room
  public static var settingsInvitedToRoom: String { return ElementL10n.tr("Localizable", "settings_invited_to_room") }
  /// Keep media
  public static var settingsKeepMedia: String { return ElementL10n.tr("Localizable", "settings_keep_media") }
  /// Key Requests
  public static var settingsKeyRequests: String { return ElementL10n.tr("Localizable", "settings_key_requests") }
  /// Use native camera
  public static var settingsLabsNativeCamera: String { return ElementL10n.tr("Localizable", "settings_labs_native_camera") }
  /// Start the system camera instead of the custom camera screen.
  public static var settingsLabsNativeCameraSummary: String { return ElementL10n.tr("Localizable", "settings_labs_native_camera_summary") }
  /// Show complete history in encrypted rooms
  public static var settingsLabsShowCompleteHistoryInEncryptedRoom: String { return ElementL10n.tr("Localizable", "settings_labs_show_complete_history_in_encrypted_room") }
  /// Show hidden events in timeline
  public static var settingsLabsShowHiddenEventsInTimeline: String { return ElementL10n.tr("Localizable", "settings_labs_show_hidden_events_in_timeline") }
  /// Logged in as
  public static var settingsLoggedIn: String { return ElementL10n.tr("Localizable", "settings_logged_in") }
  /// Media
  public static var settingsMedia: String { return ElementL10n.tr("Localizable", "settings_media") }
  /// You won’t get notifications for mentions & keywords in encrypted rooms on mobile.
  public static var settingsMentionsAndKeywordsEncryptionNotice: String { return ElementL10n.tr("Localizable", "settings_mentions_and_keywords_encryption_notice") }
  /// @room
  public static var settingsMentionsAtRoom: String { return ElementL10n.tr("Localizable", "settings_mentions_at_room") }
  /// Messages containing @room
  public static var settingsMessagesAtRoom: String { return ElementL10n.tr("Localizable", "settings_messages_at_room") }
  /// Messages by bot
  public static var settingsMessagesByBot: String { return ElementL10n.tr("Localizable", "settings_messages_by_bot") }
  /// My display name
  public static var settingsMessagesContainingDisplayName: String { return ElementL10n.tr("Localizable", "settings_messages_containing_display_name") }
  /// Keywords
  public static var settingsMessagesContainingKeywords: String { return ElementL10n.tr("Localizable", "settings_messages_containing_keywords") }
  /// My username
  public static var settingsMessagesContainingUsername: String { return ElementL10n.tr("Localizable", "settings_messages_containing_username") }
  /// Direct messages
  public static var settingsMessagesDirectMessages: String { return ElementL10n.tr("Localizable", "settings_messages_direct_messages") }
  /// Encrypted messages in group chats
  public static var settingsMessagesInE2eGroupChat: String { return ElementL10n.tr("Localizable", "settings_messages_in_e2e_group_chat") }
  /// Encrypted messages in one-to-one chats
  public static var settingsMessagesInE2eOneToOne: String { return ElementL10n.tr("Localizable", "settings_messages_in_e2e_one_to_one") }
  /// Msgs in group chats
  public static var settingsMessagesInGroupChat: String { return ElementL10n.tr("Localizable", "settings_messages_in_group_chat") }
  /// Msgs in one-to-one chats
  public static var settingsMessagesInOneToOne: String { return ElementL10n.tr("Localizable", "settings_messages_in_one_to_one") }
  /// Messages sent by bot
  public static var settingsMessagesSentByBot: String { return ElementL10n.tr("Localizable", "settings_messages_sent_by_bot") }
  /// New password
  public static var settingsNewPassword: String { return ElementL10n.tr("Localizable", "settings_new_password") }
  /// Configure Noisy Notifications
  public static var settingsNoisyNotificationsPreferences: String { return ElementL10n.tr("Localizable", "settings_noisy_notifications_preferences") }
  /// Advanced Notification Settings
  public static var settingsNotificationAdvanced: String { return ElementL10n.tr("Localizable", "settings_notification_advanced") }
  /// Notification importance by event
  public static var settingsNotificationByEvent: String { return ElementL10n.tr("Localizable", "settings_notification_by_event") }
  /// Notifications configuration
  public static var settingsNotificationConfiguration: String { return ElementL10n.tr("Localizable", "settings_notification_configuration") }
  /// Default Notifications
  public static var settingsNotificationDefault: String { return ElementL10n.tr("Localizable", "settings_notification_default") }
  /// Email notification
  public static var settingsNotificationEmailsCategory: String { return ElementL10n.tr("Localizable", "settings_notification_emails_category") }
  /// Enable email notifications for %@
  public static func settingsNotificationEmailsEnableForEmail(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_notification_emails_enable_for_email", String(describing: p1))
  }
  /// To receive email with notification, please associate an email to your Matrix account
  public static var settingsNotificationEmailsNoEmails: String { return ElementL10n.tr("Localizable", "settings_notification_emails_no_emails") }
  /// Keywords cannot start with '.'
  public static var settingsNotificationKeywordContainsDot: String { return ElementL10n.tr("Localizable", "settings_notification_keyword_contains_dot") }
  /// Keywords cannot contain '%@'
  public static func settingsNotificationKeywordContainsInvalidCharacter(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_notification_keyword_contains_invalid_character", String(describing: p1))
  }
  /// Mentions and Keywords
  public static var settingsNotificationMentionsAndKeywords: String { return ElementL10n.tr("Localizable", "settings_notification_mentions_and_keywords") }
  /// Notification method
  public static var settingsNotificationMethod: String { return ElementL10n.tr("Localizable", "settings_notification_method") }
  /// Add new keyword
  public static var settingsNotificationNewKeyword: String { return ElementL10n.tr("Localizable", "settings_notification_new_keyword") }
  /// Notify me for
  public static var settingsNotificationNotifyMeFor: String { return ElementL10n.tr("Localizable", "settings_notification_notify_me_for") }
  /// Other
  public static var settingsNotificationOther: String { return ElementL10n.tr("Localizable", "settings_notification_other") }
  /// Notification sound
  public static var settingsNotificationRingtone: String { return ElementL10n.tr("Localizable", "settings_notification_ringtone") }
  /// Troubleshoot Notifications
  public static var settingsNotificationTroubleshoot: String { return ElementL10n.tr("Localizable", "settings_notification_troubleshoot") }
  /// Your keywords
  public static var settingsNotificationYourKeywords: String { return ElementL10n.tr("Localizable", "settings_notification_your_keywords") }
  /// Notifications
  public static var settingsNotifications: String { return ElementL10n.tr("Localizable", "settings_notifications") }
  /// Notification Targets
  public static var settingsNotificationsTargets: String { return ElementL10n.tr("Localizable", "settings_notifications_targets") }
  /// Current password
  public static var settingsOldPassword: String { return ElementL10n.tr("Localizable", "settings_old_password") }
  /// olm version
  public static var settingsOlmVersion: String { return ElementL10n.tr("Localizable", "settings_olm_version") }
  /// Send analytics data
  public static var settingsOptInOfAnalytics: String { return ElementL10n.tr("Localizable", "settings_opt_in_of_analytics") }
  /// %@ collects anonymous analytics to allow us to improve the application.
  public static func settingsOptInOfAnalyticsSummary(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_opt_in_of_analytics_summary", String(describing: p1))
  }
  /// Other
  public static var settingsOther: String { return ElementL10n.tr("Localizable", "settings_other") }
  /// Other third party notices
  public static var settingsOtherThirdPartyNotices: String { return ElementL10n.tr("Localizable", "settings_other_third_party_notices") }
  /// Password
  public static var settingsPassword: String { return ElementL10n.tr("Localizable", "settings_password") }
  /// Your password has been updated
  public static var settingsPasswordUpdated: String { return ElementL10n.tr("Localizable", "settings_password_updated") }
  /// No phone number has been added to your account
  public static var settingsPhoneNumberEmpty: String { return ElementL10n.tr("Localizable", "settings_phone_number_empty") }
  /// Phone numbers
  public static var settingsPhoneNumbers: String { return ElementL10n.tr("Localizable", "settings_phone_numbers") }
  /// Pin rooms with missed notifications
  public static var settingsPinMissedNotifications: String { return ElementL10n.tr("Localizable", "settings_pin_missed_notifications") }
  /// Pin rooms with unread messages
  public static var settingsPinUnreadMessages: String { return ElementL10n.tr("Localizable", "settings_pin_unread_messages") }
  /// Play shutter sound
  public static var settingsPlayShutterSound: String { return ElementL10n.tr("Localizable", "settings_play_shutter_sound") }
  /// Preferences
  public static var settingsPreferences: String { return ElementL10n.tr("Localizable", "settings_preferences") }
  /// Presence
  public static var settingsPresence: String { return ElementL10n.tr("Localizable", "settings_presence") }
  /// Offline mode
  public static var settingsPresenceUserAlwaysAppearsOffline: String { return ElementL10n.tr("Localizable", "settings_presence_user_always_appears_offline") }
  /// If enabled, you will always appear offline to other users, even when using the application.
  public static var settingsPresenceUserAlwaysAppearsOfflineSummary: String { return ElementL10n.tr("Localizable", "settings_presence_user_always_appears_offline_summary") }
  /// Preview media before sending
  public static var settingsPreviewMediaBeforeSending: String { return ElementL10n.tr("Localizable", "settings_preview_media_before_sending") }
  /// Privacy policy
  public static var settingsPrivacyPolicy: String { return ElementL10n.tr("Localizable", "settings_privacy_policy") }
  /// Profile Picture
  public static var settingsProfilePicture: String { return ElementL10n.tr("Localizable", "settings_profile_picture") }
  /// No registered push gateways
  public static var settingsPushGatewayNoPushers: String { return ElementL10n.tr("Localizable", "settings_push_gateway_no_pushers") }
  /// Push Rules
  public static var settingsPushRules: String { return ElementL10n.tr("Localizable", "settings_push_rules") }
  /// No push rules defined
  public static var settingsPushRulesNoRules: String { return ElementL10n.tr("Localizable", "settings_push_rules_no_rules") }
  /// Rageshake
  public static var settingsRageshake: String { return ElementL10n.tr("Localizable", "settings_rageshake") }
  /// Detection threshold
  public static var settingsRageshakeDetectionThreshold: String { return ElementL10n.tr("Localizable", "settings_rageshake_detection_threshold") }
  /// Shake your phone to test the detection threshold
  public static var settingsRageshakeDetectionThresholdSummary: String { return ElementL10n.tr("Localizable", "settings_rageshake_detection_threshold_summary") }
  /// Remove %@?
  public static func settingsRemoveThreePidConfirmationContent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_remove_three_pid_confirmation_content", String(describing: p1))
  }
  /// Show rooms with explicit content
  public static var settingsRoomDirectoryShowAllRooms: String { return ElementL10n.tr("Localizable", "settings_room_directory_show_all_rooms") }
  /// Show all rooms in the room directory, including rooms with explicit content.
  public static var settingsRoomDirectoryShowAllRoomsSummary: String { return ElementL10n.tr("Localizable", "settings_room_directory_show_all_rooms_summary") }
  /// Room invitations
  public static var settingsRoomInvitations: String { return ElementL10n.tr("Localizable", "settings_room_invitations") }
  /// Room upgrades
  public static var settingsRoomUpgrades: String { return ElementL10n.tr("Localizable", "settings_room_upgrades") }
  /// Matrix SDK Version
  public static var settingsSdkVersion: String { return ElementL10n.tr("Localizable", "settings_sdk_version") }
  /// Set up on this device
  public static var settingsSecureBackupEnterToSetup: String { return ElementL10n.tr("Localizable", "settings_secure_backup_enter_to_setup") }
  /// Reset Secure Backup
  public static var settingsSecureBackupReset: String { return ElementL10n.tr("Localizable", "settings_secure_backup_reset") }
  /// Safeguard against losing access to encrypted messages & data by backing up encryption keys on your server.
  public static var settingsSecureBackupSectionInfo: String { return ElementL10n.tr("Localizable", "settings_secure_backup_section_info") }
  /// Secure Backup
  public static var settingsSecureBackupSectionTitle: String { return ElementL10n.tr("Localizable", "settings_secure_backup_section_title") }
  /// Set up Secure Backup
  public static var settingsSecureBackupSetup: String { return ElementL10n.tr("Localizable", "settings_secure_backup_setup") }
  /// Security & Privacy
  public static var settingsSecurityAndPrivacy: String { return ElementL10n.tr("Localizable", "settings_security_and_privacy") }
  /// Configure protection
  public static var settingsSecurityApplicationProtectionScreenTitle: String { return ElementL10n.tr("Localizable", "settings_security_application_protection_screen_title") }
  /// Protect access using PIN and biometrics.
  public static var settingsSecurityApplicationProtectionSummary: String { return ElementL10n.tr("Localizable", "settings_security_application_protection_summary") }
  /// Protect access
  public static var settingsSecurityApplicationProtectionTitle: String { return ElementL10n.tr("Localizable", "settings_security_application_protection_title") }
  /// Change your current PIN
  public static var settingsSecurityPinCodeChangePinSummary: String { return ElementL10n.tr("Localizable", "settings_security_pin_code_change_pin_summary") }
  /// Change PIN
  public static var settingsSecurityPinCodeChangePinTitle: String { return ElementL10n.tr("Localizable", "settings_security_pin_code_change_pin_title") }
  /// PIN code is required every time you open %@.
  public static func settingsSecurityPinCodeGracePeriodSummaryOff(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_security_pin_code_grace_period_summary_off", String(describing: p1))
  }
  /// PIN code is required after 2 minutes of not using %@.
  public static func settingsSecurityPinCodeGracePeriodSummaryOn(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_security_pin_code_grace_period_summary_on", String(describing: p1))
  }
  /// Require PIN after 2 minutes
  public static var settingsSecurityPinCodeGracePeriodTitle: String { return ElementL10n.tr("Localizable", "settings_security_pin_code_grace_period_title") }
  /// Only display number of unread messages in a simple notification.
  public static var settingsSecurityPinCodeNotificationsSummaryOff: String { return ElementL10n.tr("Localizable", "settings_security_pin_code_notifications_summary_off") }
  /// Show details like room names and message content.
  public static var settingsSecurityPinCodeNotificationsSummaryOn: String { return ElementL10n.tr("Localizable", "settings_security_pin_code_notifications_summary_on") }
  /// Show content in notifications
  public static var settingsSecurityPinCodeNotificationsTitle: String { return ElementL10n.tr("Localizable", "settings_security_pin_code_notifications_title") }
  /// If you want to reset your PIN, tap Forgot PIN to logout and reset.
  public static var settingsSecurityPinCodeSummary: String { return ElementL10n.tr("Localizable", "settings_security_pin_code_summary") }
  /// Enable PIN
  public static var settingsSecurityPinCodeTitle: String { return ElementL10n.tr("Localizable", "settings_security_pin_code_title") }
  /// Could not enable biometric authentication.
  public static var settingsSecurityPinCodeUseBiometricsError: String { return ElementL10n.tr("Localizable", "settings_security_pin_code_use_biometrics_error") }
  /// PIN code is the only way to unlock %@.
  public static func settingsSecurityPinCodeUseBiometricsSummaryOff(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_security_pin_code_use_biometrics_summary_off", String(describing: p1))
  }
  /// Enable device specific biometrics, like fingerprints and face recognition.
  public static var settingsSecurityPinCodeUseBiometricsSummaryOn: String { return ElementL10n.tr("Localizable", "settings_security_pin_code_use_biometrics_summary_on") }
  /// Enable biometrics
  public static var settingsSecurityPinCodeUseBiometricsTitle: String { return ElementL10n.tr("Localizable", "settings_security_pin_code_use_biometrics_title") }
  /// Enabling this setting adds the FLAG_SECURE to all Activities. Restart the application for the change to take effect.
  public static var settingsSecurityPreventScreenshotsSummary: String { return ElementL10n.tr("Localizable", "settings_security_prevent_screenshots_summary") }
  /// Prevent screenshots of the application
  public static var settingsSecurityPreventScreenshotsTitle: String { return ElementL10n.tr("Localizable", "settings_security_prevent_screenshots_title") }
  /// Choose a country
  public static var settingsSelectCountry: String { return ElementL10n.tr("Localizable", "settings_select_country") }
  /// Choose language
  public static var settingsSelectLanguage: String { return ElementL10n.tr("Localizable", "settings_select_language") }
  /// Markdown formatting
  public static var settingsSendMarkdown: String { return ElementL10n.tr("Localizable", "settings_send_markdown") }
  /// Format messages using markdown syntax before they are sent. This allows for advanced formatting such as using asterisks to display italic text.
  public static var settingsSendMarkdownSummary: String { return ElementL10n.tr("Localizable", "settings_send_markdown_summary") }
  /// Send message with enter
  public static var settingsSendMessageWithEnter: String { return ElementL10n.tr("Localizable", "settings_send_message_with_enter") }
  /// Enter button of the soft keyboard will send message instead of adding a line break
  public static var settingsSendMessageWithEnterSummary: String { return ElementL10n.tr("Localizable", "settings_send_message_with_enter_summary") }
  /// Send typing notifications
  public static var settingsSendTypingNotifs: String { return ElementL10n.tr("Localizable", "settings_send_typing_notifs") }
  /// Let other users know that you are typing.
  public static var settingsSendTypingNotifsSummary: String { return ElementL10n.tr("Localizable", "settings_send_typing_notifs_summary") }
  /// Default Version
  public static var settingsServerDefaultRoomVersion: String { return ElementL10n.tr("Localizable", "settings_server_default_room_version") }
  /// Server name
  public static var settingsServerName: String { return ElementL10n.tr("Localizable", "settings_server_name") }
  /// stable
  public static var settingsServerRoomVersionStable: String { return ElementL10n.tr("Localizable", "settings_server_room_version_stable") }
  /// unstable
  public static var settingsServerRoomVersionUnstable: String { return ElementL10n.tr("Localizable", "settings_server_room_version_unstable") }
  /// Room Versions 👓
  public static var settingsServerRoomVersions: String { return ElementL10n.tr("Localizable", "settings_server_room_versions") }
  /// Your homeserver accepts attachments (files, media, etc.) with a size up to %@.
  public static func settingsServerUploadSizeContent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_server_upload_size_content", String(describing: p1))
  }
  /// Server file upload limit
  public static var settingsServerUploadSizeTitle: String { return ElementL10n.tr("Localizable", "settings_server_upload_size_title") }
  /// The limit is unknown.
  public static var settingsServerUploadSizeUnknown: String { return ElementL10n.tr("Localizable", "settings_server_upload_size_unknown") }
  /// Server version
  public static var settingsServerVersion: String { return ElementL10n.tr("Localizable", "settings_server_version") }
  /// Sessions
  public static var settingsSessionsList: String { return ElementL10n.tr("Localizable", "settings_sessions_list") }
  /// For best security, verify your sessions and sign out from any session that you don’t recognize or use anymore.
  public static var settingsSessionsOtherDescription: String { return ElementL10n.tr("Localizable", "settings_sessions_other_description") }
  /// Other sessions
  public static var settingsSessionsOtherTitle: String { return ElementL10n.tr("Localizable", "settings_sessions_other_title") }
  /// Delay between each Sync
  public static var settingsSetSyncDelay: String { return ElementL10n.tr("Localizable", "settings_set_sync_delay") }
  /// Sync request timeout
  public static var settingsSetSyncTimeout: String { return ElementL10n.tr("Localizable", "settings_set_sync_timeout") }
  /// Show account events
  public static var settingsShowAvatarDisplayNameChangesMessages: String { return ElementL10n.tr("Localizable", "settings_show_avatar_display_name_changes_messages") }
  /// Includes avatar and display name changes.
  public static var settingsShowAvatarDisplayNameChangesMessagesSummary: String { return ElementL10n.tr("Localizable", "settings_show_avatar_display_name_changes_messages_summary") }
  /// Show emoji keyboard
  public static var settingsShowEmojiKeyboard: String { return ElementL10n.tr("Localizable", "settings_show_emoji_keyboard") }
  /// Add a button on message composer to open emoji keyboard
  public static var settingsShowEmojiKeyboardSummary: String { return ElementL10n.tr("Localizable", "settings_show_emoji_keyboard_summary") }
  /// Show join and leave events
  public static var settingsShowJoinLeaveMessages: String { return ElementL10n.tr("Localizable", "settings_show_join_leave_messages") }
  /// Invites, removes, and bans are unaffected.
  public static var settingsShowJoinLeaveMessagesSummary: String { return ElementL10n.tr("Localizable", "settings_show_join_leave_messages_summary") }
  /// Show latest user info
  public static var settingsShowLatestProfile: String { return ElementL10n.tr("Localizable", "settings_show_latest_profile") }
  /// Show the latest profile info (avatar and display name) for all the messages.
  public static var settingsShowLatestProfileDescription: String { return ElementL10n.tr("Localizable", "settings_show_latest_profile_description") }
  /// Show read receipts
  public static var settingsShowReadReceipts: String { return ElementL10n.tr("Localizable", "settings_show_read_receipts") }
  /// Click on the read receipts for a detailed list.
  public static var settingsShowReadReceiptsSummary: String { return ElementL10n.tr("Localizable", "settings_show_read_receipts_summary") }
  /// Show removed messages
  public static var settingsShowRedacted: String { return ElementL10n.tr("Localizable", "settings_show_redacted") }
  /// Show a placeholder for removed messages
  public static var settingsShowRedactedSummary: String { return ElementL10n.tr("Localizable", "settings_show_redacted_summary") }
  /// Configure Silent Notifications
  public static var settingsSilentNotificationsPreferences: String { return ElementL10n.tr("Localizable", "settings_silent_notifications_preferences") }
  /// Start on boot
  public static var settingsStartOnBoot: String { return ElementL10n.tr("Localizable", "settings_start_on_boot") }
  /// Choose LED color, vibration, sound…
  public static var settingsSystemPreferencesSummary: String { return ElementL10n.tr("Localizable", "settings_system_preferences_summary") }
  /// A text message has been sent to %@. Please enter the verification code it contains.
  public static func settingsTextMessageSent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_text_message_sent", String(describing: p1))
  }
  /// Code
  public static var settingsTextMessageSentHint: String { return ElementL10n.tr("Localizable", "settings_text_message_sent_hint") }
  /// The verification code is not correct.
  public static var settingsTextMessageSentWrongCode: String { return ElementL10n.tr("Localizable", "settings_text_message_sent_wrong_code") }
  /// Theme
  public static var settingsTheme: String { return ElementL10n.tr("Localizable", "settings_theme") }
  /// Third party notices
  public static var settingsThirdPartyNotices: String { return ElementL10n.tr("Localizable", "settings_third_party_notices") }
  /// Troubleshooting diagnostics
  public static var settingsTroubleshootDiagnostic: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_diagnostic") }
  /// One or more tests have failed, please submit a bug report to help us investigate.
  public static var settingsTroubleshootDiagnosticFailureStatusNoQuickfix: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_diagnostic_failure_status_no_quickfix") }
  /// One or more tests have failed, try suggested fix(es).
  public static var settingsTroubleshootDiagnosticFailureStatusWithQuickfix: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_diagnostic_failure_status_with_quickfix") }
  /// Run Tests
  public static var settingsTroubleshootDiagnosticRunButtonTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_diagnostic_run_button_title") }
  /// Running… (%1$d of %2$d)
  public static func settingsTroubleshootDiagnosticRunningStatus(_ p1: Int, _ p2: Int) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_diagnostic_running_status", p1, p2)
  }
  /// Basic diagnostic is OK. If you still do not receive notifications, please submit a bug report to help us investigate.
  public static var settingsTroubleshootDiagnosticSuccessStatus: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_diagnostic_success_status") }
  /// Notifications are disabled for your account.
  /// Please check account settings.
  public static var settingsTroubleshootTestAccountSettingsFailed: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_account_settings_failed") }
  /// Enable
  public static var settingsTroubleshootTestAccountSettingsQuickfix: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_account_settings_quickfix") }
  /// Notifications are enabled for your account.
  public static var settingsTroubleshootTestAccountSettingsSuccess: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_account_settings_success") }
  /// Account Settings.
  public static var settingsTroubleshootTestAccountSettingsTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_account_settings_title") }
  /// If a user leaves a device unplugged and stationary for a period of time, with the screen off, the device enters Doze mode. This prevents apps from accessing the network and defers their jobs, syncs, and standard alarms.
  public static var settingsTroubleshootTestBatteryFailed: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_battery_failed") }
  /// Ignore Optimization
  public static var settingsTroubleshootTestBatteryQuickfix: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_battery_quickfix") }
  /// %@ is not affected by Battery Optimization.
  public static func settingsTroubleshootTestBatterySuccess(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_battery_success", String(describing: p1))
  }
  /// Battery Optimization
  public static var settingsTroubleshootTestBatteryTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_battery_title") }
  /// Background restrictions are enabled for %@.
  /// Work that the app tries to do will be aggressively restricted while it is in the background, and this could affect notifications.
  /// %1$@
  public static func settingsTroubleshootTestBgRestrictedFailed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_bg_restricted_failed", String(describing: p1))
  }
  /// Disable restrictions
  public static var settingsTroubleshootTestBgRestrictedQuickfix: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_bg_restricted_quickfix") }
  /// Background restrictions are disabled for %@. This test should be run using mobile data (no WIFI).
  /// %1$@
  public static func settingsTroubleshootTestBgRestrictedSuccess(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_bg_restricted_success", String(describing: p1))
  }
  /// Check background restrictions
  public static var settingsTroubleshootTestBgRestrictedTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_bg_restricted_title") }
  /// Some notifications are disabled in your custom settings.
  public static var settingsTroubleshootTestBingSettingsFailed: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_bing_settings_failed") }
  /// Notice that some messages type are set to be silent (will produce a notification with no sound).
  public static var settingsTroubleshootTestBingSettingsSuccessWithWarn: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_bing_settings_success_with_warn") }
  /// Custom Settings.
  public static var settingsTroubleshootTestBingSettingsTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_bing_settings_title") }
  /// Currently using %@.
  public static func settingsTroubleshootTestCurrentDistributor(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_current_distributor", String(describing: p1))
  }
  /// Method
  public static var settingsTroubleshootTestCurrentDistributorTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_current_distributor_title") }
  /// Cannot find the endpoint.
  public static var settingsTroubleshootTestCurrentEndpointFailed: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_current_endpoint_failed") }
  /// Current endpoint: %@
  public static func settingsTroubleshootTestCurrentEndpointSuccess(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_current_endpoint_success", String(describing: p1))
  }
  /// Endpoint
  public static var settingsTroubleshootTestCurrentEndpointTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_current_endpoint_title") }
  /// Current gateway: %@
  public static func settingsTroubleshootTestCurrentGateway(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_current_gateway", String(describing: p1))
  }
  /// Gateway
  public static var settingsTroubleshootTestCurrentGatewayTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_current_gateway_title") }
  /// Notifications are not enabled for this session.
  /// Please check the %@ settings.
  public static func settingsTroubleshootTestDeviceSettingsFailed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_device_settings_failed", String(describing: p1))
  }
  /// Enable
  public static var settingsTroubleshootTestDeviceSettingsQuickfix: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_device_settings_quickfix") }
  /// Notifications are enabled for this session.
  public static var settingsTroubleshootTestDeviceSettingsSuccess: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_device_settings_success") }
  /// Session Settings.
  public static var settingsTroubleshootTestDeviceSettingsTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_device_settings_title") }
  /// No other method than background synchronization found.
  public static var settingsTroubleshootTestDistributorsFdroid: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_distributors_fdroid") }
  /// No other method than Google Play Service found.
  public static var settingsTroubleshootTestDistributorsGplay: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_distributors_gplay") }
  /// Plural format key: "%#@VARIABLE@"
  public static func settingsTroubleshootTestDistributorsMany(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_distributors_many", p1)
  }
  /// Available methods
  public static var settingsTroubleshootTestDistributorsTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_distributors_title") }
  /// Failed to register endpoint token to homeserver:
  /// %1$@
  public static func settingsTroubleshootTestEndpointRegistrationFailed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_endpoint_registration_failed", String(describing: p1))
  }
  /// Reset notification method
  public static var settingsTroubleshootTestEndpointRegistrationQuickFix: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_endpoint_registration_quick_fix") }
  /// Endpoint successfully registered to homeserver.
  public static var settingsTroubleshootTestEndpointRegistrationSuccess: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_endpoint_registration_success") }
  /// Endpoint Registration
  public static var settingsTroubleshootTestEndpointRegistrationTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_endpoint_registration_title") }
  /// Failed to retrieved FCM token:
  /// %1$@
  public static func settingsTroubleshootTestFcmFailed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_fcm_failed", String(describing: p1))
  }
  /// [%1$@]
  /// This error is out of control of %@. There is no Google account on the phone. Please open the account manager and add a Google account.
  public static func settingsTroubleshootTestFcmFailedAccountMissing(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_fcm_failed_account_missing", String(describing: p1))
  }
  /// Add Account
  public static var settingsTroubleshootTestFcmFailedAccountMissingQuickFix: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_fcm_failed_account_missing_quick_fix") }
  /// [%1$@]
  /// This error is out of control of %@. It can occur for several reasons. Maybe it will work if you retry later, you can also check that Google Play Service is not restricted in data usage in the system settings, or that your device clock is correct, or it can happen on custom ROM.
  public static func settingsTroubleshootTestFcmFailedServiceNotAvailable(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_fcm_failed_service_not_available", String(describing: p1))
  }
  /// [%1$@]
  /// This error is out of control of %@ and according to Google, this error indicates that the device has too many apps registered with FCM. The error only occurs in cases where there are extreme numbers of apps, so it should not affect the average user.
  public static func settingsTroubleshootTestFcmFailedTooManyRegistration(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_fcm_failed_too_many_registration", String(describing: p1))
  }
  /// FCM token successfully retrieved:
  /// %1$@
  public static func settingsTroubleshootTestFcmSuccess(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_fcm_success", String(describing: p1))
  }
  /// Firebase Token
  public static var settingsTroubleshootTestFcmTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_fcm_title") }
  /// Please click on the notification. If you do not see the notification, please check the system settings.
  public static var settingsTroubleshootTestNotificationNotice: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_notification_notice") }
  /// The notification has been clicked!
  public static var settingsTroubleshootTestNotificationNotificationClicked: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_notification_notification_clicked") }
  /// Notification Display
  public static var settingsTroubleshootTestNotificationTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_notification_title") }
  /// %@ uses Google Play Services to deliver push messages but it doesn’t seem to be configured correctly:
  /// %1$@
  public static func settingsTroubleshootTestPlayServicesFailed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_play_services_failed", String(describing: p1))
  }
  /// Fix Play Services
  public static var settingsTroubleshootTestPlayServicesQuickfix: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_play_services_quickfix") }
  /// Google Play Services APK is available and up-to-date.
  public static var settingsTroubleshootTestPlayServicesSuccess: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_play_services_success") }
  /// Play Services Check
  public static var settingsTroubleshootTestPlayServicesTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_play_services_title") }
  /// Failed to receive push. Solution could be to reinstall the application.
  public static var settingsTroubleshootTestPushLoopFailed: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_push_loop_failed") }
  /// The application is receiving PUSH
  public static var settingsTroubleshootTestPushLoopSuccess: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_push_loop_success") }
  /// Test Push
  public static var settingsTroubleshootTestPushLoopTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_push_loop_title") }
  /// The application is waiting for the PUSH
  public static var settingsTroubleshootTestPushLoopWaitingForPush: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_push_loop_waiting_for_push") }
  /// You are viewing the notification! Click me!
  public static var settingsTroubleshootTestPushNotificationContent: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_push_notification_content") }
  /// The service will not start when the device is restarted, you will not receive notifications until %@ has been opened once.
  public static func settingsTroubleshootTestServiceBootFailed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_service_boot_failed", String(describing: p1))
  }
  /// Enable Start on boot
  public static var settingsTroubleshootTestServiceBootQuickfix: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_service_boot_quickfix") }
  /// Service will start when the device is restarted.
  public static var settingsTroubleshootTestServiceBootSuccess: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_service_boot_success") }
  /// Start on boot
  public static var settingsTroubleshootTestServiceBootTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_service_boot_title") }
  /// Notifications are disabled in the system settings.
  /// Please check system settings.
  public static var settingsTroubleshootTestSystemSettingsFailed: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_system_settings_failed") }
  /// Notifications are enabled in the system settings.
  public static var settingsTroubleshootTestSystemSettingsSuccess: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_system_settings_success") }
  /// System Settings.
  public static var settingsTroubleshootTestSystemSettingsTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_system_settings_title") }
  /// Failed to register FCM token to homeserver:
  /// %1$@
  public static func settingsTroubleshootTestTokenRegistrationFailed(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_troubleshoot_test_token_registration_failed", String(describing: p1))
  }
  /// Register token
  public static var settingsTroubleshootTestTokenRegistrationQuickFix: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_token_registration_quick_fix") }
  /// FCM token successfully registered to homeserver.
  public static var settingsTroubleshootTestTokenRegistrationSuccess: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_token_registration_success") }
  /// Token Registration
  public static var settingsTroubleshootTestTokenRegistrationTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_test_token_registration_title") }
  /// Troubleshoot
  public static var settingsTroubleshootTitle: String { return ElementL10n.tr("Localizable", "settings_troubleshoot_title") }
  /// Show all messages from %@?
  public static func settingsUnignoreUser(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "settings_unignore_user", String(describing: p1))
  }
  /// User interface
  public static var settingsUserInterface: String { return ElementL10n.tr("Localizable", "settings_user_interface") }
  /// User settings
  public static var settingsUserSettings: String { return ElementL10n.tr("Localizable", "settings_user_settings") }
  /// Version
  public static var settingsVersion: String { return ElementL10n.tr("Localizable", "settings_version") }
  /// Vibrate when mentioning a user
  public static var settingsVibrateOnMention: String { return ElementL10n.tr("Localizable", "settings_vibrate_on_mention") }
  /// When rooms are upgraded
  public static var settingsWhenRoomsAreUpgraded: String { return ElementL10n.tr("Localizable", "settings_when_rooms_are_upgraded") }
  /// Share by text
  public static var shareByText: String { return ElementL10n.tr("Localizable", "share_by_text") }
  /// Do you want to send this attachment to %1$@?
  public static func shareConfirmRoom(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "share_confirm_room", String(describing: p1))
  }
  /// Join my space %1$@ %2$@
  public static func shareSpaceLinkMessage(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "share_space_link_message", String(describing: p1), String(describing: p2))
  }
  /// Share
  public static var shareWithoutVerifyingShortLabel: String { return ElementL10n.tr("Localizable", "share_without_verifying_short_label") }
  /// The room has been left!
  public static var shortcutDisabledReasonRoomLeft: String { return ElementL10n.tr("Localizable", "shortcut_disabled_reason_room_left") }
  /// The session has been signed out!
  public static var shortcutDisabledReasonSignOut: String { return ElementL10n.tr("Localizable", "shortcut_disabled_reason_sign_out") }
  /// Show advanced
  public static var showAdvanced: String { return ElementL10n.tr("Localizable", "show_advanced") }
  /// Backing up keys…
  public static var signOutBottomSheetBackingUpKeys: String { return ElementL10n.tr("Localizable", "sign_out_bottom_sheet_backing_up_keys") }
  /// I don’t want my encrypted messages
  public static var signOutBottomSheetDontWantSecureMessages: String { return ElementL10n.tr("Localizable", "sign_out_bottom_sheet_dont_want_secure_messages") }
  /// Key backup in progress. If you sign out now you’ll lose access to your encrypted messages.
  public static var signOutBottomSheetWarningBackingUp: String { return ElementL10n.tr("Localizable", "sign_out_bottom_sheet_warning_backing_up") }
  /// Secure Key Backup should be active on all of your sessions to avoid losing access to your encrypted messages.
  public static var signOutBottomSheetWarningBackupNotActive: String { return ElementL10n.tr("Localizable", "sign_out_bottom_sheet_warning_backup_not_active") }
  /// You’ll lose your encrypted messages if you sign out now
  public static var signOutBottomSheetWarningNoBackup: String { return ElementL10n.tr("Localizable", "sign_out_bottom_sheet_warning_no_backup") }
  /// You’ll lose access to your encrypted messages unless you back up your keys before signing out.
  public static var signOutBottomSheetWillLoseSecureMessages: String { return ElementL10n.tr("Localizable", "sign_out_bottom_sheet_will_lose_secure_messages") }
  /// It can be due to various reasons:
  /// 
  /// • You’ve changed your password on another session.
  /// 
  /// • You have deleted this session from another session.
  /// 
  /// • The administrator of your server has invalidated your access for security reason.
  public static var signedOutNotice: String { return ElementL10n.tr("Localizable", "signed_out_notice") }
  /// Sign in again
  public static var signedOutSubmit: String { return ElementL10n.tr("Localizable", "signed_out_submit") }
  /// You’re signed out
  public static var signedOutTitle: String { return ElementL10n.tr("Localizable", "signed_out_title") }
  /// Skip for now
  public static var skipForNow: String { return ElementL10n.tr("Localizable", "skip_for_now") }
  /// Small
  public static var small: String { return ElementL10n.tr("Localizable", "small") }
  /// Clear all data currently stored on this device?
  /// Sign in again to access your account data and messages.
  public static var softLogoutClearDataDialogContent: String { return ElementL10n.tr("Localizable", "soft_logout_clear_data_dialog_content") }
  /// You’ll lose access to secure messages unless you sign in to recover your encryption keys.
  public static var softLogoutClearDataDialogE2eWarningContent: String { return ElementL10n.tr("Localizable", "soft_logout_clear_data_dialog_e2e_warning_content") }
  /// Clear data
  public static var softLogoutClearDataDialogTitle: String { return ElementL10n.tr("Localizable", "soft_logout_clear_data_dialog_title") }
  /// Warning: Your personal data (including encryption keys) is still stored on this device.
  /// 
  /// Clear it if you’re finished using this device, or want to sign in to another account.
  public static var softLogoutClearDataNotice: String { return ElementL10n.tr("Localizable", "soft_logout_clear_data_notice") }
  /// Clear all data
  public static var softLogoutClearDataSubmit: String { return ElementL10n.tr("Localizable", "soft_logout_clear_data_submit") }
  /// Clear personal data
  public static var softLogoutClearDataTitle: String { return ElementL10n.tr("Localizable", "soft_logout_clear_data_title") }
  /// Sign in to recover encryption keys stored exclusively on this device. You need them to read all of your secure messages on any device.
  public static var softLogoutSigninE2eWarningNotice: String { return ElementL10n.tr("Localizable", "soft_logout_signin_e2e_warning_notice") }
  /// Your homeserver (%1$@) admin has signed you out of your account %2$@ (%3$@).
  public static func softLogoutSigninNotice(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "soft_logout_signin_notice", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Password
  public static var softLogoutSigninPasswordHint: String { return ElementL10n.tr("Localizable", "soft_logout_signin_password_hint") }
  /// Sign in
  public static var softLogoutSigninSubmit: String { return ElementL10n.tr("Localizable", "soft_logout_signin_submit") }
  /// Sign in
  public static var softLogoutSigninTitle: String { return ElementL10n.tr("Localizable", "soft_logout_signin_title") }
  /// The current session is for user %1$@ and you provide credentials for user %2$@. This is not supported by %@.
  /// Please first clear data, then sign in again on another account.
  public static func softLogoutSsoNotSameUserError(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "soft_logout_sso_not_same_user_error", String(describing: p1), String(describing: p2))
  }
  /// You’re signed out
  public static var softLogoutTitle: String { return ElementL10n.tr("Localizable", "soft_logout_title") }
  /// Headset
  public static var soundDeviceHeadset: String { return ElementL10n.tr("Localizable", "sound_device_headset") }
  /// Phone
  public static var soundDevicePhone: String { return ElementL10n.tr("Localizable", "sound_device_phone") }
  /// Speaker
  public static var soundDeviceSpeaker: String { return ElementL10n.tr("Localizable", "sound_device_speaker") }
  /// Wireless Headset
  public static var soundDeviceWirelessHeadset: String { return ElementL10n.tr("Localizable", "sound_device_wireless_headset") }
  /// Add rooms
  public static var spaceAddChildTitle: String { return ElementL10n.tr("Localizable", "space_add_child_title") }
  /// Add existing rooms and space
  public static var spaceAddExistingRooms: String { return ElementL10n.tr("Localizable", "space_add_existing_rooms") }
  /// Add existing rooms
  public static var spaceAddExistingRoomsOnly: String { return ElementL10n.tr("Localizable", "space_add_existing_rooms_only") }
  /// Add existing spaces
  public static var spaceAddExistingSpaces: String { return ElementL10n.tr("Localizable", "space_add_existing_spaces") }
  /// Add a space to any space you manage.
  public static var spaceAddSpaceToAnySpaceYouManage: String { return ElementL10n.tr("Localizable", "space_add_space_to_any_space_you_manage") }
  /// Explore rooms
  public static var spaceExploreActivityTitle: String { return ElementL10n.tr("Localizable", "space_explore_activity_title") }
  /// Some results may be hidden because they’re private and you need an invite to them.
  public static var spaceExploreFilterNoResultDescription: String { return ElementL10n.tr("Localizable", "space_explore_filter_no_result_description") }
  /// No results found
  public static var spaceExploreFilterNoResultTitle: String { return ElementL10n.tr("Localizable", "space_explore_filter_no_result_title") }
  /// You're the only admin of this space. Leaving it will mean no one has control over it.
  public static var spaceLeavePromptMsgAsAdmin: String { return ElementL10n.tr("Localizable", "space_leave_prompt_msg_as_admin") }
  /// You are the only person here. If you leave, no one will be able to join in the future, including you.
  public static var spaceLeavePromptMsgOnlyYou: String { return ElementL10n.tr("Localizable", "space_leave_prompt_msg_only_you") }
  /// You won't be able to rejoin unless you are re-invited.
  public static var spaceLeavePromptMsgPrivate: String { return ElementL10n.tr("Localizable", "space_leave_prompt_msg_private") }
  /// Are you sure you want to leave %@?
  public static func spaceLeavePromptMsgWithName(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "space_leave_prompt_msg_with_name", String(describing: p1))
  }
  /// Leave all
  public static var spaceLeaveRadioButtonAll: String { return ElementL10n.tr("Localizable", "space_leave_radio_button_all") }
  /// Leave none
  public static var spaceLeaveRadioButtonNone: String { return ElementL10n.tr("Localizable", "space_leave_radio_button_none") }
  /// Things in this space
  public static var spaceLeaveRadioButtonsTitle: String { return ElementL10n.tr("Localizable", "space_leave_radio_buttons_title") }
  /// Spaces are a new way to group rooms and people. Create a space to get started.
  public static var spaceListEmptyMessage: String { return ElementL10n.tr("Localizable", "space_list_empty_message") }
  /// No spaces yet.
  public static var spaceListEmptyTitle: String { return ElementL10n.tr("Localizable", "space_list_empty_title") }
  /// Manage rooms and spaces
  public static var spaceManageRoomsAndSpaces: String { return ElementL10n.tr("Localizable", "space_manage_rooms_and_spaces") }
  /// Mark as not suggested
  public static var spaceMarkAsNotSuggested: String { return ElementL10n.tr("Localizable", "space_mark_as_not_suggested") }
  /// Mark as suggested
  public static var spaceMarkAsSuggested: String { return ElementL10n.tr("Localizable", "space_mark_as_suggested") }
  /// Banning user will remove them from this space and prevent them from joining again.
  public static var spaceParticipantsBanPromptMsg: String { return ElementL10n.tr("Localizable", "space_participants_ban_prompt_msg") }
  /// The user will be removed from this space.
  /// 
  /// To prevent them from joining again, you should ban them instead.
  public static var spaceParticipantsRemovePromptMsg: String { return ElementL10n.tr("Localizable", "space_participants_remove_prompt_msg") }
  /// Unbanning user will allow them to join the space again.
  public static var spaceParticipantsUnbanPromptMsg: String { return ElementL10n.tr("Localizable", "space_participants_unban_prompt_msg") }
  /// Plural format key: "%#@VARIABLE@"
  public static func spacePeopleYouKnow(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "space_people_you_know", p1)
  }
  /// Select the roles required to change various parts of this space
  public static var spacePermissionsNotice: String { return ElementL10n.tr("Localizable", "space_permissions_notice") }
  /// You don't have permission to update the roles required to change various parts of this space
  public static var spacePermissionsNoticeReadOnly: String { return ElementL10n.tr("Localizable", "space_permissions_notice_read_only") }
  /// See and managed addresses of this space.
  public static var spaceSettingsAliasSubtitle: String { return ElementL10n.tr("Localizable", "space_settings_alias_subtitle") }
  /// Space addresses
  public static var spaceSettingsAliasTitle: String { return ElementL10n.tr("Localizable", "space_settings_alias_title") }
  /// Manage rooms
  public static var spaceSettingsManageRooms: String { return ElementL10n.tr("Localizable", "space_settings_manage_rooms") }
  /// View and update the roles required to change various parts of the space.
  public static var spaceSettingsPermissionsSubtitle: String { return ElementL10n.tr("Localizable", "space_settings_permissions_subtitle") }
  /// Space permissions
  public static var spaceSettingsPermissionsTitle: String { return ElementL10n.tr("Localizable", "space_settings_permissions_title") }
  /// Suggested
  public static var spaceSuggested: String { return ElementL10n.tr("Localizable", "space_suggested") }
  /// Private
  public static var spaceTypePrivate: String { return ElementL10n.tr("Localizable", "space_type_private") }
  /// Invite only, best for yourself or teams
  public static var spaceTypePrivateDesc: String { return ElementL10n.tr("Localizable", "space_type_private_desc") }
  /// Public
  public static var spaceTypePublic: String { return ElementL10n.tr("Localizable", "space_type_public") }
  /// Open to anyone, best for communities
  public static var spaceTypePublicDesc: String { return ElementL10n.tr("Localizable", "space_type_public_desc") }
  /// Space you know that contain this room
  public static var spaceYouKnowThatContainsThisRoom: String { return ElementL10n.tr("Localizable", "space_you_know_that_contains_this_room") }
  /// Spaces
  public static var spaces: String { return ElementL10n.tr("Localizable", "spaces") }
  /// Spaces are a new way to group rooms and people.
  public static var spacesBetaWelcomeToSpacesDesc: String { return ElementL10n.tr("Localizable", "spaces_beta_welcome_to_spaces_desc") }
  /// Feeling experimental?
  /// You can add existing spaces to a space.
  public static var spacesFeelingExperimentalSubspace: String { return ElementL10n.tr("Localizable", "spaces_feeling_experimental_subspace") }
  /// Spaces
  public static var spacesHeader: String { return ElementL10n.tr("Localizable", "spaces_header") }
  /// Please contact your homeserver admin for further information
  public static var spacesNoServerSupportDescription: String { return ElementL10n.tr("Localizable", "spaces_no_server_support_description") }
  /// It looks like your homeserver does not support Spaces yet
  public static var spacesNoServerSupportTitle: String { return ElementL10n.tr("Localizable", "spaces_no_server_support_title") }
  /// Spaces which can access
  public static var spacesWhichCanAccess: String { return ElementL10n.tr("Localizable", "spaces_which_can_access") }
  /// Spoiler
  public static var spoiler: String { return ElementL10n.tr("Localizable", "spoiler") }
  /// If the server administrator has said that this is expected, ensure that the fingerprint below matches the fingerprint provided by them.
  public static var sslCertNewAccountExpl: String { return ElementL10n.tr("Localizable", "ssl_cert_new_account_expl") }
  /// This could mean that someone is maliciously intercepting your traffic, or that your phone does not trust the certificate provided by the remote server.
  public static var sslCertNotTrust: String { return ElementL10n.tr("Localizable", "ssl_cert_not_trust") }
  /// Could not verify identity of remote server.
  public static var sslCouldNotVerify: String { return ElementL10n.tr("Localizable", "ssl_could_not_verify") }
  /// Do not trust
  public static var sslDoNotTrust: String { return ElementL10n.tr("Localizable", "ssl_do_not_trust") }
  /// The certificate has changed from a previously trusted one to one that is not trusted. The server may have renewed its certificate. Contact the server administrator for the expected fingerprint.
  public static var sslExpectedExistingExpl: String { return ElementL10n.tr("Localizable", "ssl_expected_existing_expl") }
  /// Fingerprint (%@):
  public static func sslFingerprintHash(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "ssl_fingerprint_hash", String(describing: p1))
  }
  /// Logout
  public static var sslLogoutAccount: String { return ElementL10n.tr("Localizable", "ssl_logout_account") }
  /// Only accept the certificate if the server administrator has published a fingerprint that matches the one above.
  public static var sslOnlyAccept: String { return ElementL10n.tr("Localizable", "ssl_only_accept") }
  /// Ignore
  public static var sslRemainOffline: String { return ElementL10n.tr("Localizable", "ssl_remain_offline") }
  /// Trust
  public static var sslTrust: String { return ElementL10n.tr("Localizable", "ssl_trust") }
  /// The certificate has changed from one that was trusted by your phone. This is HIGHLY UNUSUAL. It is recommended that you DO NOT ACCEPT this new certificate.
  public static var sslUnexpectedExistingExpl: String { return ElementL10n.tr("Localizable", "ssl_unexpected_existing_expl") }
  /// Start Chat
  public static var startChat: String { return ElementL10n.tr("Localizable", "start_chat") }
  /// Start Chatting
  public static var startChatting: String { return ElementL10n.tr("Localizable", "start_chatting") }
  /// Start verification
  public static var startVerification: String { return ElementL10n.tr("Localizable", "start_verification") }
  /// Start Video Call
  public static var startVideoCall: String { return ElementL10n.tr("Localizable", "start_video_call") }
  /// Are you sure that you want to start a video call?
  public static var startVideoCallPromptMsg: String { return ElementL10n.tr("Localizable", "start_video_call_prompt_msg") }
  /// Start Voice Call
  public static var startVoiceCall: String { return ElementL10n.tr("Localizable", "start_voice_call") }
  /// Are you sure that you want to start a voice call?
  public static var startVoiceCallPromptMsg: String { return ElementL10n.tr("Localizable", "start_voice_call_prompt_msg") }
  /// Suggested Rooms
  public static var suggestedHeader: String { return ElementL10n.tr("Localizable", "suggested_header") }
  /// System Alerts
  public static var systemAlertsHeader: String { return ElementL10n.tr("Localizable", "system_alerts_header") }
  /// System Default
  public static var systemTheme: String { return ElementL10n.tr("Localizable", "system_theme") }
  /// Tap to edit spaces
  public static var tapToEditSpaces: String { return ElementL10n.tr("Localizable", "tap_to_edit_spaces") }
  /// Be discoverable by others
  public static var termsDescriptionForIdentityServer: String { return ElementL10n.tr("Localizable", "terms_description_for_identity_server") }
  /// Use Bots, bridges, widgets and sticker packs
  public static var termsDescriptionForIntegrationManager: String { return ElementL10n.tr("Localizable", "terms_description_for_integration_manager") }
  /// Terms of Service
  public static var termsOfService: String { return ElementL10n.tr("Localizable", "terms_of_service") }
  /// This invite to this room was sent to %@ which is not associated with your account
  public static func thisInviteToThisRoomWasSent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "this_invite_to_this_room_was_sent", String(describing: p1))
  }
  /// This invite to this space was sent to %@ which is not associated with your account
  public static func thisInviteToThisSpaceWasSent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "this_invite_to_this_space_was_sent", String(describing: p1))
  }
  /// This is the beginning of your direct message history with %@.
  public static func thisIsTheBeginningOfDm(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "this_is_the_beginning_of_dm", String(describing: p1))
  }
  /// This is the beginning of %@.
  public static func thisIsTheBeginningOfRoom(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "this_is_the_beginning_of_room", String(describing: p1))
  }
  /// This is the beginning of this conversation.
  public static var thisIsTheBeginningOfRoomNoName: String { return ElementL10n.tr("Localizable", "this_is_the_beginning_of_room_no_name") }
  /// This space has no rooms
  public static var thisSpaceHasNoRooms: String { return ElementL10n.tr("Localizable", "this_space_has_no_rooms") }
  /// Some rooms may be hidden because they’re private and you need an invite.
  public static var thisSpaceHasNoRoomsAdmin: String { return ElementL10n.tr("Localizable", "this_space_has_no_rooms_admin") }
  /// Some rooms may be hidden because they’re private and you need an invite.
  /// You don’t have permission to add rooms.
  public static var thisSpaceHasNoRoomsNotAdmin: String { return ElementL10n.tr("Localizable", "this_space_has_no_rooms_not_admin") }
  /// Tip: Long tap a message and use “%@”.
  public static func threadListEmptyNotice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "thread_list_empty_notice", String(describing: p1))
  }
  /// Threads help keep your conversations on-topic and easy to track.
  public static var threadListEmptySubtitle: String { return ElementL10n.tr("Localizable", "thread_list_empty_subtitle") }
  /// Keep discussions organised with threads
  public static var threadListEmptyTitle: String { return ElementL10n.tr("Localizable", "thread_list_empty_title") }
  /// Shows all threads from current room
  public static var threadListModalAllThreadsSubtitle: String { return ElementL10n.tr("Localizable", "thread_list_modal_all_threads_subtitle") }
  /// All Threads
  public static var threadListModalAllThreadsTitle: String { return ElementL10n.tr("Localizable", "thread_list_modal_all_threads_title") }
  /// Shows all threads you’ve participated in
  public static var threadListModalMyThreadsSubtitle: String { return ElementL10n.tr("Localizable", "thread_list_modal_my_threads_subtitle") }
  /// My Threads
  public static var threadListModalMyThreadsTitle: String { return ElementL10n.tr("Localizable", "thread_list_modal_my_threads_title") }
  /// Filter
  public static var threadListModalTitle: String { return ElementL10n.tr("Localizable", "thread_list_modal_title") }
  /// Threads
  public static var threadListTitle: String { return ElementL10n.tr("Localizable", "thread_list_title") }
  /// Thread
  public static var threadTimelineTitle: String { return ElementL10n.tr("Localizable", "thread_timeline_title") }
  /// Threads help keep your conversations on-topic and easy to track. %@Enabling threads will refresh the app. This may take longer for some accounts.
  public static func threadsBetaEnableNoticeMessage(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "threads_beta_enable_notice_message", String(describing: p1))
  }
  /// Threads Beta
  public static var threadsBetaEnableNoticeTitle: String { return ElementL10n.tr("Localizable", "threads_beta_enable_notice_title") }
  /// Your homeserver does not currently support threads, so this feature may be unreliable. Some threaded messages may not be reliably available. %@Do you want to enable threads anyway?
  public static func threadsLabsEnableNoticeMessage(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "threads_labs_enable_notice_message", String(describing: p1))
  }
  /// Threads Beta
  public static var threadsLabsEnableNoticeTitle: String { return ElementL10n.tr("Localizable", "threads_labs_enable_notice_title") }
  /// We’re getting closer to releasing a public Beta for Threads.
  /// 
  /// As we prepare for it, we need to make some changes: threads created before this point will be displayed as regular replies.
  /// 
  /// This will be a one-off transition as Threads are now part of the Matrix specification.
  public static var threadsNoticeMigrationMessage: String { return ElementL10n.tr("Localizable", "threads_notice_migration_message") }
  /// Threads Approaching Beta 🎉
  public static var threadsNoticeMigrationTitle: String { return ElementL10n.tr("Localizable", "threads_notice_migration_title") }
  /// Revoke invite to %1$@?
  public static func threePidRevokeInviteDialogContent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "three_pid_revoke_invite_dialog_content", String(describing: p1))
  }
  /// Revoke invite
  public static var threePidRevokeInviteDialogTitle: String { return ElementL10n.tr("Localizable", "three_pid_revoke_invite_dialog_title") }
  /// %1$@, %2$@ and %3$@ read
  public static func threeUsersRead(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return ElementL10n.tr("Localizable", "three_users_read", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// h
  public static var timeUnitHourShort: String { return ElementL10n.tr("Localizable", "time_unit_hour_short") }
  /// min
  public static var timeUnitMinuteShort: String { return ElementL10n.tr("Localizable", "time_unit_minute_short") }
  /// sec
  public static var timeUnitSecondShort: String { return ElementL10n.tr("Localizable", "time_unit_second_short") }
  /// Sorry, this room has not been found.
  /// Please retry later.%@
  public static func timelineErrorRoomNotFound(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "timeline_error_room_not_found", String(describing: p1))
  }
  /// Unread messages
  public static var timelineUnreadMessages: String { return ElementL10n.tr("Localizable", "timeline_unread_messages") }
  /// Tiny
  public static var tiny: String { return ElementL10n.tr("Localizable", "tiny") }
  /// Bug report
  public static var titleActivityBugReport: String { return ElementL10n.tr("Localizable", "title_activity_bug_report") }
  /// Send a sticker
  public static var titleActivityChooseSticker: String { return ElementL10n.tr("Localizable", "title_activity_choose_sticker") }
  /// Reactions
  public static var titleActivityEmojiReactionPicker: String { return ElementL10n.tr("Localizable", "title_activity_emoji_reaction_picker") }
  /// Use Key Backup
  public static var titleActivityKeysBackupRestore: String { return ElementL10n.tr("Localizable", "title_activity_keys_backup_restore") }
  /// Key Backup
  public static var titleActivityKeysBackupSetup: String { return ElementL10n.tr("Localizable", "title_activity_keys_backup_setup") }
  /// Settings
  public static var titleActivitySettings: String { return ElementL10n.tr("Localizable", "title_activity_settings") }
  /// Too many errors, you've been logged out
  public static var tooManyPinFailures: String { return ElementL10n.tr("Localizable", "too_many_pin_failures") }
  /// Open contacts
  public static var tooltipAttachmentContact: String { return ElementL10n.tr("Localizable", "tooltip_attachment_contact") }
  /// Upload file
  public static var tooltipAttachmentFile: String { return ElementL10n.tr("Localizable", "tooltip_attachment_file") }
  /// Send images and videos
  public static var tooltipAttachmentGallery: String { return ElementL10n.tr("Localizable", "tooltip_attachment_gallery") }
  /// Share location
  public static var tooltipAttachmentLocation: String { return ElementL10n.tr("Localizable", "tooltip_attachment_location") }
  /// Open camera
  public static var tooltipAttachmentPhoto: String { return ElementL10n.tr("Localizable", "tooltip_attachment_photo") }
  /// Create poll
  public static var tooltipAttachmentPoll: String { return ElementL10n.tr("Localizable", "tooltip_attachment_poll") }
  /// Send sticker
  public static var tooltipAttachmentSticker: String { return ElementL10n.tr("Localizable", "tooltip_attachment_sticker") }
  /// Topic: 
  public static var topicPrefix: String { return ElementL10n.tr("Localizable", "topic_prefix") }
  /// Trusted
  public static var trusted: String { return ElementL10n.tr("Localizable", "trusted") }
  /// Plural format key: "%#@VARIABLE@"
  public static func twoAndSomeOthersRead(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "two_and_some_others_read", p1)
  }
  /// %1$@ and %2$@ read
  public static func twoUsersRead(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "two_users_read", String(describing: p1), String(describing: p2))
  }
  /// Unable to send message
  public static var unableToSendMessage: String { return ElementL10n.tr("Localizable", "unable_to_send_message") }
  /// Unencrypted
  public static var unencrypted: String { return ElementL10n.tr("Localizable", "unencrypted") }
  /// Unexpected error
  public static var unexpectedError: String { return ElementL10n.tr("Localizable", "unexpected_error") }
  /// Background synchronization
  public static var unifiedpushDistributorBackgroundSync: String { return ElementL10n.tr("Localizable", "unifiedpush_distributor_background_sync") }
  /// Google Services
  public static var unifiedpushDistributorFcmFallback: String { return ElementL10n.tr("Localizable", "unifiedpush_distributor_fcm_fallback") }
  /// Choose how to receive notifications
  public static var unifiedpushGetdistributorsDialogTitle: String { return ElementL10n.tr("Localizable", "unifiedpush_getdistributors_dialog_title") }
  /// Unignore
  public static var unignore: String { return ElementL10n.tr("Localizable", "unignore") }
  /// The link was malformed
  public static var universalLinkMalformed: String { return ElementL10n.tr("Localizable", "universal_link_malformed") }
  /// Sorry, an error occurred
  public static var unknownError: String { return ElementL10n.tr("Localizable", "unknown_error") }
  /// Unnamed Room
  public static var unnamedRoom: String { return ElementL10n.tr("Localizable", "unnamed_room") }
  /// Unrecognized command: %@
  public static func unrecognizedCommand(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "unrecognized_command", String(describing: p1))
  }
  /// Updating your data…
  public static var updatingYourData: String { return ElementL10n.tr("Localizable", "updating_your_data") }
  /// Upgrade
  public static var upgrade: String { return ElementL10n.tr("Localizable", "upgrade") }
  /// Upgrade private room
  public static var upgradePrivateRoom: String { return ElementL10n.tr("Localizable", "upgrade_private_room") }
  /// Upgrade public room
  public static var upgradePublicRoom: String { return ElementL10n.tr("Localizable", "upgrade_public_room") }
  /// You'll upgrade this room from %1$@ to %2$@.
  public static func upgradePublicRoomFromTo(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "upgrade_public_room_from_to", String(describing: p1), String(describing: p2))
  }
  /// Upgrade Required
  public static var upgradeRequired: String { return ElementL10n.tr("Localizable", "upgrade_required") }
  /// Automatically invite users
  public static var upgradeRoomAutoInvite: String { return ElementL10n.tr("Localizable", "upgrade_room_auto_invite") }
  /// Anyone in %@ will be able to find and join this room - no need to manually invite everyone. You’ll be able to change this in room settings anytime.
  public static func upgradeRoomForRestricted(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "upgrade_room_for_restricted", String(describing: p1))
  }
  /// Anyone in a parent space will be able to find and join this room - no need to manually invite everyone. You’ll be able to change this in room settings anytime.
  public static var upgradeRoomForRestrictedNoParam: String { return ElementL10n.tr("Localizable", "upgrade_room_for_restricted_no_param") }
  /// Please note upgrading will make a new version of the room. All current messages will stay in this archived room.
  public static var upgradeRoomForRestrictedNote: String { return ElementL10n.tr("Localizable", "upgrade_room_for_restricted_note") }
  /// You need permission to upgrade a room
  public static var upgradeRoomNoPowerToManage: String { return ElementL10n.tr("Localizable", "upgrade_room_no_power_to_manage") }
  /// Automatically update space parent
  public static var upgradeRoomUpdateParentSpace: String { return ElementL10n.tr("Localizable", "upgrade_room_update_parent_space") }
  /// Upgrading a room is an advanced action and is usually recommended when a room is unstable due to bugs, missing features or security vulnerabilities.
  /// This usually only affects how the room is processed on the server.
  public static var upgradeRoomWarning: String { return ElementL10n.tr("Localizable", "upgrade_room_warning") }
  /// Encryption upgrade available
  public static var upgradeSecurity: String { return ElementL10n.tr("Localizable", "upgrade_security") }
  /// There are no files in this room
  public static var uploadsFilesNoResult: String { return ElementL10n.tr("Localizable", "uploads_files_no_result") }
  /// %1$@ at %2$@
  public static func uploadsFilesSubtitle(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "uploads_files_subtitle", String(describing: p1), String(describing: p2))
  }
  /// FILES
  public static var uploadsFilesTitle: String { return ElementL10n.tr("Localizable", "uploads_files_title") }
  /// There are no media in this room
  public static var uploadsMediaNoResult: String { return ElementL10n.tr("Localizable", "uploads_media_no_result") }
  /// MEDIA
  public static var uploadsMediaTitle: String { return ElementL10n.tr("Localizable", "uploads_media_title") }
  /// Use as default and do not ask again
  public static var useAsDefaultAndDoNotAskAgain: String { return ElementL10n.tr("Localizable", "use_as_default_and_do_not_ask_again") }
  /// Use File
  public static var useFile: String { return ElementL10n.tr("Localizable", "use_file") }
  /// Use the latest %@ on your other devices:
  public static func useLatestApp(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "use_latest_app", String(describing: p1))
  }
  /// Use the latest %@ on your other devices, %@ Web, %@ Desktop, %@ iOS, %@ for Android, or another cross-signing capable Matrix client
  public static func useOtherSessionContentDescription(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any, _ p5: Any) -> String {
    return ElementL10n.tr("Localizable", "use_other_session_content_description", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4), String(describing: p5))
  }
  /// Use Recovery Key
  public static var useRecoveryKey: String { return ElementL10n.tr("Localizable", "use_recovery_key") }
  /// Share this code with people so they can scan it to add you and start chatting.
  public static var userCodeInfoText: String { return ElementL10n.tr("Localizable", "user_code_info_text") }
  /// My code
  public static var userCodeMyCode: String { return ElementL10n.tr("Localizable", "user_code_my_code") }
  /// Scan a QR code
  public static var userCodeScan: String { return ElementL10n.tr("Localizable", "user_code_scan") }
  /// Share my code
  public static var userCodeShare: String { return ElementL10n.tr("Localizable", "user_code_share") }
  /// Search by name, ID or mail
  public static var userDirectorySearchHint2: String { return ElementL10n.tr("Localizable", "user_directory_search_hint_2") }
  /// %@ invites you
  public static func userInvitesYou(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "user_invites_you", String(describing: p1))
  }
  /// Username
  public static var username: String { return ElementL10n.tr("Localizable", "username") }
  /// Verification Cancelled
  public static var verificationCancelled: String { return ElementL10n.tr("Localizable", "verification_cancelled") }
  /// Use a Recovery Passphrase or Key
  public static var verificationCannotAccessOtherSession: String { return ElementL10n.tr("Localizable", "verification_cannot_access_other_session") }
  /// Compare the code with the one displayed on the other user's screen.
  public static var verificationCodeNotice: String { return ElementL10n.tr("Localizable", "verification_code_notice") }
  /// One of the following may be compromised:
  /// 
  ///    - Your homeserver
  ///    - The homeserver the user you’re verifying is connected to
  ///    - Yours, or the other users’ internet connection
  ///    - Yours, or the other users’ device
  public static var verificationConclusionCompromised: String { return ElementL10n.tr("Localizable", "verification_conclusion_compromised") }
  /// Not secure
  public static var verificationConclusionNotSecure: String { return ElementL10n.tr("Localizable", "verification_conclusion_not_secure") }
  /// Messages with this user are end-to-end encrypted and can't be read by third parties.
  public static var verificationConclusionOkNotice: String { return ElementL10n.tr("Localizable", "verification_conclusion_ok_notice") }
  /// Your new session is now verified. It has access to your encrypted messages, and other users will see it as trusted.
  public static var verificationConclusionOkSelfNotice: String { return ElementL10n.tr("Localizable", "verification_conclusion_ok_self_notice") }
  /// Untrusted sign in
  public static var verificationConclusionWarning: String { return ElementL10n.tr("Localizable", "verification_conclusion_warning") }
  /// Compare the unique emoji, ensuring they appear in the same order.
  public static var verificationEmojiNotice: String { return ElementL10n.tr("Localizable", "verification_emoji_notice") }
  /// Verify by comparing emojis
  public static var verificationNoScanEmojiTitle: String { return ElementL10n.tr("Localizable", "verification_no_scan_emoji_title") }
  /// Use an existing session to verify this one, granting it access to encrypted messages.
  public static var verificationOpenOtherToVerify: String { return ElementL10n.tr("Localizable", "verification_open_other_to_verify") }
  /// %1$@ (%2$@) signed in using a new session:
  public static func verificationProfileDeviceNewSigning(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "verification_profile_device_new_signing", String(describing: p1), String(describing: p2))
  }
  /// Until this user trusts this session, messages sent to and from it are labelled with warnings. Alternatively, you can manually verify it.
  public static var verificationProfileDeviceUntrustInfo: String { return ElementL10n.tr("Localizable", "verification_profile_device_untrust_info") }
  /// This session is trusted for secure messaging because %1$@ (%2$@) verified it:
  public static func verificationProfileDeviceVerifiedBecause(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "verification_profile_device_verified_because", String(describing: p1), String(describing: p2))
  }
  /// Verified
  public static var verificationProfileVerified: String { return ElementL10n.tr("Localizable", "verification_profile_verified") }
  /// Verify
  public static var verificationProfileVerify: String { return ElementL10n.tr("Localizable", "verification_profile_verify") }
  /// Warning
  public static var verificationProfileWarning: String { return ElementL10n.tr("Localizable", "verification_profile_warning") }
  /// Verification Request
  public static var verificationRequest: String { return ElementL10n.tr("Localizable", "verification_request") }
  /// To be secure, verify %@ by checking a one-time code.
  public static func verificationRequestNotice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "verification_request_notice", String(describing: p1))
  }
  /// %@ accepted
  public static func verificationRequestOtherAccepted(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "verification_request_other_accepted", String(describing: p1))
  }
  /// %@ cancelled
  public static func verificationRequestOtherCancelled(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "verification_request_other_cancelled", String(describing: p1))
  }
  /// To be secure, do this in person or use another way to communicate.
  public static var verificationRequestStartNotice: String { return ElementL10n.tr("Localizable", "verification_request_start_notice") }
  /// Waiting…
  public static var verificationRequestWaiting: String { return ElementL10n.tr("Localizable", "verification_request_waiting") }
  /// Waiting for %@…
  public static func verificationRequestWaitingFor(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "verification_request_waiting_for", String(describing: p1))
  }
  /// You accepted
  public static var verificationRequestYouAccepted: String { return ElementL10n.tr("Localizable", "verification_request_you_accepted") }
  /// You cancelled
  public static var verificationRequestYouCancelled: String { return ElementL10n.tr("Localizable", "verification_request_you_cancelled") }
  /// They don't match
  public static var verificationSasDoNotMatch: String { return ElementL10n.tr("Localizable", "verification_sas_do_not_match") }
  /// They match
  public static var verificationSasMatch: String { return ElementL10n.tr("Localizable", "verification_sas_match") }
  /// If you're not in person, compare emoji instead
  public static var verificationScanEmojiSubtitle: String { return ElementL10n.tr("Localizable", "verification_scan_emoji_subtitle") }
  /// Can't scan
  public static var verificationScanEmojiTitle: String { return ElementL10n.tr("Localizable", "verification_scan_emoji_title") }
  /// Scan the code with the other user's device to securely verify each other
  public static var verificationScanNotice: String { return ElementL10n.tr("Localizable", "verification_scan_notice") }
  /// Verify by comparing emoji instead
  public static var verificationScanSelfEmojiSubtitle: String { return ElementL10n.tr("Localizable", "verification_scan_self_emoji_subtitle") }
  /// Scan the code with your other device or switch and scan with this device
  public static var verificationScanSelfNotice: String { return ElementL10n.tr("Localizable", "verification_scan_self_notice") }
  /// Scan their code
  public static var verificationScanTheirCode: String { return ElementL10n.tr("Localizable", "verification_scan_their_code") }
  /// Scan with this device
  public static var verificationScanWithThisDevice: String { return ElementL10n.tr("Localizable", "verification_scan_with_this_device") }
  /// Verification Sent
  public static var verificationSent: String { return ElementL10n.tr("Localizable", "verification_sent") }
  /// If you can’t access an existing session
  public static var verificationUsePassphrase: String { return ElementL10n.tr("Localizable", "verification_use_passphrase") }
  /// Verified %@
  public static func verificationVerifiedUser(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "verification_verified_user", String(describing: p1))
  }
  /// Verify this session
  public static var verificationVerifyDevice: String { return ElementL10n.tr("Localizable", "verification_verify_device") }
  /// Verify %@
  public static func verificationVerifyUser(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "verification_verify_user", String(describing: p1))
  }
  /// You won’t verify %1$@ (%2$@) if you cancel now. Start again in their user profile.
  public static func verifyCancelOther(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "verify_cancel_other", String(describing: p1), String(describing: p2))
  }
  /// If you cancel, you won’t be able to read encrypted messages on your new device, and other users won’t trust it
  public static var verifyCancelSelfVerificationFromTrusted: String { return ElementL10n.tr("Localizable", "verify_cancel_self_verification_from_trusted") }
  /// If you cancel, you won’t be able to read encrypted messages on this device, and other users won’t trust it
  public static var verifyCancelSelfVerificationFromUntrusted: String { return ElementL10n.tr("Localizable", "verify_cancel_self_verification_from_untrusted") }
  /// Verification has been cancelled. You can start verification again.
  public static var verifyCancelledNotice: String { return ElementL10n.tr("Localizable", "verify_cancelled_notice") }
  /// This session is unable to share this verification with your other sessions.
  /// The verification will be saved locally and shared in a future version of the app.
  public static var verifyCannotCrossSign: String { return ElementL10n.tr("Localizable", "verify_cannot_cross_sign") }
  /// This QR code looks malformed. Please try to verify with another method.
  public static var verifyInvalidQrNotice: String { return ElementL10n.tr("Localizable", "verify_invalid_qr_notice") }
  /// Your account may be compromised
  public static var verifyNewSessionCompromized: String { return ElementL10n.tr("Localizable", "verify_new_session_compromized") }
  /// Use this session to verify your new one, granting it access to encrypted messages.
  public static var verifyNewSessionNotice: String { return ElementL10n.tr("Localizable", "verify_new_session_notice") }
  /// This wasn’t me
  public static var verifyNewSessionWasNotMe: String { return ElementL10n.tr("Localizable", "verify_new_session_was_not_me") }
  /// One of the following may be compromised:
  /// 
  /// - Your password
  /// - Your homeserver
  /// - This device, or the other device
  /// - The internet connection either device is using
  /// 
  /// We recommend you change your password & recovery key in Settings immediately.
  public static var verifyNotMeSelfVerification: String { return ElementL10n.tr("Localizable", "verify_not_me_self_verification") }
  /// Verify all your sessions to ensure your account & messages are safe
  public static var verifyOtherSessions: String { return ElementL10n.tr("Localizable", "verify_other_sessions") }
  /// Verify the new login accessing your account: %1$@
  public static func verifyThisSession(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "verify_this_session", String(describing: p1))
  }
  /// Video Call In Progress…
  public static var videoCallInProgress: String { return ElementL10n.tr("Localizable", "video_call_in_progress") }
  /// Video call with %@
  public static func videoCallWithParticipant(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "video_call_with_participant", String(describing: p1))
  }
  /// Start video meeting
  public static var videoMeeting: String { return ElementL10n.tr("Localizable", "video_meeting") }
  /// View Decrypted Source
  public static var viewDecryptedSource: String { return ElementL10n.tr("Localizable", "view_decrypted_source") }
  /// View In Room
  public static var viewInRoom: String { return ElementL10n.tr("Localizable", "view_in_room") }
  /// View Source
  public static var viewSource: String { return ElementL10n.tr("Localizable", "view_source") }
  /// %1$ds left
  public static func voiceMessageNSecondsWarningToast(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "voice_message_n_seconds_warning_toast", p1)
  }
  /// Hold to record, release to send
  public static var voiceMessageReleaseToSendToast: String { return ElementL10n.tr("Localizable", "voice_message_release_to_send_toast") }
  /// Voice Message (%1$@)
  public static func voiceMessageReplyContent(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "voice_message_reply_content", String(describing: p1))
  }
  /// Slide to cancel
  public static var voiceMessageSlideToCancel: String { return ElementL10n.tr("Localizable", "voice_message_slide_to_cancel") }
  /// Tap on your recording to stop or listen
  public static var voiceMessageTapToStopToast: String { return ElementL10n.tr("Localizable", "voice_message_tap_to_stop_toast") }
  /// The room is not yet created. Cancel the room creation?
  public static var warningRoomNotCreatedYet: String { return ElementL10n.tr("Localizable", "warning_room_not_created_yet") }
  /// There are unsaved changes. Discard the changes?
  public static var warningUnsavedChange: String { return ElementL10n.tr("Localizable", "warning_unsaved_change") }
  /// Discard changes
  public static var warningUnsavedChangeDiscard: String { return ElementL10n.tr("Localizable", "warning_unsaved_change_discard") }
  /// Are you sure you want to delete the widget from this room?
  public static var widgetDeleteMessageConfirmation: String { return ElementL10n.tr("Localizable", "widget_delete_message_confirmation") }
  /// Failed to send request.
  public static var widgetIntegrationFailedToSendRequest: String { return ElementL10n.tr("Localizable", "widget_integration_failed_to_send_request") }
  /// A required parameter is missing.
  public static var widgetIntegrationMissingParameter: String { return ElementL10n.tr("Localizable", "widget_integration_missing_parameter") }
  /// Missing room_id in request.
  public static var widgetIntegrationMissingRoomId: String { return ElementL10n.tr("Localizable", "widget_integration_missing_room_id") }
  /// Missing user_id in request.
  public static var widgetIntegrationMissingUserId: String { return ElementL10n.tr("Localizable", "widget_integration_missing_user_id") }
  /// You are not in this room.
  public static var widgetIntegrationMustBeInRoom: String { return ElementL10n.tr("Localizable", "widget_integration_must_be_in_room") }
  /// You do not have permission to do that in this room.
  public static var widgetIntegrationNoPermissionInRoom: String { return ElementL10n.tr("Localizable", "widget_integration_no_permission_in_room") }
  /// Power level must be positive integer.
  public static var widgetIntegrationPositivePowerLevel: String { return ElementL10n.tr("Localizable", "widget_integration_positive_power_level") }
  /// To continue you need to accept the Terms of this service.
  public static var widgetIntegrationReviewTerms: String { return ElementL10n.tr("Localizable", "widget_integration_review_terms") }
  /// Room %@ is not visible.
  public static func widgetIntegrationRoomNotVisible(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "widget_integration_room_not_visible", String(describing: p1))
  }
  /// Unable to create widget.
  public static var widgetIntegrationUnableToCreate: String { return ElementL10n.tr("Localizable", "widget_integration_unable_to_create") }
  /// Warning! Last remaining attempt before logout!
  public static var wrongPinMessageLastRemainingAttempt: String { return ElementL10n.tr("Localizable", "wrong_pin_message_last_remaining_attempt") }
  /// Plural format key: "%#@VARIABLE@"
  public static func wrongPinMessageRemainingAttempts(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "wrong_pin_message_remaining_attempts", p1)
  }
  /// +%d
  public static func xPlus(_ p1: Int) -> String {
    return ElementL10n.tr("Localizable", "x_plus", p1)
  }
  /// YES
  public static var yes: String { return ElementL10n.tr("Localizable", "yes") }
  /// You added a new session '%@', which is requesting encryption keys.
  public static func youAddedANewDevice(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "you_added_a_new_device", String(describing: p1))
  }
  /// A new session is requesting encryption keys.
  /// Session name: %1$@
  /// Last seen: %2$@
  /// If you didn’t log in on another session, ignore this request.
  public static func youAddedANewDeviceWithInfo(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "you_added_a_new_device_with_info", String(describing: p1), String(describing: p2))
  }
  /// You are invited
  public static var youAreInvited: String { return ElementL10n.tr("Localizable", "you_are_invited") }
  /// You may contact me if you have any follow up questions
  public static var youMayContactMe: String { return ElementL10n.tr("Localizable", "you_may_contact_me") }
  /// Your private space
  public static var yourPrivateSpace: String { return ElementL10n.tr("Localizable", "your_private_space") }
  /// Your public space
  public static var yourPublicSpace: String { return ElementL10n.tr("Localizable", "your_public_space") }
  /// Your unverified session  '%@' is requesting encryption keys.
  public static func yourUnverifiedDeviceRequesting(_ p1: Any) -> String {
    return ElementL10n.tr("Localizable", "your_unverified_device_requesting", String(describing: p1))
  }
  /// An unverified session is requesting encryption keys.
  /// Session name: %1$@
  /// Last seen: %2$@
  /// If you didn’t log in on another session, ignore this request.
  public static func yourUnverifiedDeviceRequestingWithInfo(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Localizable", "your_unverified_device_requesting_with_info", String(describing: p1), String(describing: p2))
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension ElementL10n {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let languages = Bundle.preferredLanguages

    for language in languages {
      let translation = trIn(language, table, key, args)
      if translation != key {
        return translation
      }
    }
    return key
  }

  private static func trIn(_ language: String, _ table: String, _ key: String, _ args: CVarArg...) -> String {
    guard let bundle = Bundle(for: BundleToken.self).lprojBundle(for: language) else {
      // no translations for the desired language
      return key
    }
    let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    return String(format: format, locale: Locale(identifier: language), arguments: args)
  }
}

private final class BundleToken {}

