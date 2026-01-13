//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceScreenViewModelType = StateStoreViewModelV2<SpaceScreenViewState, SpaceScreenViewAction>

class SpaceScreenViewModel: SpaceScreenViewModelType, SpaceScreenViewModelProtocol {
    private let spaceRoomListProxy: SpaceRoomListProxyProtocol
    private let spaceServiceProxy: SpaceServiceProxyProtocol
    private let clientProxy: ClientProxyProtocol
    private let mediaProvider: MediaProviderProtocol
    private let appSettings: AppSettings
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<SpaceScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(spaceRoomListProxy: SpaceRoomListProxyProtocol,
         spaceServiceProxy: SpaceServiceProxyProtocol,
         selectedSpaceRoomPublisher: CurrentValuePublisher<String?, Never>,
         userSession: UserSessionProtocol,
         appSettings: AppSettings,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.spaceRoomListProxy = spaceRoomListProxy
        self.spaceServiceProxy = spaceServiceProxy
        clientProxy = userSession.clientProxy
        mediaProvider = userSession.mediaProvider
        self.userIndicatorController = userIndicatorController
        self.appSettings = appSettings
        
        super.init(initialViewState: SpaceScreenViewState(space: spaceRoomListProxy.spaceServiceRoomPublisher.value,
                                                          rooms: spaceRoomListProxy.spaceRoomsPublisher.value,
                                                          selectedSpaceRoomID: selectedSpaceRoomPublisher.value),
                   mediaProvider: userSession.mediaProvider)
        
        spaceRoomListProxy.spaceServiceRoomPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.space, on: self)
            .store(in: &cancellables)
        
        spaceRoomListProxy.spaceRoomsPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.rooms, on: self)
            .store(in: &cancellables)
        
        // As the server is slow, we just let the screen automatically paginate everything in. We can
        // switch this to use the scroll position once Synapse receives some performance improvements.
        spaceRoomListProxy.paginationStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paginationState in
                switch paginationState {
                case .idle(let endReached):
                    self?.state.isPaginating = false
                    guard !endReached else { return }
                    Task { await spaceRoomListProxy.paginate() }
                case .loading:
                    self?.state.isPaginating = true
                }
            }
            .store(in: &cancellables)
        
        selectedSpaceRoomPublisher
            .weakAssign(to: \.state.selectedSpaceRoomID, on: self)
            .store(in: &cancellables)
        
        Task {
            if case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(spaceRoomListProxy.id) {
                // Required to listen for membership updates in the members flow
                await roomProxy.subscribeForUpdates()
                state.roomProxy = roomProxy
                if case let .success(permalinkURL) = await roomProxy.matrixToPermalink() {
                    state.permalink = permalinkURL
                }
                
                appSettings.$spaceSettingsEnabled
                    .combineLatest(roomProxy.infoPublisher)
                    .sink { [weak self] isEnabled, roomInfo in
                        guard let self else { return }
                        guard isEnabled, let powerLevels = roomInfo.powerLevels else {
                            state.canEditBaseInfo = false
                            state.canEditRolesAndPermissions = false
                            state.canEditSecurityAndPrivacy = false
                            return
                        }
                        state.canEditBaseInfo = powerLevels.canOwnUserEditBaseInfo()
                        state.canEditRolesAndPermissions = powerLevels.canOwnUserEditRolesAndPermissions()
                        state.canEditSecurityAndPrivacy = powerLevels.canOwnUserEditSecurityAndPrivacy(isSpace: roomInfo.isSpace,
                                                                                                       joinRule: roomInfo.joinRule)
                    }
                    .store(in: &cancellables)
            }
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: SpaceScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .spaceAction(.select(let spaceServiceRoom)):
            if spaceServiceRoom.isSpace {
                if spaceServiceRoom.state != .joined {
                    actionsSubject.send(.selectUnjoinedSpace(spaceServiceRoom))
                } else {
                    Task { await selectSpace(spaceServiceRoom) }
                }
            } else {
                // No need to check the join state, the room flow will show an appropriately configured join screen if needed.
                actionsSubject.send(.selectRoom(roomID: spaceServiceRoom.id))
            }
        case .spaceAction(.join(let spaceServiceRoom)):
            Task { await join(spaceServiceRoom) }
        case .leaveSpace:
            Task { await showLeaveSpaceConfirmation() }
        case .displayMembers(let roomProxy):
            actionsSubject.send(.displayMembers(roomProxy: roomProxy))
        case .spaceSettings(let roomProxy):
            actionsSubject.send(.displaySpaceSettings(roomProxy: roomProxy))
        }
    }
    
    func stop() {
        // If we pop this screen with running join operations, we don't want them to do anything.
        state.joiningRoomIDs.removeAll()
    }
    
    // MARK: - Private
    
    private func join(_ spaceServiceRoom: SpaceServiceRoomProtocol) async {
        state.joiningRoomIDs.insert(spaceServiceRoom.id)
        defer { state.joiningRoomIDs.remove(spaceServiceRoom.id) }
        
        guard case .success = await clientProxy.joinRoom(spaceServiceRoom.id, via: spaceServiceRoom.via) else {
            showFailureIndicator()
            return
        }
        
        // We don't want to show the space room after joining it this way 🤷‍♂️
    }
    
    private func selectSpace(_ spaceServiceRoom: SpaceServiceRoomProtocol) async {
        switch await spaceServiceProxy.spaceRoomList(spaceID: spaceServiceRoom.id) {
        case .success(let spaceRoomListProxy):
            actionsSubject.send(.selectSpace(spaceRoomListProxy))
        case .failure(let error):
            MXLog.error("Unable to select space: \(error)")
            showFailureIndicator()
        }
    }
    
    private func showLeaveSpaceConfirmation() async {
        guard case let .success(leaveHandle) = await spaceServiceProxy.leaveSpace(spaceID: spaceRoomListProxy.id) else {
            showFailureIndicator()
            return
        }
        
        let leaveSpaceViewModel = LeaveSpaceViewModel(spaceName: state.space.name,
                                                      canEditRolesAndPermissions: appSettings.spaceSettingsEnabled && state.canEditRolesAndPermissions,
                                                      leaveHandle: leaveHandle,
                                                      userIndicatorController: userIndicatorController,
                                                      mediaProvider: mediaProvider)
        leaveSpaceViewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .didCancel:
                state.bindings.leaveSpaceViewModel = nil
            case .presentRolesAndPermissions:
                guard let roomProxy = state.roomProxy else {
                    fatalError("The space screen should always have a room proxy")
                }
                state.bindings.leaveSpaceViewModel = nil
                actionsSubject.send(.presentRolesAndPermissions(roomProxy: roomProxy))
            case .didLeaveSpace:
                state.bindings.leaveSpaceViewModel = nil
                actionsSubject.send(.leftSpace)
            }
        }
        .store(in: &cancellables)
        
        state.bindings.leaveSpaceViewModel = leaveSpaceViewModel
    }
        
    // MARK: - Indicators
    
    private static var leavingIndicatorID: String { "\(Self.self)-Leaving" }
    private static var failureIndicatorID: String { "\(Self.self)-Failure" }
    
    private func showFailureIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.failureIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
}
