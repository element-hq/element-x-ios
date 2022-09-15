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
import Foundation
import MatrixRustSDK

private class WeakRoomSummaryProviderWrapper: SlidingSyncViewRoomListObserver, SlidingSyncViewStateObserver {
    private weak var roomSummaryProvider: RoomSummaryProvider?
    
    let roomListDiffPublisher = PassthroughSubject<SlidingSyncViewRoomsListDiff, Never>()
    let stateUpdatePublisher = CurrentValueSubject<SlidingSyncState, Never>(.cold)
    
    init(roomSummaryProvider: RoomSummaryProvider) {
        self.roomSummaryProvider = roomSummaryProvider
    }
    
    // MARK: - SlidingSyncViewRoomListObserver
    
    func didReceiveUpdate(diff: SlidingSyncViewRoomsListDiff) {
        roomListDiffPublisher.send(diff)
    }
    
    // MARK: - SlidingSyncViewStateObserver
    
    func didReceiveUpdate(newState: SlidingSyncState) {
        stateUpdatePublisher.send(newState)
    }
}

class RoomSummaryProvider: RoomSummaryProviderProtocol {
    private let slidingSyncController: SlidingSyncProtocol
    private let slidingSyncView: SlidingSyncViewProtocol
    private let roomMessageFactory = RoomMessageFactory()
    private var stateUpdatePublisher: CurrentValueSubject<SlidingSyncState, Never>?
    
    private var listUpdateObserverToken: StoppableSpawn?
    private var stateUpdateObserverToken: StoppableSpawn?
    
    private var cancellables = Set<AnyCancellable>()
        
    let callbacks = PassthroughSubject<RoomSummaryProviderCallback, Never>()
    
    private(set) var roomSummaries: [RoomSummary] = [] {
        didSet {
            callbacks.send(.updatedRoomSummaries)
        }
    }
    
    deinit {
        listUpdateObserverToken?.cancel()
        stateUpdateObserverToken?.cancel()
    }
    
    init(slidingSyncController: SlidingSyncProtocol, slidingSyncView: SlidingSyncViewProtocol) {
        self.slidingSyncView = slidingSyncView
        self.slidingSyncController = slidingSyncController
        
        let weakProvider = WeakRoomSummaryProviderWrapper(roomSummaryProvider: self)
        stateUpdatePublisher = weakProvider.stateUpdatePublisher
        
        weakProvider.roomListDiffPublisher
            .collect(.byTime(DispatchQueue.main, 0.5))
            .sink { self.updateRoomsWithDiffs($0) }
            .store(in: &cancellables)
                
        listUpdateObserverToken = slidingSyncView.observeRoomList(observer: weakProvider)
        stateUpdateObserverToken = slidingSyncView.observeState(observer: weakProvider)
    }
    
    func updateRoomsWithIdentifiers(_ identifiers: [String]) {
        guard stateUpdatePublisher?.value == .live else {
            return
        }
        
        var changes = [CollectionDifference<RoomSummary>.Change]()
        for identifier in identifiers {
            guard let oldSummary = roomSummaries.first(where: { $0.id == identifier }),
                  let index = roomSummaries.firstIndex(where: { $0.id == identifier }) else {
                continue
            }
            
            let newSummary = buildRoomSummaryForIdentifier(identifier)
            
            changes.append(.remove(offset: index, element: oldSummary, associatedWith: nil))
            changes.append(.insert(offset: index, element: newSummary, associatedWith: nil))
        }
        
        guard let diff = CollectionDifference(changes) else {
            MXLog.error("Failed creating diff from changes: \(changes)")
            return
        }
        
        guard let newSummaries = roomSummaries.applying(diff) else {
            MXLog.error("Failed applying diff: \(diff)")
            return
        }
        
        roomSummaries = newSummaries
    }
    
    // MARK: - Private
    
    fileprivate func updateRoomsWithDiffs(_ diffs: [SlidingSyncViewRoomsListDiff]) {
        roomSummaries = diffs
            .compactMap { buildDiffFrom($0) }
            .reduce(roomSummaries) { $0.applying($1) ?? $0 }
    }
    
    private func buildEmptyRoomSummary(forIdentifier identifier: String = UUID().uuidString) -> RoomSummary {
        RoomSummary(id: identifier,
                    name: "",
                    isDirect: false,
                    avatarURLString: nil,
                    lastMessage: nil,
                    unreadNotificationCount: 0)
    }
    
    private func buildRoomSummaryForIdentifier(_ identifier: String) -> RoomSummary {
        guard let room = try? slidingSyncController.getRoom(roomId: identifier) else {
            MXLog.error("Failed finding room with id: \(identifier)")
            return buildEmptyRoomSummary(forIdentifier: identifier)
        }
        
        var lastMessage: RoomMessageProtocol?
        if let message = room.latestRoomMessage() {
            lastMessage = roomMessageFactory.buildRoomMessageFrom(EventTimelineItem(item: message))
        }
               
        return RoomSummary(id: room.roomId(),
                           name: room.name() ?? room.roomId(),
                           isDirect: room.isDm() ?? false,
                           avatarURLString: room.fullRoom()?.avatarUrl(),
                           lastMessage: lastMessage,
                           unreadNotificationCount: UInt(room.unreadNotifications().notificationCount()))
    }
    
    private func buildSummaryForRoomListEntry(_ entry: RoomListEntry) -> RoomSummary {
        switch entry {
        case .empty:
            return buildEmptyRoomSummary()
        case .filled(let roomId):
            return buildRoomSummaryForIdentifier(roomId)
        case .invalidated(let roomId):
            return buildRoomSummaryForIdentifier(roomId)
        }
    }
    
    // swiftlint:disable cyclomatic_complexity
    private func buildDiffFrom(_ diff: SlidingSyncViewRoomsListDiff) -> CollectionDifference<RoomSummary>? {
        switch diff {
        case .push(let value), .updateAt(_, let value), .insertAt(_, let value):
            switch value {
            case .invalidated:
                return nil
            default:
                break
            }
        default:
            break
        }
        
        var changes = [CollectionDifference<RoomSummary>.Change]()
        
        switch diff {
        case .push(value: let value):
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: Int(roomSummaries.count), element: summary, associatedWith: nil))
        case .updateAt(let index, let value):
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .insertAt(let index, let value):
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .move(let oldIndex, let newIndex):
            let summary = roomSummaries[Int(oldIndex)]
            changes.append(.remove(offset: Int(oldIndex), element: summary, associatedWith: nil))
            changes.append(.insert(offset: Int(newIndex), element: summary, associatedWith: nil))
        case .removeAt(let index):
            let summary = roomSummaries[Int(index)]
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
        case .replace(let values):
            for (index, summary) in roomSummaries.enumerated() {
                changes.append(.remove(offset: index, element: summary, associatedWith: nil))
            }
            
            values
                .reversed()
                .map { buildSummaryForRoomListEntry($0) }
                .forEach { summary in
                    changes.append(.insert(offset: 0, element: summary, associatedWith: nil))
                }
        }
        
        return CollectionDifference(changes)
    }
    // swiftlint:enable cyclomatic_complexity
}
