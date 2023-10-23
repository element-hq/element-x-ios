// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum UntranslatedL10n {
  /// You are about to sign out of your last session. If you sign out now, you will lose access to your encrypted messages.
  public static var screenSignoutKeyBackupDisabledSubtitle: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_key_backup_disabled_subtitle") }
  /// You have turned off backup
  public static var screenSignoutKeyBackupDisabledTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_key_backup_disabled_title") }
  /// Your keys were still being backed up when you went offline. Reconnect so that your keys can be backed up before signing out.
  public static var screenSignoutKeyBackupOfflineSubtitle: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_key_backup_offline_subtitle") }
  /// Your keys are still being backed up
  public static var screenSignoutKeyBackupOfflineTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_key_backup_offline_title") }
  /// Please wait for this to complete before signing out.
  public static var screenSignoutKeyBackupOngoingSubtitle: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_key_backup_ongoing_subtitle") }
  /// Your keys are still being backed up
  public static var screenSignoutKeyBackupOngoingTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_key_backup_ongoing_title") }
  /// You are about to sign out of your last session. If you sign out now, you'll lose access to your encrypted messages.
  public static var screenSignoutRecoveryDisabledSubtitle: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_recovery_disabled_subtitle") }
  /// Recovery not set up
  public static var screenSignoutRecoveryDisabledTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_recovery_disabled_title") }
  /// You are about to sign out of your last session. If you sign out now, you might lose access to your encrypted messages.
  public static var screenSignoutSaveRecoveryKeySubtitle: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_save_recovery_key_subtitle") }
  /// Have you saved your recovery key?
  public static var screenSignoutSaveRecoveryKeyTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_save_recovery_key_title") }
  /// Clear all data currently stored on this device?
  /// Sign in again to access your account data and messages.
  public static var softLogoutClearDataDialogContent: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_dialog_content") }
  /// Clear data
  public static var softLogoutClearDataDialogTitle: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_dialog_title") }
  /// Warning: Your personal data (including encryption keys) is still stored on this device.
  /// 
  /// Clear it if you’re finished using this device, or want to sign in to another account.
  public static var softLogoutClearDataNotice: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_notice") }
  /// Clear all data
  public static var softLogoutClearDataSubmit: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_submit") }
  /// Clear personal data
  public static var softLogoutClearDataTitle: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_title") }
  /// Sign in to recover encryption keys stored exclusively on this device. You need them to read all of your secure messages on any device.
  public static var softLogoutSigninE2eWarningNotice: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_signin_e2e_warning_notice") }
  /// Your homeserver (%1$s) admin has signed you out of your account %2$s (%3$s).
  public static func softLogoutSigninNotice(_ p1: UnsafePointer<CChar>, _ p2: UnsafePointer<CChar>, _ p3: UnsafePointer<CChar>) -> String {
    return UntranslatedL10n.tr("Untranslated", "soft_logout_signin_notice", p1, p2, p3)
  }
  /// Sign in
  public static var softLogoutSigninTitle: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_signin_title") }
  /// Untranslated
  public static var untranslated: String { return UntranslatedL10n.tr("Untranslated", "untranslated") }
  /// Plural format key: "%#@VARIABLE@"
  public static func untranslatedPlural(_ p1: Int) -> String {
    return UntranslatedL10n.tr("Untranslated", "untranslated_plural", p1)
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension UntranslatedL10n {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // No need to check languages, we always default to en for untranslated strings
    guard let bundle = Bundle.lprojBundle(for: "en") else { return key }
    let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    return String(format: format, locale: Locale(identifier: "en"), arguments: args)
  }
}

// swiftlint:enable all
