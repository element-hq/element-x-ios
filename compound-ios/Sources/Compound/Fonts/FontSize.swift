import SwiftUI

/// The size of a SwiftUI font.
enum FontSize {
    case custom(CGFloat, Font.TextStyle?)
    case style(Font.TextStyle)
    
    /// The raw value in points.
    var value: CGFloat {
        switch self {
        case .custom(let size, _):
            return size
        case .style(let style):
            switch style {
            case .largeTitle:
                return UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
            case .title:
                return UIFont.preferredFont(forTextStyle: .title1).pointSize
            case .title2:
                return UIFont.preferredFont(forTextStyle: .title2).pointSize
            case .title3:
                return UIFont.preferredFont(forTextStyle: .title3).pointSize
            case .body:
                return UIFont.preferredFont(forTextStyle: .body).pointSize
            case .headline:
                return UIFont.preferredFont(forTextStyle: .headline).pointSize
            case .callout:
                return UIFont.preferredFont(forTextStyle: .callout).pointSize
            case .subheadline:
                return UIFont.preferredFont(forTextStyle: .subheadline).pointSize
            case .footnote:
                return UIFont.preferredFont(forTextStyle: .footnote).pointSize
            case .caption:
                return UIFont.preferredFont(forTextStyle: .caption1).pointSize
            case .caption2:
                return UIFont.preferredFont(forTextStyle: .caption2).pointSize
            @unknown default:
                return UIFont.preferredFont(forTextStyle: .body).pointSize
            }
        }
    }
    
    /// The text style of the font.
    var style: Font.TextStyle {
        switch self {
        case .custom(_, let textStyle):
            return textStyle ?? .body
        case .style(let textStyle):
            return textStyle
        }
    }
    
    static func reflecting(_ font: Font) -> FontSize? {
        let mirror = Mirror(reflecting: font)
        guard let provider = mirror.descendant("provider", "base") else { return nil }
        return resolveFontSize(provider)
    }
    
    private static func resolveFontSize(_ provider: Any) -> FontSize? {
        let mirror = Mirror(reflecting: provider)
        
        if let size = mirror.descendant("size") as? CGFloat {
            return .custom(size, mirror.descendant("textStyle") as? Font.TextStyle)
        } else if let textStyle = mirror.descendant("style") as? Font.TextStyle {
            return .style(textStyle)
        }
        
        // recurse to handle modifiers.
        guard let provider = mirror.descendant("base", "provider", "base") else { return nil }
        return resolveFontSize(provider)
    }
}
