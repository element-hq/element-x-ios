//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct KnockRequestInfo {
    let displayName: String?
    let avatarURL: URL?
    let userID: String
    let reason: String?
}

struct KnockRequestsBannerView: View {
    let requests: [KnockRequestInfo]
    let onDismiss: () -> Void
    let onAccept: () -> Void
    let onViewAll: () -> Void
    var mediaProvider: MediaProviderProtocol?
    
    private var avatars: [StackedAvatarInfo] {
        requests
            .prefix(3)
            .map { .init(url: $0.avatarURL, name: $0.displayName, contentID: $0.userID) }
            .reversed()
    }
    
    var body: some View {
        mainContent
            .padding(16)
            .background(.compound.bgCanvasDefault)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if requests.count == 1,
           let request = requests.first {
            singleRequestView(request: request)
        } else {
            multipleRequestsView
        }
    }
    
    private func singleRequestView(request: KnockRequestInfo) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                LoadableAvatarImage(url: request.avatarURL,
                                    name: request.displayName,
                                    contentID: request.userID,
                                    avatarSize: .user(on: .knockingUser), mediaProvider: mediaProvider)
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        Text("Message")
                            .lineLimit(2)
                            .font(.compound.bodyMDSemibold)
                            .foregroundStyle(.compound.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        dismissButton
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
            if let reason = request.reason {
                Text(reason)
                    .lineLimit(2)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 12) {
                Button("View", action: {
                    onViewAll()
                })
                .buttonStyle(.compound(.secondary))
                Button("Accept", action: {
                    onViewAll()
                })
                .buttonStyle(.compound(.primary))
            }
            .padding(.top, request.reason == nil ? 0 : 2)
            .frame(maxWidth: .infinity)
        }
    }
    
    private var multipleRequestsView: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                StackedAvatarsView(overlap: 16, lineWidth: 2, shouldStackFromLast: true, avatars: avatars, avatarSize: .user(on: .knockingUsers), mediaProvider: mediaProvider)
                Text("Message")
                    .lineLimit(2)
                    .font(.compound.bodyMDSemibold)
                    .foregroundStyle(.compound.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                dismissButton
            }
            Button("View All") {
                onViewAll()
            }
            .buttonStyle(.compound(.primary))
        }
    }
    
    private var dismissButton: some View {
        Button {
            onDismiss()
        } label: {
            CompoundIcon(\.close, size: .medium, relativeTo: .compound.bodySMSemibold)
                .foregroundColor(.compound.iconTertiary)
        }
    }
}

struct KnockRequestsBannerView_Previews: PreviewProvider, TestablePreview {
    static let singleRequest: [KnockRequestInfo] = [.init(displayName: "Alice", avatarURL: nil, userID: "@alice:matrix.org", reason: nil)]
    
    static let singleRequestWithReason: [KnockRequestInfo] = [.init(displayName: "Alice", avatarURL: nil, userID: "@alice:matrix.org", reason: "Hey, I’d like to join this room because of xyz topic and I’d like to participate in the room.")]
    
    static let singleRequestNoDisplayName: [KnockRequestInfo] = [.init(displayName: nil, avatarURL: nil, userID: "@alice:matrix.org", reason: nil)]
    
    static let multipleRequests: [KnockRequestInfo] = [
        .init(displayName: "Alice", avatarURL: nil, userID: "@alice:matrix.org", reason: nil),
        .init(displayName: "Bob", avatarURL: nil, userID: "@bob:matrix.org", reason: nil),
        .init(displayName: "Charlie", avatarURL: nil, userID: "@charlie:matrix.org", reason: nil),
        .init(displayName: "Dan", avatarURL: nil, userID: "@dan:matrix.org", reason: nil),
        .init(displayName: "Test", avatarURL: nil, userID: "@dan:matrix.org", reason: nil)
    ]
    
    static var previews: some View {
        KnockRequestsBannerView(requests: singleRequest, onDismiss: { }, onAccept: { }, onViewAll: { })
            .previewDisplayName("Single Request")
        KnockRequestsBannerView(requests: singleRequestWithReason, onDismiss: { }, onAccept: { }, onViewAll: { })
            .previewDisplayName("Single Request with reason")
        KnockRequestsBannerView(requests: singleRequestNoDisplayName, onDismiss: { }, onAccept: { }, onViewAll: { })
            .previewDisplayName("Single Request, No Display Name")
        KnockRequestsBannerView(requests: multipleRequests, onDismiss: { }, onAccept: { }, onViewAll: { })
            .previewDisplayName("Multiple Requests")
    }
}
