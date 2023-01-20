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

private class RoomTimelineListener: TimelineListener {
    let itemsUpdatePublisher = PassthroughSubject<TimelineDiff, Never>()
    
    func onUpdate(update: TimelineDiff) {
        itemsUpdatePublisher.send(update)
    }
}

class RoomTimelineProvider: RoomTimelineProviderProtocol {
    private let roomProxy: RoomProxyProtocol
    private var cancellables = Set<AnyCancellable>()
    private let serialDispatchQueue: DispatchQueue
    
    let itemsPublisher = CurrentValueSubject<[TimelineItemProxy], Never>([])
    
    private var itemProxies: [TimelineItemProxy] {
        didSet {
            itemsPublisher.send(itemProxies)
        }
    }
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomtimelineprovider")
        itemProxies = []

        Task {
            let roomTimelineListener = RoomTimelineListener()
            
            roomTimelineListener
                .itemsUpdatePublisher
                .collect(.byTime(serialDispatchQueue, 0.025))
                .sink { [weak self] in self?.updateItemsWithDiffs($0) }
                .store(in: &cancellables)
            
            switch await roomProxy.addTimelineListener(listener: roomTimelineListener) {
            case .failure:
                let roomID = await roomProxy.id
                MXLog.error("Failed adding timeline listener on room with identifier: \(roomID)")
            default:
                break
            }
        }
    }
    
    // MARK: - Private
    
    private func updateItemsWithDiffs(_ diffs: [TimelineDiff]) {
        MXLog.verbose("Received timeline diff")
        
        itemProxies = diffs
            .reduce(itemProxies) { currentItems, diff in
                guard let collectionDiff = buildDiff(from: diff, on: currentItems) else {
                    MXLog.error("Failed building CollectionDifference from \(diff)")
                    return currentItems
                }
                
                guard let updatedItems = currentItems.applying(collectionDiff) else {
                    MXLog.error("Failed applying diff: \(collectionDiff)")
                    return currentItems
                }
                
                MXLog.verbose("Applied diff \(collectionDiff), new count: \(updatedItems.count)")
                
                return updatedItems
            }
        
        MXLog.verbose("Finished applying diff")
    }
     
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func buildDiff(from diff: TimelineDiff, on itemProxies: [TimelineItemProxy]) -> CollectionDifference<TimelineItemProxy>? {
        var changes = [CollectionDifference<TimelineItemProxy>.Change]()
        
        switch diff.change() {
        case .push:
            guard let item = diff.push() else {
                fatalError()
            }
            
            MXLog.verbose("Push")
            let itemProxy = TimelineItemProxy(item: item)
            changes.append(.insert(offset: Int(itemProxies.count), element: itemProxy, associatedWith: nil))
        case .updateAt:
            guard let update = diff.updateAt() else {
                fatalError()
            }
            
            MXLog.verbose("Update \(update.index), current total count: \(itemProxies.count)")
            let itemProxy = TimelineItemProxy(item: update.item)
            changes.append(.remove(offset: Int(update.index), element: itemProxy, associatedWith: nil))
            changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
        case .insertAt:
            guard let update = diff.insertAt() else {
                fatalError()
            }
            
            MXLog.verbose("Insert at \(update.index), current total count: \(itemProxies.count)")
            let itemProxy = TimelineItemProxy(item: update.item)
            changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
        case .move:
            guard let update = diff.move() else {
                fatalError()
            }
                
            MXLog.verbose("Move from: \(update.oldIndex) to: \(update.newIndex), current total count: \(itemProxies.count)")
            let itemProxy = itemProxies[Int(update.oldIndex)]
            changes.append(.remove(offset: Int(update.oldIndex), element: itemProxy, associatedWith: nil))
            changes.append(.insert(offset: Int(update.newIndex), element: itemProxy, associatedWith: nil))
        case .removeAt:
            guard let index = diff.removeAt() else {
                fatalError()
            }
            
            MXLog.verbose("Remove from: \(index), current total count: \(itemProxies.count)")
            let itemProxy = itemProxies[Int(index)]
            changes.append(.remove(offset: Int(index), element: itemProxy, associatedWith: nil))
        case .replace:
            guard let items = diff.replace() else {
                fatalError()
            }
            
            MXLog.verbose("Replace all items with new count: \(items.count), current total count: \(itemProxies.count)")
            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }
            
            for (index, item) in items.enumerated() {
                changes.append(.insert(offset: index, element: TimelineItemProxy(item: item), associatedWith: nil))
            }
        case .clear:
            MXLog.verbose("Clear all items, current total count: \(itemProxies.count)")
            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }
        case .pop:
            MXLog.verbose("Pop, current total count: \(itemProxies.count)")
            guard let itemProxy = itemProxies.last else {
                fatalError()
            }
            
            changes.append(.remove(offset: itemProxies.count - 1, element: itemProxy, associatedWith: nil))
        }
        
        return CollectionDifference(changes)
    }
}
