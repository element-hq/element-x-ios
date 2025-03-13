//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeMyPostsContent: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @ObservedObject var context: HomeScreenViewModel.Context
    let scrollViewAdapter: ScrollViewAdapter
    
    var body: some View {
        myPostList
    }
    
    private var myPostList: some View {
        GeometryReader { geometry in
            ScrollView {
                switch context.viewState.myPostListMode {
                case .skeletons:
                    LazyVStack(spacing: 0) {
                        ForEach(context.viewState.visibleMyPosts) { post in
                            VStack {
                                HomeScreenPostCell(post: post,
                                                   mediaProvider: context.mediaProvider,
                                                   showThreadLine: false,
                                                   onPostTapped: {},
                                                   onOpenArweaveLink: {},
                                                   onMeowTapped: { _ in })
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
                        ForEach(context.viewState.visibleMyPosts, id: \.id) { post in
                            VStack(alignment: .leading) {
                                HomeScreenPostCell(post: post, mediaProvider: context.mediaProvider, showThreadLine: false,
                                                   onPostTapped: {
                                    context.send(viewAction: .postTapped(post))
                                },
                                                   onOpenArweaveLink: {
                                    context.send(viewAction: .openArweaveLink(post))
                                },
                                                   onMeowTapped: { _ in
                                })
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 6)
                                Divider()
                            }
                            .onTapGesture {
                                context.send(viewAction: .postTapped(post))
                            }
                        }
                        
                        if context.viewState.canLoadMoreMyPosts {
                            ProgressView()
                                .padding()
                                .onAppear {
                                    context.send(viewAction: .loadMorePostsIfNeeded(true))
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
            .scrollDisabled(context.viewState.myPostListMode == .skeletons)
            .scrollBounceBehavior(context.viewState.myPostListMode == .empty ? .basedOnSize : .automatic)
            .animation(.elementDefault, value: context.viewState.myPostListMode)
            .animation(.none, value: context.viewState.visibleMyPosts)
            .refreshable {
                context.send(viewAction: .forceRefreshPosts(true))
            }
        }
    }
}
