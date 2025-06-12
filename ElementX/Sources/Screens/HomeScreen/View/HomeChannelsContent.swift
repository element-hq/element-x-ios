//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeChannelsContent: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @ObservedObject var context: HomeScreenViewModel.Context
    let scrollViewAdapter: ScrollViewAdapter
    
    var body: some View {
        channelList
    }
    
    private var channelList: some View {
        GeometryReader { geometry in
            ScrollView {
                switch context.viewState.channelsListMode {
                case .skeletons:
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(context.viewState.visibleChannels) { channel in
                            HomeScreenChannelCell(channel: channel, onChannelSelected: { _ in })
                                .redacted(reason: .placeholder)
                                .shimmer()
                        }
                    }
                    .disabled(true)
                case .empty:
                    HomeChannelsEmptyView()
                case .channels:
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(context.viewState.visibleChannels, id: \.id) { channel in
                            HomeScreenChannelCell(channel: channel, onChannelSelected: { channel in
                                context.send(viewAction: .channelTapped(channel))
                            })
                        }
                        
                        HomeTabBottomSpace()
                    }
                }
            }
            .introspect(.scrollView, on: .supportedVersions) { scrollView in
                guard scrollView != scrollViewAdapter.scrollView else { return }
                scrollViewAdapter.scrollView = scrollView
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollDisabled(context.viewState.channelsListMode == .skeletons)
            .scrollBounceBehavior(context.viewState.channelsListMode == .empty ? .basedOnSize : .automatic)
            .animation(.elementDefault, value: context.viewState.channelsListMode)
            .animation(.none, value: context.viewState.visibleChannels)
//            .refreshable {
//                context.send(viewAction: .forceRefreshChannels)
//            }
        }
    }
}

struct HomeChannelsEmptyView: View {
    var body: some View {
        ZStack {
            Text("No channels yet")
                .font(.compound.headingMD)
                .foregroundColor(.compound.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, minHeight: 500)
    }
}
