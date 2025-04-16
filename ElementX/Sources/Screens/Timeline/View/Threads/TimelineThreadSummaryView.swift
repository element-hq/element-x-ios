//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineThreadSummaryView: View {
    let threadSummary: TimelineItemThreadSummary
    var onTap: (() -> Void)?
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            content
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch threadSummary {
        case .loaded(let senderID, let sender, let latestEventContent):
            switch latestEventContent {
            case .message(let content):
                switch content {
                case .audio(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.caption ?? content.filename,
                               formattedBody: content.formattedCaption)
                case .emote(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.body,
                               formattedBody: content.formattedBody)
                case .file(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.caption ?? content.filename,
                               formattedBody: content.formattedCaption)
                case .image(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.caption ?? content.filename,
                               formattedBody: content.formattedCaption)
                case .notice(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.body,
                               formattedBody: content.formattedBody)
                case .text(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.body,
                               formattedBody: content.formattedBody)
                case .video(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.caption ?? content.filename,
                               formattedBody: content.formattedCaption)
                case .voice:
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: L10n.commonVoiceMessage,
                               formattedBody: nil)
                case .location:
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: L10n.commonSharedLocation,
                               formattedBody: nil)
                }
            case .poll(let question):
                ThreadView(senderID: senderID,
                           sender: sender,
                           plainBody: question,
                           formattedBody: nil)
            case .redacted:
                ThreadView(senderID: senderID,
                           sender: sender,
                           plainBody: L10n.commonMessageRemoved,
                           formattedBody: nil)
            }
        default:
            LoadingThreadView()
        }
    }
    
    private struct LoadingThreadView: View {
        var body: some View {
            ThreadView(senderID: "@alice:matrix.org", sender: nil, plainBody: "Hello world", formattedBody: nil)
                .redacted(reason: .placeholder)
        }
    }
    
    private struct ThreadView: View {
        @EnvironmentObject private var context: TimelineViewModel.Context
        
        let senderID: String
        let sender: TimelineItemSender?
        let plainBody: String
        let formattedBody: AttributedString?
        
        var body: some View {
            HStack(spacing: 8) {
                CompoundIcon(\.threads, size: .xSmall, relativeTo: .compound.bodyXS)
                    .foregroundColor(.compound.iconSecondary)
                
                LoadableAvatarImage(url: sender?.avatarURL,
                                    name: sender?.displayName,
                                    contentID: sender?.id,
                                    avatarSize: .user(on: .threadSummary),
                                    mediaProvider: context.mediaProvider)
                
                Text(sender?.disambiguatedDisplayName ?? senderID)
                    .font(.compound.bodyXSSemibold)
                    .foregroundColor(.compound.textPrimary)
                    .accessibilityLabel(L10n.commonInReplyTo(sender?.disambiguatedDisplayName ?? senderID))
                
                Text(context.viewState.buildMessagePreview(formattedBody: formattedBody, plainBody: plainBody))
                    .font(.compound.bodyXS)
                    .foregroundColor(.compound.textSecondary)
                    .tint(.compound.textLinkExternal)
                    .lineLimit(2)
            }
            .padding(.vertical, 4.0)
            .padding(.horizontal, 8.0)
            .background(Color.compound.bgSubtlePrimary)
            .cornerRadius(8)
        }
    }
}

struct TimelineThreadSummaryView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static let attributedStringWithMention = {
        var attributedString = AttributedString("To be replaced")
        attributedString.userID = "@alice:matrix.org"
        return attributedString
    }()
    
    static let attributedStringWithAtRoomMention = {
        var attributedString = AttributedString("to be replaced")
        attributedString.allUsersMention = true
        return attributedString
    }()
    
    static let attributedStringWithRoomAliasMention = {
        var attributedString = AttributedString("to be replaced")
        attributedString.roomAlias = "#room:matrix.org"
        return attributedString
    }()
    
    static let attributedStringWithRoomIDMention = {
        var attributedString = AttributedString("to be replaced")
        attributedString.roomID = "!room:matrix.org"
        return attributedString
    }()
    
    static let attributedStringWithEventOnRoomIDMention = {
        var attributedString = AttributedString("to be replaced")
        attributedString.eventOnRoomID = .init(roomID: "!room:matrix.org", eventID: "$event")
        return attributedString
    }()
    
    static let attributedStringWithEventOnRoomAliasMention = {
        var attributedString = AttributedString("to be replaced")
        attributedString.eventOnRoomAlias = .init(alias: "#room:matrix.org", eventID: "$event")
        return attributedString
    }()
    
    static var previewItems: [TimelineThreadSummaryView] {
        [
            TimelineThreadSummaryView(threadSummary: .notLoaded),
            
            TimelineThreadSummaryView(threadSummary: .loading),
            
            TimelineThreadSummaryView(threadSummary: .error(message: "Error")),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.text(.init(body: "This is a threaded message"))))),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "Hello world"))))),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.audio(.init(filename: "audio.m4a",
                                                                                                       caption: "Some audio",
                                                                                                       duration: 0,
                                                                                                       waveform: nil,
                                                                                                       source: nil,
                                                                                                       fileSize: nil,
                                                                                                       contentType: nil))))),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.file(.init(filename: "file.txt",
                                                                                                      caption: "Some file",
                                                                                                      source: nil,
                                                                                                      fileSize: nil,
                                                                                                      thumbnailSource: nil,
                                                                                                      contentType: nil))))),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.image(.init(filename: "image.jpg",
                                                                                                       caption: "Some image",
                                                                                                       imageInfo: .mockImage,
                                                                                                       thumbnailInfo: .mockThumbnail))))),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.video(.init(filename: "video.mp4",
                                                                                                       caption: "Some video",
                                                                                                       videoInfo: .mockVideo,
                                                                                                       thumbnailInfo: .mockVideoThumbnail))))),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.location(.init(body: ""))))),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.voice(.init(filename: "voice-message.ogg",
                                                                                                       caption: "Some voice message",
                                                                                                       duration: 0,
                                                                                                       waveform: nil,
                                                                                                       source: nil,
                                                                                                       fileSize: nil,
                                                                                                       contentType: nil))))),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .poll(question: "Do you like polls?"))),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .redacted)),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithMention))))),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithAtRoomMention))))),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithRoomAliasMention))))),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithRoomIDMention))))),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithEventOnRoomIDMention))))),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithEventOnRoomAliasMention)))))
        ]
    }
    
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(0..<previewItems.count, id: \.self) { index in
                previewItems[index]
            }
        }
        .padding()
        .environmentObject(viewModel.context)
        .previewLayout(.sizeThatFits)
    }
}
