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

class RoomTimelineProvider: RoomTimelineProviderProtocol {
    private let roomProxy: RoomProxyProtocol
    private var cancellables = Set<AnyCancellable>()
    private let serialDispatchQueue: DispatchQueue
    
    private let itemsSubject = CurrentValueSubject<[TimelineItemProxy], Never>([])
    
    var itemsPublisher: CurrentValuePublisher<[TimelineItemProxy], Never> {
        itemsSubject.asCurrentValuePublisher()
    }
    
    private var itemProxies: [TimelineItemProxy] {
        didSet {
            itemsSubject.send(itemProxies)
        }
    }
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomtimelineprovider", qos: .utility)
        itemProxies = []

        Task { @MainActor in
            roomProxy
                .updatesPublisher
                .collect(.byTime(serialDispatchQueue, 0.1))
                .sink { [weak self] in self?.updateItemsWithDiffs($0) }
                .store(in: &cancellables)
            
            switch roomProxy.registerTimelineListenerIfNeeded() {
            case .success(.none):
                MXLog.info("Listener already registered for the room: \(roomProxy.id)")
            case let .success(.some(items)):
                itemProxies = items.map(TimelineItemProxy.init)
                MXLog.info("Added timeline listener, current items (\(items.count)) : \(items.map(\.debugIdentifier))")
            case .failure:
                let roomID = roomProxy.id
                MXLog.error("Failed adding timeline listener on room with identifier: \(roomID)")
            }
        }
    }
    
    // MARK: - Private
    
    private func updateItemsWithDiffs(_ diffs: [TimelineDiff]) {
        let span = MXLog.createSpan("process_timeline_list_diffs")
        span.enter()
        defer {
            span.exit()
        }
        
        MXLog.info("Received timeline diff")
        
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
                
                return updatedItems
            }
        
        MXLog.info("Finished applying diffs, current items (\(itemProxies.count)) : \(itemProxies.map(\.debugIdentifier))")
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func buildDiff(from diff: TimelineDiff, on itemProxies: [TimelineItemProxy]) -> CollectionDifference<TimelineItemProxy>? {
        var changes = [CollectionDifference<TimelineItemProxy>.Change]()
        
        switch diff.change() {
        case .pushFront:
            guard let item = diff.pushFront() else { fatalError() }
            
            MXLog.info("Push Front: \(item.debugIdentifier)")
            let itemProxy = TimelineItemProxy(item: item)
            changes.append(.insert(offset: 0, element: itemProxy, associatedWith: nil))
        case .pushBack:
            guard let item = diff.pushBack() else { fatalError() }
            
            MXLog.info("Push Back \(item.debugIdentifier)")
            let itemProxy = TimelineItemProxy(item: item)
            changes.append(.insert(offset: Int(itemProxies.count), element: itemProxy, associatedWith: nil))
        case .insert:
            guard let update = diff.insert() else { fatalError() }
            
            MXLog.info("Insert \(update.item.debugIdentifier) at \(update.index)")
            let itemProxy = TimelineItemProxy(item: update.item)
            changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
        case .append:
            guard let items = diff.append() else { fatalError() }
            
            MXLog.info("Append \(items.map(\.debugIdentifier))")
            for (index, item) in items.enumerated() {
                changes.append(.insert(offset: Int(itemProxies.count) + index, element: TimelineItemProxy(item: item), associatedWith: nil))
            }
        case .set:
            guard let update = diff.set() else { fatalError() }
            
            MXLog.info("Set \(update.item.debugIdentifier) at index \(update.index)")
            let itemProxy = TimelineItemProxy(item: update.item)
            changes.append(.remove(offset: Int(update.index), element: itemProxy, associatedWith: nil))
            changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
        case .popFront:
            guard let itemProxy = itemProxies.first else { fatalError() }
            
            MXLog.info("Pop Front \(itemProxy.debugIdentifier)")
            
            changes.append(.remove(offset: 0, element: itemProxy, associatedWith: nil))
        case .popBack:
            guard let itemProxy = itemProxies.last else { fatalError() }
            
            MXLog.info("Pop Back \(itemProxy.debugIdentifier)")
            
            changes.append(.remove(offset: itemProxies.count - 1, element: itemProxy, associatedWith: nil))
        case .remove:
            guard let index = diff.remove() else { fatalError() }
            
            let itemProxy = itemProxies[Int(index)]
            
            MXLog.info("Remove \(itemProxy.debugIdentifier) at: \(index)")
            
            changes.append(.remove(offset: Int(index), element: itemProxy, associatedWith: nil))
        case .clear:
            MXLog.info("Clear all items")
            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }
        case .reset:
            guard let items = diff.reset() else { fatalError() }
            
            MXLog.info("Replace all items with \(items.map(\.debugIdentifier))")
            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }
            
            for (index, timelineItem) in items.enumerated() {
                changes.append(.insert(offset: index, element: TimelineItemProxy(item: timelineItem), associatedWith: nil))
            }
        }
        
        return CollectionDifference(changes)
    }
}

private extension TimelineItem {
    var debugIdentifier: String {
        if let virtualTimelineItem = asVirtual() {
            return virtualTimelineItem.debugIdentifier
        } else if let eventTimelineItem = asEvent() {
            return eventTimelineItem.uniqueIdentifier()
        }
        
        return "UnknownTimelineItem"
    }
}

private extension TimelineItemProxy {
    var debugIdentifier: String {
        switch self {
        case .event(let eventTimelineItem):
            return eventTimelineItem.item.uniqueIdentifier()
        case .virtual(let virtualTimelineItem):
            return virtualTimelineItem.debugIdentifier
        case .unknown:
            return "UnknownTimelineItem"
        }
    }
}

private extension VirtualTimelineItem {
    var debugIdentifier: String {
        switch self {
        case .dayDivider(let timestamp):
            return "DayDiviver(\(timestamp))"
        case .loadingIndicator:
            return "LoadingIndicator"
        case .readMarker:
            return "ReadMarker"
        case .timelineStart:
            return "TimelineStart"
        }
    }
}
