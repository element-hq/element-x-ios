//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all

import Combine
import Foundation
import MatrixRustSDK

/// A ``TimelineItemProviderMock`` subclass that optionally listens for ``UITestsSignalling`` signals
/// to drive pagination and incoming message simulation.
@MainActor
class SignallingTimelineItemProviderMock: TimelineItemProviderMock, @unchecked Sendable {
    private let stateSubject: CurrentValueSubject<([TimelineItemProxy], TimelinePaginationState), Never>
    
    /// An array of item arrays that will be prepended in order on each paginate signal.
    var backPaginationResponses: [[TimelineItemProxy]] = []
    /// An array of items that will be appended in order on each incoming message signal.
    var incomingItems: [TimelineItemProxy] = []
    
    private var client: UITestsSignalling.Client?
    private var signalCancellable: AnyCancellable?
    
    override nonisolated init() {
        fatalError("Use init(itemProxies:paginationState:listenForSignals:) instead.")
    }
    
    init(itemProxies: [TimelineItemProxy] = [],
         paginationState: TimelinePaginationState = .init(backward: .idle, forward: .endReached),
         listenForSignals: Bool = false) {
        stateSubject = CurrentValueSubject((itemProxies, paginationState))
        
        super.init()
        
        self.itemProxies = itemProxies
        
        self.paginationState = paginationState
        kind = .live
        updatePublisher = stateSubject.eraseToAnyPublisher()
        membershipChangePublisher = Empty().eraseToAnyPublisher()
        
        guard listenForSignals else { return }
        
        do {
            let client = try UITestsSignalling.Client(mode: .app)
            signalCancellable = client.signals.sink { [weak self] signal in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    do {
                        try self.handleSignal(signal)
                    } catch {
                        MXLog.error(error.localizedDescription)
                    }
                }
            }
            self.client = client
        } catch {
            fatalError("Failure setting up signalling: \(error)")
        }
    }
    
    // MARK: - Private
    
    private func handleSignal(_ signal: UITestsSignal) throws {
        switch signal {
        case .timeline(.paginate):
            try simulateBackPagination()
        case .timeline(.incomingMessage):
            try simulateIncomingItem()
        default:
            break
        }
    }
    
    private func simulateIncomingItem() throws {
        guard !incomingItems.isEmpty else { return }
        let item = incomingItems.removeFirst()
        let (items, paginationState) = stateSubject.value
        let newItems = items + [item]
        itemProxies = newItems
        stateSubject.send((newItems, paginationState))
        try client?.send(.success)
    }
    
    func inject(_ proxies: [TimelineItemProxy]) {
        let (items, paginationState) = stateSubject.value
        let newItems = items + proxies
        itemProxies = newItems
        stateSubject.send((newItems, paginationState))
    }
    
    func replaceLastItem(with proxy: TimelineItemProxy) {
        var (items, paginationState) = stateSubject.value
        guard !items.isEmpty else { return }
        items[items.index(before: items.endIndex)] = proxy
        itemProxies = items
        stateSubject.send((items, paginationState))
    }
    
    private func simulateBackPagination() throws {
        let (items, _) = stateSubject.value
        
        guard !backPaginationResponses.isEmpty else {
            let newState = TimelinePaginationState(backward: .endReached, forward: .endReached)
            paginationState = newState
            stateSubject.send((items, newState))
            return
        }
        
        let newItems = backPaginationResponses.removeFirst()
        let newPaginationState = TimelinePaginationState(backward: backPaginationResponses.isEmpty ? .endReached : .idle,
                                                         forward: .endReached)
        itemProxies = newItems + items
        paginationState = newPaginationState
        stateSubject.send((newItems + items, newPaginationState))
        try client?.send(.success)
    }
}
