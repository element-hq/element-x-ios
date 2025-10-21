//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
        case .loaded(let senderID, let sender, let latestEventContent, let numberOfReplies):
            switch latestEventContent {
            case .message(let content):
                switch content {
                case .audio(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.caption ?? content.filename,
                               formattedBody: content.formattedCaption,
                               numberOfReplies: numberOfReplies)
                case .emote(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.body,
                               formattedBody: content.formattedBody,
                               numberOfReplies: numberOfReplies)
                case .file(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.caption ?? content.filename,
                               formattedBody: content.formattedCaption,
                               numberOfReplies: numberOfReplies)
                case .image(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.caption ?? content.filename,
                               formattedBody: content.formattedCaption,
                               numberOfReplies: numberOfReplies)
                case .notice(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.body,
                               formattedBody: content.formattedBody,
                               numberOfReplies: numberOfReplies)
                case .text(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.body,
                               formattedBody: content.formattedBody,
                               numberOfReplies: numberOfReplies)
                case .video(let content):
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: content.caption ?? content.filename,
                               formattedBody: content.formattedCaption,
                               numberOfReplies: numberOfReplies)
                case .voice:
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: L10n.commonVoiceMessage,
                               formattedBody: nil,
                               numberOfReplies: numberOfReplies)
                case .location:
                    ThreadView(senderID: senderID,
                               sender: sender,
                               plainBody: L10n.commonSharedLocation,
                               formattedBody: nil,
                               numberOfReplies: numberOfReplies)
                }
            case .poll(let question):
                ThreadView(senderID: senderID,
                           sender: sender,
                           plainBody: question,
                           formattedBody: nil,
                           numberOfReplies: numberOfReplies)
            case .redacted:
                ThreadView(senderID: senderID,
                           sender: sender,
                           plainBody: L10n.commonMessageRemoved,
                           formattedBody: nil,
                           numberOfReplies: numberOfReplies)
            }
        default:
            LoadingThreadView()
        }
    }
    
    private struct LoadingThreadView: View {
        var body: some View {
            ThreadView(senderID: "@alice:matrix.org",
                       sender: nil,
                       plainBody: "Hello world",
                       formattedBody: nil,
                       numberOfReplies: 42)
                .redacted(reason: .placeholder)
                .accessibilityLabel(L10n.commonLoading)
        }
    }
    
    private struct ThreadView: View {
        @EnvironmentObject private var context: TimelineViewModel.Context
        
        let senderID: String
        let sender: TimelineItemSender?
        let plainBody: String
        let formattedBody: AttributedString?
        let numberOfReplies: Int
        
        var body: some View {
            HStack(spacing: 4) {
                CompoundIcon(\.threads, size: .xSmall, relativeTo: .compound.bodyXS)
                    .foregroundColor(.compound.iconSecondary)
                    .accessibilityLabel(L10n.commonThread)
                
                Text(L10n.commonReplies(numberOfReplies))
                    .font(.compound.bodyXSSemibold)
                    .foregroundColor(.compound.textPrimary)
                
                LoadableAvatarImage(url: sender?.avatarURL,
                                    name: sender?.displayName,
                                    contentID: senderID,
                                    avatarSize: .user(on: .threadSummary),
                                    mediaProvider: context.mediaProvider)
                    .accessibilityHidden(true)
                
                Text(sender?.disambiguatedDisplayName ?? senderID)
                    .font(.compound.bodyXSSemibold)
                    .foregroundColor(.compound.textPrimary)
                    .accessibilityLabel(L10n.commonInReplyTo(sender?.disambiguatedDisplayName ?? senderID))
                
                Text(context.viewState.buildMessagePreview(formattedBody: formattedBody, plainBody: plainBody))
                    .font(.compound.bodyXS)
                    .foregroundColor(.compound.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .lineLimit(1)
            .padding(.vertical, 7.0)
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
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice McAliceFace"),
                                                             latestEventContent: .message(.text(.init(body: "This is a very long, multi-lined, threaded message"))),
                                                             numberOfReplies: 42)),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "Hello world"))),
                                                             numberOfReplies: 42)),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.audio(.init(filename: "audio.m4a",
                                                                                                       caption: "Some audio",
                                                                                                       duration: 0,
                                                                                                       waveform: nil,
                                                                                                       source: nil,
                                                                                                       fileSize: nil,
                                                                                                       contentType: nil))),
                                                             numberOfReplies: 42)),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.file(.init(filename: "file.txt",
                                                                                                      caption: "Some file",
                                                                                                      source: nil,
                                                                                                      fileSize: nil,
                                                                                                      thumbnailSource: nil,
                                                                                                      contentType: nil))),
                                                             numberOfReplies: 42)),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.image(.init(filename: "image.jpg",
                                                                                                       caption: "Some image",
                                                                                                       imageInfo: .mockImage,
                                                                                                       thumbnailInfo: .mockThumbnail))),
                                                             numberOfReplies: 42)),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.video(.init(filename: "video.mp4",
                                                                                                       caption: "Some video",
                                                                                                       videoInfo: .mockVideo,
                                                                                                       thumbnailInfo: .mockVideoThumbnail))),
                                                             numberOfReplies: 42)),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.location(.init(body: ""))),
                                                             numberOfReplies: 42)),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.voice(.init(filename: "voice-message.ogg",
                                                                                                       caption: "Some voice message",
                                                                                                       duration: 0,
                                                                                                       waveform: nil,
                                                                                                       source: nil,
                                                                                                       fileSize: nil,
                                                                                                       contentType: nil))),
                                                             numberOfReplies: 42)),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .poll(question: "Do you like polls?"),
                                                             numberOfReplies: 42)),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .redacted,
                                                             numberOfReplies: 42)),
            
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithMention))),
                                                             numberOfReplies: 42)),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithAtRoomMention))),
                                                             numberOfReplies: 42)),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithRoomAliasMention))),
                                                             numberOfReplies: 42)),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithRoomIDMention))),
                                                             numberOfReplies: 42)),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithEventOnRoomIDMention))),
                                                             numberOfReplies: 42)),
            TimelineThreadSummaryView(threadSummary: .loaded(senderID: "@alice:matrix.org",
                                                             sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                             latestEventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithEventOnRoomAliasMention))),
                                                             numberOfReplies: 42))
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
