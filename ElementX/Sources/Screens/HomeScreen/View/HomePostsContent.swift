//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomePostsContent: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @ObservedObject var context: HomeScreenViewModel.Context
    let scrollViewAdapter: ScrollViewAdapter
    
    var body: some View {
        postList
    }
    
    private var postList: some View {
        GeometryReader { geometry in
            ScrollView {
                switch context.viewState.postListMode {
                case .skeletons:
                    // TODO: add skeleton list loading for post (for now added a simple progress loader)
                    //                    LazyVStack(spacing: 0) {
                    //                        ForEach(context.viewState.visiblePosts) { room in
                    //                            HomeScreenRoomCell(room: room, context: context, isSelected: false)
                    //                                .redacted(reason: .placeholder)
                    //                                .shimmer() // Putting this directly on the LazyVStack creates an accordion animation on iOS 16.
                    //                        }
                    //                    }
                    //                    .disabled(true)
                    
                    ProgressView()
                case .empty:
                    // TODO: add an empty view stating no posts etc
                    EmptyView()
                case .posts:
                    LazyVStack(spacing: 0) {
                        HomeScreenPostList(context: context)
                        
                        if context.viewState.canLoadMorePosts {
                            ProgressView()
                                .padding()
                                .onAppear {
                                    context.send(viewAction: .loadMorePostsIfNeeded)
                                }
                        }
                    }
                    //                    .isSearching($context.isSearchFieldFocused)
                    //                    .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always))
                    //                    .compoundSearchField()
                    //                    .disableAutocorrection(true)
                }
            }
            .introspect(.scrollView, on: .supportedVersions) { scrollView in
                guard scrollView != scrollViewAdapter.scrollView else { return }
                scrollViewAdapter.scrollView = scrollView
            }
            .background {
                Button("") {
                    context.send(viewAction: .globalSearch)
                }
                .keyboardShortcut(KeyEquivalent("k"), modifiers: [.command])
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollDisabled(context.viewState.postListMode == .skeletons)
            .scrollBounceBehavior(context.viewState.postListMode == .empty ? .basedOnSize : .automatic)
            .animation(.elementDefault, value: context.viewState.postListMode)
            .animation(.none, value: context.viewState.visiblePosts)
        }
    }
}
