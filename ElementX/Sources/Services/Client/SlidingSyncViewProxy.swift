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

private class SlidingSyncViewObserver: SlidingSyncListRoomListObserver, SlidingSyncListStateObserver, SlidingSyncListRoomsCountObserver {
    /// Publishes room list diffs as they come in through sliding sync
    let roomListDiffPublisher = PassthroughSubject<SlidingSyncListRoomsListDiff, Never>()
    
    /// Publishes the current state of sliding sync, such as whether its catching up or live.
    let stateUpdatePublisher = CurrentValueSubject<SlidingSyncState, Never>(.notLoaded)
    
    /// Publishes the number of available rooms
    let countUpdatePublisher = CurrentValueSubject<UInt, Never>(0)
    
    private let name: String
    
    init(name: String) {
        self.name = name
    }
        
    // MARK: - SlidingSyncListRoomListObserver
    
    func didReceiveUpdate(diff: SlidingSyncListRoomsListDiff) {
        MXLog.verbose("\(name): Received room diff")
        roomListDiffPublisher.send(diff)
    }
    
    // MARK: - SlidingSyncListStateObserver
    
    func didReceiveUpdate(newState: SlidingSyncState) {
        MXLog.info("\(name): Updated state: \(newState)")
        stateUpdatePublisher.send(newState)
    }
    
    // MARK: - SlidingSyncListRoomsCountObserver
    
    func didReceiveUpdate(count: UInt32) {
        MXLog.info("\(name): Updated room count: \(count)")
        countUpdatePublisher.send(UInt(count))
    }
}

class SlidingSyncViewProxy {
    private var slidingSync: SlidingSyncProtocol!
    private let slidingSyncView: SlidingSyncListProtocol
    
    private var listUpdateObserverToken: TaskHandle?
    private var stateUpdateObserverToken: TaskHandle?
    private var countUpdateObserverToken: TaskHandle?
    
    private var cancellables = Set<AnyCancellable>()
    
    let diffPublisher = PassthroughSubject<SlidingSyncListRoomsListDiff, Never>()
    let statePublisher = PassthroughSubject<SlidingSyncState, Never>()
    let countPublisher = PassthroughSubject<UInt, Never>()
    let visibleRangeUpdatePublisher = PassthroughSubject<Void, Never>()
    
    deinit {
        listUpdateObserverToken?.cancel()
        stateUpdateObserverToken?.cancel()
        countUpdateObserverToken?.cancel()
    }
    
    init(slidingSyncView: SlidingSyncListProtocol, name: String) {
        self.slidingSyncView = slidingSyncView
        
        let slidingSyncViewObserver = SlidingSyncViewObserver(name: name)
        
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
    
    func setSlidingSync(slidingSync: SlidingSyncProtocol) {
        self.slidingSync = slidingSync
    }
    
    func currentRoomsList() -> [RoomListEntry] {
        slidingSyncView.currentRoomList()
    }
    
    func roomForIdentifier(_ identifier: String) throws -> SlidingSyncRoomProtocol? {
        try slidingSync.getRoom(roomId: identifier)
    }
    
    func updateVisibleRange(_ range: Range<Int>, timelineLimit: UInt) {
        MXLog.info("Setting sliding sync view range to \(range), timeline limit: \(timelineLimit)")
        
        do {
            try slidingSyncView.setRange(start: UInt32(range.lowerBound), end: UInt32(range.upperBound))
            slidingSyncView.setTimelineLimit(value: UInt32(timelineLimit))
            
            visibleRangeUpdatePublisher.send(())
        } catch {
            MXLog.error("Failed setting sliding sync list range with error: \(error)")
        }
    }
}
