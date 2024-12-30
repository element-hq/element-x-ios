//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineMediaPreviewDetailsView: View {
    let item: TimelineMediaPreviewItem
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                details
                actions
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .padding(.top, 19) // For the drag indicator
        .presentationBackground(.compound.bgCanvasDefault)
        .preferredColorScheme(.dark)
        .sheet(item: $context.redactConfirmationItem) { item in
            TimelineMediaPreviewRedactConfirmationView(item: item, context: context)
        }
    }
    
    private var details: some View {
        VStack(alignment: .leading, spacing: 24) {
            DetailsRow(title: L10n.screenMediaDetailsUploadedBy) {
                HStack(spacing: 8) {
                    LoadableAvatarImage(url: item.sender.avatarURL,
                                        name: item.sender.displayName,
                                        contentID: item.sender.id,
                                        avatarSize: .user(on: .mediaPreviewDetails),
                                        mediaProvider: context.mediaProvider)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        if let displayName = item.sender.displayName {
                            Text(displayName)
                                .font(.compound.bodyMDSemibold)
                                .foregroundStyle(.compound.decorativeColor(for: item.sender.id).text)
                        }
                        
                        Text(item.sender.id)
                            .font(.compound.bodySM)
                            .foregroundStyle(.compound.textSecondary)
                    }
                }
            }
            
            DetailsRow(title: L10n.screenMediaDetailsUploadedOn) {
                Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
            }
            
            DetailsRow(title: L10n.screenMediaDetailsFilename) {
                Text(item.filename ?? "")
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
            }
            
            if let contentType = item.contentType {
                DetailsRow(title: L10n.screenMediaDetailsFileFormat) {
                    Group {
                        if let fileSize = item.fileSize {
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
                        context.send(viewAction: .menuAction(action, item: item))
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
                        context.send(viewAction: .menuAction(action, item: item))
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
    @Namespace private static var previewNamespace
    
    static let viewModel = makeViewModel(contentType: .jpeg, isOutgoing: true)
    static let unknownTypeViewModel = makeViewModel()
    static let presentedOnRoomViewModel = makeViewModel(isPresentedOnRoomScreen: true)
    
    static var previews: some View {
        TimelineMediaPreviewDetailsView(item: viewModel.state.currentItem,
                                        context: viewModel.context)
            .previewDisplayName("Image")
            .snapshotPreferences(expect: viewModel.context.$viewState.map { state in
                state.currentItemActions?.secondaryActions.contains(.redact) ?? false
            })
        
        TimelineMediaPreviewDetailsView(item: unknownTypeViewModel.state.currentItem,
                                        context: unknownTypeViewModel.context)
            .previewDisplayName("Unknown type")
        
        TimelineMediaPreviewDetailsView(item: presentedOnRoomViewModel.state.currentItem,
                                        context: presentedOnRoomViewModel.context)
            .previewDisplayName("Incoming on Room")
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
        let timelineController = MockRoomTimelineController(timelineKind: timelineKind)
        timelineController.timelineItems = [item]
        return TimelineMediaPreviewViewModel(context: .init(item: item,
                                                            viewModel: TimelineViewModel.mock(timelineKind: timelineKind,
                                                                                              timelineController: timelineController),
                                                            namespace: previewNamespace),
                                             mediaProvider: MediaProviderMock(configuration: .init()),
                                             photoLibraryManager: PhotoLibraryManagerMock(.init()),
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             appMediator: AppMediatorMock())
    }
}
