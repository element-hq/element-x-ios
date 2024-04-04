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
class HomeScreenViewModelTests: XCTestCase {
    var viewModel: HomeScreenViewModelProtocol!
    var clientProxy: ClientProxyMock!
    var context: HomeScreenViewModelType.Context! { viewModel.context }
    var cancellables = Set<AnyCancellable>()
    var roomSummaryProvider: RoomSummaryProviderMock!
    
    override func setUpWithError() throws {
        cancellables.removeAll()
        roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        clientProxy = ClientProxyMock(.init(userID: "@mock:client.com", roomSummaryProvider: roomSummaryProvider))
        viewModel = HomeScreenViewModel(userSession: MockUserSession(clientProxy: clientProxy,
                                                                     mediaProvider: MockMediaProvider(),
                                                                     voiceMessageMediaManager: VoiceMessageMediaManagerMock()),
                                        analyticsService: ServiceLocator.shared.analytics,
                                        appSettings: ServiceLocator.shared.settings,
                                        selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                        userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }
    
    func testSelectRoom() async throws {
        let mockRoomId = "mock_room_id"
        var correctResult = false
        var selectedRoomId = ""
        
        viewModel.actions
            .sink { action in
                switch action {
                case .presentRoom(let roomId):
                    correctResult = true
                    selectedRoomId = roomId
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        context.send(viewAction: .selectRoom(roomIdentifier: mockRoomId))
        await Task.yield()
        XCTAssert(correctResult)
        XCTAssertEqual(mockRoomId, selectedRoomId)
    }

    func testTapUserAvatar() async throws {
        var correctResult = false
        
        viewModel.actions
            .sink { action in
                switch action {
                case .presentSettingsScreen:
                    correctResult = true
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        context.send(viewAction: .showSettings)
        await Task.yield()
        XCTAssert(correctResult)
    }
    
    func testLeaveRoomAlert() async throws {
        let mockRoomId = "1"
        
        clientProxy.roomForIdentifierClosure = { _ in RoomProxyMock(with: .init(id: mockRoomId, name: "Some room")) }
        
        let deferred = deferFulfillment(context.$viewState) { value in
            value.bindings.leaveRoomAlertItem != nil
        }
        
        context.send(viewAction: .leaveRoom(roomIdentifier: mockRoomId))
        
        try await deferred.fulfill()
        
        XCTAssertEqual(context.leaveRoomAlertItem?.roomID, mockRoomId)
    }
    
    func testLeaveRoomError() async throws {
        let mockRoomId = "1"
        let room: RoomProxyMock = .init(with: .init(id: mockRoomId, name: "Some room"))
        room.leaveRoomClosure = { .failure(.sdkError(ClientProxyMockError.generic)) }
        
        clientProxy.roomForIdentifierClosure = { _ in room }

        let deferred = deferFulfillment(context.$viewState) { value in
            value.bindings.alertInfo != nil
        }
        
        context.send(viewAction: .confirmLeaveRoom(roomIdentifier: mockRoomId))
        
        try await deferred.fulfill()
                
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testLeaveRoomSuccess() async throws {
        let mockRoomId = "1"
        var correctResult = false
        let expectation = expectation(description: #function)
        viewModel.actions
            .sink { action in
                switch action {
                case .roomLeft(let roomIdentifier):
                    correctResult = roomIdentifier == mockRoomId
                default:
                    break
                }
                expectation.fulfill()
            }
            .store(in: &cancellables)
        let room: RoomProxyMock = .init(with: .init(id: mockRoomId, name: "Some room"))
        room.leaveRoomClosure = { .success(()) }
        
        clientProxy.roomForIdentifierClosure = { _ in room }
        
        context.send(viewAction: .confirmLeaveRoom(roomIdentifier: mockRoomId))
        await fulfillment(of: [expectation])
        XCTAssertNil(context.alertInfo)
        XCTAssertTrue(correctResult)
    }
    
    func testShowRoomDetails() async throws {
        let mockRoomId = "1"
        var correctResult = false
        viewModel.actions
            .sink { action in
                switch action {
                case .presentRoomDetails(let roomIdentifier):
                    correctResult = roomIdentifier == mockRoomId
                default:
                    break
                }
            }
            .store(in: &cancellables)
        context.send(viewAction: .showRoomDetails(roomIdentifier: mockRoomId))
        await Task.yield()
        XCTAssertNil(context.alertInfo)
        XCTAssertTrue(correctResult)
    }
    
    func testFilters() async throws {
        context.filtersState.activateFilter(.people)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(roomSummaryProvider.roomListPublisher.value.count, 2)
        XCTAssertEqual(roomSummaryProvider.roomListPublisher.value.first?.name, "Foundation and Earth")
    }
    
    func testSearch() async throws {
        context.isSearchFieldFocused = true
        context.searchQuery = "lude to Found"
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(roomSummaryProvider.roomListPublisher.value.first?.name, "Prelude to Foundation")
        XCTAssertEqual(roomSummaryProvider.roomListPublisher.value.count, 1)
    }
    
    func testFiltersEmptyState() async throws {
        context.filtersState.activateFilter(.people)
        context.filtersState.activateFilter(.favourites)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(context.viewState.shouldShowEmptyFilterState)
        context.isSearchFieldFocused = true
        XCTAssertFalse(context.viewState.shouldShowEmptyFilterState)
    }
}
