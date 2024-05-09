//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
final class RoomTimelineControllerTests: XCTestCase {
    func testRetrySend() async throws {
        let timelineController = MockRoomTimelineController()
        let roomProxy = RoomProxyMock(with: .init(name: ""))
        
        let timelineProxy = TimelineProxyMock()
        timelineProxy.underlyingActions = Empty(completeImmediately: false).eraseToAnyPublisher()
        
        roomProxy.underlyingTimeline = timelineProxy
        timelineController.roomProxy = roomProxy

        await timelineController.retrySending(itemID: .init(timelineID: UUID().uuidString, transactionID: "test retry send id"))
        
        try? await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(timelineProxy.retrySendTransactionIDCallsCount == 1)
        XCTAssert(timelineProxy.retrySendTransactionIDReceivedInvocations == ["test retry send id"])
    }

    func testRetrySendNoTransactionID() async {
        let timelineController = MockRoomTimelineController()
        let roomProxy = RoomProxyMock(with: .init(name: ""))
        
        let timelineProxy = TimelineProxyMock()
        timelineProxy.underlyingActions = Empty(completeImmediately: false).eraseToAnyPublisher()
        
        roomProxy.underlyingTimeline = timelineProxy
        
        await timelineController.retrySending(itemID: .random)
        
        try? await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(timelineProxy.retrySendTransactionIDCallsCount == 0)
    }

    func testCancelSend() async {
        let timelineController = MockRoomTimelineController()
        let roomProxy = RoomProxyMock(with: .init(name: ""))
        
        let timelineProxy = TimelineProxyMock()
        timelineProxy.underlyingActions = Empty(completeImmediately: false).eraseToAnyPublisher()
        
        roomProxy.underlyingTimeline = timelineProxy
        timelineController.roomProxy = roomProxy
        
        await timelineController.cancelSending(itemID: .init(timelineID: UUID().uuidString, transactionID: "test cancel send id"))
        
        try? await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(timelineProxy.cancelSendTransactionIDCallsCount == 1)
        XCTAssert(timelineProxy.cancelSendTransactionIDReceivedInvocations == ["test cancel send id"])
    }

    func testCancelSendNoTransactionID() async {
        let timelineController = MockRoomTimelineController()
        let roomProxy = RoomProxyMock(with: .init(name: ""))
        
        let timelineProxy = TimelineProxyMock()
        timelineProxy.underlyingActions = Empty(completeImmediately: false).eraseToAnyPublisher()
        
        roomProxy.underlyingTimeline = timelineProxy
        
        await timelineController.cancelSending(itemID: .random)

        try? await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(timelineProxy.cancelSendTransactionIDCallsCount == 0)
    }
}
