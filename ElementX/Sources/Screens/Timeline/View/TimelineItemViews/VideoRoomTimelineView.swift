//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct VideoRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: VideoRoomTimelineItem
    
    @State private var contentScanningFailure: ContentScanningFailure?
    
    private var hasMediaCaption: Bool {
        timelineItem.content.caption != nil
    }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            // The caption sits 8pts below the content scanner failure placeholder, 4pts below the media.
            VStack(alignment: .leading, spacing: contentScanningFailure == nil ? 4 : 8) {
                ContentScanningView(contentScannerService: context?.contentScannerService,
                                    mediaSource: timelineItem.content.videoInfo.source) {
                    thumbnail
                        .timelineMediaFrame(imageInfo: timelineItem.content.thumbnailInfo)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(L10n.commonVideo)
                        // This clip shape is distinct from the one in the styler as that one
                        // operates on the entire message so wouldn't round the bottom corners.
                        .clipShape(RoundedRectangle(cornerRadius: hasMediaCaption ? 6 : 0))
                        .onTapGesture {
                            context?.send(viewAction: .mediaTapped(itemID: timelineItem.id))
                        }
                } scanningContent: {
                    placeholder
                        .overlay { ProgressView() }
                        .timelineMediaFrame(imageInfo: timelineItem.content.thumbnailInfo)
                } unsafeContent: { failure in
                    ContentScanningFailureView(failure: failure)
                }
                
                if let attributedCaption = timelineItem.content.formattedCaption {
                    FormattedBodyText(attributedString: attributedCaption,
                                      trailingReservedSize: timelineItem.trailingReservedSize,
                                      boostFontSize: timelineItem.shouldBoost)
                } else if let caption = timelineItem.content.caption {
                    FormattedBodyText(text: caption,
                                      trailingReservedSize: timelineItem.trailingReservedSize,
                                      boostFontSize: timelineItem.shouldBoost)
                }
            }
            .onPreferenceChange(ContentScanningFailurePreferenceKey.self) { contentScanningFailure = $0 }
        }
    }
    
    @ViewBuilder
    var thumbnail: some View {
        if let thumbnailSource = timelineItem.content.thumbnailInfo?.source {
            LoadableImage(mediaSource: thumbnailSource,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID),
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.thumbnailInfo?.size,
                          mediaProvider: context?.mediaProvider) { imageView in
                imageView
                    .overlay { playIcon }
            } placeholder: {
                placeholder
            }
        } else {
            playIcon
        }
    }
    
    var playIcon: some View {
        CompoundIcon(\.playSolid, size: .medium, relativeTo: .compound.headingLG)
            .foregroundStyle(.compound.iconPrimary)
            .padding(13)
            .background {
                ZStack {
                    Circle().fill(.compound.bgSubtleSecondary)
                    Circle().stroke(.compound.borderInteractiveSecondary)
                }
            }
    }
    
    var placeholder: some View {
        Rectangle()
            .foregroundStyle(timelineItem.isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming)
            .opacity(0.3)
    }
}

struct VideoRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    static let scanningViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: nil)))
    static let unsafeViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: false)))
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20.0) {
                VideoRoomTimelineView(timelineItem: makeTimelineItem())
                VideoRoomTimelineView(timelineItem: makeTimelineItem(isEdited: true))
                
                // Blurhash item?
                
                VideoRoomTimelineView(timelineItem: makeTimelineItem(caption: "This is a great video 😎"))
                VideoRoomTimelineView(timelineItem: makeTimelineItem(caption: "This is a great video with a really long multiline caption",
                                                                     isEdited: true))
            }
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
        .previewLayout(.fixed(width: 390, height: 975))
        .padding(.bottom, 20)
        
        VStack(spacing: 20.0) {
            VideoRoomTimelineView(timelineItem: makeTimelineItem())
                .environmentObject(scanningViewModel.context)
                .environment(\.timelineContext, scanningViewModel.context)
            VideoRoomTimelineView(timelineItem: makeTimelineItem(caption: "This is an unsafe video."))
                .environmentObject(unsafeViewModel.context)
                .environment(\.timelineContext, unsafeViewModel.context)
        }
        .environmentObject(viewModel.context)
        .previewDisplayName("Content Scanner")
    }
    
    private static func makeTimelineItem(caption: String? = nil, isEdited: Bool = false) -> VideoRoomTimelineItem {
        VideoRoomTimelineItem(id: .randomEvent,
                              timestamp: .mock,
                              isOutgoing: false,
                              isEditable: false,
                              canBeRepliedTo: true,
                              sender: .init(id: "Bob"),
                              content: .init(filename: "video.mp4",
                                             caption: caption,
                                             videoInfo: .mockVideo,
                                             thumbnailInfo: .mockVideoThumbnail,
                                             blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW"),
                              properties: .init(isEdited: isEdited))
    }
}
