//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import PushKit
import XCTest

@testable import ElementX

@MainActor
class ElementCallServiceTests: XCTestCase {
    var callProvider: CXProviderMock!
    let pushRegistry = PKPushRegistry(queue: nil)
    
    var service: ElementCallService!
    
    func testIncomingCall() async {
        setupService()
        XCTAssertFalse(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let expectation = XCTestExpectation(description: "Call accepted")
        
        service.pushRegistry(pushRegistry, didReceiveIncomingPushWith: PKPushPayloadMock(), for: .voIP) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertTrue(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
    }
    
    // MARK: - Helpers
    
    private func setupService() {
        callProvider = CXProviderMock(.init())
        service = ElementCallService(callProvider: callProvider)
    }
}

private class PKPushPayloadMock: PKPushPayload {
    override var dictionaryPayload: [AnyHashable: Any] {
        [
            ElementCallServiceNotificationKey.roomID.rawValue: "1",
            ElementCallServiceNotificationKey.roomDisplayName.rawValue: "Test",
            ElementCallServiceNotificationKey.rtcNotifyEventID.rawValue: "a",
            ElementCallServiceNotificationKey.expirationTimestampMillis.rawValue: UInt64((Date().timeIntervalSince1970 + 5) * 1000)
        ]
    }
}
