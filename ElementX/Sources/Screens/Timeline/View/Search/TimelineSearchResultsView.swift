//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineSearchResultsView: View {
    @ObservedObject var searchManager: TimelineSearchManager
    let onResultTapped: (TimelineSearchResult) -> Void
    let onCancel: () -> Void
    
    @State private var searchText = ""
    @State private var selectedResultIndex: Int? = nil
    @FocusState private var searchFieldFocus: Bool
    
    var body: some View {
        List {
            Section {
                header
            }
            .listRowInsets(.init())
            
            Section {
                if searchManager.searchResults.isEmpty {
                    emptyStateView
                } else {
                    ForEach(Array(searchManager.searchResults.enumerated()), id: \.element.id) { index, result in
                        SearchResultRow(
                            result: result,
                            searchTerm: searchManager.lastSearchTerm,
                            onTapped: {
                                selectedResultIndex = index
                                onResultTapped(result)
                            }
                        )
                        .background(
                            selectedResultIndex == index
                            ? Color.compound.bgSubtlePrimary
                            : Color.compound.bgCanvasDefault
                        )
                    }
                }
            }
            
            // Load more footer section
            if !searchManager.searchResults.isEmpty {
                Section {
                    loadMoreFooter
                }
                .listRowInsets(.init())
            }
        }
        .listStyle(.plain)
        .background { keyboardShortcuts }
        .onAppear {
            searchText = ""
            searchFieldFocus = true
        }
        .onChange(of: searchManager.searchResults) {
            selectedResultIndex = nil
        }
        
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            // Search field styled like GlobalSearchScreen (magnifying glass + clear icon)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.compound.iconTertiary)
                
                GlobalSearchTextFieldRepresentable(
                    placeholder: "Search messages...",
                    text: $searchText,
                    keyPressHandler: { keyCode in
                        switch keyCode {
                        case .keyboardUpArrow:
                            moveToNextResult(backwards: true)
                            return true
                        case .keyboardDownArrow:
                            moveToNextResult()
                            return true
                        case .keyboardReturnOrEnter, .keyboardReturn:
                            
                            performSearch()
                            
                            return true
                        case .keyboardEscape:
                            onCancel()
                            return true
                        default:
                            return false
                        }
                    },
                    endEditingHandler: {
                        performSearch()
                        searchFieldFocus = false
                    },
                    returnKeyType: UIReturnKeyType.search
                )
                .focused($searchFieldFocus)
                .autocorrectionDisabled(true)
                .autocapitalization(.none)
                .textInputAutocapitalization(.never)
                .accessibilityLabel(Text("search message"))
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchManager.clearResults()
                        selectedResultIndex = nil
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.compound.iconSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.compound.bgCanvasDefault)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    private func performSearch() {
        let trimmedTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else { return }
        
        selectedResultIndex = nil
        Task {
            await searchManager.performFullTextSearch(term: trimmedTerm)
        }
    }
    
    private func moveToNextResult(backwards: Bool = false) {
        guard !searchManager.searchResults.isEmpty else {
            selectedResultIndex = nil
            return
        }
        
        let currentIndex = selectedResultIndex ?? -1
        let nextIndex = backwards ? currentIndex - 1 : currentIndex + 1
        
        if nextIndex < 0 {
            selectedResultIndex = searchManager.searchResults.count - 1
        } else if nextIndex >= searchManager.searchResults.count {
            selectedResultIndex = 0
        } else {
            selectedResultIndex = nextIndex
        }
    }
    
    private var keyboardShortcuts: some View {
        Group {
            Button("") {
                onCancel()
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.compound.iconTertiary)
            
            VStack(spacing: 8) {
                if searchManager.searchProgress.isSearching {
                    Text("Searching...")
                        .font(.compound.headingSM)
                        .foregroundColor(.compound.textPrimary)
                    
                    Text("Looking through message history for '\(searchManager.lastSearchTerm)'")
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    if (searchManager.searchProgress.resultsCount) > 0 {
                        Text("\(searchManager.searchProgress.resultsCount) items found")
                            .font(.compound.bodySM)
                            .foregroundColor(.compound.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                } else if !searchManager.lastSearchTerm.isEmpty {
                    Text("No results found")
                        .font(.compound.headingSM)
                        .foregroundColor(.compound.textPrimary)

                } else {
                    Text("Search messages")
                        .font(.compound.headingSM)
                        .foregroundColor(.compound.textPrimary)
                    
                    Text("Enter a search term to find messages")
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadMoreFooter: some View {
        HStack {
            if searchManager.hasMoreResults && !searchManager.isSearching {
                Button(action: {
                    Task {
                        await searchManager.loadMoreResults()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Load more results")
                    }
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textActionAccent)
                }
                .buttonStyle(.plain)
                
            } else if searchManager.isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading more...")
                }
                .font(.compound.bodySM)
                .foregroundColor(.compound.textSecondary)
                
            } else {
                Text("End of search history")
                    .font(.compound.bodyXS)
                    .foregroundColor(.compound.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}

struct SearchResultRow: View {
    let result: TimelineSearchResult
    let searchTerm: String
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            VStack(alignment: .leading, spacing: 8) {
                // Header with sender and timestamp
                HStack {
                    Text(result.senderDisplayName ?? result.senderID)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.compound.textPrimary)
                    
                    Spacer()
                    
                    Text(formattedTimestamp)
                        .font(.caption)
                        .foregroundColor(.compound.textSecondary)
                }
                
                // Message snippet with highlighting
                HighlightedText(
                    text: result.messageSnippet,
                    highlightRanges: result.highlightRanges
                )
                .font(.subheadline)
                .foregroundColor(.compound.textSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(result.timestamp) {
            formatter.timeStyle = .short
            return formatter.string(from: result.timestamp)
        } else if Calendar.current.isDate(result.timestamp, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d, HH:mm"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: result.timestamp)
    }
}

struct HighlightedText: View {
    let text: String
    let highlightRanges: [NSRange]
    
    var body: some View {
        Text(highlightedAttributedString)
    }
    
    private var highlightedAttributedString: AttributedString {
        var attributedString = AttributedString(text)
        
        // Apply highlighting to ranges
        for range in highlightRanges {
            guard range.location >= 0,
                  range.location + range.length <= text.count else { continue }
            
            let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: range.location)
            let endIndex = attributedString.index(startIndex, offsetByCharacters: range.length)
            
            if startIndex < attributedString.endIndex && endIndex <= attributedString.endIndex {
                attributedString[startIndex..<endIndex].backgroundColor = .yellow.opacity(0.3)
                attributedString[startIndex..<endIndex].foregroundColor = .primary
            }
        }
        
        return attributedString
    }
}

#Preview {
    let mockSearchManager = TimelineSearchManager(
        timelineController: MockTimelineController()
    )
    
    return TimelineSearchResultsView(
        searchManager: mockSearchManager,
        onResultTapped: { _ in },
        onCancel: { }
    )
}
