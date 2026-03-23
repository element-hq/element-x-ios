//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomThreadListScreen: View {
    @Bindable var context: RoomThreadListScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(context.viewState.items) { item in
                    RoomThreadListCell(item: item, mediaProvider: context.mediaProvider)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                
                footer
            }
        }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .navigationTitle(L10n.commonThreads)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var footer: some View {
        // Needs to be wrapped in a LazyStack otherwise appearance calls don't trigger
        LazyVStack(spacing: 0) {
            ProgressView()
                .padding()
                .opacity(context.viewState.isPaginating ? 1 : 0)
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.compound.bgCanvasDefault)
                .onAppear {
                    context.send(viewAction: .oldestItemDidAppear)
                }
                .onDisappear {
                    context.send(viewAction: .oldestItemDidDisappear)
                }
        }
    }
}

private struct RoomThreadListCell: View {
    let item: RoomThreadListItem
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            LoadableAvatarImage(url: item.rootMessageDetails.sender.avatarURL,
                                name: item.rootMessageDetails.sender.displayName,
                                contentID: item.rootMessageDetails.sender.id,
                                avatarSize: .user(on: .threadList),
                                mediaProvider: mediaProvider)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 16) {
                    creatorDetails
                    Spacer()
                    timestamp
                }
                
                rootMessageDetails
                latestMessageDetails
            }
        }
    }
    
    private var creatorDetails: some View {
        Text(item.rootMessageDetails.sender.disambiguatedDisplayName ?? item.rootMessageDetails.sender.id)
            .font(.compound.bodyLGSemibold)
            .foregroundColor(.compound.textPrimary)
            .lineLimit(1)
    }
    
    @ViewBuilder
    private var rootMessageDetails: some View {
        if let message = item.rootMessageDetails.message {
            Text(message)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var latestMessageDetails: some View {
        if let latestMessageDetails = item.latestMessageDetails {
            HStack(alignment: .center, spacing: 8) {
                Label {
                    Text("\(item.numberOfReplies)")
                        .font(.compound.bodySMSemibold)
                        .foregroundColor(.compound.textSecondary)
                } icon: {
                    CompoundIcon(\.threads, size: .small, relativeTo: .compound.bodySMSemibold)
                        .foregroundColor(.compound.iconSecondary)
                }
                .labelStyle(.custom(spacing: 4, alignment: .center, iconLayout: .trailing))
                
                LoadableAvatarImage(url: latestMessageDetails.sender.avatarURL,
                                    name: latestMessageDetails.sender.displayName,
                                    contentID: latestMessageDetails.sender.id,
                                    avatarSize: .user(on: .threadSummary),
                                    mediaProvider: mediaProvider)
                    .accessibilityHidden(true)
                
                if let message = latestMessageDetails.message {
                    Text(message)
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private var timestamp: some View {
        if let latestMessageDetails = item.latestMessageDetails {
            Text(latestMessageDetails.timestamp.formattedMinimal())
                .font(.compound.bodySM)
                .foregroundColor(.compound.textSecondary)
        } else {
            Text(item.rootMessageDetails.timestamp.formattedTime())
                .font(.compound.bodySM)
                .foregroundColor(.compound.textSecondary)
        }
    }
}

// MARK: - Previews

struct RoomThreadListScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        RoomThreadListScreen(context: viewModel.context)
    }
    
    static func makeViewModel() -> RoomThreadListScreenViewModel {
        RoomThreadListScreenViewModel(threadListServiceProxy: RoomThreadListServiceProxyMock(.init()),
                                      mediaProvider: MediaProviderMock(configuration: .init()))
    }
}
