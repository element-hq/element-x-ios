//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024, 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineMediaPreviewRedactConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let item: TimelineMediaPreviewItem.Media
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    var preferredColorScheme: ColorScheme? = .dark

    @State private var sheetHeight: CGFloat = .zero
    private let topPadding: CGFloat = 19
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                preview
                buttons
            }
            .readHeight($sheetHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding(.top, topPadding) // For the drag indicator
        .presentationDetents([.height(sheetHeight + topPadding)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.compound.bgCanvasDefault)
        .preferredColorScheme(preferredColorScheme)
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.delete, style: .alertSolid)
            
            VStack(spacing: 8) {
                Text(L10n.screenMediaBrowserDeleteConfirmationTitle)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(L10n.screenMediaBrowserDeleteConfirmationSubtitle)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
        .padding(.horizontal, 24)
    }
    
    private var preview: some View {
        HStack(spacing: 12) {
            if let mediaSource = item.thumbnailMediaSource {
                Color.clear
                    .scaledFrame(size: 40)
                    .background {
                        LoadableImage(mediaSource: mediaSource,
                                      mediaType: .generic,
                                      blurhash: item.blurhash,
                                      mediaProvider: context.mediaProvider) {
                            Color.compound.bgSubtleSecondary
                        }
                        .aspectRatio(contentMode: .fill)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
            }
                
            VStack(alignment: .leading, spacing: 4) {
                Text(item.filename ?? "")
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
                    
                if let contentType = item.contentType {
                    Group {
                        if let fileSize = item.fileSize {
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
                context.send(viewAction: .redactConfirmation(item: item))
            }
            .buttonStyle(.compound(.primary))
            
            Button(L10n.actionCancel) {
                dismiss()
            }
            .buttonStyle(.compound(.tertiary))
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
        if case let .media(mediaItem) = viewModel.state.currentItem {
            TimelineMediaPreviewRedactConfirmationView(item: mediaItem, context: viewModel.context)
        }
    }
    
    static func makeViewModel(contentType: UTType? = nil) -> TimelineMediaPreviewViewModel {
        let item = ImageRoomTimelineItem(id: .randomEvent,
                                         timestamp: .mock,
                                         isOutgoing: false,
                                         isEditable: true,
                                         canBeRepliedTo: true,
                                         sender: .init(id: "@alice:matrix.org",
                                                       displayName: "Alice",
                                                       avatarURL: .mockMXCUserAvatar),
                                         content: .init(filename: "Amazing Image.jpeg",
                                                        imageInfo: .mockImage,
                                                        thumbnailInfo: .mockThumbnail,
                                                        contentType: contentType))
        
        let timelineController = MockTimelineController(timelineKind: .media(.mediaFilesScreen))
        timelineController.timelineItems = [item]
        return TimelineMediaPreviewViewModel(initialItem: item,
                                             timelineViewModel: TimelineViewModel.mock(timelineKind: timelineController.timelineKind,
                                                                                       timelineController: timelineController),
                                             mediaProvider: MediaProviderMock(configuration: .init()),
                                             photoLibraryManager: PhotoLibraryManagerMock(.init()),
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             appMediator: AppMediatorMock())
    }
}
