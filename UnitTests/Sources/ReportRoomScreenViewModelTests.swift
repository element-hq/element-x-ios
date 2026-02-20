//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
@MainActor
struct ReportRoomScreenViewModelTests {
    private var viewModel: ReportRoomScreenViewModelProtocol
    private var roomProxy: JoinedRoomProxyMock
    
    private var context: ReportRoomScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        roomProxy = JoinedRoomProxyMock(.init())
        viewModel = ReportRoomScreenViewModel(roomProxy: roomProxy, userIndicatorController: UserIndicatorControllerMock())
    }
    
    @Test
    func initialState() {
        #expect(context.viewState.bindings.reason.isEmpty)
        #expect(!context.viewState.bindings.shouldLeaveRoom)
    }
    
    @Test
    func reportSuccess() async throws {
        let reason = "Spam"
        
        try await confirmation { confirmation in
            roomProxy.reportRoomReasonClosure = { reasonArgument in
                #expect(reasonArgument == reason)
                confirmation()
                return .success(())
            }
            
            let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
                action == .dismiss(shouldLeaveRoom: false)
            }
            
            context.reason = reason
            context.send(viewAction: .report)
            
            try await deferred.fulfill()
        }
    }
    
    @Test
    func reportAndLeaveSuccess() async throws {
        let reason = "Spam"
        
        try await confirmation(expectedCount: 2) { confirmation in
            roomProxy.reportRoomReasonClosure = { reasonArgument in
                #expect(reasonArgument == reason)
                confirmation()
                return .success(())
            }
            
            roomProxy.leaveRoomClosure = {
                confirmation()
                return .success(())
            }
            
            let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
                action == .dismiss(shouldLeaveRoom: true)
            }
            
            context.reason = reason
            context.shouldLeaveRoom = true
            context.send(viewAction: .report)
            
            try await deferred.fulfill()
        }
        
        #expect(roomProxy.reportRoomReasonCalled)
        #expect(roomProxy.leaveRoomCalled)
    }
    
    @Test
    func reportSuccessLeaveFails() async throws {
        let reason = "Spam"
        
        try await confirmation(expectedCount: 2) { confirmation in
            roomProxy.reportRoomReasonClosure = { reasonArgument in
                #expect(reasonArgument == reason)
                confirmation()
                return .success(())
            }
            
            roomProxy.leaveRoomClosure = {
                confirmation()
                return .failure(.eventNotFound)
            }
            
            let deferred = deferFulfillment(context.observe(\.viewState.bindings.alert)) { $0 != nil }
            
            context.reason = reason
            context.shouldLeaveRoom = true
            context.send(viewAction: .report)
            
            try await deferred.fulfill()
        }
        
        #expect(roomProxy.reportRoomReasonCalled)
        #expect(roomProxy.leaveRoomCalled)
    }
}
