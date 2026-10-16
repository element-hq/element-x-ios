// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal nonisolated enum UntranslatedL10n {
  /// Make sure you always have access to another verified device or your recovery key to avoid losing your encrypted chat history.
  internal static var screenSignoutOtherVerifiedDeviceDialogContent: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_other_verified_device_dialog_content") }
  /// Are you sure you want to remove this device?
  internal static var screenSignoutOtherVerifiedDeviceDialogTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_other_verified_device_dialog_title") }
  /// Continue to remove this device
  internal static var screenSignoutSaveRecoveryKeyActionContinue: String { return UntranslatedL10n.tr("Untranslated", "screen_signout_save_recovery_key_action_continue") }
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
