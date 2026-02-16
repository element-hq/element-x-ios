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
                guard let self else { return }
                
                switch paginationState {
                case .idle(endReached: false):
                    state.paginationState = .idle
                    Task { await spaceRoomListProxy.paginate() }
                case .idle(endReached: true):
                    state.paginationState = .endReached
                case .loading:
                    state.paginationState = .paginating
                }
            }
            .store(in: &cancellables)
        
        selectedSpaceRoomPublisher
            .weakAssign(to: \.state.selectedSpaceRoomID, on: self)
            .store(in: &cancellables)
        
        appSettings.$createSpaceEnabled
            .weakAssign(to: \.state.canCreateRoom, on: self)
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
                            state.canEditChildren = false
                            return
                        }
                        state.canEditBaseInfo = powerLevels.canOwnUserEditBaseInfo()
                        state.canEditRolesAndPermissions = powerLevels.canOwnUserEditRolesAndPermissions()
                        state.canEditSecurityAndPrivacy = powerLevels.canOwnUserEditSecurityAndPrivacy(isSpace: roomInfo.isSpace,
                                                                                                       joinRule: roomInfo.joinRule)
                        state.canEditChildren = powerLevels.canOwnUser(sendStateEvent: .spaceChild)
                    }
                    .store(in: &cancellables)
            }
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: SpaceScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .spaceAction(.select(let spaceServiceRoom)) where state.editMode == .inactive:
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
        case .spaceAction(.select(let spaceServiceRoom)): // isEditModeActive == true
            withTransaction(\.disablesAnimations, true) { // The button adds an unwanted animation.
                if state.editModeSelectedIDs.contains(spaceServiceRoom.id) {
                    state.editModeSelectedIDs.remove(spaceServiceRoom.id)
                } else {
                    state.editModeSelectedIDs.insert(spaceServiceRoom.id)
                }
            }
        case .spaceAction(.join(let spaceServiceRoom)):
            Task { await join(spaceServiceRoom) }
        case .leaveSpace:
            Task { await showLeaveSpaceConfirmation() }
        case .displayMembers(let roomProxy):
            actionsSubject.send(.displayMembers(roomProxy: roomProxy))
        case .spaceSettings(let roomProxy):
            actionsSubject.send(.displaySpaceSettings(roomProxy: roomProxy))
        case .addExistingRooms:
            actionsSubject.send(.addExistingChildren)
        case .manageChildren:
            withAnimation(.easeOut(duration: 0.25).disabledDuringTests()) {
                state.editMode = .transient
            }
        case .removeSelectedChildren:
            state.bindings.isPresentingRemoveChildrenConfirmation = true
        case .confirmRemoveSelectedChildren:
            Task { await removeSelectedChildren() }
        case .finishManagingChildren:
            withAnimation(.easeOut(duration: 0.25).disabledDuringTests()) {
                state.editMode = .inactive
                state.editModeRemovedIDs = []
            } completion: {
                self.state.editModeSelectedIDs.removeAll()
            }
        case .createChildRoom:
            Task { await createChildRoom() }
        }
    }
    
    func stop() {
        // If we pop this screen with running join operations, we don't want them to do anything.
        state.joiningRoomIDs.removeAll()
    }
    
    func resetRoomList() {
        Task { await spaceRoomListProxy.resetAndWaitForFullReload(timeout: .seconds(10)) }
    }
    
    // MARK: - Private
    
    private func createChildRoom() async {
        switch await spaceServiceProxy.spaceForIdentifier(spaceID: spaceRoomListProxy.id) {
        case .success(.some(let space)):
            actionsSubject.send(.displayCreateChildRoomFlow(space: space))
        default:
            MXLog.error("Unable to create child room: space not found")
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
        }
    }
    
    private func join(_ spaceServiceRoom: SpaceServiceRoom) async {
        state.joiningRoomIDs.insert(spaceServiceRoom.id)
        defer { state.joiningRoomIDs.remove(spaceServiceRoom.id) }
        
        guard case .success = await clientProxy.joinRoom(spaceServiceRoom.id, via: spaceServiceRoom.via) else {
            showFailureIndicator()
            return
        }
        
        // We don't want to show the space room after joining it this way 🤷‍♂️
    }
    
    private func selectSpace(_ spaceServiceRoom: SpaceServiceRoom) async {
        switch await spaceServiceProxy.spaceRoomList(spaceID: spaceServiceRoom.id) {
        case .success(let spaceRoomListProxy):
            actionsSubject.send(.selectSpace(spaceRoomListProxy))
        case .failure(let error):
            MXLog.error("Unable to select space: \(error)")
            showFailureIndicator()
        }
    }
    
    private func removeSelectedChildren() async {
        showRemovingIndicator()
        defer { hideRemovingIndicator() }
        
        state.bindings.isPresentingRemoveChildrenConfirmation = false
        
        MXLog.info("Removing \(state.editModeSelectedIDs.count) children from space \(spaceRoomListProxy.id)")
        
        var removedIDs: [String] = [] // Using an intermediate array so the screen doesn't change until the operation finishes.
        for childID in state.editModeSelectedIDs {
            switch await spaceServiceProxy.removeChild(childID, from: spaceRoomListProxy.id) {
            case .success:
                removedIDs.append(childID)
            case .failure(let error):
                MXLog.error("Failed removing room from space: \(error)")
                showFailureIndicator()
                
                // Hide rooms that were successfully removed.
                state.editModeSelectedIDs = state.editModeSelectedIDs.filter { !removedIDs.contains($0) }
                state.editModeRemovedIDs.formUnion(removedIDs)
                
                return
            }
        }
        
        MXLog.info("\(state.editModeSelectedIDs.count) children removed from space \(spaceRoomListProxy.id)")
        
        await spaceRoomListProxy.resetAndWaitForFullReload(timeout: .seconds(10))
        
        process(viewAction: .finishManagingChildren)
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
                    fatalError("There should always be a room proxy available for joined spaces.")
                }
                state.bindings.leaveSpaceViewModel = nil
                actionsSubject.send(.presentRolesAndPermissions(roomProxy: roomProxy))
            case .didLeaveSpace:
                state.bindings.leaveSpaceViewModel = nil
                actionsSubject.send(.leftSpace)
            case .presentTransferOwnership:
                guard let roomProxy = state.roomProxy else {
                    fatalError("There should always be a room proxy available for joined spaces.")
                }
                state.bindings.leaveSpaceViewModel = nil
                actionsSubject.send(.presentTransferOwnership(roomProxy: roomProxy))
            }
        }
        .store(in: &cancellables)
        
        state.bindings.leaveSpaceViewModel = leaveSpaceViewModel
    }
        
    // MARK: - Indicators
    
    private static var removingIndicatorID: String {
        "\(Self.self)-Removing"
    }

    private static var failureIndicatorID: String {
        "\(Self.self)-Failure"
    }
    
    private func showRemovingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.removingIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonRemoving,
                                                              persistent: true))
    }
    
    private func hideRemovingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.removingIndicatorID)
    }
    
    private func showFailureIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.failureIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
}
