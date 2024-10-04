import SwiftUI

public extension Font {
    static func inter(size: CGFloat, weight: Weight = .regular) -> Font {
        switch weight {
        case .ultraLight:
            return .custom("Inter-ExtraLight", size: size)
        case .light, .thin:
            return .custom("Inter-Light", size: size)
        case .regular:
            return .custom("Inter-Regular", size: size)
        case .medium:
            return .custom("Inter-Medium", size: size)
        case .semibold:
            return .custom("Inter-SemiBold", size: size)
        case .bold:
            return .custom("Inter-Bold", size: size)
        case .heavy:
            return .custom("Inter-ExtraBold", size: size)
        case .black:
            return .custom("Inter-Black", size: size)
        default:
            return .custom("Inter-Regular", size: size)
        }
    }
    
    static func robotoMonoRegular(size: CGFloat) -> Font {
        .custom("RobotoMono", size: size)
    }
}
