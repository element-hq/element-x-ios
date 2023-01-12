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

private class SlidingSyncViewObserver: SlidingSyncViewRoomListObserver, SlidingSyncViewStateObserver, SlidingSyncViewRoomsCountObserver {
    /// Publishes room list diffs as they come in through sliding sync
    let roomListDiffPublisher = PassthroughSubject<SlidingSyncViewRoomsListDiff, Never>()
    
    /// Publishes the current state of sliding sync, such as whether its catching up or live.
    let stateUpdatePublisher = CurrentValueSubject<SlidingSyncState, Never>(.cold)
    
    /// Publishes the number of available rooms
    let countUpdatePublisher = CurrentValueSubject<UInt, Never>(0)
        
    // MARK: - SlidingSyncViewRoomListObserver
    
    func didReceiveUpdate(diff: SlidingSyncViewRoomsListDiff) {
        MXLog.verbose("Received room diff")
        roomListDiffPublisher.send(diff)
    }
    
    // MARK: - SlidingSyncViewStateObserver
    
    func didReceiveUpdate(newState: SlidingSyncState) {
        MXLog.verbose("Updated state: \(newState)")
        stateUpdatePublisher.send(newState)
    }
    
    // MARK: - SlidingSyncViewRoomsCountObserver
    
    func didReceiveUpdate(count: UInt32) {
        MXLog.verbose("Updated room count: \(count)")
        countUpdatePublisher.send(UInt(count))
    }
}

class SlidingSyncViewProxy {
    private let slidingSync: SlidingSyncProtocol
    private let slidingSyncView: SlidingSyncViewProtocol
    
    private var listUpdateObserverToken: StoppableSpawn?
    private var stateUpdateObserverToken: StoppableSpawn?
    private var countUpdateObserverToken: StoppableSpawn?
    
    private var cancellables = Set<AnyCancellable>()
    
    let diffPublisher = PassthroughSubject<SlidingSyncViewRoomsListDiff, Never>()
    let statePublisher = PassthroughSubject<SlidingSyncState, Never>()
    let countPublisher = PassthroughSubject<UInt, Never>()
    let visibleRangeUpdatePublisher = PassthroughSubject<Void, Never>()
    
    deinit {
        listUpdateObserverToken?.cancel()
        stateUpdateObserverToken?.cancel()
        countUpdateObserverToken?.cancel()
    }
    
    init(slidingSync: SlidingSyncProtocol, slidingSyncView: SlidingSyncViewProtocol) {
        self.slidingSync = slidingSync
        self.slidingSyncView = slidingSyncView
        
        let slidingSyncViewObserver = SlidingSyncViewObserver()
        
        slidingSyncViewObserver.stateUpdatePublisher
            .subscribe(statePublisher)
            .store(in: &cancellables)
        
        slidingSyncViewObserver.countUpdatePublisher
            .subscribe(countPublisher)
            .store(in: &cancellables)
        
        slidingSyncViewObserver.roomListDiffPublisher
            .subscribe(diffPublisher)
            .store(in: &cancellables)
        
        listUpdateObserverToken = slidingSyncView.observeRoomList(observer: slidingSyncViewObserver)
        stateUpdateObserverToken = slidingSyncView.observeState(observer: slidingSyncViewObserver)
        countUpdateObserverToken = slidingSyncView.observeRoomsCount(observer: slidingSyncViewObserver)
    }
    
    func currentRoomsList() -> [RoomListEntry] {
        slidingSyncView.currentRoomsList()
    }
    
    func roomForIdentifier(_ identifier: String) throws -> SlidingSyncRoomProtocol? {
        try slidingSync.getRoom(roomId: identifier)
    }
    
    func updateVisibleRange(_ range: Range<Int>) {
        MXLog.info("Setting sliding sync view range to \(range)")
        
        slidingSyncView.setRange(start: UInt32(range.lowerBound), end: UInt32(range.upperBound))
        
        visibleRangeUpdatePublisher.send(())
    }
}
