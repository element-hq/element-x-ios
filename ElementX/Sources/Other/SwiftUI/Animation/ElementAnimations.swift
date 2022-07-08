//
//  ElementAnimations.swift
//  ElementX
//
//  Created by Ismail on 8.07.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

extension Animation {
    /// Disabled if running UI tests, otherwise `Animation.default`
    static var elementDefault: Animation {
        ProcessInfo.processInfo.environment["IS_RUNNING_UI_TESTS"] == "1" ? .linear(duration: 0) : .default
    }
}
