//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

class RoomTimelineProvider: RoomTimelineProviderProtocol {
    private var cancellables = Set<AnyCancellable>()
    private let serialDispatchQueue: DispatchQueue
    
    private var roomTimelineObservationToken: TaskHandle?

    private let paginationStateSubject = CurrentValueSubject<PaginationState, Never>(.initial)
    var paginationState: PaginationState {
        paginationStateSubject.value
    }

    private let itemProxiesSubject: CurrentValueSubject<[TimelineItemProxy], Never>
    private(set) var itemProxies: [TimelineItemProxy] = [] {
        didSet {
            itemProxiesSubject.send(itemProxies)
        }
    }

    var updatePublisher: AnyPublisher<([TimelineItemProxy], PaginationState), Never> {
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
        roomTimelineObservationToken?.cancel()
    }

    init(timeline: Timeline, kind: TimelineKind, paginationStatePublisher: AnyPublisher<PaginationState, Never>) {
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomtimelineprovider", qos: .utility)
        itemProxiesSubject = CurrentValueSubject<[TimelineItemProxy], Never>([])
        self.kind = kind
        
        paginationStatePublisher
            .sink { [weak self] in
                self?.paginationStateSubject.send($0)
            }
            .store(in: &cancellables)
        
        Task {
            roomTimelineObservationToken = await timeline.addListener(listener: RoomTimelineListener { [weak self] timelineDiffs in
                self?.serialDispatchQueue.sync {
                    self?.updateItemsWithDiffs(timelineDiffs)
                }
            })
        }
    }
    
    /// A continuation to signal whether the initial timeline items have been loaded and processed.
    private var hasLoadedInitialItemsContinuation: CheckedContinuation<Void, Never>?
    /// A method that allows `await`ing the first update of timeline items from the listener, as the items
    /// aren't added directly to the provider upon initialisation and may take some time to come in.
    func waitForInitialItems() async {
        guard itemProxies.isEmpty else { return }
        return await withCheckedContinuation { continuation in
            hasLoadedInitialItemsContinuation = continuation
        }
    }
    
    // MARK: - Private
    
    private func updateItemsWithDiffs(_ diffs: [TimelineDiff]) {
        let span = MXLog.createSpan("process_timeline_list_diffs")
        span.enter()
        defer {
            span.exit()
        }
        
        itemProxies = diffs.reduce(itemProxies) { currentItems, diff in
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
        
        if let hasLoadedInitialItemsContinuation {
            hasLoadedInitialItemsContinuation.resume()
            self.hasLoadedInitialItemsContinuation = nil
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    private func buildDiff(from diff: TimelineDiff, on itemProxies: [TimelineItemProxy]) -> CollectionDifference<TimelineItemProxy>? {
        var changes = [CollectionDifference<TimelineItemProxy>.Change]()
        
        switch diff.change() {
        case .append:
            guard let items = diff.append() else { fatalError() }

            for (index, item) in items.enumerated() {
                // Add logging for append case
                MXLog.debug("Append: Creating TimelineItemProxy for item type: \(type(of: item))")
                
                let itemProxy = TimelineItemProxy(item: item)
                
                // Check if it's an event timeline item
                if case .event(let eventProxy) = itemProxy {
                    if let messageContent = eventProxy.content as? MessageContent {
                        // Log message type
                        let msgTypeString: String
                        switch messageContent.msgType {
                        case .text: msgTypeString = "text"
                        case .image: msgTypeString = "image"
                        case .video: msgTypeString = "video"
                        case .file: msgTypeString = "file"
                        case .notice: msgTypeString = "notice"
                        case .emote: msgTypeString = "emote"
                        case .audio: msgTypeString = "audio"
                        case .location: msgTypeString = "location"
                        case .rawStt: msgTypeString = "rawStt"
                        case .refinedStt: msgTypeString = "refinedStt"
                        case .other: msgTypeString = "other"
                        }
                        MXLog.debug("Append: Message type enum case: \(msgTypeString)")
                    }
                }
                
                if itemProxy.isMembershipChange {
                    membershipChangeSubject.send(())
                }
                
                changes.append(.insert(offset: Int(itemProxies.count) + index, element: itemProxy, associatedWith: nil))
            }
        case .clear:
            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }
        case .insert:
            guard let update = diff.insert() else { fatalError() }

            let itemProxy = TimelineItemProxy(item: update.item)
            changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
        case .popBack:
            guard let itemProxy = itemProxies.last else { fatalError() }

            changes.append(.remove(offset: itemProxies.count - 1, element: itemProxy, associatedWith: nil))
        case .popFront:
            guard let itemProxy = itemProxies.first else { fatalError() }

            changes.append(.remove(offset: 0, element: itemProxy, associatedWith: nil))
        case .pushBack:
            guard let item = diff.pushBack() else { fatalError() }
            
            // Add logging to see what kind of timeline items we're getting from Rust SDK
            MXLog.debug("PushBack: Creating TimelineItemProxy for item type: \(type(of: item))")
            
            // Create a TimelineItemProxy to examine its properties
            let tempProxy = TimelineItemProxy(item: item)
            
            // Log the type of proxy created
            MXLog.debug("PushBack: Created proxy type: \(type(of: tempProxy))")
            
            // Check if it's an event timeline item
            if case .event(let eventProxy) = tempProxy {
                MXLog.debug("PushBack: Event timeline item with content type: \(String(describing: type(of: eventProxy.content)))")
                MXLog.debug("PushBack: Event timeline item content: \(String(describing: eventProxy.content))")
                
                // Check if it's a message content
                if let messageContent = eventProxy.content as? MessageContent {
                    MXLog.debug("PushBack: Message content msgType: \(messageContent.msgType)")
                    
                    // Log more details about the message type
                    let msgTypeString: String
                    switch messageContent.msgType {
                    case .text: msgTypeString = "text"
                    case .image: msgTypeString = "image"
                    case .video: msgTypeString = "video"
                    case .file: msgTypeString = "file"
                    case .notice: msgTypeString = "notice"
                    case .emote: msgTypeString = "emote"
                    case .audio: msgTypeString = "audio"
                    case .location: msgTypeString = "location"
                    case .rawStt: msgTypeString = "rawStt"
                    case .refinedStt: msgTypeString = "refinedStt"
                    case .other: msgTypeString = "other"
                    }
                    MXLog.debug("PushBack: Message type enum case: \(msgTypeString)")
                } else {
                    MXLog.debug("PushBack: Content is not a MessageContent")
                }
            } else {
                MXLog.debug("PushBack: Not an event timeline item, but \(tempProxy)")
            }
            
            let itemProxy = TimelineItemProxy(item: item)
            
            if itemProxy.isMembershipChange {
                membershipChangeSubject.send(())
            }
            
            changes.append(.insert(offset: Int(itemProxies.count), element: itemProxy, associatedWith: nil))
        case .pushFront:
            guard let item = diff.pushFront() else { fatalError() }

            let itemProxy = TimelineItemProxy(item: item)
            changes.append(.insert(offset: 0, element: itemProxy, associatedWith: nil))
        case .remove:
            guard let index = diff.remove() else { fatalError() }

            let itemProxy = itemProxies[Int(index)]

            changes.append(.remove(offset: Int(index), element: itemProxy, associatedWith: nil))
        case .reset:
            guard let items = diff.reset() else { fatalError() }

            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }

            for (index, timelineItem) in items.enumerated() {
                // Add logging for reset case
                MXLog.debug("Reset: Creating TimelineItemProxy for item type: \(type(of: timelineItem))")
                
                // Create proxy to examine
                let itemProxy = TimelineItemProxy(item: timelineItem)
                
                // Log the type of proxy created
                MXLog.debug("Reset: Created proxy type: \(type(of: itemProxy))")
                
                // Check if it's an event timeline item
                if case .event(let eventProxy) = itemProxy {
                    MXLog.debug("Reset: Event timeline item with content type: \(String(describing: type(of: eventProxy.content)))")
                    MXLog.debug("Reset: Event timeline item content: \(String(describing: eventProxy.content))")
                    
                    if let messageContent = eventProxy.content as? MessageContent {
                        // Log message type
                        MXLog.debug("Reset: Message content msgType: \(messageContent.msgType)")
                        
                        let msgTypeString: String
                        switch messageContent.msgType {
                        case .text: msgTypeString = "text"
                        case .image: msgTypeString = "image"
                        case .video: msgTypeString = "video"
                        case .file: msgTypeString = "file"
                        case .notice: msgTypeString = "notice"
                        case .emote: msgTypeString = "emote"
                        case .audio: msgTypeString = "audio"
                        case .location: msgTypeString = "location"
                        case .rawStt: msgTypeString = "rawStt"
                        case .refinedStt: msgTypeString = "refinedStt"
                        case .other: msgTypeString = "other"
                        }
                        MXLog.debug("Reset: Message type enum case: \(msgTypeString)")
                    } else {
                        MXLog.debug("Reset: Content is not a MessageContent")
                    }
                } else {
                    MXLog.debug("Reset: Not an event timeline item, but \(itemProxy)")
                }
                
                changes.append(.insert(offset: index, element: itemProxy, associatedWith: nil))
            }
        case .set:
            guard let update = diff.set() else { fatalError() }

            let itemProxy = TimelineItemProxy(item: update.item)
            changes.append(.remove(offset: Int(update.index), element: itemProxy, associatedWith: nil))
            changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
        case .truncate:
            break
        }
        
        return CollectionDifference(changes)
    }
}

private extension TimelineItemProxy {
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

private extension VirtualTimelineItem {
    var description: String {
        switch self {
        case .dayDivider(let timestamp):
            return "DayDiviver(\(timestamp))"
        case .readMarker:
            return "ReadMarker"
        }
    }
}

private final class RoomTimelineListener: TimelineListener {
    private let onUpdateClosure: ([TimelineDiff]) -> Void
   
    init(_ onUpdateClosure: @escaping ([TimelineDiff]) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(diff: [TimelineDiff]) {
        onUpdateClosure(diff)
    }
}
