//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineMediaPreviewDetailsView: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    
    @State private var isPresentingRedactConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                details
                actions
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 19) // For the drag indicator
        .sheet(isPresented: $isPresentingRedactConfirmation) {
            TimelineMediaPreviewRedactConfirmationView(context: context)
        }
    }
    
    private var details: some View {
        VStack(alignment: .leading, spacing: 24) {
            DetailsRow(title: L10n.screenMediaDetailsUploadedBy) {
                HStack(spacing: 8) {
                    if let sender = context.viewState.currentItem?.sender {
                        LoadableAvatarImage(url: sender.avatarURL,
                                            name: sender.displayName,
                                            contentID: sender.id,
                                            avatarSize: .user(on: .mediaPreviewDetails),
                                            mediaProvider: context.mediaProvider)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if let displayName = sender.displayName {
                                Text(displayName)
                                    .font(.compound.bodyMDSemibold)
                                    .foregroundStyle(.compound.decorativeColor(for: sender.id).text)
                            }
                            
                            Text(sender.id)
                                .font(.compound.bodySM)
                                .foregroundStyle(.compound.textSecondary)
                        }
                    } else {
                        Text(L10n.commonLoading)
                            .font(.compound.bodyMD)
                            .foregroundStyle(.compound.textPrimary)
                    }
                }
            }
            
            DetailsRow(title: L10n.screenMediaDetailsUploadedOn) {
                Text(context.viewState.currentItem?.timestamp.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
            }
            
            DetailsRow(title: L10n.screenMediaDetailsFilename) {
                Text(context.viewState.currentItem?.filename ?? "")
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
            }
            
            if let contentType = context.viewState.currentItem?.contentType {
                DetailsRow(title: L10n.screenMediaDetailsFileFormat) {
                    Group {
                        if let fileSize = context.viewState.currentItem?.fileSize {
                            Text(contentType) + Text(" – ") + Text(UInt(fileSize).formatted(.byteCount(style: .file)))
                        } else {
                            Text(contentType)
                        }
                    }
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
                }
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
        .padding(.horizontal, 16)
    }
    
    private var actions: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.compound.bgSubtlePrimary)
            
            Button { context.send(viewAction: .viewInTimeline) } label: {
                Label(L10n.actionViewInTimeline, icon: \.visibilityOn)
            }
            .buttonStyle(.menuSheet)
            
            Divider()
                .background(Color.compound.bgSubtlePrimary)
            
            Button(role: .destructive) { isPresentingRedactConfirmation = true } label: {
                Label(L10n.actionRemove, icon: \.delete)
            }
            .buttonStyle(.menuSheet)
        }
    }
    
    private struct DetailsRow<Content: View>: View {
        let title: String
        let content: () -> Content
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.compound.bodyXS)
                    .foregroundStyle(.compound.textSecondary)
                    .textCase(.uppercase)
                
                content()
            }
        }
    }
}

// MARK: - Previews

import UniformTypeIdentifiers

struct TimelineMediaPreviewDetailsView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel(contentType: .jpeg)
    static let unknownTypeViewModel = makeViewModel()
    
    static var previews: some View {
        TimelineMediaPreviewDetailsView(context: viewModel.context)
            .previewDisplayName("Image")
        TimelineMediaPreviewDetailsView(context: unknownTypeViewModel.context)
            .previewDisplayName("Unknown type")
    }
    
    static func makeViewModel(contentType: UTType? = nil) -> TimelineMediaPreviewViewModel {
        let previewItems = [
            ImageRoomTimelineItem(id: .randomEvent,
                                  timestamp: .mock,
                                  isOutgoing: false,
                                  isEditable: true,
                                  canBeRepliedTo: true,
                                  isThreaded: false,
                                  sender: .init(id: "@alice:matrix.org",
                                                displayName: "Alice",
                                                avatarURL: .mockMXCUserAvatar),
                                  content: .init(filename: "Amazing Image.jpeg",
                                                 imageInfo: .mockImage,
                                                 thumbnailInfo: .mockThumbnail,
                                                 contentType: contentType))
        ]
        
        let viewModel = TimelineMediaPreviewViewModel(previewItems: previewItems,
                                                      mediaProvider: MediaProviderMock(configuration: .init()),
                                                      userIndicatorController: UserIndicatorControllerMock())
        viewModel.state.currentItem = viewModel.state.previewItems.first
        
        return viewModel
    }
}
