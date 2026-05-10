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

    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 8) {
                GalleryGridView(items: timelineItem.content.items,
                                uniqueID: timelineItem.id.uniqueID,
                                mediaProvider: context?.mediaProvider) {
                    context?.send(viewAction: .mediaTapped(itemID: timelineItem.id))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(UntranslatedL10n.commonAttachmentsCount(timelineItem.content.items.count))

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
            .frame(width: GalleryGridView.groupWidth, alignment: .leading)
        }
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
}
