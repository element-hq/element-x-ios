// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.

import Combine
import Foundation
import MatrixRustSDK

class SearchServiceProxy: SearchServiceProxyProtocol {
    private let searchService: SearchServiceProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    private let roomID: String?
    
    private var resultsHandle: TaskHandle?
    
    /// Index-parallel with the SDK's list — positional diffs land here. Never filter this.
    private var innerResults: [SearchServiceResult] = []
    
    private let resultsSubject = CurrentValueSubject<[SearchServiceResult], Never>([])
    var resultsPublisher: CurrentValuePublisher<[SearchServiceResult], Never> {
        resultsSubject.asCurrentValuePublisher()
    }
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var paginationStateHandle: TaskHandle?
    
    private let paginationStateSubject: CurrentValueSubject<SearchServicePaginationState, Never>
    var paginationStatePublisher: CurrentValuePublisher<SearchServicePaginationState, Never> {
        paginationStateSubject.asCurrentValuePublisher()
    }
    
    init(searchService: SearchServiceProtocol,
         timelineItemFactory: RoomTimelineItemFactoryProtocol,
         roomID: String? = nil) {
        self.searchService = searchService
        self.timelineItemFactory = timelineItemFactory
        self.roomID = roomID
        
        paginationStateSubject = CurrentValueSubject(.init(sdkState: searchService.paginationState()))
        
        paginationStateHandle = searchService.subscribeToPaginationStateUpdates(listener: SDKListener.onMainActor { [weak self] state in
            self?.paginationStateSubject.send(.init(sdkState: state))
        })
    }
    
    func setQuery(_ query: String) async -> Result<Void, SearchServiceProxyError> {
        if resultsHandle == nil {
            resultsHandle = await searchService.subscribeToResults(listener: SDKListener.onMainActor { [weak self] updates in
                self?.handleResultUpdates(updates)
            })
        }
        
        // Whatever endReached we are holding describes the PREVIOUS query — or, on the very first
        // search, a cursor that was never queried at all and reports endReached = true. Carrying
        // it over makes a search look finished before it has started. We are about to load the
        // first page, so publish .loading rather than an .idle that would momentarily clear the
        // view's loading state and flash the empty view before any result arrives.
        paginationStateSubject.send(.loading)
        
        do {
            try await searchService.setQuery(query: query.escapedForTantivy)
            return .success(())
        } catch {
            MXLog.error("Failed to set search query: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    @discardableResult
    func paginate() async -> Result<Void, SearchServiceProxyError> {
        do {
            try await searchService.paginate()
            return .success(())
        } catch {
            MXLog.error("Failed to paginate search results: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Private
    
    private func handleResultUpdates(_ updates: [SearchServiceResultsUpdate]) {
        // This list MUST stay index-parallel with the SDK's: the updates below carry the SDK's
        // indices. Dropping or filtering entries here mis-addresses every later positional
        // update — do any filtering at the exposure boundary instead.
        var results = innerResults
        
        for update in updates {
            switch update {
            case .append(let values):
                results.append(contentsOf: values.map(makeResult))
            case .clear:
                results.removeAll()
            case .pushFront(let value):
                results.insert(makeResult(value), at: 0)
            case .pushBack(let value):
                results.append(makeResult(value))
            case .popFront:
                if !results.isEmpty {
                    results.removeFirst()
                }
            case .popBack:
                if !results.isEmpty {
                    results.removeLast()
                }
            case .insert(let index, let value):
                results.insert(makeResult(value), at: Int(index))
            case .set(let index, let value):
                results[Int(index)] = makeResult(value)
            case .remove(let index):
                results.remove(at: Int(index))
            case .truncate(let length):
                results.removeSubrange(Int(length)..<results.count)
            case .reset(let values):
                results = values.map(makeResult)
            }
        }
        
        innerResults = results
        publishResults()
    }
    
    private func publishResults() {
        guard let roomID else {
            resultsSubject.send(innerResults)
            return
        }
        
        // Room scoping is a client-side filter over a globally ranked set — the FFI has no
        // per-room search. Applied here, at the exposure boundary, and nowhere earlier.
        resultsSubject.send(innerResults.filter { $0.roomID == roomID })
    }
    
    /// Maps every SDK result — never drops one. Content the app has no rendering for becomes a
    /// placeholder so the list stays index-parallel with the SDK's.
    private func makeResult(_ searchResult: MatrixRustSDK.SearchServiceResult) -> SearchServiceResult {
        switch searchResult {
        case .message(let roomID, let result):
            let sender = TimelineItemSender(senderID: result.sender, senderProfile: result.senderProfile)
            
            let content: TimelineEventContent
            switch result.content {
            case .msgLike(let msgLike):
                switch msgLike.kind {
                case .message(let msg):
                    content = .message(timelineItemFactory.buildMessageTimelineItemContent(messageType: msg.msgType,
                                                                                           senderID: result.sender,
                                                                                           senderDisplayName: sender.displayName))
                case .poll(let question, _, _, _, _, _, _):
                    content = .poll(question: question)
                case .sticker(let body, _, _):
                    content = .message(.text(.init(body: body)))
                case .redacted:
                    content = .redacted
                case .liveLocation:
                    content = .liveLocation
                default:
                    content = .message(.text(.init(body: L10n.commonUnsupportedEvent)))
                }
            default:
                content = .message(.text(.init(body: L10n.commonUnsupportedEvent)))
            }
            
            return SearchServiceResult(roomID: roomID,
                                       eventID: result.eventId,
                                       sender: sender,
                                       content: content,
                                       timestamp: Date(timeIntervalSince1970: TimeInterval(result.timestamp) / 1000))
        }
    }
}
