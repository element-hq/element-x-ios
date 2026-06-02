//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct GalleryRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: GalleryRoomTimelineItem

    private var hasMediaCaption: Bool {
        timelineItem.content.caption != nil
    }

    /// A gallery falls back to a vertical file-list layout when any of its items lacks a thumbnail
    /// (typically audio or generic files). Mixed galleries (image/video + file) also use the list
    /// — a grid of mostly-icons looks worse than a tidy list.
    private var usesListLayout: Bool {
        timelineItem.content.items.contains { !$0.hasThumbnail }
    }

    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 8) {
                if usesListLayout {
                    GalleryListView(items: timelineItem.content.items,
                                    uniqueID: timelineItem.id.uniqueID,
                                    mediaProvider: context?.mediaProvider) { index in
                        tap(index: index)
                    }
                } else {
                    GalleryGridView(items: timelineItem.content.items,
                                    uniqueID: timelineItem.id.uniqueID,
                                    mediaProvider: context?.mediaProvider) { index in
                        tap(index: index)
                    }
                }

                if hasMediaCaption {
                    if usesListLayout {
                        GalleryListView.galleryDivider
                    }
                    caption
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(UntranslatedL10n.commonAttachmentsCount(timelineItem.content.items.count))
            .frame(width: GalleryGridView.groupWidth, alignment: .leading)
        }
    }

    @ViewBuilder
    private var caption: some View {
        if let attributedCaption = timelineItem.content.formattedCaption {
            FormattedBodyText(attributedString: attributedCaption,
                              additionalWhitespacesCount: timelineItem.additionalWhitespaces(),
                              boostFontSize: timelineItem.shouldBoost)
        } else if let caption = timelineItem.content.caption {
            FormattedBodyText(text: caption,
                              additionalWhitespacesCount: timelineItem.additionalWhitespaces(),
                              boostFontSize: timelineItem.shouldBoost)
        }
    }

    private func tap(index: Int) {
        context?.send(viewAction: .galleryItemTapped(itemID: timelineItem.id, index: index))
    }
}

// MARK: - Previews

struct GalleryRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock

    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                GalleryRoomTimelineView(timelineItem: makeItem(itemCount: 1))
                GalleryRoomTimelineView(timelineItem: makeItem(itemCount: 2))
                GalleryRoomTimelineView(timelineItem: makeItem(itemCount: 3))
                GalleryRoomTimelineView(timelineItem: makeItem(itemCount: 4))
                GalleryRoomTimelineView(timelineItem: makeItem(itemCount: 5))
                GalleryRoomTimelineView(timelineItem: makeItem(itemCount: 7, caption: "A trip to remember 🌅"))
                GalleryRoomTimelineView(timelineItem: makeFileListItem(caption: "Quarterly reports"))
            }
            .padding(.vertical, 20)
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
    }

    private static func makeItem(itemCount: Int, caption: String? = nil) -> GalleryRoomTimelineItem {
        let items: [GalleryItem] = (0..<itemCount).map { index in
            let isVideo = index.isMultiple(of: 3)
            return GalleryItem(id: "preview-\(index)",
                               filename: isVideo ? "clip-\(index).mp4" : "image-\(index).jpg",
                               kind: isVideo ? .video : .image,
                               mediaSource: ImageInfoProxy.mockImage.source,
                               thumbnailSource: ImageInfoProxy.mockThumbnail.source,
                               size: .init(width: 1920, height: 1080),
                               blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW",
                               duration: isVideo ? 42 : nil,
                               contentType: isVideo ? .mpeg4Movie : .jpeg)
        }

        return GalleryRoomTimelineItem(id: .randomEvent,
                                       timestamp: .mock,
                                       isOutgoing: false,
                                       isEditable: false,
                                       canBeRepliedTo: true,
                                       sender: .init(id: "Bob"),
                                       content: .init(body: "Gallery (\(itemCount) items)",
                                                      caption: caption,
                                                      items: items),
                                       properties: .init())
    }

    private static func makeFileListItem(caption: String?) -> GalleryRoomTimelineItem {
        let items: [GalleryItem] = [
            GalleryItem(id: "preview-image",
                        filename: "photo.jpg",
                        kind: .image,
                        mediaSource: ImageInfoProxy.mockImage.source,
                        thumbnailSource: ImageInfoProxy.mockThumbnail.source,
                        size: .init(width: 1920, height: 1080),
                        blurhash: nil,
                        duration: nil,
                        contentType: .jpeg),
            GalleryItem(id: "preview-pdf",
                        filename: "report.pdf",
                        kind: .file,
                        mediaSource: nil,
                        thumbnailSource: nil,
                        size: nil,
                        blurhash: nil,
                        duration: nil,
                        contentType: .pdf),
            GalleryItem(id: "preview-audio",
                        filename: "meeting.m4a",
                        kind: .audio,
                        mediaSource: nil,
                        thumbnailSource: nil,
                        size: nil,
                        blurhash: nil,
                        duration: 65,
                        contentType: .mpeg4Audio)
        ]

        return GalleryRoomTimelineItem(id: .randomEvent,
                                       timestamp: .mock,
                                       isOutgoing: false,
                                       isEditable: false,
                                       canBeRepliedTo: true,
                                       sender: .init(id: "Bob"),
                                       content: .init(body: "Mixed gallery",
                                                      caption: caption,
                                                      items: items),
                                       properties: .init())
    }
}
