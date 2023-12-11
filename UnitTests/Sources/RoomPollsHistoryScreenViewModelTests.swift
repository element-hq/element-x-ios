//
// Copyright 2022 New Vector Ltd
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

import XCTest

@testable import ElementX

@MainActor
class RoomPollsHistoryScreenViewModelTests: XCTestCase {
    var viewModel: RoomPollsHistoryScreenViewModelProtocol!
    var interactionHandler: PollInteractionHandlerMock!
    var timelineController: MockRoomPollsHistoryTimelineController!
    
    var context: RoomPollsHistoryScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        interactionHandler = PollInteractionHandlerMock()
        timelineController = MockRoomPollsHistoryTimelineController()
        viewModel = RoomPollsHistoryScreenViewModel(pollInteractionHandler: interactionHandler,
                                                    roomPollsHistoryTimelineController: timelineController,
                                                    userIndicatorController: UserIndicatorControllerMock())
    }

    func testBackPaginate() async throws {
        timelineController.backPaginationResponses = [
            [PollRoomTimelineItem.mock(poll: .emptyDisclosed, isEditable: true),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: true)),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: false)),
             PollRoomTimelineItem.mock(poll: .endedDisclosed)]
        ]
                
        let deferredViewState = deferFulfillment(viewModel.context.$viewState, keyPath: \.isBackPaginating, transitionValues: [true, true, false])
        
        viewModel.context.send(viewAction: .loadMore)
        
        try await deferredViewState.fulfill()
        
        XCTAssertEqual(viewModel.context.viewState.pollTimelineItems.count, 3)
        XCTAssertFalse(viewModel.context.viewState.canBackPaginate)
    }
    
    func testBackPaginateCanBackPaginate() async throws {
        timelineController.backPaginationResponses = [
            [PollRoomTimelineItem.mock(poll: .emptyDisclosed, isEditable: true),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: true)),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: false)),
             PollRoomTimelineItem.mock(poll: .endedDisclosed)],
            []
        ]
                
        let deferredViewState = deferFulfillment(viewModel.context.$viewState, keyPath: \.isBackPaginating, transitionValues: [true, true, false])
        
        viewModel.context.send(viewAction: .loadMore)
        
        try await deferredViewState.fulfill()
        
        XCTAssertEqual(viewModel.context.viewState.pollTimelineItems.count, 3)
        XCTAssert(viewModel.context.viewState.canBackPaginate)
    }
    
    func testBackPaginateTwice() async throws {
        timelineController.backPaginationResponses = [
            [PollRoomTimelineItem.mock(poll: .emptyDisclosed, isEditable: true),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: true)),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: false))],
            [PollRoomTimelineItem.mock(poll: .endedDisclosed)]
        ]
        timelineController.backPaginationDelay = .seconds(1)
        let deferredViewState = deferFulfillment(viewModel.context.$viewState, keyPath: \.isBackPaginating, transitionValues: [true, true, false])
        
        viewModel.context.send(viewAction: .loadMore)
        viewModel.context.send(viewAction: .loadMore)
        
        try await deferredViewState.fulfill()
        
        XCTAssertEqual(viewModel.context.viewState.pollTimelineItems.count, 3)
        XCTAssert(viewModel.context.viewState.canBackPaginate)
    }
    
    func testFilters() async throws {
        timelineController.backPaginationResponses = [
            [PollRoomTimelineItem.mock(poll: .emptyDisclosed, isEditable: true),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: true)),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: false)),
             PollRoomTimelineItem.mock(poll: .endedDisclosed)],
            []
        ]
                
        let deferredViewState = deferFulfillment(viewModel.context.$viewState) { value in
            !value.pollTimelineItems.isEmpty
        }
        
        viewModel.context.filter = .ongoing
        viewModel.context.send(viewAction: .loadMore)
        
        try await deferredViewState.fulfill()
        
        XCTAssertEqual(viewModel.context.viewState.pollTimelineItems.count, 3)
        
        viewModel.context.send(viewAction: .filter(.past))
        XCTAssertEqual(viewModel.context.viewState.pollTimelineItems.count, 1)
    }
    
    func testEndPoll() async throws {
        let deferred = deferFulfillment(interactionHandler.publisher) { _ in true }
            
        interactionHandler.endPollPollStartIDReturnValue = .success(())
        viewModel.context.send(viewAction: .end(pollStartID: "somePollID"))

        try await deferred.fulfill()
        
        XCTAssert(interactionHandler.endPollPollStartIDCalled)
        XCTAssertEqual(interactionHandler.endPollPollStartIDReceivedPollStartID, "somePollID")
    }

    func testEndPollFailure() async throws {
        let deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.bindings.alertInfo != nil
        }
            
        interactionHandler.endPollPollStartIDReturnValue = .failure(TimelineProxyError.failedEndingPoll)
        viewModel.context.send(viewAction: .end(pollStartID: "somePollID"))

        try await deferred.fulfill()
        
        XCTAssert(interactionHandler.endPollPollStartIDCalled)
        XCTAssertEqual(interactionHandler.endPollPollStartIDReceivedPollStartID, "somePollID")
    }
    
    func testSendPollResponse() async throws {
        let deferred = deferFulfillment(interactionHandler.publisher) { _ in true }
            
        interactionHandler.sendPollResponsePollStartIDOptionIDReturnValue = .success(())
        viewModel.context.send(viewAction: .sendPollResponse(pollStartID: "somePollID", optionID: "someOptionID"))

        try await deferred.fulfill()
        
        XCTAssert(interactionHandler.sendPollResponsePollStartIDOptionIDCalled)
        XCTAssertEqual(interactionHandler.sendPollResponsePollStartIDOptionIDReceivedInvocations[0].pollStartID, "somePollID")
        XCTAssertEqual(interactionHandler.sendPollResponsePollStartIDOptionIDReceivedInvocations[0].optionID, "someOptionID")
    }

    func testSendPollResponseFailure() async throws {
        let deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.bindings.alertInfo != nil
        }
            
        interactionHandler.sendPollResponsePollStartIDOptionIDReturnValue = .failure(TimelineProxyError.failedSendingPollResponse)
        viewModel.context.send(viewAction: .sendPollResponse(pollStartID: "somePollID", optionID: "someOptionID"))

        try await deferred.fulfill()
        
        XCTAssert(interactionHandler.sendPollResponsePollStartIDOptionIDCalled)
        XCTAssertEqual(interactionHandler.sendPollResponsePollStartIDOptionIDReceivedInvocations[0].pollStartID, "somePollID")
        XCTAssertEqual(interactionHandler.sendPollResponsePollStartIDOptionIDReceivedInvocations[0].optionID, "someOptionID")
    }
    
    func testEditPoll() async throws {
        let expectedPoll: Poll = .emptyDisclosed
        let expectedPollStartID = "someEventID"
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .editPoll(let pollStartID, let poll):
                expectedPollStartID == pollStartID && expectedPoll == poll
            }
        }
        
        viewModel.context.send(viewAction: .edit(pollStartID: expectedPollStartID, poll: expectedPoll))
        try await deferred.fulfill()
    }
}
