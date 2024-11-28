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
            .background(.compound.bgCanvasDefault)
            .overlay {
                if !context.viewState.shouldDisplayRequests {
                    KnockRequestsListEmptyStateView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if context.viewState.shouldDisplayRequests {
                    acceptAllButton
                }
            }
            .alert(item: $context.alertInfo)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if context.viewState.shouldDisplayRequests {
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
            }
            .padding(.top, 40)
        }
    }
    
    private var acceptAllButton: some View {
        Button(L10n.screenKnockRequestsListAcceptAllButtonTitle) {
            context.send(viewAction: .acceptAllRequests)
        }
        .buttonStyle(.compound(.secondary))
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .background(.compound.bgCanvasDefault)
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
    static let emptyViewModel = KnockRequestsListScreenViewModel.mockWithInitialState(.init(requests: []))
    
    static let viewModel = KnockRequestsListScreenViewModel.mockWithInitialState(.init(requests: [.init(id: "1", userID: "@alice:matrix.org", displayName: "Alice", avatarURL: nil, timestamp: "Now", reason: "Hello"),
                                                                                                  // swiftlint:disable:next line_length
                                                                                                  .init(id: "2", userID: "@bob:matrix.org", displayName: "Bob", avatarURL: nil, timestamp: "Now", reason: "Hello this one is a very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very long reason"),
                                                                                                  .init(id: "3", userID: "@charlie:matrix.org", displayName: "Charlie", avatarURL: nil, timestamp: "Now", reason: nil),
                                                                                                  .init(id: "4", userID: "@dan:matrix.org", displayName: "Dan", avatarURL: nil, timestamp: "Now", reason: "Hello! It's a me! Dan!")]))
                                                                                      
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
