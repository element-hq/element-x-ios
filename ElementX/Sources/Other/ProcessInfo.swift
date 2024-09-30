//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension ProcessInfo {
    /// Flag indicating whether the app is running the unit tests.
    static var isRunningUnitTests: Bool {
        #if DEBUG
        processInfo.environment["IS_RUNNING_UNIT_TESTS"] == "1"
        #else
        false
        #endif
    }

    /// Flag indicating whether the app is running the UI tests.
    static var isRunningUITests: Bool {
        #if DEBUG
        processInfo.environment["UI_TESTS_SCREEN"] != nil
        #else
        false
        #endif
    }
    
    static var isRunningIntegrationTests: Bool {
        #if DEBUG
        processInfo.environment["IS_RUNNING_INTEGRATION_TESTS"] == "1"
        #else
        false
        #endif
    }

    /// Flag indicating whether the app is running the UI tests or unit tests.
    static var isRunningTests: Bool {
        isRunningUITests || isRunningUnitTests || isRunningIntegrationTests
    }
    
    /// The identifier of the screen to be loaded when running UI tests.
    static var testScreenID: UITestsScreenIdentifier? {
        #if DEBUG
        processInfo.environment["UI_TESTS_SCREEN"].flatMap(UITestsScreenIdentifier.init)
        #else
        nil
        #endif
    }
    
    static var shouldDisableTimelineAccessibility: Bool {
        guard isRunningUITests else {
            return false
        }
        
        #if DEBUG
        return processInfo.environment["UI_TESTS_DISABLE_TIMELINE_ACCESSIBILITY"] != nil
        #else
        return false
        #endif
    }
    
    static var isXcodePreview: Bool {
        #if DEBUG
        processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        false
        #endif
    }
}
