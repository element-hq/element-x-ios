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
            .onReceive(scrollViewAdapter.didScroll) { _ in
                updateVisibleRange()
            }
            .onReceive(scrollViewAdapter.isScrolling) { _ in
                updateVisibleRange()
            }
            .onChange(of: context.searchQuery) {
                updateVisibleRange()
            }
            .onChange(of: context.viewState.visiblePosts) {
                updateVisibleRange()
                
                DispatchQueue.main.async {
                    guard !scrollViewAdapter.isScrolling.value, let scrollView = scrollViewAdapter.scrollView else {
                        return
                    }
                    
                    let oldOffset = scrollView.contentOffset
                    var newOffset = scrollView.contentOffset
                    newOffset.y += 1
                    
                    scrollView.setContentOffset(newOffset, animated: false)
                    scrollView.setContentOffset(oldOffset, animated: false)
                }
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
    
    /// Often times the scroll view's content size isn't correct yet when this method is called e.g. when cancelling a search
    /// Dispatch it with a delay to allow the UI to update and the computations to be correct
    /// Once we move to iOS 17 we should remove all of this and use scroll anchors instead
    private func updateVisibleRange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { delayedUpdateVisibleRange() }
    }
    
    private func delayedUpdateVisibleRange() {
        guard let scrollView = scrollViewAdapter.scrollView,
              scrollViewAdapter.isScrolling.value == false, // Ignore while scrolling
              context.searchQuery.isEmpty == true, // Ignore while filtering
              context.viewState.visiblePosts.count > 0 else {
            return
        }
        
        guard scrollView.contentSize.height > scrollView.bounds.height else {
            return
        }
        
        let adjustedContentSize = max(scrollView.contentSize.height - scrollView.contentInset.top - scrollView.contentInset.bottom, scrollView.bounds.height)
        let cellHeight = adjustedContentSize / Double(context.viewState.visiblePosts.count)
        
        let firstIndex = Int(max(0.0, scrollView.contentOffset.y + scrollView.contentInset.top) / cellHeight)
        let lastIndex = Int(max(0.0, scrollView.contentOffset.y + scrollView.bounds.height) / cellHeight)
        
        // This will be deduped and throttled on the view model layer
        context.send(viewAction: .updateVisibleItemRangeForPosts(firstIndex..<lastIndex))
    }
}
