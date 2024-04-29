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
class JoinRoomScreenViewModelTests: XCTestCase {
    var viewModel: JoinRoomScreenViewModelProtocol!
    
    var context: JoinRoomScreenViewModelType.Context {
        viewModel.context
    }

    func testInteraction() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .joined }
        context.send(viewAction: .join)
        try await deferred.fulfill()
    }
    
    func testAcceptInviteInteraction() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .joined }
        context.send(viewAction: .acceptInvite)
        try await deferred.fulfill()
    }
    
    func testDeclineInviteInteraction() async throws {
        setupViewModel()
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.roomDetails != nil }.fulfill()
        
        context.send(viewAction: .declineInvite)
        
        XCTAssertEqual(viewModel.context.alertInfo?.id, .declineInvite)
    }
    
    private func setupViewModel(throwing: Bool = false) {
        let clientProxy = ClientProxyMock(.init())
        
        clientProxy.joinRoomReturnValue = throwing ? .failure(.sdkError(ClientProxyMockError.generic)) : .success(())
        
        clientProxy.roomPreviewForIdentifierReturnValue = .success(.init(roomID: "",
                                                                         name: nil,
                                                                         canonicalAlias: nil,
                                                                         topic: nil,
                                                                         avatarURL: nil,
                                                                         memberCount: 0,
                                                                         isHistoryWorldReadable: false,
                                                                         isJoined: false,
                                                                         isInvited: false,
                                                                         isPublic: false,
                                                                         canKnock: false))
        
        viewModel = JoinRoomScreenViewModel(roomID: "1",
                                            clientProxy: clientProxy,
                                            mediaProvider: MockMediaProvider(),
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
