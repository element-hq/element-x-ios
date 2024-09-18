// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Colors {
    internal static let accentColor = ColorAsset(name: "colors/accent-color")
    internal static let backgroundColor = ColorAsset(name: "colors/background-color")
    internal static let blue11 = ColorAsset(name: "colors/blue-11")
    internal static let brandColor = ColorAsset(name: "colors/brand-color")
    internal static let grabber = ColorAsset(name: "colors/grabber")
    internal static let greyScale150 = ColorAsset(name: "colors/grey-scale-150")
    internal static let textPrimary = ColorAsset(name: "colors/text-primary")
    internal static let textSecondary = ColorAsset(name: "colors/text-secondary")
    internal static let textWarning = ColorAsset(name: "colors/text-warning")
    internal static let zeroDarkGrey = ColorAsset(name: "colors/zero-dark-grey")
  }
  internal enum Images {
    internal static let appLogo = ImageAsset(name: "images/app-logo")
    internal static let serverSelectionIcon = ImageAsset(name: "images/server-selection-icon")
    internal static let backgroundBottom = ImageAsset(name: "images/background-bottom")
    internal static let closeRte = ImageAsset(name: "images/close-rte")
    internal static let composerAttachment = ImageAsset(name: "images/composer-attachment")
    internal static let stopRecording = ImageAsset(name: "images/stop-recording")
    internal static let settingsIconWithBadge = ImageAsset(name: "images/settings-icon-with-badge")
    internal static let joinRoomBackground = ImageAsset(name: "images/join-room-background")
    internal static let launchBackground = ImageAsset(name: "images/launch-background")
    internal static let locationMarkerShape = ImageAsset(name: "images/location-marker-shape")
    internal static let mediaPause = ImageAsset(name: "images/media-pause")
    internal static let mediaPlay = ImageAsset(name: "images/media-play")
    internal static let notificationsPromptGraphic = ImageAsset(name: "images/notifications-prompt-graphic")
    internal static let pollWinner = ImageAsset(name: "images/poll-winner")
    internal static let waitingGradient = ImageAsset(name: "images/waiting-gradient")
    internal static let alertCircleIcon = ImageAsset(name: "images/alert-circle-icon")
    internal static let alertFillCircleIcon = ImageAsset(name: "images/alert-fill-circle-icon")
    internal static let backgroundLevel1 = ImageAsset(name: "images/background-level-1")
    internal static let backgroundLevel2 = ImageAsset(name: "images/background-level-2")
    internal static let backgroundLevel3 = ImageAsset(name: "images/background-level-3")
    internal static let checkIcon = ImageAsset(name: "images/check-icon")
    internal static let conversationsListHeader = ImageAsset(name: "images/conversations-list-header")
    internal static let crossIcon = ImageAsset(name: "images/cross-icon")
    internal static let defaultAuthTextfield = ImageAsset(name: "images/default-auth-textfield")
    internal static let defaultAvatarIcon = ImageAsset(name: "images/default-avatar-icon")
    internal static let defaultLoginButton = ImageAsset(name: "images/default-login-button")
    internal static let defaultWalletConnectButton = ImageAsset(name: "images/default-wallet-connect-button")
    internal static let landingBackground = ImageAsset(name: "images/landing-background")
    internal static let zeroBackupHeader = ImageAsset(name: "images/zero-backup-header")
    internal static let zeroLogoMark = ImageAsset(name: "images/zero-logo-mark")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  internal func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal private(set) lazy var swiftUIColor: SwiftUI.Color = {
    SwiftUI.Color(asset: self)
  }()
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Color {
  init(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }
}
#endif

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

internal extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Image {
  init(asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: ImageAsset, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
