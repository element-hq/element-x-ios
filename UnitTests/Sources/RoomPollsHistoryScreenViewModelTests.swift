//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class RoomPollsHistoryScreenViewModelTests: XCTestCase {
    var viewModel: RoomPollsHistoryScreenViewModelProtocol!
    var interactionHandler: PollInteractionHandlerMock!
    var timelineController: MockRoomTimelineController!
    
    override func setUpWithError() throws {
        interactionHandler = PollInteractionHandlerMock()
        timelineController = MockRoomTimelineController()
        viewModel = RoomPollsHistoryScreenViewModel(pollInteractionHandler: interactionHandler,
                                                    roomTimelineController: timelineController,
                                                    userIndicatorController: UserIndicatorControllerMock())
    }

    func testBackPaginate() async throws {
        timelineController.backPaginationResponses = [
            [PollRoomTimelineItem.mock(poll: .emptyDisclosed, isEditable: true),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: true)),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: false)),
             PollRoomTimelineItem.mock(poll: .endedDisclosed)]
        ]
                
        let deferredViewState = deferFulfillment(viewModel.context.$viewState, keyPath: \.isBackPaginating, transitionValues: [false, true, false])
        
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
                
        let deferredViewState = deferFulfillment(viewModel.context.$viewState, keyPath: \.isBackPaginating, transitionValues: [false, true, false])
        
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
        let deferredViewState = deferFulfillment(viewModel.context.$viewState, keyPath: \.isBackPaginating, transitionValues: [false, true, false])
        
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
        let deferred = deferFulfillment(interactionHandler.publisher.delay(for: 0.1, scheduler: DispatchQueue.main)) { _ in true }
            
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
            
        interactionHandler.endPollPollStartIDReturnValue = .failure(SDKError.generic)
        viewModel.context.send(viewAction: .end(pollStartID: "somePollID"))

        try await deferred.fulfill()
        
        XCTAssert(interactionHandler.endPollPollStartIDCalled)
        XCTAssertEqual(interactionHandler.endPollPollStartIDReceivedPollStartID, "somePollID")
    }
    
    func testSendPollResponse() async throws {
        let deferred = deferFulfillment(interactionHandler.publisher.delay(for: 0.1, scheduler: DispatchQueue.main)) { _ in true }
            
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
            
        interactionHandler.sendPollResponsePollStartIDOptionIDReturnValue = .failure(SDKError.generic)
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

private enum SDKError: Error {
    case generic
}
