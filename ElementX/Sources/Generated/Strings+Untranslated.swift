// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum UntranslatedL10n {
  /// Cancel for now
  internal static var actionCancelForNow: String { return UntranslatedL10n.tr("Untranslated", "action_cancel_for_now") }
  /// Message not sent because %1$@’s verified identity has changed.
  internal static func screenRoomSendFailureIdentityChangedMenuTitle(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_room_send_failure_identity_changed_menu_title", String(describing: p1))
  }
  /// Withdraw verification and send
  internal static var screenRoomSendFailureIdentityChangedResolvePrimaryButtonTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_room_send_failure_identity_changed_resolve_primary_button_title") }
  /// You can withdraw your verification and send this message anyway, or you can cancel for now and try again later after reverifying %1$@.
  internal static func screenRoomSendFailureIdentityChangedResolveSubtitle(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_room_send_failure_identity_changed_resolve_subtitle", String(describing: p1))
  }
  /// Your message was not sent because %1$@’s verified identity has changed
  internal static func screenRoomSendFailureIdentityChangedResolveTitle(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_room_send_failure_identity_changed_resolve_title", String(describing: p1))
  }
  /// Message not sent because %1$@ has not verified one or more devices.
  internal static func screenRoomSendFailureUnsignedDeviceMenuTitle(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_room_send_failure_unsigned_device_menu_title", String(describing: p1))
  }
  /// Send message anyway
  internal static var screenRoomSendFailureUnsignedDeviceResolvePrimaryButtonTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_room_send_failure_unsigned_device_resolve_primary_button_title") }
  /// %1$@ is using one or more unverified devices. You can send the message anyway, or you can cancel for now and try again later after %2$@ has verified all their devices.
  internal static func screenRoomSendFailureUnsignedDeviceResolveSubtitle(_ p1: Any, _ p2: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_room_send_failure_unsigned_device_resolve_subtitle", String(describing: p1), String(describing: p2))
  }
  /// Your message was not sent because %1$@ has not verified one or more devices
  internal static func screenRoomSendFailureUnsignedDeviceResolveTitle(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_room_send_failure_unsigned_device_resolve_title", String(describing: p1))
  }
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

extension UntranslatedL10n {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // No need to check languages, we always default to en for untranslated strings
    guard let bundle = Bundle.lprojBundle(for: "en") else { return key }
    let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    return String(format: format, locale: Locale(identifier: "en"), arguments: args)
  }
}

// swiftlint:enable all
