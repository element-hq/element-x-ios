// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// Attach screenshot
  public static var actionAttachScreenshot: String { return L10n.tr("Localizable", "action_attach_screenshot") }
  /// Cancel
  public static var actionCancel: String { return L10n.tr("Localizable", "action_cancel") }
  /// Confirm
  public static var actionConfirm: String { return L10n.tr("Localizable", "action_confirm") }
  /// Continue
  public static var actionContinue: String { return L10n.tr("Localizable", "action_continue") }
  /// Copy
  public static var actionCopy: String { return L10n.tr("Localizable", "action_copy") }
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
  /// Not now
  public static var actionNotNow: String { return L10n.tr("Localizable", "action_not_now") }
  /// Ok
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
  /// All Chats
  public static var commonAllChats: String { return L10n.tr("Localizable", "common_all_chats") }
  /// Decryption error
  public static var commonDecryptionError: String { return L10n.tr("Localizable", "common_decryption_error") }
  /// (edited)
  public static var commonEditedSuffix: String { return L10n.tr("Localizable", "common_edited_suffix") }
  /// Editing
  public static var commonEditing: String { return L10n.tr("Localizable", "common_editing") }
  /// Encryption enabled
  public static var commonEncryptionEnabled: String { return L10n.tr("Localizable", "common_encryption_enabled") }
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
  /// Message
  public static var commonMessage: String { return L10n.tr("Localizable", "common_message") }
  /// Message removed
  public static var commonMessageRemoved: String { return L10n.tr("Localizable", "common_message_removed") }
  /// Password
  public static var commonPassword: String { return L10n.tr("Localizable", "common_password") }
  /// People
  public static var commonPeople: String { return L10n.tr("Localizable", "common_people") }
  /// Permalink
  public static var commonPermalink: String { return L10n.tr("Localizable", "common_permalink") }
  /// Reactions
  public static var commonReactions: String { return L10n.tr("Localizable", "common_reactions") }
  /// Settings
  public static var commonSettings: String { return L10n.tr("Localizable", "common_settings") }
  /// Sticker
  public static var commonSticker: String { return L10n.tr("Localizable", "common_sticker") }
  /// Suggestions
  public static var commonSuggestions: String { return L10n.tr("Localizable", "common_suggestions") }
  /// Topic
  public static var commonTopic: String { return L10n.tr("Localizable", "common_topic") }
  /// Unsupported event
  public static var commonUnsupportedEvent: String { return L10n.tr("Localizable", "common_unsupported_event") }
  /// Username
  public static var commonUsername: String { return L10n.tr("Localizable", "common_username") }
  /// Version
  public static var commonVersion: String { return L10n.tr("Localizable", "common_version") }
  /// Video
  public static var commonVideo: String { return L10n.tr("Localizable", "common_video") }
  /// Waiting…
  public static var commonWaiting: String { return L10n.tr("Localizable", "common_waiting") }
  /// Search for someone
  public static var searchForSomeone: String { return L10n.tr("Localizable", "search_for_someone") }
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

