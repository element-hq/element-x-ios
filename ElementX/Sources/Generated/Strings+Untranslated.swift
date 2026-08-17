// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal nonisolated enum UntranslatedL10n {
  /// Manage storage
  internal static var screenAdvancedSettingsManageStorage: String { return UntranslatedL10n.tr("Untranslated", "screen_advanced_settings_manage_storage") }
  /// Fetch the photos and videos either side of the one on show ahead of swiping, using more data
  internal static var screenAdvancedSettingsPreloadMediaDescription: String { return UntranslatedL10n.tr("Untranslated", "screen_advanced_settings_preload_media_description") }
  /// Preload media in viewer
  internal static var screenAdvancedSettingsPreloadMediaTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_advanced_settings_preload_media_title") }
  /// Search
  internal static var screenHomeTabSearch: String { return UntranslatedL10n.tr("Untranslated", "screen_home_tab_search") }
  /// Clear %1$@
  internal static func screenManageStorageA11yClear(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_a11y_clear", String(describing: p1))
  }
  /// Log files
  internal static var screenManageStorageCacheLogs: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_cache_logs") }
  /// Cached media
  internal static var screenManageStorageCacheMedia: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_cache_media") }
  /// Cached message keys
  internal static var screenManageStorageCacheMessageKeys: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_cache_message_keys") }
  /// Cached messages
  internal static var screenManageStorageCacheMessages: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_cache_messages") }
  /// Cached room state
  internal static var screenManageStorageCacheRoomState: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_cache_room_state") }
  /// Clear all caches
  internal static var screenManageStorageClearAll: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_clear_all") }
  /// Clear %1$@?
  internal static func screenManageStorageClearCacheTitle(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_clear_cache_title", String(describing: p1))
  }
  /// Clear caches for %1$@
  internal static func screenManageStorageClearForRoom(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_clear_for_room", String(describing: p1))
  }
  /// Clear caches for %1$d rooms
  internal static func screenManageStorageClearForRooms(_ p1: Int) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_clear_for_rooms", p1)
  }
  /// %1$@?
  internal static func screenManageStorageClearScopeTitle(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_clear_scope_title", String(describing: p1))
  }
  /// Cleared
  internal static var screenManageStorageCleared: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_cleared") }
  /// Some caches could not be cleared.
  internal static var screenManageStorageError: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_error") }
  /// Rooms using more than 5 MB. Select rooms to see and clear their caches only.
  internal static var screenManageStorageRoomsSectionFooter: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_rooms_section_footer") }
  /// Storage by room
  internal static var screenManageStorageRoomsSectionTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_rooms_section_title") }
  /// All rooms
  internal static var screenManageStorageScopeAllRooms: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_scope_all_rooms") }
  /// %1$d rooms
  internal static func screenManageStorageScopeRooms(_ p1: Int) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_scope_rooms", p1)
  }
  /// Manage storage
  internal static var screenManageStorageTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_title") }
  /// View log files
  internal static var screenManageStorageViewLogs: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_view_logs") }
  /// If your message keys aren’t backed up, you may not be able to read older encrypted messages after clearing them.
  internal static var screenManageStorageWarningMessageKeys: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_warning_message_keys") }
  /// The app will restart to clear them.
  internal static var screenManageStorageWarningRestart: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_warning_restart") }
  /// Cached room state and cached messages are cleared together.
  internal static var screenManageStorageWarningRoomState: String { return UntranslatedL10n.tr("Untranslated", "screen_manage_storage_warning_room_state") }
  /// Search for chats and messages
  internal static var screenSearchEmptyStateMessage: String { return UntranslatedL10n.tr("Untranslated", "screen_search_empty_state_message") }
  /// Start searching...
  internal static var screenSearchEmptyStateTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_search_empty_state_title") }
  /// There are no results for “%1$@.” Try a new search term.
  internal static func screenSearchNoResultsMessage(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_search_no_results_message", String(describing: p1))
  }
  /// Chats
  internal static var screenSearchTabChats: String { return UntranslatedL10n.tr("Untranslated", "screen_search_tab_chats") }
  /// Messages
  internal static var screenSearchTabMessages: String { return UntranslatedL10n.tr("Untranslated", "screen_search_tab_messages") }
  /// Clear all data currently stored on this device?
  /// Sign in again to access your account data and messages.
  internal static var softLogoutClearDataDialogContent: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_dialog_content") }
  /// Clear data
  internal static var softLogoutClearDataDialogTitle: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_dialog_title") }
  /// Warning: Your personal data (including encryption keys) is still stored on this device.
  /// 
  /// Clear it if you’re finished using this device, or want to sign in to another account.
  internal static var softLogoutClearDataNotice: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_notice") }
  /// Clear all data
  internal static var softLogoutClearDataSubmit: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_submit") }
  /// Clear personal data
  internal static var softLogoutClearDataTitle: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_title") }
  /// Sign in to recover encryption keys stored exclusively on this device. You need them to read all of your secure messages on any device.
  internal static var softLogoutSigninE2eWarningNotice: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_signin_e2e_warning_notice") }
  /// Your homeserver (%1$s) admin has signed you out of your account %2$s (%3$s).
  internal static func softLogoutSigninNotice(_ p1: UnsafePointer<CChar>, _ p2: UnsafePointer<CChar>, _ p3: UnsafePointer<CChar>) -> String {
    return UntranslatedL10n.tr("Untranslated", "soft_logout_signin_notice", p1, p2, p3)
  }
  /// Sign in
  internal static var softLogoutSigninTitle: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_signin_title") }
  /// Untranslated
  internal static var untranslated: String { return UntranslatedL10n.tr("Untranslated", "untranslated") }
  /// Plural format key: "%#@VARIABLE@"
  internal static func untranslatedPlural(_ p1: Int) -> String {
    return UntranslatedL10n.tr("Untranslated", "untranslated_plural", p1)
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

nonisolated extension UntranslatedL10n {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // No need to check languages, we always default to en for untranslated strings
    guard let bundle = Bundle.lprojBundle(for: "en") else { return key }
    let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    return String(format: format, locale: Locale(identifier: "en"), arguments: args)
  }
}

// swiftlint:enable all
