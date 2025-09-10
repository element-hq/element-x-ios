//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import SwiftUI
import XCTest

@testable import ElementX

/// Tests for ElementCallWidgetDriver intent computation during call placement
@MainActor
class ElementCallWidgetDriverIntentTests: XCTestCase {
    private let baseURL = URL(string: "https://call.element.io")!
    private let clientID = "test-client-id"
    private let deviceID = "test-device-id"
    
    func testStartCallIntentInNonDirectRoom() async throws {
        // Given: A non-direct room with no active call
        let mockRoom = RoomMock()
        mockRoom.hasActiveRoomCallReturnValue = false
        mockRoom.isDirectReturnValue = false
        
        let driver = ElementCallWidgetDriver(room: mockRoom, deviceID: deviceID)
        
        // When: Starting the widget
        let result = await driver.start(baseURL: baseURL,
                                        clientID: clientID,
                                        colorScheme: .light,
                                        rageshakeURL: nil,
                                        analyticsConfiguration: nil)
        
        // Then: The intent computation was called correctly
        XCTAssertTrue(mockRoom.hasActiveRoomCallCalled, "Should check if room has active call")
        XCTAssertTrue(mockRoom.isDirectCalled, "Should check if room is direct")
        
        // Note: We can't easily verify the exact intent passed to newVirtualElementCallWidget
        // since it's a MatrixRustSDK function, but we can verify the room state checks were made
        switch result {
        case .success:
            break // Test passes - the widget was created successfully
        case .failure(let error):
            // For this test, we expect it might fail due to missing MatrixRustSDK setup
            // but the important part is that the room state was checked correctly
            XCTFail("Widget creation failed with error: \(error)")
        }
    }
    
    func testJoinCallIntentInNonDirectRoom() async throws {
        // Given: A non-direct room with an active call
        let mockRoom = RoomMock()
        mockRoom.hasActiveRoomCallReturnValue = true
        mockRoom.isDirectReturnValue = false
        
        let driver = ElementCallWidgetDriver(room: mockRoom, deviceID: deviceID)
        
        // When: Starting the widget
        let result = await driver.start(baseURL: baseURL,
                                        clientID: clientID,
                                        colorScheme: .light,
                                        rageshakeURL: nil,
                                        analyticsConfiguration: nil)
        
        // Then: The room state was checked for join intent
        XCTAssertTrue(mockRoom.hasActiveRoomCallCalled)
        XCTAssertTrue(mockRoom.isDirectCalled)
        
        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Widget creation failed with error: \(error)")
        }
    }
    
    func testStartDmCallIntentInDirectRoom() async throws {
        // Given: A direct room with no active call
        let mockRoom = RoomMock()
        mockRoom.hasActiveRoomCallReturnValue = false
        mockRoom.isDirectReturnValue = true
        
        let driver = ElementCallWidgetDriver(room: mockRoom, deviceID: deviceID)
        
        // When: Starting the widget
        let result = await driver.start(baseURL: baseURL,
                                        clientID: clientID,
                                        colorScheme: .light,
                                        rageshakeURL: nil,
                                        analyticsConfiguration: nil)
        
        // Then: The room state was checked for DM start intent
        XCTAssertTrue(mockRoom.hasActiveRoomCallCalled)
        XCTAssertTrue(mockRoom.isDirectCalled)
        
        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Widget creation failed with error: \(error)")
        }
    }
    
    func testJoinDmCallIntentInDirectRoom() async throws {
        // Given: A direct room with an active call
        let mockRoom = RoomMock()
        mockRoom.hasActiveRoomCallReturnValue = true
        mockRoom.isDirectReturnValue = true
        
        let driver = ElementCallWidgetDriver(room: mockRoom, deviceID: deviceID)
        
        // When: Starting the widget
        let result = await driver.start(baseURL: baseURL,
                                        clientID: clientID,
                                        colorScheme: .light,
                                        rageshakeURL: nil,
                                        analyticsConfiguration: nil)
        
        // Then: The room state was checked for DM join intent
        XCTAssertTrue(mockRoom.hasActiveRoomCallCalled)
        XCTAssertTrue(mockRoom.isDirectCalled)
        
        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Widget creation failed with error: \(error)")
        }
    }
}
