import SwiftUI

public extension Font {
    static let zero = ZeroFonts()
}

public struct ZeroFonts {
    /// Font sizes reference from https://gist.github.com/zacwest/916d31da5d03405809c4

    public let bodyXS = Font.inter(size: 12) // caption
    public let bodyXSSemibold = Font.inter(size: 12, weight: .semibold)
    public let bodySM = Font.inter(size: 13) // footnote
    public let bodySMSemibold = Font.inter(size: 13, weight: .semibold)
    public let bodyMD = Font.inter(size: 15) // subHeadline
    public let bodyMDSemibold = Font.inter(size: 15, weight: .semibold)
    public let bodyLG = Font.inter(size: 17) // body
    public let bodyLGSemibold = Font.inter(size: 17, weight: .semibold)
    public let headingSM = Font.inter(size: 20) // title3
    public let headingSMSemibold = Font.inter(size: 20, weight: .semibold)
    public let headingMD = Font.inter(size: 22) // title2
    public let headingMDBold = Font.inter(size: 22, weight: .bold)
    public let headingLG = Font.inter(size: 28) // title1
    public let headingLGBold = Font.inter(size: 28, weight: .bold)
    public let headingXL = Font.inter(size: 34) // largeTitle
    public let headingXLBold = Font.inter(size: 34, weight: .bold)
}
