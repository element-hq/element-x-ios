//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceAddRoomsScreenViewModelType = StateStoreViewModelV2<SpaceAddRoomsScreenViewState, SpaceAddRoomsScreenViewAction>

class SpaceAddRoomsScreenViewModel: SpaceAddRoomsScreenViewModelType, SpaceAddRoomsScreenViewModelProtocol {
    private let spaceRoomListProxy: SpaceRoomListProxyProtocol
    private let spaceServiceProxy: SpaceServiceProxyProtocol
    private let roomSummaryProvider: RoomSummaryProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var suggestedRooms: [SpaceAddRoomsScreenRoom] = []
    /// A place to track rooms that were sucessfully added to the space in order to filter them out from
    /// the roomsSection when a failure occurs part way through the array.
    private var addedRoomIDs: Set<String> = []
    
    private var actionsSubject: PassthroughSubject<SpaceAddRoomsScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SpaceAddRoomsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(spaceRoomListProxy: SpaceRoomListProxyProtocol,
         userSession: UserSessionProtocol,
         roomSummaryProvider: RoomSummaryProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.spaceRoomListProxy = spaceRoomListProxy
        spaceServiceProxy = userSession.clientProxy.spaceService
        self.roomSummaryProvider = roomSummaryProvider
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: SpaceAddRoomsScreenViewState(roomsSection: .init(type: .suggestions, rooms: [])),
                   mediaProvider: userSession.mediaProvider)
        
        roomSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRooms()
            }
            .store(in: &cancellables)
        
        Task {
            let existingRooms = spaceRoomListProxy.spaceRoomsPublisher.value
            suggestedRooms = await userSession.clientProxy
                .recentlyVisitedRooms { roomProxy in
                    !roomProxy.infoPublisher.value.isDirect
                        && !roomProxy.infoPublisher.value.isSpace
                        && roomProxy.infoPublisher.value.membership == .joined
                        && !existingRooms.contains { $0.id == roomProxy.id }
                }
                .map { .init(roomProxy: $0) }
            
            if state.roomsSection.type == .suggestions {
                state.roomsSection = .init(type: .suggestions, rooms: suggestedRooms)
            }
        }
    }
    
    override func process(viewAction: SpaceAddRoomsScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.dismiss)
        case .reachedTop:
            updateVisibleRange(edge: .top)
        case .reachedBottom:
            updateVisibleRange(edge: .bottom)
        case .searchQueryChanged where state.bindings.searchQuery.isEmpty:
            roomSummaryProvider.setFilter(.all(filters: []))
        case .searchQueryChanged:
            roomSummaryProvider.setFilter(.search(query: state.bindings.searchQuery))
        case .toggleRoom(let room):
            toggleRoom(room)
        case .save:
            Task { await save() }
        }
    }
    
    func stop() {
        // This is a shared provider so we should reset the filtering when we are done with the view
        roomSummaryProvider.setFilter(.all(filters: []))
    }
    
    // MARK: - Private
    
    private func updateRooms() {
        guard !state.bindings.searchQuery.isEmpty else {
            state.roomsSection = .init(type: .suggestions, rooms: suggestedRooms)
            return
        }
        
        let existingRooms = spaceRoomListProxy.spaceRoomsPublisher.value
        
        let rooms = roomSummaryProvider.roomListPublisher.value
            .lazy
            .filter { [addedRoomIDs] summary in
                !summary.isDirect && !existingRooms.contains { $0.id == summary.id } && !addedRoomIDs.contains(summary.id)
            }
            .map(SpaceAddRoomsScreenRoom.init)
        
        state.roomsSection = .init(type: .searchResults, rooms: Array(rooms))
    }
    
    /// The actual range values don't matter as long as they contain the lower
    /// or upper bounds. updateVisibleRange is a hybrid API that powers both
    /// sliding sync visible range update and list paginations
    /// For lists other than the home screen one we don't care about visible ranges,
    /// we just need the respective bounds to be there to trigger a next page load or
    /// a reset to just one page
    private func updateVisibleRange(edge: UIRectEdge) {
        switch edge {
        case .top:
            roomSummaryProvider.updateVisibleRange(0..<0)
        case .bottom:
            let roomCount = roomSummaryProvider.roomListPublisher.value.count
            roomSummaryProvider.updateVisibleRange(roomCount..<roomCount)
        default:
            break
        }
    }
    
    private func toggleRoom(_ room: SpaceAddRoomsScreenRoom) {
        if state.selectedRooms.contains(room) {
            state.selectedRooms.removeAll { $0.id == room.id }
        } else {
            state.selectedRooms.append(room)
            withElementAnimation(.easeInOut) { state.bindings.selectedRoomsPosition = room.id }
        }
    }
    
    private func save() async {
        showSavingIndicator()
        defer { hideSavingIndicator() }
        
        MXLog.info("Adding \(state.selectedRooms.count) rooms to space \(spaceRoomListProxy.id)")
        
        for room in state.selectedRooms {
            switch await spaceServiceProxy.addChild(room.id, to: spaceRoomListProxy.id) {
            case .success:
                addedRoomIDs.insert(room.id)
            case .failure(let error):
                MXLog.error("Failed adding room to space: \(error)")
                showErrorIndicator()
                
                // Hide rooms that were successfully added.
                state.selectedRooms.removeAll { addedRoomIDs.contains($0.id) }
                updateRooms()
                
                return
            }
        }
        
        MXLog.info("\(state.selectedRooms.count) rooms added to space \(spaceRoomListProxy.id)")
        
        await spaceRoomListProxy.resetAndWaitForFullReload(timeout: .seconds(10))
        
        actionsSubject.send(.dismiss)
    }
    
    // MARK: User Indicators
    
    private var savingIndicatorID: String {
        "\(Self.self)-Saving"
    }

    private var failureIndicatorID: String {
        "\(Self.self)-Failure"
    }
    
    private func showSavingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: savingIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonSaving,
                                                              persistent: true))
    }
    
    private func hideSavingIndicator() {
        userIndicatorController.retractIndicatorWithId(savingIndicatorID)
    }
    
    private func showErrorIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: failureIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
}
