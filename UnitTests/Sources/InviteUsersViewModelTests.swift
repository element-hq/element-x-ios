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
class InviteUsersScreenViewModelTests: XCTestCase {
    var viewModel: InviteUsersScreenViewModelProtocol!
    var userDiscoveryService: UserDiscoveryServiceMock!
    
    private var cancellables = Set<AnyCancellable>()
    
    var context: InviteUsersScreenViewModel.Context {
        viewModel.context
    }
    
    override func setUp() {
        cancellables.removeAll()
    }
    
    func testSelectUser() {
        setupWithRoomType(roomType: .draft)
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        XCTAssertTrue(context.viewState.selectedUsers.count == 1)
        XCTAssertEqual(context.viewState.selectedUsers.first?.userID, UserProfileProxy.mockAlice.userID)
    }
    
    func testReselectUser() {
        setupWithRoomType(roomType: .draft)
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        XCTAssertEqual(context.viewState.selectedUsers.count, 1)
        XCTAssertEqual(context.viewState.selectedUsers.first?.userID, UserProfileProxy.mockAlice.userID)
        context.send(viewAction: .toggleUser(.mockAlice))
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
    }
    
    func testDeselectUser() {
        setupWithRoomType(roomType: .draft)
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        XCTAssertEqual(context.viewState.selectedUsers.count, 1)
        XCTAssertEqual(context.viewState.selectedUsers.first?.userID, UserProfileProxy.mockAlice.userID)
        context.send(viewAction: .toggleUser(.mockAlice))
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
    }
     
    func testInviteButton() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockAlice, .mockBob]
        setupWithRoomType(roomType: .room(roomProxy: JoinedRoomProxyMock(.init(name: "test", members: mockedMembers))))
        
        let deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            state.isUserSelected(.mockAlice)
        }
        
        context.send(viewAction: .toggleUser(.mockAlice))
        
        try await deferredState.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .invite:
                return true
            default:
                return false
            }
        }
        
        context.send(viewAction: .proceed)
        
        guard case let .invite(members) = try await deferredAction.fulfill() else {
            XCTFail("Sent action should be 'invite'")
            return
        }
        
        XCTAssertEqual(members, [RoomMemberProxyMock.mockAlice.userID])
    }
    
    private func setupWithRoomType(roomType: InviteUsersScreenRoomType) {
        let usersSubject = CurrentValueSubject<[UserProfileProxy], Never>([])
        userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.searchProfilesWithReturnValue = .success([])
        usersSubject.send([])
        let viewModel = InviteUsersScreenViewModel(clientProxy: ClientProxyMock(.init()),
                                                   selectedUsers: usersSubject.asCurrentValuePublisher(),
                                                   roomType: roomType,
                                                   mediaProvider: MockMediaProvider(),
                                                   userDiscoveryService: userDiscoveryService,
                                                   userIndicatorController: UserIndicatorControllerMock())
        viewModel.state.usersSection = .init(type: .suggestions, users: [.mockAlice, .mockBob, .mockCharlie])
        self.viewModel = viewModel
        
        viewModel.actions.sink { action in
            switch action {
            case .toggleUser(let user):
                var selectedUsers = usersSubject.value
                if let index = selectedUsers.firstIndex(where: { $0.userID == user.userID }) {
                    selectedUsers.remove(at: index)
                } else {
                    selectedUsers.append(user)
                }
                usersSubject.send(selectedUsers)
            default:
                break
            }
        }
        .store(in: &cancellables)
    }
}
