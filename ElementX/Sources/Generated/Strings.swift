// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Delete
  internal static var a11yDelete: String { return L10n.tr("Localizable", "a11y_delete") }
  /// Plural format key: "%#@COUNT@"
  internal static func a11yDigitsEntered(_ p1: Int) -> String {
    return L10n.tr("Localizable", "a11y_digits_entered", p1)
  }
  /// Hide password
  internal static var a11yHidePassword: String { return L10n.tr("Localizable", "a11y_hide_password") }
  /// Jump to bottom
  internal static var a11yJumpToBottom: String { return L10n.tr("Localizable", "a11y_jump_to_bottom") }
  /// Mentions only
  internal static var a11yNotificationsMentionsOnly: String { return L10n.tr("Localizable", "a11y_notifications_mentions_only") }
  /// Muted
  internal static var a11yNotificationsMuted: String { return L10n.tr("Localizable", "a11y_notifications_muted") }
  /// Page %1$d
  internal static func a11yPageN(_ p1: Int) -> String {
    return L10n.tr("Localizable", "a11y_page_n", p1)
  }
  /// Pause
  internal static var a11yPause: String { return L10n.tr("Localizable", "a11y_pause") }
  /// PIN field
  internal static var a11yPinField: String { return L10n.tr("Localizable", "a11y_pin_field") }
  /// Play
  internal static var a11yPlay: String { return L10n.tr("Localizable", "a11y_play") }
  /// Poll
  internal static var a11yPoll: String { return L10n.tr("Localizable", "a11y_poll") }
  /// Ended poll
  internal static var a11yPollEnd: String { return L10n.tr("Localizable", "a11y_poll_end") }
  /// React with %1$@
  internal static func a11yReactWith(_ p1: Any) -> String {
    return L10n.tr("Localizable", "a11y_react_with", String(describing: p1))
  }
  /// React with other emojis
  internal static var a11yReactWithOtherEmojis: String { return L10n.tr("Localizable", "a11y_react_with_other_emojis") }
  /// Read by %1$@ and %2$@
  internal static func a11yReadReceiptsMultiple(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "a11y_read_receipts_multiple", String(describing: p1), String(describing: p2))
  }
  /// Plural format key: "%#@COUNT@"
  internal static func a11yReadReceiptsMultipleWithOthers(_ p1: Int) -> String {
    return L10n.tr("Localizable", "a11y_read_receipts_multiple_with_others", p1)
  }
  /// Read by %1$@
  internal static func a11yReadReceiptsSingle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "a11y_read_receipts_single", String(describing: p1))
  }
  /// Tap to show all
  internal static var a11yReadReceiptsTapToShowAll: String { return L10n.tr("Localizable", "a11y_read_receipts_tap_to_show_all") }
  /// Remove reaction with %1$@
  internal static func a11yRemoveReactionWith(_ p1: Any) -> String {
    return L10n.tr("Localizable", "a11y_remove_reaction_with", String(describing: p1))
  }
  /// Send files
  internal static var a11ySendFiles: String { return L10n.tr("Localizable", "a11y_send_files") }
  /// Show password
  internal static var a11yShowPassword: String { return L10n.tr("Localizable", "a11y_show_password") }
  /// Start a call
  internal static var a11yStartCall: String { return L10n.tr("Localizable", "a11y_start_call") }
  /// User menu
  internal static var a11yUserMenu: String { return L10n.tr("Localizable", "a11y_user_menu") }
  /// Record voice message.
  internal static var a11yVoiceMessageRecord: String { return L10n.tr("Localizable", "a11y_voice_message_record") }
  /// Stop recording
  internal static var a11yVoiceMessageStopRecording: String { return L10n.tr("Localizable", "a11y_voice_message_stop_recording") }
  /// Accept
  internal static var actionAccept: String { return L10n.tr("Localizable", "action_accept") }
  /// Add to timeline
  internal static var actionAddToTimeline: String { return L10n.tr("Localizable", "action_add_to_timeline") }
  /// Back
  internal static var actionBack: String { return L10n.tr("Localizable", "action_back") }
  /// Call
  internal static var actionCall: String { return L10n.tr("Localizable", "action_call") }
  /// Cancel
  internal static var actionCancel: String { return L10n.tr("Localizable", "action_cancel") }
  /// Cancel for now
  internal static var actionCancelForNow: String { return L10n.tr("Localizable", "action_cancel_for_now") }
  /// Choose photo
  internal static var actionChoosePhoto: String { return L10n.tr("Localizable", "action_choose_photo") }
  /// Clear
  internal static var actionClear: String { return L10n.tr("Localizable", "action_clear") }
  /// Close
  internal static var actionClose: String { return L10n.tr("Localizable", "action_close") }
  /// Complete verification
  internal static var actionCompleteVerification: String { return L10n.tr("Localizable", "action_complete_verification") }
  /// Confirm
  internal static var actionConfirm: String { return L10n.tr("Localizable", "action_confirm") }
  /// Confirm password
  internal static var actionConfirmPassword: String { return L10n.tr("Localizable", "action_confirm_password") }
  /// Continue
  internal static var actionContinue: String { return L10n.tr("Localizable", "action_continue") }
  /// Copy
  internal static var actionCopy: String { return L10n.tr("Localizable", "action_copy") }
  /// Copy link
  internal static var actionCopyLink: String { return L10n.tr("Localizable", "action_copy_link") }
  /// Copy link to message
  internal static var actionCopyLinkToMessage: String { return L10n.tr("Localizable", "action_copy_link_to_message") }
  /// Create
  internal static var actionCreate: String { return L10n.tr("Localizable", "action_create") }
  /// Create a room
  internal static var actionCreateARoom: String { return L10n.tr("Localizable", "action_create_a_room") }
  /// Deactivate
  internal static var actionDeactivate: String { return L10n.tr("Localizable", "action_deactivate") }
  /// Deactivate account
  internal static var actionDeactivateAccount: String { return L10n.tr("Localizable", "action_deactivate_account") }
  /// Decline
  internal static var actionDecline: String { return L10n.tr("Localizable", "action_decline") }
  /// Delete Poll
  internal static var actionDeletePoll: String { return L10n.tr("Localizable", "action_delete_poll") }
  /// Disable
  internal static var actionDisable: String { return L10n.tr("Localizable", "action_disable") }
  /// Discard
  internal static var actionDiscard: String { return L10n.tr("Localizable", "action_discard") }
  /// Done
  internal static var actionDone: String { return L10n.tr("Localizable", "action_done") }
  /// Edit
  internal static var actionEdit: String { return L10n.tr("Localizable", "action_edit") }
  /// Edit poll
  internal static var actionEditPoll: String { return L10n.tr("Localizable", "action_edit_poll") }
  /// Enable
  internal static var actionEnable: String { return L10n.tr("Localizable", "action_enable") }
  /// End poll
  internal static var actionEndPoll: String { return L10n.tr("Localizable", "action_end_poll") }
  /// Enter PIN
  internal static var actionEnterPin: String { return L10n.tr("Localizable", "action_enter_pin") }
  /// Forgot password?
  internal static var actionForgotPassword: String { return L10n.tr("Localizable", "action_forgot_password") }
  /// Forward
  internal static var actionForward: String { return L10n.tr("Localizable", "action_forward") }
  /// Go back
  internal static var actionGoBack: String { return L10n.tr("Localizable", "action_go_back") }
  /// Invite
  internal static var actionInvite: String { return L10n.tr("Localizable", "action_invite") }
  /// Invite people
  internal static var actionInviteFriends: String { return L10n.tr("Localizable", "action_invite_friends") }
  /// Invite people to %1$@
  internal static func actionInviteFriendsToApp(_ p1: Any) -> String {
    return L10n.tr("Localizable", "action_invite_friends_to_app", String(describing: p1))
  }
  /// Invite people to %1$@
  internal static func actionInvitePeopleToApp(_ p1: Any) -> String {
    return L10n.tr("Localizable", "action_invite_people_to_app", String(describing: p1))
  }
  /// Invites
  internal static var actionInvitesList: String { return L10n.tr("Localizable", "action_invites_list") }
  /// Join
  internal static var actionJoin: String { return L10n.tr("Localizable", "action_join") }
  /// Learn more
  internal static var actionLearnMore: String { return L10n.tr("Localizable", "action_learn_more") }
  /// Leave
  internal static var actionLeave: String { return L10n.tr("Localizable", "action_leave") }
  /// Leave conversation
  internal static var actionLeaveConversation: String { return L10n.tr("Localizable", "action_leave_conversation") }
  /// Leave room
  internal static var actionLeaveRoom: String { return L10n.tr("Localizable", "action_leave_room") }
  /// Load more
  internal static var actionLoadMore: String { return L10n.tr("Localizable", "action_load_more") }
  /// Manage account
  internal static var actionManageAccount: String { return L10n.tr("Localizable", "action_manage_account") }
  /// Manage devices
  internal static var actionManageDevices: String { return L10n.tr("Localizable", "action_manage_devices") }
  /// Message
  internal static var actionMessage: String { return L10n.tr("Localizable", "action_message") }
  /// Next
  internal static var actionNext: String { return L10n.tr("Localizable", "action_next") }
  /// No
  internal static var actionNo: String { return L10n.tr("Localizable", "action_no") }
  /// Not now
  internal static var actionNotNow: String { return L10n.tr("Localizable", "action_not_now") }
  /// OK
  internal static var actionOk: String { return L10n.tr("Localizable", "action_ok") }
  /// Settings
  internal static var actionOpenSettings: String { return L10n.tr("Localizable", "action_open_settings") }
  /// Open with
  internal static var actionOpenWith: String { return L10n.tr("Localizable", "action_open_with") }
  /// Pin
  internal static var actionPin: String { return L10n.tr("Localizable", "action_pin") }
  /// Quick reply
  internal static var actionQuickReply: String { return L10n.tr("Localizable", "action_quick_reply") }
  /// Quote
  internal static var actionQuote: String { return L10n.tr("Localizable", "action_quote") }
  /// React
  internal static var actionReact: String { return L10n.tr("Localizable", "action_react") }
  /// Reject
  internal static var actionReject: String { return L10n.tr("Localizable", "action_reject") }
  /// Delete
  internal static var actionRemove: String { return L10n.tr("Localizable", "action_remove") }
  /// Reply
  internal static var actionReply: String { return L10n.tr("Localizable", "action_reply") }
  /// Reply in thread
  internal static var actionReplyInThread: String { return L10n.tr("Localizable", "action_reply_in_thread") }
  /// Report bug
  internal static var actionReportBug: String { return L10n.tr("Localizable", "action_report_bug") }
  /// Report content
  internal static var actionReportContent: String { return L10n.tr("Localizable", "action_report_content") }
  /// Reset
  internal static var actionReset: String { return L10n.tr("Localizable", "action_reset") }
  /// Reset identity
  internal static var actionResetIdentity: String { return L10n.tr("Localizable", "action_reset_identity") }
  /// Retry
  internal static var actionRetry: String { return L10n.tr("Localizable", "action_retry") }
  /// Retry decryption
  internal static var actionRetryDecryption: String { return L10n.tr("Localizable", "action_retry_decryption") }
  /// Save
  internal static var actionSave: String { return L10n.tr("Localizable", "action_save") }
  /// Search
  internal static var actionSearch: String { return L10n.tr("Localizable", "action_search") }
  /// Send
  internal static var actionSend: String { return L10n.tr("Localizable", "action_send") }
  /// Send message
  internal static var actionSendMessage: String { return L10n.tr("Localizable", "action_send_message") }
  /// Share
  internal static var actionShare: String { return L10n.tr("Localizable", "action_share") }
  /// Share link
  internal static var actionShareLink: String { return L10n.tr("Localizable", "action_share_link") }
  /// Show
  internal static var actionShow: String { return L10n.tr("Localizable", "action_show") }
  /// Sign in again
  internal static var actionSignInAgain: String { return L10n.tr("Localizable", "action_sign_in_again") }
  /// Sign out
  internal static var actionSignout: String { return L10n.tr("Localizable", "action_signout") }
  /// Sign out anyway
  internal static var actionSignoutAnyway: String { return L10n.tr("Localizable", "action_signout_anyway") }
  /// Skip
  internal static var actionSkip: String { return L10n.tr("Localizable", "action_skip") }
  /// Start
  internal static var actionStart: String { return L10n.tr("Localizable", "action_start") }
  /// Start chat
  internal static var actionStartChat: String { return L10n.tr("Localizable", "action_start_chat") }
  /// Start verification
  internal static var actionStartVerification: String { return L10n.tr("Localizable", "action_start_verification") }
  /// Tap to load map
  internal static var actionStaticMapLoad: String { return L10n.tr("Localizable", "action_static_map_load") }
  /// Take photo
  internal static var actionTakePhoto: String { return L10n.tr("Localizable", "action_take_photo") }
  /// Tap for options
  internal static var actionTapForOptions: String { return L10n.tr("Localizable", "action_tap_for_options") }
  /// Try again
  internal static var actionTryAgain: String { return L10n.tr("Localizable", "action_try_again") }
  /// Unpin
  internal static var actionUnpin: String { return L10n.tr("Localizable", "action_unpin") }
  /// View in timeline
  internal static var actionViewInTimeline: String { return L10n.tr("Localizable", "action_view_in_timeline") }
  /// View source
  internal static var actionViewSource: String { return L10n.tr("Localizable", "action_view_source") }
  /// Yes
  internal static var actionYes: String { return L10n.tr("Localizable", "action_yes") }
  /// Log Out & Upgrade
  internal static var bannerMigrateToNativeSlidingSyncAction: String { return L10n.tr("Localizable", "banner_migrate_to_native_sliding_sync_action") }
  /// Your server now supports a new, faster protocol. Log out and log back in to upgrade now. Doing this now will help you avoid a forced logout when the old protocol is removed later.
  internal static var bannerMigrateToNativeSlidingSyncDescription: String { return L10n.tr("Localizable", "banner_migrate_to_native_sliding_sync_description") }
  /// Your homeserver no longer supports the old protocol. Please log out and log back in to continue using the app.
  internal static var bannerMigrateToNativeSlidingSyncForceLogoutTitle: String { return L10n.tr("Localizable", "banner_migrate_to_native_sliding_sync_force_logout_title") }
  /// Upgrade available
  internal static var bannerMigrateToNativeSlidingSyncTitle: String { return L10n.tr("Localizable", "banner_migrate_to_native_sliding_sync_title") }
  /// About
  internal static var commonAbout: String { return L10n.tr("Localizable", "common_about") }
  /// Acceptable use policy
  internal static var commonAcceptableUsePolicy: String { return L10n.tr("Localizable", "common_acceptable_use_policy") }
  /// Advanced settings
  internal static var commonAdvancedSettings: String { return L10n.tr("Localizable", "common_advanced_settings") }
  /// Analytics
  internal static var commonAnalytics: String { return L10n.tr("Localizable", "common_analytics") }
  /// Appearance
  internal static var commonAppearance: String { return L10n.tr("Localizable", "common_appearance") }
  /// Audio
  internal static var commonAudio: String { return L10n.tr("Localizable", "common_audio") }
  /// Blocked users
  internal static var commonBlockedUsers: String { return L10n.tr("Localizable", "common_blocked_users") }
  /// Bubbles
  internal static var commonBubbles: String { return L10n.tr("Localizable", "common_bubbles") }
  /// Call in progress (unsupported)
  internal static var commonCallInvite: String { return L10n.tr("Localizable", "common_call_invite") }
  /// Call started
  internal static var commonCallStarted: String { return L10n.tr("Localizable", "common_call_started") }
  /// Chat backup
  internal static var commonChatBackup: String { return L10n.tr("Localizable", "common_chat_backup") }
  /// Copyright
  internal static var commonCopyright: String { return L10n.tr("Localizable", "common_copyright") }
  /// Creating room…
  internal static var commonCreatingRoom: String { return L10n.tr("Localizable", "common_creating_room") }
  /// Left room
  internal static var commonCurrentUserLeftRoom: String { return L10n.tr("Localizable", "common_current_user_left_room") }
  /// Dark
  internal static var commonDark: String { return L10n.tr("Localizable", "common_dark") }
  /// Decryption error
  internal static var commonDecryptionError: String { return L10n.tr("Localizable", "common_decryption_error") }
  /// Developer options
  internal static var commonDeveloperOptions: String { return L10n.tr("Localizable", "common_developer_options") }
  /// Direct chat
  internal static var commonDirectChat: String { return L10n.tr("Localizable", "common_direct_chat") }
  /// (edited)
  internal static var commonEditedSuffix: String { return L10n.tr("Localizable", "common_edited_suffix") }
  /// Editing
  internal static var commonEditing: String { return L10n.tr("Localizable", "common_editing") }
  /// * %1$@ %2$@
  internal static func commonEmote(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "common_emote", String(describing: p1), String(describing: p2))
  }
  /// Encryption enabled
  internal static var commonEncryptionEnabled: String { return L10n.tr("Localizable", "common_encryption_enabled") }
  /// Enter your PIN
  internal static var commonEnterYourPin: String { return L10n.tr("Localizable", "common_enter_your_pin") }
  /// Error
  internal static var commonError: String { return L10n.tr("Localizable", "common_error") }
  /// Everyone
  internal static var commonEveryone: String { return L10n.tr("Localizable", "common_everyone") }
  /// Face ID
  internal static var commonFaceIdIos: String { return L10n.tr("Localizable", "common_face_id_ios") }
  /// Failed
  internal static var commonFailed: String { return L10n.tr("Localizable", "common_failed") }
  /// Favourite
  internal static var commonFavourite: String { return L10n.tr("Localizable", "common_favourite") }
  /// Favourited
  internal static var commonFavourited: String { return L10n.tr("Localizable", "common_favourited") }
  /// File
  internal static var commonFile: String { return L10n.tr("Localizable", "common_file") }
  /// Forward message
  internal static var commonForwardMessage: String { return L10n.tr("Localizable", "common_forward_message") }
  /// GIF
  internal static var commonGif: String { return L10n.tr("Localizable", "common_gif") }
  /// Image
  internal static var commonImage: String { return L10n.tr("Localizable", "common_image") }
  /// In reply to %1$@
  internal static func commonInReplyTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_in_reply_to", String(describing: p1))
  }
  /// This Matrix ID can't be found, so the invite might not be received.
  internal static var commonInviteUnknownProfile: String { return L10n.tr("Localizable", "common_invite_unknown_profile") }
  /// Leaving room
  internal static var commonLeavingRoom: String { return L10n.tr("Localizable", "common_leaving_room") }
  /// Light
  internal static var commonLight: String { return L10n.tr("Localizable", "common_light") }
  /// Link copied to clipboard
  internal static var commonLinkCopiedToClipboard: String { return L10n.tr("Localizable", "common_link_copied_to_clipboard") }
  /// Loading…
  internal static var commonLoading: String { return L10n.tr("Localizable", "common_loading") }
  /// Plural format key: "%#@COUNT@"
  internal static func commonMemberCount(_ p1: Int) -> String {
    return L10n.tr("Localizable", "common_member_count", p1)
  }
  /// Message
  internal static var commonMessage: String { return L10n.tr("Localizable", "common_message") }
  /// Message actions
  internal static var commonMessageActions: String { return L10n.tr("Localizable", "common_message_actions") }
  /// Message layout
  internal static var commonMessageLayout: String { return L10n.tr("Localizable", "common_message_layout") }
  /// Message removed
  internal static var commonMessageRemoved: String { return L10n.tr("Localizable", "common_message_removed") }
  /// Modern
  internal static var commonModern: String { return L10n.tr("Localizable", "common_modern") }
  /// Mute
  internal static var commonMute: String { return L10n.tr("Localizable", "common_mute") }
  /// No results
  internal static var commonNoResults: String { return L10n.tr("Localizable", "common_no_results") }
  /// No room name
  internal static var commonNoRoomName: String { return L10n.tr("Localizable", "common_no_room_name") }
  /// Offline
  internal static var commonOffline: String { return L10n.tr("Localizable", "common_offline") }
  /// Optic ID
  internal static var commonOpticIdIos: String { return L10n.tr("Localizable", "common_optic_id_ios") }
  /// or
  internal static var commonOr: String { return L10n.tr("Localizable", "common_or") }
  /// Password
  internal static var commonPassword: String { return L10n.tr("Localizable", "common_password") }
  /// People
  internal static var commonPeople: String { return L10n.tr("Localizable", "common_people") }
  /// Permalink
  internal static var commonPermalink: String { return L10n.tr("Localizable", "common_permalink") }
  /// Permission
  internal static var commonPermission: String { return L10n.tr("Localizable", "common_permission") }
  /// Please wait…
  internal static var commonPleaseWait: String { return L10n.tr("Localizable", "common_please_wait") }
  /// Are you sure you want to end this poll?
  internal static var commonPollEndConfirmation: String { return L10n.tr("Localizable", "common_poll_end_confirmation") }
  /// Poll: %1$@
  internal static func commonPollSummary(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_poll_summary", String(describing: p1))
  }
  /// Total votes: %1$@
  internal static func commonPollTotalVotes(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_poll_total_votes", String(describing: p1))
  }
  /// Results will show after the poll has ended
  internal static var commonPollUndisclosedText: String { return L10n.tr("Localizable", "common_poll_undisclosed_text") }
  /// Plural format key: "%#@COUNT@"
  internal static func commonPollVotesCount(_ p1: Int) -> String {
    return L10n.tr("Localizable", "common_poll_votes_count", p1)
  }
  /// Privacy policy
  internal static var commonPrivacyPolicy: String { return L10n.tr("Localizable", "common_privacy_policy") }
  /// Reaction
  internal static var commonReaction: String { return L10n.tr("Localizable", "common_reaction") }
  /// Reactions
  internal static var commonReactions: String { return L10n.tr("Localizable", "common_reactions") }
  /// Recovery key
  internal static var commonRecoveryKey: String { return L10n.tr("Localizable", "common_recovery_key") }
  /// Refreshing…
  internal static var commonRefreshing: String { return L10n.tr("Localizable", "common_refreshing") }
  /// Replying to %1$@
  internal static func commonReplyingTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_replying_to", String(describing: p1))
  }
  /// Report a bug
  internal static var commonReportABug: String { return L10n.tr("Localizable", "common_report_a_bug") }
  /// Report a problem
  internal static var commonReportAProblem: String { return L10n.tr("Localizable", "common_report_a_problem") }
  /// Report submitted
  internal static var commonReportSubmitted: String { return L10n.tr("Localizable", "common_report_submitted") }
  /// Rich text editor
  internal static var commonRichTextEditor: String { return L10n.tr("Localizable", "common_rich_text_editor") }
  /// Room
  internal static var commonRoom: String { return L10n.tr("Localizable", "common_room") }
  /// Room name
  internal static var commonRoomName: String { return L10n.tr("Localizable", "common_room_name") }
  /// e.g. your project name
  internal static var commonRoomNamePlaceholder: String { return L10n.tr("Localizable", "common_room_name_placeholder") }
  /// Saved changes
  internal static var commonSavedChanges: String { return L10n.tr("Localizable", "common_saved_changes") }
  /// Saving
  internal static var commonSaving: String { return L10n.tr("Localizable", "common_saving") }
  /// Screen lock
  internal static var commonScreenLock: String { return L10n.tr("Localizable", "common_screen_lock") }
  /// Search for someone
  internal static var commonSearchForSomeone: String { return L10n.tr("Localizable", "common_search_for_someone") }
  /// Search results
  internal static var commonSearchResults: String { return L10n.tr("Localizable", "common_search_results") }
  /// Security
  internal static var commonSecurity: String { return L10n.tr("Localizable", "common_security") }
  /// Seen by
  internal static var commonSeenBy: String { return L10n.tr("Localizable", "common_seen_by") }
  /// Sending…
  internal static var commonSending: String { return L10n.tr("Localizable", "common_sending") }
  /// Sending failed
  internal static var commonSendingFailed: String { return L10n.tr("Localizable", "common_sending_failed") }
  /// Sent
  internal static var commonSent: String { return L10n.tr("Localizable", "common_sent") }
  /// Server not supported
  internal static var commonServerNotSupported: String { return L10n.tr("Localizable", "common_server_not_supported") }
  /// Server URL
  internal static var commonServerUrl: String { return L10n.tr("Localizable", "common_server_url") }
  /// Settings
  internal static var commonSettings: String { return L10n.tr("Localizable", "common_settings") }
  /// Shared location
  internal static var commonSharedLocation: String { return L10n.tr("Localizable", "common_shared_location") }
  /// Signing out
  internal static var commonSigningOut: String { return L10n.tr("Localizable", "common_signing_out") }
  /// Something went wrong
  internal static var commonSomethingWentWrong: String { return L10n.tr("Localizable", "common_something_went_wrong") }
  /// Starting chat…
  internal static var commonStartingChat: String { return L10n.tr("Localizable", "common_starting_chat") }
  /// Sticker
  internal static var commonSticker: String { return L10n.tr("Localizable", "common_sticker") }
  /// Success
  internal static var commonSuccess: String { return L10n.tr("Localizable", "common_success") }
  /// Suggestions
  internal static var commonSuggestions: String { return L10n.tr("Localizable", "common_suggestions") }
  /// Syncing
  internal static var commonSyncing: String { return L10n.tr("Localizable", "common_syncing") }
  /// System
  internal static var commonSystem: String { return L10n.tr("Localizable", "common_system") }
  /// Text
  internal static var commonText: String { return L10n.tr("Localizable", "common_text") }
  /// Third-party notices
  internal static var commonThirdPartyNotices: String { return L10n.tr("Localizable", "common_third_party_notices") }
  /// Thread
  internal static var commonThread: String { return L10n.tr("Localizable", "common_thread") }
  /// Topic
  internal static var commonTopic: String { return L10n.tr("Localizable", "common_topic") }
  /// What is this room about?
  internal static var commonTopicPlaceholder: String { return L10n.tr("Localizable", "common_topic_placeholder") }
  /// Touch ID
  internal static var commonTouchIdIos: String { return L10n.tr("Localizable", "common_touch_id_ios") }
  /// Unable to decrypt
  internal static var commonUnableToDecrypt: String { return L10n.tr("Localizable", "common_unable_to_decrypt") }
  /// You don't have access to this message
  internal static var commonUnableToDecryptNoAccess: String { return L10n.tr("Localizable", "common_unable_to_decrypt_no_access") }
  /// Invites couldn't be sent to one or more users.
  internal static var commonUnableToInviteMessage: String { return L10n.tr("Localizable", "common_unable_to_invite_message") }
  /// Unable to send invite(s)
  internal static var commonUnableToInviteTitle: String { return L10n.tr("Localizable", "common_unable_to_invite_title") }
  /// Unlock
  internal static var commonUnlock: String { return L10n.tr("Localizable", "common_unlock") }
  /// Unmute
  internal static var commonUnmute: String { return L10n.tr("Localizable", "common_unmute") }
  /// Unsupported event
  internal static var commonUnsupportedEvent: String { return L10n.tr("Localizable", "common_unsupported_event") }
  /// Username
  internal static var commonUsername: String { return L10n.tr("Localizable", "common_username") }
  /// Verification cancelled
  internal static var commonVerificationCancelled: String { return L10n.tr("Localizable", "common_verification_cancelled") }
  /// Verification complete
  internal static var commonVerificationComplete: String { return L10n.tr("Localizable", "common_verification_complete") }
  /// Verify device
  internal static var commonVerifyDevice: String { return L10n.tr("Localizable", "common_verify_device") }
  /// Video
  internal static var commonVideo: String { return L10n.tr("Localizable", "common_video") }
  /// Voice message
  internal static var commonVoiceMessage: String { return L10n.tr("Localizable", "common_voice_message") }
  /// Waiting…
  internal static var commonWaiting: String { return L10n.tr("Localizable", "common_waiting") }
  /// Waiting for this message
  internal static var commonWaitingForDecryptionKey: String { return L10n.tr("Localizable", "common_waiting_for_decryption_key") }
  /// Your chat backup is currently out of sync. You need to enter your recovery key to maintain access to your chat backup.
  internal static var confirmRecoveryKeyBannerMessage: String { return L10n.tr("Localizable", "confirm_recovery_key_banner_message") }
  /// Enter your recovery key
  internal static var confirmRecoveryKeyBannerTitle: String { return L10n.tr("Localizable", "confirm_recovery_key_banner_title") }
  /// %1$@ crashed the last time it was used. Would you like to share a crash report with us?
  internal static func crashDetectionDialogContent(_ p1: Any) -> String {
    return L10n.tr("Localizable", "crash_detection_dialog_content", String(describing: p1))
  }
  /// %1$@'s identity appears to have changed. %2$@
  internal static func cryptoIdentityChangePinViolation(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "crypto_identity_change_pin_violation", String(describing: p1), String(describing: p2))
  }
  /// In order to let the application use the camera, please grant the permission in the system settings.
  internal static var dialogPermissionCamera: String { return L10n.tr("Localizable", "dialog_permission_camera") }
  /// Please grant the permission in the system settings.
  internal static var dialogPermissionGeneric: String { return L10n.tr("Localizable", "dialog_permission_generic") }
  /// Grant access in Settings -> Location.
  internal static var dialogPermissionLocationDescriptionIos: String { return L10n.tr("Localizable", "dialog_permission_location_description_ios") }
  /// %1$@ does not have access to your location.
  internal static func dialogPermissionLocationTitleIos(_ p1: Any) -> String {
    return L10n.tr("Localizable", "dialog_permission_location_title_ios", String(describing: p1))
  }
  /// In order to let the application use the microphone, please grant the permission in the system settings.
  internal static var dialogPermissionMicrophone: String { return L10n.tr("Localizable", "dialog_permission_microphone") }
  /// Grant access so you can record and send messages with audio.
  internal static var dialogPermissionMicrophoneDescriptionIos: String { return L10n.tr("Localizable", "dialog_permission_microphone_description_ios") }
  /// %1$@ needs permission to access your microphone.
  internal static func dialogPermissionMicrophoneTitleIos(_ p1: Any) -> String {
    return L10n.tr("Localizable", "dialog_permission_microphone_title_ios", String(describing: p1))
  }
  /// In order to let the application display notifications, please grant the permission in the system settings.
  internal static var dialogPermissionNotification: String { return L10n.tr("Localizable", "dialog_permission_notification") }
  /// Confirmation
  internal static var dialogTitleConfirmation: String { return L10n.tr("Localizable", "dialog_title_confirmation") }
  /// Error
  internal static var dialogTitleError: String { return L10n.tr("Localizable", "dialog_title_error") }
  /// Success
  internal static var dialogTitleSuccess: String { return L10n.tr("Localizable", "dialog_title_success") }
  /// Warning
  internal static var dialogTitleWarning: String { return L10n.tr("Localizable", "dialog_title_warning") }
  /// Your changes won’t be saved
  internal static var dialogUnsavedChangesDescriptionIos: String { return L10n.tr("Localizable", "dialog_unsaved_changes_description_ios") }
  /// Save changes?
  internal static var dialogUnsavedChangesTitle: String { return L10n.tr("Localizable", "dialog_unsaved_changes_title") }
  /// Activities
  internal static var emojiPickerCategoryActivity: String { return L10n.tr("Localizable", "emoji_picker_category_activity") }
  /// Flags
  internal static var emojiPickerCategoryFlags: String { return L10n.tr("Localizable", "emoji_picker_category_flags") }
  /// Food & Drink
  internal static var emojiPickerCategoryFoods: String { return L10n.tr("Localizable", "emoji_picker_category_foods") }
  /// Animals & Nature
  internal static var emojiPickerCategoryNature: String { return L10n.tr("Localizable", "emoji_picker_category_nature") }
  /// Objects
  internal static var emojiPickerCategoryObjects: String { return L10n.tr("Localizable", "emoji_picker_category_objects") }
  /// Smileys & People
  internal static var emojiPickerCategoryPeople: String { return L10n.tr("Localizable", "emoji_picker_category_people") }
  /// Travel & Places
  internal static var emojiPickerCategoryPlaces: String { return L10n.tr("Localizable", "emoji_picker_category_places") }
  /// Symbols
  internal static var emojiPickerCategorySymbols: String { return L10n.tr("Localizable", "emoji_picker_category_symbols") }
  /// Your homeserver needs to be upgraded to support Matrix Authentication Service and account creation.
  internal static var errorAccountCreationNotPossible: String { return L10n.tr("Localizable", "error_account_creation_not_possible") }
  /// Failed creating the permalink
  internal static var errorFailedCreatingThePermalink: String { return L10n.tr("Localizable", "error_failed_creating_the_permalink") }
  /// %1$@ could not load the map. Please try again later.
  internal static func errorFailedLoadingMap(_ p1: Any) -> String {
    return L10n.tr("Localizable", "error_failed_loading_map", String(describing: p1))
  }
  /// Failed loading messages
  internal static var errorFailedLoadingMessages: String { return L10n.tr("Localizable", "error_failed_loading_messages") }
  /// %1$@ could not access your location. Please try again later.
  internal static func errorFailedLocatingUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "error_failed_locating_user", String(describing: p1))
  }
  /// Failed to upload your voice message.
  internal static var errorFailedUploadingVoiceMessage: String { return L10n.tr("Localizable", "error_failed_uploading_voice_message") }
  /// Message not found
  internal static var errorMessageNotFound: String { return L10n.tr("Localizable", "error_message_not_found") }
  /// No compatible app was found to handle this action.
  internal static var errorNoCompatibleAppFound: String { return L10n.tr("Localizable", "error_no_compatible_app_found") }
  /// Some messages have not been sent
  internal static var errorSomeMessagesHaveNotBeenSent: String { return L10n.tr("Localizable", "error_some_messages_have_not_been_sent") }
  /// Sorry, an error occurred
  internal static var errorUnknown: String { return L10n.tr("Localizable", "error_unknown") }
  /// The authenticity of this encrypted message can't be guaranteed on this device.
  internal static var eventShieldReasonAuthenticityNotGuaranteed: String { return L10n.tr("Localizable", "event_shield_reason_authenticity_not_guaranteed") }
  /// Encrypted by a previously-verified user.
  internal static var eventShieldReasonPreviouslyVerified: String { return L10n.tr("Localizable", "event_shield_reason_previously_verified") }
  /// Not encrypted.
  internal static var eventShieldReasonSentInClear: String { return L10n.tr("Localizable", "event_shield_reason_sent_in_clear") }
  /// Encrypted by an unknown or deleted device.
  internal static var eventShieldReasonUnknownDevice: String { return L10n.tr("Localizable", "event_shield_reason_unknown_device") }
  /// Encrypted by a device not verified by its owner.
  internal static var eventShieldReasonUnsignedDevice: String { return L10n.tr("Localizable", "event_shield_reason_unsigned_device") }
  /// Encrypted by an unverified user.
  internal static var eventShieldReasonUnverifiedIdentity: String { return L10n.tr("Localizable", "event_shield_reason_unverified_identity") }
  /// To ensure you never miss an important call, please change your settings to allow full-screen notifications when your phone is locked.
  internal static var fullScreenIntentBannerMessage: String { return L10n.tr("Localizable", "full_screen_intent_banner_message") }
  /// Enhance your call experience
  internal static var fullScreenIntentBannerTitle: String { return L10n.tr("Localizable", "full_screen_intent_banner_title") }
  /// 🔐️ Join me on %1$@
  internal static func inviteFriendsRichTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "invite_friends_rich_title", String(describing: p1))
  }
  /// Hey, talk to me on %1$@: %2$@
  internal static func inviteFriendsText(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "invite_friends_text", String(describing: p1), String(describing: p2))
  }
  /// Are you sure that you want to leave this conversation? This conversation is not public and you won't be able to rejoin without an invite.
  internal static var leaveConversationAlertSubtitle: String { return L10n.tr("Localizable", "leave_conversation_alert_subtitle") }
  /// Are you sure that you want to leave this room? You're the only person here. If you leave, no one will be able to join in the future, including you.
  internal static var leaveRoomAlertEmptySubtitle: String { return L10n.tr("Localizable", "leave_room_alert_empty_subtitle") }
  /// Are you sure that you want to leave this room? This room is not public and you won't be able to rejoin without an invite.
  internal static var leaveRoomAlertPrivateSubtitle: String { return L10n.tr("Localizable", "leave_room_alert_private_subtitle") }
  /// Are you sure that you want to leave the room?
  internal static var leaveRoomAlertSubtitle: String { return L10n.tr("Localizable", "leave_room_alert_subtitle") }
  /// %1$@ iOS
  internal static func loginInitialDeviceNameIos(_ p1: Any) -> String {
    return L10n.tr("Localizable", "login_initial_device_name_ios", String(describing: p1))
  }
  /// Notification
  internal static var notification: String { return L10n.tr("Localizable", "Notification") }
  /// Call
  internal static var notificationChannelCall: String { return L10n.tr("Localizable", "notification_channel_call") }
  /// Listening for events
  internal static var notificationChannelListeningForEvents: String { return L10n.tr("Localizable", "notification_channel_listening_for_events") }
  /// Noisy notifications
  internal static var notificationChannelNoisy: String { return L10n.tr("Localizable", "notification_channel_noisy") }
  /// Ringing calls
  internal static var notificationChannelRingingCalls: String { return L10n.tr("Localizable", "notification_channel_ringing_calls") }
  /// Silent notifications
  internal static var notificationChannelSilent: String { return L10n.tr("Localizable", "notification_channel_silent") }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationCompatSummaryLineForRoom(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_compat_summary_line_for_room", p1)
  }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationCompatSummaryTitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_compat_summary_title", p1)
  }
  /// Notification
  internal static var notificationFallbackContent: String { return L10n.tr("Localizable", "notification_fallback_content") }
  /// Incoming call
  internal static var notificationIncomingCall: String { return L10n.tr("Localizable", "notification_incoming_call") }
  /// ** Failed to send - please open room
  internal static var notificationInlineReplyFailed: String { return L10n.tr("Localizable", "notification_inline_reply_failed") }
  /// Join
  internal static var notificationInvitationActionJoin: String { return L10n.tr("Localizable", "notification_invitation_action_join") }
  /// Reject
  internal static var notificationInvitationActionReject: String { return L10n.tr("Localizable", "notification_invitation_action_reject") }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationInvitations(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_invitations", p1)
  }
  /// Invited you to chat
  internal static var notificationInviteBody: String { return L10n.tr("Localizable", "notification_invite_body") }
  /// %1$@ invited you to chat
  internal static func notificationInviteBodyWithSender(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notification_invite_body_with_sender", String(describing: p1))
  }
  /// Mentioned you: %1$@
  internal static func notificationMentionedYouBody(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notification_mentioned_you_body", String(describing: p1))
  }
  /// New Messages
  internal static var notificationNewMessages: String { return L10n.tr("Localizable", "notification_new_messages") }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationNewMessagesForRoom(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_new_messages_for_room", p1)
  }
  /// Reacted with %1$@
  internal static func notificationReactionBody(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notification_reaction_body", String(describing: p1))
  }
  /// Mark as read
  internal static var notificationRoomActionMarkAsRead: String { return L10n.tr("Localizable", "notification_room_action_mark_as_read") }
  /// Quick reply
  internal static var notificationRoomActionQuickReply: String { return L10n.tr("Localizable", "notification_room_action_quick_reply") }
  /// Invited you to join the room
  internal static var notificationRoomInviteBody: String { return L10n.tr("Localizable", "notification_room_invite_body") }
  /// %1$@ invited you to join the room
  internal static func notificationRoomInviteBodyWithSender(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notification_room_invite_body_with_sender", String(describing: p1))
  }
  /// Me
  internal static var notificationSenderMe: String { return L10n.tr("Localizable", "notification_sender_me") }
  /// %1$@ mentioned or replied
  internal static func notificationSenderMentionReply(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notification_sender_mention_reply", String(describing: p1))
  }
  /// You are viewing the notification! Click me!
  internal static var notificationTestPushNotificationContent: String { return L10n.tr("Localizable", "notification_test_push_notification_content") }
  /// %1$@: %2$@
  internal static func notificationTickerTextDm(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "notification_ticker_text_dm", String(describing: p1), String(describing: p2))
  }
  /// %1$@: %2$@ %3$@
  internal static func notificationTickerTextGroup(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "notification_ticker_text_group", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationUnreadNotifiedMessages(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages", p1)
  }
  /// %1$@ and %2$@
  internal static func notificationUnreadNotifiedMessagesAndInvitation(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_and_invitation", String(describing: p1), String(describing: p2))
  }
  /// %1$@ in %2$@
  internal static func notificationUnreadNotifiedMessagesInRoom(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_in_room", String(describing: p1), String(describing: p2))
  }
  /// %1$@ in %2$@ and %3$@
  internal static func notificationUnreadNotifiedMessagesInRoomAndInvitation(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_in_room_and_invitation", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationUnreadNotifiedMessagesInRoomRooms(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_in_room_rooms", p1)
  }
  /// Rageshake to report bug
  internal static var preferenceRageshake: String { return L10n.tr("Localizable", "preference_rageshake") }
  /// You seem to be shaking the phone in frustration. Would you like to open the bug report screen?
  internal static var rageshakeDetectionDialogContent: String { return L10n.tr("Localizable", "rageshake_detection_dialog_content") }
  /// Add attachment
  internal static var richTextEditorA11yAddAttachment: String { return L10n.tr("Localizable", "rich_text_editor_a11y_add_attachment") }
  /// Toggle bullet list
  internal static var richTextEditorBulletList: String { return L10n.tr("Localizable", "rich_text_editor_bullet_list") }
  /// Close formatting options
  internal static var richTextEditorCloseFormattingOptions: String { return L10n.tr("Localizable", "rich_text_editor_close_formatting_options") }
  /// Toggle code block
  internal static var richTextEditorCodeBlock: String { return L10n.tr("Localizable", "rich_text_editor_code_block") }
  /// Message…
  internal static var richTextEditorComposerPlaceholder: String { return L10n.tr("Localizable", "rich_text_editor_composer_placeholder") }
  /// Create a link
  internal static var richTextEditorCreateLink: String { return L10n.tr("Localizable", "rich_text_editor_create_link") }
  /// Edit link
  internal static var richTextEditorEditLink: String { return L10n.tr("Localizable", "rich_text_editor_edit_link") }
  /// Apply bold format
  internal static var richTextEditorFormatBold: String { return L10n.tr("Localizable", "rich_text_editor_format_bold") }
  /// Apply italic format
  internal static var richTextEditorFormatItalic: String { return L10n.tr("Localizable", "rich_text_editor_format_italic") }
  /// Apply strikethrough format
  internal static var richTextEditorFormatStrikethrough: String { return L10n.tr("Localizable", "rich_text_editor_format_strikethrough") }
  /// Apply underline format
  internal static var richTextEditorFormatUnderline: String { return L10n.tr("Localizable", "rich_text_editor_format_underline") }
  /// Toggle full screen mode
  internal static var richTextEditorFullScreenToggle: String { return L10n.tr("Localizable", "rich_text_editor_full_screen_toggle") }
  /// Indent
  internal static var richTextEditorIndent: String { return L10n.tr("Localizable", "rich_text_editor_indent") }
  /// Apply inline code format
  internal static var richTextEditorInlineCode: String { return L10n.tr("Localizable", "rich_text_editor_inline_code") }
  /// Set link
  internal static var richTextEditorLink: String { return L10n.tr("Localizable", "rich_text_editor_link") }
  /// Toggle numbered list
  internal static var richTextEditorNumberedList: String { return L10n.tr("Localizable", "rich_text_editor_numbered_list") }
  /// Open compose options
  internal static var richTextEditorOpenComposeOptions: String { return L10n.tr("Localizable", "rich_text_editor_open_compose_options") }
  /// Toggle quote
  internal static var richTextEditorQuote: String { return L10n.tr("Localizable", "rich_text_editor_quote") }
  /// Remove link
  internal static var richTextEditorRemoveLink: String { return L10n.tr("Localizable", "rich_text_editor_remove_link") }
  /// Unindent
  internal static var richTextEditorUnindent: String { return L10n.tr("Localizable", "rich_text_editor_unindent") }
  /// Link
  internal static var richTextEditorUrlPlaceholder: String { return L10n.tr("Localizable", "rich_text_editor_url_placeholder") }
  /// Change account provider
  internal static var screenAccountProviderChange: String { return L10n.tr("Localizable", "screen_account_provider_change") }
  /// Homeserver address
  internal static var screenAccountProviderFormHint: String { return L10n.tr("Localizable", "screen_account_provider_form_hint") }
  /// Enter a search term or a domain address.
  internal static var screenAccountProviderFormNotice: String { return L10n.tr("Localizable", "screen_account_provider_form_notice") }
  /// Search for a company, community, or private server.
  internal static var screenAccountProviderFormSubtitle: String { return L10n.tr("Localizable", "screen_account_provider_form_subtitle") }
  /// Find an account provider
  internal static var screenAccountProviderFormTitle: String { return L10n.tr("Localizable", "screen_account_provider_form_title") }
  /// This is where your conversations will live — just like you would use an email provider to keep your emails.
  internal static var screenAccountProviderSigninSubtitle: String { return L10n.tr("Localizable", "screen_account_provider_signin_subtitle") }
  /// You’re about to sign in to %@
  internal static func screenAccountProviderSigninTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_account_provider_signin_title", String(describing: p1))
  }
  /// This is where your conversations will live — just like you would use an email provider to keep your emails.
  internal static var screenAccountProviderSignupSubtitle: String { return L10n.tr("Localizable", "screen_account_provider_signup_subtitle") }
  /// You’re about to create an account on %@
  internal static func screenAccountProviderSignupTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_account_provider_signup_title", String(describing: p1))
  }
  /// Developer mode
  internal static var screenAdvancedSettingsDeveloperMode: String { return L10n.tr("Localizable", "screen_advanced_settings_developer_mode") }
  /// Enable to have access to features and functionality for developers.
  internal static var screenAdvancedSettingsDeveloperModeDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_developer_mode_description") }
  /// Custom Element Call base URL
  internal static var screenAdvancedSettingsElementCallBaseUrl: String { return L10n.tr("Localizable", "screen_advanced_settings_element_call_base_url") }
  /// Set a custom base URL for Element Call.
  internal static var screenAdvancedSettingsElementCallBaseUrlDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_element_call_base_url_description") }
  /// Invalid URL, please make sure you include the protocol (http/https) and the correct address.
  internal static var screenAdvancedSettingsElementCallBaseUrlValidationError: String { return L10n.tr("Localizable", "screen_advanced_settings_element_call_base_url_validation_error") }
  /// Disable the rich text editor to type Markdown manually.
  internal static var screenAdvancedSettingsRichTextEditorDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_rich_text_editor_description") }
  /// Read receipts
  internal static var screenAdvancedSettingsSendReadReceipts: String { return L10n.tr("Localizable", "screen_advanced_settings_send_read_receipts") }
  /// If turned off, your read receipts won't be sent to anyone. You will still receive read receipts from other users.
  internal static var screenAdvancedSettingsSendReadReceiptsDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_send_read_receipts_description") }
  /// Share presence
  internal static var screenAdvancedSettingsSharePresence: String { return L10n.tr("Localizable", "screen_advanced_settings_share_presence") }
  /// If turned off, you won’t be able to send or receive read receipts or typing notifications.
  internal static var screenAdvancedSettingsSharePresenceDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_share_presence_description") }
  /// Enable option to view message source in the timeline.
  internal static var screenAdvancedSettingsViewSourceDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_view_source_description") }
  /// We won't record or profile any personal data
  internal static var screenAnalyticsPromptDataUsage: String { return L10n.tr("Localizable", "screen_analytics_prompt_data_usage") }
  /// Share anonymous usage data to help us identify issues.
  internal static var screenAnalyticsPromptHelpUsImprove: String { return L10n.tr("Localizable", "screen_analytics_prompt_help_us_improve") }
  /// You can read all our terms %1$@.
  internal static func screenAnalyticsPromptReadTerms(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_analytics_prompt_read_terms", String(describing: p1))
  }
  /// here
  internal static var screenAnalyticsPromptReadTermsContentLink: String { return L10n.tr("Localizable", "screen_analytics_prompt_read_terms_content_link") }
  /// You can turn this off anytime
  internal static var screenAnalyticsPromptSettings: String { return L10n.tr("Localizable", "screen_analytics_prompt_settings") }
  /// We won't share your data with third parties
  internal static var screenAnalyticsPromptThirdPartySharing: String { return L10n.tr("Localizable", "screen_analytics_prompt_third_party_sharing") }
  /// Help improve %1$@
  internal static func screenAnalyticsPromptTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_analytics_prompt_title", String(describing: p1))
  }
  /// Share anonymous usage data to help us identify issues.
  internal static var screenAnalyticsSettingsHelpUsImprove: String { return L10n.tr("Localizable", "screen_analytics_settings_help_us_improve") }
  /// You can read all our terms %1$@.
  internal static func screenAnalyticsSettingsReadTerms(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_analytics_settings_read_terms", String(describing: p1))
  }
  /// here
  internal static var screenAnalyticsSettingsReadTermsContentLink: String { return L10n.tr("Localizable", "screen_analytics_settings_read_terms_content_link") }
  /// Share analytics data
  internal static var screenAnalyticsSettingsShareData: String { return L10n.tr("Localizable", "screen_analytics_settings_share_data") }
  /// biometric authentication
  internal static var screenAppLockBiometricAuthentication: String { return L10n.tr("Localizable", "screen_app_lock_biometric_authentication") }
  /// biometric unlock
  internal static var screenAppLockBiometricUnlock: String { return L10n.tr("Localizable", "screen_app_lock_biometric_unlock") }
  /// Authentication is needed to access your app
  internal static var screenAppLockBiometricUnlockReasonIos: String { return L10n.tr("Localizable", "screen_app_lock_biometric_unlock_reason_ios") }
  /// Forgot PIN?
  internal static var screenAppLockForgotPin: String { return L10n.tr("Localizable", "screen_app_lock_forgot_pin") }
  /// Change PIN code
  internal static var screenAppLockSettingsChangePin: String { return L10n.tr("Localizable", "screen_app_lock_settings_change_pin") }
  /// Allow biometric unlock
  internal static var screenAppLockSettingsEnableBiometricUnlock: String { return L10n.tr("Localizable", "screen_app_lock_settings_enable_biometric_unlock") }
  /// Allow Face ID
  internal static var screenAppLockSettingsEnableFaceIdIos: String { return L10n.tr("Localizable", "screen_app_lock_settings_enable_face_id_ios") }
  /// Allow Optic ID
  internal static var screenAppLockSettingsEnableOpticIdIos: String { return L10n.tr("Localizable", "screen_app_lock_settings_enable_optic_id_ios") }
  /// Allow Touch ID
  internal static var screenAppLockSettingsEnableTouchIdIos: String { return L10n.tr("Localizable", "screen_app_lock_settings_enable_touch_id_ios") }
  /// Remove PIN
  internal static var screenAppLockSettingsRemovePin: String { return L10n.tr("Localizable", "screen_app_lock_settings_remove_pin") }
  /// Are you sure you want to remove PIN?
  internal static var screenAppLockSettingsRemovePinAlertMessage: String { return L10n.tr("Localizable", "screen_app_lock_settings_remove_pin_alert_message") }
  /// Remove PIN?
  internal static var screenAppLockSettingsRemovePinAlertTitle: String { return L10n.tr("Localizable", "screen_app_lock_settings_remove_pin_alert_title") }
  /// Allow %1$@
  internal static func screenAppLockSetupBiometricUnlockAllowTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_app_lock_setup_biometric_unlock_allow_title", String(describing: p1))
  }
  /// I’d rather use PIN
  internal static var screenAppLockSetupBiometricUnlockSkip: String { return L10n.tr("Localizable", "screen_app_lock_setup_biometric_unlock_skip") }
  /// Save yourself some time and use %1$@ to unlock the app each time
  internal static func screenAppLockSetupBiometricUnlockSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_app_lock_setup_biometric_unlock_subtitle", String(describing: p1))
  }
  /// Choose PIN
  internal static var screenAppLockSetupChoosePin: String { return L10n.tr("Localizable", "screen_app_lock_setup_choose_pin") }
  /// Confirm PIN
  internal static var screenAppLockSetupConfirmPin: String { return L10n.tr("Localizable", "screen_app_lock_setup_confirm_pin") }
  /// Lock %1$@ to add extra security to your chats.
  /// 
  /// Choose something memorable. If you forget this PIN, you will be logged out of the app.
  internal static func screenAppLockSetupPinContext(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_app_lock_setup_pin_context", String(describing: p1))
  }
  /// You cannot choose this as your PIN code for security reasons
  internal static var screenAppLockSetupPinForbiddenDialogContent: String { return L10n.tr("Localizable", "screen_app_lock_setup_pin_forbidden_dialog_content") }
  /// Choose a different PIN
  internal static var screenAppLockSetupPinForbiddenDialogTitle: String { return L10n.tr("Localizable", "screen_app_lock_setup_pin_forbidden_dialog_title") }
  /// Please enter the same PIN twice
  internal static var screenAppLockSetupPinMismatchDialogContent: String { return L10n.tr("Localizable", "screen_app_lock_setup_pin_mismatch_dialog_content") }
  /// PINs don't match
  internal static var screenAppLockSetupPinMismatchDialogTitle: String { return L10n.tr("Localizable", "screen_app_lock_setup_pin_mismatch_dialog_title") }
  /// You’ll need to re-login and create a new PIN to proceed
  internal static var screenAppLockSignoutAlertMessage: String { return L10n.tr("Localizable", "screen_app_lock_signout_alert_message") }
  /// You are being signed out
  internal static var screenAppLockSignoutAlertTitle: String { return L10n.tr("Localizable", "screen_app_lock_signout_alert_title") }
  /// Plural format key: "%#@COUNT@"
  internal static func screenAppLockSubtitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_app_lock_subtitle", p1)
  }
  /// Plural format key: "%#@COUNT@"
  internal static func screenAppLockSubtitleWrongPin(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_app_lock_subtitle_wrong_pin", p1)
  }
  /// You have no blocked users
  internal static var screenBlockedUsersEmpty: String { return L10n.tr("Localizable", "screen_blocked_users_empty") }
  /// Unblock
  internal static var screenBlockedUsersUnblockAlertAction: String { return L10n.tr("Localizable", "screen_blocked_users_unblock_alert_action") }
  /// You'll be able to see all messages from them again.
  internal static var screenBlockedUsersUnblockAlertDescription: String { return L10n.tr("Localizable", "screen_blocked_users_unblock_alert_description") }
  /// Unblock user
  internal static var screenBlockedUsersUnblockAlertTitle: String { return L10n.tr("Localizable", "screen_blocked_users_unblock_alert_title") }
  /// Unblocking…
  internal static var screenBlockedUsersUnblocking: String { return L10n.tr("Localizable", "screen_blocked_users_unblocking") }
  /// Attach screenshot
  internal static var screenBugReportAttachScreenshot: String { return L10n.tr("Localizable", "screen_bug_report_attach_screenshot") }
  /// You may contact me if you have any follow up questions.
  internal static var screenBugReportContactMe: String { return L10n.tr("Localizable", "screen_bug_report_contact_me") }
  /// Contact me
  internal static var screenBugReportContactMeTitle: String { return L10n.tr("Localizable", "screen_bug_report_contact_me_title") }
  /// Edit screenshot
  internal static var screenBugReportEditScreenshot: String { return L10n.tr("Localizable", "screen_bug_report_edit_screenshot") }
  /// Please describe the problem. What did you do? What did you expect to happen? What actually happened. Please go into as much detail as you can.
  internal static var screenBugReportEditorDescription: String { return L10n.tr("Localizable", "screen_bug_report_editor_description") }
  /// Describe the problem…
  internal static var screenBugReportEditorPlaceholder: String { return L10n.tr("Localizable", "screen_bug_report_editor_placeholder") }
  /// If possible, please write the description in English.
  internal static var screenBugReportEditorSupporting: String { return L10n.tr("Localizable", "screen_bug_report_editor_supporting") }
  /// The description is too short, please provide more details about what happened. Thanks!
  internal static var screenBugReportErrorDescriptionTooShort: String { return L10n.tr("Localizable", "screen_bug_report_error_description_too_short") }
  /// Send crash logs
  internal static var screenBugReportIncludeCrashLogs: String { return L10n.tr("Localizable", "screen_bug_report_include_crash_logs") }
  /// Allow logs
  internal static var screenBugReportIncludeLogs: String { return L10n.tr("Localizable", "screen_bug_report_include_logs") }
  /// Send screenshot
  internal static var screenBugReportIncludeScreenshot: String { return L10n.tr("Localizable", "screen_bug_report_include_screenshot") }
  /// Logs will be included with your message to make sure that everything is working properly. To send your message without logs, turn off this setting.
  internal static var screenBugReportLogsDescription: String { return L10n.tr("Localizable", "screen_bug_report_logs_description") }
  /// %1$@ crashed the last time it was used. Would you like to share a crash report with us?
  internal static func screenBugReportRashLogsAlertTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_bug_report_rash_logs_alert_title", String(describing: p1))
  }
  /// View logs
  internal static var screenBugReportViewLogs: String { return L10n.tr("Localizable", "screen_bug_report_view_logs") }
  /// Matrix.org is a large, free server on the public Matrix network for secure, decentralised communication, run by the Matrix.org Foundation.
  internal static var screenChangeAccountProviderMatrixOrgSubtitle: String { return L10n.tr("Localizable", "screen_change_account_provider_matrix_org_subtitle") }
  /// Other
  internal static var screenChangeAccountProviderOther: String { return L10n.tr("Localizable", "screen_change_account_provider_other") }
  /// Use a different account provider, such as your own private server or a work account.
  internal static var screenChangeAccountProviderSubtitle: String { return L10n.tr("Localizable", "screen_change_account_provider_subtitle") }
  /// Change account provider
  internal static var screenChangeAccountProviderTitle: String { return L10n.tr("Localizable", "screen_change_account_provider_title") }
  /// We couldn't reach this homeserver. Please check that you have entered the homeserver URL correctly. If the URL is correct, contact your homeserver administrator for further help.
  internal static var screenChangeServerErrorInvalidHomeserver: String { return L10n.tr("Localizable", "screen_change_server_error_invalid_homeserver") }
  /// Sliding sync isn't available due to an issue in the well-known file:
  /// %1$@
  internal static func screenChangeServerErrorInvalidWellKnown(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_change_server_error_invalid_well_known", String(describing: p1))
  }
  /// This server currently doesn’t support sliding sync.
  internal static var screenChangeServerErrorNoSlidingSyncMessage: String { return L10n.tr("Localizable", "screen_change_server_error_no_sliding_sync_message") }
  /// Homeserver URL
  internal static var screenChangeServerFormHeader: String { return L10n.tr("Localizable", "screen_change_server_form_header") }
  /// You can only connect to an existing server that supports sliding sync. Your homeserver admin will need to configure it. %1$@
  internal static func screenChangeServerFormNotice(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_change_server_form_notice", String(describing: p1))
  }
  /// What is the address of your server?
  internal static var screenChangeServerSubtitle: String { return L10n.tr("Localizable", "screen_change_server_subtitle") }
  /// Select your server
  internal static var screenChangeServerTitle: String { return L10n.tr("Localizable", "screen_change_server_title") }
  /// Turn off backup
  internal static var screenChatBackupKeyBackupActionDisable: String { return L10n.tr("Localizable", "screen_chat_backup_key_backup_action_disable") }
  /// Turn on backup
  internal static var screenChatBackupKeyBackupActionEnable: String { return L10n.tr("Localizable", "screen_chat_backup_key_backup_action_enable") }
  /// Backup ensures that you don't lose your message history. %1$@.
  internal static func screenChatBackupKeyBackupDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_chat_backup_key_backup_description", String(describing: p1))
  }
  /// Backup
  internal static var screenChatBackupKeyBackupTitle: String { return L10n.tr("Localizable", "screen_chat_backup_key_backup_title") }
  /// Change recovery key
  internal static var screenChatBackupRecoveryActionChange: String { return L10n.tr("Localizable", "screen_chat_backup_recovery_action_change") }
  /// Enter recovery key
  internal static var screenChatBackupRecoveryActionConfirm: String { return L10n.tr("Localizable", "screen_chat_backup_recovery_action_confirm") }
  /// Your chat backup is currently out of sync.
  internal static var screenChatBackupRecoveryActionConfirmDescription: String { return L10n.tr("Localizable", "screen_chat_backup_recovery_action_confirm_description") }
  /// Set up recovery
  internal static var screenChatBackupRecoveryActionSetup: String { return L10n.tr("Localizable", "screen_chat_backup_recovery_action_setup") }
  /// Get access to your encrypted messages if you lose all your devices or are signed out of %1$@ everywhere.
  internal static func screenChatBackupRecoveryActionSetupDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_chat_backup_recovery_action_setup_description", String(describing: p1))
  }
  /// Create account
  internal static var screenCreateAccountTitle: String { return L10n.tr("Localizable", "screen_create_account_title") }
  /// Open %1$@ in a desktop device
  internal static func screenCreateNewRecoveryKeyListItem1(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_1", String(describing: p1))
  }
  /// Sign into your account again
  internal static var screenCreateNewRecoveryKeyListItem2: String { return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_2") }
  /// When asked to verify your device, select %1$@
  internal static func screenCreateNewRecoveryKeyListItem3(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_3", String(describing: p1))
  }
  /// “Reset all”
  internal static var screenCreateNewRecoveryKeyListItem3ResetAll: String { return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_3_reset_all") }
  /// Follow the instructions to create a new recovery key
  internal static var screenCreateNewRecoveryKeyListItem4: String { return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_4") }
  /// Save your new recovery key in a password manager or encrypted note
  internal static var screenCreateNewRecoveryKeyListItem5: String { return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_5") }
  /// Reset the encryption for your account using another device
  internal static var screenCreateNewRecoveryKeyTitle: String { return L10n.tr("Localizable", "screen_create_new_recovery_key_title") }
  /// Add option
  internal static var screenCreatePollAddOptionBtn: String { return L10n.tr("Localizable", "screen_create_poll_add_option_btn") }
  /// Show results only after poll ends
  internal static var screenCreatePollAnonymousDesc: String { return L10n.tr("Localizable", "screen_create_poll_anonymous_desc") }
  /// Hide votes
  internal static var screenCreatePollAnonymousHeadline: String { return L10n.tr("Localizable", "screen_create_poll_anonymous_headline") }
  /// Option %1$d
  internal static func screenCreatePollAnswerHint(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_create_poll_answer_hint", p1)
  }
  /// Your changes won’t be saved
  internal static var screenCreatePollCancelConfirmationContentIos: String { return L10n.tr("Localizable", "screen_create_poll_cancel_confirmation_content_ios") }
  /// Cancel Poll
  internal static var screenCreatePollCancelConfirmationTitleIos: String { return L10n.tr("Localizable", "screen_create_poll_cancel_confirmation_title_ios") }
  /// Question or topic
  internal static var screenCreatePollQuestionDesc: String { return L10n.tr("Localizable", "screen_create_poll_question_desc") }
  /// What is the poll about?
  internal static var screenCreatePollQuestionHint: String { return L10n.tr("Localizable", "screen_create_poll_question_hint") }
  /// Create Poll
  internal static var screenCreatePollTitle: String { return L10n.tr("Localizable", "screen_create_poll_title") }
  /// Anyone can join this room
  internal static var screenCreateRoomAccessSectionAnyoneOptionDescription: String { return L10n.tr("Localizable", "screen_create_room_access_section_anyone_option_description") }
  /// Anyone
  internal static var screenCreateRoomAccessSectionAnyoneOptionTitle: String { return L10n.tr("Localizable", "screen_create_room_access_section_anyone_option_title") }
  /// Room Access
  internal static var screenCreateRoomAccessSectionHeader: String { return L10n.tr("Localizable", "screen_create_room_access_section_header") }
  /// Anyone can ask to join the room but an administrator or a moderator will have to accept the request
  internal static var screenCreateRoomAccessSectionKnockingOptionDescription: String { return L10n.tr("Localizable", "screen_create_room_access_section_knocking_option_description") }
  /// Ask to join
  internal static var screenCreateRoomAccessSectionKnockingOptionTitle: String { return L10n.tr("Localizable", "screen_create_room_access_section_knocking_option_title") }
  /// New room
  internal static var screenCreateRoomActionCreateRoom: String { return L10n.tr("Localizable", "screen_create_room_action_create_room") }
  /// Invite people
  internal static var screenCreateRoomAddPeopleTitle: String { return L10n.tr("Localizable", "screen_create_room_add_people_title") }
  /// An error occurred when creating the room
  internal static var screenCreateRoomErrorCreatingRoom: String { return L10n.tr("Localizable", "screen_create_room_error_creating_room") }
  /// Messages in this room are encrypted. Encryption can’t be disabled afterwards.
  internal static var screenCreateRoomPrivateOptionDescription: String { return L10n.tr("Localizable", "screen_create_room_private_option_description") }
  /// Private room (invite only)
  internal static var screenCreateRoomPrivateOptionTitle: String { return L10n.tr("Localizable", "screen_create_room_private_option_title") }
  /// Messages are not encrypted and anyone can read them. You can enable encryption at a later date.
  internal static var screenCreateRoomPublicOptionDescription: String { return L10n.tr("Localizable", "screen_create_room_public_option_description") }
  /// Public room (anyone)
  internal static var screenCreateRoomPublicOptionTitle: String { return L10n.tr("Localizable", "screen_create_room_public_option_title") }
  /// Room name
  internal static var screenCreateRoomRoomNameLabel: String { return L10n.tr("Localizable", "screen_create_room_room_name_label") }
  /// Create a room
  internal static var screenCreateRoomTitle: String { return L10n.tr("Localizable", "screen_create_room_title") }
  /// Topic (optional)
  internal static var screenCreateRoomTopicLabel: String { return L10n.tr("Localizable", "screen_create_room_topic_label") }
  /// Please confirm that you want to deactivate your account. This action cannot be undone.
  internal static var screenDeactivateAccountConfirmationDialogContent: String { return L10n.tr("Localizable", "screen_deactivate_account_confirmation_dialog_content") }
  /// Delete all my messages
  internal static var screenDeactivateAccountDeleteAllMessages: String { return L10n.tr("Localizable", "screen_deactivate_account_delete_all_messages") }
  /// Warning: Future users may see incomplete conversations.
  internal static var screenDeactivateAccountDeleteAllMessagesNotice: String { return L10n.tr("Localizable", "screen_deactivate_account_delete_all_messages_notice") }
  /// Deactivating your account is %1$@, it will:
  internal static func screenDeactivateAccountDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_deactivate_account_description", String(describing: p1))
  }
  /// irreversible
  internal static var screenDeactivateAccountDescriptionBoldPart: String { return L10n.tr("Localizable", "screen_deactivate_account_description_bold_part") }
  /// %1$@ your account (you can't log back in, and your ID can't be reused).
  internal static func screenDeactivateAccountListItem1(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_deactivate_account_list_item_1", String(describing: p1))
  }
  /// Permanently disable
  internal static var screenDeactivateAccountListItem1BoldPart: String { return L10n.tr("Localizable", "screen_deactivate_account_list_item_1_bold_part") }
  /// Remove you from all chat rooms.
  internal static var screenDeactivateAccountListItem2: String { return L10n.tr("Localizable", "screen_deactivate_account_list_item_2") }
  /// Delete your account information from our identity server.
  internal static var screenDeactivateAccountListItem3: String { return L10n.tr("Localizable", "screen_deactivate_account_list_item_3") }
  /// Your messages will still be visible to registered users but won’t be available to new or unregistered users if you choose to delete them.
  internal static var screenDeactivateAccountListItem4: String { return L10n.tr("Localizable", "screen_deactivate_account_list_item_4") }
  /// Deactivate account
  internal static var screenDeactivateAccountTitle: String { return L10n.tr("Localizable", "screen_deactivate_account_title") }
  /// Block
  internal static var screenDmDetailsBlockAlertAction: String { return L10n.tr("Localizable", "screen_dm_details_block_alert_action") }
  /// Blocked users won't be able to send you messages and all their messages will be hidden. You can unblock them anytime.
  internal static var screenDmDetailsBlockAlertDescription: String { return L10n.tr("Localizable", "screen_dm_details_block_alert_description") }
  /// Block user
  internal static var screenDmDetailsBlockUser: String { return L10n.tr("Localizable", "screen_dm_details_block_user") }
  /// Unblock
  internal static var screenDmDetailsUnblockAlertAction: String { return L10n.tr("Localizable", "screen_dm_details_unblock_alert_action") }
  /// You'll be able to see all messages from them again.
  internal static var screenDmDetailsUnblockAlertDescription: String { return L10n.tr("Localizable", "screen_dm_details_unblock_alert_description") }
  /// Unblock user
  internal static var screenDmDetailsUnblockUser: String { return L10n.tr("Localizable", "screen_dm_details_unblock_user") }
  /// Are you sure you want to delete this poll?
  internal static var screenEditPollDeleteConfirmation: String { return L10n.tr("Localizable", "screen_edit_poll_delete_confirmation") }
  /// Delete Poll
  internal static var screenEditPollDeleteConfirmationTitle: String { return L10n.tr("Localizable", "screen_edit_poll_delete_confirmation_title") }
  /// Edit poll
  internal static var screenEditPollTitle: String { return L10n.tr("Localizable", "screen_edit_poll_title") }
  /// Display name
  internal static var screenEditProfileDisplayName: String { return L10n.tr("Localizable", "screen_edit_profile_display_name") }
  /// Your display name
  internal static var screenEditProfileDisplayNamePlaceholder: String { return L10n.tr("Localizable", "screen_edit_profile_display_name_placeholder") }
  /// An unknown error was encountered and the information couldn't be changed.
  internal static var screenEditProfileError: String { return L10n.tr("Localizable", "screen_edit_profile_error") }
  /// Unable to update profile
  internal static var screenEditProfileErrorTitle: String { return L10n.tr("Localizable", "screen_edit_profile_error_title") }
  /// Edit profile
  internal static var screenEditProfileTitle: String { return L10n.tr("Localizable", "screen_edit_profile_title") }
  /// Updating profile…
  internal static var screenEditProfileUpdatingDetails: String { return L10n.tr("Localizable", "screen_edit_profile_updating_details") }
  /// Continue reset
  internal static var screenEncryptionResetActionContinueReset: String { return L10n.tr("Localizable", "screen_encryption_reset_action_continue_reset") }
  /// Your account details, contacts, preferences, and chat list will be kept
  internal static var screenEncryptionResetBullet1: String { return L10n.tr("Localizable", "screen_encryption_reset_bullet_1") }
  /// You will lose any message history that’s stored only on the server
  internal static var screenEncryptionResetBullet2: String { return L10n.tr("Localizable", "screen_encryption_reset_bullet_2") }
  /// You will need to verify all your existing devices and contacts again
  internal static var screenEncryptionResetBullet3: String { return L10n.tr("Localizable", "screen_encryption_reset_bullet_3") }
  /// Only reset your identity if you don’t have access to another signed-in device and you’ve lost your recovery key.
  internal static var screenEncryptionResetFooter: String { return L10n.tr("Localizable", "screen_encryption_reset_footer") }
  /// Can't confirm? You’ll need to reset your identity.
  internal static var screenEncryptionResetTitle: String { return L10n.tr("Localizable", "screen_encryption_reset_title") }
  /// Can't confirm?
  internal static var screenIdentityConfirmationCannotConfirm: String { return L10n.tr("Localizable", "screen_identity_confirmation_cannot_confirm") }
  /// Create a new recovery key
  internal static var screenIdentityConfirmationCreateNewRecoveryKey: String { return L10n.tr("Localizable", "screen_identity_confirmation_create_new_recovery_key") }
  /// Verify this device to set up secure messaging.
  internal static var screenIdentityConfirmationSubtitle: String { return L10n.tr("Localizable", "screen_identity_confirmation_subtitle") }
  /// Confirm your identity
  internal static var screenIdentityConfirmationTitle: String { return L10n.tr("Localizable", "screen_identity_confirmation_title") }
  /// Use another device
  internal static var screenIdentityConfirmationUseAnotherDevice: String { return L10n.tr("Localizable", "screen_identity_confirmation_use_another_device") }
  /// Use recovery key
  internal static var screenIdentityConfirmationUseRecoveryKey: String { return L10n.tr("Localizable", "screen_identity_confirmation_use_recovery_key") }
  /// Now you can read or send messages securely, and anyone you chat with can also trust this device.
  internal static var screenIdentityConfirmedSubtitle: String { return L10n.tr("Localizable", "screen_identity_confirmed_subtitle") }
  /// Device verified
  internal static var screenIdentityConfirmedTitle: String { return L10n.tr("Localizable", "screen_identity_confirmed_title") }
  /// Use another device
  internal static var screenIdentityUseAnotherDevice: String { return L10n.tr("Localizable", "screen_identity_use_another_device") }
  /// Waiting on other device…
  internal static var screenIdentityWaitingOnOtherDevice: String { return L10n.tr("Localizable", "screen_identity_waiting_on_other_device") }
  /// Are you sure you want to decline the invitation to join %1$@?
  internal static func screenInvitesDeclineChatMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_invites_decline_chat_message", String(describing: p1))
  }
  /// Decline invite
  internal static var screenInvitesDeclineChatTitle: String { return L10n.tr("Localizable", "screen_invites_decline_chat_title") }
  /// Are you sure you want to decline this private chat with %1$@?
  internal static func screenInvitesDeclineDirectChatMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_invites_decline_direct_chat_message", String(describing: p1))
  }
  /// Decline chat
  internal static var screenInvitesDeclineDirectChatTitle: String { return L10n.tr("Localizable", "screen_invites_decline_direct_chat_title") }
  /// No Invites
  internal static var screenInvitesEmptyList: String { return L10n.tr("Localizable", "screen_invites_empty_list") }
  /// %1$@ (%2$@) invited you
  internal static func screenInvitesInvitedYou(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_invites_invited_you", String(describing: p1), String(describing: p2))
  }
  /// Join room
  internal static var screenJoinRoomJoinAction: String { return L10n.tr("Localizable", "screen_join_room_join_action") }
  /// Knock to join
  internal static var screenJoinRoomKnockAction: String { return L10n.tr("Localizable", "screen_join_room_knock_action") }
  /// %1$@ does not support spaces yet. You can access spaces on web.
  internal static func screenJoinRoomSpaceNotSupportedDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_join_room_space_not_supported_description", String(describing: p1))
  }
  /// Spaces are not supported yet
  internal static var screenJoinRoomSpaceNotSupportedTitle: String { return L10n.tr("Localizable", "screen_join_room_space_not_supported_title") }
  /// Click the button below and a room administrator will be notified. You’ll be able to join the conversation once approved.
  internal static var screenJoinRoomSubtitleKnock: String { return L10n.tr("Localizable", "screen_join_room_subtitle_knock") }
  /// You must be a member of this room to view the message history.
  internal static var screenJoinRoomSubtitleNoPreview: String { return L10n.tr("Localizable", "screen_join_room_subtitle_no_preview") }
  /// Want to join this room?
  internal static var screenJoinRoomTitleKnock: String { return L10n.tr("Localizable", "screen_join_room_title_knock") }
  /// Preview is not available
  internal static var screenJoinRoomTitleNoPreview: String { return L10n.tr("Localizable", "screen_join_room_title_no_preview") }
  /// Turn off
  internal static var screenKeyBackupDisableConfirmationActionTurnOff: String { return L10n.tr("Localizable", "screen_key_backup_disable_confirmation_action_turn_off") }
  /// You will lose your encrypted messages if you are signed out of all devices.
  internal static var screenKeyBackupDisableConfirmationDescription: String { return L10n.tr("Localizable", "screen_key_backup_disable_confirmation_description") }
  /// Are you sure you want to turn off backup?
  internal static var screenKeyBackupDisableConfirmationTitle: String { return L10n.tr("Localizable", "screen_key_backup_disable_confirmation_title") }
  /// Turning off backup will remove your current encryption key backup and turn off other security features. In this case, you will:
  internal static var screenKeyBackupDisableDescription: String { return L10n.tr("Localizable", "screen_key_backup_disable_description") }
  /// Not have encrypted message history on new devices
  internal static var screenKeyBackupDisableDescriptionPoint1: String { return L10n.tr("Localizable", "screen_key_backup_disable_description_point_1") }
  /// Lose access to your encrypted messages if you are signed out of %1$@ everywhere
  internal static func screenKeyBackupDisableDescriptionPoint2(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_key_backup_disable_description_point_2", String(describing: p1))
  }
  /// Are you sure you want to turn off backup?
  internal static var screenKeyBackupDisableTitle: String { return L10n.tr("Localizable", "screen_key_backup_disable_title") }
  /// This account has been deactivated.
  internal static var screenLoginErrorDeactivatedAccount: String { return L10n.tr("Localizable", "screen_login_error_deactivated_account") }
  /// Incorrect username and/or password
  internal static var screenLoginErrorInvalidCredentials: String { return L10n.tr("Localizable", "screen_login_error_invalid_credentials") }
  /// This is not a valid user identifier. Expected format: ‘@user:homeserver.org’
  internal static var screenLoginErrorInvalidUserId: String { return L10n.tr("Localizable", "screen_login_error_invalid_user_id") }
  /// This server is configured to use refresh tokens. These aren't supported when using password based login.
  internal static var screenLoginErrorRefreshTokens: String { return L10n.tr("Localizable", "screen_login_error_refresh_tokens") }
  /// The selected homeserver doesn't support password or OIDC login. Please contact your admin or choose another homeserver.
  internal static var screenLoginErrorUnsupportedAuthentication: String { return L10n.tr("Localizable", "screen_login_error_unsupported_authentication") }
  /// Enter your details
  internal static var screenLoginFormHeader: String { return L10n.tr("Localizable", "screen_login_form_header") }
  /// Matrix is an open network for secure, decentralised communication.
  internal static var screenLoginSubtitle: String { return L10n.tr("Localizable", "screen_login_subtitle") }
  /// Welcome back!
  internal static var screenLoginTitle: String { return L10n.tr("Localizable", "screen_login_title") }
  /// Sign in to %1$@
  internal static func screenLoginTitleWithHomeserver(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_login_title_with_homeserver", String(describing: p1))
  }
  /// Failed selecting media, please try again.
  internal static var screenMediaPickerErrorFailedSelection: String { return L10n.tr("Localizable", "screen_media_picker_error_failed_selection") }
  /// Failed processing media to upload, please try again.
  internal static var screenMediaUploadPreviewErrorFailedProcessing: String { return L10n.tr("Localizable", "screen_media_upload_preview_error_failed_processing") }
  /// Failed uploading media, please try again.
  internal static var screenMediaUploadPreviewErrorFailedSending: String { return L10n.tr("Localizable", "screen_media_upload_preview_error_failed_sending") }
  /// This is a one time process, thanks for waiting.
  internal static var screenMigrationMessage: String { return L10n.tr("Localizable", "screen_migration_message") }
  /// Setting up your account.
  internal static var screenMigrationTitle: String { return L10n.tr("Localizable", "screen_migration_title") }
  /// You can change your settings later.
  internal static var screenNotificationOptinSubtitle: String { return L10n.tr("Localizable", "screen_notification_optin_subtitle") }
  /// Allow notifications and never miss a message
  internal static var screenNotificationOptinTitle: String { return L10n.tr("Localizable", "screen_notification_optin_title") }
  /// Additional settings
  internal static var screenNotificationSettingsAdditionalSettingsSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_additional_settings_section_title") }
  /// Audio and video calls
  internal static var screenNotificationSettingsCallsLabel: String { return L10n.tr("Localizable", "screen_notification_settings_calls_label") }
  /// Configuration mismatch
  internal static var screenNotificationSettingsConfigurationMismatch: String { return L10n.tr("Localizable", "screen_notification_settings_configuration_mismatch") }
  /// We’ve simplified Notifications Settings to make options easier to find. Some custom settings you’ve chosen in the past are not shown here, but they’re still active.
  /// 
  /// If you proceed, some of your settings may change.
  internal static var screenNotificationSettingsConfigurationMismatchDescription: String { return L10n.tr("Localizable", "screen_notification_settings_configuration_mismatch_description") }
  /// Direct chats
  internal static var screenNotificationSettingsDirectChats: String { return L10n.tr("Localizable", "screen_notification_settings_direct_chats") }
  /// Custom setting per chat
  internal static var screenNotificationSettingsEditCustomSettingsSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_edit_custom_settings_section_title") }
  /// An error occurred while updating the notification setting.
  internal static var screenNotificationSettingsEditFailedUpdatingDefaultMode: String { return L10n.tr("Localizable", "screen_notification_settings_edit_failed_updating_default_mode") }
  /// All messages
  internal static var screenNotificationSettingsEditModeAllMessages: String { return L10n.tr("Localizable", "screen_notification_settings_edit_mode_all_messages") }
  /// Mentions and Keywords only
  internal static var screenNotificationSettingsEditModeMentionsAndKeywords: String { return L10n.tr("Localizable", "screen_notification_settings_edit_mode_mentions_and_keywords") }
  /// On direct chats, notify me for
  internal static var screenNotificationSettingsEditScreenDirectSectionHeader: String { return L10n.tr("Localizable", "screen_notification_settings_edit_screen_direct_section_header") }
  /// On group chats, notify me for
  internal static var screenNotificationSettingsEditScreenGroupSectionHeader: String { return L10n.tr("Localizable", "screen_notification_settings_edit_screen_group_section_header") }
  /// Enable notifications on this device
  internal static var screenNotificationSettingsEnableNotifications: String { return L10n.tr("Localizable", "screen_notification_settings_enable_notifications") }
  /// The configuration has not been corrected, please try again.
  internal static var screenNotificationSettingsFailedFixingConfiguration: String { return L10n.tr("Localizable", "screen_notification_settings_failed_fixing_configuration") }
  /// Group chats
  internal static var screenNotificationSettingsGroupChats: String { return L10n.tr("Localizable", "screen_notification_settings_group_chats") }
  /// Invitations
  internal static var screenNotificationSettingsInviteForMeLabel: String { return L10n.tr("Localizable", "screen_notification_settings_invite_for_me_label") }
  /// Your homeserver does not support this option in encrypted rooms, you may not get notified in some rooms.
  internal static var screenNotificationSettingsMentionsOnlyDisclaimer: String { return L10n.tr("Localizable", "screen_notification_settings_mentions_only_disclaimer") }
  /// Mentions
  internal static var screenNotificationSettingsMentionsSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_mentions_section_title") }
  /// All
  internal static var screenNotificationSettingsModeAll: String { return L10n.tr("Localizable", "screen_notification_settings_mode_all") }
  /// Mentions
  internal static var screenNotificationSettingsModeMentions: String { return L10n.tr("Localizable", "screen_notification_settings_mode_mentions") }
  /// Notify me for
  internal static var screenNotificationSettingsNotificationSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_notification_section_title") }
  /// Notify me on @room
  internal static var screenNotificationSettingsRoomMentionLabel: String { return L10n.tr("Localizable", "screen_notification_settings_room_mention_label") }
  /// To receive notifications, please change your %1$@.
  internal static func screenNotificationSettingsSystemNotificationsActionRequired(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_notification_settings_system_notifications_action_required", String(describing: p1))
  }
  /// system settings
  internal static var screenNotificationSettingsSystemNotificationsActionRequiredContentLink: String { return L10n.tr("Localizable", "screen_notification_settings_system_notifications_action_required_content_link") }
  /// System notifications turned off
  internal static var screenNotificationSettingsSystemNotificationsTurnedOff: String { return L10n.tr("Localizable", "screen_notification_settings_system_notifications_turned_off") }
  /// Notifications
  internal static var screenNotificationSettingsTitle: String { return L10n.tr("Localizable", "screen_notification_settings_title") }
  /// Sign in manually
  internal static var screenOnboardingSignInManually: String { return L10n.tr("Localizable", "screen_onboarding_sign_in_manually") }
  /// Sign in with QR code
  internal static var screenOnboardingSignInWithQrCode: String { return L10n.tr("Localizable", "screen_onboarding_sign_in_with_qr_code") }
  /// Create account
  internal static var screenOnboardingSignUp: String { return L10n.tr("Localizable", "screen_onboarding_sign_up") }
  /// Welcome to the fastest %1$@ ever. Supercharged for speed and simplicity.
  internal static func screenOnboardingWelcomeMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_onboarding_welcome_message", String(describing: p1))
  }
  /// Welcome to %1$@. Supercharged, for speed and simplicity.
  internal static func screenOnboardingWelcomeSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_onboarding_welcome_subtitle", String(describing: p1))
  }
  /// Be in your element
  internal static var screenOnboardingWelcomeTitle: String { return L10n.tr("Localizable", "screen_onboarding_welcome_title") }
  /// Press on a message and choose “%1$@” to include here.
  internal static func screenPinnedTimelineEmptyStateDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_pinned_timeline_empty_state_description", String(describing: p1))
  }
  /// Pin important messages so that they can be easily discovered
  internal static var screenPinnedTimelineEmptyStateHeadline: String { return L10n.tr("Localizable", "screen_pinned_timeline_empty_state_headline") }
  /// Plural format key: "%#@COUNT@"
  internal static func screenPinnedTimelineScreenTitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_pinned_timeline_screen_title", p1)
  }
  /// Pinned messages
  internal static var screenPinnedTimelineScreenTitleEmpty: String { return L10n.tr("Localizable", "screen_pinned_timeline_screen_title_empty") }
  /// Can't find any ongoing polls.
  internal static var screenPollsHistoryEmptyOngoing: String { return L10n.tr("Localizable", "screen_polls_history_empty_ongoing") }
  /// Can't find any past polls.
  internal static var screenPollsHistoryEmptyPast: String { return L10n.tr("Localizable", "screen_polls_history_empty_past") }
  /// Ongoing
  internal static var screenPollsHistoryFilterOngoing: String { return L10n.tr("Localizable", "screen_polls_history_filter_ongoing") }
  /// Past
  internal static var screenPollsHistoryFilterPast: String { return L10n.tr("Localizable", "screen_polls_history_filter_past") }
  /// Polls
  internal static var screenPollsHistoryTitle: String { return L10n.tr("Localizable", "screen_polls_history_title") }
  /// Establishing a secure connection
  internal static var screenQrCodeLoginConnectingSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_connecting_subtitle") }
  /// A secure connection could not be made to the new device. Your existing devices are still safe and you don't need to worry about them.
  internal static var screenQrCodeLoginConnectionNoteSecureStateDescription: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_description") }
  /// What now?
  internal static var screenQrCodeLoginConnectionNoteSecureStateListHeader: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_list_header") }
  /// Try signing in again with a QR code in case this was a network problem
  internal static var screenQrCodeLoginConnectionNoteSecureStateListItem1: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_list_item_1") }
  /// If you encounter the same problem, try a different wifi network or use your mobile data instead of wifi
  internal static var screenQrCodeLoginConnectionNoteSecureStateListItem2: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_list_item_2") }
  /// If that doesn’t work, sign in manually
  internal static var screenQrCodeLoginConnectionNoteSecureStateListItem3: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_list_item_3") }
  /// Connection not secure
  internal static var screenQrCodeLoginConnectionNoteSecureStateTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_title") }
  /// You’ll be asked to enter the two digits shown on this device.
  internal static var screenQrCodeLoginDeviceCodeSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_device_code_subtitle") }
  /// Enter the number below on your other device
  internal static var screenQrCodeLoginDeviceCodeTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_device_code_title") }
  /// Sign in to your other device and then try again, or use another device that’s already signed in.
  internal static var screenQrCodeLoginDeviceNotSignedInScanStateDescription: String { return L10n.tr("Localizable", "screen_qr_code_login_device_not_signed_in_scan_state_description") }
  /// Other device not signed in
  internal static var screenQrCodeLoginDeviceNotSignedInScanStateSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_device_not_signed_in_scan_state_subtitle") }
  /// The sign in was cancelled on the other device.
  internal static var screenQrCodeLoginErrorCancelledSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_cancelled_subtitle") }
  /// Sign in request cancelled
  internal static var screenQrCodeLoginErrorCancelledTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_cancelled_title") }
  /// The sign in was declined on the other device.
  internal static var screenQrCodeLoginErrorDeclinedSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_declined_subtitle") }
  /// Sign in declined
  internal static var screenQrCodeLoginErrorDeclinedTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_declined_title") }
  /// Sign in expired. Please try again.
  internal static var screenQrCodeLoginErrorExpiredSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_expired_subtitle") }
  /// The sign in was not completed in time
  internal static var screenQrCodeLoginErrorExpiredTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_expired_title") }
  /// Your other device does not support signing in to %@ with a QR code.
  /// 
  /// Try signing in manually, or scan the QR code with another device.
  internal static func screenQrCodeLoginErrorLinkingNotSuportedSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_error_linking_not_suported_subtitle", String(describing: p1))
  }
  /// QR code not supported
  internal static var screenQrCodeLoginErrorLinkingNotSuportedTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_linking_not_suported_title") }
  /// Your account provider does not support %1$@.
  internal static func screenQrCodeLoginErrorSlidingSyncNotSupportedSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_error_sliding_sync_not_supported_subtitle", String(describing: p1))
  }
  /// %1$@ not supported
  internal static func screenQrCodeLoginErrorSlidingSyncNotSupportedTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_error_sliding_sync_not_supported_title", String(describing: p1))
  }
  /// Ready to scan
  internal static var screenQrCodeLoginInitialStateButtonTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_initial_state_button_title") }
  /// Open %1$@ on a desktop device
  internal static func screenQrCodeLoginInitialStateItem1(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_initial_state_item_1", String(describing: p1))
  }
  /// Click on your avatar
  internal static var screenQrCodeLoginInitialStateItem2: String { return L10n.tr("Localizable", "screen_qr_code_login_initial_state_item_2") }
  /// Select %1$@
  internal static func screenQrCodeLoginInitialStateItem3(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_initial_state_item_3", String(describing: p1))
  }
  /// “Link new device”
  internal static var screenQrCodeLoginInitialStateItem3Action: String { return L10n.tr("Localizable", "screen_qr_code_login_initial_state_item_3_action") }
  /// Scan the QR code with this device
  internal static var screenQrCodeLoginInitialStateItem4: String { return L10n.tr("Localizable", "screen_qr_code_login_initial_state_item_4") }
  /// Only available if your account provider supports it.
  internal static var screenQrCodeLoginInitialStateSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_initial_state_subtitle") }
  /// Open %1$@ on another device to get the QR code
  internal static func screenQrCodeLoginInitialStateTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_initial_state_title", String(describing: p1))
  }
  /// Use the QR code shown on the other device.
  internal static var screenQrCodeLoginInvalidScanStateDescription: String { return L10n.tr("Localizable", "screen_qr_code_login_invalid_scan_state_description") }
  /// Try again
  internal static var screenQrCodeLoginInvalidScanStateRetryButton: String { return L10n.tr("Localizable", "screen_qr_code_login_invalid_scan_state_retry_button") }
  /// Wrong QR code
  internal static var screenQrCodeLoginInvalidScanStateSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_invalid_scan_state_subtitle") }
  /// Go to camera settings
  internal static var screenQrCodeLoginNoCameraPermissionButton: String { return L10n.tr("Localizable", "screen_qr_code_login_no_camera_permission_button") }
  /// You need to give permission for %1$@ to use your device’s camera in order to continue.
  internal static func screenQrCodeLoginNoCameraPermissionStateDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_no_camera_permission_state_description", String(describing: p1))
  }
  /// Allow camera access to scan the QR code
  internal static var screenQrCodeLoginNoCameraPermissionStateTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_no_camera_permission_state_title") }
  /// Scan the QR code
  internal static var screenQrCodeLoginScanningStateTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_scanning_state_title") }
  /// Start over
  internal static var screenQrCodeLoginStartOverButton: String { return L10n.tr("Localizable", "screen_qr_code_login_start_over_button") }
  /// An unexpected error occurred. Please try again.
  internal static var screenQrCodeLoginUnknownErrorDescription: String { return L10n.tr("Localizable", "screen_qr_code_login_unknown_error_description") }
  /// Waiting for your other device
  internal static var screenQrCodeLoginVerifyCodeLoading: String { return L10n.tr("Localizable", "screen_qr_code_login_verify_code_loading") }
  /// Your account provider may ask for the following code to verify the sign in.
  internal static var screenQrCodeLoginVerifyCodeSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_verify_code_subtitle") }
  /// Your verification code
  internal static var screenQrCodeLoginVerifyCodeTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_verify_code_title") }
  /// Get a new recovery key if you've lost your existing one. After changing your recovery key, your old one will no longer work.
  internal static var screenRecoveryKeyChangeDescription: String { return L10n.tr("Localizable", "screen_recovery_key_change_description") }
  /// Generate a new recovery key
  internal static var screenRecoveryKeyChangeGenerateKey: String { return L10n.tr("Localizable", "screen_recovery_key_change_generate_key") }
  /// Make sure you can store your recovery key somewhere safe
  internal static var screenRecoveryKeyChangeGenerateKeyDescription: String { return L10n.tr("Localizable", "screen_recovery_key_change_generate_key_description") }
  /// Recovery key changed
  internal static var screenRecoveryKeyChangeSuccess: String { return L10n.tr("Localizable", "screen_recovery_key_change_success") }
  /// Change recovery key?
  internal static var screenRecoveryKeyChangeTitle: String { return L10n.tr("Localizable", "screen_recovery_key_change_title") }
  /// Create new recovery key
  internal static var screenRecoveryKeyConfirmCreateNewRecoveryKey: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_create_new_recovery_key") }
  /// Make sure nobody can see this screen!
  internal static var screenRecoveryKeyConfirmDescription: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_description") }
  /// Please try again to confirm access to your chat backup.
  internal static var screenRecoveryKeyConfirmErrorContent: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_error_content") }
  /// Incorrect recovery key
  internal static var screenRecoveryKeyConfirmErrorTitle: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_error_title") }
  /// If you have a security key or security phrase, this will work too.
  internal static var screenRecoveryKeyConfirmKeyDescription: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_key_description") }
  /// Enter…
  internal static var screenRecoveryKeyConfirmKeyPlaceholder: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_key_placeholder") }
  /// Lost your recovery key?
  internal static var screenRecoveryKeyConfirmLostRecoveryKey: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_lost_recovery_key") }
  /// Recovery key confirmed
  internal static var screenRecoveryKeyConfirmSuccess: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_success") }
  /// Enter your recovery key
  internal static var screenRecoveryKeyConfirmTitle: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_title") }
  /// Copied recovery key
  internal static var screenRecoveryKeyCopiedToClipboard: String { return L10n.tr("Localizable", "screen_recovery_key_copied_to_clipboard") }
  /// Generating…
  internal static var screenRecoveryKeyGeneratingKey: String { return L10n.tr("Localizable", "screen_recovery_key_generating_key") }
  /// Save recovery key
  internal static var screenRecoveryKeySaveAction: String { return L10n.tr("Localizable", "screen_recovery_key_save_action") }
  /// Write down your recovery key somewhere safe or save it in a password manager.
  internal static var screenRecoveryKeySaveDescription: String { return L10n.tr("Localizable", "screen_recovery_key_save_description") }
  /// Tap to copy recovery key
  internal static var screenRecoveryKeySaveKeyDescription: String { return L10n.tr("Localizable", "screen_recovery_key_save_key_description") }
  /// Save your recovery key
  internal static var screenRecoveryKeySaveTitle: String { return L10n.tr("Localizable", "screen_recovery_key_save_title") }
  /// You will not be able to access your new recovery key after this step.
  internal static var screenRecoveryKeySetupConfirmationDescription: String { return L10n.tr("Localizable", "screen_recovery_key_setup_confirmation_description") }
  /// Have you saved your recovery key?
  internal static var screenRecoveryKeySetupConfirmationTitle: String { return L10n.tr("Localizable", "screen_recovery_key_setup_confirmation_title") }
  /// Your chat backup is protected by a recovery key. If you need a new recovery key after setup you can recreate by selecting ‘Change recovery key’.
  internal static var screenRecoveryKeySetupDescription: String { return L10n.tr("Localizable", "screen_recovery_key_setup_description") }
  /// Generate your recovery key
  internal static var screenRecoveryKeySetupGenerateKey: String { return L10n.tr("Localizable", "screen_recovery_key_setup_generate_key") }
  /// Make sure you can store your recovery key somewhere safe
  internal static var screenRecoveryKeySetupGenerateKeyDescription: String { return L10n.tr("Localizable", "screen_recovery_key_setup_generate_key_description") }
  /// Recovery setup successful
  internal static var screenRecoveryKeySetupSuccess: String { return L10n.tr("Localizable", "screen_recovery_key_setup_success") }
  /// Set up recovery
  internal static var screenRecoveryKeySetupTitle: String { return L10n.tr("Localizable", "screen_recovery_key_setup_title") }
  /// Block user
  internal static var screenReportContentBlockUser: String { return L10n.tr("Localizable", "screen_report_content_block_user") }
  /// Check if you want to hide all current and future messages from this user
  internal static var screenReportContentBlockUserHint: String { return L10n.tr("Localizable", "screen_report_content_block_user_hint") }
  /// This message will be reported to your homeserver’s administrator. They will not be able to read any encrypted messages.
  internal static var screenReportContentExplanation: String { return L10n.tr("Localizable", "screen_report_content_explanation") }
  /// Reason for reporting this content
  internal static var screenReportContentHint: String { return L10n.tr("Localizable", "screen_report_content_hint") }
  /// Yes, reset now
  internal static var screenResetEncryptionConfirmationAlertAction: String { return L10n.tr("Localizable", "screen_reset_encryption_confirmation_alert_action") }
  /// This process is irreversible.
  internal static var screenResetEncryptionConfirmationAlertSubtitle: String { return L10n.tr("Localizable", "screen_reset_encryption_confirmation_alert_subtitle") }
  /// Are you sure you want to reset your identity?
  internal static var screenResetEncryptionConfirmationAlertTitle: String { return L10n.tr("Localizable", "screen_reset_encryption_confirmation_alert_title") }
  /// An unknown error happened. Please check your account password is correct and try again.
  internal static var screenResetEncryptionPasswordError: String { return L10n.tr("Localizable", "screen_reset_encryption_password_error") }
  /// Enter…
  internal static var screenResetEncryptionPasswordPlaceholder: String { return L10n.tr("Localizable", "screen_reset_encryption_password_placeholder") }
  /// Confirm that you want to reset your identity.
  internal static var screenResetEncryptionPasswordSubtitle: String { return L10n.tr("Localizable", "screen_reset_encryption_password_subtitle") }
  /// Enter your account password to continue
  internal static var screenResetEncryptionPasswordTitle: String { return L10n.tr("Localizable", "screen_reset_encryption_password_title") }
  /// You're about to go to your %1$@ account to reset your identity. Afterwards you'll be taken back to the app.
  internal static func screenResetIdentityConfirmationSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_reset_identity_confirmation_subtitle", String(describing: p1))
  }
  /// Can't confirm? Go to your account to reset your identity.
  internal static var screenResetIdentityConfirmationTitle: String { return L10n.tr("Localizable", "screen_reset_identity_confirmation_title") }
  /// Withdraw verification and send
  internal static var screenResolveSendFailureChangedIdentityPrimaryButtonTitle: String { return L10n.tr("Localizable", "screen_resolve_send_failure_changed_identity_primary_button_title") }
  /// You can withdraw your verification and send this message anyway, or you can cancel for now and try again later after reverifying %1$@.
  internal static func screenResolveSendFailureChangedIdentitySubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_resolve_send_failure_changed_identity_subtitle", String(describing: p1))
  }
  /// Your message was not sent because %1$@’s verified identity has changed
  internal static func screenResolveSendFailureChangedIdentityTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_resolve_send_failure_changed_identity_title", String(describing: p1))
  }
  /// Send message anyway
  internal static var screenResolveSendFailureUnsignedDevicePrimaryButtonTitle: String { return L10n.tr("Localizable", "screen_resolve_send_failure_unsigned_device_primary_button_title") }
  /// %1$@ is using one or more unverified devices. You can send the message anyway, or you can cancel for now and try again later after %2$@ has verified all their devices.
  internal static func screenResolveSendFailureUnsignedDeviceSubtitle(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_resolve_send_failure_unsigned_device_subtitle", String(describing: p1), String(describing: p2))
  }
  /// Your message was not sent because %1$@ has not verified all devices
  internal static func screenResolveSendFailureUnsignedDeviceTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_resolve_send_failure_unsigned_device_title", String(describing: p1))
  }
  /// One or more of your devices are unverified. You can send the message anyway, or you can cancel for now and try again later after you have verified all of your devices.
  internal static var screenResolveSendFailureYouUnsignedDeviceSubtitle: String { return L10n.tr("Localizable", "screen_resolve_send_failure_you_unsigned_device_subtitle") }
  /// Your message was not sent because you have not verified one or more of your devices
  internal static var screenResolveSendFailureYouUnsignedDeviceTitle: String { return L10n.tr("Localizable", "screen_resolve_send_failure_you_unsigned_device_title") }
  /// Failed to resolve room alias.
  internal static var screenRoomAliasResolverResolveAliasFailure: String { return L10n.tr("Localizable", "screen_room_alias_resolver_resolve_alias_failure") }
  /// Camera
  internal static var screenRoomAttachmentSourceCamera: String { return L10n.tr("Localizable", "screen_room_attachment_source_camera") }
  /// Take photo
  internal static var screenRoomAttachmentSourceCameraPhoto: String { return L10n.tr("Localizable", "screen_room_attachment_source_camera_photo") }
  /// Record video
  internal static var screenRoomAttachmentSourceCameraVideo: String { return L10n.tr("Localizable", "screen_room_attachment_source_camera_video") }
  /// Attachment
  internal static var screenRoomAttachmentSourceFiles: String { return L10n.tr("Localizable", "screen_room_attachment_source_files") }
  /// Photo & Video Library
  internal static var screenRoomAttachmentSourceGallery: String { return L10n.tr("Localizable", "screen_room_attachment_source_gallery") }
  /// Location
  internal static var screenRoomAttachmentSourceLocation: String { return L10n.tr("Localizable", "screen_room_attachment_source_location") }
  /// Poll
  internal static var screenRoomAttachmentSourcePoll: String { return L10n.tr("Localizable", "screen_room_attachment_source_poll") }
  /// Text Formatting
  internal static var screenRoomAttachmentTextFormatting: String { return L10n.tr("Localizable", "screen_room_attachment_text_formatting") }
  /// Admins only
  internal static var screenRoomChangePermissionsAdministrators: String { return L10n.tr("Localizable", "screen_room_change_permissions_administrators") }
  /// Ban people
  internal static var screenRoomChangePermissionsBanPeople: String { return L10n.tr("Localizable", "screen_room_change_permissions_ban_people") }
  /// Remove messages
  internal static var screenRoomChangePermissionsDeleteMessages: String { return L10n.tr("Localizable", "screen_room_change_permissions_delete_messages") }
  /// Everyone
  internal static var screenRoomChangePermissionsEveryone: String { return L10n.tr("Localizable", "screen_room_change_permissions_everyone") }
  /// Invite people
  internal static var screenRoomChangePermissionsInvitePeople: String { return L10n.tr("Localizable", "screen_room_change_permissions_invite_people") }
  /// Member moderation
  internal static var screenRoomChangePermissionsMemberModeration: String { return L10n.tr("Localizable", "screen_room_change_permissions_member_moderation") }
  /// Messages and content
  internal static var screenRoomChangePermissionsMessagesAndContent: String { return L10n.tr("Localizable", "screen_room_change_permissions_messages_and_content") }
  /// Admins and moderators
  internal static var screenRoomChangePermissionsModerators: String { return L10n.tr("Localizable", "screen_room_change_permissions_moderators") }
  /// Remove people
  internal static var screenRoomChangePermissionsRemovePeople: String { return L10n.tr("Localizable", "screen_room_change_permissions_remove_people") }
  /// Change room avatar
  internal static var screenRoomChangePermissionsRoomAvatar: String { return L10n.tr("Localizable", "screen_room_change_permissions_room_avatar") }
  /// Room details
  internal static var screenRoomChangePermissionsRoomDetails: String { return L10n.tr("Localizable", "screen_room_change_permissions_room_details") }
  /// Change room name
  internal static var screenRoomChangePermissionsRoomName: String { return L10n.tr("Localizable", "screen_room_change_permissions_room_name") }
  /// Change room topic
  internal static var screenRoomChangePermissionsRoomTopic: String { return L10n.tr("Localizable", "screen_room_change_permissions_room_topic") }
  /// Send messages
  internal static var screenRoomChangePermissionsSendMessages: String { return L10n.tr("Localizable", "screen_room_change_permissions_send_messages") }
  /// Edit Admins
  internal static var screenRoomChangeRoleAdministratorsTitle: String { return L10n.tr("Localizable", "screen_room_change_role_administrators_title") }
  /// You will not be able to undo this action. You are promoting the user to have the same power level as you.
  internal static var screenRoomChangeRoleConfirmAddAdminDescription: String { return L10n.tr("Localizable", "screen_room_change_role_confirm_add_admin_description") }
  /// Add Admin?
  internal static var screenRoomChangeRoleConfirmAddAdminTitle: String { return L10n.tr("Localizable", "screen_room_change_role_confirm_add_admin_title") }
  /// Demote
  internal static var screenRoomChangeRoleConfirmDemoteSelfAction: String { return L10n.tr("Localizable", "screen_room_change_role_confirm_demote_self_action") }
  /// You will not be able to undo this change as you are demoting yourself, if you are the last privileged user in the room it will be impossible to regain privileges.
  internal static var screenRoomChangeRoleConfirmDemoteSelfDescription: String { return L10n.tr("Localizable", "screen_room_change_role_confirm_demote_self_description") }
  /// Demote yourself?
  internal static var screenRoomChangeRoleConfirmDemoteSelfTitle: String { return L10n.tr("Localizable", "screen_room_change_role_confirm_demote_self_title") }
  /// %1$@ (Pending)
  internal static func screenRoomChangeRoleInvitedMemberName(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_change_role_invited_member_name", String(describing: p1))
  }
  /// Admins automatically have moderator privileges
  internal static var screenRoomChangeRoleModeratorsAdminSectionFooter: String { return L10n.tr("Localizable", "screen_room_change_role_moderators_admin_section_footer") }
  /// Edit Moderators
  internal static var screenRoomChangeRoleModeratorsTitle: String { return L10n.tr("Localizable", "screen_room_change_role_moderators_title") }
  /// Admins
  internal static var screenRoomChangeRoleSectionAdministrators: String { return L10n.tr("Localizable", "screen_room_change_role_section_administrators") }
  /// Moderators
  internal static var screenRoomChangeRoleSectionModerators: String { return L10n.tr("Localizable", "screen_room_change_role_section_moderators") }
  /// Members
  internal static var screenRoomChangeRoleSectionUsers: String { return L10n.tr("Localizable", "screen_room_change_role_section_users") }
  /// You have unsaved changes.
  internal static var screenRoomChangeRoleUnsavedChangesDescription: String { return L10n.tr("Localizable", "screen_room_change_role_unsaved_changes_description") }
  /// Save changes?
  internal static var screenRoomChangeRoleUnsavedChangesTitle: String { return L10n.tr("Localizable", "screen_room_change_role_unsaved_changes_title") }
  /// Add topic
  internal static var screenRoomDetailsAddTopicTitle: String { return L10n.tr("Localizable", "screen_room_details_add_topic_title") }
  /// Already a member
  internal static var screenRoomDetailsAlreadyAMember: String { return L10n.tr("Localizable", "screen_room_details_already_a_member") }
  /// Already invited
  internal static var screenRoomDetailsAlreadyInvited: String { return L10n.tr("Localizable", "screen_room_details_already_invited") }
  /// Encrypted
  internal static var screenRoomDetailsBadgeEncrypted: String { return L10n.tr("Localizable", "screen_room_details_badge_encrypted") }
  /// Not encrypted
  internal static var screenRoomDetailsBadgeNotEncrypted: String { return L10n.tr("Localizable", "screen_room_details_badge_not_encrypted") }
  /// Public room
  internal static var screenRoomDetailsBadgePublic: String { return L10n.tr("Localizable", "screen_room_details_badge_public") }
  /// Edit Room
  internal static var screenRoomDetailsEditRoomTitle: String { return L10n.tr("Localizable", "screen_room_details_edit_room_title") }
  /// There was an unknown error and the information couldn't be changed.
  internal static var screenRoomDetailsEditionError: String { return L10n.tr("Localizable", "screen_room_details_edition_error") }
  /// Unable to update room
  internal static var screenRoomDetailsEditionErrorTitle: String { return L10n.tr("Localizable", "screen_room_details_edition_error_title") }
  /// Messages are secured with locks. Only you and the recipients have the unique keys to unlock them.
  internal static var screenRoomDetailsEncryptionEnabledSubtitle: String { return L10n.tr("Localizable", "screen_room_details_encryption_enabled_subtitle") }
  /// Message encryption enabled
  internal static var screenRoomDetailsEncryptionEnabledTitle: String { return L10n.tr("Localizable", "screen_room_details_encryption_enabled_title") }
  /// An error occurred when loading notification settings.
  internal static var screenRoomDetailsErrorLoadingNotificationSettings: String { return L10n.tr("Localizable", "screen_room_details_error_loading_notification_settings") }
  /// Failed muting this room, please try again.
  internal static var screenRoomDetailsErrorMuting: String { return L10n.tr("Localizable", "screen_room_details_error_muting") }
  /// Failed unmuting this room, please try again.
  internal static var screenRoomDetailsErrorUnmuting: String { return L10n.tr("Localizable", "screen_room_details_error_unmuting") }
  /// Invite people
  internal static var screenRoomDetailsInvitePeopleTitle: String { return L10n.tr("Localizable", "screen_room_details_invite_people_title") }
  /// Leave conversation
  internal static var screenRoomDetailsLeaveConversationTitle: String { return L10n.tr("Localizable", "screen_room_details_leave_conversation_title") }
  /// Leave room
  internal static var screenRoomDetailsLeaveRoomTitle: String { return L10n.tr("Localizable", "screen_room_details_leave_room_title") }
  /// Custom
  internal static var screenRoomDetailsNotificationModeCustom: String { return L10n.tr("Localizable", "screen_room_details_notification_mode_custom") }
  /// Default
  internal static var screenRoomDetailsNotificationModeDefault: String { return L10n.tr("Localizable", "screen_room_details_notification_mode_default") }
  /// Notifications
  internal static var screenRoomDetailsNotificationTitle: String { return L10n.tr("Localizable", "screen_room_details_notification_title") }
  /// Pinned messages
  internal static var screenRoomDetailsPinnedEventsRowTitle: String { return L10n.tr("Localizable", "screen_room_details_pinned_events_row_title") }
  /// Roles and permissions
  internal static var screenRoomDetailsRolesAndPermissions: String { return L10n.tr("Localizable", "screen_room_details_roles_and_permissions") }
  /// Room name
  internal static var screenRoomDetailsRoomNameLabel: String { return L10n.tr("Localizable", "screen_room_details_room_name_label") }
  /// Security
  internal static var screenRoomDetailsSecurityTitle: String { return L10n.tr("Localizable", "screen_room_details_security_title") }
  /// Share room
  internal static var screenRoomDetailsShareRoomTitle: String { return L10n.tr("Localizable", "screen_room_details_share_room_title") }
  /// Room info
  internal static var screenRoomDetailsTitle: String { return L10n.tr("Localizable", "screen_room_details_title") }
  /// Topic
  internal static var screenRoomDetailsTopicTitle: String { return L10n.tr("Localizable", "screen_room_details_topic_title") }
  /// Updating room…
  internal static var screenRoomDetailsUpdatingRoom: String { return L10n.tr("Localizable", "screen_room_details_updating_room") }
  /// Failed loading
  internal static var screenRoomDirectorySearchLoadingError: String { return L10n.tr("Localizable", "screen_room_directory_search_loading_error") }
  /// Room directory
  internal static var screenRoomDirectorySearchTitle: String { return L10n.tr("Localizable", "screen_room_directory_search_title") }
  /// Message history is currently unavailable.
  internal static var screenRoomEncryptedHistoryBanner: String { return L10n.tr("Localizable", "screen_room_encrypted_history_banner") }
  /// Message history is unavailable in this room. Verify this device to see your message history.
  internal static var screenRoomEncryptedHistoryBannerUnverified: String { return L10n.tr("Localizable", "screen_room_encrypted_history_banner_unverified") }
  /// Failed processing media to upload, please try again.
  internal static var screenRoomErrorFailedProcessingMedia: String { return L10n.tr("Localizable", "screen_room_error_failed_processing_media") }
  /// Could not retrieve user details
  internal static var screenRoomErrorFailedRetrievingUserDetails: String { return L10n.tr("Localizable", "screen_room_error_failed_retrieving_user_details") }
  /// Would you like to invite them back?
  internal static var screenRoomInviteAgainAlertMessage: String { return L10n.tr("Localizable", "screen_room_invite_again_alert_message") }
  /// You are alone in this chat
  internal static var screenRoomInviteAgainAlertTitle: String { return L10n.tr("Localizable", "screen_room_invite_again_alert_title") }
  /// Block
  internal static var screenRoomMemberDetailsBlockAlertAction: String { return L10n.tr("Localizable", "screen_room_member_details_block_alert_action") }
  /// Blocked users won't be able to send you messages and all their messages will be hidden. You can unblock them anytime.
  internal static var screenRoomMemberDetailsBlockAlertDescription: String { return L10n.tr("Localizable", "screen_room_member_details_block_alert_description") }
  /// Block user
  internal static var screenRoomMemberDetailsBlockUser: String { return L10n.tr("Localizable", "screen_room_member_details_block_user") }
  /// Profile
  internal static var screenRoomMemberDetailsTitle: String { return L10n.tr("Localizable", "screen_room_member_details_title") }
  /// Unblock
  internal static var screenRoomMemberDetailsUnblockAlertAction: String { return L10n.tr("Localizable", "screen_room_member_details_unblock_alert_action") }
  /// You'll be able to see all messages from them again.
  internal static var screenRoomMemberDetailsUnblockAlertDescription: String { return L10n.tr("Localizable", "screen_room_member_details_unblock_alert_description") }
  /// Unblock user
  internal static var screenRoomMemberDetailsUnblockUser: String { return L10n.tr("Localizable", "screen_room_member_details_unblock_user") }
  /// Ban
  internal static var screenRoomMemberListBanMemberConfirmationAction: String { return L10n.tr("Localizable", "screen_room_member_list_ban_member_confirmation_action") }
  /// They won’t be able to join this room again if invited.
  internal static var screenRoomMemberListBanMemberConfirmationDescription: String { return L10n.tr("Localizable", "screen_room_member_list_ban_member_confirmation_description") }
  /// Are you sure you want to ban this member?
  internal static var screenRoomMemberListBanMemberConfirmationTitle: String { return L10n.tr("Localizable", "screen_room_member_list_ban_member_confirmation_title") }
  /// There are no banned users in this room.
  internal static var screenRoomMemberListBannedEmpty: String { return L10n.tr("Localizable", "screen_room_member_list_banned_empty") }
  /// Banning %1$@
  internal static func screenRoomMemberListBanningUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_member_list_banning_user", String(describing: p1))
  }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomMemberListHeaderTitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_member_list_header_title", p1)
  }
  /// Remove and ban member
  internal static var screenRoomMemberListManageMemberBan: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_ban") }
  /// Remove from room
  internal static var screenRoomMemberListManageMemberRemove: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_remove") }
  /// Remove and ban member
  internal static var screenRoomMemberListManageMemberRemoveConfirmationBan: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_remove_confirmation_ban") }
  /// Only remove member
  internal static var screenRoomMemberListManageMemberRemoveConfirmationKick: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_remove_confirmation_kick") }
  /// Remove member and ban from joining in the future?
  internal static var screenRoomMemberListManageMemberRemoveConfirmationTitle: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_remove_confirmation_title") }
  /// Unban
  internal static var screenRoomMemberListManageMemberUnbanAction: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_unban_action") }
  /// They will be able to join this room again if invited.
  internal static var screenRoomMemberListManageMemberUnbanMessage: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_unban_message") }
  /// Unban user
  internal static var screenRoomMemberListManageMemberUnbanTitle: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_unban_title") }
  /// View profile
  internal static var screenRoomMemberListManageMemberUserInfo: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_user_info") }
  /// Banned
  internal static var screenRoomMemberListModeBanned: String { return L10n.tr("Localizable", "screen_room_member_list_mode_banned") }
  /// Members
  internal static var screenRoomMemberListModeMembers: String { return L10n.tr("Localizable", "screen_room_member_list_mode_members") }
  /// Pending
  internal static var screenRoomMemberListPendingHeaderTitle: String { return L10n.tr("Localizable", "screen_room_member_list_pending_header_title") }
  /// Removing %1$@…
  internal static func screenRoomMemberListRemovingUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_member_list_removing_user", String(describing: p1))
  }
  /// Admin
  internal static var screenRoomMemberListRoleAdministrator: String { return L10n.tr("Localizable", "screen_room_member_list_role_administrator") }
  /// Moderator
  internal static var screenRoomMemberListRoleModerator: String { return L10n.tr("Localizable", "screen_room_member_list_role_moderator") }
  /// Room members
  internal static var screenRoomMemberListRoomMembersHeaderTitle: String { return L10n.tr("Localizable", "screen_room_member_list_room_members_header_title") }
  /// Unbanning %1$@
  internal static func screenRoomMemberListUnbanningUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_member_list_unbanning_user", String(describing: p1))
  }
  /// Notify the whole room
  internal static var screenRoomMentionsAtRoomSubtitle: String { return L10n.tr("Localizable", "screen_room_mentions_at_room_subtitle") }
  /// Everyone
  internal static var screenRoomMentionsAtRoomTitle: String { return L10n.tr("Localizable", "screen_room_mentions_at_room_title") }
  /// Allow custom setting
  internal static var screenRoomNotificationSettingsAllowCustom: String { return L10n.tr("Localizable", "screen_room_notification_settings_allow_custom") }
  /// Turning this on will override your default setting
  internal static var screenRoomNotificationSettingsAllowCustomFootnote: String { return L10n.tr("Localizable", "screen_room_notification_settings_allow_custom_footnote") }
  /// Notify me in this chat for
  internal static var screenRoomNotificationSettingsCustomSettingsTitle: String { return L10n.tr("Localizable", "screen_room_notification_settings_custom_settings_title") }
  /// You can change it in your %1$@.
  internal static func screenRoomNotificationSettingsDefaultSettingFootnote(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_notification_settings_default_setting_footnote", String(describing: p1))
  }
  /// global settings
  internal static var screenRoomNotificationSettingsDefaultSettingFootnoteContentLink: String { return L10n.tr("Localizable", "screen_room_notification_settings_default_setting_footnote_content_link") }
  /// Default setting
  internal static var screenRoomNotificationSettingsDefaultSettingTitle: String { return L10n.tr("Localizable", "screen_room_notification_settings_default_setting_title") }
  /// Remove custom setting
  internal static var screenRoomNotificationSettingsEditRemoveSetting: String { return L10n.tr("Localizable", "screen_room_notification_settings_edit_remove_setting") }
  /// An error occurred while loading notification settings.
  internal static var screenRoomNotificationSettingsErrorLoadingSettings: String { return L10n.tr("Localizable", "screen_room_notification_settings_error_loading_settings") }
  /// Failed restoring the default mode, please try again.
  internal static var screenRoomNotificationSettingsErrorRestoringDefault: String { return L10n.tr("Localizable", "screen_room_notification_settings_error_restoring_default") }
  /// Failed setting the mode, please try again.
  internal static var screenRoomNotificationSettingsErrorSettingMode: String { return L10n.tr("Localizable", "screen_room_notification_settings_error_setting_mode") }
  /// Your homeserver does not support this option in encrypted rooms, you won't get notified in this room.
  internal static var screenRoomNotificationSettingsMentionsOnlyDisclaimer: String { return L10n.tr("Localizable", "screen_room_notification_settings_mentions_only_disclaimer") }
  /// All messages
  internal static var screenRoomNotificationSettingsModeAllMessages: String { return L10n.tr("Localizable", "screen_room_notification_settings_mode_all_messages") }
  /// Mentions and Keywords only
  internal static var screenRoomNotificationSettingsModeMentionsAndKeywords: String { return L10n.tr("Localizable", "screen_room_notification_settings_mode_mentions_and_keywords") }
  /// In this room, notify me for
  internal static var screenRoomNotificationSettingsRoomCustomSettingsTitle: String { return L10n.tr("Localizable", "screen_room_notification_settings_room_custom_settings_title") }
  /// %1$@ of %2$@
  internal static func screenRoomPinnedBannerIndicator(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_room_pinned_banner_indicator", String(describing: p1), String(describing: p2))
  }
  /// %1$@ Pinned messages
  internal static func screenRoomPinnedBannerIndicatorDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_pinned_banner_indicator_description", String(describing: p1))
  }
  /// Loading message…
  internal static var screenRoomPinnedBannerLoadingDescription: String { return L10n.tr("Localizable", "screen_room_pinned_banner_loading_description") }
  /// View All
  internal static var screenRoomPinnedBannerViewAllButtonTitle: String { return L10n.tr("Localizable", "screen_room_pinned_banner_view_all_button_title") }
  /// Send again
  internal static var screenRoomRetrySendMenuSendAgainAction: String { return L10n.tr("Localizable", "screen_room_retry_send_menu_send_again_action") }
  /// Your message failed to send
  internal static var screenRoomRetrySendMenuTitle: String { return L10n.tr("Localizable", "screen_room_retry_send_menu_title") }
  /// Admins
  internal static var screenRoomRolesAndPermissionsAdmins: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_admins") }
  /// Change my role
  internal static var screenRoomRolesAndPermissionsChangeMyRole: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_change_my_role") }
  /// Demote to member
  internal static var screenRoomRolesAndPermissionsChangeRoleDemoteToMember: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_change_role_demote_to_member") }
  /// Demote to moderator
  internal static var screenRoomRolesAndPermissionsChangeRoleDemoteToModerator: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_change_role_demote_to_moderator") }
  /// Member moderation
  internal static var screenRoomRolesAndPermissionsMemberModeration: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_member_moderation") }
  /// Messages and content
  internal static var screenRoomRolesAndPermissionsMessagesAndContent: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_messages_and_content") }
  /// Moderators
  internal static var screenRoomRolesAndPermissionsModerators: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_moderators") }
  /// Permissions
  internal static var screenRoomRolesAndPermissionsPermissionsHeader: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_permissions_header") }
  /// Reset permissions
  internal static var screenRoomRolesAndPermissionsReset: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_reset") }
  /// Once you reset permissions, you will lose the current settings.
  internal static var screenRoomRolesAndPermissionsResetConfirmDescription: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_reset_confirm_description") }
  /// Reset permissions?
  internal static var screenRoomRolesAndPermissionsResetConfirmTitle: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_reset_confirm_title") }
  /// Roles
  internal static var screenRoomRolesAndPermissionsRolesHeader: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_roles_header") }
  /// Room details
  internal static var screenRoomRolesAndPermissionsRoomDetails: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_room_details") }
  /// Roles and permissions
  internal static var screenRoomRolesAndPermissionsTitle: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_title") }
  /// Add emoji
  internal static var screenRoomTimelineAddReaction: String { return L10n.tr("Localizable", "screen_room_timeline_add_reaction") }
  /// This is the beginning of %1$@.
  internal static func screenRoomTimelineBeginningOfRoom(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_timeline_beginning_of_room", String(describing: p1))
  }
  /// This is the beginning of this conversation.
  internal static var screenRoomTimelineBeginningOfRoomNoName: String { return L10n.tr("Localizable", "screen_room_timeline_beginning_of_room_no_name") }
  /// Show less
  internal static var screenRoomTimelineLessReactions: String { return L10n.tr("Localizable", "screen_room_timeline_less_reactions") }
  /// Message copied
  internal static var screenRoomTimelineMessageCopied: String { return L10n.tr("Localizable", "screen_room_timeline_message_copied") }
  /// You do not have permission to post to this room
  internal static var screenRoomTimelineNoPermissionToPost: String { return L10n.tr("Localizable", "screen_room_timeline_no_permission_to_post") }
  /// Show less
  internal static var screenRoomTimelineReactionsShowLess: String { return L10n.tr("Localizable", "screen_room_timeline_reactions_show_less") }
  /// Show more
  internal static var screenRoomTimelineReactionsShowMore: String { return L10n.tr("Localizable", "screen_room_timeline_reactions_show_more") }
  /// New
  internal static var screenRoomTimelineReadMarkerTitle: String { return L10n.tr("Localizable", "screen_room_timeline_read_marker_title") }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomTimelineStateChanges(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_timeline_state_changes", p1)
  }
  /// Chat
  internal static var screenRoomTitle: String { return L10n.tr("Localizable", "screen_room_title") }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomTypingManyMembers(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_typing_many_members", p1)
  }
  /// %1$@, %2$@ and 
  internal static func screenRoomTypingManyMembersFirstComponentIos(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_room_typing_many_members_first_component_ios", String(describing: p1), String(describing: p2))
  }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomTypingManyMembersSecondComponentIos(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_typing_many_members_second_component_ios", p1)
  }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomTypingNotification(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_typing_notification", p1)
  }
  ///  are typing…
  internal static var screenRoomTypingNotificationPluralIos: String { return L10n.tr("Localizable", "screen_room_typing_notification_plural_ios") }
  ///  is typing…
  internal static var screenRoomTypingNotificationSingularIos: String { return L10n.tr("Localizable", "screen_room_typing_notification_singular_ios") }
  /// %1$@ and %2$@
  internal static func screenRoomTypingTwoMembers(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_room_typing_two_members", String(describing: p1), String(describing: p2))
  }
  /// Hold to record
  internal static var screenRoomVoiceMessageTooltip: String { return L10n.tr("Localizable", "screen_room_voice_message_tooltip") }
  /// Create a new conversation or room
  internal static var screenRoomlistA11yCreateMessage: String { return L10n.tr("Localizable", "screen_roomlist_a11y_create_message") }
  /// Get started by messaging someone.
  internal static var screenRoomlistEmptyMessage: String { return L10n.tr("Localizable", "screen_roomlist_empty_message") }
  /// No chats yet.
  internal static var screenRoomlistEmptyTitle: String { return L10n.tr("Localizable", "screen_roomlist_empty_title") }
  /// Favourites
  internal static var screenRoomlistFilterFavourites: String { return L10n.tr("Localizable", "screen_roomlist_filter_favourites") }
  /// You can add a chat to your favourites in the chat settings.
  /// For now, you can deselect filters in order to see your other chats
  internal static var screenRoomlistFilterFavouritesEmptyStateSubtitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_favourites_empty_state_subtitle") }
  /// You don’t have favourite chats yet
  internal static var screenRoomlistFilterFavouritesEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_favourites_empty_state_title") }
  /// Invites
  internal static var screenRoomlistFilterInvites: String { return L10n.tr("Localizable", "screen_roomlist_filter_invites") }
  /// You don't have any pending invites.
  internal static var screenRoomlistFilterInvitesEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_invites_empty_state_title") }
  /// Low Priority
  internal static var screenRoomlistFilterLowPriority: String { return L10n.tr("Localizable", "screen_roomlist_filter_low_priority") }
  /// You can deselect filters in order to see your other chats
  internal static var screenRoomlistFilterMixedEmptyStateSubtitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_mixed_empty_state_subtitle") }
  /// You don’t have chats for this selection
  internal static var screenRoomlistFilterMixedEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_mixed_empty_state_title") }
  /// People
  internal static var screenRoomlistFilterPeople: String { return L10n.tr("Localizable", "screen_roomlist_filter_people") }
  /// You don’t have any DMs yet
  internal static var screenRoomlistFilterPeopleEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_people_empty_state_title") }
  /// Rooms
  internal static var screenRoomlistFilterRooms: String { return L10n.tr("Localizable", "screen_roomlist_filter_rooms") }
  /// You’re not in any room yet
  internal static var screenRoomlistFilterRoomsEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_rooms_empty_state_title") }
  /// Unreads
  internal static var screenRoomlistFilterUnreads: String { return L10n.tr("Localizable", "screen_roomlist_filter_unreads") }
  /// Congrats!
  /// You don’t have any unread messages!
  internal static var screenRoomlistFilterUnreadsEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_unreads_empty_state_title") }
  /// Chats
  internal static var screenRoomlistMainSpaceTitle: String { return L10n.tr("Localizable", "screen_roomlist_main_space_title") }
  /// Mark as read
  internal static var screenRoomlistMarkAsRead: String { return L10n.tr("Localizable", "screen_roomlist_mark_as_read") }
  /// Mark as unread
  internal static var screenRoomlistMarkAsUnread: String { return L10n.tr("Localizable", "screen_roomlist_mark_as_unread") }
  /// Browse all rooms
  internal static var screenRoomlistRoomDirectoryButtonTitle: String { return L10n.tr("Localizable", "screen_roomlist_room_directory_button_title") }
  /// Change account provider
  internal static var screenServerConfirmationChangeServer: String { return L10n.tr("Localizable", "screen_server_confirmation_change_server") }
  /// A private server for Element employees.
  internal static var screenServerConfirmationMessageLoginElementDotIo: String { return L10n.tr("Localizable", "screen_server_confirmation_message_login_element_dot_io") }
  /// Matrix is an open network for secure, decentralised communication.
  internal static var screenServerConfirmationMessageLoginMatrixDotOrg: String { return L10n.tr("Localizable", "screen_server_confirmation_message_login_matrix_dot_org") }
  /// This is where your conversations will live — just like you would use an email provider to keep your emails.
  internal static var screenServerConfirmationMessageRegister: String { return L10n.tr("Localizable", "screen_server_confirmation_message_register") }
  /// You’re about to sign in to %1$@
  internal static func screenServerConfirmationTitleLogin(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_server_confirmation_title_login", String(describing: p1))
  }
  /// You’re about to create an account on %1$@
  internal static func screenServerConfirmationTitleRegister(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_server_confirmation_title_register", String(describing: p1))
  }
  /// Something doesn’t seem right. Either the request timed out or the request was denied.
  internal static var screenSessionVerificationCancelledSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_cancelled_subtitle") }
  /// Confirm that the emojis below match those shown on your other session.
  internal static var screenSessionVerificationCompareEmojisSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_compare_emojis_subtitle") }
  /// Compare emojis
  internal static var screenSessionVerificationCompareEmojisTitle: String { return L10n.tr("Localizable", "screen_session_verification_compare_emojis_title") }
  /// Confirm that the numbers below match those shown on your other session.
  internal static var screenSessionVerificationCompareNumbersSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_compare_numbers_subtitle") }
  /// Compare numbers
  internal static var screenSessionVerificationCompareNumbersTitle: String { return L10n.tr("Localizable", "screen_session_verification_compare_numbers_title") }
  /// Your new session is now verified. It has access to your encrypted messages, and other users will see it as trusted.
  internal static var screenSessionVerificationCompleteSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_complete_subtitle") }
  /// Enter recovery key
  internal static var screenSessionVerificationEnterRecoveryKey: String { return L10n.tr("Localizable", "screen_session_verification_enter_recovery_key") }
  /// Prove it’s you in order to access your encrypted message history.
  internal static var screenSessionVerificationOpenExistingSessionSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_open_existing_session_subtitle") }
  /// Open an existing session
  internal static var screenSessionVerificationOpenExistingSessionTitle: String { return L10n.tr("Localizable", "screen_session_verification_open_existing_session_title") }
  /// Retry verification
  internal static var screenSessionVerificationPositiveButtonCanceled: String { return L10n.tr("Localizable", "screen_session_verification_positive_button_canceled") }
  /// I am ready
  internal static var screenSessionVerificationPositiveButtonInitial: String { return L10n.tr("Localizable", "screen_session_verification_positive_button_initial") }
  /// Waiting to match
  internal static var screenSessionVerificationPositiveButtonVerifyingOngoing: String { return L10n.tr("Localizable", "screen_session_verification_positive_button_verifying_ongoing") }
  /// Compare a unique set of emojis.
  internal static var screenSessionVerificationReadySubtitle: String { return L10n.tr("Localizable", "screen_session_verification_ready_subtitle") }
  /// Compare the unique emoji, ensuring they appear in the same order.
  internal static var screenSessionVerificationRequestAcceptedSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_request_accepted_subtitle") }
  /// They don’t match
  internal static var screenSessionVerificationTheyDontMatch: String { return L10n.tr("Localizable", "screen_session_verification_they_dont_match") }
  /// They match
  internal static var screenSessionVerificationTheyMatch: String { return L10n.tr("Localizable", "screen_session_verification_they_match") }
  /// Accept the request to start the verification process in your other session to continue.
  internal static var screenSessionVerificationWaitingToAcceptSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_waiting_to_accept_subtitle") }
  /// Waiting to accept request
  internal static var screenSessionVerificationWaitingToAcceptTitle: String { return L10n.tr("Localizable", "screen_session_verification_waiting_to_accept_title") }
  /// Share location
  internal static var screenShareLocationTitle: String { return L10n.tr("Localizable", "screen_share_location_title") }
  /// Share my location
  internal static var screenShareMyLocationAction: String { return L10n.tr("Localizable", "screen_share_my_location_action") }
  /// Open in Apple Maps
  internal static var screenShareOpenAppleMaps: String { return L10n.tr("Localizable", "screen_share_open_apple_maps") }
  /// Open in Google Maps
  internal static var screenShareOpenGoogleMaps: String { return L10n.tr("Localizable", "screen_share_open_google_maps") }
  /// Open in OpenStreetMap
  internal static var screenShareOpenOsmMaps: String { return L10n.tr("Localizable", "screen_share_open_osm_maps") }
  /// Share this location
  internal static var screenShareThisLocationAction: String { return L10n.tr("Localizable", "screen_share_this_location_action") }
  /// You’ve changed your password on another session
  internal static var screenSignedOutReason1: String { return L10n.tr("Localizable", "screen_signed_out_reason_1") }
  /// You have deleted the session from another session
  internal static var screenSignedOutReason2: String { return L10n.tr("Localizable", "screen_signed_out_reason_2") }
  /// Your server’s administrator has invalidated your access
  internal static var screenSignedOutReason3: String { return L10n.tr("Localizable", "screen_signed_out_reason_3") }
  /// You might have been signed out for one of the reasons listed below. Please sign in again to continue using %@.
  internal static func screenSignedOutSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_signed_out_subtitle", String(describing: p1))
  }
  /// You’re signed out
  internal static var screenSignedOutTitle: String { return L10n.tr("Localizable", "screen_signed_out_title") }
  /// Are you sure you want to sign out?
  internal static var screenSignoutConfirmationDialogContent: String { return L10n.tr("Localizable", "screen_signout_confirmation_dialog_content") }
  /// Sign out
  internal static var screenSignoutConfirmationDialogSubmit: String { return L10n.tr("Localizable", "screen_signout_confirmation_dialog_submit") }
  /// Sign out
  internal static var screenSignoutConfirmationDialogTitle: String { return L10n.tr("Localizable", "screen_signout_confirmation_dialog_title") }
  /// Signing out…
  internal static var screenSignoutInProgressDialogContent: String { return L10n.tr("Localizable", "screen_signout_in_progress_dialog_content") }
  /// You are about to sign out of your last session. If you sign out now, you will lose access to your encrypted messages.
  internal static var screenSignoutKeyBackupDisabledSubtitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_disabled_subtitle") }
  /// You have turned off backup
  internal static var screenSignoutKeyBackupDisabledTitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_disabled_title") }
  /// Your keys were still being backed up when you went offline. Reconnect so that your keys can be backed up before signing out.
  internal static var screenSignoutKeyBackupOfflineSubtitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_offline_subtitle") }
  /// Your keys are still being backed up
  internal static var screenSignoutKeyBackupOfflineTitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_offline_title") }
  /// Please wait for this to complete before signing out.
  internal static var screenSignoutKeyBackupOngoingSubtitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_ongoing_subtitle") }
  /// Your keys are still being backed up
  internal static var screenSignoutKeyBackupOngoingTitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_ongoing_title") }
  /// Sign out
  internal static var screenSignoutPreferenceItem: String { return L10n.tr("Localizable", "screen_signout_preference_item") }
  /// You are about to sign out of your last session. If you sign out now, you'll lose access to your encrypted messages.
  internal static var screenSignoutRecoveryDisabledSubtitle: String { return L10n.tr("Localizable", "screen_signout_recovery_disabled_subtitle") }
  /// Recovery not set up
  internal static var screenSignoutRecoveryDisabledTitle: String { return L10n.tr("Localizable", "screen_signout_recovery_disabled_title") }
  /// You are about to sign out of your last session. If you sign out now, you might lose access to your encrypted messages.
  internal static var screenSignoutSaveRecoveryKeySubtitle: String { return L10n.tr("Localizable", "screen_signout_save_recovery_key_subtitle") }
  /// Have you saved your recovery key?
  internal static var screenSignoutSaveRecoveryKeyTitle: String { return L10n.tr("Localizable", "screen_signout_save_recovery_key_title") }
  /// An error occurred when trying to start a chat
  internal static var screenStartChatErrorStartingChat: String { return L10n.tr("Localizable", "screen_start_chat_error_starting_chat") }
  /// Message not sent because %1$@’s verified identity has changed.
  internal static func screenTimelineItemMenuSendFailureChangedIdentity(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_timeline_item_menu_send_failure_changed_identity", String(describing: p1))
  }
  /// Message not sent because %1$@ has not verified all devices.
  internal static func screenTimelineItemMenuSendFailureUnsignedDevice(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_timeline_item_menu_send_failure_unsigned_device", String(describing: p1))
  }
  /// Message not sent because you have not verified one or more of your devices.
  internal static var screenTimelineItemMenuSendFailureYouUnsignedDevice: String { return L10n.tr("Localizable", "screen_timeline_item_menu_send_failure_you_unsigned_device") }
  /// Location
  internal static var screenViewLocationTitle: String { return L10n.tr("Localizable", "screen_view_location_title") }
  /// Calls, polls, search and more will be added later this year.
  internal static var screenWelcomeBullet1: String { return L10n.tr("Localizable", "screen_welcome_bullet_1") }
  /// Message history for encrypted rooms isn’t available yet.
  internal static var screenWelcomeBullet2: String { return L10n.tr("Localizable", "screen_welcome_bullet_2") }
  /// We’d love to hear from you, let us know what you think via the settings page.
  internal static var screenWelcomeBullet3: String { return L10n.tr("Localizable", "screen_welcome_bullet_3") }
  /// Let's go!
  internal static var screenWelcomeButton: String { return L10n.tr("Localizable", "screen_welcome_button") }
  /// Here’s what you need to know:
  internal static var screenWelcomeSubtitle: String { return L10n.tr("Localizable", "screen_welcome_subtitle") }
  /// Welcome to %1$@!
  internal static func screenWelcomeTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_welcome_title", String(describing: p1))
  }
  /// Looks like you’re using a new device. Verify with another device to access your encrypted messages.
  internal static var sessionVerificationBannerMessage: String { return L10n.tr("Localizable", "session_verification_banner_message") }
  /// Verify it’s you
  internal static var sessionVerificationBannerTitle: String { return L10n.tr("Localizable", "session_verification_banner_title") }
  /// Rageshake
  internal static var settingsRageshake: String { return L10n.tr("Localizable", "settings_rageshake") }
  /// Detection threshold
  internal static var settingsRageshakeDetectionThreshold: String { return L10n.tr("Localizable", "settings_rageshake_detection_threshold") }
  /// Version: %1$@ (%2$@)
  internal static func settingsVersionNumber(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "settings_version_number", String(describing: p1), String(describing: p2))
  }
  /// (avatar was changed too)
  internal static var stateEventAvatarChangedToo: String { return L10n.tr("Localizable", "state_event_avatar_changed_too") }
  /// %1$@ changed their avatar
  internal static func stateEventAvatarUrlChanged(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_avatar_url_changed", String(describing: p1))
  }
  /// You changed your avatar
  internal static var stateEventAvatarUrlChangedByYou: String { return L10n.tr("Localizable", "state_event_avatar_url_changed_by_you") }
  /// %1$@ was demoted to member
  internal static func stateEventDemotedToMember(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_demoted_to_member", String(describing: p1))
  }
  /// %1$@ was demoted to moderator
  internal static func stateEventDemotedToModerator(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_demoted_to_moderator", String(describing: p1))
  }
  /// %1$@ changed their display name from %2$@ to %3$@
  internal static func stateEventDisplayNameChangedFrom(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_changed_from", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// You changed your display name from %1$@ to %2$@
  internal static func stateEventDisplayNameChangedFromByYou(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_changed_from_by_you", String(describing: p1), String(describing: p2))
  }
  /// %1$@ removed their display name (it was %2$@)
  internal static func stateEventDisplayNameRemoved(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_removed", String(describing: p1), String(describing: p2))
  }
  /// You removed your display name (it was %1$@)
  internal static func stateEventDisplayNameRemovedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_removed_by_you", String(describing: p1))
  }
  /// %1$@ set their display name to %2$@
  internal static func stateEventDisplayNameSet(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_set", String(describing: p1), String(describing: p2))
  }
  /// You set your display name to %1$@
  internal static func stateEventDisplayNameSetByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_set_by_you", String(describing: p1))
  }
  /// %1$@ was promoted to admin
  internal static func stateEventPromotedToAdministrator(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_promoted_to_administrator", String(describing: p1))
  }
  /// %1$@ was promoted to moderator
  internal static func stateEventPromotedToModerator(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_promoted_to_moderator", String(describing: p1))
  }
  /// %1$@ changed the room avatar
  internal static func stateEventRoomAvatarChanged(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_avatar_changed", String(describing: p1))
  }
  /// You changed the room avatar
  internal static var stateEventRoomAvatarChangedByYou: String { return L10n.tr("Localizable", "state_event_room_avatar_changed_by_you") }
  /// %1$@ removed the room avatar
  internal static func stateEventRoomAvatarRemoved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_avatar_removed", String(describing: p1))
  }
  /// You removed the room avatar
  internal static var stateEventRoomAvatarRemovedByYou: String { return L10n.tr("Localizable", "state_event_room_avatar_removed_by_you") }
  /// %1$@ banned %2$@
  internal static func stateEventRoomBan(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_ban", String(describing: p1), String(describing: p2))
  }
  /// You banned %1$@
  internal static func stateEventRoomBanByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_ban_by_you", String(describing: p1))
  }
  /// %1$@ created the room
  internal static func stateEventRoomCreated(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_created", String(describing: p1))
  }
  /// You created the room
  internal static var stateEventRoomCreatedByYou: String { return L10n.tr("Localizable", "state_event_room_created_by_you") }
  /// %1$@ invited %2$@
  internal static func stateEventRoomInvite(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite", String(describing: p1), String(describing: p2))
  }
  /// %1$@ accepted the invite
  internal static func stateEventRoomInviteAccepted(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite_accepted", String(describing: p1))
  }
  /// You accepted the invite
  internal static var stateEventRoomInviteAcceptedByYou: String { return L10n.tr("Localizable", "state_event_room_invite_accepted_by_you") }
  /// You invited %1$@
  internal static func stateEventRoomInviteByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite_by_you", String(describing: p1))
  }
  /// %1$@ invited you
  internal static func stateEventRoomInviteYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite_you", String(describing: p1))
  }
  /// %1$@ joined the room
  internal static func stateEventRoomJoin(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_join", String(describing: p1))
  }
  /// You joined the room
  internal static var stateEventRoomJoinByYou: String { return L10n.tr("Localizable", "state_event_room_join_by_you") }
  /// %1$@ requested to join
  internal static func stateEventRoomKnock(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock", String(describing: p1))
  }
  /// %1$@ allowed %2$@ to join
  internal static func stateEventRoomKnockAccepted(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_accepted", String(describing: p1), String(describing: p2))
  }
  /// You allowed %1$@ to join
  internal static func stateEventRoomKnockAcceptedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_accepted_by_you", String(describing: p1))
  }
  /// You requested to join
  internal static var stateEventRoomKnockByYou: String { return L10n.tr("Localizable", "state_event_room_knock_by_you") }
  /// %1$@ rejected %2$@'s request to join
  internal static func stateEventRoomKnockDenied(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_denied", String(describing: p1), String(describing: p2))
  }
  /// You rejected %1$@'s request to join
  internal static func stateEventRoomKnockDeniedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_denied_by_you", String(describing: p1))
  }
  /// %1$@ rejected your request to join
  internal static func stateEventRoomKnockDeniedYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_denied_you", String(describing: p1))
  }
  /// %1$@ is no longer interested in joining
  internal static func stateEventRoomKnockRetracted(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_retracted", String(describing: p1))
  }
  /// You cancelled your request to join
  internal static var stateEventRoomKnockRetractedByYou: String { return L10n.tr("Localizable", "state_event_room_knock_retracted_by_you") }
  /// %1$@ left the room
  internal static func stateEventRoomLeave(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_leave", String(describing: p1))
  }
  /// You left the room
  internal static var stateEventRoomLeaveByYou: String { return L10n.tr("Localizable", "state_event_room_leave_by_you") }
  /// %1$@ changed the room name to: %2$@
  internal static func stateEventRoomNameChanged(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_name_changed", String(describing: p1), String(describing: p2))
  }
  /// You changed the room name to: %1$@
  internal static func stateEventRoomNameChangedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_name_changed_by_you", String(describing: p1))
  }
  /// %1$@ removed the room name
  internal static func stateEventRoomNameRemoved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_name_removed", String(describing: p1))
  }
  /// You removed the room name
  internal static var stateEventRoomNameRemovedByYou: String { return L10n.tr("Localizable", "state_event_room_name_removed_by_you") }
  /// %1$@ made no changes
  internal static func stateEventRoomNone(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_none", String(describing: p1))
  }
  /// You made no changes
  internal static var stateEventRoomNoneByYou: String { return L10n.tr("Localizable", "state_event_room_none_by_you") }
  /// %1$@ changed the pinned messages
  internal static func stateEventRoomPinnedEventsChanged(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_pinned_events_changed", String(describing: p1))
  }
  /// You changed the pinned messages
  internal static var stateEventRoomPinnedEventsChangedByYou: String { return L10n.tr("Localizable", "state_event_room_pinned_events_changed_by_you") }
  /// %1$@ pinned a message
  internal static func stateEventRoomPinnedEventsPinned(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_pinned_events_pinned", String(describing: p1))
  }
  /// You pinned a message
  internal static var stateEventRoomPinnedEventsPinnedByYou: String { return L10n.tr("Localizable", "state_event_room_pinned_events_pinned_by_you") }
  /// %1$@ unpinned a message
  internal static func stateEventRoomPinnedEventsUnpinned(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_pinned_events_unpinned", String(describing: p1))
  }
  /// You unpinned a message
  internal static var stateEventRoomPinnedEventsUnpinnedByYou: String { return L10n.tr("Localizable", "state_event_room_pinned_events_unpinned_by_you") }
  /// %1$@ rejected the invitation
  internal static func stateEventRoomReject(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_reject", String(describing: p1))
  }
  /// You rejected the invitation
  internal static var stateEventRoomRejectByYou: String { return L10n.tr("Localizable", "state_event_room_reject_by_you") }
  /// %1$@ removed %2$@
  internal static func stateEventRoomRemove(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_remove", String(describing: p1), String(describing: p2))
  }
  /// You removed %1$@
  internal static func stateEventRoomRemoveByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_remove_by_you", String(describing: p1))
  }
  /// %1$@ sent an invitation to %2$@ to join the room
  internal static func stateEventRoomThirdPartyInvite(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_invite", String(describing: p1), String(describing: p2))
  }
  /// You sent an invitation to %1$@ to join the room
  internal static func stateEventRoomThirdPartyInviteByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_invite_by_you", String(describing: p1))
  }
  /// %1$@ revoked the invitation for %2$@ to join the room
  internal static func stateEventRoomThirdPartyRevokedInvite(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_revoked_invite", String(describing: p1), String(describing: p2))
  }
  /// You revoked the invitation for %1$@ to join the room
  internal static func stateEventRoomThirdPartyRevokedInviteByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_revoked_invite_by_you", String(describing: p1))
  }
  /// %1$@ changed the topic to: %2$@
  internal static func stateEventRoomTopicChanged(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_topic_changed", String(describing: p1), String(describing: p2))
  }
  /// You changed the topic to: %1$@
  internal static func stateEventRoomTopicChangedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_topic_changed_by_you", String(describing: p1))
  }
  /// %1$@ removed the room topic
  internal static func stateEventRoomTopicRemoved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_topic_removed", String(describing: p1))
  }
  /// You removed the room topic
  internal static var stateEventRoomTopicRemovedByYou: String { return L10n.tr("Localizable", "state_event_room_topic_removed_by_you") }
  /// %1$@ unbanned %2$@
  internal static func stateEventRoomUnban(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_unban", String(describing: p1), String(describing: p2))
  }
  /// You unbanned %1$@
  internal static func stateEventRoomUnbanByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_unban_by_you", String(describing: p1))
  }
  /// %1$@ made an unknown change to their membership
  internal static func stateEventRoomUnknownMembershipChange(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_unknown_membership_change", String(describing: p1))
  }
  /// en
  internal static var testLanguageIdentifier: String { return L10n.tr("Localizable", "test_language_identifier") }
  /// en
  internal static var testUntranslatedDefaultLanguageIdentifier: String { return L10n.tr("Localizable", "test_untranslated_default_language_identifier") }
  /// Troubleshoot
  internal static var troubleshootNotificationsEntryPointSection: String { return L10n.tr("Localizable", "troubleshoot_notifications_entry_point_section") }
  /// Troubleshoot notifications
  internal static var troubleshootNotificationsEntryPointTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_entry_point_title") }
  /// Run tests
  internal static var troubleshootNotificationsScreenAction: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_action") }
  /// Run tests again
  internal static var troubleshootNotificationsScreenActionAgain: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_action_again") }
  /// Some tests failed. Please check the details.
  internal static var troubleshootNotificationsScreenFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_failure") }
  /// Run the tests to detect any issue in your configuration that may make notifications not behave as expected.
  internal static var troubleshootNotificationsScreenNotice: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_notice") }
  /// Attempt to fix
  internal static var troubleshootNotificationsScreenQuickFixAction: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_quick_fix_action") }
  /// All tests passed successfully.
  internal static var troubleshootNotificationsScreenSuccess: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_success") }
  /// Troubleshoot notifications
  internal static var troubleshootNotificationsScreenTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_title") }
  /// Some tests require your attention. Please check the details.
  internal static var troubleshootNotificationsScreenWaiting: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_waiting") }
  /// Check that the application can show notifications.
  internal static var troubleshootNotificationsTestCheckPermissionDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_check_permission_description") }
  /// Check permissions
  internal static var troubleshootNotificationsTestCheckPermissionTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_check_permission_title") }
  /// Get the name of the current provider.
  internal static var troubleshootNotificationsTestCurrentPushProviderDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_current_push_provider_description") }
  /// No push providers selected.
  internal static var troubleshootNotificationsTestCurrentPushProviderFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_current_push_provider_failure") }
  /// Current push provider: %1$@.
  internal static func troubleshootNotificationsTestCurrentPushProviderSuccess(_ p1: Any) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_current_push_provider_success", String(describing: p1))
  }
  /// Current push provider
  internal static var troubleshootNotificationsTestCurrentPushProviderTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_current_push_provider_title") }
  /// Ensure that the application has at least one push provider.
  internal static var troubleshootNotificationsTestDetectPushProviderDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_detect_push_provider_description") }
  /// No push providers found.
  internal static var troubleshootNotificationsTestDetectPushProviderFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_detect_push_provider_failure") }
  /// Plural format key: "%#@COUNT@"
  internal static func troubleshootNotificationsTestDetectPushProviderSuccess(_ p1: Int) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_detect_push_provider_success", p1)
  }
  /// Detect push providers
  internal static var troubleshootNotificationsTestDetectPushProviderTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_detect_push_provider_title") }
  /// Check that the application can display notification.
  internal static var troubleshootNotificationsTestDisplayNotificationDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_description") }
  /// The notification has not been clicked.
  internal static var troubleshootNotificationsTestDisplayNotificationFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_failure") }
  /// Cannot display the notification.
  internal static var troubleshootNotificationsTestDisplayNotificationPermissionFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_permission_failure") }
  /// The notification has been clicked!
  internal static var troubleshootNotificationsTestDisplayNotificationSuccess: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_success") }
  /// Display notification
  internal static var troubleshootNotificationsTestDisplayNotificationTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_title") }
  /// Please click on the notification to continue the test.
  internal static var troubleshootNotificationsTestDisplayNotificationWaiting: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_waiting") }
  /// Ensure that Firebase is available.
  internal static var troubleshootNotificationsTestFirebaseAvailabilityDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_availability_description") }
  /// Firebase is not available.
  internal static var troubleshootNotificationsTestFirebaseAvailabilityFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_availability_failure") }
  /// Firebase is available.
  internal static var troubleshootNotificationsTestFirebaseAvailabilitySuccess: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_availability_success") }
  /// Check Firebase
  internal static var troubleshootNotificationsTestFirebaseAvailabilityTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_availability_title") }
  /// Ensure that Firebase token is available.
  internal static var troubleshootNotificationsTestFirebaseTokenDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_token_description") }
  /// Firebase token is not known.
  internal static var troubleshootNotificationsTestFirebaseTokenFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_token_failure") }
  /// Firebase token: %1$@.
  internal static func troubleshootNotificationsTestFirebaseTokenSuccess(_ p1: Any) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_token_success", String(describing: p1))
  }
  /// Check Firebase token
  internal static var troubleshootNotificationsTestFirebaseTokenTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_token_title") }
  /// Ensure that the application is receiving push.
  internal static var troubleshootNotificationsTestPushLoopBackDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_description") }
  /// Error: pusher has rejected the request.
  internal static var troubleshootNotificationsTestPushLoopBackFailure1: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_failure_1") }
  /// Error: %1$@.
  internal static func troubleshootNotificationsTestPushLoopBackFailure2(_ p1: Any) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_failure_2", String(describing: p1))
  }
  /// Error, cannot test push.
  internal static var troubleshootNotificationsTestPushLoopBackFailure3: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_failure_3") }
  /// Error, timeout waiting for push.
  internal static var troubleshootNotificationsTestPushLoopBackFailure4: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_failure_4") }
  /// Push loop back took %1$d ms.
  internal static func troubleshootNotificationsTestPushLoopBackSuccess(_ p1: Int) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_success", p1)
  }
  /// Test Push loop back
  internal static var troubleshootNotificationsTestPushLoopBackTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_title") }
  /// Ensure that UnifiedPush distributors are available.
  internal static var troubleshootNotificationsTestUnifiedPushDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_unified_push_description") }
  /// No push distributors found.
  internal static var troubleshootNotificationsTestUnifiedPushFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_unified_push_failure") }
  /// Plural format key: "%#@COUNT@"
  internal static func troubleshootNotificationsTestUnifiedPushSuccess(_ p1: Int) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_unified_push_success", p1)
  }
  /// Check UnifiedPush
  internal static var troubleshootNotificationsTestUnifiedPushTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_unified_push_title") }

  internal enum Banner {
    internal enum SetUpRecovery {
      /// Generate a new recovery key that can be used to restore your encrypted message history in case you lose access to your devices.
      internal static var content: String { return L10n.tr("Localizable", "banner.set_up_recovery.content") }
      /// Set up recovery
      internal static var title: String { return L10n.tr("Localizable", "banner.set_up_recovery.title") }
    }
  }

  internal enum Common {
    /// Copied to clipboard
    internal static var copiedToClipboard: String { return L10n.tr("Localizable", "common.copied_to_clipboard") }
    /// Do not show this again
    internal static var doNotShowThisAgain: String { return L10n.tr("Localizable", "common.do_not_show_this_again") }
    /// Open source licenses
    internal static var openSourceLicenses: String { return L10n.tr("Localizable", "common.open_source_licenses") }
    /// Pinned
    internal static var pinned: String { return L10n.tr("Localizable", "common.pinned") }
    /// Send to
    internal static var sendTo: String { return L10n.tr("Localizable", "common.send_to") }
    /// You
    internal static var you: String { return L10n.tr("Localizable", "common.you") }
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
