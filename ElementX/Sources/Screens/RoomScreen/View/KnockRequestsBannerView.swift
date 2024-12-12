//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct KnockRequestInfo: Equatable {
    let displayName: String?
    let avatarURL: URL?
    let userID: String
    let reason: String?
    let eventID: String
}

struct KnockRequestsBannerView: View {
    let requests: [KnockRequestInfo]
    let onDismiss: () -> Void
    let onAccept: ((String) -> Void)?
    let onViewAll: () -> Void
    var mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        mainContent
            .padding(16)
            .background(.compound.bgCanvasDefaultLevel1, in: RoundedRectangle(cornerRadius: 12))
            .compositingGroup()
            .shadow(color: Color(red: 0.11, green: 0.11, blue: 0.13).opacity(0.1), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if requests.count == 1 {
            SingleKnockRequestBannerContent(request: requests[0],
                                            onDismiss: onDismiss,
                                            onAccept: onAccept,
                                            onViewAll: onViewAll,
                                            mediaProvider: mediaProvider)
        } else if requests.count > 1 {
            MultipleKnockRequestsBannerContent(requests: requests,
                                               onDismiss: onDismiss,
                                               onViewAll: onViewAll,
                                               mediaProvider: mediaProvider)
        } else {
            EmptyView()
        }
    }
}

private struct SingleKnockRequestBannerContent: View {
    let request: KnockRequestInfo
    let onDismiss: () -> Void
    let onAccept: ((String) -> Void)?
    let onViewAll: () -> Void
    var mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        VStack(spacing: 14) {
            header
            if let reason = request.reason {
                Text(reason)
                    .lineLimit(2)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            actions
        }
    }
    
    private var header: some View {
        HStack(spacing: 10) {
            LoadableAvatarImage(url: request.avatarURL,
                                name: request.displayName,
                                contentID: request.userID,
                                avatarSize: .user(on: .knockingUserBanner), mediaProvider: mediaProvider)
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    Text(L10n.screenRoomSingleKnockRequestTitle(request.displayName ?? request.userID))
                        .lineLimit(2)
                        .font(.compound.bodyMDSemibold)
                        .foregroundStyle(.compound.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    KnockRequestsBannerDismissButton(onDismiss: onDismiss)
                }
                if request.displayName != nil {
                    Text(request.userID)
                        .lineLimit(2)
                        .font(.compound.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private var actions: some View {
        HStack(spacing: 12) {
            Button(L10n.screenRoomSingleKnockRequestViewButtonTitle, action: onViewAll)
                .buttonStyle(.compound(.secondary, size: .medium))
            if let onAccept {
                Button(L10n.screenRoomSingleKnockRequestAcceptButtonTitle) { onAccept(request.eventID) }
                    .buttonStyle(.compound(.primary, size: .medium))
            }
        }
        .padding(.top, request.reason == nil ? 0 : 2)
        .frame(maxWidth: .infinity)
    }
}

private struct MultipleKnockRequestsBannerContent: View {
    let requests: [KnockRequestInfo]
    let onDismiss: () -> Void
    let onViewAll: () -> Void
    var mediaProvider: MediaProviderProtocol?
    
    private var avatars: [StackedAvatarInfo] {
        requests
            .prefix(3)
            .map { .init(url: $0.avatarURL, name: $0.displayName, contentID: $0.userID) }
    }
    
    private var multipleKnockRequestsTitle: String {
        guard let first = requests.first else {
            return ""
        }
        
        let string = first.displayName ?? first.userID
        return L10n.tr("Localizable", "screen_room_multiple_knock_requests_title", string, avatars.count - 1)
    }
    
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                StackedAvatarsView(overlap: 16, lineWidth: 2, avatars: avatars, avatarSize: .user(on: .knockingUsersBannerStack), mediaProvider: mediaProvider)
                HStack(alignment: .top, spacing: 0) {
                    Text(multipleKnockRequestsTitle)
                        .lineLimit(2)
                        .font(.compound.bodyMDSemibold)
                        .foregroundStyle(.compound.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    KnockRequestsBannerDismissButton(onDismiss: onDismiss)
                }
            }
            Button(L10n.screenRoomMultipleKnockRequestsViewAllButtonTitle) {
                onViewAll()
            }
            .buttonStyle(.compound(.primary, size: .medium))
        }
    }
}

private struct KnockRequestsBannerDismissButton: View {
    let onDismiss: () -> Void
    
    var body: some View {
        Button {
            onDismiss()
        } label: {
            CompoundIcon(\.close, size: .medium, relativeTo: .compound.bodySMSemibold)
                .foregroundColor(.compound.iconTertiary)
        }
        .alignmentGuide(.top) { _ in
            3
        }
    }
}

struct KnockRequestsBannerView_Previews: PreviewProvider, TestablePreview {
    static let singleRequest: [KnockRequestInfo] = [.init(displayName: "Alice", avatarURL: nil, userID: "@alice:matrix.org", reason: nil, eventID: "1")]
    
    static let singleRequestWithReason: [KnockRequestInfo] = [.init(displayName: "Alice",
                                                                    avatarURL: nil,
                                                                    userID: "@alice:matrix.org",
                                                                    reason: "Hey, I’d like to join this room because of xyz topic and I’d like to participate in the room.",
                                                                    eventID: "1")]
    
    static let singleRequestNoDisplayName: [KnockRequestInfo] = [.init(displayName: nil, avatarURL: nil, userID: "@alice:matrix.org", reason: nil, eventID: "1")]
    
    static let multipleRequests: [KnockRequestInfo] = [
        .init(displayName: "Alice", avatarURL: nil, userID: "@alice:matrix.org", reason: nil, eventID: "1"),
        .init(displayName: "Bob", avatarURL: nil, userID: "@bob:matrix.org", reason: nil, eventID: "2"),
        .init(displayName: "Charlie", avatarURL: nil, userID: "@charlie:matrix.org", reason: nil, eventID: "3"),
        .init(displayName: "Dan", avatarURL: nil, userID: "@dan:matrix.org", reason: nil, eventID: "4"),
        .init(displayName: "Test", avatarURL: nil, userID: "@dan:matrix.org", reason: nil, eventID: "5")
    ]
    
    static var previews: some View {
        KnockRequestsBannerView(requests: singleRequest) { } onAccept: { _ in } onViewAll: { }
            .previewDisplayName("Single Request")
        // swiftlint:disable:next trailing_closure
        KnockRequestsBannerView(requests: singleRequest, onDismiss: { }, onAccept: nil, onViewAll: { })
            .previewDisplayName("Single Request, no accept action")
        KnockRequestsBannerView(requests: singleRequestWithReason) { } onAccept: { _ in } onViewAll: { }
            .previewDisplayName("Single Request with reason")
        KnockRequestsBannerView(requests: singleRequestNoDisplayName) { } onAccept: { _ in } onViewAll: { }
            .previewDisplayName("Single Request, No Display Name")
        KnockRequestsBannerView(requests: multipleRequests) { } onAccept: { _ in } onViewAll: { }
            .previewDisplayName("Multiple Requests")
    }
}
