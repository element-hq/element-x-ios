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
    
    @State private var selectedTab: HomePostsTab = .following
    
    var body: some View {
        VStack(spacing: 0) {
            HomePostsTabView(
                onTabSelected: { tab in
                    selectedTab = tab
                    context.send(viewAction: .forceRefreshAllPosts(followingPostsOnly: tab == .following))
                }
            )
            postList
        }
    }
    
    private var postList: some View {
        GeometryReader { geometry in
            ScrollView {
                switch context.viewState.postListMode {
                case .skeletons:
                    LazyVStack(spacing: 0) {
                        ForEach(context.viewState.visiblePosts) { post in
                            VStack {
                                HomeScreenPostCell(post: post,
                                                   mediaProvider: context.mediaProvider,
                                                   postMediaUrl: nil,
                                                   availableLinkPreview: nil,
                                                   showThreadLine: false,
                                                   onPostTapped: {},
                                                   onOpenArweaveLink: {},
                                                   onMeowTapped: { _ in },
                                                   onOpenYoutubeLink: { _ in },
                                                   onOpenUserProfile: { _ in })
                                .padding(.all, 16)
                                Divider()
                            }
                            .redacted(reason: .placeholder)
                            .shimmer()
                        }
                    }
                    .disabled(true)
                case .empty:
                    HomePostsEmptyView()
                case .posts:
                    LazyVStack(spacing: 0) {
                        HomeScreenPostList(context: context)
                        
                        if context.viewState.canLoadMorePosts {
                            ProgressView()
                                .padding()
                                .onAppear {
                                    context.send(viewAction: .loadMoreAllPosts(followingPostsOnly: selectedTab == .following))
                                }
                        }
                    }
                }
            }
            .introspect(.scrollView, on: .supportedVersions) { scrollView in
                guard scrollView != scrollViewAdapter.scrollView else { return }
                scrollViewAdapter.scrollView = scrollView
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollDisabled(context.viewState.postListMode == .skeletons)
            .scrollBounceBehavior(context.viewState.postListMode == .empty ? .basedOnSize : .automatic)
            .animation(.elementDefault, value: context.viewState.postListMode)
            .animation(.none, value: context.viewState.visiblePosts)
            .refreshable {
                context.send(viewAction: .forceRefreshAllPosts(followingPostsOnly: selectedTab == .following))
            }
        }
    }
}

struct HomePostsEmptyView: View {
    var body: some View {
        ZStack {
            Text("No posts yet")
                .font(.compound.headingMD)
                .foregroundColor(.compound.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, minHeight: 500)
    }
}
