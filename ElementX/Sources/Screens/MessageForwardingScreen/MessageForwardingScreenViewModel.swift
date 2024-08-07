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
import SwiftUI

typealias MessageForwardingScreenViewModelType = StateStoreViewModel<MessageForwardingScreenViewState, MessageForwardingScreenViewAction>

class MessageForwardingScreenViewModel: MessageForwardingScreenViewModelType, MessageForwardingScreenViewModelProtocol {
    private let forwardingItem: MessageForwardingItem
    private let clientProxy: ClientProxyProtocol
    private let roomSummaryProvider: RoomSummaryProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<MessageForwardingScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<MessageForwardingScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(forwardingItem: MessageForwardingItem,
         clientProxy: ClientProxyProtocol,
         roomSummaryProvider: RoomSummaryProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.forwardingItem = forwardingItem
        self.clientProxy = clientProxy
        self.roomSummaryProvider = roomSummaryProvider
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: MessageForwardingScreenViewState(), imageProvider: mediaProvider)
        
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
                guard let self else { return }
                self.roomSummaryProvider.setFilter(.search(query: searchQuery))
            }
            .store(in: &cancellables)
        
        updateRooms()
    }
    
    override func process(viewAction: MessageForwardingScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.dismiss)
            roomSummaryProvider.setFilter(.all(filters: []))
        case .send:
            Task { await forward() }
        case .selectRoom(let roomID):
            state.selectedRoomID = roomID
        case .reachedTop:
            updateVisibleRange(edge: .top)
        case .reachedBottom:
            updateVisibleRange(edge: .bottom)
        }
    }
    
    // MARK: - Private
    
    private func updateRooms() {
        var rooms = [MessageForwardingRoom]()
        
        for summary in roomSummaryProvider.roomListPublisher.value {
            if summary.id == forwardingItem.roomID {
                continue
            }
            
            let room = MessageForwardingRoom(id: summary.id, name: summary.name, alias: summary.canonicalAlias, avatar: summary.avatar)
            rooms.append(room)
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
        guard let roomID = state.selectedRoomID else {
            fatalError()
        }
        
        guard let targetRoomProxy = await clientProxy.roomForIdentifier(roomID) else {
            MXLog.error("Failed retrieving room to forward to with id: \(roomID)")
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        if case .failure(let error) = await targetRoomProxy.timeline.sendMessageEventContent(forwardingItem.content) {
            MXLog.error("Failed forwarding message with error: \(error)")
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        // Timelines are cached - the local echo will be visible when fetching the room by its ID.
        actionsSubject.send(.sent(roomID: roomID))
    }
}
