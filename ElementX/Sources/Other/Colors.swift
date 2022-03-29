//
//  Colors.swift
//  ElementX
//
//  Created by Stefan Ceriu on 29/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

//TODO: Switch this to SwiftGen

extension Color {
    static let elementGreen = Color(ColorNames.elementGreen.rawValue)
    static let codeBlockBackgroundColor = Color(ColorNames.codeBlockBackgroundColor.rawValue)
}

extension UIColor {
    static let elementGreen = UIColor(named: ColorNames.elementGreen.rawValue)
    static let codeBlockBackgroundColor = UIColor(named: ColorNames.codeBlockBackgroundColor.rawValue)
}

private enum ColorNames: String {
    case elementGreen
    case codeBlockBackgroundColor
    
    var rawValue: String {
        switch self {
        case .elementGreen:
            return "ElementGreen"
        case .codeBlockBackgroundColor:
            return "CodeBlockBackgroundColor"
        }
    }
}
