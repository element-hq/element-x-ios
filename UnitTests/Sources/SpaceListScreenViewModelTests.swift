//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
@Suite(.serialized)
struct SpacesScreenViewModelTests {
    @MainActor
    private struct TestSetup {
        var topLevelSpacesSubject: CurrentValueSubject<[SpaceServiceRoom], Never>
        var spaceServiceProxy: SpaceServiceProxyMock
        var appSettings: AppSettings
        var viewModel: SpacesScreenViewModelProtocol
        
        var context: SpacesScreenViewModelType.Context {
            viewModel.context
        }
        
        init() {
            AppSettings.resetAllSettings()
            appSettings = AppSettings()
            
            let clientProxy = ClientProxyMock(.init())
            let userSession = UserSessionMock(.init(clientProxy: clientProxy))
            
            topLevelSpacesSubject = .init([
                SpaceServiceRoom.mock(id: "space1", isSpace: true),
                SpaceServiceRoom.mock(id: "space2", isSpace: true),
                SpaceServiceRoom.mock(id: "space3", isSpace: true)
            ])
            spaceServiceProxy = SpaceServiceProxyMock(.init())
            spaceServiceProxy.topLevelSpacesPublisher = topLevelSpacesSubject.asCurrentValuePublisher()
            spaceServiceProxy.spaceRoomListSpaceIDClosure = { [topLevelSpacesSubject] spaceID in
                guard let spaceServiceRoom = topLevelSpacesSubject.value.first(where: { $0.id == spaceID }) else { return .failure(.missingSpace) }
                return .success(SpaceRoomListProxyMock(.init(spaceServiceRoom: spaceServiceRoom)))
            }
            clientProxy.spaceService = spaceServiceProxy
            
            viewModel = SpacesScreenViewModel(userSession: userSession,
                                              selectedSpacePublisher: .init(nil),
                                              appSettings: ServiceLocator.shared.settings,
                                              userIndicatorController: UserIndicatorControllerMock())
        }
    }

    @Test
    func initialState() {
        let testSetup = TestSetup()
        defer { AppSettings.resetAllSettings() }
        #expect(testSetup.context.viewState.topLevelSpaces.count == 3)
    }
    
    @Test
    func topLevelSpacesSubscription() async throws {
        var testSetup = TestSetup()
        defer { AppSettings.resetAllSettings() }
        
        var deferred = deferFulfillment(testSetup.context.observe(\.viewState.topLevelSpaces)) { $0.count == 0 }
        testSetup.topLevelSpacesSubject.send([])
        try await deferred.fulfill()
        #expect(testSetup.context.viewState.topLevelSpaces.count == 0)
        
        deferred = deferFulfillment(testSetup.context.observe(\.viewState.topLevelSpaces)) { $0.count == 1 }
        testSetup.topLevelSpacesSubject.send([
            SpaceServiceRoom.mock(isSpace: true)
        ])
        try await deferred.fulfill()
        #expect(testSetup.context.viewState.topLevelSpaces.count == 1)
    }
    
    @Test
    func selectingSpace() async throws {
        var testSetup = TestSetup()
        defer { AppSettings.resetAllSettings() }
        
        let selectedSpace = testSetup.topLevelSpacesSubject.value[0]
        let deferred = deferFulfillment(testSetup.viewModel.actionsPublisher) { _ in true }
        testSetup.viewModel.context.send(viewAction: .spaceAction(.select(selectedSpace)))
        let action = try await deferred.fulfill()
        
        switch action {
        case .selectSpace(let spaceRoomListProxy) where spaceRoomListProxy.id == selectedSpace.id:
            break
        default:
            Issue.record("The action should select the space.")
        }
    }
    
    @Test
    func featureAnnouncement() async throws {
        var testSetup = TestSetup()
        defer { AppSettings.resetAllSettings() }
        #expect(!testSetup.appSettings.hasSeenSpacesAnnouncement)
        #expect(!testSetup.context.isPresentingFeatureAnnouncement)
        
        let deferred = deferFulfillment(testSetup.context.observe(\.isPresentingFeatureAnnouncement)) { $0 == true }
        testSetup.viewModel.context.send(viewAction: .screenAppeared)
        try await deferred.fulfill()
        #expect(testSetup.context.isPresentingFeatureAnnouncement)
        
        testSetup.viewModel.context.send(viewAction: .featureAnnouncementAppeared)
        #expect(testSetup.appSettings.hasSeenSpacesAnnouncement)
        
        testSetup.context.isPresentingFeatureAnnouncement = false
        
        let deferredFailure = deferFailure(testSetup.context.observe(\.isPresentingFeatureAnnouncement), timeout: 1) { $0 == true }
        testSetup.viewModel.context.send(viewAction: .screenAppeared)
        try await deferredFailure.fulfill()
        #expect(!testSetup.context.isPresentingFeatureAnnouncement)
    }
}
