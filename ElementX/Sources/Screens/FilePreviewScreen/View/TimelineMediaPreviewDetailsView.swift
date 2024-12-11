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
    
    private var currentItem: TimelineMediaPreviewItem { context.viewState.currentItem }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                details
                actions
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 19) // For the drag indicator
        .sheet(isPresented: $context.isPresentingRedactConfirmation) {
            TimelineMediaPreviewRedactConfirmationView(context: context)
        }
    }
    
    private var details: some View {
        VStack(alignment: .leading, spacing: 24) {
            DetailsRow(title: L10n.screenMediaDetailsUploadedBy) {
                HStack(spacing: 8) {
                    LoadableAvatarImage(url: currentItem.sender.avatarURL,
                                        name: currentItem.sender.displayName,
                                        contentID: currentItem.sender.id,
                                        avatarSize: .user(on: .mediaPreviewDetails),
                                        mediaProvider: context.mediaProvider)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        if let displayName = currentItem.sender.displayName {
                            Text(displayName)
                                .font(.compound.bodyMDSemibold)
                                .foregroundStyle(.compound.decorativeColor(for: currentItem.sender.id).text)
                        }
                        
                        Text(currentItem.sender.id)
                            .font(.compound.bodySM)
                            .foregroundStyle(.compound.textSecondary)
                    }
                }
            }
            
            DetailsRow(title: L10n.screenMediaDetailsUploadedOn) {
                Text(currentItem.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
            }
            
            DetailsRow(title: L10n.screenMediaDetailsFilename) {
                Text(currentItem.filename ?? "")
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
            }
            
            if let contentType = currentItem.contentType {
                DetailsRow(title: L10n.screenMediaDetailsFileFormat) {
                    Group {
                        if let fileSize = currentItem.fileSize {
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
    
    @ViewBuilder
    private var actions: some View {
        if let actions = context.viewState.currentItemActions {
            VStack(spacing: 0) {
                if !actions.actions.isEmpty {
                    Divider()
                        .background(Color.compound.bgSubtlePrimary)
                }
                
                ForEach(actions.actions, id: \.self) { action in
                    Button(role: action.isDestructive ? .destructive : nil) {
                        context.send(viewAction: .menuAction(action))
                    } label: {
                        action.label
                    }
                    .buttonStyle(.menuSheet)
                }
                
                if !actions.secondaryActions.isEmpty {
                    Divider()
                        .background(Color.compound.bgSubtlePrimary)
                }
                
                ForEach(actions.secondaryActions, id: \.self) { action in
                    Button(role: action.isDestructive ? .destructive : nil) {
                        context.send(viewAction: .menuAction(action))
                    } label: {
                        action.label
                    }
                    .buttonStyle(.menuSheet)
                }
            }
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
    static let viewModel = makeViewModel(contentType: .jpeg, isOutgoing: true)
    static let unknownTypeViewModel = makeViewModel()
    static let presentedOnRoomViewModel = makeViewModel(isPresentedOnRoomScreen: true)
    
    static var previews: some View {
        TimelineMediaPreviewDetailsView(context: viewModel.context)
            .previewDisplayName("Image")
            .snapshotPreferences(delay: 0.1)
        TimelineMediaPreviewDetailsView(context: unknownTypeViewModel.context)
            .previewDisplayName("Unknown type")
            .snapshotPreferences(delay: 0.1)
        
        TimelineMediaPreviewDetailsView(context: presentedOnRoomViewModel.context)
            .previewDisplayName("Incoming on Room")
            .snapshotPreferences(delay: 0.1)
    }
    
    static func makeViewModel(contentType: UTType? = nil, isOutgoing: Bool = false, isPresentedOnRoomScreen: Bool = false) -> TimelineMediaPreviewViewModel {
        let item = ImageRoomTimelineItem(id: .randomEvent,
                                         timestamp: .mock,
                                         isOutgoing: isOutgoing,
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
        
        let timelineKind = TimelineKind.media(isPresentedOnRoomScreen ? .roomScreen : .mediaFilesScreen)
        return TimelineMediaPreviewViewModel(initialItem: item,
                                             timelineViewModel: TimelineViewModel.mock(timelineKind: timelineKind),
                                             mediaProvider: MediaProviderMock(configuration: .init()),
                                             userIndicatorController: UserIndicatorControllerMock())
    }
}
