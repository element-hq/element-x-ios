//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct RoomMessageSearchScreen: View {
    @Bindable var context: RoomMessageSearchScreenViewModel.Context
    
    var body: some View {
        content
            .navigationTitle(UntranslatedL10n.screenMessageSearchTitle)
            .navigationBarTitleDisplayMode(.inline)
            .background(.compound.bgCanvasDefault)
            .conditionalSearchable(searchQuery: $context.searchQuery)
            .compoundSearchField()
            .autocorrectionDisabled(true)
    }
    
    @ViewBuilder
    private var content: some View {
        if context.viewState.displayErrorState {
            statePlaceholder(title: UntranslatedL10n.screenMessageSearchError)
        } else if context.viewState.displaySearchingState {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if context.viewState.displayEmptyState {
            statePlaceholder(title: L10n.commonNoResults)
        } else if context.viewState.displayInitialState {
            Color.clear
        } else {
            resultsList
        }
    }
    
    private func statePlaceholder(title: String) -> some View {
        Text(title)
            .font(.compound.bodyLG)
            .foregroundStyle(.compound.textSecondary)
            .multilineTextAlignment(.center)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsList: some View {
        List {
            ForEach(context.viewState.results) { result in
                RoomMessageSearchScreenCell(result: result, mediaProvider: context.mediaProvider) {
                    context.send(viewAction: .selectResult(eventID: result.id))
                }
                .onAppear {
                    if isNearListEnd(result) {
                        context.send(viewAction: .listEndVisible(true))
                    }
                }
                .onDisappear {
                    if isNearListEnd(result) {
                        context.send(viewAction: .listEndVisible(false))
                    }
                }
            }
            
            if context.viewState.displayLoadMoreIndicator {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .compoundList(.plain)
    }
    
    /// Android parity: `LOAD_MORE_LOOKAHEAD = 2` (MessageSearchView.kt) — report the end while
    /// either of the last two rows is on screen, so the next page is already in flight before the
    /// user reaches the bottom.
    private func isNearListEnd(_ result: RoomMessageSearchResult) -> Bool {
        context.viewState.results.suffix(2).contains { $0.id == result.id }
    }
}

private extension View {
    /// `.searchable` shifts snapshot content down unpredictably in previews/tests, so it is
    /// suppressed there — the same workaround the Search tab uses (SearchScreen.swift).
    @ViewBuilder
    func conditionalSearchable(searchQuery: Binding<String>) -> some View {
        if !ProcessInfo.isXcodePreview, !ProcessInfo.isRunningTests {
            searchable(text: searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        } else {
            self
        }
    }
}

// MARK: - Previews

struct RoomMessageSearchScreen_Previews: PreviewProvider, TestablePreview {
    static let initialViewModel = makeViewModel()
    static let resultsViewModel = makeViewModel(results: .fixtureResults, endReached: true, searchQuery: "Foundation")
    static let paginatingViewModel = makeViewModel(results: .fixtureResults, paginationState: .loading, searchQuery: "Foundation")
    // Seeded `.loading` so the walk suspends awaiting idle instead of spinning against the
    // no-op mock — the visible state (spinner over empty results) is identical.
    static let walkingViewModel = makeViewModel(results: [], paginationState: .loading, searchQuery: "Foundation")
    static let emptyViewModel = makeEmptyResultsViewModel(searchQuery: "Foundation")
    static let errorViewModel = makeViewModel(setQueryResult: .failure(.sdkError(SearchServiceMockError.generic)), searchQuery: "Foundation")
    
    static var previews: some View {
        ElementNavigationStack { RoomMessageSearchScreen(context: initialViewModel.context) }
            .previewDisplayName("Initial")
        ElementNavigationStack { RoomMessageSearchScreen(context: resultsViewModel.context) }
            .previewDisplayName("Results")
            .snapshotPreferences(expect: resultsViewModel.context.observe(\.viewState.results).map { !$0.isEmpty })
        ElementNavigationStack { RoomMessageSearchScreen(context: paginatingViewModel.context) }
            .previewDisplayName("Results while paginating")
            .snapshotPreferences(expect: paginatingViewModel.context.observe(\.viewState.isPaginating).map { $0 })
        ElementNavigationStack { RoomMessageSearchScreen(context: walkingViewModel.context) }
            .previewDisplayName("Room-scoped walk running")
            // Wait on the stored `isSearching` rather than the computed `displaySearchingState`
            // (Observation doesn't reliably track computed properties); the spinner is shown
            // throughout the search so this captures it deterministically.
            .snapshotPreferences(expect: walkingViewModel.context.observe(\.viewState.isSearching).map { $0 })
        ElementNavigationStack { RoomMessageSearchScreen(context: emptyViewModel.context) }
            .previewDisplayName("No results")
            // The walk exhausts the index (`endReached`) with no hit — a stored signal that lands
            // exactly on the empty state.
            .snapshotPreferences(expect: emptyViewModel.context.observe(\.viewState.endReached).map { $0 })
        ElementNavigationStack { RoomMessageSearchScreen(context: errorViewModel.context) }
            .previewDisplayName("Error")
            .snapshotPreferences(expect: errorViewModel.context.observe(\.viewState.hasError).map { $0 })
    }
    
    static func makeViewModel(results: [SearchServiceResult] = [],
                              paginationState: SearchServicePaginationState = .idle(endReached: false),
                              endReached: Bool = false,
                              setQueryResult: Result<Void, SearchServiceProxyError> = .success(()),
                              searchQuery: String = "") -> RoomMessageSearchScreenViewModel {
        let searchService = SearchServiceProxyMock()
        searchService.underlyingResultsPublisher = CurrentValueSubject<[SearchServiceResult], Never>(results).asCurrentValuePublisher()
        searchService.underlyingPaginationStatePublisher = CurrentValueSubject(endReached ? .idle(endReached: true) : paginationState).asCurrentValuePublisher()
        searchService.setQueryReturnValue = setQueryResult
        searchService.paginateReturnValue = .success(())
        
        let viewModel = RoomMessageSearchScreenViewModel(searchService: searchService,
                                                         userID: "@me:example.org",
                                                         mediaProvider: MediaProviderMock(.init()))
        viewModel.context.searchQuery = searchQuery
        return viewModel
    }
    
    /// A view model whose room-scoped walk exhausts the index without a hit, landing on the empty
    /// state deterministically (rather than seeding `endReached` up front, which races the query).
    static func makeEmptyResultsViewModel(searchQuery: String) -> RoomMessageSearchScreenViewModel {
        let searchService = SearchServiceProxyMock()
        let paginationState = CurrentValueSubject<SearchServicePaginationState, Never>(.idle(endReached: false))
        searchService.underlyingResultsPublisher = CurrentValueSubject<[SearchServiceResult], Never>([]).asCurrentValuePublisher()
        searchService.underlyingPaginationStatePublisher = paginationState.asCurrentValuePublisher()
        searchService.setQueryReturnValue = .success(())
        searchService.paginateClosure = {
            paginationState.send(.idle(endReached: true))
            return .success(())
        }
        
        let viewModel = RoomMessageSearchScreenViewModel(searchService: searchService,
                                                         userID: "@me:example.org",
                                                         mediaProvider: MediaProviderMock(.init()))
        viewModel.context.searchQuery = searchQuery
        return viewModel
    }
}

private enum SearchServiceMockError: Error { case generic }

private extension [SearchServiceResult] {
    static var fixtureResults: [SearchServiceResult] {
        // A fixed timestamp keeps the snapshots deterministic — `.now` would render a different
        // time on every recording.
        let timestamp = Date(timeIntervalSince1970: 1_609_459_200)
        return [
            SearchServiceResult(roomID: "!room:example.org",
                                eventID: "$1",
                                sender: .init(id: "@alice:example.org", displayName: "Alice"),
                                content: .message(.text(.init(body: "Have you read the Foundation series?"))),
                                timestamp: timestamp),
            SearchServiceResult(roomID: "!room:example.org",
                                eventID: "$2",
                                sender: .init(id: "@me:example.org", displayName: "Me"),
                                content: .message(.text(.init(body: "Yes! The Second Foundation was my favourite."))),
                                timestamp: timestamp),
            SearchServiceResult(roomID: "!room:example.org",
                                eventID: "$3",
                                sender: .init(id: "@bob:example.org", displayName: "Bob"),
                                content: .message(.file(.init(filename: "Foundation.pdf",
                                                              caption: nil,
                                                              source: nil,
                                                              fileSize: 4 * 1024 * 1024,
                                                              thumbnailSource: nil,
                                                              contentType: nil))),
                                timestamp: timestamp),
            SearchServiceResult(roomID: "!room:example.org",
                                eventID: "$4",
                                sender: .init(id: "@coline:example.org", displayName: "Coline"),
                                content: .poll(question: "What's your favourite Foundation book?"),
                                timestamp: timestamp)
        ]
    }
}
