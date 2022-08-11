//
//  Tests.swift
//  ElementX
//
//  Created by Ismail on 29.07.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

public enum Tests {
    /// Flag indicating whether the app is running the unit tests.
    static var isRunningUnitTests: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["IS_RUNNING_UNIT_TESTS"] == "1"
        #else
        false
        #endif
    }

    /// Flag indicating whether the app is running the UI tests.
    static var isRunningUITests: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["IS_RUNNING_UI_TESTS"] == "1"
        #else
        false
        #endif
    }
}
