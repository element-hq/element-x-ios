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
    private let liveLocationShares: LiveLocationShares
    // periphery:ignore - required for instance retention in the rust codebase
    private var observationToken: TaskHandle?
    
    private let liveLocationsSubject = PassthroughSubject<[LiveLocationShare], Never>()
    var liveLocationsPublisher: AnyPublisher<[LiveLocationShare], Never> {
        liveLocationsSubject.eraseToAnyPublisher()
    }
    
    private var previousLiveLocationShares: [LiveLocationShare] = []
    
    init(liveLocationShares: LiveLocationShares) {
        self.liveLocationShares = liveLocationShares
        observationToken = liveLocationShares
            .subscribe(listener: SDKListener { [weak self] updates in
                guard let self else { return }
                
                MXLog.info("Received live location shares update")
                let updatedShares = handleLiveLocationShareUpdates(updates)
                liveLocationsSubject.send(updatedShares)
            })
    }
    
    // MARK: - Private
    
    private func handleLiveLocationShareUpdates(_ updates: [LiveLocationShareUpdate]) -> [LiveLocationShare] {
        var shares = previousLiveLocationShares
        
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
        
        previousLiveLocationShares = shares
        return shares
    }
}
