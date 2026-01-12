//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class SpaceListScreenViewModelTests: XCTestCase {
    var topLevelSpacesSubject: CurrentValueSubject<[SpaceServiceRoomProtocol], Never>!
    var spaceServiceProxy: SpaceServiceProxyMock!
    var appSettings: AppSettings!
    
    var viewModel: SpaceListScreenViewModelProtocol!
    
    var context: SpaceListScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }

    func testInitialState() {
        setupViewModel()
        XCTAssertEqual(context.viewState.topLevelSpaces.count, 3)
    }
    
    func testTopLevelSpacesSubscription() async throws {
        setupViewModel()
        
        var deferred = deferFulfillment(context.observe(\.viewState.topLevelSpaces)) { $0.count == 0 }
        topLevelSpacesSubject.send([])
        try await deferred.fulfill()
        XCTAssertEqual(context.viewState.topLevelSpaces.count, 0)
        
        deferred = deferFulfillment(context.observe(\.viewState.topLevelSpaces)) { $0.count == 1 }
        topLevelSpacesSubject.send([
            SpaceServiceRoomMock(.init(isSpace: true))
        ])
        try await deferred.fulfill()
        XCTAssertEqual(context.viewState.topLevelSpaces.count, 1)
    }
    
    func testSelectingSpace() async throws {
        setupViewModel()
        
        let selectedSpace = topLevelSpacesSubject.value[0]
        let deferred = deferFulfillment(viewModel.actionsPublisher) { _ in true }
        viewModel.context.send(viewAction: .spaceAction(.select(selectedSpace)))
        let action = try await deferred.fulfill()
        
        switch action {
        case .selectSpace(let spaceRoomListProxy) where spaceRoomListProxy.id == selectedSpace.id:
            break
        default:
            XCTFail("The action should select the space.")
        }
    }
    
    func testFeatureAnnouncement() async throws {
        setupViewModel()
        XCTAssertFalse(appSettings.hasSeenSpacesAnnouncement)
        XCTAssertFalse(context.isPresentingFeatureAnnouncement)
        
        let deferred = deferFulfillment(context.observe(\.isPresentingFeatureAnnouncement)) { $0 == true }
        viewModel.context.send(viewAction: .screenAppeared)
        try await deferred.fulfill()
        XCTAssertTrue(context.isPresentingFeatureAnnouncement)
        
        viewModel.context.send(viewAction: .featureAnnouncementAppeared)
        XCTAssertTrue(appSettings.hasSeenSpacesAnnouncement)
        
        context.isPresentingFeatureAnnouncement = false
        
        let deferredFailure = deferFailure(context.observe(\.isPresentingFeatureAnnouncement), timeout: 1) { $0 == true }
        viewModel.context.send(viewAction: .screenAppeared)
        try await deferredFailure.fulfill()
        XCTAssertFalse(context.isPresentingFeatureAnnouncement)
    }
    
    // MARK: - Helpers
    
    private func setupViewModel() {
        let clientProxy = ClientProxyMock(.init())
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        
        topLevelSpacesSubject = .init([
            SpaceServiceRoomMock(.init(id: "space1", isSpace: true)),
            SpaceServiceRoomMock(.init(id: "space2", isSpace: true)),
            SpaceServiceRoomMock(.init(id: "space3", isSpace: true))
        ])
        spaceServiceProxy = SpaceServiceProxyMock(.init())
        spaceServiceProxy.topLevelSpacesPublisher = topLevelSpacesSubject.asCurrentValuePublisher()
        spaceServiceProxy.spaceRoomListSpaceIDClosure = { [topLevelSpacesSubject] spaceID in
            guard let spaceServiceRoom = topLevelSpacesSubject?.value.first(where: { $0.id == spaceID }) else { return .failure(.missingSpace) }
            return .success(SpaceRoomListProxyMock(.init(spaceServiceRoom: spaceServiceRoom)))
        }
        clientProxy.spaceService = spaceServiceProxy
        
        viewModel = SpaceListScreenViewModel(userSession: userSession,
                                             selectedSpacePublisher: .init(nil),
                                             appSettings: ServiceLocator.shared.settings,
                                             userIndicatorController: UserIndicatorControllerMock())
    }
}
