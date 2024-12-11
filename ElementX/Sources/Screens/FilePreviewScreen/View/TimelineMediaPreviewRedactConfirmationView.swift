//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineMediaPreviewRedactConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    
    private var currentItem: TimelineMediaPreviewItem { context.viewState.currentItem }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                preview
                buttons
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .padding(.top, 19) // For the drag indicator
        .presentationBackground(.compound.bgCanvasDefault)
        .preferredColorScheme(.dark)
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.delete, style: .alertSolid)
            
            VStack(spacing: 8) {
                Text(L10n.screenMediaDetailsRedactConfirmationTitle)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(L10n.screenMediaDetailsRedactConfirmationMessage)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var preview: some View {
        HStack(spacing: 12) {
            if let mediaSource = currentItem.thumbnailMediaSource {
                Color.clear
                    .scaledFrame(size: 40)
                    .background {
                        LoadableImage(mediaSource: mediaSource,
                                      mediaType: .timelineItem(uniqueID: currentItem.id.uniqueID.id),
                                      blurhash: currentItem.blurhash,
                                      mediaProvider: context.mediaProvider) {
                            Color.compound.bgSubtleSecondary
                        }
                        .aspectRatio(contentMode: .fill)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
                
            VStack(alignment: .leading, spacing: 4) {
                Text(currentItem.filename ?? "")
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
                    
                if let contentType = currentItem.contentType {
                    Group {
                        if let fileSize = currentItem.fileSize {
                            Text(contentType) + Text(" – ") + Text(UInt(fileSize).formatted(.byteCount(style: .file)))
                        } else {
                            Text(contentType)
                        }
                    }
                    .font(.compound.bodySM)
                    .foregroundStyle(.compound.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private var buttons: some View {
        VStack(spacing: 16) {
            Button(L10n.actionRemove, role: .destructive) {
                context.send(viewAction: .redactConfirmation)
            }
            .buttonStyle(.compound(.primary))
            
            Button {
                dismiss()
            } label: {
                Text(L10n.actionCancel)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.compound(.plain))
        }
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

import UniformTypeIdentifiers

struct TimelineMediaPreviewRedactConfirmationView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel(contentType: .jpeg)
    
    static var previews: some View {
        TimelineMediaPreviewRedactConfirmationView(context: viewModel.context)
    }
    
    static func makeViewModel(contentType: UTType? = nil) -> TimelineMediaPreviewViewModel {
        let item = ImageRoomTimelineItem(id: .randomEvent,
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
        
        return TimelineMediaPreviewViewModel(initialItem: item,
                                             isFromRoomScreen: false,
                                             timelineViewModel: TimelineViewModel.mock,
                                             mediaProvider: MediaProviderMock(configuration: .init()),
                                             userIndicatorController: UserIndicatorControllerMock())
    }
}
