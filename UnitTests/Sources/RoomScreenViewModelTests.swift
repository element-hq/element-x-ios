//
// Copyright 2024 New Vector Ltd
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

@testable import ElementX

import Combine
import XCTest

@MainActor
class RoomScreenViewModelTests: XCTestCase {
    private var viewModel: RoomScreenViewModel!
    
    override func setUp() async throws {
        AppSettings.resetAllSettings()
    }
    
    override func tearDown() {
        viewModel = nil
    }
    
    func testPinnedEventsBanner() async throws {
        ServiceLocator.shared.settings.pinningEnabled = true
        let timelineSubject = PassthroughSubject<TimelineProxyProtocol, Never>()
        let updateSubject = PassthroughSubject<JoinedRoomProxyAction, Never>()
        let roomProxyMock = JoinedRoomProxyMock(.init())
        // setup a way to inject the mock of the pinned events timeline
        roomProxyMock.pinnedEventsTimelineClosure = {
            await timelineSubject.values.first()
        }
        // setup the room proxy actions publisher
        roomProxyMock.underlyingActionsPublisher = updateSubject.eraseToAnyPublisher()
        let viewModel = RoomScreenViewModel(roomProxy: roomProxyMock,
                                            mediaProvider: MockMediaProvider(),
                                            appMediator: AppMediatorMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics)
        self.viewModel = viewModel
        
        // check if in the default state is not showing but is indeed loading
        var deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.pinnedEventsBannerState.count == 0
        }
        try await deferred.fulfill()
        XCTAssertTrue(viewModel.context.viewState.pinnedEventsBannerState.isLoading)
        XCTAssertFalse(viewModel.context.viewState.shouldShowPinnedEventsBanner)

        // check if if after the pinned event ids are set the banner is still in a loading state, but is both loading and showing with a counter
        deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.pinnedEventsBannerState.count == 2
        }
        roomProxyMock.underlyingPinnedEventIDs = ["test1", "test2"]
        updateSubject.send(.roomInfoUpdate)
        try await deferred.fulfill()
        XCTAssertTrue(viewModel.context.viewState.pinnedEventsBannerState.isLoading)
        XCTAssertTrue(viewModel.context.viewState.shouldShowPinnedEventsBanner)
        
        // setup the loaded pinned events injection in the timeline
        let pinnedTimelineMock = TimelineProxyMock()
        let pinnedTimelineProviderMock = RoomTimelineProviderMock()
        let providerUpdateSubject = PassthroughSubject<([TimelineItemProxy], PaginationState), Never>()
        pinnedTimelineProviderMock.underlyingUpdatePublisher = providerUpdateSubject.eraseToAnyPublisher()
        pinnedTimelineMock.timelineProvider = pinnedTimelineProviderMock
        pinnedTimelineProviderMock.itemProxies = [.event(.init(item: EventTimelineItemSDKMock(configuration: .init()), id: "1")),
                                                  .event(.init(item: EventTimelineItemSDKMock(configuration: .init()), id: "2"))]
        
        // check if the banner is now in a loaded state and is showing the counter
        deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            !viewState.pinnedEventsBannerState.isLoading
        }
        timelineSubject.send(pinnedTimelineMock)
        try await deferred.fulfill()
        XCTAssertEqual(viewModel.context.viewState.pinnedEventsBannerState.count, 2)
        XCTAssertTrue(viewModel.context.viewState.shouldShowPinnedEventsBanner)
        
        // check if the banner is updating alongside the timeline
        deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.pinnedEventsBannerState.count == 3
        }
        providerUpdateSubject.send(([.event(.init(item: EventTimelineItemSDKMock(configuration: .init()), id: "1")),
                                     .event(.init(item: EventTimelineItemSDKMock(configuration: .init()), id: "2")),
                                     .event(.init(item: EventTimelineItemSDKMock(configuration: .init()), id: "3"))], .initial))
        XCTAssertFalse(viewModel.context.viewState.pinnedEventsBannerState.isLoading)
        XCTAssertTrue(viewModel.context.viewState.shouldShowPinnedEventsBanner)
        try await deferred.fulfill()
        
        // check how the scrolling changes the banner visibility
        viewModel.timelineHasScrolled(direction: .top)
        XCTAssertFalse(viewModel.context.viewState.shouldShowPinnedEventsBanner)
        
        viewModel.timelineHasScrolled(direction: .bottom)
        XCTAssertTrue(viewModel.context.viewState.shouldShowPinnedEventsBanner)
    }
    
    func testRoomInfoUpdate() async throws {
        let updateSubject = PassthroughSubject<JoinedRoomProxyAction, Never>()
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "TestID", name: "StartingName", avatarURL: nil, hasOngoingCall: false))
        // setup the room proxy actions publisher
        roomProxyMock.canUserJoinCallUserIDReturnValue = .success(false)
        roomProxyMock.underlyingActionsPublisher = updateSubject.eraseToAnyPublisher()
        let viewModel = RoomScreenViewModel(roomProxy: roomProxyMock,
                                            mediaProvider: MockMediaProvider(),
                                            appMediator: AppMediatorMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics)
        self.viewModel = viewModel
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.roomTitle == "StartingName" &&
                viewState.roomAvatar == .room(id: "TestID", name: "StartingName", avatarURL: nil) &&
                !viewState.canJoinCall &&
                !viewState.hasOngoingCall
        }
        try await deferred.fulfill()
        
        roomProxyMock.name = "NewName"
        roomProxyMock.avatar = .room(id: "TestID", name: "NewName", avatarURL: .documentsDirectory)
        roomProxyMock.hasOngoingCall = true
        roomProxyMock.canUserJoinCallUserIDReturnValue = .success(true)
        
        deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.roomTitle == "NewName" &&
                viewState.roomAvatar == .room(id: "TestID", name: "NewName", avatarURL: .documentsDirectory) &&
                viewState.canJoinCall &&
                viewState.hasOngoingCall
        }
        
        updateSubject.send(.roomInfoUpdate)
        try await deferred.fulfill()
    }
}
