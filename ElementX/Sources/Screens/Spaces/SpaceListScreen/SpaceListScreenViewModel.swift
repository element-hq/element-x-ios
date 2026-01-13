//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceListScreenViewModelType = StateStoreViewModelV2<SpaceListScreenViewState, SpaceListScreenViewAction>

class SpaceListScreenViewModel: SpaceListScreenViewModelType, SpaceListScreenViewModelProtocol {
    private let spaceServiceProxy: SpaceServiceProxyProtocol
    private let appSettings: AppSettings
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<SpaceListScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceListScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userSession: UserSessionProtocol,
         selectedSpacePublisher: CurrentValuePublisher<String?, Never>,
         appSettings: AppSettings,
         userIndicatorController: UserIndicatorControllerProtocol) {
        spaceServiceProxy = userSession.clientProxy.spaceService
        self.appSettings = appSettings
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: SpaceListScreenViewState(userID: userSession.clientProxy.userID,
                                                              topLevelSpaces: spaceServiceProxy.topLevelSpacesPublisher.value,
                                                              isCreateSpaceEnabled: appSettings.createSpaceEnabled,
                                                              bindings: .init()),
                   mediaProvider: userSession.mediaProvider)
        
        spaceServiceProxy.topLevelSpacesPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.topLevelSpaces, on: self)
            .store(in: &cancellables)
        
        selectedSpacePublisher
            .weakAssign(to: \.state.selectedSpaceID, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.userAvatarURLPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.userDisplayNamePublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userDisplayName, on: self)
            .store(in: &cancellables)
        
        appSettings.$createSpaceEnabled
            .weakAssign(to: \.state.isCreateSpaceEnabled, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: SpaceListScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .spaceAction(.select(let spaceServiceRoom)):
            Task { await selectSpace(spaceServiceRoom) }
        case .spaceAction(.join):
            fatalError("There shouldn't be any unjoined spaces in the joined spaces list.")
        case .showSettings:
            actionsSubject.send(.showSettings)
        case .screenAppeared:
            if !appSettings.hasSeenSpacesAnnouncement {
                // Use a task otherwise the presentation isn't animated.
                Task { state.bindings.isPresentingFeatureAnnouncement = true }
            }
        case .featureAnnouncementAppeared:
            appSettings.hasSeenSpacesAnnouncement = true
        case .createSpace:
            // TODO: Implement
            break
        }
    }
    
    // MARK: - Private
    
    private func selectSpace(_ spaceServiceRoom: SpaceServiceRoomProtocol) async {
        switch await spaceServiceProxy.spaceRoomList(spaceID: spaceServiceRoom.id) {
        case .success(let spaceRoomListProxy):
            actionsSubject.send(.selectSpace(spaceRoomListProxy))
        case .failure(let error):
            MXLog.error("Unable to select space: \(error)")
            showFailureIndicator()
        }
    }
    
    // MARK: - Indicators
    
    private static var failureIndicatorID: String { "\(Self.self)-Failure" }
    
    private func showFailureIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.failureIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
}
