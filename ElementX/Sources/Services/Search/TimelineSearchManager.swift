//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

/// Manages full-text search across timeline messages
@MainActor
final class TimelineSearchManager: ObservableObject {
    private let timelineController: TimelineControllerProtocol
    private let maxResultsLimit: Int
    private let pageSize: UInt16
    private let initialResultsLimit: Int
    private let loadMoreBatchSize: Int
    
    @Published private(set) var searchResults: [TimelineSearchResult] = []
    @Published private(set) var searchProgress = TimelineSearchProgress.initial
    @Published private(set) var lastSearchTerm: String = ""
    @Published private(set) var hasMoreResults: Bool = false
    @Published private(set) var isSearching: Bool = false
    
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init(timelineController: TimelineControllerProtocol,
         maxResultsLimit: Int = 500,
         pageSize: UInt16 = 20,
         initialResultsLimit: Int = 20,
         loadMoreBatchSize: Int = 20) {
        self.timelineController = timelineController
        self.maxResultsLimit = maxResultsLimit
        self.pageSize = pageSize
        self.initialResultsLimit = initialResultsLimit
        self.loadMoreBatchSize = loadMoreBatchSize
    }
    
    /// Performs full-text search across timeline messages
    /// Paginates backwards until timeline start or maxResultsLimit is reached
    func performFullTextSearch(term: String) {
        guard !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            cancelSearch()
            return
        }
        
        cancelSearch()
        lastSearchTerm = term
        
        searchTask = Task { [weak self] in
            await self?.executeSearch(term: term)
        }
    }
    
    /// Cancels the current search operation
    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
        searchProgress = TimelineSearchProgress.initial
        searchResults = []
        hasMoreResults = false
        isSearching = false
    }
    
    /// Clears search results while keeping the last search term
    func clearResults() {
        searchResults = []
        searchProgress = TimelineSearchProgress.initial
        hasMoreResults = false
        isSearching = false
    }
    
    /// Clears search results and resets search state
    func clearSearch() async {
        searchTask?.cancel()
        searchTask = nil
        searchResults = []
        searchProgress = TimelineSearchProgress.initial
        hasMoreResults = false
        isSearching = false
    }
    
    /// Loads more search results by continuing pagination
    func loadMoreResults() async {
        guard !lastSearchTerm.isEmpty,
              hasMoreResults,
              !isSearching else { return }
        
        searchTask?.cancel()
        
        searchTask = Task { [weak self] in
            await self?.executeLoadMore()
        }
    }
    
    // MARK: - Private
    
    private func executeSearch(term: String) async {
        let normalizedTerm = normalizeSearchTerm(term)
        guard !normalizedTerm.isEmpty else { return }
        
        isSearching = true
        await updateProgress(isSearching: true, resultsCount: 0, pagesScanned: 0, hasReachedTimelineStart: false)
        
        let (results, hasMore) = await searchForResults(normalizedTerm: normalizedTerm, targetLimit: initialResultsLimit)
        
        // Sort results by timestamp (newest first)
        self.searchResults = results.sorted { $0.timestamp > $1.timestamp }
        self.hasMoreResults = hasMore
        self.isSearching = false
        
        // Final update
        await updateProgress(
            isSearching: false,
            resultsCount: results.count,
            pagesScanned: 0,
            hasReachedTimelineStart: !hasMore
        )
    }
    
    private func executeLoadMore() async {
        let normalizedTerm = normalizeSearchTerm(lastSearchTerm)
        guard !normalizedTerm.isEmpty else { return }
        
        isSearching = true
        
        let currentResults = searchResults
        let (newResults, hasMore) = await searchForResults(
            normalizedTerm: normalizedTerm,
            targetLimit: loadMoreBatchSize,
            existingResults: currentResults
        )
        
        // Append new results and sort all by timestamp (newest first)
        let allResults = currentResults + newResults
        self.searchResults = allResults.sorted { $0.timestamp > $1.timestamp }
        self.hasMoreResults = hasMore
        self.isSearching = false
        
        // Update progress
        await updateProgress(
            isSearching: false,
            resultsCount: allResults.count,
            pagesScanned: 0,
            hasReachedTimelineStart: !hasMore
        )
    }
    
    private func searchForResults(normalizedTerm: String, targetLimit: Int, existingResults: [TimelineSearchResult] = []) async -> ([TimelineSearchResult], Bool) {
        var results: [TimelineSearchResult] = []
        var pagesScanned = 0
        var hasReachedStart = false
        
        // Continue pagination until we reach timeline start or hit limits
        while !Task.isCancelled &&
              results.count < targetLimit &&
              !hasReachedStart {
            
            // Paginate backwards to load more messages
            let paginationResult = await timelineController.paginateBackwards(requestSize: pageSize)
            
            switch paginationResult {
            case .success:
                pagesScanned += 1
                
                // Wait briefly for timeline items to update
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                
                // Scan newly loaded messages
                let newResults = await scanTimelineItemsForTerm(normalizedTerm, existingResults: existingResults + results)
                results.append(contentsOf: newResults)
                
                // Check if we've reached the start
                hasReachedStart = timelineController.paginationState.backward == .timelineEndReached
                
            case .failure(let error):
                MXLog.error("Timeline pagination failed during search: \\(error)")
                break
            }
        }
        
        // Determine if there are more results available
        let hasMoreResults = !hasReachedStart && (existingResults.count + results.count) < maxResultsLimit
        
        return (results, hasMoreResults)
    }
    
    private func scanTimelineItemsForTerm(_ normalizedTerm: String, existingResults: [TimelineSearchResult]) async -> [TimelineSearchResult] {
        let existingEventIDs = Set(existingResults.map { $0.eventID })
        var newResults: [TimelineSearchResult] = []
        
        for timelineItem in timelineController.timelineItems {
            guard let messageItem = timelineItem as? EventBasedMessageTimelineItemProtocol,
                  let eventID = messageItem.id.eventID,
                  !existingEventIDs.contains(eventID) else {
                continue
            }
            
            // Ensure message details are loaded
            await timelineController.processItemAppearance(messageItem.id)
            
            // Extract message content
            if let messageContent = await extractMessageContent(from: messageItem) {
                let normalizedContent = normalizeSearchTerm(messageContent)
                
                if normalizedContent.contains(normalizedTerm) {
                    if let searchResult = createSearchResult(
                        from: messageItem,
                        messageContent: messageContent,
                        searchTerm: normalizedTerm
                    ) {
                        newResults.append(searchResult)
                    }
                }
            }
            
            // Break if we've hit the results limit
            if newResults.count + existingResults.count >= maxResultsLimit {
                break
            }
        }
        
        return newResults
    }
    
    private func extractMessageContent(from messageItem: EventBasedMessageTimelineItemProtocol) async -> String? {
        // First try to get the body directly from the timeline item
        let body = messageItem.body
        if !body.isEmpty && body != "Unable to decrypt" {
            return body
        }
        
        // If body is empty or indicates decryption failure, try to fetch event content
        if let eventContent = await timelineController.messageEventContent(for: messageItem.id) {
            return" eventContent.msg"
        }
        
        return nil
    }
    
    private func createSearchResult(from messageItem: EventBasedMessageTimelineItemProtocol,
                                    messageContent: String,
                                    searchTerm: String) -> TimelineSearchResult? {
        guard let eventID = messageItem.id.eventID else { return nil }
        
        // Create snippet with highlighting
        let (snippet, highlightRanges) = createSnippetWithHighlighting(
            content: messageContent,
            searchTerm: searchTerm
        )
        
        let timestamp = timelineController.eventTimestamp(for: messageItem.id) ?? messageItem.timestamp
        
        return TimelineSearchResult(
            eventID: eventID,
            timestamp: timestamp,
            senderID: messageItem.sender.id,
            senderDisplayName: messageItem.sender.displayName,
            messageSnippet: snippet,
            highlightRanges: highlightRanges,
            roomID: timelineController.roomID
        )
    }
    
    private func createSnippetWithHighlighting(content: String, searchTerm: String) -> (String, [NSRange]) {
        let maxSnippetLength = 200
        let normalizedContent = normalizeSearchTerm(content)
        let normalizedTerm = normalizeSearchTerm(searchTerm)
        
        guard let range = normalizedContent.range(of: normalizedTerm) else {
            return (String(content.prefix(maxSnippetLength)), [])
        }
        
        let termLocation = normalizedContent.distance(from: normalizedContent.startIndex, to: range.lowerBound)
        let termLength = normalizedTerm.count
        
        // Calculate snippet boundaries
        let snippetStart = max(0, termLocation - (maxSnippetLength - termLength) / 2)
        let snippetEnd = min(content.count, snippetStart + maxSnippetLength)
        
        let startIndex = content.index(content.startIndex, offsetBy: snippetStart)
        let endIndex = content.index(content.startIndex, offsetBy: snippetEnd)
        let snippet = String(content[startIndex..<endIndex])
        
        // Adjust highlight range for the snippet
        let highlightStart = max(0, termLocation - snippetStart)
        let highlightRange = NSRange(location: highlightStart, length: termLength)
        
        return (snippet, [highlightRange])
    }
    
    private func normalizeSearchTerm(_ text: String) -> String {
        return text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: .current)
    }
    
    private func updateProgress(isSearching: Bool,
                                resultsCount: Int,
                                pagesScanned: Int,
                                hasReachedTimelineStart: Bool) async {
        await MainActor.run {
            self.searchProgress = TimelineSearchProgress(
                isSearching: isSearching,
                resultsCount: resultsCount,
                pagesScanned: pagesScanned,
                hasReachedTimelineStart: hasReachedTimelineStart
            )
        }
    }
}
