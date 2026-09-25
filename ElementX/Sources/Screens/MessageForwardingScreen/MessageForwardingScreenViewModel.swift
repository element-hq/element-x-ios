//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias MessageForwardingScreenViewModelType = StateStoreViewModel<MessageForwardingScreenViewState, MessageForwardingScreenViewAction>

class MessageForwardingScreenViewModel: MessageForwardingScreenViewModelType, MessageForwardingScreenViewModelProtocol {
    private let forwardingPayload: MessageForwardingPayload
    private let clientProxy: ClientProxyProtocol
    private let roomSummaryProvider: RoomSummaryProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<MessageForwardingScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<MessageForwardingScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(forwardingPayload: MessageForwardingPayload,
         userSession: UserSessionProtocol,
         roomSummaryProvider: RoomSummaryProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.forwardingPayload = forwardingPayload
        clientProxy = userSession.clientProxy
        self.roomSummaryProvider = roomSummaryProvider
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: MessageForwardingScreenViewState(), mediaProvider: userSession.mediaProvider)
        
        roomSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRooms()
            }
            .store(in: &cancellables)
        
        context.$viewState
            .map(\.bindings.searchQuery)
            .removeDuplicates()
            .sink { [weak self] searchQuery in
                if searchQuery.isEmpty {
                    self?.roomSummaryProvider.setFilter(.all(filters: []))
                } else {
                    self?.roomSummaryProvider.setFilter(.search(query: searchQuery))
                }
            }
            .store(in: &cancellables)
        
        updateRooms()
    }
    
    override func process(viewAction: MessageForwardingScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.dismiss)
        case .send:
            Task { await forward() }
        case .selectRoom(let roomID):
            if state.selectedRoomIDs.contains(roomID) == false, state.selectedRoomIDs.count < state.maxRoomSelectionCount {
                state.selectedRoomIDs.insert(roomID)
            } else {
                state.selectedRoomIDs.remove(roomID)
            }
        case .reachedTop:
            updateVisibleRange(edge: .top)
        case .reachedBottom:
            updateVisibleRange(edge: .bottom)
        }
    }
    
    func stop() {
        // This is a shared provider so we should reset the filtering when we are done with the view
        roomSummaryProvider.setFilter(.all(filters: []))
    }
    
    // MARK: - Private
    
    private func updateRooms() {
        var rooms = [MessageForwardingRoom]()
        
        for summary in roomSummaryProvider.roomListPublisher.value {
            if summary.id == forwardingPayload.roomID {
                continue
            }
            
            rooms.append(.init(id: summary.id,
                               title: summary.name,
                               description: summary.roomListDescription,
                               avatar: summary.avatar))
        }
        
        state.rooms = rooms
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
    
    private func forward() async {
        guard !state.selectedRoomIDs.isEmpty else {
            fatalError()
        }
        
        var succeededRoomIdentifiers = [String]()
        var hasFailures = false
        
        for roomID in state.selectedRoomIDs {
            guard case let .joined(targetRoomProxy) = await clientProxy.roomForIdentifier(roomID) else {
                MXLog.error("Failed retrieving room to forward to with id: \(roomID)")
                hasFailures = true
                continue
            }
            
            // The contents are already in timeline order and the send queue preserves it.
            for content in forwardingPayload.contents {
                if case .failure(let error) = await targetRoomProxy.timeline.sendMessageEventContent(content) {
                    MXLog.error("Failed forwarding message with error: \(error)")
                    hasFailures = true
                }
            }
            
            succeededRoomIdentifiers.append(roomID)
        }
        
        if hasFailures {
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
        } else if succeededRoomIdentifiers.count > 1 {
            // The flow opens the room when there is a single one, otherwise the user stays here and needs to know it worked.
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.screenRoomMessagesForwarded(forwardingPayload.contents.count)))
        }
        
        if !succeededRoomIdentifiers.isEmpty {
            actionsSubject.send(.sent(roomIDs: succeededRoomIdentifiers))
        }
    }
}
