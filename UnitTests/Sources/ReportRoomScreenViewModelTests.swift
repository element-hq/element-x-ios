//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
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
        let testSetup = self
        #expect(testSetup.context.viewState.bindings.reason.isEmpty)
        #expect(!testSetup.context.viewState.bindings.shouldLeaveRoom)
    }
    
    @Test
    func reportSuccess() async {
        var testSetup = self
        let reason = "Spam"
        
        await confirmation { confirmation in
            testSetup.roomProxy.reportRoomReasonClosure = { reasonArgument in
                #expect(reasonArgument == reason)
                confirmation()
                return .success(())
            }
            
            let deferred = deferFulfillment(testSetup.viewModel.actionsPublisher) { action in
                action == .dismiss(shouldLeaveRoom: false)
            }
            
            testSetup.context.reason = reason
            testSetup.context.send(viewAction: .report)
            
            try? await deferred.fulfill()
        }
    }
    
    @Test
    func reportAndLeaveSuccess() async {
        var testSetup = self
        let reason = "Spam"
        
        await confirmation(expectedCount: 2) { confirmation in
            testSetup.roomProxy.reportRoomReasonClosure = { reasonArgument in
                #expect(reasonArgument == reason)
                confirmation()
                return .success(())
            }
            
            testSetup.roomProxy.leaveRoomClosure = {
                confirmation()
                return .success(())
            }
            
            let deferred = deferFulfillment(testSetup.viewModel.actionsPublisher) { action in
                action == .dismiss(shouldLeaveRoom: true)
            }
            
            testSetup.context.reason = reason
            testSetup.context.shouldLeaveRoom = true
            testSetup.context.send(viewAction: .report)
            
            try? await deferred.fulfill()
        }
    }
    
    @Test
    func reportSuccessLeaveFails() async {
        var testSetup = self
        let reason = "Spam"
        
        await confirmation(expectedCount: 2) { confirmation in
            testSetup.roomProxy.reportRoomReasonClosure = { reasonArgument in
                #expect(reasonArgument == reason)
                confirmation()
                return .success(())
            }
            
            testSetup.roomProxy.leaveRoomClosure = {
                confirmation()
                return .failure(.eventNotFound)
            }
            
            let deferred = deferFulfillment(testSetup.context.observe(\.viewState.bindings.alert)) { $0 != nil }
            
            testSetup.context.reason = reason
            testSetup.context.shouldLeaveRoom = true
            testSetup.context.send(viewAction: .report)
            
            try? await deferred.fulfill()
        }
    }
}
