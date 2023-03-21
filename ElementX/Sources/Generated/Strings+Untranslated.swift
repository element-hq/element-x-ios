// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
extension ElementL10n {
  /// Help us identify issues and improve %@ by sharing anonymous usage data. To understand how people use multiple devices, we’ll generate a random identifier, shared by your devices.
  /// 
  /// You can read all our terms %@.
  public static func analyticsOptInContent(_ p1: Any, _ p2: Any) -> String {
    return ElementL10n.tr("Untranslated", "analytics_opt_in_content", String(describing: p1), String(describing: p2))
  }
  /// here
  public static let analyticsOptInContentLink = ElementL10n.tr("Untranslated", "analytics_opt_in_content_link")
  /// We <b>don't</b> record or profile any account data
  public static let analyticsOptInListItem1 = ElementL10n.tr("Untranslated", "analytics_opt_in_list_item_1")
  /// We <b>don't</b> share information with third parties
  public static let analyticsOptInListItem2 = ElementL10n.tr("Untranslated", "analytics_opt_in_list_item_2")
  /// You can turn this off anytime in settings
  public static let analyticsOptInListItem3 = ElementL10n.tr("Untranslated", "analytics_opt_in_list_item_3")
  /// Help improve %@
  public static func analyticsOptInTitle(_ p1: Any) -> String {
    return ElementL10n.tr("Untranslated", "analytics_opt_in_title", String(describing: p1))
  }
  /// Clear all data currently stored on this device?
  /// Sign in again to access your account data and messages.
  public static let softLogoutClearDataDialogContent = ElementL10n.tr("Untranslated", "soft_logout_clear_data_dialog_content")
  /// Clear data
  public static let softLogoutClearDataDialogTitle = ElementL10n.tr("Untranslated", "soft_logout_clear_data_dialog_title")
  /// Warning: Your personal data (including encryption keys) is still stored on this device.
  /// 
  /// Clear it if you’re finished using this device, or want to sign in to another account.
  public static let softLogoutClearDataNotice = ElementL10n.tr("Untranslated", "soft_logout_clear_data_notice")
  /// Clear all data
  public static let softLogoutClearDataSubmit = ElementL10n.tr("Untranslated", "soft_logout_clear_data_submit")
  /// Clear personal data
  public static let softLogoutClearDataTitle = ElementL10n.tr("Untranslated", "soft_logout_clear_data_title")
  /// Sign in to recover encryption keys stored exclusively on this device. You need them to read all of your secure messages on any device.
  public static let softLogoutSigninE2eWarningNotice = ElementL10n.tr("Untranslated", "soft_logout_signin_e2e_warning_notice")
  /// Your homeserver (%1$s) admin has signed you out of your account %2$s (%3$s).
  public static func softLogoutSigninNotice(_ p1: UnsafePointer<CChar>, _ p2: UnsafePointer<CChar>, _ p3: UnsafePointer<CChar>) -> String {
    return ElementL10n.tr("Untranslated", "soft_logout_signin_notice", p1, p2, p3)
  }
  /// Sign in
  public static let softLogoutSigninTitle = ElementL10n.tr("Untranslated", "soft_logout_signin_title")
  /// Untranslated
  public static let untranslated = ElementL10n.tr("Untranslated", "untranslated")
  /// Plural format key: "%#@VARIABLE@"
  public static func untranslatedPlural(_ p1: Int) -> String {
    return ElementL10n.tr("Untranslated", "untranslated_plural", p1)
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces
