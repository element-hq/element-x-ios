//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

struct StickerRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: StickerRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            ContentScanningView(contentScannerService: context?.contentScannerService,
                                mediaSource: timelineItem.imageInfo.source) {
                LoadableImage(mediaSource: timelineItem.imageInfo.source,
                              mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID),
                              blurhash: timelineItem.blurhash,
                              size: timelineItem.imageInfo.size,
                              mediaProvider: context?.mediaProvider) {
                    placeholder
                }
                .timelineMediaFrame(imageInfo: timelineItem.imageInfo)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(L10n.commonSticker), \(timelineItem.body)")
                .onTapGesture {
                    context?.send(viewAction: .mediaTapped(itemID: timelineItem.id))
                }
            } loading: {
                placeholder
                    .overlay { ProgressView() }
                    .timelineMediaFrame(imageInfo: timelineItem.imageInfo)
            } failed: { failure in
                ContentScanningFailureView(failure: failure)
            }
        }
    }
    
    private var placeholder: some View {
        Rectangle()
            .foregroundColor(timelineItem.isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming)
            .opacity(0.3)
    }
}

struct StickerRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    static let scanningViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: nil)))
    static let unsafeViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: false)))
    
    static var previews: some View {
        VStack(spacing: 20.0) {
            StickerRoomTimelineView(timelineItem: makeTimelineItem(body: "Some image"))
            
            StickerRoomTimelineView(timelineItem: makeTimelineItem(body: "Blurhashed image",
                                                                   blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW"))
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
        
        VStack(spacing: 20.0) {
            StickerRoomTimelineView(timelineItem: makeTimelineItem(body: "Scanning image"))
                .environmentObject(scanningViewModel.context)
                .environment(\.timelineContext, scanningViewModel.context)
            
            StickerRoomTimelineView(timelineItem: makeTimelineItem(body: "Unsafe image"))
                .environmentObject(unsafeViewModel.context)
                .environment(\.timelineContext, unsafeViewModel.context)
        }
        .environmentObject(viewModel.context)
        .previewDisplayName("Content Scanner")
    }
    
    private static func makeTimelineItem(body: String, blurhash: String? = nil) -> StickerRoomTimelineItem {
        StickerRoomTimelineItem(id: .randomEvent,
                                body: body,
                                timestamp: .mock,
                                isOutgoing: false,
                                isEditable: false,
                                canBeRepliedTo: true,
                                sender: .init(id: "Bob"),
                                imageInfo: .mockImage,
                                blurhash: blurhash)
    }
}
