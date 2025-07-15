//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

enum Application {
    static func launch(viewID: String) -> XCUIApplication {
        checkEnvironments()
        
        let app = XCUIApplication()
        
        let launchEnvironment = [
            "ACCESSIBILITY_VIEW": viewID
        ]
        
        app.launchEnvironment = launchEnvironment
        app.launch()
        return app
    }
    
    private static func checkEnvironments() {
        let requirediPhoneSimulator = "iPhone17,3" // iPhone 16
        let requiredOSVersion = 18
        
        let osVersion = ProcessInfo().operatingSystemVersion
        guard osVersion.majorVersion == requiredOSVersion else {
            fatalError("Switch to iOS \(requiredOSVersion) for these tests.")
        }
        
        guard let deviceModel = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] else {
            fatalError("Unknown simulator.")
        }
        guard deviceModel == requirediPhoneSimulator else {
            fatalError("Running on \(deviceModel) but we only support \(requirediPhoneSimulator)")
        }
    }
}
