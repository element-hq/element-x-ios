//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

class TimelineItemProvider: TimelineItemProviderProtocol {
    private var cancellables = Set<AnyCancellable>()
    
    private var roomTimelineObservationToken: TaskHandle?
    
    /// Bridge from the SDK's synchronous callback into Swift Concurrency. Yielding is safe from any
    /// thread; a single long-lived `for await` consumer (set up in `init`) applies the diffs on the
    /// main actor in FIFO order, guaranteeing one in-flight update at a time.
    private let diffContinuation: AsyncStream<[TimelineDiff]>.Continuation
    
    private let paginationStateSubject = CurrentValueSubject<TimelinePaginationState, Never>(.initial)
    var paginationState: TimelinePaginationState {
        paginationStateSubject.value
    }
    
    private let itemProxiesSubject: CurrentValueSubject<[TimelineItemProxy], Never>
    private(set) var itemProxies: [TimelineItemProxy] = [] {
        didSet {
            itemProxiesSubject.send(itemProxies)
        }
    }
    
    var updatePublisher: AnyPublisher<([TimelineItemProxy], TimelinePaginationState), Never> {
        itemProxiesSubject
            .combineLatest(paginationStateSubject)
            .eraseToAnyPublisher()
    }
    
    let kind: TimelineKind
    
    private let membershipChangeSubject = PassthroughSubject<Void, Never>()
    var membershipChangePublisher: AnyPublisher<Void, Never> {
        membershipChangeSubject
            .eraseToAnyPublisher()
    }
    
    deinit {
        diffContinuation.finish()
        roomTimelineObservationToken?.cancel()
    }
    
    init(timeline: Timeline, kind: TimelineKind, paginationStatePublisher: AnyPublisher<TimelinePaginationState, Never>) {
        itemProxiesSubject = CurrentValueSubject<[TimelineItemProxy], Never>([])
        self.kind = kind
        
        let (diffStream, diffContinuation) = AsyncStream<[TimelineDiff]>.makeStream()
        self.diffContinuation = diffContinuation
        
        paginationStatePublisher
            .sink { [weak self] in
                self?.paginationStateSubject.send($0)
            }
            .store(in: &cancellables)
        
        // `for await` guarantees FIFO ordering and that only one diff is being applied at a time.
        // The stream also allows to handle the sendable items in the listener.
        Task { [weak self] in
            for await diffs in diffStream {
                await self?.applyDiffs(diffs)
            }
        }
        
        Task {
            roomTimelineObservationToken = await timeline.addListener(listener: SDKListener { diffs in
                diffContinuation.yield(diffs)
            })
        }
    }
    
    // MARK: - Private
    
    private func applyDiffs(_ diffs: [TimelineDiff]) async {
        MXLog.verbose("Received diffs: \(diffs)")
        
        // Building the item proxies and computing/applying the CollectionDifference can be
        // expensive, so run it off the main actor and only hop back to publish the result.
        let result = await Self.processDiffs(diffs, on: itemProxies, spanName: "process_timeline_list_diffs:\(kind)")
        
        itemProxies = result.itemProxies
        
        if result.hasMembershipChange {
            membershipChangeSubject.send(())
        }
    }
    
    @concurrent
    private static func processDiffs(_ diffs: [TimelineDiff],
                                     on currentItems: [TimelineItemProxy],
                                     spanName: String) async -> (itemProxies: [TimelineItemProxy], hasMembershipChange: Bool) {
        let span = MXLog.createSpan(spanName)
        span.enter()
        defer {
            span.exit()
        }
        
        var hasMembershipChange = false
        
        let itemProxies = diffs.reduce(currentItems) { currentItems, diff in
            guard let collectionDiff = buildDiff(from: diff, on: currentItems, hasMembershipChange: &hasMembershipChange) else {
                MXLog.error("Failed building CollectionDifference from \(diff)")
                return currentItems
            }
            
            guard let updatedItems = currentItems.applying(collectionDiff) else {
                MXLog.error("Failed applying diff: \(collectionDiff)")
                return currentItems
            }
            
            return updatedItems
        }
        
        return (itemProxies, hasMembershipChange)
    }
    
    private nonisolated static func buildDiff(from diff: TimelineDiff, on itemProxies: [TimelineItemProxy], hasMembershipChange: inout Bool) -> CollectionDifference<TimelineItemProxy>? {
        var changes = [CollectionDifference<TimelineItemProxy>.Change]()
        
        switch diff {
        case .append(let items):
            for (index, item) in items.enumerated() {
                let itemProxy = TimelineItemProxy(item: item)
                
                if itemProxy.isMembershipChange {
                    hasMembershipChange = true
                }
                
                changes.append(.insert(offset: Int(itemProxies.count) + index, element: itemProxy, associatedWith: nil))
            }
        case .clear:
            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }
        case .insert(let index, let item):
            let itemProxy = TimelineItemProxy(item: item)
            changes.append(.insert(offset: Int(index), element: itemProxy, associatedWith: nil))
        case .popBack:
            guard let itemProxy = itemProxies.last else { fatalError() }
            
            changes.append(.remove(offset: itemProxies.count - 1, element: itemProxy, associatedWith: nil))
        case .popFront:
            guard let itemProxy = itemProxies.first else { fatalError() }
            
            changes.append(.remove(offset: 0, element: itemProxy, associatedWith: nil))
        case .pushBack(let item):
            let itemProxy = TimelineItemProxy(item: item)
            
            if itemProxy.isMembershipChange {
                hasMembershipChange = true
            }
            
            changes.append(.insert(offset: Int(itemProxies.count), element: itemProxy, associatedWith: nil))
        case .pushFront(let item):
            let itemProxy = TimelineItemProxy(item: item)
            
            changes.append(.insert(offset: 0, element: itemProxy, associatedWith: nil))
        case .remove(let index):
            let itemProxy = itemProxies[Int(index)]
            
            changes.append(.remove(offset: Int(index), element: itemProxy, associatedWith: nil))
        case .reset(let items):
            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }
            
            for (index, timelineItem) in items.enumerated() {
                changes.append(.insert(offset: index, element: TimelineItemProxy(item: timelineItem), associatedWith: nil))
            }
        case .set(let index, let item):
            let itemProxy = TimelineItemProxy(item: item)
            changes.append(.remove(offset: Int(index), element: itemProxy, associatedWith: nil))
            changes.append(.insert(offset: Int(index), element: itemProxy, associatedWith: nil))
        case .truncate:
            break
        }
        
        return CollectionDifference(changes)
    }
}

private nonisolated extension TimelineItemProxy {
    var isMembershipChange: Bool {
        switch self {
        case .event(let eventTimelineItemProxy):
            switch eventTimelineItemProxy.content {
            case .roomMembership:
                true
            default:
                false
            }
        case .virtual, .unknown:
            false
        }
    }
}

extension TimelineDiff: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .append(let items):
            return "Append(\(items.count))"
        case .clear:
            return "Clear"
        case .insert:
            return "Insert"
        case .set(let index, _):
            return "Set(\(index))"
        case .remove(let index):
            return "Remove(\(index))"
        case .pushBack:
            return "PushBack"
        case .pushFront:
            return "PushFront"
        case .popBack:
            return "PopBack"
        case .popFront:
            return "PopFront"
        case .truncate(let length):
            return "Truncate(\(length))"
        case .reset(let items):
            return "Reset(\(items.count)@\(items.startIndex)-\(items.endIndex))"
        }
    }
}
