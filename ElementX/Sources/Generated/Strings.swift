// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// User menu
  public static var a11yUserMenu: String { return L10n.tr("Localizable", "a11y_user_menu") }
  /// Attach screenshot
  public static var actionAttachScreenshot: String { return L10n.tr("Localizable", "action_attach_screenshot") }
  /// Cancel
  public static var actionCancel: String { return L10n.tr("Localizable", "action_cancel") }
  /// Complete verification
  public static var actionCompleteVerification: String { return L10n.tr("Localizable", "action_complete_verification") }
  /// Confirm
  public static var actionConfirm: String { return L10n.tr("Localizable", "action_confirm") }
  /// Continue
  public static var actionContinue: String { return L10n.tr("Localizable", "action_continue") }
  /// Copy
  public static var actionCopy: String { return L10n.tr("Localizable", "action_copy") }
  /// Copy link
  public static var actionCopyLink: String { return L10n.tr("Localizable", "action_copy_link") }
  /// Create a room
  public static var actionCreateARoom: String { return L10n.tr("Localizable", "action_create_a_room") }
  /// Done
  public static var actionDone: String { return L10n.tr("Localizable", "action_done") }
  /// Edit
  public static var actionEdit: String { return L10n.tr("Localizable", "action_edit") }
  /// Edit screenshot
  public static var actionEditScreenshot: String { return L10n.tr("Localizable", "action_edit_screenshot") }
  /// Enable
  public static var actionEnable: String { return L10n.tr("Localizable", "action_enable") }
  /// Invite
  public static var actionInvite: String { return L10n.tr("Localizable", "action_invite") }
  /// Invite friends to %1$@
  public static func actionInviteFriendsToApp(_ p1: Any) -> String {
    return L10n.tr("Localizable", "action_invite_friends_to_app", String(describing: p1))
  }
  /// Learn more
  public static var actionLearnMore: String { return L10n.tr("Localizable", "action_learn_more") }
  /// Leave
  public static var actionLeave: String { return L10n.tr("Localizable", "action_leave") }
  /// Leave room
  public static var actionLeaveRoom: String { return L10n.tr("Localizable", "action_leave_room") }
  /// Next
  public static var actionNext: String { return L10n.tr("Localizable", "action_next") }
  /// No
  public static var actionNo: String { return L10n.tr("Localizable", "action_no") }
  /// Not now
  public static var actionNotNow: String { return L10n.tr("Localizable", "action_not_now") }
  /// OK
  public static var actionOk: String { return L10n.tr("Localizable", "action_ok") }
  /// Quick reply
  public static var actionQuickReply: String { return L10n.tr("Localizable", "action_quick_reply") }
  /// Quote
  public static var actionQuote: String { return L10n.tr("Localizable", "action_quote") }
  /// Remove
  public static var actionRemove: String { return L10n.tr("Localizable", "action_remove") }
  /// Reply
  public static var actionReply: String { return L10n.tr("Localizable", "action_reply") }
  /// Report bug
  public static var actionReportBug: String { return L10n.tr("Localizable", "action_report_bug") }
  /// Report Content
  public static var actionReportContent: String { return L10n.tr("Localizable", "action_report_content") }
  /// Retry
  public static var actionRetry: String { return L10n.tr("Localizable", "action_retry") }
  /// Retry decryption
  public static var actionRetryDecryption: String { return L10n.tr("Localizable", "action_retry_decryption") }
  /// Send
  public static var actionSend: String { return L10n.tr("Localizable", "action_send") }
  /// Sign out
  public static var actionSignOut: String { return L10n.tr("Localizable", "action_sign_out") }
  /// Are you sure you want to sign out?
  public static var actionSignOutConfirmation: String { return L10n.tr("Localizable", "action_sign_out_confirmation") }
  /// Start
  public static var actionStart: String { return L10n.tr("Localizable", "action_start") }
  /// Start chat
  public static var actionStartChat: String { return L10n.tr("Localizable", "action_start_chat") }
  /// Start verification
  public static var actionStartVerification: String { return L10n.tr("Localizable", "action_start_verification") }
  /// View Source
  public static var actionViewSource: String { return L10n.tr("Localizable", "action_view_source") }
  /// Yes
  public static var actionYes: String { return L10n.tr("Localizable", "action_yes") }
  /// Please describe the bug. What did you do? What did you expect to happen? What actually happened. Please go into as much detail as you can.
  public static var bugReportScreenEditorDescription: String { return L10n.tr("Localizable", "bug_report_screen_editor_description") }
  /// Describe the bug…
  public static var bugReportScreenEditorPlaceholder: String { return L10n.tr("Localizable", "bug_report_screen_editor_placeholder") }
  /// Send logs to help
  public static var bugReportScreenIncludeLogs: String { return L10n.tr("Localizable", "bug_report_screen_include_logs") }
  /// To check things work as intended, logs will be sent with your message. These will be private. To just send your message, turn off this setting.
  public static var bugReportScreenLogsDescription: String { return L10n.tr("Localizable", "bug_report_screen_logs_description") }
  /// %1$@ crashed the last time it was used. Would you like to share a crash report with us?
  public static func bugReportShareCrashLogsAlertTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "bug_report_share_crash_logs_alert_title", String(describing: p1))
  }
  /// About
  public static var commonAbout: String { return L10n.tr("Localizable", "common_about") }
  /// All Chats
  public static var commonAllChats: String { return L10n.tr("Localizable", "common_all_chats") }
  /// Bubbles
  public static var commonBubbles: String { return L10n.tr("Localizable", "common_bubbles") }
  /// Decryption error
  public static var commonDecryptionError: String { return L10n.tr("Localizable", "common_decryption_error") }
  /// Developer options
  public static var commonDeveloperOptions: String { return L10n.tr("Localizable", "common_developer_options") }
  /// (edited)
  public static var commonEditedSuffix: String { return L10n.tr("Localizable", "common_edited_suffix") }
  /// Editing
  public static var commonEditing: String { return L10n.tr("Localizable", "common_editing") }
  /// Encryption enabled
  public static var commonEncryptionEnabled: String { return L10n.tr("Localizable", "common_encryption_enabled") }
  /// Enter your details
  public static var commonEnterYourDetails: String { return L10n.tr("Localizable", "common_enter_your_details") }
  /// Error
  public static var commonError: String { return L10n.tr("Localizable", "common_error") }
  /// File
  public static var commonFile: String { return L10n.tr("Localizable", "common_file") }
  /// GIF
  public static var commonGif: String { return L10n.tr("Localizable", "common_gif") }
  /// Homeserver URL
  public static var commonHomeserverUrl: String { return L10n.tr("Localizable", "common_homeserver_url") }
  /// Image
  public static var commonImage: String { return L10n.tr("Localizable", "common_image") }
  /// Link copied to clipboard
  public static var commonLinkCopiedToClipboard: String { return L10n.tr("Localizable", "common_link_copied_to_clipboard") }
  /// Loading…
  public static var commonLoading: String { return L10n.tr("Localizable", "common_loading") }
  /// Plural format key: "%#@COUNT@"
  public static func commonMemberCount(_ p1: Int) -> String {
    return L10n.tr("Localizable", "common_member_count", p1)
  }
  /// Message
  public static var commonMessage: String { return L10n.tr("Localizable", "common_message") }
  /// Message layout
  public static var commonMessageLayout: String { return L10n.tr("Localizable", "common_message_layout") }
  /// Message removed
  public static var commonMessageRemoved: String { return L10n.tr("Localizable", "common_message_removed") }
  /// Modern
  public static var commonModern: String { return L10n.tr("Localizable", "common_modern") }
  /// Offline
  public static var commonOffline: String { return L10n.tr("Localizable", "common_offline") }
  /// Password
  public static var commonPassword: String { return L10n.tr("Localizable", "common_password") }
  /// People
  public static var commonPeople: String { return L10n.tr("Localizable", "common_people") }
  /// Permalink
  public static var commonPermalink: String { return L10n.tr("Localizable", "common_permalink") }
  /// Reactions
  public static var commonReactions: String { return L10n.tr("Localizable", "common_reactions") }
  /// Replying to %1$@
  public static func commonReplyingTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_replying_to", String(describing: p1))
  }
  /// Report a bug
  public static var commonReportABug: String { return L10n.tr("Localizable", "common_report_a_bug") }
  /// Report submitted
  public static var commonReportSubmitted: String { return L10n.tr("Localizable", "common_report_submitted") }
  /// Search for someone
  public static var commonSearchForSomeone: String { return L10n.tr("Localizable", "common_search_for_someone") }
  /// Security
  public static var commonSecurity: String { return L10n.tr("Localizable", "common_security") }
  /// Select your server
  public static var commonSelectYourServer: String { return L10n.tr("Localizable", "common_select_your_server") }
  /// Sending…
  public static var commonSending: String { return L10n.tr("Localizable", "common_sending") }
  /// Server not supported
  public static var commonServerNotSupported: String { return L10n.tr("Localizable", "common_server_not_supported") }
  /// Server URL
  public static var commonServerUrl: String { return L10n.tr("Localizable", "common_server_url") }
  /// Settings
  public static var commonSettings: String { return L10n.tr("Localizable", "common_settings") }
  /// Sticker
  public static var commonSticker: String { return L10n.tr("Localizable", "common_sticker") }
  /// Success
  public static var commonSuccess: String { return L10n.tr("Localizable", "common_success") }
  /// Suggestions
  public static var commonSuggestions: String { return L10n.tr("Localizable", "common_suggestions") }
  /// They don’t match
  public static var commonTheyDontMatch: String { return L10n.tr("Localizable", "common_they_dont_match") }
  /// They match
  public static var commonTheyMatch: String { return L10n.tr("Localizable", "common_they_match") }
  /// Topic
  public static var commonTopic: String { return L10n.tr("Localizable", "common_topic") }
  /// Unable to decrypt
  public static var commonUnableToDecrypt: String { return L10n.tr("Localizable", "common_unable_to_decrypt") }
  /// Unsupported event
  public static var commonUnsupportedEvent: String { return L10n.tr("Localizable", "common_unsupported_event") }
  /// Username
  public static var commonUsername: String { return L10n.tr("Localizable", "common_username") }
  /// Verification cancelled
  public static var commonVerificationCancelled: String { return L10n.tr("Localizable", "common_verification_cancelled") }
  /// Verification complete
  public static var commonVerificationComplete: String { return L10n.tr("Localizable", "common_verification_complete") }
  /// Video
  public static var commonVideo: String { return L10n.tr("Localizable", "common_video") }
  /// Waiting…
  public static var commonWaiting: String { return L10n.tr("Localizable", "common_waiting") }
  /// Activities
  public static var emojiPickerCategoryActivity: String { return L10n.tr("Localizable", "emoji_picker_category_activity") }
  /// Flags
  public static var emojiPickerCategoryFlags: String { return L10n.tr("Localizable", "emoji_picker_category_flags") }
  /// Food & Drink
  public static var emojiPickerCategoryFoods: String { return L10n.tr("Localizable", "emoji_picker_category_foods") }
  /// Animals & Nature
  public static var emojiPickerCategoryNature: String { return L10n.tr("Localizable", "emoji_picker_category_nature") }
  /// Objects
  public static var emojiPickerCategoryObjects: String { return L10n.tr("Localizable", "emoji_picker_category_objects") }
  /// Smileys & People
  public static var emojiPickerCategoryPeople: String { return L10n.tr("Localizable", "emoji_picker_category_people") }
  /// Travel & Places
  public static var emojiPickerCategoryPlaces: String { return L10n.tr("Localizable", "emoji_picker_category_places") }
  /// Symbols
  public static var emojiPickerCategorySymbols: String { return L10n.tr("Localizable", "emoji_picker_category_symbols") }
  /// Failed creating the permalink
  public static var errorFailedCreatingThePermalink: String { return L10n.tr("Localizable", "error_failed_creating_the_permalink") }
  /// Failed loading messages
  public static var errorFailedLoadingMessages: String { return L10n.tr("Localizable", "error_failed_loading_messages") }
  /// Some messages have not been sent
  public static var errorSomeMessagesHaveNotBeenSent: String { return L10n.tr("Localizable", "error_some_messages_have_not_been_sent") }
  /// Sorry, an error occurred
  public static var errorUnknown: String { return L10n.tr("Localizable", "error_unknown") }
  /// Hey, talk to me on %1$@: %2$@
  public static func inviteFriendsText(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "invite_friends_text", String(describing: p1), String(describing: p2))
  }
  /// Are you sure that you want to leave this room? You are the only person here. If you leave, no one will be able to join in the future, including you.
  public static var leaveRoomAlertEmptySubtitle: String { return L10n.tr("Localizable", "leave_room_alert_empty_subtitle") }
  /// Are you sure that you want to leave this room? This room is not public and you will not be able to rejoin without an invite.
  public static var leaveRoomAlertPrivateSubtitle: String { return L10n.tr("Localizable", "leave_room_alert_private_subtitle") }
  /// Are you sure that you want to leave the room?
  public static var leaveRoomAlertSubtitle: String { return L10n.tr("Localizable", "leave_room_alert_subtitle") }
  /// This account has been deactivated.
  public static var loginErrorDeactivatedAccount: String { return L10n.tr("Localizable", "login_error_deactivated_account") }
  /// Incorrect username and/or password
  public static var loginErrorInvalidCredentials: String { return L10n.tr("Localizable", "login_error_invalid_credentials") }
  /// This is not a valid user identifier. Expected format: ‘@user:homeserver.org’
  public static var loginErrorInvalidUserId: String { return L10n.tr("Localizable", "login_error_invalid_user_id") }
  /// The selected homeserver doesn't support password or OIDC login. Please contact your admin or choose another homeserver.
  public static var loginErrorUnsupportedAuthentication: String { return L10n.tr("Localizable", "login_error_unsupported_authentication") }
  /// %1$@ iOS
  public static func loginInitialDeviceNameIos(_ p1: Any) -> String {
    return L10n.tr("Localizable", "login_initial_device_name_ios", String(describing: p1))
  }
  /// Where your conversations live
  public static var loginServerHeader: String { return L10n.tr("Localizable", "login_server_header") }
  /// Welcome back!
  public static var loginTitle: String { return L10n.tr("Localizable", "login_title") }
  /// Message…
  public static var messageComposerPlaceholder: String { return L10n.tr("Localizable", "message_composer_placeholder") }
  /// Notification
  public static var notification: String { return L10n.tr("Localizable", "Notification") }
  /// Welcome to the %1$@ Beta. Supercharged, for speed and simplicity.
  public static func onboardingWelcomeSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "onboarding_welcome_subtitle", String(describing: p1))
  }
  /// Be in your Element
  public static var onboardingWelcomeTitle: String { return L10n.tr("Localizable", "onboarding_welcome_title") }
  /// Reporting this message will send it’s unique ‘event ID’ to the administrator of your homeserver. If messages in this room are encrypted, your homeserver administrator will not be able to read the message text or view any files or images.
  public static var reportContentExplanation: String { return L10n.tr("Localizable", "report_content_explanation") }
  /// Reason for reporting this content
  public static var reportContentHint: String { return L10n.tr("Localizable", "report_content_hint") }
  /// Messages in this room are end-to-end encrypted. Learn more & verify users in their profile.
  public static var roomDetailsEncryptionEnabledDescription: String { return L10n.tr("Localizable", "room_details_encryption_enabled_description") }
  /// This is the beginning of %1$@.
  public static func roomTimelineBeginningOfRoom(_ p1: Any) -> String {
    return L10n.tr("Localizable", "room_timeline_beginning_of_room", String(describing: p1))
  }
  /// This is the beginning of this conversation.
  public static var roomTimelineBeginningOfRoomNoName: String { return L10n.tr("Localizable", "room_timeline_beginning_of_room_no_name") }
  /// New
  public static var roomTimelineReadMarkerTitle: String { return L10n.tr("Localizable", "room_timeline_read_marker_title") }
  /// %1$d room changes
  public static func roomTimelineStateChanges(_ p1: Int) -> String {
    return L10n.tr("Localizable", "room_timeline_state_changes", p1)
  }
  /// Unable to find a homeserver at this URL, please check that you entered it correctly and try again.
  public static var serverSelectionErrorHomeserverNotFound: String { return L10n.tr("Localizable", "server_selection_error_homeserver_not_found") }
  /// You can only connect to an existing server that supports sliding sync. Your homeserver admin will need to configure it. %1$@
  public static func serverSelectionServerFooter(_ p1: Any) -> String {
    return L10n.tr("Localizable", "server_selection_server_footer", String(describing: p1))
  }
  /// This server currently doesn’t support sliding sync.
  public static var serverSelectionSlidingSyncAlertMessage: String { return L10n.tr("Localizable", "server_selection_sliding_sync_alert_message") }
  /// What is the address of your server?
  public static var serverSelectionSubtitle: String { return L10n.tr("Localizable", "server_selection_subtitle") }
  /// Looks like you’re using a new device. Verify it’s you to access your encrypted messages.
  public static var sessionVerificationBannerMessage: String { return L10n.tr("Localizable", "session_verification_banner_message") }
  /// Access your message history
  public static var sessionVerificationBannerTitle: String { return L10n.tr("Localizable", "session_verification_banner_title") }
  /// Something doesn’t seem right. Either the request timed out or the request was denied.
  public static var sessionVerificationCancelledSubtitle: String { return L10n.tr("Localizable", "session_verification_cancelled_subtitle") }
  /// Confirm that the emojis below match those shown on your other session.
  public static var sessionVerificationCompareEmojisSubtitle: String { return L10n.tr("Localizable", "session_verification_compare_emojis_subtitle") }
  /// Compare emojis
  public static var sessionVerificationCompareEmojisTitle: String { return L10n.tr("Localizable", "session_verification_compare_emojis_title") }
  /// Your new session is now verified. It has access to your encrypted messages, and other users will see it as trusted.
  public static var sessionVerificationCompleteSubtitle: String { return L10n.tr("Localizable", "session_verification_complete_subtitle") }
  /// Prove it’s you in order to access your encrypted message history.
  public static var sessionVerificationOpenExistingSessionSubtitle: String { return L10n.tr("Localizable", "session_verification_open_existing_session_subtitle") }
  /// Open an existing session
  public static var sessionVerificationOpenExistingSessionTitle: String { return L10n.tr("Localizable", "session_verification_open_existing_session_title") }
  /// Compare the unique emoji, ensuring they appear in the same order.
  public static var sessionVerificationRequestAcceptedSubtitle: String { return L10n.tr("Localizable", "session_verification_request_accepted_subtitle") }
  /// Accept the request to start the verification process in your other session to continue.
  public static var sessionVerificationWaitingToAcceptSubtitle: String { return L10n.tr("Localizable", "session_verification_waiting_to_accept_subtitle") }
  /// Waiting to accept request
  public static var sessionVerificationWaitingToAcceptTitle: String { return L10n.tr("Localizable", "session_verification_waiting_to_accept_title") }
  /// Version: %1$@ (%2$@)
  public static func settingsVersionNumber(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "settings_version_number", String(describing: p1), String(describing: p2))
  }
  /// (avatar was changed too)
  public static var stateEventAvatarChangedToo: String { return L10n.tr("Localizable", "state_event_avatar_changed_too") }
  /// %1$@ changed their avatar
  public static func stateEventAvatarUrlChanged(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_avatar_url_changed", String(describing: p1))
  }
  /// You changed your avatar
  public static var stateEventAvatarUrlChangedByYou: String { return L10n.tr("Localizable", "state_event_avatar_url_changed_by_you") }
  /// %1$@ changed their display name from %2$@ to %3$@
  public static func stateEventDisplayNameChangedFrom(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_changed_from", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// You changed your display name from %1$@ to %2$@
  public static func stateEventDisplayNameChangedFromByYou(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_changed_from_by_you", String(describing: p1), String(describing: p2))
  }
  /// %1$@ removed their display name (it was %2$@)
  public static func stateEventDisplayNameRemoved(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_removed", String(describing: p1), String(describing: p2))
  }
  /// You removed your display name (it was %1$@)
  public static func stateEventDisplayNameRemovedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_removed_by_you", String(describing: p1))
  }
  /// %1$@ set their display name to %2$@
  public static func stateEventDisplayNameSet(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_set", String(describing: p1), String(describing: p2))
  }
  /// You set your display name to %1$@
  public static func stateEventDisplayNameSetByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_set_by_you", String(describing: p1))
  }
  /// %1$@ changed the room avatar
  public static func stateEventRoomAvatarChanged(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_avatar_changed", String(describing: p1))
  }
  /// You changed the room avatar
  public static var stateEventRoomAvatarChangedByYou: String { return L10n.tr("Localizable", "state_event_room_avatar_changed_by_you") }
  /// %1$@ removed the room avatar
  public static func stateEventRoomAvatarRemoved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_avatar_removed", String(describing: p1))
  }
  /// You removed the room avatar
  public static var stateEventRoomAvatarRemovedByYou: String { return L10n.tr("Localizable", "state_event_room_avatar_removed_by_you") }
  /// %1$@ banned %2$@
  public static func stateEventRoomBan(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_ban", String(describing: p1), String(describing: p2))
  }
  /// You banned %1$@
  public static func stateEventRoomBanByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_ban_by_you", String(describing: p1))
  }
  /// %1$@ created the room
  public static func stateEventRoomCreated(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_created", String(describing: p1))
  }
  /// You created the room
  public static var stateEventRoomCreatedByYou: String { return L10n.tr("Localizable", "state_event_room_created_by_you") }
  /// %1$@ invited %2$@
  public static func stateEventRoomInvite(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite", String(describing: p1), String(describing: p2))
  }
  /// %1$@ accepted the invite
  public static func stateEventRoomInviteAccepted(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite_accepted", String(describing: p1))
  }
  /// You accepted the invite
  public static var stateEventRoomInviteAcceptedByYou: String { return L10n.tr("Localizable", "state_event_room_invite_accepted_by_you") }
  /// You invited %1$@
  public static func stateEventRoomInviteByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite_by_you", String(describing: p1))
  }
  /// %1$@ invited you
  public static func stateEventRoomInviteYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite_you", String(describing: p1))
  }
  /// %1$@ joined the room
  public static func stateEventRoomJoin(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_join", String(describing: p1))
  }
  /// You joined the room
  public static var stateEventRoomJoinByYou: String { return L10n.tr("Localizable", "state_event_room_join_by_you") }
  /// %1$@ requested to join
  public static func stateEventRoomKnock(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock", String(describing: p1))
  }
  /// %1$@ allowed %2$@ to join
  public static func stateEventRoomKnockAccepted(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_accepted", String(describing: p1), String(describing: p2))
  }
  /// %1$@ allowed you to join
  public static func stateEventRoomKnockAcceptedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_accepted_by_you", String(describing: p1))
  }
  /// You requested to join
  public static var stateEventRoomKnockByYou: String { return L10n.tr("Localizable", "state_event_room_knock_by_you") }
  /// %1$@ rejected %2$@'s request to join
  public static func stateEventRoomKnockDenied(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_denied", String(describing: p1), String(describing: p2))
  }
  /// You rejected %1$@'s request to join
  public static func stateEventRoomKnockDeniedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_denied_by_you", String(describing: p1))
  }
  /// %1$@ rejected your request to join
  public static func stateEventRoomKnockDeniedYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_denied_you", String(describing: p1))
  }
  /// %1$@ is no longer interested in joining
  public static func stateEventRoomKnockRetracted(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_retracted", String(describing: p1))
  }
  /// You cancelled your request to join
  public static var stateEventRoomKnockRetractedByYou: String { return L10n.tr("Localizable", "state_event_room_knock_retracted_by_you") }
  /// %1$@ left the room
  public static func stateEventRoomLeave(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_leave", String(describing: p1))
  }
  /// You left the room
  public static var stateEventRoomLeaveByYou: String { return L10n.tr("Localizable", "state_event_room_leave_by_you") }
  /// %1$@ changed the room name to: %2$@
  public static func stateEventRoomNameChanged(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_name_changed", String(describing: p1), String(describing: p2))
  }
  /// You changed the room name to: %1$@
  public static func stateEventRoomNameChangedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_name_changed_by_you", String(describing: p1))
  }
  /// %1$@ removed the room name
  public static func stateEventRoomNameRemoved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_name_removed", String(describing: p1))
  }
  /// You removed the room name
  public static var stateEventRoomNameRemovedByYou: String { return L10n.tr("Localizable", "state_event_room_name_removed_by_you") }
  /// %1$@ rejected the invitation
  public static func stateEventRoomReject(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_reject", String(describing: p1))
  }
  /// You rejected the invitation
  public static var stateEventRoomRejectByYou: String { return L10n.tr("Localizable", "state_event_room_reject_by_you") }
  /// %1$@ removed %2$@
  public static func stateEventRoomRemove(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_remove", String(describing: p1), String(describing: p2))
  }
  /// You removed %1$@
  public static func stateEventRoomRemoveByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_remove_by_you", String(describing: p1))
  }
  /// %1$@ sent an invitation to %2$@ to join the room
  public static func stateEventRoomThirdPartyInvite(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_invite", String(describing: p1), String(describing: p2))
  }
  /// You sent an invitation to %1$@ to join the room
  public static func stateEventRoomThirdPartyInviteByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_invite_by_you", String(describing: p1))
  }
  /// %1$@ revoked the invitation for %2$@ to join the room
  public static func stateEventRoomThirdPartyRevokedInvite(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_revoked_invite", String(describing: p1), String(describing: p2))
  }
  /// You revoked the invitation for %1$@ to join the room
  public static func stateEventRoomThirdPartyRevokedInviteByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_revoked_invite_by_you", String(describing: p1))
  }
  /// %1$@ changed the topic to: %2$@
  public static func stateEventRoomTopicChanged(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_topic_changed", String(describing: p1), String(describing: p2))
  }
  /// You changed the topic to: %1$@
  public static func stateEventRoomTopicChangedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_topic_changed_by_you", String(describing: p1))
  }
  /// %1$@ removed the room topic
  public static func stateEventRoomTopicRemoved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_topic_removed", String(describing: p1))
  }
  /// You removed the room topic
  public static var stateEventRoomTopicRemovedByYou: String { return L10n.tr("Localizable", "state_event_room_topic_removed_by_you") }
  /// %1$@ unbanned %2$@
  public static func stateEventRoomUnban(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_unban", String(describing: p1), String(describing: p2))
  }
  /// You unbanned %1$@
  public static func stateEventRoomUnbanByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_unban_by_you", String(describing: p1))
  }
  /// %1$@ made an unknown change to their membership
  public static func stateEventRoomUnknownMembershipChange(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_unknown_membership_change", String(describing: p1))
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
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

