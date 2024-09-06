//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class CreateRoomScreenViewModelTests: XCTestCase {
    var viewModel: CreateRoomViewModelProtocol!
    var clientProxy: ClientProxyMock!
    var userSession: UserSessionMock!
    
    private let usersSubject = CurrentValueSubject<[UserProfileProxy], Never>([])
    private var cancellables = Set<AnyCancellable>()
    
    var context: CreateRoomViewModel.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        cancellables.removeAll()
        clientProxy = ClientProxyMock(.init(userID: "@a:b.com"))
        userSession = UserSessionMock(.init(clientProxy: clientProxy))
        let parameters = CreateRoomFlowParameters()
        usersSubject.send([.mockAlice, .mockBob, .mockCharlie])
        let viewModel = CreateRoomViewModel(userSession: userSession,
                                            createRoomParameters: .init(parameters),
                                            selectedUsers: usersSubject.asCurrentValuePublisher(),
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: UserIndicatorControllerMock())
        self.viewModel = viewModel
        
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .deselectUser(let user):
                var selectedUsers = usersSubject.value
                if let index = selectedUsers.firstIndex(where: { $0.userID == user.userID }) {
                    selectedUsers.remove(at: index)
                }
                usersSubject.send(selectedUsers)
            default:
                break
            }
        }
        .store(in: &cancellables)
    }
    
    func testDeselectUser() {
        XCTAssertFalse(context.viewState.selectedUsers.isEmpty)
        XCTAssertEqual(context.viewState.selectedUsers.count, 3)
        XCTAssertEqual(context.viewState.selectedUsers.first?.userID, UserProfileProxy.mockAlice.userID)
        context.send(viewAction: .deselectUser(.mockAlice))
        XCTAssertNotEqual(context.viewState.selectedUsers.first?.userID, UserProfileProxy.mockAlice.userID)
    }
    
    func testDefaulSecurity() {
        XCTAssertTrue(context.viewState.bindings.isRoomPrivate)
    }
    
    func testCreateRoomRequirements() {
        XCTAssertFalse(context.viewState.canCreateRoom)
        context.roomName = "A"
        XCTAssertTrue(context.viewState.canCreateRoom)
    }
}
