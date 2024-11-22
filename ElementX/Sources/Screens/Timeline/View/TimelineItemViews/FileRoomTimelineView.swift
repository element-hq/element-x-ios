//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct FileRoomTimelineView: View {
    let timelineItem: FileRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            MediaFileRoomTimelineContent(filename: timelineItem.content.filename,
                                         fileSize: timelineItem.content.fileSize,
                                         caption: timelineItem.content.caption,
                                         formattedCaption: timelineItem.content.formattedCaption,
                                         additionalWhitespaces: timelineItem.additionalWhitespaces())
                .accessibilityLabel(L10n.commonFile)
        }
    }
}

// MARK: Content

struct MediaFileRoomTimelineContent: View {
    let filename: String
    let fileSize: UInt?
    let caption: String?
    let formattedCaption: AttributedString?
    let additionalWhitespaces: Int
    var isAudioFile = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            filePreview
            
            if let formattedCaption {
                FormattedBodyText(attributedString: formattedCaption,
                                  additionalWhitespacesCount: additionalWhitespaces)
            } else if let caption {
                FormattedBodyText(text: caption,
                                  additionalWhitespacesCount: additionalWhitespaces)
            }
        }
    }
    
    var filePreview: some View {
        Label {
            HStack(spacing: 4) {
                Text(filename)
                    .truncationMode(.middle)
                
                if let fileSize {
                    Text("(\(fileSize.formatted(.byteCount(style: .file))))")
                        .layoutPriority(1) // We want the filename to truncate rather than the size.
                }
            }
            .font(.compound.bodyLG)
            .foregroundStyle(.compound.textPrimary)
            .lineLimit(1)
        } icon: {
            icon
                .foregroundColor(.compound.iconPrimary)
                .padding(8)
                .background(.compound.iconOnSolidPrimary, in: Circle())
        }
        .labelStyle(.custom(spacing: 8, alignment: .center))
        .padding(.horizontal, 4) // Add to the styler's padding of 8, as we use the default insets for the caption.
    }
    
    var icon: CompoundIcon {
        if isAudioFile {
            CompoundIcon(\.audio)
        } else {
            CompoundIcon(\.attachment)
        }
    }
}

// MARK: - Previews

struct FileRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        VStack(spacing: 20.0) {
            FileRoomTimelineView(timelineItem: makeItem(filename: "document.pdf"))
            
            FileRoomTimelineView(timelineItem: makeItem(filename: "document.pdf",
                                                        fileSize: 3 * 1024 * 1024))
            
            FileRoomTimelineView(timelineItem: makeItem(filename: "spreadsheet.xlsx",
                                                        fileSize: 17 * 1024,
                                                        caption: "The important figures you asked me to send over."))
            
            FileRoomTimelineView(timelineItem: makeItem(filename: "document.txt",
                                                        fileSize: 456,
                                                        caption: "Plain caption",
                                                        formattedCaption: "Formatted caption"))
        }
        .environmentObject(viewModel.context)
    }
    
    static func makeItem(filename: String,
                         fileSize: UInt? = nil,
                         caption: String? = nil,
                         formattedCaption: AttributedString? = nil) -> FileRoomTimelineItem {
        .init(id: .randomEvent,
              timestamp: "Now",
              isOutgoing: false,
              isEditable: false,
              canBeRepliedTo: true,
              isThreaded: false,
              sender: .init(id: "Bob"),
              content: .init(filename: filename,
                             caption: caption,
                             formattedCaption: formattedCaption,
                             source: nil,
                             fileSize: fileSize,
                             thumbnailSource: nil,
                             contentType: nil))
    }
}
