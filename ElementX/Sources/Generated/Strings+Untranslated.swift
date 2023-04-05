// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum UntranslatedL10n {
  /// Help us identify issues and improve %@ by sharing anonymous usage data. To understand how people use multiple devices, we’ll generate a random identifier, shared by your devices.
  /// 
  /// You can read all our terms %@.
  public static func analyticsOptInContent(_ p1: Any, _ p2: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "analytics_opt_in_content", String(describing: p1), String(describing: p2))
  }
  /// here
  public static var analyticsOptInContentLink: String { return UntranslatedL10n.tr("Untranslated", "analytics_opt_in_content_link") }
  /// We <b>don't</b> record or profile any account data
  public static var analyticsOptInListItem1: String { return UntranslatedL10n.tr("Untranslated", "analytics_opt_in_list_item_1") }
  /// We <b>don't</b> share information with third parties
  public static var analyticsOptInListItem2: String { return UntranslatedL10n.tr("Untranslated", "analytics_opt_in_list_item_2") }
  /// You can turn this off anytime in settings
  public static var analyticsOptInListItem3: String { return UntranslatedL10n.tr("Untranslated", "analytics_opt_in_list_item_3") }
  /// Help improve %@
  public static func analyticsOptInTitle(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "analytics_opt_in_title", String(describing: p1))
  }
  /// Camera
  public static var mediaUploadCameraPicker: String { return UntranslatedL10n.tr("Untranslated", "media_upload_camera_picker") }
  /// Document
  public static var mediaUploadDocumentPicker: String { return UntranslatedL10n.tr("Untranslated", "media_upload_document_picker") }
  /// Photo & Video Library
  public static var mediaUploadPhotoAndVideoPicker: String { return UntranslatedL10n.tr("Untranslated", "media_upload_photo_and_video_picker") }
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
  /// Forgot password
  public static var softLogoutForgotPassword: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_forgot_password") }
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
    guard let bundle = Bundle(for: BundleToken.self).lprojBundle(for: "en") else {
      // no translations for the desired language
      return key
    }
    let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    return String(format: format, locale: Locale(identifier: "en"), arguments: args)
  }
}

private final class BundleToken {}

