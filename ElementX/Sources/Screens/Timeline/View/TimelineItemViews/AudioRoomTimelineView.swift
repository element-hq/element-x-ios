//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

struct AudioRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: AudioRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            MediaFileRoomTimelineContent(filename: timelineItem.content.filename,
                                         fileSize: timelineItem.content.fileSize,
                                         caption: timelineItem.content.caption,
                                         formattedCaption: timelineItem.content.formattedCaption,
                                         trailingReservedSize: timelineItem.trailingReservedSize,
                                         shouldBoost: timelineItem.shouldBoost,
                                         isAudioFile: true,
                                         contentScannerService: context?.contentScannerService,
                                         mediaSource: timelineItem.content.source) {
                context?.send(viewAction: .mediaTapped(itemID: timelineItem.id))
            }
            .accessibilityLabel(L10n.commonAudio)
        }
    }
}

struct AudioRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    static let scanningViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: nil)))
    static let unsafeViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: false)))
    
    static var previews: some View {
        VStack(spacing: 20) {
            AudioRoomTimelineView(timelineItem: makeItem(filename: "audio.ogg",
                                                         fileSize: 2 * 1024 * 1024))
            
            AudioRoomTimelineView(timelineItem: makeItem(filename: "Best Song Ever.mp3",
                                                         fileSize: 7 * 1024 * 1024,
                                                         caption: "This song rocks!"))
        }
        .environmentObject(viewModel.context)
        
        VStack(spacing: 20) {
            AudioRoomTimelineView(timelineItem: makeItem(filename: "scanning.ogg",
                                                         fileSize: 2 * 1024 * 1024,
                                                         caption: "The audio is being scanned."))
                .environmentObject(scanningViewModel.context)
                .environment(\.timelineContext, scanningViewModel.context)
            
            AudioRoomTimelineView(timelineItem: makeItem(filename: "unsafe.ogg",
                                                         fileSize: 2 * 1024 * 1024,
                                                         caption: "The audio is not safe."))
                .environmentObject(unsafeViewModel.context)
                .environment(\.timelineContext, unsafeViewModel.context)
        }
        .environmentObject(viewModel.context)
        .previewDisplayName("Content Scanner")
    }
    
    static func makeItem(filename: String, fileSize: UInt, caption: String? = nil) -> AudioRoomTimelineItem {
        .init(id: .randomEvent,
              timestamp: .mock,
              isOutgoing: false,
              isEditable: false,
              canBeRepliedTo: true,
              sender: .init(id: "Bob"),
              content: .init(filename: filename,
                             caption: caption,
                             duration: 300,
                             waveform: nil,
                             source: try? MediaSourceProxy(url: .mockMXCAudio, mimeType: nil),
                             fileSize: fileSize,
                             contentType: nil))
    }
}
