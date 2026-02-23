//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite
@MainActor
struct RoomPollsHistoryScreenViewModelTests {
    var viewModel: RoomPollsHistoryScreenViewModelProtocol!
    var interactionHandler: PollInteractionHandlerMock!
    var timelineController: MockTimelineController!
    
    init() throws {
        interactionHandler = PollInteractionHandlerMock()
        timelineController = MockTimelineController()
        viewModel = RoomPollsHistoryScreenViewModel(pollInteractionHandler: interactionHandler,
                                                    timelineController: timelineController,
                                                    userIndicatorController: UserIndicatorControllerMock())
    }

    @Test
    func backPaginate() async throws {
        timelineController.backPaginationResponses = [
            [PollRoomTimelineItem.mock(poll: .emptyDisclosed, isEditable: true),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: true)),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: false)),
             PollRoomTimelineItem.mock(poll: .endedDisclosed)]
        ]
                
        let deferredViewState = deferFulfillment(viewModel.context.$viewState, keyPath: \.isBackPaginating, transitionValues: [false, true, false])
        
        viewModel.context.send(viewAction: .loadMore)
        
        try await deferredViewState.fulfill()
        
        #expect(viewModel.context.viewState.pollTimelineItems.count == 3)
        #expect(!viewModel.context.viewState.canBackPaginate)
    }
    
    @Test
    func backPaginateCanBackPaginate() async throws {
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
        
        #expect(viewModel.context.viewState.pollTimelineItems.count == 3)
        #expect(viewModel.context.viewState.canBackPaginate)
    }
    
    @Test
    func backPaginateTwice() async throws {
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
        
        #expect(viewModel.context.viewState.pollTimelineItems.count == 3)
        #expect(viewModel.context.viewState.canBackPaginate)
    }
    
    @Test
    func filters() async throws {
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
        
        #expect(viewModel.context.viewState.pollTimelineItems.count == 3)
        
        viewModel.context.send(viewAction: .filter(.past))
        #expect(viewModel.context.viewState.pollTimelineItems.count == 1)
    }
    
    @Test
    func endPoll() async throws {
        let deferred = deferFulfillment(interactionHandler.publisher.delay(for: 0.1, scheduler: DispatchQueue.main)) { _ in true }
            
        interactionHandler.endPollPollStartIDReturnValue = .success(())
        viewModel.context.send(viewAction: .end(pollStartID: "somePollID"))

        try await deferred.fulfill()
        
        #expect(interactionHandler.endPollPollStartIDCalled)
        #expect(interactionHandler.endPollPollStartIDReceivedPollStartID == "somePollID")
    }

    @Test
    func endPollFailure() async throws {
        let deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.bindings.alertInfo != nil
        }
            
        interactionHandler.endPollPollStartIDReturnValue = .failure(SDKError.generic)
        viewModel.context.send(viewAction: .end(pollStartID: "somePollID"))

        try await deferred.fulfill()
        
        #expect(interactionHandler.endPollPollStartIDCalled)
        #expect(interactionHandler.endPollPollStartIDReceivedPollStartID == "somePollID")
    }
    
    @Test
    func sendPollResponse() async throws {
        let deferred = deferFulfillment(interactionHandler.publisher.delay(for: 0.1, scheduler: DispatchQueue.main)) { _ in true }
            
        interactionHandler.sendPollResponsePollStartIDOptionIDReturnValue = .success(())
        viewModel.context.send(viewAction: .sendPollResponse(pollStartID: "somePollID", optionID: "someOptionID"))

        try await deferred.fulfill()
        
        #expect(interactionHandler.sendPollResponsePollStartIDOptionIDCalled)
        #expect(interactionHandler.sendPollResponsePollStartIDOptionIDReceivedInvocations[0].pollStartID == "somePollID")
        #expect(interactionHandler.sendPollResponsePollStartIDOptionIDReceivedInvocations[0].optionID == "someOptionID")
    }

    @Test
    func sendPollResponseFailure() async throws {
        let deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.bindings.alertInfo != nil
        }
            
        interactionHandler.sendPollResponsePollStartIDOptionIDReturnValue = .failure(SDKError.generic)
        viewModel.context.send(viewAction: .sendPollResponse(pollStartID: "somePollID", optionID: "someOptionID"))

        try await deferred.fulfill()
        
        #expect(interactionHandler.sendPollResponsePollStartIDOptionIDCalled)
        #expect(interactionHandler.sendPollResponsePollStartIDOptionIDReceivedInvocations[0].pollStartID == "somePollID")
        #expect(interactionHandler.sendPollResponsePollStartIDOptionIDReceivedInvocations[0].optionID == "someOptionID")
    }
    
    @Test
    func editPoll() async throws {
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
