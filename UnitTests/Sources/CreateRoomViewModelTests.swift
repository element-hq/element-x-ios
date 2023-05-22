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

import Combine
import XCTest

@testable import ElementX

@MainActor
class CreateRoomScreenViewModelTests: XCTestCase {
    var viewModel: CreateRoomViewModelProtocol!
    var clientProxy: MockClientProxy!
    var userSession: MockUserSession!
    
    private let usersSubject = CurrentValueSubject<[UserProfile], Never>([])
    private var cancellables: Set<AnyCancellable> = []
    
    var context: CreateRoomViewModel.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        clientProxy = MockClientProxy(userID: "@a:b.com")
        userSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
        let parameters = CreateRoomFlowParameters()
        usersSubject.send([.mockAlice, .mockBob, .mockCharlie])
        let viewModel = CreateRoomViewModel(userSession: userSession, userIndicatorController: nil, createRoomParameters: .init(parameters), selectedUsers: usersSubject.asCurrentValuePublisher())
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
        XCTAssertEqual(context.viewState.selectedUsers.first?.userID, UserProfile.mockAlice.userID)
        context.send(viewAction: .deselectUser(.mockAlice))
        XCTAssertNotEqual(context.viewState.selectedUsers.first?.userID, UserProfile.mockAlice.userID)
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
