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
    internal static let grabber = ColorAsset(name: "colors/grabber")
  }
  internal enum Images {
    internal static let appLogo = ImageAsset(name: "images/app-logo")
    internal static let serverSelectionIcon = ImageAsset(name: "images/server-selection-icon")
    internal static let closeCircle = ImageAsset(name: "images/close-circle")
    internal static let addLocation = ImageAsset(name: "images/add-location")
    internal static let attachment = ImageAsset(name: "images/attachment")
    internal static let photosLibrary = ImageAsset(name: "images/photos-library")
    internal static let takePhoto = ImageAsset(name: "images/take-photo")
    internal static let textFormatting = ImageAsset(name: "images/text-formatting")
    internal static let bold = ImageAsset(name: "images/bold")
    internal static let bulletList = ImageAsset(name: "images/bullet-list")
    internal static let closeRte = ImageAsset(name: "images/close-rte")
    internal static let codeBlock = ImageAsset(name: "images/code-block")
    internal static let composerAttachment = ImageAsset(name: "images/composer-attachment")
    internal static let editing = ImageAsset(name: "images/editing")
    internal static let indent = ImageAsset(name: "images/indent")
    internal static let inlineCode = ImageAsset(name: "images/inline-code")
    internal static let italic = ImageAsset(name: "images/italic")
    internal static let link = ImageAsset(name: "images/link")
    internal static let numberedList = ImageAsset(name: "images/numbered-list")
    internal static let quote = ImageAsset(name: "images/quote")
    internal static let sendMessage = ImageAsset(name: "images/send-message")
    internal static let strikethrough = ImageAsset(name: "images/strikethrough")
    internal static let textFormat = ImageAsset(name: "images/text-format")
    internal static let underline = ImageAsset(name: "images/underline")
    internal static let unindent = ImageAsset(name: "images/unindent")
    internal static let decryptionError = ImageAsset(name: "images/decryption-error")
    internal static let endedPoll = ImageAsset(name: "images/ended-poll")
    internal static let compose = ImageAsset(name: "images/compose")
    internal static let launchBackground = ImageAsset(name: "images/launch-background")
    internal static let locationMarker = ImageAsset(name: "images/location-marker")
    internal static let locationPin = ImageAsset(name: "images/location-pin")
    internal static let locationPointerFull = ImageAsset(name: "images/location-pointer-full")
    internal static let locationPointer = ImageAsset(name: "images/location-pointer")
    internal static let addReaction = ImageAsset(name: "images/add-reaction")
    internal static let copy = ImageAsset(name: "images/copy")
    internal static let editOutline = ImageAsset(name: "images/edit-outline")
    internal static let forward = ImageAsset(name: "images/forward")
    internal static let reply = ImageAsset(name: "images/reply")
    internal static let viewSource = ImageAsset(name: "images/view-source")
    internal static let timelineEndedPoll = ImageAsset(name: "images/timeline-ended-poll")
    internal static let timelinePollAttachment = ImageAsset(name: "images/timeline-poll-attachment")
    internal static let timelinePoll = ImageAsset(name: "images/timeline-poll")
    internal static let waitingGradient = ImageAsset(name: "images/waiting-gradient")
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
