//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
                if context.viewState.shouldDisplayEmptyView {
                    KnockRequestsListEmptyStateView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if context.viewState.shouldDisplayAcceptAllButton {
                    acceptAllButton
                }
            }
            .alert(item: $context.alertInfo)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if context.viewState.isLoading {
            EmptyView()
        } else {
            list
        }
    }
    
    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if context.viewState.shouldDisplayRequests {
                    ForEach(context.viewState.displayedRequests) { requestInfo in
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
    
    private func onAccept(eventID: String) {
        context.send(viewAction: .acceptRequest(eventID: eventID))
    }
    
    private func onDecline(eventID: String) {
        context.send(viewAction: .declineRequest(eventID: eventID))
    }
    
    private func onDeclineAndBan(eventID: String) {
        context.send(viewAction: .ban(eventID: eventID))
    }
}

// MARK: - Previews

struct KnockRequestsListScreen_Previews: PreviewProvider, TestablePreview {
    static let loadingViewModel = KnockRequestsListScreenViewModel.mockWithRequestsState(.loading)
    
    static let emptyViewModel = KnockRequestsListScreenViewModel.mockWithRequestsState(.loaded([]))
    
    static let singleRequestViewModel = KnockRequestsListScreenViewModel.mockWithRequestsState(.loaded([KnockRequestProxyMock(.init(eventID: "1",
                                                                                                                                    userID: "@alice:matrix.org",
                                                                                                                                    displayName: "Alice",
                                                                                                                                    avatarURL: nil,
                                                                                                                                    timestamp: "Now",
                                                                                                                                    reason: "Hello"))]))
    
    static let viewModel = KnockRequestsListScreenViewModel.mockWithRequestsState(.loaded([
        KnockRequestProxyMock(.init(eventID: "1",
                                    userID: "@alice:matrix.org",
                                    displayName: "Alice",
                                    avatarURL: nil,
                                    timestamp: "Now",
                                    reason: "Hello")),
        KnockRequestProxyMock(.init(eventID: "2",
                                    userID: "@bob:matrix.org",
                                    displayName: "Bob",
                                    avatarURL: nil,
                                    timestamp: "Now",
                                    // swiftlint:disable:next line_length
                                    reason: "Hello this one is a very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very long reason")),
        KnockRequestProxyMock(.init(eventID: "3",
                                    userID: "@charlie:matrix.org",
                                    displayName: "Charlie",
                                    avatarURL: nil,
                                    timestamp: "Now",
                                    reason: nil)),
        KnockRequestProxyMock(.init(eventID: "4",
                                    userID: "@dan:matrix.org",
                                    displayName: "Dan",
                                    avatarURL: nil,
                                    timestamp: "Now",
                                    reason: "Hello! It's a me! Dan!"))
    ]))
    
    static var previews: some View {
        NavigationStack {
            KnockRequestsListScreen(context: viewModel.context)
        }
        .snapshotPreferences(expect: viewModel.context.$viewState.map { state in
            state.shouldDisplayRequests == true
        })
        
        NavigationStack {
            KnockRequestsListScreen(context: singleRequestViewModel.context)
        }
        .snapshotPreferences(expect: singleRequestViewModel.context.$viewState.map { state in
            state.shouldDisplayRequests == true
        })
        .previewDisplayName("Single Request")
        
        NavigationStack {
            KnockRequestsListScreen(context: emptyViewModel.context)
        }
        .snapshotPreferences(expect: emptyViewModel.context.$viewState.map { state in
            state.shouldDisplayEmptyView == true
        })
        .previewDisplayName("Empty state")
        
        NavigationStack {
            KnockRequestsListScreen(context: loadingViewModel.context)
        }
        .snapshotPreferences(expect: loadingViewModel.context.$viewState.map { state in
            state.isLoading == true
        })
        .previewDisplayName("Loading state")
    }
}

extension KnockRequestsListScreenViewModel {
    static func mockWithRequestsState(_ requestsState: KnockRequestsState) -> KnockRequestsListScreenViewModel {
        .init(roomProxy: JoinedRoomProxyMock(.init(members: [.mockAdmin],
                                                   knockRequestsState: requestsState,
                                                   ownUserID: RoomMemberProxyMock.mockAdmin.userID,
                                                   joinRule: .knock)),
              mediaProvider: MediaProviderMock(),
              userIndicatorController: UserIndicatorControllerMock())
    }
}
