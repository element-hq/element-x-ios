//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import MatrixRustSDKMocks
import Testing

@MainActor
struct MessageForwardingScreenViewModelTests {
    let forwardingItem = MessageForwardingItem(ids: [.event(uniqueID: .init("t1"), eventOrTransactionID: .eventID("t1")),
                                                     .event(uniqueID: .init("t2"), eventOrTransactionID: .eventID("t2"))],
                                               roomID: "1",
                                               contents: [RoomMessageEventContentWithoutRelationSDKMock(),
                                                          RoomMessageEventContentWithoutRelationSDKMock()])
    var viewModel: MessageForwardingScreenViewModelProtocol!
    var context: MessageForwardingScreenViewModelType.Context!
    
    init() {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.roomForIdentifierClosure = { .joined(JoinedRoomProxyMock(.init(id: $0))) }
        
        viewModel = MessageForwardingScreenViewModel(forwardingItem: forwardingItem,
                                                     userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                     roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                     userIndicatorController: UserIndicatorControllerMock())
        context = viewModel.context
    }
    
    @Test
    func initialState() {
        #expect(!context.viewState.rooms.contains { $0.id == forwardingItem.roomID }, "The source room ID shouldn't be shown")
    }
    
    @Test
    mutating func roomSelection() {
        context.send(viewAction: .selectRoom(roomID: "2"))
        #expect(context.viewState.selectedRoomIDs == ["2"])
    }
    
    @Test
    mutating func searching() async throws {
        let deferred = deferFulfillment(context.$viewState) { state in
            state.rooms.count == 1
        }
        
        context.searchQuery = "Second"
        
        try await deferred.fulfill()
    }
    
    @Test
    mutating func forwarding() async throws {
        context.send(viewAction: .selectRoom(roomID: "2"))
        #expect(context.viewState.selectedRoomIDs == ["2"])
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .sent(let roomIDs):
                return roomIDs == ["2"]
            default:
                return false
            }
        }
        
        context.send(viewAction: .send)
        
        try await deferred.fulfill()
    }
    
    @Test
    mutating func forwardingSendsEveryMessageToEveryRoomInOrder() async throws {
        let clientProxy = ClientProxyMock(.init())
        var roomProxies = [String: JoinedRoomProxyMock]()
        clientProxy.roomForIdentifierClosure = { roomID in
            let roomProxy = JoinedRoomProxyMock(.init(id: roomID))
            roomProxies[roomID] = roomProxy
            return .joined(roomProxy)
        }
        viewModel = MessageForwardingScreenViewModel(forwardingItem: forwardingItem,
                                                     userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                     roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                     userIndicatorController: UserIndicatorControllerMock())
        context = viewModel.context
        
        context.send(viewAction: .selectRoom(roomID: "2"))
        context.send(viewAction: .selectRoom(roomID: "3"))
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            if case .sent(let roomIDs) = action {
                return Set(roomIDs) == ["2", "3"]
            }
            return false
        }
        context.send(viewAction: .send)
        try await deferred.fulfill()
        
        let expectedContents = forwardingItem.contents.map { ObjectIdentifier($0) }
        for roomID in ["2", "3"] {
            let timeline = try #require(roomProxies[roomID]?.timeline as? TimelineProxyMock)
            let sentContents = timeline.sendMessageEventContentReceivedInvocations.map { ObjectIdentifier($0) }
            #expect(sentContents == expectedContents)
        }
    }
    
    @Test
    mutating func forwardingToSeveralRoomsShowsAToast() async throws {
        let userIndicatorController = UserIndicatorControllerMock()
        viewModel = makeViewModel(userIndicatorController: userIndicatorController)
        context = viewModel.context
        
        context.send(viewAction: .selectRoom(roomID: "2"))
        context.send(viewAction: .selectRoom(roomID: "3"))
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            if case .sent = action {
                return true
            }
            return false
        }
        context.send(viewAction: .send)
        try await deferred.fulfill()
        
        let titles = userIndicatorController.submitIndicatorDelayReceivedInvocations.map(\.indicator.title)
        #expect(titles == [UntranslatedL10n.screenRoomMessagesForwarded])
    }
    
    @Test
    mutating func forwardingToOneRoomDoesNotShowAToast() async throws {
        let userIndicatorController = UserIndicatorControllerMock()
        viewModel = makeViewModel(userIndicatorController: userIndicatorController)
        context = viewModel.context
        
        context.send(viewAction: .selectRoom(roomID: "2"))
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            if case .sent = action {
                return true
            }
            return false
        }
        context.send(viewAction: .send)
        try await deferred.fulfill()
        
        // The flow opens the room instead.
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 0)
    }
    
    @Test
    mutating func forwardingReportsRoomsThatCouldNotBeReached() async throws {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.roomForIdentifierClosure = { roomID in
            roomID == "3" ? nil : .joined(JoinedRoomProxyMock(.init(id: roomID)))
        }
        let userIndicatorController = UserIndicatorControllerMock()
        viewModel = MessageForwardingScreenViewModel(forwardingItem: forwardingItem,
                                                     userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                     roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                     userIndicatorController: userIndicatorController)
        context = viewModel.context
        
        context.send(viewAction: .selectRoom(roomID: "2"))
        context.send(viewAction: .selectRoom(roomID: "3"))
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            if case .sent(let roomIDs) = action {
                return roomIDs == ["2"]
            }
            return false
        }
        context.send(viewAction: .send)
        try await deferred.fulfill()
        
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 1)
    }
    
    // MARK: - Helpers
    
    private func makeViewModel(userIndicatorController: UserIndicatorControllerProtocol) -> MessageForwardingScreenViewModelProtocol {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.roomForIdentifierClosure = { .joined(JoinedRoomProxyMock(.init(id: $0))) }
        
        return MessageForwardingScreenViewModel(forwardingItem: forwardingItem,
                                                userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                userIndicatorController: userIndicatorController)
    }
}
