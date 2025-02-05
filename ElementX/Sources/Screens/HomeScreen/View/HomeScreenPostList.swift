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
            VStack {
                HomeScreenPostCell(post: post, context: context)
                    .padding(.all, 16)
                Divider()
            }
            .onTapGesture {
                context.send(viewAction: .postTapped(post))
            }
        }
    }
}

struct HomeScreenPostCell: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.redactionReasons) private var redactionReasons
    
    let post: HomeScreenPost
    let context: HomeScreenViewModel.Context
    
    var body: some View {
        HStack(alignment: .top) {
            //sender image
            LoadableAvatarImage(url: post.senderInfo.avatarURL,
                                name: nil,
                                contentID: post.senderInfo.userID,
                                avatarSize: .user(on: .home),
                                mediaProvider: context.mediaProvider)
            VStack(alignment: .leading) {
                HStack {
                    Text(post.senderInfo.displayName ?? "")
                        .font(.compound.bodyMDSemibold)
                        .foregroundStyle(.compound.textPrimary)
                        .lineLimit(1)
                    
                    Text("• \(post.postTimestamp)")
                        .font(.zero.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .lineLimit(1)
                    if post.worldPrimaryZId != nil {
                        Spacer()
                        Text("0://\(post.worldPrimaryZId!)")
                            .font(.compound.bodyMDSemibold)
                            .foregroundStyle(.compound.textSecondary)
                            .lineLimit(1)
                            .padding(.leading, 6)
                    }
                }
                if post.senderPrimaryZId != nil {
                    Text("0://\(post.senderPrimaryZId!)")
                        .font(.zero.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .lineLimit(1)
                }
                if post.attributedPostText != nil {
                    Text(post.attributedPostText!)
                        .font(.zero.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                        .padding(.vertical, 12)
                }
                
                HStack {
                    HomeScreenPostFooterItem(icon: Asset.Images.postMeowIcon,
                                             count: post.meowCount,
                                             highlightColor: true)
                    
                    HomeScreenPostFooterItem(icon: Asset.Images.postCommentIcon,
                                             count: post.repliesCount,
                                             highlightColor: false)
                    .padding(.horizontal, 24)
                }
            }
        }
    }
}

struct HomeScreenPostFooterItem: View {
    
    let icon: ImageAsset
    let count: String
    let highlightColor: Bool
    
    var body: some View {
        HStack {
            Image(asset: icon)
            Text("\(count)")
                .font(.zero.bodyMD)
                .foregroundStyle(highlightColor ? .zero.bgAccentRest : .compound.textSecondary)
        }
    }
}
