// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// Hide password
  public static var a11yHidePassword: String { return L10n.tr("Localizable", "a11y_hide_password") }
  /// Mentions only
  public static var a11yNotificationsMentionsOnly: String { return L10n.tr("Localizable", "a11y_notifications_mentions_only") }
  /// Muted
  public static var a11yNotificationsMuted: String { return L10n.tr("Localizable", "a11y_notifications_muted") }
  /// Poll
  public static var a11yPoll: String { return L10n.tr("Localizable", "a11y_poll") }
  /// Ended poll
  public static var a11yPollEnd: String { return L10n.tr("Localizable", "a11y_poll_end") }
  /// Send files
  public static var a11ySendFiles: String { return L10n.tr("Localizable", "a11y_send_files") }
  /// Show password
  public static var a11yShowPassword: String { return L10n.tr("Localizable", "a11y_show_password") }
  /// User menu
  public static var a11yUserMenu: String { return L10n.tr("Localizable", "a11y_user_menu") }
  /// Accept
  public static var actionAccept: String { return L10n.tr("Localizable", "action_accept") }
  /// Add to timeline
  public static var actionAddToTimeline: String { return L10n.tr("Localizable", "action_add_to_timeline") }
  /// Back
  public static var actionBack: String { return L10n.tr("Localizable", "action_back") }
  /// Cancel
  public static var actionCancel: String { return L10n.tr("Localizable", "action_cancel") }
  /// Choose photo
  public static var actionChoosePhoto: String { return L10n.tr("Localizable", "action_choose_photo") }
  /// Clear
  public static var actionClear: String { return L10n.tr("Localizable", "action_clear") }
  /// Close
  public static var actionClose: String { return L10n.tr("Localizable", "action_close") }
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
  /// Copy link to message
  public static var actionCopyLinkToMessage: String { return L10n.tr("Localizable", "action_copy_link_to_message") }
  /// Create
  public static var actionCreate: String { return L10n.tr("Localizable", "action_create") }
  /// Create a room
  public static var actionCreateARoom: String { return L10n.tr("Localizable", "action_create_a_room") }
  /// Decline
  public static var actionDecline: String { return L10n.tr("Localizable", "action_decline") }
  /// Disable
  public static var actionDisable: String { return L10n.tr("Localizable", "action_disable") }
  /// Done
  public static var actionDone: String { return L10n.tr("Localizable", "action_done") }
  /// Edit
  public static var actionEdit: String { return L10n.tr("Localizable", "action_edit") }
  /// Enable
  public static var actionEnable: String { return L10n.tr("Localizable", "action_enable") }
  /// End poll
  public static var actionEndPoll: String { return L10n.tr("Localizable", "action_end_poll") }
  /// Forgot password?
  public static var actionForgotPassword: String { return L10n.tr("Localizable", "action_forgot_password") }
  /// Forward
  public static var actionForward: String { return L10n.tr("Localizable", "action_forward") }
  /// Invite
  public static var actionInvite: String { return L10n.tr("Localizable", "action_invite") }
  /// Invite friends
  public static var actionInviteFriends: String { return L10n.tr("Localizable", "action_invite_friends") }
  /// Invite friends to %1$@
  public static func actionInviteFriendsToApp(_ p1: Any) -> String {
    return L10n.tr("Localizable", "action_invite_friends_to_app", String(describing: p1))
  }
  /// Invite people to %1$@
  public static func actionInvitePeopleToApp(_ p1: Any) -> String {
    return L10n.tr("Localizable", "action_invite_people_to_app", String(describing: p1))
  }
  /// Invites
  public static var actionInvitesList: String { return L10n.tr("Localizable", "action_invites_list") }
  /// Learn more
  public static var actionLearnMore: String { return L10n.tr("Localizable", "action_learn_more") }
  /// Leave
  public static var actionLeave: String { return L10n.tr("Localizable", "action_leave") }
  /// Leave room
  public static var actionLeaveRoom: String { return L10n.tr("Localizable", "action_leave_room") }
  /// Manage account
  public static var actionManageAccount: String { return L10n.tr("Localizable", "action_manage_account") }
  /// Manage devices
  public static var actionManageDevices: String { return L10n.tr("Localizable", "action_manage_devices") }
  /// Next
  public static var actionNext: String { return L10n.tr("Localizable", "action_next") }
  /// No
  public static var actionNo: String { return L10n.tr("Localizable", "action_no") }
  /// Not now
  public static var actionNotNow: String { return L10n.tr("Localizable", "action_not_now") }
  /// OK
  public static var actionOk: String { return L10n.tr("Localizable", "action_ok") }
  /// Open settings
  public static var actionOpenSettings: String { return L10n.tr("Localizable", "action_open_settings") }
  /// Open with
  public static var actionOpenWith: String { return L10n.tr("Localizable", "action_open_with") }
  /// Quick reply
  public static var actionQuickReply: String { return L10n.tr("Localizable", "action_quick_reply") }
  /// Quote
  public static var actionQuote: String { return L10n.tr("Localizable", "action_quote") }
  /// React
  public static var actionReact: String { return L10n.tr("Localizable", "action_react") }
  /// Remove
  public static var actionRemove: String { return L10n.tr("Localizable", "action_remove") }
  /// Reply
  public static var actionReply: String { return L10n.tr("Localizable", "action_reply") }
  /// Reply in thread
  public static var actionReplyInThread: String { return L10n.tr("Localizable", "action_reply_in_thread") }
  /// Report bug
  public static var actionReportBug: String { return L10n.tr("Localizable", "action_report_bug") }
  /// Report Content
  public static var actionReportContent: String { return L10n.tr("Localizable", "action_report_content") }
  /// Retry
  public static var actionRetry: String { return L10n.tr("Localizable", "action_retry") }
  /// Retry decryption
  public static var actionRetryDecryption: String { return L10n.tr("Localizable", "action_retry_decryption") }
  /// Save
  public static var actionSave: String { return L10n.tr("Localizable", "action_save") }
  /// Search
  public static var actionSearch: String { return L10n.tr("Localizable", "action_search") }
  /// Send
  public static var actionSend: String { return L10n.tr("Localizable", "action_send") }
  /// Send message
  public static var actionSendMessage: String { return L10n.tr("Localizable", "action_send_message") }
  /// Share
  public static var actionShare: String { return L10n.tr("Localizable", "action_share") }
  /// Share link
  public static var actionShareLink: String { return L10n.tr("Localizable", "action_share_link") }
  /// Skip
  public static var actionSkip: String { return L10n.tr("Localizable", "action_skip") }
  /// Start
  public static var actionStart: String { return L10n.tr("Localizable", "action_start") }
  /// Start chat
  public static var actionStartChat: String { return L10n.tr("Localizable", "action_start_chat") }
  /// Start verification
  public static var actionStartVerification: String { return L10n.tr("Localizable", "action_start_verification") }
  /// Tap to load map
  public static var actionStaticMapLoad: String { return L10n.tr("Localizable", "action_static_map_load") }
  /// Take photo
  public static var actionTakePhoto: String { return L10n.tr("Localizable", "action_take_photo") }
  /// View Source
  public static var actionViewSource: String { return L10n.tr("Localizable", "action_view_source") }
  /// Yes
  public static var actionYes: String { return L10n.tr("Localizable", "action_yes") }
  /// About
  public static var commonAbout: String { return L10n.tr("Localizable", "common_about") }
  /// Acceptable use policy
  public static var commonAcceptableUsePolicy: String { return L10n.tr("Localizable", "common_acceptable_use_policy") }
  /// Advanced settings
  public static var commonAdvancedSettings: String { return L10n.tr("Localizable", "common_advanced_settings") }
  /// Analytics
  public static var commonAnalytics: String { return L10n.tr("Localizable", "common_analytics") }
  /// Audio
  public static var commonAudio: String { return L10n.tr("Localizable", "common_audio") }
  /// Bubbles
  public static var commonBubbles: String { return L10n.tr("Localizable", "common_bubbles") }
  /// Copyright
  public static var commonCopyright: String { return L10n.tr("Localizable", "common_copyright") }
  /// Creating room…
  public static var commonCreatingRoom: String { return L10n.tr("Localizable", "common_creating_room") }
  /// Left room
  public static var commonCurrentUserLeftRoom: String { return L10n.tr("Localizable", "common_current_user_left_room") }
  /// Decryption error
  public static var commonDecryptionError: String { return L10n.tr("Localizable", "common_decryption_error") }
  /// Developer options
  public static var commonDeveloperOptions: String { return L10n.tr("Localizable", "common_developer_options") }
  /// (edited)
  public static var commonEditedSuffix: String { return L10n.tr("Localizable", "common_edited_suffix") }
  /// Editing
  public static var commonEditing: String { return L10n.tr("Localizable", "common_editing") }
  /// * %1$@ %2$@
  public static func commonEmote(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "common_emote", String(describing: p1), String(describing: p2))
  }
  /// Encryption enabled
  public static var commonEncryptionEnabled: String { return L10n.tr("Localizable", "common_encryption_enabled") }
  /// Error
  public static var commonError: String { return L10n.tr("Localizable", "common_error") }
  /// File
  public static var commonFile: String { return L10n.tr("Localizable", "common_file") }
  /// Forward message
  public static var commonForwardMessage: String { return L10n.tr("Localizable", "common_forward_message") }
  /// GIF
  public static var commonGif: String { return L10n.tr("Localizable", "common_gif") }
  /// Image
  public static var commonImage: String { return L10n.tr("Localizable", "common_image") }
  /// In reply to %1$@
  public static func commonInReplyTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_in_reply_to", String(describing: p1))
  }
  /// This Matrix ID can't be found, so the invite might not be received.
  public static var commonInviteUnknownProfile: String { return L10n.tr("Localizable", "common_invite_unknown_profile") }
  /// Leaving room
  public static var commonLeavingRoom: String { return L10n.tr("Localizable", "common_leaving_room") }
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
  /// Mute
  public static var commonMute: String { return L10n.tr("Localizable", "common_mute") }
  /// No results
  public static var commonNoResults: String { return L10n.tr("Localizable", "common_no_results") }
  /// Offline
  public static var commonOffline: String { return L10n.tr("Localizable", "common_offline") }
  /// Password
  public static var commonPassword: String { return L10n.tr("Localizable", "common_password") }
  /// People
  public static var commonPeople: String { return L10n.tr("Localizable", "common_people") }
  /// Permalink
  public static var commonPermalink: String { return L10n.tr("Localizable", "common_permalink") }
  /// Permission
  public static var commonPermission: String { return L10n.tr("Localizable", "common_permission") }
  /// Are you sure you want to end this poll?
  public static var commonPollEndConfirmation: String { return L10n.tr("Localizable", "common_poll_end_confirmation") }
  /// Poll: %1$@
  public static func commonPollSummary(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_poll_summary", String(describing: p1))
  }
  /// Total votes: %1$@
  public static func commonPollTotalVotes(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_poll_total_votes", String(describing: p1))
  }
  /// Results will show after the poll has ended
  public static var commonPollUndisclosedText: String { return L10n.tr("Localizable", "common_poll_undisclosed_text") }
  /// Plural format key: "%#@COUNT@"
  public static func commonPollVotesCount(_ p1: Int) -> String {
    return L10n.tr("Localizable", "common_poll_votes_count", p1)
  }
  /// Privacy policy
  public static var commonPrivacyPolicy: String { return L10n.tr("Localizable", "common_privacy_policy") }
  /// Reaction
  public static var commonReaction: String { return L10n.tr("Localizable", "common_reaction") }
  /// Reactions
  public static var commonReactions: String { return L10n.tr("Localizable", "common_reactions") }
  /// Refreshing…
  public static var commonRefreshing: String { return L10n.tr("Localizable", "common_refreshing") }
  /// Replying to %1$@
  public static func commonReplyingTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_replying_to", String(describing: p1))
  }
  /// Report a bug
  public static var commonReportABug: String { return L10n.tr("Localizable", "common_report_a_bug") }
  /// Report submitted
  public static var commonReportSubmitted: String { return L10n.tr("Localizable", "common_report_submitted") }
  /// Rich text editor
  public static var commonRichTextEditor: String { return L10n.tr("Localizable", "common_rich_text_editor") }
  /// Room name
  public static var commonRoomName: String { return L10n.tr("Localizable", "common_room_name") }
  /// e.g. your project name
  public static var commonRoomNamePlaceholder: String { return L10n.tr("Localizable", "common_room_name_placeholder") }
  /// Search for someone
  public static var commonSearchForSomeone: String { return L10n.tr("Localizable", "common_search_for_someone") }
  /// Search results
  public static var commonSearchResults: String { return L10n.tr("Localizable", "common_search_results") }
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
  /// Shared location
  public static var commonSharedLocation: String { return L10n.tr("Localizable", "common_shared_location") }
  /// Starting chat…
  public static var commonStartingChat: String { return L10n.tr("Localizable", "common_starting_chat") }
  /// Sticker
  public static var commonSticker: String { return L10n.tr("Localizable", "common_sticker") }
  /// Success
  public static var commonSuccess: String { return L10n.tr("Localizable", "common_success") }
  /// Suggestions
  public static var commonSuggestions: String { return L10n.tr("Localizable", "common_suggestions") }
  /// Syncing
  public static var commonSyncing: String { return L10n.tr("Localizable", "common_syncing") }
  /// Text
  public static var commonText: String { return L10n.tr("Localizable", "common_text") }
  /// Third-party notices
  public static var commonThirdPartyNotices: String { return L10n.tr("Localizable", "common_third_party_notices") }
  /// Thread
  public static var commonThread: String { return L10n.tr("Localizable", "common_thread") }
  /// Topic
  public static var commonTopic: String { return L10n.tr("Localizable", "common_topic") }
  /// What is this room about?
  public static var commonTopicPlaceholder: String { return L10n.tr("Localizable", "common_topic_placeholder") }
  /// Unable to decrypt
  public static var commonUnableToDecrypt: String { return L10n.tr("Localizable", "common_unable_to_decrypt") }
  /// Invites couldn't be sent to one or more users.
  public static var commonUnableToInviteMessage: String { return L10n.tr("Localizable", "common_unable_to_invite_message") }
  /// Unable to send invite(s)
  public static var commonUnableToInviteTitle: String { return L10n.tr("Localizable", "common_unable_to_invite_title") }
  /// Unmute
  public static var commonUnmute: String { return L10n.tr("Localizable", "common_unmute") }
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
  /// %1$@ crashed the last time it was used. Would you like to share a crash report with us?
  public static func crashDetectionDialogContent(_ p1: Any) -> String {
    return L10n.tr("Localizable", "crash_detection_dialog_content", String(describing: p1))
  }
  /// In order to let the application use the camera, please grant the permission in the system settings.
  public static var dialogPermissionCamera: String { return L10n.tr("Localizable", "dialog_permission_camera") }
  /// Please grant the permission in the system settings.
  public static var dialogPermissionGeneric: String { return L10n.tr("Localizable", "dialog_permission_generic") }
  /// In order to let the application use the microphone, please grant the permission in the system settings.
  public static var dialogPermissionMicrophone: String { return L10n.tr("Localizable", "dialog_permission_microphone") }
  /// In order to let the application display notifications, please grant the permission in the system settings.
  public static var dialogPermissionNotification: String { return L10n.tr("Localizable", "dialog_permission_notification") }
  /// Confirmation
  public static var dialogTitleConfirmation: String { return L10n.tr("Localizable", "dialog_title_confirmation") }
  /// Error
  public static var dialogTitleError: String { return L10n.tr("Localizable", "dialog_title_error") }
  /// Success
  public static var dialogTitleSuccess: String { return L10n.tr("Localizable", "dialog_title_success") }
  /// Warning
  public static var dialogTitleWarning: String { return L10n.tr("Localizable", "dialog_title_warning") }
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
  /// %1$@ could not load the map. Please try again later.
  public static func errorFailedLoadingMap(_ p1: Any) -> String {
    return L10n.tr("Localizable", "error_failed_loading_map", String(describing: p1))
  }
  /// Failed loading messages
  public static var errorFailedLoadingMessages: String { return L10n.tr("Localizable", "error_failed_loading_messages") }
  /// %1$@ could not access your location. Please try again later.
  public static func errorFailedLocatingUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "error_failed_locating_user", String(describing: p1))
  }
  /// %1$@ does not have permission to access your location. You can enable access in Settings > Location
  public static func errorMissingLocationAuthIos(_ p1: Any) -> String {
    return L10n.tr("Localizable", "error_missing_location_auth_ios", String(describing: p1))
  }
  /// No compatible app was found to handle this action.
  public static var errorNoCompatibleAppFound: String { return L10n.tr("Localizable", "error_no_compatible_app_found") }
  /// Some messages have not been sent
  public static var errorSomeMessagesHaveNotBeenSent: String { return L10n.tr("Localizable", "error_some_messages_have_not_been_sent") }
  /// Sorry, an error occurred
  public static var errorUnknown: String { return L10n.tr("Localizable", "error_unknown") }
  /// 🔐️ Join me on %1$@
  public static func inviteFriendsRichTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "invite_friends_rich_title", String(describing: p1))
  }
  /// Hey, talk to me on %1$@: %2$@
  public static func inviteFriendsText(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "invite_friends_text", String(describing: p1), String(describing: p2))
  }
  /// Are you sure that you want to leave this room? You're the only person here. If you leave, no one will be able to join in the future, including you.
  public static var leaveRoomAlertEmptySubtitle: String { return L10n.tr("Localizable", "leave_room_alert_empty_subtitle") }
  /// Are you sure that you want to leave this room? This room is not public and you won't be able to rejoin without an invite.
  public static var leaveRoomAlertPrivateSubtitle: String { return L10n.tr("Localizable", "leave_room_alert_private_subtitle") }
  /// Are you sure that you want to leave the room?
  public static var leaveRoomAlertSubtitle: String { return L10n.tr("Localizable", "leave_room_alert_subtitle") }
  /// %1$@ iOS
  public static func loginInitialDeviceNameIos(_ p1: Any) -> String {
    return L10n.tr("Localizable", "login_initial_device_name_ios", String(describing: p1))
  }
  /// Notification
  public static var notification: String { return L10n.tr("Localizable", "Notification") }
  /// Call
  public static var notificationChannelCall: String { return L10n.tr("Localizable", "notification_channel_call") }
  /// Listening for events
  public static var notificationChannelListeningForEvents: String { return L10n.tr("Localizable", "notification_channel_listening_for_events") }
  /// Noisy notifications
  public static var notificationChannelNoisy: String { return L10n.tr("Localizable", "notification_channel_noisy") }
  /// Silent notifications
  public static var notificationChannelSilent: String { return L10n.tr("Localizable", "notification_channel_silent") }
  /// Plural format key: "%#@COUNT@"
  public static func notificationCompatSummaryLineForRoom(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_compat_summary_line_for_room", p1)
  }
  /// Plural format key: "%#@COUNT@"
  public static func notificationCompatSummaryTitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_compat_summary_title", p1)
  }
  /// Notification
  public static var notificationFallbackContent: String { return L10n.tr("Localizable", "notification_fallback_content") }
  /// ** Failed to send - please open room
  public static var notificationInlineReplyFailed: String { return L10n.tr("Localizable", "notification_inline_reply_failed") }
  /// Join
  public static var notificationInvitationActionJoin: String { return L10n.tr("Localizable", "notification_invitation_action_join") }
  /// Reject
  public static var notificationInvitationActionReject: String { return L10n.tr("Localizable", "notification_invitation_action_reject") }
  /// Plural format key: "%#@COUNT@"
  public static func notificationInvitations(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_invitations", p1)
  }
  /// Invited you to chat
  public static var notificationInviteBody: String { return L10n.tr("Localizable", "notification_invite_body") }
  /// New Messages
  public static var notificationNewMessages: String { return L10n.tr("Localizable", "notification_new_messages") }
  /// Plural format key: "%#@COUNT@"
  public static func notificationNewMessagesForRoom(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_new_messages_for_room", p1)
  }
  /// Reacted with %1$@
  public static func notificationReactionBody(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notification_reaction_body", String(describing: p1))
  }
  /// Mark as read
  public static var notificationRoomActionMarkAsRead: String { return L10n.tr("Localizable", "notification_room_action_mark_as_read") }
  /// Quick reply
  public static var notificationRoomActionQuickReply: String { return L10n.tr("Localizable", "notification_room_action_quick_reply") }
  /// Invited you to join the room
  public static var notificationRoomInviteBody: String { return L10n.tr("Localizable", "notification_room_invite_body") }
  /// Me
  public static var notificationSenderMe: String { return L10n.tr("Localizable", "notification_sender_me") }
  /// You are viewing the notification! Click me!
  public static var notificationTestPushNotificationContent: String { return L10n.tr("Localizable", "notification_test_push_notification_content") }
  /// %1$@: %2$@
  public static func notificationTickerTextDm(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "notification_ticker_text_dm", String(describing: p1), String(describing: p2))
  }
  /// %1$@: %2$@ %3$@
  public static func notificationTickerTextGroup(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "notification_ticker_text_group", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Plural format key: "%#@COUNT@"
  public static func notificationUnreadNotifiedMessages(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages", p1)
  }
  /// %1$@ and %2$@
  public static func notificationUnreadNotifiedMessagesAndInvitation(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_and_invitation", String(describing: p1), String(describing: p2))
  }
  /// %1$@ in %2$@
  public static func notificationUnreadNotifiedMessagesInRoom(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_in_room", String(describing: p1), String(describing: p2))
  }
  /// %1$@ in %2$@ and %3$@
  public static func notificationUnreadNotifiedMessagesInRoomAndInvitation(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_in_room_and_invitation", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Plural format key: "%#@COUNT@"
  public static func notificationUnreadNotifiedMessagesInRoomRooms(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_in_room_rooms", p1)
  }
  /// Rageshake to report bug
  public static var preferenceRageshake: String { return L10n.tr("Localizable", "preference_rageshake") }
  /// You seem to be shaking the phone in frustration. Would you like to open the bug report screen?
  public static var rageshakeDetectionDialogContent: String { return L10n.tr("Localizable", "rageshake_detection_dialog_content") }
  /// You seem to be shaking the phone in frustration. Would you like to open the bug report screen?
  public static var rageshakeDialogContent: String { return L10n.tr("Localizable", "rageshake_dialog_content") }
  /// This message will be reported to your homeserver’s administrator. They will not be able to read any encrypted messages.
  public static var reportContentExplanation: String { return L10n.tr("Localizable", "report_content_explanation") }
  /// Reason for reporting this content
  public static var reportContentHint: String { return L10n.tr("Localizable", "report_content_hint") }
  /// Add attachment
  public static var richTextEditorA11yAddAttachment: String { return L10n.tr("Localizable", "rich_text_editor_a11y_add_attachment") }
  /// Toggle bullet list
  public static var richTextEditorBulletList: String { return L10n.tr("Localizable", "rich_text_editor_bullet_list") }
  /// Close formatting options
  public static var richTextEditorCloseFormattingOptions: String { return L10n.tr("Localizable", "rich_text_editor_close_formatting_options") }
  /// Toggle code block
  public static var richTextEditorCodeBlock: String { return L10n.tr("Localizable", "rich_text_editor_code_block") }
  /// Message…
  public static var richTextEditorComposerPlaceholder: String { return L10n.tr("Localizable", "rich_text_editor_composer_placeholder") }
  /// Create a link
  public static var richTextEditorCreateLink: String { return L10n.tr("Localizable", "rich_text_editor_create_link") }
  /// Edit link
  public static var richTextEditorEditLink: String { return L10n.tr("Localizable", "rich_text_editor_edit_link") }
  /// Apply bold format
  public static var richTextEditorFormatBold: String { return L10n.tr("Localizable", "rich_text_editor_format_bold") }
  /// Apply italic format
  public static var richTextEditorFormatItalic: String { return L10n.tr("Localizable", "rich_text_editor_format_italic") }
  /// Apply strikethrough format
  public static var richTextEditorFormatStrikethrough: String { return L10n.tr("Localizable", "rich_text_editor_format_strikethrough") }
  /// Apply underline format
  public static var richTextEditorFormatUnderline: String { return L10n.tr("Localizable", "rich_text_editor_format_underline") }
  /// Toggle full screen mode
  public static var richTextEditorFullScreenToggle: String { return L10n.tr("Localizable", "rich_text_editor_full_screen_toggle") }
  /// Indent
  public static var richTextEditorIndent: String { return L10n.tr("Localizable", "rich_text_editor_indent") }
  /// Apply inline code format
  public static var richTextEditorInlineCode: String { return L10n.tr("Localizable", "rich_text_editor_inline_code") }
  /// Set link
  public static var richTextEditorLink: String { return L10n.tr("Localizable", "rich_text_editor_link") }
  /// Toggle numbered list
  public static var richTextEditorNumberedList: String { return L10n.tr("Localizable", "rich_text_editor_numbered_list") }
  /// Open compose options
  public static var richTextEditorOpenComposeOptions: String { return L10n.tr("Localizable", "rich_text_editor_open_compose_options") }
  /// Toggle quote
  public static var richTextEditorQuote: String { return L10n.tr("Localizable", "rich_text_editor_quote") }
  /// Remove link
  public static var richTextEditorRemoveLink: String { return L10n.tr("Localizable", "rich_text_editor_remove_link") }
  /// Unindent
  public static var richTextEditorUnindent: String { return L10n.tr("Localizable", "rich_text_editor_unindent") }
  /// Link
  public static var richTextEditorUrlPlaceholder: String { return L10n.tr("Localizable", "rich_text_editor_url_placeholder") }
  /// This is the beginning of %1$@.
  public static func roomTimelineBeginningOfRoom(_ p1: Any) -> String {
    return L10n.tr("Localizable", "room_timeline_beginning_of_room", String(describing: p1))
  }
  /// This is the beginning of this conversation.
  public static var roomTimelineBeginningOfRoomNoName: String { return L10n.tr("Localizable", "room_timeline_beginning_of_room_no_name") }
  /// New
  public static var roomTimelineReadMarkerTitle: String { return L10n.tr("Localizable", "room_timeline_read_marker_title") }
  /// Plural format key: "%#@COUNT@"
  public static func roomTimelineStateChanges(_ p1: Int) -> String {
    return L10n.tr("Localizable", "room_timeline_state_changes", p1)
  }
  /// Change account provider
  public static var screenAccountProviderChange: String { return L10n.tr("Localizable", "screen_account_provider_change") }
  /// Continue
  public static var screenAccountProviderContinue: String { return L10n.tr("Localizable", "screen_account_provider_continue") }
  /// Homeserver address
  public static var screenAccountProviderFormHint: String { return L10n.tr("Localizable", "screen_account_provider_form_hint") }
  /// Enter a search term or a domain address.
  public static var screenAccountProviderFormNotice: String { return L10n.tr("Localizable", "screen_account_provider_form_notice") }
  /// Search for a company, community, or private server.
  public static var screenAccountProviderFormSubtitle: String { return L10n.tr("Localizable", "screen_account_provider_form_subtitle") }
  /// Find an account provider
  public static var screenAccountProviderFormTitle: String { return L10n.tr("Localizable", "screen_account_provider_form_title") }
  /// This is where your conversations will live — just like you would use an email provider to keep your emails.
  public static var screenAccountProviderSigninSubtitle: String { return L10n.tr("Localizable", "screen_account_provider_signin_subtitle") }
  /// You’re about to sign in to %@
  public static func screenAccountProviderSigninTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_account_provider_signin_title", String(describing: p1))
  }
  /// This is where your conversations will live — just like you would use an email provider to keep your emails.
  public static var screenAccountProviderSignupSubtitle: String { return L10n.tr("Localizable", "screen_account_provider_signup_subtitle") }
  /// You’re about to create an account on %@
  public static func screenAccountProviderSignupTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_account_provider_signup_title", String(describing: p1))
  }
  /// We won't record or profile any personal data
  public static var screenAnalyticsPromptDataUsage: String { return L10n.tr("Localizable", "screen_analytics_prompt_data_usage") }
  /// Share anonymous usage data to help us identify issues.
  public static var screenAnalyticsPromptHelpUsImprove: String { return L10n.tr("Localizable", "screen_analytics_prompt_help_us_improve") }
  /// You can read all our terms %1$@.
  public static func screenAnalyticsPromptReadTerms(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_analytics_prompt_read_terms", String(describing: p1))
  }
  /// here
  public static var screenAnalyticsPromptReadTermsContentLink: String { return L10n.tr("Localizable", "screen_analytics_prompt_read_terms_content_link") }
  /// You can turn this off anytime
  public static var screenAnalyticsPromptSettings: String { return L10n.tr("Localizable", "screen_analytics_prompt_settings") }
  /// We won't share your data with third parties
  public static var screenAnalyticsPromptThirdPartySharing: String { return L10n.tr("Localizable", "screen_analytics_prompt_third_party_sharing") }
  /// Help improve %1$@
  public static func screenAnalyticsPromptTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_analytics_prompt_title", String(describing: p1))
  }
  /// Share anonymous usage data to help us identify issues.
  public static var screenAnalyticsSettingsHelpUsImprove: String { return L10n.tr("Localizable", "screen_analytics_settings_help_us_improve") }
  /// You can read all our terms %1$@.
  public static func screenAnalyticsSettingsReadTerms(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_analytics_settings_read_terms", String(describing: p1))
  }
  /// here
  public static var screenAnalyticsSettingsReadTermsContentLink: String { return L10n.tr("Localizable", "screen_analytics_settings_read_terms_content_link") }
  /// Share analytics data
  public static var screenAnalyticsSettingsShareData: String { return L10n.tr("Localizable", "screen_analytics_settings_share_data") }
  /// Attach screenshot
  public static var screenBugReportAttachScreenshot: String { return L10n.tr("Localizable", "screen_bug_report_attach_screenshot") }
  /// You may contact me if you have any follow up questions.
  public static var screenBugReportContactMe: String { return L10n.tr("Localizable", "screen_bug_report_contact_me") }
  /// Contact me
  public static var screenBugReportContactMeTitle: String { return L10n.tr("Localizable", "screen_bug_report_contact_me_title") }
  /// Edit screenshot
  public static var screenBugReportEditScreenshot: String { return L10n.tr("Localizable", "screen_bug_report_edit_screenshot") }
  /// Please describe the bug. What did you do? What did you expect to happen? What actually happened. Please go into as much detail as you can.
  public static var screenBugReportEditorDescription: String { return L10n.tr("Localizable", "screen_bug_report_editor_description") }
  /// Describe the bug…
  public static var screenBugReportEditorPlaceholder: String { return L10n.tr("Localizable", "screen_bug_report_editor_placeholder") }
  /// If possible, please write the description in English.
  public static var screenBugReportEditorSupporting: String { return L10n.tr("Localizable", "screen_bug_report_editor_supporting") }
  /// Send crash logs
  public static var screenBugReportIncludeCrashLogs: String { return L10n.tr("Localizable", "screen_bug_report_include_crash_logs") }
  /// Allow logs
  public static var screenBugReportIncludeLogs: String { return L10n.tr("Localizable", "screen_bug_report_include_logs") }
  /// Send screenshot
  public static var screenBugReportIncludeScreenshot: String { return L10n.tr("Localizable", "screen_bug_report_include_screenshot") }
  /// Logs will be included with your message to make sure that everything is working properly. To send your message without logs, turn off this setting.
  public static var screenBugReportLogsDescription: String { return L10n.tr("Localizable", "screen_bug_report_logs_description") }
  /// %1$@ crashed the last time it was used. Would you like to share a crash report with us?
  public static func screenBugReportRashLogsAlertTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_bug_report_rash_logs_alert_title", String(describing: p1))
  }
  /// Matrix.org is a large, free server on the public Matrix network for secure, decentralised communication, run by the Matrix.org Foundation.
  public static var screenChangeAccountProviderMatrixOrgSubtitle: String { return L10n.tr("Localizable", "screen_change_account_provider_matrix_org_subtitle") }
  /// Other
  public static var screenChangeAccountProviderOther: String { return L10n.tr("Localizable", "screen_change_account_provider_other") }
  /// Use a different account provider, such as your own private server or a work account.
  public static var screenChangeAccountProviderSubtitle: String { return L10n.tr("Localizable", "screen_change_account_provider_subtitle") }
  /// Change account provider
  public static var screenChangeAccountProviderTitle: String { return L10n.tr("Localizable", "screen_change_account_provider_title") }
  /// We couldn't reach this homeserver. Please check that you have entered the homeserver URL correctly. If the URL is correct, contact your homeserver administrator for further help.
  public static var screenChangeServerErrorInvalidHomeserver: String { return L10n.tr("Localizable", "screen_change_server_error_invalid_homeserver") }
  /// This server currently doesn’t support sliding sync.
  public static var screenChangeServerErrorNoSlidingSyncMessage: String { return L10n.tr("Localizable", "screen_change_server_error_no_sliding_sync_message") }
  /// Homeserver URL
  public static var screenChangeServerFormHeader: String { return L10n.tr("Localizable", "screen_change_server_form_header") }
  /// You can only connect to an existing server that supports sliding sync. Your homeserver admin will need to configure it. %1$@
  public static func screenChangeServerFormNotice(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_change_server_form_notice", String(describing: p1))
  }
  /// Continue
  public static var screenChangeServerSubmit: String { return L10n.tr("Localizable", "screen_change_server_submit") }
  /// What is the address of your server?
  public static var screenChangeServerSubtitle: String { return L10n.tr("Localizable", "screen_change_server_subtitle") }
  /// Select your server
  public static var screenChangeServerTitle: String { return L10n.tr("Localizable", "screen_change_server_title") }
  /// Add option
  public static var screenCreatePollAddOptionBtn: String { return L10n.tr("Localizable", "screen_create_poll_add_option_btn") }
  /// Show results only after poll ends
  public static var screenCreatePollAnonymousDesc: String { return L10n.tr("Localizable", "screen_create_poll_anonymous_desc") }
  /// Hide votes
  public static var screenCreatePollAnonymousHeadline: String { return L10n.tr("Localizable", "screen_create_poll_anonymous_headline") }
  /// Option %1$d
  public static func screenCreatePollAnswerHint(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_create_poll_answer_hint", p1)
  }
  /// Are you sure you want to discard this poll?
  public static var screenCreatePollDiscardConfirmation: String { return L10n.tr("Localizable", "screen_create_poll_discard_confirmation") }
  /// Discard Poll
  public static var screenCreatePollDiscardConfirmationTitle: String { return L10n.tr("Localizable", "screen_create_poll_discard_confirmation_title") }
  /// Question or topic
  public static var screenCreatePollQuestionDesc: String { return L10n.tr("Localizable", "screen_create_poll_question_desc") }
  /// What is the poll about?
  public static var screenCreatePollQuestionHint: String { return L10n.tr("Localizable", "screen_create_poll_question_hint") }
  /// Create Poll
  public static var screenCreatePollTitle: String { return L10n.tr("Localizable", "screen_create_poll_title") }
  /// New room
  public static var screenCreateRoomActionCreateRoom: String { return L10n.tr("Localizable", "screen_create_room_action_create_room") }
  /// Invite friends to Element
  public static var screenCreateRoomActionInvitePeople: String { return L10n.tr("Localizable", "screen_create_room_action_invite_people") }
  /// Invite people
  public static var screenCreateRoomAddPeopleTitle: String { return L10n.tr("Localizable", "screen_create_room_add_people_title") }
  /// An error occurred when creating the room
  public static var screenCreateRoomErrorCreatingRoom: String { return L10n.tr("Localizable", "screen_create_room_error_creating_room") }
  /// Messages in this room are encrypted. Encryption can’t be disabled afterwards.
  public static var screenCreateRoomPrivateOptionDescription: String { return L10n.tr("Localizable", "screen_create_room_private_option_description") }
  /// Private room (invite only)
  public static var screenCreateRoomPrivateOptionTitle: String { return L10n.tr("Localizable", "screen_create_room_private_option_title") }
  /// Messages are not encrypted and anyone can read them. You can enable encryption at a later date.
  public static var screenCreateRoomPublicOptionDescription: String { return L10n.tr("Localizable", "screen_create_room_public_option_description") }
  /// Public room (anyone)
  public static var screenCreateRoomPublicOptionTitle: String { return L10n.tr("Localizable", "screen_create_room_public_option_title") }
  /// Room name
  public static var screenCreateRoomRoomNameLabel: String { return L10n.tr("Localizable", "screen_create_room_room_name_label") }
  /// Create a room
  public static var screenCreateRoomTitle: String { return L10n.tr("Localizable", "screen_create_room_title") }
  /// Topic (optional)
  public static var screenCreateRoomTopicLabel: String { return L10n.tr("Localizable", "screen_create_room_topic_label") }
  /// Block
  public static var screenDmDetailsBlockAlertAction: String { return L10n.tr("Localizable", "screen_dm_details_block_alert_action") }
  /// Blocked users won't be able to send you messages and all their messages will be hidden. You can unblock them anytime.
  public static var screenDmDetailsBlockAlertDescription: String { return L10n.tr("Localizable", "screen_dm_details_block_alert_description") }
  /// Block user
  public static var screenDmDetailsBlockUser: String { return L10n.tr("Localizable", "screen_dm_details_block_user") }
  /// Unblock
  public static var screenDmDetailsUnblockAlertAction: String { return L10n.tr("Localizable", "screen_dm_details_unblock_alert_action") }
  /// You'll be able to see all messages from them again.
  public static var screenDmDetailsUnblockAlertDescription: String { return L10n.tr("Localizable", "screen_dm_details_unblock_alert_description") }
  /// Unblock user
  public static var screenDmDetailsUnblockUser: String { return L10n.tr("Localizable", "screen_dm_details_unblock_user") }
  /// Display name
  public static var screenEditProfileDisplayName: String { return L10n.tr("Localizable", "screen_edit_profile_display_name") }
  /// Your display name
  public static var screenEditProfileDisplayNamePlaceholder: String { return L10n.tr("Localizable", "screen_edit_profile_display_name_placeholder") }
  /// An unknown error was encountered and the information couldn't be changed.
  public static var screenEditProfileError: String { return L10n.tr("Localizable", "screen_edit_profile_error") }
  /// Unable to update profile
  public static var screenEditProfileErrorTitle: String { return L10n.tr("Localizable", "screen_edit_profile_error_title") }
  /// Edit profile
  public static var screenEditProfileTitle: String { return L10n.tr("Localizable", "screen_edit_profile_title") }
  /// Updating profile…
  public static var screenEditProfileUpdatingDetails: String { return L10n.tr("Localizable", "screen_edit_profile_updating_details") }
  /// Are you sure you want to decline the invitation to join %1$@?
  public static func screenInvitesDeclineChatMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_invites_decline_chat_message", String(describing: p1))
  }
  /// Decline invite
  public static var screenInvitesDeclineChatTitle: String { return L10n.tr("Localizable", "screen_invites_decline_chat_title") }
  /// Are you sure you want to decline this private chat with %1$@?
  public static func screenInvitesDeclineDirectChatMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_invites_decline_direct_chat_message", String(describing: p1))
  }
  /// Decline chat
  public static var screenInvitesDeclineDirectChatTitle: String { return L10n.tr("Localizable", "screen_invites_decline_direct_chat_title") }
  /// No Invites
  public static var screenInvitesEmptyList: String { return L10n.tr("Localizable", "screen_invites_empty_list") }
  /// %1$@ (%2$@) invited you
  public static func screenInvitesInvitedYou(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_invites_invited_you", String(describing: p1), String(describing: p2))
  }
  /// This account has been deactivated.
  public static var screenLoginErrorDeactivatedAccount: String { return L10n.tr("Localizable", "screen_login_error_deactivated_account") }
  /// Incorrect username and/or password
  public static var screenLoginErrorInvalidCredentials: String { return L10n.tr("Localizable", "screen_login_error_invalid_credentials") }
  /// This is not a valid user identifier. Expected format: ‘@user:homeserver.org’
  public static var screenLoginErrorInvalidUserId: String { return L10n.tr("Localizable", "screen_login_error_invalid_user_id") }
  /// The selected homeserver doesn't support password or OIDC login. Please contact your admin or choose another homeserver.
  public static var screenLoginErrorUnsupportedAuthentication: String { return L10n.tr("Localizable", "screen_login_error_unsupported_authentication") }
  /// Enter your details
  public static var screenLoginFormHeader: String { return L10n.tr("Localizable", "screen_login_form_header") }
  /// Password
  public static var screenLoginPasswordHint: String { return L10n.tr("Localizable", "screen_login_password_hint") }
  /// Continue
  public static var screenLoginSubmit: String { return L10n.tr("Localizable", "screen_login_submit") }
  /// Matrix is an open network for secure, decentralised communication.
  public static var screenLoginSubtitle: String { return L10n.tr("Localizable", "screen_login_subtitle") }
  /// Welcome back!
  public static var screenLoginTitle: String { return L10n.tr("Localizable", "screen_login_title") }
  /// Sign in to %1$@
  public static func screenLoginTitleWithHomeserver(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_login_title_with_homeserver", String(describing: p1))
  }
  /// Username
  public static var screenLoginUsernameHint: String { return L10n.tr("Localizable", "screen_login_username_hint") }
  /// Failed selecting media, please try again.
  public static var screenMediaPickerErrorFailedSelection: String { return L10n.tr("Localizable", "screen_media_picker_error_failed_selection") }
  /// Failed processing media to upload, please try again.
  public static var screenMediaUploadPreviewErrorFailedProcessing: String { return L10n.tr("Localizable", "screen_media_upload_preview_error_failed_processing") }
  /// Failed uploading media, please try again.
  public static var screenMediaUploadPreviewErrorFailedSending: String { return L10n.tr("Localizable", "screen_media_upload_preview_error_failed_sending") }
  /// This is a one time process, thanks for waiting.
  public static var screenMigrationMessage: String { return L10n.tr("Localizable", "screen_migration_message") }
  /// Setting up your account.
  public static var screenMigrationTitle: String { return L10n.tr("Localizable", "screen_migration_title") }
  /// You can change your settings later.
  public static var screenNotificationOptinSubtitle: String { return L10n.tr("Localizable", "screen_notification_optin_subtitle") }
  /// Allow notifications and never miss a message
  public static var screenNotificationOptinTitle: String { return L10n.tr("Localizable", "screen_notification_optin_title") }
  /// Additional settings
  public static var screenNotificationSettingsAdditionalSettingsSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_additional_settings_section_title") }
  /// Audio and video calls
  public static var screenNotificationSettingsCallsLabel: String { return L10n.tr("Localizable", "screen_notification_settings_calls_label") }
  /// Configuration mismatch
  public static var screenNotificationSettingsConfigurationMismatch: String { return L10n.tr("Localizable", "screen_notification_settings_configuration_mismatch") }
  /// We’ve simplified Notifications Settings to make options easier to find. Some custom settings you’ve chosen in the past are not shown here, but they’re still active.
  /// 
  /// If you proceed, some of your settings may change.
  public static var screenNotificationSettingsConfigurationMismatchDescription: String { return L10n.tr("Localizable", "screen_notification_settings_configuration_mismatch_description") }
  /// Direct chats
  public static var screenNotificationSettingsDirectChats: String { return L10n.tr("Localizable", "screen_notification_settings_direct_chats") }
  /// Custom setting per chat
  public static var screenNotificationSettingsEditCustomSettingsSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_edit_custom_settings_section_title") }
  /// An error occurred while updating the notification setting.
  public static var screenNotificationSettingsEditFailedUpdatingDefaultMode: String { return L10n.tr("Localizable", "screen_notification_settings_edit_failed_updating_default_mode") }
  /// All messages
  public static var screenNotificationSettingsEditModeAllMessages: String { return L10n.tr("Localizable", "screen_notification_settings_edit_mode_all_messages") }
  /// Mentions and Keywords only
  public static var screenNotificationSettingsEditModeMentionsAndKeywords: String { return L10n.tr("Localizable", "screen_notification_settings_edit_mode_mentions_and_keywords") }
  /// On direct chats, notify me for
  public static var screenNotificationSettingsEditScreenDirectSectionHeader: String { return L10n.tr("Localizable", "screen_notification_settings_edit_screen_direct_section_header") }
  /// On group chats, notify me for
  public static var screenNotificationSettingsEditScreenGroupSectionHeader: String { return L10n.tr("Localizable", "screen_notification_settings_edit_screen_group_section_header") }
  /// Enable notifications on this device
  public static var screenNotificationSettingsEnableNotifications: String { return L10n.tr("Localizable", "screen_notification_settings_enable_notifications") }
  /// The configuration has not been corrected, please try again.
  public static var screenNotificationSettingsFailedFixingConfiguration: String { return L10n.tr("Localizable", "screen_notification_settings_failed_fixing_configuration") }
  /// Group chats
  public static var screenNotificationSettingsGroupChats: String { return L10n.tr("Localizable", "screen_notification_settings_group_chats") }
  /// Mentions
  public static var screenNotificationSettingsMentionsSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_mentions_section_title") }
  /// All
  public static var screenNotificationSettingsModeAll: String { return L10n.tr("Localizable", "screen_notification_settings_mode_all") }
  /// Mentions
  public static var screenNotificationSettingsModeMentions: String { return L10n.tr("Localizable", "screen_notification_settings_mode_mentions") }
  /// Notify me for
  public static var screenNotificationSettingsNotificationSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_notification_section_title") }
  /// Notify me on @room
  public static var screenNotificationSettingsRoomMentionLabel: String { return L10n.tr("Localizable", "screen_notification_settings_room_mention_label") }
  /// To receive notifications, please change your %1$@.
  public static func screenNotificationSettingsSystemNotificationsActionRequired(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_notification_settings_system_notifications_action_required", String(describing: p1))
  }
  /// system settings
  public static var screenNotificationSettingsSystemNotificationsActionRequiredContentLink: String { return L10n.tr("Localizable", "screen_notification_settings_system_notifications_action_required_content_link") }
  /// System notifications turned off
  public static var screenNotificationSettingsSystemNotificationsTurnedOff: String { return L10n.tr("Localizable", "screen_notification_settings_system_notifications_turned_off") }
  /// Notifications
  public static var screenNotificationSettingsTitle: String { return L10n.tr("Localizable", "screen_notification_settings_title") }
  /// Sign in manually
  public static var screenOnboardingSignInManually: String { return L10n.tr("Localizable", "screen_onboarding_sign_in_manually") }
  /// Sign in with QR code
  public static var screenOnboardingSignInWithQrCode: String { return L10n.tr("Localizable", "screen_onboarding_sign_in_with_qr_code") }
  /// Create account
  public static var screenOnboardingSignUp: String { return L10n.tr("Localizable", "screen_onboarding_sign_up") }
  /// Communicate and collaborate securely
  public static var screenOnboardingSubtitle: String { return L10n.tr("Localizable", "screen_onboarding_subtitle") }
  /// Welcome to the fastest Element ever. Supercharged for speed and simplicity.
  public static var screenOnboardingWelcomeMessage: String { return L10n.tr("Localizable", "screen_onboarding_welcome_message") }
  /// Welcome to %1$@. Supercharged, for speed and simplicity.
  public static func screenOnboardingWelcomeSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_onboarding_welcome_subtitle", String(describing: p1))
  }
  /// Be in your element
  public static var screenOnboardingWelcomeTitle: String { return L10n.tr("Localizable", "screen_onboarding_welcome_title") }
  /// Block user
  public static var screenReportContentBlockUser: String { return L10n.tr("Localizable", "screen_report_content_block_user") }
  /// Check if you want to hide all current and future messages from this user
  public static var screenReportContentBlockUserHint: String { return L10n.tr("Localizable", "screen_report_content_block_user_hint") }
  /// Camera
  public static var screenRoomAttachmentSourceCamera: String { return L10n.tr("Localizable", "screen_room_attachment_source_camera") }
  /// Take photo
  public static var screenRoomAttachmentSourceCameraPhoto: String { return L10n.tr("Localizable", "screen_room_attachment_source_camera_photo") }
  /// Record video
  public static var screenRoomAttachmentSourceCameraVideo: String { return L10n.tr("Localizable", "screen_room_attachment_source_camera_video") }
  /// Attachment
  public static var screenRoomAttachmentSourceFiles: String { return L10n.tr("Localizable", "screen_room_attachment_source_files") }
  /// Photo & Video Library
  public static var screenRoomAttachmentSourceGallery: String { return L10n.tr("Localizable", "screen_room_attachment_source_gallery") }
  /// Location
  public static var screenRoomAttachmentSourceLocation: String { return L10n.tr("Localizable", "screen_room_attachment_source_location") }
  /// Poll
  public static var screenRoomAttachmentSourcePoll: String { return L10n.tr("Localizable", "screen_room_attachment_source_poll") }
  /// Text Formatting
  public static var screenRoomAttachmentTextFormatting: String { return L10n.tr("Localizable", "screen_room_attachment_text_formatting") }
  /// Add topic
  public static var screenRoomDetailsAddTopicTitle: String { return L10n.tr("Localizable", "screen_room_details_add_topic_title") }
  /// Already a member
  public static var screenRoomDetailsAlreadyAMember: String { return L10n.tr("Localizable", "screen_room_details_already_a_member") }
  /// Already invited
  public static var screenRoomDetailsAlreadyInvited: String { return L10n.tr("Localizable", "screen_room_details_already_invited") }
  /// Edit Room
  public static var screenRoomDetailsEditRoomTitle: String { return L10n.tr("Localizable", "screen_room_details_edit_room_title") }
  /// There was an unknown error and the information couldn't be changed.
  public static var screenRoomDetailsEditionError: String { return L10n.tr("Localizable", "screen_room_details_edition_error") }
  /// Unable to update room
  public static var screenRoomDetailsEditionErrorTitle: String { return L10n.tr("Localizable", "screen_room_details_edition_error_title") }
  /// Messages are secured with locks. Only you and the recipients have the unique keys to unlock them.
  public static var screenRoomDetailsEncryptionEnabledSubtitle: String { return L10n.tr("Localizable", "screen_room_details_encryption_enabled_subtitle") }
  /// Message encryption enabled
  public static var screenRoomDetailsEncryptionEnabledTitle: String { return L10n.tr("Localizable", "screen_room_details_encryption_enabled_title") }
  /// An error occurred when loading notification settings.
  public static var screenRoomDetailsErrorLoadingNotificationSettings: String { return L10n.tr("Localizable", "screen_room_details_error_loading_notification_settings") }
  /// Failed muting this room, please try again.
  public static var screenRoomDetailsErrorMuting: String { return L10n.tr("Localizable", "screen_room_details_error_muting") }
  /// Failed unmuting this room, please try again.
  public static var screenRoomDetailsErrorUnmuting: String { return L10n.tr("Localizable", "screen_room_details_error_unmuting") }
  /// Invite people
  public static var screenRoomDetailsInvitePeopleTitle: String { return L10n.tr("Localizable", "screen_room_details_invite_people_title") }
  /// Leave room
  public static var screenRoomDetailsLeaveRoomTitle: String { return L10n.tr("Localizable", "screen_room_details_leave_room_title") }
  /// Custom
  public static var screenRoomDetailsNotificationModeCustom: String { return L10n.tr("Localizable", "screen_room_details_notification_mode_custom") }
  /// Default
  public static var screenRoomDetailsNotificationModeDefault: String { return L10n.tr("Localizable", "screen_room_details_notification_mode_default") }
  /// Notifications
  public static var screenRoomDetailsNotificationTitle: String { return L10n.tr("Localizable", "screen_room_details_notification_title") }
  /// People
  public static var screenRoomDetailsPeopleTitle: String { return L10n.tr("Localizable", "screen_room_details_people_title") }
  /// Room name
  public static var screenRoomDetailsRoomNameLabel: String { return L10n.tr("Localizable", "screen_room_details_room_name_label") }
  /// Security
  public static var screenRoomDetailsSecurityTitle: String { return L10n.tr("Localizable", "screen_room_details_security_title") }
  /// Share room
  public static var screenRoomDetailsShareRoomTitle: String { return L10n.tr("Localizable", "screen_room_details_share_room_title") }
  /// Topic
  public static var screenRoomDetailsTopicTitle: String { return L10n.tr("Localizable", "screen_room_details_topic_title") }
  /// Updating room…
  public static var screenRoomDetailsUpdatingRoom: String { return L10n.tr("Localizable", "screen_room_details_updating_room") }
  /// Message history is currently unavailable in this room
  public static var screenRoomEncryptedHistoryBanner: String { return L10n.tr("Localizable", "screen_room_encrypted_history_banner") }
  /// Failed processing media to upload, please try again.
  public static var screenRoomErrorFailedProcessingMedia: String { return L10n.tr("Localizable", "screen_room_error_failed_processing_media") }
  /// Could not retrieve user details
  public static var screenRoomErrorFailedRetrievingUserDetails: String { return L10n.tr("Localizable", "screen_room_error_failed_retrieving_user_details") }
  /// Would you like to invite them back?
  public static var screenRoomInviteAgainAlertMessage: String { return L10n.tr("Localizable", "screen_room_invite_again_alert_message") }
  /// You are alone in this chat
  public static var screenRoomInviteAgainAlertTitle: String { return L10n.tr("Localizable", "screen_room_invite_again_alert_title") }
  /// Block
  public static var screenRoomMemberDetailsBlockAlertAction: String { return L10n.tr("Localizable", "screen_room_member_details_block_alert_action") }
  /// Blocked users won't be able to send you messages and all their messages will be hidden. You can unblock them anytime.
  public static var screenRoomMemberDetailsBlockAlertDescription: String { return L10n.tr("Localizable", "screen_room_member_details_block_alert_description") }
  /// Block user
  public static var screenRoomMemberDetailsBlockUser: String { return L10n.tr("Localizable", "screen_room_member_details_block_user") }
  /// Unblock
  public static var screenRoomMemberDetailsUnblockAlertAction: String { return L10n.tr("Localizable", "screen_room_member_details_unblock_alert_action") }
  /// You'll be able to see all messages from them again.
  public static var screenRoomMemberDetailsUnblockAlertDescription: String { return L10n.tr("Localizable", "screen_room_member_details_unblock_alert_description") }
  /// Unblock user
  public static var screenRoomMemberDetailsUnblockUser: String { return L10n.tr("Localizable", "screen_room_member_details_unblock_user") }
  /// Plural format key: "%#@COUNT@"
  public static func screenRoomMemberListHeaderTitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_member_list_header_title", p1)
  }
  /// Pending
  public static var screenRoomMemberListPendingHeaderTitle: String { return L10n.tr("Localizable", "screen_room_member_list_pending_header_title") }
  /// Room members
  public static var screenRoomMemberListRoomMembersHeaderTitle: String { return L10n.tr("Localizable", "screen_room_member_list_room_members_header_title") }
  /// Message copied
  public static var screenRoomMessageCopied: String { return L10n.tr("Localizable", "screen_room_message_copied") }
  /// You do not have permission to post to this room
  public static var screenRoomNoPermissionToPost: String { return L10n.tr("Localizable", "screen_room_no_permission_to_post") }
  /// Allow custom setting
  public static var screenRoomNotificationSettingsAllowCustom: String { return L10n.tr("Localizable", "screen_room_notification_settings_allow_custom") }
  /// Turning this on will override your default setting
  public static var screenRoomNotificationSettingsAllowCustomFootnote: String { return L10n.tr("Localizable", "screen_room_notification_settings_allow_custom_footnote") }
  /// Notify me in this chat for
  public static var screenRoomNotificationSettingsCustomSettingsTitle: String { return L10n.tr("Localizable", "screen_room_notification_settings_custom_settings_title") }
  /// You can change it in your %1$@.
  public static func screenRoomNotificationSettingsDefaultSettingFootnote(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_notification_settings_default_setting_footnote", String(describing: p1))
  }
  /// global settings
  public static var screenRoomNotificationSettingsDefaultSettingFootnoteContentLink: String { return L10n.tr("Localizable", "screen_room_notification_settings_default_setting_footnote_content_link") }
  /// Default setting
  public static var screenRoomNotificationSettingsDefaultSettingTitle: String { return L10n.tr("Localizable", "screen_room_notification_settings_default_setting_title") }
  /// Remove custom setting
  public static var screenRoomNotificationSettingsEditRemoveSetting: String { return L10n.tr("Localizable", "screen_room_notification_settings_edit_remove_setting") }
  /// An error occurred while loading notification settings.
  public static var screenRoomNotificationSettingsErrorLoadingSettings: String { return L10n.tr("Localizable", "screen_room_notification_settings_error_loading_settings") }
  /// Failed restoring the default mode, please try again.
  public static var screenRoomNotificationSettingsErrorRestoringDefault: String { return L10n.tr("Localizable", "screen_room_notification_settings_error_restoring_default") }
  /// Failed setting the mode, please try again.
  public static var screenRoomNotificationSettingsErrorSettingMode: String { return L10n.tr("Localizable", "screen_room_notification_settings_error_setting_mode") }
  /// All messages
  public static var screenRoomNotificationSettingsModeAllMessages: String { return L10n.tr("Localizable", "screen_room_notification_settings_mode_all_messages") }
  /// Mentions and Keywords only
  public static var screenRoomNotificationSettingsModeMentionsAndKeywords: String { return L10n.tr("Localizable", "screen_room_notification_settings_mode_mentions_and_keywords") }
  /// In this room, notify me for
  public static var screenRoomNotificationSettingsRoomCustomSettingsTitle: String { return L10n.tr("Localizable", "screen_room_notification_settings_room_custom_settings_title") }
  /// Show less
  public static var screenRoomReactionsShowLess: String { return L10n.tr("Localizable", "screen_room_reactions_show_less") }
  /// Show more
  public static var screenRoomReactionsShowMore: String { return L10n.tr("Localizable", "screen_room_reactions_show_more") }
  /// Remove
  public static var screenRoomRetrySendMenuRemoveAction: String { return L10n.tr("Localizable", "screen_room_retry_send_menu_remove_action") }
  /// Send again
  public static var screenRoomRetrySendMenuSendAgainAction: String { return L10n.tr("Localizable", "screen_room_retry_send_menu_send_again_action") }
  /// Your message failed to send
  public static var screenRoomRetrySendMenuTitle: String { return L10n.tr("Localizable", "screen_room_retry_send_menu_title") }
  /// Add emoji
  public static var screenRoomTimelineAddReaction: String { return L10n.tr("Localizable", "screen_room_timeline_add_reaction") }
  /// Show less
  public static var screenRoomTimelineLessReactions: String { return L10n.tr("Localizable", "screen_room_timeline_less_reactions") }
  /// Create a new conversation or room
  public static var screenRoomlistA11yCreateMessage: String { return L10n.tr("Localizable", "screen_roomlist_a11y_create_message") }
  /// Get started by messaging someone.
  public static var screenRoomlistEmptyMessage: String { return L10n.tr("Localizable", "screen_roomlist_empty_message") }
  /// No chats yet.
  public static var screenRoomlistEmptyTitle: String { return L10n.tr("Localizable", "screen_roomlist_empty_title") }
  /// All Chats
  public static var screenRoomlistMainSpaceTitle: String { return L10n.tr("Localizable", "screen_roomlist_main_space_title") }
  /// Change account provider
  public static var screenServerConfirmationChangeServer: String { return L10n.tr("Localizable", "screen_server_confirmation_change_server") }
  /// A private server for Element employees.
  public static var screenServerConfirmationMessageLoginElementDotIo: String { return L10n.tr("Localizable", "screen_server_confirmation_message_login_element_dot_io") }
  /// Matrix is an open network for secure, decentralised communication.
  public static var screenServerConfirmationMessageLoginMatrixDotOrg: String { return L10n.tr("Localizable", "screen_server_confirmation_message_login_matrix_dot_org") }
  /// This is where your conversations will live — just like you would use an email provider to keep your emails.
  public static var screenServerConfirmationMessageRegister: String { return L10n.tr("Localizable", "screen_server_confirmation_message_register") }
  /// You’re about to sign in to %1$@
  public static func screenServerConfirmationTitleLogin(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_server_confirmation_title_login", String(describing: p1))
  }
  /// You’re about to create an account on %1$@
  public static func screenServerConfirmationTitleRegister(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_server_confirmation_title_register", String(describing: p1))
  }
  /// Something doesn’t seem right. Either the request timed out or the request was denied.
  public static var screenSessionVerificationCancelledSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_cancelled_subtitle") }
  /// Verification cancelled
  public static var screenSessionVerificationCancelledTitle: String { return L10n.tr("Localizable", "screen_session_verification_cancelled_title") }
  /// Confirm that the emojis below match those shown on your other session.
  public static var screenSessionVerificationCompareEmojisSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_compare_emojis_subtitle") }
  /// Compare emojis
  public static var screenSessionVerificationCompareEmojisTitle: String { return L10n.tr("Localizable", "screen_session_verification_compare_emojis_title") }
  /// Your new session is now verified. It has access to your encrypted messages, and other users will see it as trusted.
  public static var screenSessionVerificationCompleteSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_complete_subtitle") }
  /// Prove it’s you in order to access your encrypted message history.
  public static var screenSessionVerificationOpenExistingSessionSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_open_existing_session_subtitle") }
  /// Open an existing session
  public static var screenSessionVerificationOpenExistingSessionTitle: String { return L10n.tr("Localizable", "screen_session_verification_open_existing_session_title") }
  /// Retry verification
  public static var screenSessionVerificationPositiveButtonCanceled: String { return L10n.tr("Localizable", "screen_session_verification_positive_button_canceled") }
  /// I am ready
  public static var screenSessionVerificationPositiveButtonInitial: String { return L10n.tr("Localizable", "screen_session_verification_positive_button_initial") }
  /// Start
  public static var screenSessionVerificationPositiveButtonReady: String { return L10n.tr("Localizable", "screen_session_verification_positive_button_ready") }
  /// Waiting to match
  public static var screenSessionVerificationPositiveButtonVerifyingOngoing: String { return L10n.tr("Localizable", "screen_session_verification_positive_button_verifying_ongoing") }
  /// Compare the unique emoji, ensuring they appear in the same order.
  public static var screenSessionVerificationRequestAcceptedSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_request_accepted_subtitle") }
  /// They don’t match
  public static var screenSessionVerificationTheyDontMatch: String { return L10n.tr("Localizable", "screen_session_verification_they_dont_match") }
  /// They match
  public static var screenSessionVerificationTheyMatch: String { return L10n.tr("Localizable", "screen_session_verification_they_match") }
  /// Accept the request to start the verification process in your other session to continue.
  public static var screenSessionVerificationWaitingToAcceptSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_waiting_to_accept_subtitle") }
  /// Waiting to accept request
  public static var screenSessionVerificationWaitingToAcceptTitle: String { return L10n.tr("Localizable", "screen_session_verification_waiting_to_accept_title") }
  /// Account and devices
  public static var screenSettingsOidcAccount: String { return L10n.tr("Localizable", "screen_settings_oidc_account") }
  /// Share location
  public static var screenShareLocationTitle: String { return L10n.tr("Localizable", "screen_share_location_title") }
  /// Share my location
  public static var screenShareMyLocationAction: String { return L10n.tr("Localizable", "screen_share_my_location_action") }
  /// Open in Apple Maps
  public static var screenShareOpenAppleMaps: String { return L10n.tr("Localizable", "screen_share_open_apple_maps") }
  /// Open in Google Maps
  public static var screenShareOpenGoogleMaps: String { return L10n.tr("Localizable", "screen_share_open_google_maps") }
  /// Open in OpenStreetMap
  public static var screenShareOpenOsmMaps: String { return L10n.tr("Localizable", "screen_share_open_osm_maps") }
  /// Share this location
  public static var screenShareThisLocationAction: String { return L10n.tr("Localizable", "screen_share_this_location_action") }
  /// Are you sure you want to sign out?
  public static var screenSignoutConfirmationDialogContent: String { return L10n.tr("Localizable", "screen_signout_confirmation_dialog_content") }
  /// Sign out
  public static var screenSignoutConfirmationDialogSubmit: String { return L10n.tr("Localizable", "screen_signout_confirmation_dialog_submit") }
  /// Sign out
  public static var screenSignoutConfirmationDialogTitle: String { return L10n.tr("Localizable", "screen_signout_confirmation_dialog_title") }
  /// Signing out…
  public static var screenSignoutInProgressDialogContent: String { return L10n.tr("Localizable", "screen_signout_in_progress_dialog_content") }
  /// Sign out
  public static var screenSignoutPreferenceItem: String { return L10n.tr("Localizable", "screen_signout_preference_item") }
  /// An error occurred when trying to start a chat
  public static var screenStartChatErrorStartingChat: String { return L10n.tr("Localizable", "screen_start_chat_error_starting_chat") }
  /// Location
  public static var screenViewLocationTitle: String { return L10n.tr("Localizable", "screen_view_location_title") }
  /// There's a high demand for %1$@ on %2$@ at the moment. Come back to the app in a few days and try again.
  /// 
  /// Thanks for your patience!
  public static func screenWaitlistMessage(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_waitlist_message", String(describing: p1), String(describing: p2))
  }
  /// Welcome to %1$@!
  public static func screenWaitlistMessageSuccess(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_waitlist_message_success", String(describing: p1))
  }
  /// You’re almost there.
  public static var screenWaitlistTitle: String { return L10n.tr("Localizable", "screen_waitlist_title") }
  /// You're in.
  public static var screenWaitlistTitleSuccess: String { return L10n.tr("Localizable", "screen_waitlist_title_success") }
  /// Calls, polls, search and more will be added later this year.
  public static var screenWelcomeBullet1: String { return L10n.tr("Localizable", "screen_welcome_bullet_1") }
  /// Message history for encrypted rooms won’t be available in this update.
  public static var screenWelcomeBullet2: String { return L10n.tr("Localizable", "screen_welcome_bullet_2") }
  /// We’d love to hear from you, let us know what you think via the settings page.
  public static var screenWelcomeBullet3: String { return L10n.tr("Localizable", "screen_welcome_bullet_3") }
  /// Let's go!
  public static var screenWelcomeButton: String { return L10n.tr("Localizable", "screen_welcome_button") }
  /// Here’s what you need to know:
  public static var screenWelcomeSubtitle: String { return L10n.tr("Localizable", "screen_welcome_subtitle") }
  /// Welcome to %1$@!
  public static func screenWelcomeTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_welcome_title", String(describing: p1))
  }
  /// Looks like you’re using a new device. Verify with another device to access your encrypted messages moving forwards.
  public static var sessionVerificationBannerMessage: String { return L10n.tr("Localizable", "session_verification_banner_message") }
  /// Verify it’s you
  public static var sessionVerificationBannerTitle: String { return L10n.tr("Localizable", "session_verification_banner_title") }
  /// Rageshake
  public static var settingsRageshake: String { return L10n.tr("Localizable", "settings_rageshake") }
  /// Detection threshold
  public static var settingsRageshakeDetectionThreshold: String { return L10n.tr("Localizable", "settings_rageshake_detection_threshold") }
  /// General
  public static var settingsTitleGeneral: String { return L10n.tr("Localizable", "settings_title_general") }
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
  /// en
  public static var testLanguageIdentifier: String { return L10n.tr("Localizable", "test_language_identifier") }
  /// en
  public static var testUntranslatedDefaultLanguageIdentifier: String { return L10n.tr("Localizable", "test_untranslated_default_language_identifier") }

  public enum Action {
    /// Edit poll
    public static var editPoll: String { return L10n.tr("Localizable", "action.edit_poll") }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // Use preferredLocalizations to get a language that is in the bundle and the user's preferred list of languages.
    let languages = Bundle.overrideLocalizations ?? Bundle.app.preferredLocalizations

    for language in languages {
      if let translation = trIn(language, table, key, args) {
        return translation
      }
    }
    return Bundle.app.developmentLocalization.flatMap { trIn($0, table, key, args) } ?? key
  }

  private static func trIn(_ language: String, _ table: String, _ key: String, _ args: CVarArg...) -> String? {
    guard let bundle = Bundle.lprojBundle(for: language) else { return nil }
    let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    let translation = String(format: format, locale: Locale(identifier: language), arguments: args)
    guard translation != key else { return nil }
    return translation
  }
}

// swiftlint:enable all
