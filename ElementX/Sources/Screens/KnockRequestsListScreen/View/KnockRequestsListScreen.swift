//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct KnockRequestsListScreen: View {
    @ObservedObject var context: KnockRequestsListScreenViewModel.Context
    
    var body: some View {
        mainContent
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(L10n.screenKnockRequestsListTitle)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        List {
            if !context.viewState.requests.isEmpty {
                header
            }
            ForEach(context.viewState.requests) { requestInfo in
                ListRow(kind: .custom {
                    KnockRequestCell(cellInfo: requestInfo,
                                     mediaProvider: context.mediaProvider,
                                     onAccept: context.viewState.canAccept ? onAccept : nil,
                                     onDecline: context.viewState.canDecline ? onDecline : nil,
                                     onDeclineAndBan: context.viewState.canBan ? onDeclineAndBan : nil)
                })
            }
        }
        .listStyle(.plain)
        .background(.compound.bgCanvasDefault)
        .overlay {
            if context.viewState.requests.isEmpty {
                KnockRequestsListEmptyStateView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !context.viewState.requests.isEmpty {
                acceptAllButton
            }
        }
    }
    
    private var acceptAllButton: some View {
        Button("Accept all") {
            context.send(viewAction: .acceptAllRequests)
        }
        .buttonStyle(.compound(.secondary))
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .background(.compound.bgCanvasDefault)
    }
    
    private var header: some View {
        Text(L10n.screenKnockRequestsListTitle.uppercased())
            .compoundListSectionHeader()
            .padding(.top, 20)
            .listRowSeparator(.hidden)
    }
    
    private func onAccept(userID: String) {
        context.send(viewAction: .acceptRequest(userID: userID))
    }
    
    private func onDecline(userID: String) {
        context.send(viewAction: .declineRequest(userID: userID))
    }
    
    private func onDeclineAndBan(userID: String) {
        context.send(viewAction: .ban(userID: userID))
    }
}

// MARK: - Previews

struct KnockRequestsListScreen_Previews: PreviewProvider, TestablePreview {
    static let emptyViewModel = KnockRequestsListScreenViewModel.mockWithInitialState(.init())
    
    static let viewModel = KnockRequestsListScreenViewModel.mockWithInitialState(.init(requests: [.init(id: "@alice:matrix.org", displayName: "Alice", avatarUrl: nil, timestamp: "Now", reason: "Hello"),
                                                                                                  // swiftlint:disable:next line_length
                                                                                                  .init(id: "@bob:matrix.org", displayName: "Bob", avatarUrl: nil, timestamp: "Now", reason: "Hello this one is a very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very long reason"),
                                                                                                  .init(id: "@charlie:matrix.org", displayName: "Charlie", avatarUrl: nil, timestamp: "Now", reason: nil),
                                                                                                  .init(id: "@dan:matrix.org", displayName: "Dan", avatarUrl: nil, timestamp: "Now", reason: "Hello! It's a me! Dan!")],
                                                                                       canAccept: true,
                                                                                       canDecline: true,
                                                                                       canBan: true))
                                                                                      
    static var previews: some View {
        NavigationStack {
            KnockRequestsListScreen(context: viewModel.context)
        }
        NavigationStack {
            KnockRequestsListScreen(context: emptyViewModel.context)
        }
        .previewDisplayName("Empty state")
    }
}
