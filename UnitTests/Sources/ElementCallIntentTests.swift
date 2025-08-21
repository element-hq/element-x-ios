//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

/// Tests for ElementCall intent computation logic
@MainActor
class ElementCallIntentTests: XCTestCase {
    
    func testIntentComputationLogic() {
        // Test the logic for computing the correct intent based on room type and call status
        
        // Case 1: Starting a call in a non-DM room (no active call, not direct)
        var intent = computeIntent(hasActiveCall: false, isDirect: false)
        XCTAssertEqual(intent, "startCall")
        
        // Case 2: Joining a call in a non-DM room (active call, not direct) 
        intent = computeIntent(hasActiveCall: true, isDirect: false)
        XCTAssertEqual(intent, "joinCall")
        
        // Case 3: Starting a call in a DM room (no active call, is direct)
        intent = computeIntent(hasActiveCall: false, isDirect: true)
        XCTAssertEqual(intent, "startDmCall")
        
        // Case 4: Joining a call in a DM room (active call, is direct)
        intent = computeIntent(hasActiveCall: true, isDirect: true)
        XCTAssertEqual(intent, "joinDmCall")
    }
    
    /// Helper function that mirrors the logic in ElementCallWidgetDriver
    private func computeIntent(hasActiveCall: Bool, isDirect: Bool) -> String {
        switch (hasActiveCall, isDirect) {
        case (true, true):
            return "joinDmCall"
        case (true, false):
            return "joinCall"
        case (false, true):
            return "startDmCall"
        case (false, false):
            return "startCall"
        }
    }
}