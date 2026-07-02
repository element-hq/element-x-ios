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
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var resultsHandle: TaskHandle?
    
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
    
    init(searchService: SearchServiceProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol) {
        self.searchService = searchService
        self.timelineItemFactory = timelineItemFactory
        
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
        
        do {
            try await searchService.setQuery(query: query)
            return .success(())
        } catch {
            MXLog.error("Failed to set search query: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func paginate() async {
        do {
            try await searchService.paginate()
        } catch {
            MXLog.error("Failed to paginate search results: \(error)")
        }
    }
    
    // MARK: - Private
    
    private func handleResultUpdates(_ updates: [SearchServiceResultsUpdate]) {
        var results = resultsSubject.value
        
        for update in updates {
            switch update {
            case .append(let values):
                results.append(contentsOf: values.compactMap { self.makeResult($0) })
            case .clear:
                results.removeAll()
            case .pushFront(let value):
                if let result = makeResult(value) {
                    results.insert(result, at: 0)
                }
            case .pushBack(let value):
                if let result = makeResult(value) {
                    results.append(result)
                }
            case .popFront:
                results.removeFirst()
            case .popBack:
                results.removeLast()
            case .insert(let index, let value):
                if let result = makeResult(value) {
                    results.insert(result, at: Int(index))
                }
            case .set(let index, let value):
                if let result = makeResult(value) {
                    results[Int(index)] = result
                }
            case .remove(let index):
                results.remove(at: Int(index))
            case .truncate(let length):
                results.removeSubrange(Int(length)..<results.count)
            case .reset(let values):
                results = values.compactMap { self.makeResult($0) }
            }
        }
        
        resultsSubject.send(results)
    }
    
    private func makeResult(_ searchResult: MatrixRustSDK.SearchServiceResult) -> SearchServiceResult? {
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
