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
        self.userIndicatorController = userIndicatorController
        self.appSettings = appSettings
        
        super.init(initialViewState: SpaceScreenViewState(space: spaceRoomListProxy.spaceRoomProxyPublisher.value,
                                                          rooms: spaceRoomListProxy.spaceRoomsPublisher.value,
                                                          selectedSpaceRoomID: selectedSpaceRoomPublisher.value),
                   mediaProvider: userSession.mediaProvider)
        
        spaceRoomListProxy.spaceRoomProxyPublisher
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
                    .sink { [weak self] isEnabled, info in
                        guard let self else { return }
                        guard isEnabled, let powerLevels = info.powerLevels else {
                            state.isSpaceManagementEnabled = false
                            return
                        }
                        
                        state.isSpaceManagementEnabled = powerLevels.canOwnUserEditRolesAndPermissions() ||
                            powerLevels.canOwnUser(sendStateEvent: .roomName) ||
                            powerLevels.canOwnUser(sendStateEvent: .roomTopic) ||
                            powerLevels.canOwnUser(sendStateEvent: .roomAvatar)
                    }
                    .store(in: &cancellables)
            }
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: SpaceScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .spaceAction(.select(let spaceRoomProxy)):
            if spaceRoomProxy.isSpace {
                if spaceRoomProxy.state != .joined {
                    actionsSubject.send(.selectUnjoinedSpace(spaceRoomProxy))
                } else {
                    Task { await selectSpace(spaceRoomProxy) }
                }
            } else {
                // No need to check the join state, the room flow will show an appropriately configured join screen if needed.
                actionsSubject.send(.selectRoom(roomID: spaceRoomProxy.id))
            }
        case .spaceAction(.join(let spaceRoomProxy)):
            Task { await join(spaceRoomProxy) }
        case .leaveSpace:
            Task { await showLeaveSpaceConfirmation() }
        case .deselectAllLeaveRoomDetails:
            guard let leaveHandle = state.bindings.leaveHandle else { fatalError("The leave handle should be available.") }
            for room in leaveHandle.rooms {
                room.isSelected = false
            }
        case .selectAllLeaveRoomDetails:
            guard let leaveHandle = state.bindings.leaveHandle else { fatalError("The leave handle should be available.") }
            for room in leaveHandle.rooms where !room.isLastAdmin {
                room.isSelected = true
            }
        case .toggleLeaveSpaceRoomDetails(let spaceRoomID):
            guard let room = state.bindings.leaveHandle?.rooms.first(where: { $0.spaceRoomProxy.id == spaceRoomID }) else {
                fatalError("The space room to toggle is not in the list of rooms to leave.")
            }
            withTransaction(\.disablesAnimations, true) { // The button is adding an unwanted animation.
                room.isSelected.toggle()
            }
        case .confirmLeaveSpace:
            Task { await confirmLeaveSpace() }
        case .displayMembers(let roomProxy):
            actionsSubject.send(.displayMembers(roomProxy: roomProxy))
        case .spaceSettings:
            guard let roomProxy = state.roomProxy else {
                fatalError("Always available when the space settings button is tapped.")
            }
            actionsSubject.send(.displaySpaceSettings(roomProxy: roomProxy))
        }
    }
    
    func stop() {
        // If we pop this screen with running join operations, we don't want them to do anything.
        state.joiningRoomIDs.removeAll()
    }
    
    // MARK: - Private
    
    private func join(_ spaceRoomProxy: SpaceRoomProxyProtocol) async {
        state.joiningRoomIDs.insert(spaceRoomProxy.id)
        defer { state.joiningRoomIDs.remove(spaceRoomProxy.id) }
        
        guard case .success = await clientProxy.joinRoom(spaceRoomProxy.id, via: spaceRoomProxy.via) else {
            showFailureIndicator()
            return
        }
        
        // We don't want to show the space room after joining it this way 🤷‍♂️
    }
    
    private func selectSpace(_ spaceRoomProxy: SpaceRoomProxyProtocol) async {
        switch await spaceServiceProxy.spaceRoomList(spaceID: spaceRoomProxy.id) {
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
        
        state.bindings.leaveHandle = leaveHandle
    }
    
    private func confirmLeaveSpace() async {
        guard let leaveHandle = state.bindings.leaveHandle else { fatalError("Leaving without a handle is impossible.") }
        
        showLeavingIndicator()
        defer { hideLeavingIndicator() }
        
        switch await leaveHandle.leave() {
        case .success:
            state.bindings.leaveHandle = nil
            actionsSubject.send(.leftSpace)
        case .failure:
            showFailureIndicator()
        }
    }
    
    private func updatePermissions() { }
    
    // MARK: - Indicators
    
    private static var leavingIndicatorID: String { "\(Self.self)-Leaving" }
    private static var failureIndicatorID: String { "\(Self.self)-Failure" }
    
    private func showLeavingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.leavingIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonLeavingSpace))
    }
    
    private func hideLeavingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.leavingIndicatorID)
    }
    
    private func showFailureIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.failureIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
}
