//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomMessageSearchScreen: View {
    @ObservedObject var context: RoomMessageSearchScreenViewModel.Context

    var body: some View {
        List {
            Section {
                ForEach(context.viewState.results) { result in
                    Button {
                        context.send(viewAction: .selectResult(eventID: result.id))
                    } label: {
                        RoomMessageSearchScreenCell(result: result, mediaProvider: context.mediaProvider)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }
            } footer: {
                VStack(spacing: 0) {
                    if context.viewState.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if context.viewState.shouldShowEmptyState {
                        Text(L10n.commonNoResults)
                            .font(.compound.bodyLG)
                            .foregroundColor(.compound.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }

                    emptyRectangle
                        .onAppear {
                            context.send(viewAction: .reachedBottom)
                        }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 48)
        .scrollContentBackground(.hidden)
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .searchController(query: $context.searchQuery,
                          placeholder: L10n.actionSearch,
                          showsCancelButton: false)
        .navigationTitle(L10n.actionSearch)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyRectangle: some View {
        Rectangle()
            .frame(width: 0, height: 0)
    }
}

// MARK: - Previews

struct RoomMessageSearchScreen_Previews: PreviewProvider, TestablePreview {
    static let emptyViewModel = RoomMessageSearchScreenViewModel(roomProxy: JoinedRoomProxyMock(.init()),
                                                                 mediaProvider: MediaProviderMock(configuration: .init()))

    static let resultsViewModel: RoomMessageSearchScreenViewModel = {
        let results = [RoomMessageSearchResult(id: "$1",
                                               sender: TimelineItemSender(id: "@alice:matrix.org", displayName: "Alice"),
                                               timestamp: .init(timeIntervalSince1970: 0),
                                               message: AttributedString("Did you see the release notes?")),
                       RoomMessageSearchResult(id: "$2",
                                               sender: TimelineItemSender(id: "@bob:matrix.org", displayName: "Bob"),
                                               timestamp: .init(timeIntervalSince1970: 0),
                                               message: AttributedString("Yes, the search feature looks great"))]

        let searchProxy = RoomMessageSearchProxyMock()
        var batches: [[RoomMessageSearchResult]?] = [results, nil]
        searchProxy.loadNextResultsClosure = {
            .success(batches.isEmpty ? nil : batches.removeFirst())
        }

        let roomProxy = JoinedRoomProxyMock(.init())
        roomProxy.messageSearchProxyQueryReturnValue = searchProxy

        let viewModel = RoomMessageSearchScreenViewModel(roomProxy: roomProxy,
                                                         mediaProvider: MediaProviderMock(configuration: .init()))
        viewModel.context.searchQuery = "release"
        return viewModel
    }()

    static var previews: some View {
        ElementNavigationStack {
            RoomMessageSearchScreen(context: emptyViewModel.context)
        }
        .previewDisplayName("Empty")

        ElementNavigationStack {
            RoomMessageSearchScreen(context: resultsViewModel.context)
        }
        .previewDisplayName("Results")
        .snapshotPreferences(expect: resultsViewModel.context.$viewState.map { !$0.results.isEmpty }.eraseToAnyPublisher())
    }
}
