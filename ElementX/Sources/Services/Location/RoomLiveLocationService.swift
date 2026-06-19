//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

final class RoomLiveLocationService: RoomLiveLocationServiceProtocol {
    // periphery:ignore - required for instance retention in the rust codebase
    private let liveLocationsObserver: LiveLocationsObserver
    // periphery:ignore - required for instance retention in the rust codebase
    private var observationToken: TaskHandle?
    
    private let liveLocationsSubject = CurrentValueSubject<[LiveLocationShare], Never>([])
    var liveLocationsPublisher: CurrentValuePublisher<[LiveLocationShare], Never> {
        liveLocationsSubject.asCurrentValuePublisher()
    }
    
    /// Bridge from the SDK's synchronous callback into Swift Concurrency. Yielding is safe from any
    /// thread; a single long-lived `for await` consumer (set up in `init`) applies the updates on the
    /// main actor in FIFO order, guaranteeing one in-flight update at a time.
    private let updatesContinuation: AsyncStream<[LiveLocationShareUpdate]>.Continuation
    
    deinit {
        updatesContinuation.finish()
    }
    
    init(liveLocationsObserver: LiveLocationsObserver) {
        self.liveLocationsObserver = liveLocationsObserver
        
        let (updatesStream, updatesContinuation) = AsyncStream<[LiveLocationShareUpdate]>.makeStream()
        self.updatesContinuation = updatesContinuation
        
        Task { [weak self] in
            for await updates in updatesStream {
                guard let self else { return }
                
                MXLog.info("Received live location shares update")
                let updatedShares = handleLiveLocationShareUpdates(updates)
                liveLocationsSubject.send(updatedShares)
            }
        }
        
        observationToken = liveLocationsObserver
            .subscribe(listener: SDKListener { updates in
                updatesContinuation.yield(updates)
            })
    }
    
    // MARK: - Private
    
    private func handleLiveLocationShareUpdates(_ updates: [LiveLocationShareUpdate]) -> [LiveLocationShare] {
        var shares = liveLocationsSubject.value
        
        for update in updates {
            switch update {
            case .append(let values):
                shares.append(contentsOf: values.map(LiveLocationShare.init))
            case .clear:
                shares.removeAll()
            case .pushFront(let value):
                shares.insert(LiveLocationShare(liveLocationShare: value), at: 0)
            case .pushBack(let value):
                shares.append(LiveLocationShare(liveLocationShare: value))
            case .popFront:
                shares.removeFirst()
            case .popBack:
                shares.removeLast()
            case .insert(let index, let value):
                shares.insert(LiveLocationShare(liveLocationShare: value), at: Int(index))
            case .set(let index, let value):
                shares[Int(index)] = LiveLocationShare(liveLocationShare: value)
            case .remove(let index):
                shares.remove(at: Int(index))
            case .truncate(let length):
                shares.removeSubrange(Int(length)..<shares.count)
            case .reset(let values):
                shares = values.map(LiveLocationShare.init)
            }
        }
        
        return shares
    }
}
