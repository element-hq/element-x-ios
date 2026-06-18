//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

final class RoomDirectorySearchProxy: RoomDirectorySearchProxyProtocol {
    private let roomDirectorySearch: RoomDirectorySearchProtocol
    
    private let resultsSubject = CurrentValueSubject<[RoomDirectorySearchResult], Never>([])
    
    var resultsPublisher: CurrentValuePublisher<[RoomDirectorySearchResult], Never> {
        resultsSubject.asCurrentValuePublisher()
    }
    
    private var results: [RoomDirectorySearchResult] {
        get { resultsSubject.value }
        set { resultsSubject.send(newValue) }
    }
    
    /// Bridge from the SDK's synchronous callback into Swift Concurrency. Yielding is safe from any
    /// thread; a single long-lived `for await` consumer (set up in `init`) applies the updates on the
    /// main actor in FIFO order, guaranteeing one in-flight update at a time.
    private let updatesContinuation: AsyncStream<[RoomDirectorySearchEntryUpdate]>.Continuation
    
    private var searchEntriesSubscription: TaskHandle?
    
    deinit {
        updatesContinuation.finish()
    }
    
    init(roomDirectorySearch: RoomDirectorySearchProtocol) {
        self.roomDirectorySearch = roomDirectorySearch
        
        let (updatesStream, updatesContinuation) = AsyncStream<[RoomDirectorySearchEntryUpdate]>.makeStream()
        self.updatesContinuation = updatesContinuation
        
        Task { [weak self] in
            for await updates in updatesStream {
                await self?.updateResultsWithDiffs(updates)
            }
        }
        
        Task {
            searchEntriesSubscription = await roomDirectorySearch.results(listener: SDKListener { updates in
                updatesContinuation.yield(updates)
            })
        }
    }
    
    func search(query: String?) async -> Result<Void, RoomDirectorySearchError> {
        do {
            try await roomDirectorySearch.search(filter: query, batchSize: 50, viaServerName: nil)
            return .success(())
        } catch {
            return .failure(.searchFailed)
        }
    }
    
    func nextPage() async -> Result<Void, RoomDirectorySearchError> {
        do {
            try await roomDirectorySearch.nextPage()
            return .success(())
        } catch {
            return .failure(.nextPageQueryFailed)
        }
    }
    
    private func updateResultsWithDiffs(_ updates: [RoomDirectorySearchEntryUpdate]) async {
        // Building the results and applying the CollectionDifference can be expensive for large
        // search batches, so compute off the main actor and only hop back to publish.
        results = await Self.updatedResults(from: updates, on: results)
    }
    
    @concurrent
    private static func updatedResults(from updates: [RoomDirectorySearchEntryUpdate],
                                       on currentResults: [RoomDirectorySearchResult]) async -> [RoomDirectorySearchResult] {
        updates.reduce(currentResults) { currentItems, diff in
            processDiff(diff, on: currentItems)
        }
    }
    
    private nonisolated static func processDiff(_ diff: RoomDirectorySearchEntryUpdate, on currentItems: [RoomDirectorySearchResult]) -> [RoomDirectorySearchResult] {
        guard let collectionDiff = buildDiff(from: diff, on: currentItems) else {
            return currentItems
        }
        
        guard let updatedItems = currentItems.applying(collectionDiff) else {
            return currentItems
        }
        
        return updatedItems
    }
    
    private nonisolated static func buildDiff(from diff: RoomDirectorySearchEntryUpdate, on currentItems: [RoomDirectorySearchResult]) -> CollectionDifference<RoomDirectorySearchResult>? {
        var changes = [CollectionDifference<RoomDirectorySearchResult>.Change]()
        
        switch diff {
        case .append(let values):
            for (index, value) in values.enumerated() {
                let result = buildResultForRoomDescription(value)
                changes.append(.insert(offset: currentItems.count + index, element: result, associatedWith: nil))
            }
        case .clear:
            for (index, value) in currentItems.enumerated() {
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        case .insert(let index, let value):
            let result = buildResultForRoomDescription(value)
            changes.append(.insert(offset: Int(index), element: result, associatedWith: nil))
        case .popBack:
            guard let value = currentItems.last else {
                fatalError()
            }
            
            changes.append(.remove(offset: currentItems.count - 1, element: value, associatedWith: nil))
        case .popFront:
            let result = currentItems[0]
            changes.append(.remove(offset: 0, element: result, associatedWith: nil))
        case .pushBack(let value):
            let result = buildResultForRoomDescription(value)
            changes.append(.insert(offset: currentItems.count, element: result, associatedWith: nil))
        case .pushFront(let value):
            let result = buildResultForRoomDescription(value)
            changes.append(.insert(offset: 0, element: result, associatedWith: nil))
        case .remove(let index):
            let result = currentItems[Int(index)]
            changes.append(.remove(offset: Int(index), element: result, associatedWith: nil))
        case .reset(let values):
            for (index, result) in currentItems.enumerated() {
                changes.append(.remove(offset: index, element: result, associatedWith: nil))
            }
            
            for (index, value) in values.enumerated() {
                changes.append(.insert(offset: index, element: buildResultForRoomDescription(value), associatedWith: nil))
            }
        case .set(let index, let value):
            let result = buildResultForRoomDescription(value)
            changes.append(.remove(offset: Int(index), element: result, associatedWith: nil))
            changes.append(.insert(offset: Int(index), element: result, associatedWith: nil))
        case .truncate(let length):
            for (index, value) in currentItems.enumerated() {
                if index < length {
                    continue
                }
                
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        }
        
        return CollectionDifference(changes)
    }
    
    private nonisolated static func buildResultForRoomDescription(_ value: RoomDescription) -> RoomDirectorySearchResult {
        RoomDirectorySearchResult(id: value.roomId,
                                  alias: value.alias,
                                  name: value.name,
                                  topic: value.topic,
                                  avatar: .room(id: value.roomId, name: value.name, avatarURL: value.avatarUrl.flatMap(URL.init(string:))),
                                  canBeJoined: value.joinRule == .public || value.joinRule == .knock)
    }
}
