//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

import MatrixRustSDK

final class RoomDirectorySearchProxy: RoomDirectorySearchProxyProtocol {
    private let roomDirectorySearch: RoomDirectorySearchProtocol
    private let serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomdirectorysearch", qos: .default)
    
    private let resultsSubject = CurrentValueSubject<[RoomDirectorySearchResult], Never>([])
    
    var resultsPublisher: CurrentValuePublisher<[RoomDirectorySearchResult], Never> {
        resultsSubject.asCurrentValuePublisher()
    }
    
    private var results: [RoomDirectorySearchResult] {
        get { resultsSubject.value }
        set { resultsSubject.send(newValue) }
    }
    
    private let diffsPublisher = PassthroughSubject<[RoomDirectorySearchEntryUpdate], Never>()
    
    private var searchEntriesSubscription: TaskHandle?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(roomDirectorySearch: RoomDirectorySearchProtocol) {
        self.roomDirectorySearch = roomDirectorySearch
        diffsPublisher
            .receive(on: serialDispatchQueue)
            .sink { [weak self] in self?.updateResultsWithDiffs($0) }
            .store(in: &cancellables)
        
        Task {
            searchEntriesSubscription = await roomDirectorySearch.results(listener: RoomDirectorySearchEntriesListenerProxy { [weak self] updates in
                self?.diffsPublisher.send(updates)
            })
        }
    }
    
    func search(query: String?) async -> Result<Void, RoomDirectorySearchError> {
        do {
            try await roomDirectorySearch.search(filter: query, batchSize: 50)
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
    
    private func updateResultsWithDiffs(_ updates: [RoomDirectorySearchEntryUpdate]) {
        results = updates.reduce(results) { currentItems, diff in
            processDiff(diff, on: currentItems)
        }
    }
    
    private func processDiff(_ diff: RoomDirectorySearchEntryUpdate, on currentItems: [RoomDirectorySearchResult]) -> [RoomDirectorySearchResult] {
        guard let collectionDiff = buildDiff(from: diff, on: currentItems) else {
            return currentItems
        }
        
        guard let updatedItems = currentItems.applying(collectionDiff) else {
            return currentItems
        }
        
        return updatedItems
    }
    
    private func buildDiff(from diff: RoomDirectorySearchEntryUpdate, on currentItems: [RoomDirectorySearchResult]) -> CollectionDifference<RoomDirectorySearchResult>? {
        var changes = [CollectionDifference<RoomDirectorySearchResult>.Change]()
        
        switch diff {
        case .append(let values):
            for (index, value) in values.enumerated() {
                let result = buildResultForRoomDescription(value)
                changes.append(.insert(offset: results.count + index, element: result, associatedWith: nil))
            }
        case .clear:
            for (index, value) in results.enumerated() {
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        case .insert(let index, let value):
            let result = buildResultForRoomDescription(value)
            changes.append(.insert(offset: Int(index), element: result, associatedWith: nil))
        case .popBack:
            guard let value = results.last else {
                fatalError()
            }
            
            changes.append(.remove(offset: results.count - 1, element: value, associatedWith: nil))
        case .popFront:
            let result = results[0]
            changes.append(.remove(offset: 0, element: result, associatedWith: nil))
        case .pushBack(let value):
            let result = buildResultForRoomDescription(value)
            changes.append(.insert(offset: results.count, element: result, associatedWith: nil))
        case .pushFront(let value):
            let result = buildResultForRoomDescription(value)
            changes.append(.insert(offset: 0, element: result, associatedWith: nil))
        case .remove(let index):
            let result = results[Int(index)]
            changes.append(.remove(offset: Int(index), element: result, associatedWith: nil))
        case .reset(let values):
            for (index, result) in results.enumerated() {
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
            for (index, value) in results.enumerated() {
                if index < length {
                    continue
                }
                
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        }
        
        return CollectionDifference(changes)
    }
    
    private func buildResultForRoomDescription(_ value: RoomDescription) -> RoomDirectorySearchResult {
        RoomDirectorySearchResult(id: value.roomId,
                                  alias: value.alias,
                                  name: value.name,
                                  topic: value.topic,
                                  avatar: .room(id: value.roomId, name: value.name, avatarURL: value.avatarUrl.flatMap(URL.init(string:))),
                                  canBeJoined: value.joinRule == .public)
    }
}

private final class RoomDirectorySearchEntriesListenerProxy: RoomDirectorySearchEntriesListener {
    private let onUpdateClosure: ([RoomDirectorySearchEntryUpdate]) -> Void
    
    func onUpdate(roomEntriesUpdate: [RoomDirectorySearchEntryUpdate]) {
        onUpdateClosure(roomEntriesUpdate)
    }
        
    init(_ onUpdateClosure: @escaping (([RoomDirectorySearchEntryUpdate]) -> Void)) {
        self.onUpdateClosure = onUpdateClosure
    }
}
