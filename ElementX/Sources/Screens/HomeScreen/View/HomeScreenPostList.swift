//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeScreenPostList: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        ForEach(context.viewState.visiblePosts) { post in
            VStack(alignment: .leading) {
                HomeScreenPostCell(post: post, mediaProvider: context.mediaProvider, showThreadLine: false,
                                   onPostTapped: {
                    context.send(viewAction: .postTapped(post))
                },
                                   onOpenArweaveLink: {
                    context.send(viewAction: .openArweaveLink(post))
                },
                                   onMeowTapped: { count in
                    context.send(viewAction: .addMeowToPost(postId: post.id, amount: count))
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
    }
}
